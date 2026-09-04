// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {SafeCallback} from "@uniswap/v4-periphery/src/base/SafeCallback.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta, BalanceDeltaLibrary} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";

interface IERC20SwapToken { function transferFrom(address owner, address recipient, uint256 amount) external returns (bool); }

/// @notice v4 unlock-callback router that binds the permit winner to `hookData` from actual `msg.sender`.
contract UniswapV4RebalanceRouter is SafeCallback {
    using BalanceDeltaLibrary for BalanceDelta;

    struct Operation { PoolKey key; SwapParams params; bytes hookData; address payer; }

    error Unauthorized();
    error ReentrantCall();
    error NotExecuting();
    error NativeCurrencyUnsupported();
    error TokenTransferFailed();

    address public immutable owner;
    address public hook;
    bool private executing;

    constructor(IPoolManager poolManager_) SafeCallback(poolManager_) { owner = msg.sender; }

    function setHook(address hook_) external {
        if (msg.sender != owner || hook != address(0) || hook_ == address(0)) revert Unauthorized();
        hook = hook_;
    }

    function swapWithPermit(PoolKey memory key, SwapParams memory params, uint256 windowId, uint64 permitNonce) external {
        if (executing || hook == address(0) || address(key.hooks) != hook) revert ReentrantCall();
        if (Currency.unwrap(key.currency0) == address(0) || Currency.unwrap(key.currency1) == address(0)) revert NativeCurrencyUnsupported();
        executing = true;
        bytes memory hookData = abi.encode(windowId, permitNonce, msg.sender);
        poolManager.unlock(abi.encode(Operation({key: key, params: params, hookData: hookData, payer: msg.sender})));
        executing = false;
    }

    /// @notice Ordinary swaps remain permissionless and provide fresh pool observations to Reactive.
    function swap(PoolKey memory key, SwapParams memory params) external {
        if (executing || hook == address(0) || address(key.hooks) != hook) revert ReentrantCall();
        if (Currency.unwrap(key.currency0) == address(0) || Currency.unwrap(key.currency1) == address(0)) revert NativeCurrencyUnsupported();
        executing = true;
        poolManager.unlock(abi.encode(Operation({key: key, params: params, hookData: "", payer: msg.sender})));
        executing = false;
    }

    function _unlockCallback(bytes calldata data) internal override returns (bytes memory) {
        if (!executing) revert NotExecuting();
        Operation memory operation = abi.decode(data, (Operation));
        BalanceDelta delta = poolManager.swap(operation.key, operation.params, operation.hookData);
        _settleOrTake(operation.key.currency0, delta.amount0(), operation.payer);
        _settleOrTake(operation.key.currency1, delta.amount1(), operation.payer);
        return bytes("");
    }

    function _settleOrTake(Currency currency, int128 delta, address payer) private {
        if (delta < 0) {
            uint256 amount = uint256(-int256(delta));
            poolManager.sync(currency);
            if (!IERC20SwapToken(Currency.unwrap(currency)).transferFrom(payer, address(poolManager), amount)) revert TokenTransferFailed();
            poolManager.settle();
        } else if (delta > 0) {
            poolManager.take(currency, payer, uint256(uint128(delta)));
        }
    }
}
