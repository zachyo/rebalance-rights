// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IRebalanceAuction, ILpRewardVault} from "../interfaces/IRR.sol";

/// @notice Authenticated callback receiver and one-window-per-pool state machine.
contract RebalanceController {
    uint16 public constant BPS = 10_000;

    enum WindowState { None, Open, Finalized, Consumed, Expired, Closed }

    error Unauthorized();
    error InvalidState();
    error CallbackAlreadyUsed();
    error DeadlineNotReached();
    error DeadlinePassed();
    error BelowThreshold();
    error PermitInvalid();
    error PermitAlreadyUsed();
    error PriceGuardFailed();

    struct Window {
        bytes32 poolId;
        uint160 referencePriceE18;
        uint160 openingPoolPriceE18;
        uint160 priceGuardE18;
        uint64 referenceSequence;
        uint64 openedAt;
        uint64 bidDeadline;
        uint64 executionDeadline;
        uint64 snapshotBlock;
        uint64 permitNonce;
        uint256 snapshotSupply;
        uint256 winningBid;
        uint256 maximumInput;
        address winner;
        bool increasePrice;
        WindowState state;
    }

    address public immutable owner;
    address public immutable callbackProxy;
    ILpRewardVault public immutable vault;
    uint16 public immutable divergenceThresholdBps;
    uint64 public immutable auctionDuration;
    uint64 public immutable executionDuration;
    uint256 public immutable maximumInput;
    address public expectedRvmId;
    address public hook;
    IRebalanceAuction public auction;
    uint256 public nextWindowId;
    mapping(uint256 => Window) private windows;
    mapping(bytes32 => uint256) public activeWindowForPool;
    mapping(bytes32 => uint160) public latestPoolPriceE18;
    mapping(uint64 => bool) public callbackNonceUsed;

    event ExpectedRvmIdSet(address indexed rvmId);
    event HookSet(address indexed hook);
    event AuctionSet(address indexed auction);
    event PoolObserved(bytes32 indexed poolId, uint160 priceE18, int24 tick, uint64 observationId);
    event WindowOpened(
        uint256 indexed windowId,
        bytes32 indexed poolId,
        uint160 referencePriceE18,
        uint160 poolPriceE18,
        uint64 snapshotBlock,
        bool increasePrice
    );
    event WindowFinalized(uint256 indexed windowId, address indexed winner, uint256 winningBid, uint64 permitNonce);
    event PermitConsumed(uint256 indexed windowId, address indexed winner, uint256 amountIn, uint256 amountOut);
    event WindowCorrected(uint256 indexed windowId, uint64 indexed callbackNonce);
    event WindowExpired(uint256 indexed windowId, address indexed bidder, uint256 refundedBid);

    constructor(
        ILpRewardVault vault_,
        address callbackProxy_,
        address expectedRvmId_,
        uint16 divergenceThresholdBps_,
        uint64 auctionDuration_,
        uint64 executionDuration_,
        uint256 maximumInput_
    ) {
        if (
            address(vault_) == address(0) || callbackProxy_ == address(0) || divergenceThresholdBps_ == 0
                || auctionDuration_ == 0 || executionDuration_ == 0 || maximumInput_ == 0
        ) revert Unauthorized();
        owner = msg.sender;
        vault = vault_;
        callbackProxy = callbackProxy_;
        expectedRvmId = expectedRvmId_;
        divergenceThresholdBps = divergenceThresholdBps_;
        auctionDuration = auctionDuration_;
        executionDuration = executionDuration_;
        maximumInput = maximumInput_;
    }

    function setExpectedRvmId(address rvmId_) external {
        if (msg.sender != owner || expectedRvmId != address(0) || rvmId_ == address(0)) revert Unauthorized();
        expectedRvmId = rvmId_;
        emit ExpectedRvmIdSet(rvmId_);
    }

    function setHook(address hook_) external {
        if (msg.sender != owner || hook != address(0) || hook_ == address(0)) revert Unauthorized();
        hook = hook_;
        emit HookSet(hook_);
    }

    function setAuction(IRebalanceAuction auction_) external {
        if (msg.sender != owner || address(auction) != address(0) || address(auction_) == address(0)) revert Unauthorized();
        auction = auction_;
        emit AuctionSet(address(auction_));
    }

    function recordPoolObservation(bytes32 poolId, uint160 priceE18, int24 tick) external {
        if (msg.sender != hook || priceE18 == 0) revert Unauthorized();
        latestPoolPriceE18[poolId] = priceE18;
        emit PoolObserved(poolId, priceE18, tick, uint64(block.number));
    }

    /// @dev Reactive injects the RVM identity as the first callback argument.
    function openWindow(
        address rvmId,
        bytes32 poolId,
        uint160 referencePriceE18,
        uint64 referenceSequence,
        uint64 callbackNonce
    ) external returns (uint256 windowId) {
        _authenticateCallback(rvmId, callbackNonce);
        uint160 poolPrice = latestPoolPriceE18[poolId];
        if (poolPrice == 0 || activeWindowForPool[poolId] != 0 || address(auction) == address(0)) revert InvalidState();
        uint256 divergence = _difference(referencePriceE18, poolPrice) * BPS / poolPrice;
        if (divergence < divergenceThresholdBps) revert BelowThreshold();

        windowId = ++nextWindowId;
        uint64 snapshotBlock = uint64(block.number);
        uint256 snapshotSupply = vault.totalSupplyAt(snapshotBlock);
        if (snapshotSupply == 0) revert InvalidState();
        bool increasePrice = referencePriceE18 > poolPrice;
        windows[windowId] = Window({
            poolId: poolId,
            referencePriceE18: referencePriceE18,
            openingPoolPriceE18: poolPrice,
            priceGuardE18: referencePriceE18,
            referenceSequence: referenceSequence,
            openedAt: uint64(block.timestamp),
            bidDeadline: uint64(block.timestamp) + auctionDuration,
            executionDeadline: 0,
            snapshotBlock: snapshotBlock,
            permitNonce: 0,
            snapshotSupply: snapshotSupply,
            winningBid: 0,
            maximumInput: maximumInput,
            winner: address(0),
            increasePrice: increasePrice,
            state: WindowState.Open
        });
        activeWindowForPool[poolId] = windowId;
        emit WindowOpened(windowId, poolId, referencePriceE18, poolPrice, snapshotBlock, increasePrice);
    }

    function biddingOpen(uint256 windowId) external view returns (bool) {
        Window storage window = windows[windowId];
        return window.state == WindowState.Open && block.timestamp < window.bidDeadline;
    }

    function finalizeWindow(uint256 windowId) external {
        Window storage window = windows[windowId];
        if (window.state != WindowState.Open) revert InvalidState();
        if (block.timestamp < window.bidDeadline) revert DeadlineNotReached();
        (address winner, uint256 winningBid) = auction.finalize(windowId);
        if (winner == address(0)) {
            window.state = WindowState.Expired;
            activeWindowForPool[window.poolId] = 0;
            emit WindowExpired(windowId, address(0), 0);
            return;
        }
        window.winner = winner;
        window.winningBid = winningBid;
        window.permitNonce = uint64(windowId);
        window.executionDeadline = uint64(block.timestamp) + executionDuration;
        window.state = WindowState.Finalized;
        emit WindowFinalized(windowId, winner, winningBid, window.permitNonce);
    }

    /// @notice Called only by the hook after its protected router authenticates the winner.
    function consumePermit(
        bytes32 poolId,
        uint256 windowId,
        uint64 permitNonce,
        address winner,
        bool increasePrice,
        uint256 amountIn,
        uint160 newPrice
    ) external {
        if (msg.sender != hook) revert Unauthorized();
        Window storage window = windows[windowId];
        if (window.state == WindowState.Consumed) revert PermitAlreadyUsed();
        if (!this.permitValid(poolId, windowId, permitNonce, winner, increasePrice, amountIn)) revert PermitInvalid();
        if (
            (increasePrice && (newPrice <= window.openingPoolPriceE18 || newPrice > window.priceGuardE18))
                || (!increasePrice && (newPrice >= window.openingPoolPriceE18 || newPrice < window.priceGuardE18))
        ) revert PriceGuardFailed();

        window.state = WindowState.Consumed;
        uint256 released = auction.releaseToVault(windowId);
        vault.allocateReward(windowId, released, window.snapshotBlock, window.snapshotSupply);
        emit PermitConsumed(windowId, winner, amountIn, 0);
    }

    function permitValid(bytes32 poolId, uint256 windowId, uint64 permitNonce, address winner, bool increasePrice, uint256 amountIn)
        external view returns (bool)
    {
        Window storage window = windows[windowId];
        return window.state == WindowState.Finalized && window.poolId == poolId && window.permitNonce == permitNonce
            && window.winner == winner && window.increasePrice == increasePrice && amountIn <= window.maximumInput
            && block.timestamp <= window.executionDeadline;
    }

    function markCorrected(address rvmId, uint256 windowId, uint64 callbackNonce) external {
        _authenticateCallback(rvmId, callbackNonce);
        Window storage window = windows[windowId];
        if (window.state != WindowState.Consumed) revert InvalidState();
        window.state = WindowState.Closed;
        activeWindowForPool[window.poolId] = 0;
        emit WindowCorrected(windowId, callbackNonce);
    }

    /// @notice Permissionless expiry prevents the demo from depending on Reactive cron delivery.
    function expireWindow(uint256 windowId) external {
        Window storage window = windows[windowId];
        if (window.state == WindowState.Open) {
            if (block.timestamp < window.bidDeadline) revert DeadlineNotReached();
        } else if (window.state == WindowState.Finalized) {
            if (block.timestamp <= window.executionDeadline) revert DeadlineNotReached();
        } else {
            revert InvalidState();
        }
        address bidder = window.winner;
        uint256 bid = window.winningBid;
        window.state = WindowState.Expired;
        activeWindowForPool[window.poolId] = 0;
        auction.refundExpired(windowId);
        emit WindowExpired(windowId, bidder, bid);
    }

    function getWindow(uint256 windowId) external view returns (Window memory) {
        return windows[windowId];
    }

    function _authenticateCallback(address rvmId, uint64 callbackNonce) private {
        if (msg.sender != callbackProxy || rvmId == address(0) || rvmId != expectedRvmId) revert Unauthorized();
        if (callbackNonceUsed[callbackNonce]) revert CallbackAlreadyUsed();
        callbackNonceUsed[callbackNonce] = true;
    }

    function _difference(uint160 first, uint160 second) private pure returns (uint256) {
        return first > second ? uint256(first - second) : uint256(second - first);
    }
}
