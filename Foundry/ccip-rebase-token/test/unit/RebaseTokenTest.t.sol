// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RebaseToken} from "../../src/RebaseToken.sol";

contract RebaseTokenTest is Test {
    RebaseToken token;

    bytes32 private constant MINT_AND_BURN_ROLE = keccak256("MINT_AND_BURN_ROLE");

    address private user = makeAddr("user");
    address private secondUser = makeAddr("secondUser");
    uint256 private constant AMOUNT_FOR_MINT = 1 ether;
    uint256 private constant MAX_UINT256 = type(uint256).max;

    function setUp() public {
        token = new RebaseToken();
        token.grantMintAndBurnRole(user);
    }

    modifier mintTokens() {
        vm.prank(user);
        token.mint(user, AMOUNT_FOR_MINT, token.getInterestRate());
        _;
    }

    function testGetPrincipalBalance() public mintTokens {
        assertEq(token.pincipleBalanceOf(user), AMOUNT_FOR_MINT);
    }

    function testRevertIfInvalidAmount() public mintTokens {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(RebaseToken.RebaseToken__InvalidAmount.selector, 0));
        token.mint(user, 0, token.getInterestRate());
    }

    function testRevertIfInvalidAddress() public mintTokens {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(RebaseToken.RebaseToken__InvalidAddress.selector, address(0)));
        token.mint(address(0), 1 ether, token.getInterestRate());
    }

    function testRevetIfNotAuthorizedTryToMint() public {
        vm.expectRevert();
        token.mint(msg.sender, AMOUNT_FOR_MINT, token.getInterestRate());
    }

    function testCanMint() public mintTokens {
        assertEq(token.pincipleBalanceOf(user), AMOUNT_FOR_MINT);
    }

    function testBurnMintedTokens() public mintTokens {
        vm.startPrank(user);
        token.burn(user, token.balanceOf(user));
        assertEq(token.totalSupply(), 0);
        vm.stopPrank();
    }

    function testAddLineralRateToInvestedMoney() public mintTokens {
        vm.warp(23131);
        vm.roll(5);
        vm.startPrank(user);
        assert(token.balanceOf(user) > AMOUNT_FOR_MINT);
        vm.stopPrank();
    }

    function testTransfer() public mintTokens {
        address recipient = makeAddr("recipient");
        vm.prank(user);
        token.transfer(recipient, AMOUNT_FOR_MINT);

        assertEq(token.pincipleBalanceOf(recipient), AMOUNT_FOR_MINT);
    }

    function testTransferFrom() public mintTokens {
        vm.prank(user);
        token.approve(address(this), AMOUNT_FOR_MINT);

        token.transferFrom(user, secondUser, 0.05 ether);
        console.log("addres of token:", address(this));
        console.log("user balance:", token.allowance(address(this), user));

        assertEq(token.pincipleBalanceOf(secondUser), 0.05 ether);
        assertEq(token.allowance(user, address(this)), AMOUNT_FOR_MINT - 0.05 ether);
    }

    function testTheTransferFromFunction() public mintTokens {
        vm.prank(user);
        token.approve(address(this), AMOUNT_FOR_MINT);

        vm.prank(address(this));
        token.transferFrom(user, secondUser, 0.05 ether);

        assertEq(token.pincipleBalanceOf(secondUser), 0.05 ether);
        assertEq(token.allowance(user, address(this)), AMOUNT_FOR_MINT - 0.05 ether);
    }

    function testAllowanceAndApproval() public {
        uint256 amount = 100 * 10 ** 18;
        token.approve(user, amount);
        assertEq(token.allowance(address(this), user), amount);
    }

    function testSetIntranceRate() public {
        uint256 previousInteresRate = token.getInterestRate();
        token.setInterestRate(3e10);

        assert(previousInteresRate != token.getInterestRate());
    }

    function testSetInvalidIntranceRateReturnsError() public {
        vm.expectRevert(
            abi.encodeWithSelector(RebaseToken.RebaseToken__NewInterestRateIsLowerThanCurrent.selector, 5e10, 10e10)
        );
        token.setInterestRate(10e10);
    }

    function testGetUserInterestedRate() public mintTokens {
        assertEq(token.getUserInterestRate(user), 5e10);
    }

    function testTryToTranferMoreThanHave() public mintTokens {
        uint256 amountOfSecondUser = token.balanceOf(secondUser);
        vm.startPrank(user);
        token.transfer(secondUser, MAX_UINT256);

        assertEq(token.balanceOf(user), 0);
        assertGt(token.balanceOf(secondUser), amountOfSecondUser);
        vm.stopPrank();
    }

    function testTryToTranferFromMoreThanHave() public mintTokens {
        uint256 amountOfSecondUser = token.balanceOf(secondUser);

        vm.prank(user);
        token.approve(address(this), MAX_UINT256);

        token.transferFrom(user, secondUser, MAX_UINT256);

        assertEq(token.balanceOf(user), 0);
        assertGt(token.balanceOf(secondUser), amountOfSecondUser);
        vm.stopPrank();
    }
}
