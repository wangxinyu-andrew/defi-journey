//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
contract MiniStablecoin{
    string public name = "Mini USD";
    string public symbol = "mUSD";
    uint8 public decimals = 18;

    uint256 public totalSupply;
    address public vault;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    modifier onlyVault() {
        require(msg.sender == vault, "Only Vault");
        _;
    } 

    constructor() {
        vault = msg.sender;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");  //这里要确保from地址给第三方的授权额度够用，transferfrom一般是第三方调用
        
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        return true;
    }

    function mint(address to, uint256 amount) external onlyVault{
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function burn(address from, uint256 amount) external onlyVault{
        require(balanceOf[from] >= amount, "Insufficient balance");

        balanceOf[from] -= amount;
        totalSupply -= amount;
    }
}