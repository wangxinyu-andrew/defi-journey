// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MiniStablecoin.sol";

contract MiniVault{
    MiniStablecoin public stablecoin;//需要再理解

    mapping(address => uint256) public collateralETH;
    mapping(address => uint256) public debt;

    uint256 public constant ETH_PRICE = 3000e18;
    uint256 public constant MIN_COLLATERAL_RATIO = 150e18;

    uint256 public constant BPS_DENOMINATOR = 10_000;
    uint256 public constant LIQUIDATION_BONUS_BPS =1_000;

    constructor() {
        stablecoin = new MiniStablecoin();
    }

    function deposit() external payable {
        require(msg.value > 0, "Need ETH");//msg.value代表发的这段消息里含有的ETH数量
        collateralETH[msg.sender] += msg.value;//问一下敲代码的指法,快捷键，怎么让手不累。
    }

    function withdraw(uint256 amount) external {
        require(collateralETH[msg.sender] >= amount, "Not enough collateral");

        collateralETH[msg.sender] -= amount;

        require(_isHealthy(msg.sender), "Position would be unhealthy");

        (bool suceess, ) = payable(msg.sender).call{value: amount}("");
        require(suceess, "ETH transfer failed");
    }

    function _collateralValue(address user) internal view returns(uint256) {
        return collateralETH[user] * ETH_PRICE / 1e18;
    }//这个函数的 internal、view ？？还有returns和内部的return我又有点乱了

    function _isHealthy(address user) internal view returns(bool) {
        if (debt[user] == 0){//注意这里是[]
            return true;
        }

        uint256 ratio = _collateralValue(user) * 100e18 / debt[user];//这里的抵押率为什么不能写成小数
        return ratio >= MIN_COLLATERAL_RATIO;
    }

    function borrow(uint256 amount) external {
        require(amount > 0, "Need amount");
        
        debt[msg.sender] += amount;

        require(_isHealthy(msg.sender), "Not enough collateral");

        stablecoin.mint(msg.sender, amount);
    }

    function repay(uint256 amount) external {
        require(amount > 0, "Need amount");
        require(debt[msg.sender] >= amount, "Too much repay");

        stablecoin.transferFrom(msg.sender, address(this), amount);
        stablecoin.burn(address(this), amount);

        debt[msg.sender] -= amount;  //注意这里repay完要把debt更新
    }

    function collteralRatio(address user) public view returns(uint256) {
        if (debt[user] == 0) {
            return type(uint256).max;
        }

        return _collateralValue(user) * 100e18 / debt[user];
    }

    function liquidate(address user, uint256 repayAmount) external {
        require(!_isHealthy(user), "User is healthy");
        require(repayAmount > 0, "Need repay amount");
        require(debt[user] >= repayAmount, "Too much repay");

        uint256 collateralToSeize = repayAmount * 1e18 / ETH_PRICE;
        uint256 bonus = collateralToSeize * LIQUIDATION_BONUS_BPS /BPS_DENOMINATOR;
        uint totalCollateral = collateralToSeize + bonus;

        require(collateralETH[user] >= totalCollateral, "Not enough collateral");
        
        stablecoin.transferFrom(msg.sender, address(this), repayAmount);
        stablecoin.burn(address(this), repayAmount);

        debt[user] -= repayAmount;
        collateralETH[user] -= totalCollateral;

        (bool success, ) = payable(msg.sender).call{value: totalCollateral}("");
        require(success, "ETH transfer failed");
    }
}