// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IReactive} from "reactive-lib/interfaces/IReactive.sol";
import {AbstractReactive} from "reactive-lib/abstract-base/AbstractReactive.sol";

/// @notice Reactive coordinator for reference updates, hook observations, and lifecycle closure.
/// @dev The mock reference market is a trusted simulation input, not an oracle.
contract RebalanceRSC is AbstractReactive {
    uint16 private constant BPS = 10_000;
    bytes32 public constant REFERENCE_PRICE_UPDATED = keccak256("ReferencePriceUpdated(bytes32,uint160,uint64)");
    bytes32 public constant POOL_OBSERVED = keccak256("PoolObserved(bytes32,uint160,int24,uint64)");
    bytes32 public constant PERMIT_CONSUMED = keccak256("PermitConsumed(uint256,address,uint256,uint256)");
    bytes32 public constant WINDOW_EXPIRED = keccak256("WindowExpired(uint256,address,uint256)");

    uint256 public immutable sourceChainId;
    uint256 public immutable destinationChainId;
    address public immutable referenceMarket;
    address public immutable hook;
    address public immutable controller;
    bytes32 public immutable pairId;
    bytes32 public immutable poolId;
    uint16 public immutable thresholdBps;
    uint64 public immutable callbackGasLimit;
    uint64 public nextCallbackNonce;
    uint160 public latestReferencePriceE18;
    uint160 public latestPoolPriceE18;
    uint64 public latestReferenceSequence;
    bool public windowOpen;
    mapping(bytes32 => bool) public processedLog;

    event DislocationDetected(uint160 referencePriceE18, uint160 poolPriceE18, uint64 referenceSequence);
    event CallbackRequested(bytes4 indexed action, uint256 indexed windowId, uint64 indexed callbackNonce);

    constructor(
        uint256 sourceChainId_,
        uint256 destinationChainId_,
        address referenceMarket_,
        address hook_,
        address controller_,
        bytes32 pairId_,
        bytes32 poolId_,
        uint16 thresholdBps_,
        uint64 callbackGasLimit_
    ) payable {
        require(referenceMarket_ != address(0) && hook_ != address(0) && controller_ != address(0), "invalid address");
        sourceChainId = sourceChainId_;
        destinationChainId = destinationChainId_;
        referenceMarket = referenceMarket_;
        hook = hook_;
        controller = controller_;
        pairId = pairId_;
        poolId = poolId_;
        thresholdBps = thresholdBps_;
        callbackGasLimit = callbackGasLimit_;
    }

    /// @notice Registers the source and destination event subscriptions after deployment.
    /// @dev Keeping registration outside the constructor avoids Reactive Lasna deployment simulation failures.
    function subscribe() external rnOnly {
        service.subscribe(sourceChainId, referenceMarket, uint256(REFERENCE_PRICE_UPDATED), uint256(pairId), REACTIVE_IGNORE, REACTIVE_IGNORE);
        service.subscribe(destinationChainId, hook, uint256(POOL_OBSERVED), uint256(poolId), REACTIVE_IGNORE, REACTIVE_IGNORE);
        service.subscribe(destinationChainId, hook, uint256(PERMIT_CONSUMED), REACTIVE_IGNORE, REACTIVE_IGNORE, REACTIVE_IGNORE);
        service.subscribe(destinationChainId, controller, uint256(WINDOW_EXPIRED), REACTIVE_IGNORE, REACTIVE_IGNORE, REACTIVE_IGNORE);
    }

    function react(IReactive.LogRecord calldata log) external override vmOnly {
        bytes32 eventId = keccak256(abi.encode(log.chain_id, log.tx_hash, log.log_index));
        if (processedLog[eventId]) return;
        processedLog[eventId] = true;

        if (log.chain_id == sourceChainId && log._contract == referenceMarket && log.topic_0 == uint256(REFERENCE_PRICE_UPDATED)) {
            _onReference(bytes32(log.topic_1), log.data);
        } else if (log.chain_id == destinationChainId && log._contract == hook && log.topic_0 == uint256(POOL_OBSERVED)) {
            _onPool(log.data);
        } else if (log.chain_id == destinationChainId && log._contract == hook && log.topic_0 == uint256(PERMIT_CONSUMED)) {
            _onPermitConsumed(uint256(log.topic_1));
        } else if (log.chain_id == destinationChainId && log._contract == controller && log.topic_0 == uint256(WINDOW_EXPIRED)) {
            windowOpen = false;
        }
    }

    function _onReference(bytes32 eventPairId, bytes calldata data) private {
        if (eventPairId != pairId) return;
        (uint160 priceE18, uint64 sequence) = abi.decode(data, (uint160, uint64));
        if (sequence <= latestReferenceSequence) return;
        latestReferenceSequence = sequence;
        latestReferencePriceE18 = priceE18;
        _openIfDiverged();
    }

    function _onPool(bytes calldata data) private {
        (uint160 priceE18,,) = abi.decode(data, (uint160, int24, uint64));
        latestPoolPriceE18 = priceE18;
        _openIfDiverged();
    }

    function _onPermitConsumed(uint256 windowId) private {
        if (!windowOpen) return;
        windowOpen = false;
        uint64 nonce = ++nextCallbackNonce;
        // Reactive overwrites the first callback argument with the deployer's RVM ID.
        bytes memory payload = abi.encodeWithSignature("markCorrected(address,uint256,uint64)", address(0), windowId, nonce);
        emit Callback(destinationChainId, controller, callbackGasLimit, payload);
        emit CallbackRequested(bytes4(keccak256("markCorrected(address,uint256,uint64)")), windowId, nonce);
    }

    function _openIfDiverged() private {
        if (windowOpen || latestPoolPriceE18 == 0 || latestReferencePriceE18 == 0) return;
        uint256 difference = latestReferencePriceE18 > latestPoolPriceE18
            ? uint256(latestReferencePriceE18 - latestPoolPriceE18)
            : uint256(latestPoolPriceE18 - latestReferencePriceE18);
        if (difference * BPS / latestPoolPriceE18 < thresholdBps) return;
        windowOpen = true;
        uint64 nonce = ++nextCallbackNonce;
        bytes memory payload = abi.encodeWithSignature(
            "openWindow(address,bytes32,uint160,uint64,uint64)",
            address(0),
            poolId,
            latestReferencePriceE18,
            latestReferenceSequence,
            nonce
        );
        emit DislocationDetected(latestReferencePriceE18, latestPoolPriceE18, latestReferenceSequence);
        emit Callback(destinationChainId, controller, callbackGasLimit, payload);
        emit CallbackRequested(bytes4(keccak256("openWindow(address,bytes32,uint160,uint64,uint64)")), 0, nonce);
    }
}
