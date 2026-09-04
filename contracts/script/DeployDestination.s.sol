// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {LpRewardVault} from "../src/core/LpRewardVault.sol";
import {RebalanceController} from "../src/core/RebalanceController.sol";
import {RebalanceAuction} from "../src/core/RebalanceAuction.sol";
import {RebalanceRightsHook} from "../src/hook/RebalanceRightsHook.sol";
import {RebalanceRouter, IProtectedHook} from "../src/core/RebalanceRouter.sol";
import {IERC20, ILpRewardVault, IRebalanceAuction, IRebalanceController} from "../src/interfaces/IRR.sol";

/// @notice Deploys the destination stack. Replace the documented placeholders before broadcasting.
contract DeployDestination is Script {
    function run() external returns (address liquidityToken, address bidToken, address vault, address controller, address auction, address hook, address router) {
        address callbackProxy = vm.envAddress("CALLBACK_PROXY");
        address expectedRvmId = vm.envOr("EXPECTED_RVM_ID", address(0));
        vm.startBroadcast();
        MockERC20 liquidity = new MockERC20("Demo LP asset", "DLP");
        MockERC20 bid = new MockERC20("Demo Wrapped Ether", "dWETH");
        LpRewardVault rewardVault = new LpRewardVault(IERC20(address(liquidity)), IERC20(address(bid)));
        RebalanceController rebalanceController = new RebalanceController(
            ILpRewardVault(address(rewardVault)), callbackProxy, expectedRvmId, 100, uint64(vm.envOr("AUCTION_DURATION", uint256(30))), uint64(vm.envOr("EXECUTION_DURATION", uint256(120))), 10 ether
        );
        RebalanceAuction rebalanceAuction = new RebalanceAuction(IERC20(address(bid)), address(rebalanceController), address(rewardVault));
        RebalanceRightsHook rebalanceHook = new RebalanceRightsHook(IRebalanceController(address(rebalanceController)));
        RebalanceRouter rebalanceRouter = new RebalanceRouter(IProtectedHook(address(rebalanceHook)));
        rewardVault.setController(address(rebalanceController));
        rebalanceController.setAuction(IRebalanceAuction(address(rebalanceAuction)));
        rebalanceController.setHook(address(rebalanceHook));
        rebalanceHook.setRouter(address(rebalanceRouter));
        vm.stopBroadcast();
        return (address(liquidity), address(bid), address(rewardVault), address(rebalanceController), address(rebalanceAuction), address(rebalanceHook), address(rebalanceRouter));
    }
}
