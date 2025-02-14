// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployNFT} from "script/DeployNFT.s.sol";
import {NFT} from "../../src/NFT.sol";

contract NFTTest is Test {
    address public USER = makeAddr("user");
    string public constant PUG =
        "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";
    DeployNFT public deployer;
    NFT public nft;

    function setUp() public {
        deployer = new DeployNFT();
        nft = deployer.run();
    }

    function testNameIsCorrect() public {
        string memory expected = "Catti";
        string memory actual = nft.name();

        assert(
            keccak256(abi.encodePacked(expected)) ==
                keccak256(abi.encodePacked(actual))
        );
    }

    function testCanMintAndHaveBalance() public {
        vm.prank(USER);
        nft.mintNft(PUG);

        assert(nft.balanceOf(USER) == 1);
        assert(
            keccak256(abi.encodePacked(PUG)) ==
                keccak256(abi.encodePacked(nft.tokenURI(0)))
        );
    }
}
