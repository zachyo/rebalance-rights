// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {UniswapV4RebalanceRouter} from "../src/v4/UniswapV4RebalanceRouter.sol";

/// @notice Emits a fresh post-deployment PoolObserved event for the RSC subscription.
contract ObservePool is Script {
    function run() external {
        address token0 = vm.envAddress("POOL_TOKEN_0");
        address token1 = vm.envAddress("POOL_TOKEN_1");
        UniswapV4RebalanceRouter router = UniswapV4RebalanceRouter(vm.envAddress("ROUTER"));
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(token0), currency1: Currency.wrap(token1), fee: 3_000, tickSpacing: 60, hooks: IHooks(vm.envAddress("HOOK"))
        });
        vm.startBroadcast();
        MockERC20(token0).approve(address(router), type(uint256).max);
        router.swap(
            key,
            SwapParams({zeroForOne: true, amountSpecified: -int256(0.001 ether), sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1})
        );
        vm.stopBroadcast();
    }
}
