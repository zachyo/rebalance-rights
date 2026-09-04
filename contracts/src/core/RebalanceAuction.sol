// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "../interfaces/IRR.sol";

interface IWindowState { function biddingOpen(uint256 windowId) external view returns (bool); }

/// @notice Open ascending auction with pull refunds. Winning collateral stays escrowed until correction succeeds.
contract RebalanceAuction {
    error Unauthorized();
    error BidTooLow();
    error AuctionClosed();
    error AlreadyFinalized();
    error TransferFailed();
    error NothingToWithdraw();

    struct Bid { address bidder; uint256 amount; bool settled; }
    IERC20 public immutable bidToken;
    address public immutable controller;
    address public immutable vault;
    mapping(uint256 => Bid) public highBid;
    mapping(address => uint256) public refundable;

    event BidPlaced(uint256 indexed windowId, address indexed bidder, uint256 amount);
    event OutbidRefundCredited(uint256 indexed windowId, address indexed bidder, uint256 amount);
    event WinningBidReleased(uint256 indexed windowId, address indexed winner, uint256 amount);
    event ExpiredBidRefunded(uint256 indexed windowId, address indexed winner, uint256 amount);
    event RefundWithdrawn(address indexed bidder, uint256 amount);

    constructor(IERC20 bidToken_, address controller_, address vault_) {
        if (address(bidToken_) == address(0) || controller_ == address(0) || vault_ == address(0)) revert Unauthorized();
        bidToken = bidToken_;
        controller = controller_;
        vault = vault_;
    }

    function bid(uint256 windowId, uint256 amount) external {
        if (!IWindowState(controller).biddingOpen(windowId)) revert AuctionClosed();
        Bid storage current = highBid[windowId];
        if (amount <= current.amount) revert BidTooLow();
        if (!bidToken.transferFrom(msg.sender, address(this), amount)) revert TransferFailed();
        if (current.amount != 0) {
            refundable[current.bidder] += current.amount;
            emit OutbidRefundCredited(windowId, current.bidder, current.amount);
        }
        highBid[windowId] = Bid({bidder: msg.sender, amount: amount, settled: false});
        emit BidPlaced(windowId, msg.sender, amount);
    }

    function finalize(uint256 windowId) external returns (address winner, uint256 amount) {
        if (msg.sender != controller) revert Unauthorized();
        Bid storage current = highBid[windowId];
        if (current.settled) revert AlreadyFinalized();
        current.settled = true;
        return (current.bidder, current.amount);
    }

    function releaseToVault(uint256 windowId) external returns (uint256 amount) {
        if (msg.sender != controller) revert Unauthorized();
        Bid storage current = highBid[windowId];
        if (!current.settled || current.amount == 0) revert AuctionClosed();
        amount = current.amount;
        current.amount = 0;
        if (!bidToken.transfer(vault, amount)) revert TransferFailed();
        emit WinningBidReleased(windowId, current.bidder, amount);
    }

    function refundExpired(uint256 windowId) external {
        if (msg.sender != controller) revert Unauthorized();
        Bid storage current = highBid[windowId];
        if (current.amount != 0) {
            uint256 amount = current.amount;
            current.amount = 0;
            refundable[current.bidder] += amount;
            emit ExpiredBidRefunded(windowId, current.bidder, amount);
        }
    }

    function withdrawRefund() external {
        uint256 amount = refundable[msg.sender];
        if (amount == 0) revert NothingToWithdraw();
        refundable[msg.sender] = 0;
        if (!bidToken.transfer(msg.sender, amount)) revert TransferFailed();
        emit RefundWithdrawn(msg.sender, amount);
    }
}
