// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test } from "forge-std/Test.sol";
import { StdInvariant } from "forge-std/StdInvariant.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { PoolFactory } from "../../src/PoolFactory.sol";
import { TSwapPool } from "../../src/TSwapPool.sol";
import { Handler } from "./Handler.t.sol";

contract Invariant is StdInvariant, Test {
    uint256 public constant STARTING_X = 100e18;
    uint256 public constant STARTING_Y = 50e18;

    ERC20Mock poolToken;
    ERC20Mock weth;

    PoolFactory factory;
    TSwapPool pool;
    Handler handler;

    function setUp() public {
        poolToken = new ERC20Mock();
        weth = new ERC20Mock();

        factory = new PoolFactory(address(weth));
        pool = TSwapPool(factory.createPool(address(poolToken)));

        poolToken.mint(address(this), STARTING_X);
        weth.mint(address(this), STARTING_Y);

        poolToken.approve(address(pool), type(uint256).max);
        weth.approve(address(pool), type(uint256).max);

        pool.deposit(STARTING_Y, STARTING_Y, STARTING_X, uint64(block.timestamp));

        handler = new Handler(pool);
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = handler.deposit.selector;
        selectors[1] = handler.swapPoolTokenForWethBasedOnOutputWeth.selector;

        targetSelector(FuzzSelector({ addr: address(handler), selectors: selectors }));
        targetContract(address(handler));
    }

    function invariant_constantProductFormulaStaysTheSame() public {
        assertEq(handler.actualDeltaX(), handler.expectedDeltaX());
    }
}
