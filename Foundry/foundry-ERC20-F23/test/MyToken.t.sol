// SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployToken} from "../script/DeployToken.s.sol";
import {MyToken} from "../src/MyToken.sol";

contract MyTokenTest is Test {
    MyToken public token;
    DeployToken public deployer;
    address gosho = makeAddr("gosho");
    address pioter = makeAddr("pioter");

    uint256 public constant STARTING_BALANCE = 100 ether;
    address public user1 = address(0x1);
    address public user2 = address(0x2);

    function setUp() public {
        deployer = new DeployToken();
        token = deployer.run();

        vm.prank(msg.sender);
        token.transfer(gosho, STARTING_BALANCE);
    }

    function testGoshoBalance() public {
        assert(STARTING_BALANCE == token.balanceOf(gosho));
    }

    function testAllownance() public {
        uint256 initialAllowance = 1000;
        vm.prank(gosho);
        token.approve(pioter, initialAllowance);

        uint256 amount = 500;

        vm.prank(pioter);
        token.transferFrom(gosho, pioter, amount);

        assertEq(token.balanceOf(pioter), amount);
        assertEq(token.balanceOf(gosho), STARTING_BALANCE - amount);
    }

    function testTransfer() public {
        uint256 amount = 0.01 ether;

        vm.prank(msg.sender);
        token.transfer(user1, amount);

        // Verify user1 received the tokens
        assertEq(token.balanceOf(user1), amount);
    }

    function testTransferInsufficientBalance() public {
        uint256 amount = 100 * 10 ** 18;
        vm.expectRevert();
        vm.prank(user1);
        token.transfer(user2, amount);
    }

    function testAllowanceAndApproval() public {
        uint256 amount = 100 * 10 ** 18;
        token.approve(user1, amount);
        assertEq(token.allowance(address(this), user1), amount);
    }

    function testTransferFromWithoutApproval() public {
        uint256 amount = 100 * 10 ** 18;
        vm.expectRevert();
        vm.prank(user1);
        token.transferFrom(address(this), user2, amount);
    }
}
