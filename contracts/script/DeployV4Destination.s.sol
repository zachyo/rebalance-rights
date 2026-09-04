// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {LpRewardVault} from "../src/core/LpRewardVault.sol";
import {RebalanceController} from "../src/core/RebalanceController.sol";
import {RebalanceAuction} from "../src/core/RebalanceAuction.sol";
import {UniswapV4RebalanceRouter} from "../src/v4/UniswapV4RebalanceRouter.sol";
import {UniswapV4RebalanceHookFactory} from "../src/deploy/UniswapV4RebalanceHookFactory.sol";
import {UniswapV4RebalanceRightsHook} from "../src/hook/UniswapV4RebalanceRightsHook.sol";
import {IERC20, ILpRewardVault, IRebalanceAuction, IRebalanceController} from "../src/interfaces/IRR.sol";

/// @notice Full destination deployment that mines the actual v4 hook address.
contract DeployV4Destination is Script {
    function run()
        external
        returns (address liquidityToken, address bidToken, address poolTokenA, address poolTokenB, address vault, address controller, address auction, address router, address hook)
    {
        IPoolManager poolManager = IPoolManager(vm.envAddress("POOL_MANAGER"));
        address callbackProxy = vm.envAddress("CALLBACK_PROXY");
        address expectedRvmId = vm.envOr("EXPECTED_RVM_ID", address(0));
        vm.startBroadcast();
        MockERC20 liquidity = new MockERC20("Demo LP asset", "DLP");
        MockERC20 bid = new MockERC20("Demo Wrapped Ether", "dWETH");
        MockERC20 tokenA = new MockERC20("Demo Pool Token A", "DTA");
        MockERC20 tokenB = new MockERC20("Demo Pool Token B", "DTB");
        LpRewardVault rewardVault = new LpRewardVault(IERC20(address(liquidity)), IERC20(address(bid)));
        RebalanceController rebalanceController = new RebalanceController(
            ILpRewardVault(address(rewardVault)), callbackProxy, expectedRvmId, 100, uint64(vm.envOr("AUCTION_DURATION", uint256(30))), uint64(vm.envOr("EXECUTION_DURATION", uint256(120))), 10 ether
        );
        RebalanceAuction rebalanceAuction = new RebalanceAuction(IERC20(address(bid)), address(rebalanceController), address(rewardVault));
        UniswapV4RebalanceRouter rebalanceRouter = new UniswapV4RebalanceRouter(poolManager);
        UniswapV4RebalanceHookFactory factory = new UniswapV4RebalanceHookFactory();
        (, bytes32 salt) = factory.findSalt(poolManager, IRebalanceController(address(rebalanceController)), address(rebalanceRouter));
        UniswapV4RebalanceRightsHook rebalanceHook = factory.deployHook(
            salt, poolManager, IRebalanceController(address(rebalanceController)), address(rebalanceRouter)
        );
        rewardVault.setController(address(rebalanceController));
        rebalanceController.setAuction(IRebalanceAuction(address(rebalanceAuction)));
        rebalanceController.setHook(address(rebalanceHook));
        rebalanceRouter.setHook(address(rebalanceHook));
        vm.stopBroadcast();
        return (address(liquidity), address(bid), address(tokenA), address(tokenB), address(rewardVault), address(rebalanceController), address(rebalanceAuction), address(rebalanceRouter), address(rebalanceHook));
    }
}
