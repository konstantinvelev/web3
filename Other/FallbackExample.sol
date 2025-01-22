// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

error notEnoughtBlocks();

contract FallbackExample {
    uint256 public receiveResult;
    uint256 public fallbackResult;

    function getReveive() view public returns (uint256){
        if(receiveResult < 2){
            revert notEnoughtBlocks();
        }
        return fallbackResult;
    }

    receive() external payable { 
        receiveResult += 1;
    }

    fallback() external payable {
        fallbackResult += 1;
     }
}