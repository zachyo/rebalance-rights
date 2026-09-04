// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "v4-hooks-public/utils/HookMiner.sol";
import {IRebalanceController} from "../interfaces/IRR.sol";
import {UniswapV4RebalanceRightsHook} from "../hook/UniswapV4RebalanceRightsHook.sol";

/// @notice Mines and deploys the v4 hook at an address with the required permission bits.
contract UniswapV4RebalanceHookFactory {
    uint160 public constant REQUIRED_FLAGS = Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG;
    error InvalidHookAddress();
    event HookDeployed(address indexed hook, bytes32 indexed salt);

    function findSalt(IPoolManager poolManager, IRebalanceController controller, address router)
        external view returns (address predictedHook, bytes32 salt)
    {
        return HookMiner.find(address(this), REQUIRED_FLAGS, type(UniswapV4RebalanceRightsHook).creationCode, abi.encode(poolManager, controller, router));
    }

    function deployHook(bytes32 salt, IPoolManager poolManager, IRebalanceController controller, address router)
        external returns (UniswapV4RebalanceRightsHook hook)
    {
        hook = new UniswapV4RebalanceRightsHook{salt: salt}(poolManager, controller, router);
        if ((uint160(address(hook)) & Hooks.ALL_HOOK_MASK) != REQUIRED_FLAGS) revert InvalidHookAddress();
        emit HookDeployed(address(hook), salt);
    }
}
