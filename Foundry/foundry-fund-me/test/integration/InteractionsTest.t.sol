//SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundInteraction, WithdrawInteraction} from "../../script/Interactions.s.sol";

contract InteractionsTest is Test {
    FundMe fundMe;
    address USER = makeAddr("goshkata");
    uint256 constant SEND_VALUE = 0.0000001 ether;
    uint256 constant STARTING_BALANCE = 100 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testUserCanFundInteraction() public {
        FundInteraction fundInteraction = new FundInteraction();
        fundInteraction.sendFund(address(fundMe));

        WithdrawInteraction withdrawInteraction = new WithdrawInteraction();
        withdrawInteraction.sendWithdraw(address(fundMe));

        assertEq(address(fundMe).balance, 0);
    }
}
