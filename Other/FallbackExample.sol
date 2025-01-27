// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

error notEnoughtBlocks(string message);

contract FallbackExample {
    uint256 public receiveResult;
    uint256 public fallbackResult;

    function getReveive() view public returns (uint256){
        if(receiveResult < 2){
            revert notEnoughtBlocks({message: "blocks should be more"});
        }
        return receiveResult;
    }

    receive() external payable { 
        receiveResult += 1;
    }

    fallback() external payable {
        fallbackResult += 1;
     }
}