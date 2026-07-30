// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MiniStablecoin.sol";

contract MiniVault{
    MiniStablecoin public stablecoin;//需要再理解

    mapping(address => uint256) public collateralETH;
    mapping(address => uint256) public debt;

    uint256 public constant ETH_PRICE = 3000e18;
    uint256 public constant MIN_COLLATERAL_RATIO = 150e18;

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

        payable(msg.sender).transfer(amount);
    }

    function _collateralValue(address user) internal view returns(uint256) {
        return collateralETH[user] * ETH_PRICE / 1e18;
    }//这个函数的 internal、view ？？还有returns和内部的return我又有点乱了

    function _isHealthy(address user) internal view returns(bool){
        if (debt[user] == 0){//注意这里是[]
            return ture;
        }

        uint256 ratio = _collateralValue(user) * 100e18 / debt[user];//这里的抵押率为什么不能写成小数
        return ratio >= MIN_COLLATERAL_RATIO;
    }

    function borrow(uint256 amount) external{
        require(amount > 0, "Need amount");
        
        debt[msg.sender] += amount;

        require(_isHealthy(msg.sender), "Not enought collateral");

        stablecoin.mint(msg.sender, amount);
    }

    function repay(uint256 amount) external{
        require(amount > 0, "Need amouny");
        require(debt[msg.sender] >= amount, "Too much repay");

        stablecoin.transferFrom(msg.sender, address(this), amount);
        stablecoin.burn(address(this), amount);

        debt[msg.sender] -= amount;  //注意这里repay完要把debt更新
    }
}