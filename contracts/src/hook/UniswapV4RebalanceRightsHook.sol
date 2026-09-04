// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseHook} from "v4-hooks-public/base/BaseHook.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {FullMath} from "@uniswap/v4-core/src/libraries/FullMath.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {IRebalanceController} from "../interfaces/IRR.sol";

/// @notice Production v4 enforcement hook. Deploy through CREATE2 mining for its low-bit permissions.
/// @dev `hookData` is only accepted from the configured router, which supplies its actual caller as winner.
contract UniswapV4RebalanceRightsHook is BaseHook {
    using PoolIdLibrary for PoolKey;
    using StateLibrary for IPoolManager;

    error Unauthorized();
    error InvalidPermit();
    error InvalidPrice();

    IRebalanceController public immutable controller;
    address public immutable router;

    event PoolObserved(bytes32 indexed poolId, uint160 priceE18, int24 tick, uint64 observationId);
    event PermitConsumed(uint256 indexed windowId, address indexed winner, uint256 amountIn, uint256 amountOut);

    constructor(IPoolManager poolManager_, IRebalanceController controller_, address router_) BaseHook(poolManager_) {
        if (address(controller_) == address(0) || router_ == address(0)) revert Unauthorized();
        controller = controller_;
        router = router_;
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory permissions) {
        permissions.beforeSwap = true;
        permissions.afterSwap = true;
    }

    function _beforeSwap(address sender, PoolKey calldata key, SwapParams calldata params, bytes calldata hookData)
        internal view override returns (bytes4, BeforeSwapDelta, uint24)
    {
        // Ordinary swaps carry no permit payload and remain available to establish observations.
        if (hookData.length == 0) return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
        if (sender != router) revert Unauthorized();
        (uint256 windowId, uint64 permitNonce, address winner) = abi.decode(hookData, (uint256, uint64, address));
        uint256 amountIn = _absolute(params.amountSpecified);
        if (!controller.permitValid(PoolId.unwrap(key.toId()), windowId, permitNonce, winner, !params.zeroForOne, amountIn)) {
            revert InvalidPermit();
        }
        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function _afterSwap(address sender, PoolKey calldata key, SwapParams calldata params, BalanceDelta, bytes calldata hookData)
        internal override returns (bytes4, int128)
    {
        PoolId poolId = key.toId();
        (uint160 sqrtPriceX96, int24 tick,,) = poolManager.getSlot0(poolId);
        uint160 priceE18 = _toPriceE18(sqrtPriceX96);
        if (hookData.length != 0) {
            if (sender != router) revert Unauthorized();
            (uint256 windowId, uint64 permitNonce, address winner) = abi.decode(hookData, (uint256, uint64, address));
            uint256 amountIn = _absolute(params.amountSpecified);
            controller.consumePermit(PoolId.unwrap(poolId), windowId, permitNonce, winner, !params.zeroForOne, amountIn, priceE18);
            emit PermitConsumed(windowId, winner, amountIn, 0);
        }
        emit PoolObserved(PoolId.unwrap(poolId), priceE18, tick, uint64(block.number));
        controller.recordPoolObservation(PoolId.unwrap(poolId), priceE18, tick);
        return (this.afterSwap.selector, 0);
    }

    function _absolute(int256 value) private pure returns (uint256) {
        return value < 0 ? uint256(-(value + 1)) + 1 : uint256(value);
    }

    /// @dev Demo tokens both use 18 decimals, so token1/token0 needs no decimal adjustment.
    function _toPriceE18(uint160 sqrtPriceX96) private pure returns (uint160) {
        uint256 ratioX96 = FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, 1 << 96);
        uint256 normalized = FullMath.mulDiv(ratioX96, 1e18, 1 << 96);
        if (normalized == 0 || normalized > type(uint160).max) revert InvalidPrice();
        return uint160(normalized);
    }
}
