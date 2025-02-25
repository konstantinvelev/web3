// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";

import {Vault} from "../../src/Vault.sol";
import {RebaseToken} from "../../src/RebaseToken.sol";
import {IRebaseToken} from "../../src/interfaces/IRebaseToken.sol";

contract VaultTest is Test {
    RebaseToken public token;
    Vault public vault;
    uint256 private constant STARTING_BALANCE = 1 ether;

    address private owner = makeAddr("user");
    address private user = makeAddr("user");

    function setUp() public {
        vm.startPrank(owner);
        token = new RebaseToken();
        vault = new Vault(IRebaseToken(address(token)));
        token.grantMintAndBurnRole(address(vault));
        vm.deal(address(vault), STARTING_BALANCE);
        vm.stopPrank();
    }

    function addRewardsToVault(uint256 reward) public {
        payable(address(vault)).call{value: reward}("");
    }

    function test21DepositLinear(uint256 amount) public {
        // Deposit funds
        amount = bound(amount, 1e15, type(uint96).max);
        // 1. deposit
        vm.startPrank(user);
        vm.deal(user, amount);
        vault.deposit{value: amount}();
        // 2. check our rebase token balance
        uint256 startBalance = token.balanceOf(user);
        console.log("block.timestamp", block.timestamp);
        console.log("startBalance", startBalance);
        assertEq(startBalance, amount);
        // 3. warp the time and check the balance again
        vm.warp(block.timestamp + 1 hours);
        console.log("block.timestamp", block.timestamp);
        uint256 middleBalance = token.balanceOf(user);
        console.log("middleBalance", middleBalance);
        assertGt(middleBalance, startBalance);
        // 4. warp the time again by the same amount and check the balance again
        vm.warp(block.timestamp + 1 hours);
        uint256 endBalance = token.balanceOf(user);
        console.log("block.timestamp", block.timestamp);
        console.log("endBalance", endBalance);
        assertGt(endBalance, middleBalance);

        assertApproxEqAbs(endBalance - middleBalance, middleBalance - startBalance, 1);

        vm.stopPrank();
    }

    function testRedeemStraightAway(uint256 amount) public {
        amount = bound(amount, 1e15, type(uint96).max);
        vm.startPrank(user);
        vm.deal(user, amount);
        vault.deposit{value: amount}();
        assertEq(token.balanceOf(user), amount);

        vault.redeem(type(uint256).max);
        assertEq(token.balanceOf(user), 0);
        assertEq(address(user).balance, amount);
        vm.stopPrank();
    }

    function testRedeemAfterTimePassed(uint256 amount, uint256 time) public {
        amount = bound(amount, 1e10, type(uint40).max);
        time = bound(time, 1000, type(uint96).max);

        vm.deal(user, amount);

        vm.prank(user);
        vault.deposit{value: amount}();

        vm.warp(block.timestamp + time);
        uint256 balance = token.balanceOf(user);

        vm.deal(owner, (balance - amount));
        vm.prank(owner);
        addRewardsToVault(balance - amount);

        vm.prank(user);
        vault.redeem(type(uint256).max);

        uint256 totalBalance = address(user).balance;

        assertEq(totalBalance, balance);
        assertGt(totalBalance, amount);
    }

    function testTransfer(uint256 amount, uint256 amountToSend) public {
        amount = bound(amount, 1e5 + 1e5, type(uint40).max);
        amountToSend = bound(amountToSend, 1e5, amount - 1e5);

        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();

        address user2 = makeAddr("user2");
        uint256 userBalance = token.balanceOf(user);
        uint256 user2Balance = token.balanceOf(user2);
        assertEq(userBalance, amount);
        assertEq(user2Balance, 0);

        vm.prank(owner);
        token.setInterestRate(4e10);
        console.log("userBalance: ", userBalance);
        vm.prank(user);
        token.transfer(user2, amountToSend);

        uint256 userBalanceAfterTransfer = token.balanceOf(user);
        uint256 user2BalanceAfterTransfer = token.balanceOf(user2);

        assertEq(userBalanceAfterTransfer, userBalance - amountToSend);
        assertEq(user2BalanceAfterTransfer, user2Balance + amountToSend);

        assertEq(token.getUserInterestRate(user), 5e10);
        assertEq(token.getUserInterestRate(user2), 5e10);
    }

    function testGetRebaseTokenAddress() public view {
        assertEq(vault.getRebaseTokenAddress(), address(token));
    }
}
