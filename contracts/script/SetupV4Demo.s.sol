// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {DemoLiquidityManager} from "../src/mocks/DemoLiquidityManager.sol";
import {LpRewardVault} from "../src/core/LpRewardVault.sol";
import {UniswapV4RebalanceRouter} from "../src/v4/UniswapV4RebalanceRouter.sol";

/// @notice Initializes a one-price demo pool and funds the named demo roles.
contract SetupV4Demo is Script {
    uint160 private constant ONE_X96 = 79_228_162_514_264_337_593_543_950_336;

    function run() external returns (bytes32 poolId, address token0, address token1, address liquidityManager) {
        IPoolManager manager = IPoolManager(vm.envAddress("POOL_MANAGER"));
        MockERC20 tokenA = MockERC20(vm.envAddress("POOL_TOKEN_A"));
        MockERC20 tokenB = MockERC20(vm.envAddress("POOL_TOKEN_B"));
        MockERC20 lpToken = MockERC20(vm.envAddress("LIQUIDITY_TOKEN"));
        MockERC20 bidToken = MockERC20(vm.envAddress("BID_TOKEN"));
        LpRewardVault vault = LpRewardVault(vm.envAddress("VAULT"));
        address hook = vm.envAddress("HOOK");
        UniswapV4RebalanceRouter router = UniswapV4RebalanceRouter(vm.envAddress("ROUTER"));
        address deployer = vm.envAddress("DEPLOYER");
        address alice = vm.envAddress("ALICE");
        address bao = vm.envAddress("BAO");
        address lateLp = vm.envAddress("LATE_LP");
        address searcherA = vm.envAddress("SEARCHER_A");
        address searcherB = vm.envAddress("SEARCHER_B");

        (MockERC20 first, MockERC20 second) = address(tokenA) < address(tokenB) ? (tokenA, tokenB) : (tokenB, tokenA);
        token0 = address(first);
        token1 = address(second);
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(token0), currency1: Currency.wrap(token1), fee: 3_000, tickSpacing: 60, hooks: IHooks(hook)
        });

        vm.startBroadcast();
        manager.initialize(key, ONE_X96);
        DemoLiquidityManager manager_ = new DemoLiquidityManager(manager);
        liquidityManager = address(manager_);
        first.mint(deployer, 1e30);
        second.mint(deployer, 1e30);
        first.approve(address(manager_), type(uint256).max);
        second.approve(address(manager_), type(uint256).max);
        manager_.addLiquidity(key, -60_000, 60_000, 1e21, keccak256("rebalance-rights-demo"));
        first.approve(address(router), type(uint256).max);
        router.swap(
            key,
            SwapParams({zeroForOne: true, amountSpecified: -int256(0.001 ether), sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1})
        );

        lpToken.mint(alice, 60 ether);
        lpToken.mint(bao, 40 ether);
        lpToken.mint(lateLp, 25 ether);
        bidToken.mint(searcherA, 10 ether);
        bidToken.mint(searcherB, 10 ether);
        first.mint(searcherA, 10 ether);
        second.mint(searcherB, 10 ether);
        vm.stopBroadcast();

        poolId = keccak256(abi.encode(key));
    }
}
