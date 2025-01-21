// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {SimpleStorage, SimpleStorage2} from "./SimpleStorage.sol";

contract StorageFactory {
    SimpleStorage public simpleStorageContract;

    function createSimpleStorageContract() public {
        simpleStorageContract = new SimpleStorage();
    }
}
