// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IProtectedHook {
    function executeCorrection(address caller, bytes32 poolId, uint256 windowId, uint64 permitNonce, bool increasePrice, uint256 amountIn, uint160 resultingPriceE18) external;
}

/// @notice The only route that can invoke a permitted correction; it never trusts user-provided winner identity.
contract RebalanceRouter {
    IProtectedHook public immutable hook;

    constructor(IProtectedHook hook_) { hook = hook_; }

    function swapWithPermit(
        bytes32 poolId,
        uint256 windowId,
        uint64 permitNonce,
        bool increasePrice,
        uint256 amountIn,
        uint160 resultingPriceE18
    ) external {
        hook.executeCorrection(msg.sender, poolId, windowId, permitNonce, increasePrice, amountIn, resultingPriceE18);
    }
}
