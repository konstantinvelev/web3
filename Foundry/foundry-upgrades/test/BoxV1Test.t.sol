// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";
import {DeployBox} from "../script/DeployBox.s.sol";
import {UpgradeBox} from "../script/UpgradeBox.s.sol";
import {BoxV1} from "../src/BoxV1.sol";
import {BoxV2} from "../src/BoxV2.sol";

contract Boxv1Test is Test {
    DeployBox public deployBox;
    UpgradeBox public upgradeBox;
    address public proxy;
    address public owner = makeAddr("owner");

    function setUp() public {
        vm.prank(owner);
        deployBox = new DeployBox();
        upgradeBox = new UpgradeBox();

        proxy = deployBox.run();
    }

    function testProxyStartsAsBoxV1() public {
       vm.expectRevert();
        BoxV2(proxy).setNumber(7);
    }

    function testUpgrades() public {
        vm.prank(owner);
        BoxV2 boxV2 = new BoxV2();

        address proxy1 = upgradeBox.upgradeBox(proxy, address(boxV2));
        assertEq(proxy, proxy1);
        assertEq(BoxV2(proxy).version(), 2);

        BoxV2(proxy).setNumber(7);
        assertEq(BoxV2(proxy).getNumber(), 7);
    }
}
