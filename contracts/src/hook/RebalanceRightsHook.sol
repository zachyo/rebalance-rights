// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IRebalanceController} from "../interfaces/IRR.sol";

/// @notice v4 hook adapter boundary for the demo. Its `executeCorrection` maps to the protected v4 route.
/// @dev Production deployment wires the same checks from `beforeSwap`/`afterSwap` on a mined v4 hook address.
contract RebalanceRightsHook {
    error Unauthorized();

    IRebalanceController public immutable controller;
    address public immutable owner;
    address public router;
    mapping(bytes32 => uint160) public poolPriceE18;

    event PoolObserved(bytes32 indexed poolId, uint160 priceE18, int24 tick, uint64 observationId);
    event PermitConsumed(uint256 indexed windowId, address indexed winner, uint256 amountIn, uint256 amountOut);
    event RouterSet(address indexed router);

    constructor(IRebalanceController controller_) {
        if (address(controller_) == address(0)) revert Unauthorized();
        controller = controller_;
        owner = msg.sender;
    }

    function setRouter(address router_) external {
        if (msg.sender != owner || router != address(0) || router_ == address(0)) revert Unauthorized();
        router = router_;
        emit RouterSet(router_);
    }

    /// @notice In v4 this is emitted from `afterSwap`; the adapter makes the price source deterministic locally.
    function observePool(bytes32 poolId, uint160 priceE18, int24 tick) external {
        if (msg.sender != owner || priceE18 == 0) revert Unauthorized();
        poolPriceE18[poolId] = priceE18;
        controller.recordPoolObservation(poolId, priceE18, tick);
        emit PoolObserved(poolId, priceE18, tick, uint64(block.number));
    }

    function executeCorrection(
        address caller,
        bytes32 poolId,
        uint256 windowId,
        uint64 permitNonce,
        bool increasePrice,
        uint256 amountIn,
        uint160 resultingPriceE18
    ) external {
        if (msg.sender != router) revert Unauthorized();
        controller.consumePermit(poolId, windowId, permitNonce, caller, increasePrice, amountIn, resultingPriceE18);
        poolPriceE18[poolId] = resultingPriceE18;
        controller.recordPoolObservation(poolId, resultingPriceE18, 0);
        emit PermitConsumed(windowId, caller, amountIn, 0);
        emit PoolObserved(poolId, resultingPriceE18, 0, uint64(block.number));
    }
}
