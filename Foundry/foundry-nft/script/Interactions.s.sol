// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {NFT} from "../src/NFT.sol";
import {MoodNFT} from "../src/MoodNFT.sol";

contract MintNFT is Script {
    string public constant PUG =
        "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "MoodNFT",
            block.chainid
        );

        mintNFTOnContract(mostRecentlyDeployed);
    }

    function mintNFTOnContract(address contractAddress) public {
        vm.startBroadcast();
        NFT(contractAddress).mintNft(PUG);
        vm.stopBroadcast();
    }
}

contract MintMoodNft is Script {
    function run() external {
        address mostRecentlyDeployedMoodNft = DevOpsTools
            .get_most_recent_deployment("MoodNFT", block.chainid);
        mintNftOnContract(mostRecentlyDeployedMoodNft);
    }

    function mintNftOnContract(address moodNftAddress) public {
        vm.startBroadcast();
        MoodNFT(moodNftAddress).mintNft();
        vm.stopBroadcast();
    }
}

contract FlipMoodNft is Script {
    function run() external {
        address mostRecentlyDeployedMoodNft = DevOpsTools
            .get_most_recent_deployment("MoodNFT", block.chainid);
        flipNftMoodOnContract(mostRecentlyDeployedMoodNft);
    }

    function flipNftMoodOnContract(address moodNftAddress) public {
        vm.startBroadcast();
        MoodNFT(moodNftAddress).flipMood(1);
        vm.stopBroadcast();
    }
}
