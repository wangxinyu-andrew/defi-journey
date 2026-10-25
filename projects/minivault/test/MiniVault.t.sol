// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "../lib/forge-std/src/Test.sol";
import {MiniVault} from "../contracts/MiniVault.sol";
import {MiniStablecoin} from "../contracts/MiniStablecoin.sol";

contract MiniVaultTest is Test {
    MiniVault internal vault;
    MiniStablecoin internal stablecoin;
    address internal alice = address(0xA11CE);

    function setUp() public {
        vault = new MiniVault();
        stablecoin = vault.stablecoin();
        vm.deal(alice, 10 ether);
    }

    function testDepositRecordsCollateral() public {
        vm.prank(alice);
        vault.deposit{value: 1 ether}();

        assertEq(vault.collateralETH(alice), 1 ether);
        assertEq(address(vault).balance, 1 ether);

        vm.prank(alice);
        vault.deposit{value: 2 ether}();

        assertEq(vault.collateralETH(alice), 3 ether);
        assertEq(address(vault).balance, 3 ether);
        assertEq(alice.balance, 7 ether);
    }

    function testBorrowMintsStablecoinAndRecordsDebt() public {
        vm.prank(alice);
        vault.deposit{value: 1 ether}();

        vm.prank(alice);
        vault.borrow(2000e18);

        assertEq(vault.debt(alice), 2000e18);
        assertEq(stablecoin.balanceOf(alice), 2000e18);
        assertEq(stablecoin.totalSupply(), 2000e18);
        assertEq(vault.collateralETH(alice), 1 ether);
        assertEq(address(vault).balance, 1 ether);
    }

    function testBorrowRevertsWhenUnderCollateralized() public {
        vm.prank(alice);
        vault.deposit{value: 1 ether}();

        vm.expectRevert(bytes("Not enough collateral"));
        vm.prank(alice);
        vault.borrow(2001e18);

        assertEq(vault.debt(alice), 0);
        assertEq(stablecoin.balanceOf(alice), 0);
        assertEq(stablecoin.totalSupply(), 0);
        assertEq(vault.collateralETH(alice), 1 ether);
        assertEq(address(vault).balance, 1 ether);
    }

    function testWithdrawRevertsWhenPositionWouldBecomeUnhealthy() public {
        vm.prank(alice);
        vault.deposit{value: 1 ether}();

        vm.prank(alice);
        vault.borrow(2000e18);

        vm.expectRevert(bytes("Position would be unhealthy"));
        vm.prank(alice);
        vault.withdraw(0.1 ether);

        assertEq(vault.collateralETH(alice), 1 ether);
        assertEq(address(vault).balance, 1 ether);
        assertEq(alice.balance, 9 ether);
        assertEq(vault.debt(alice), 2000e18);
        assertEq(stablecoin.balanceOf(alice), 2000e18);
        assertEq(stablecoin.totalSupply(), 2000e18);
    }
}
