// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "../interfaces/IRR.sol";

/// @notice Managed LP share vault with block checkpoints for snapshot-indexed auction rewards.
contract LpRewardVault {
    uint256 private constant INDEX_SCALE = 1e18;

    error Unauthorized();
    error InvalidAmount();
    error AlreadyAllocated();
    error AlreadyClaimed();
    error TransferFailed();

    struct Checkpoint { uint64 fromBlock; uint192 value; }
    struct Reward { uint256 index; uint256 amount; uint64 snapshotBlock; bool allocated; }

    address public immutable owner;
    IERC20 public immutable liquidityToken;
    IERC20 public immutable bidToken;
    address public controller;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => Checkpoint[]) private accountCheckpoints;
    Checkpoint[] private supplyCheckpoints;
    mapping(uint256 => Reward) public rewards;
    mapping(uint256 => mapping(address => bool)) public claimed;

    event ControllerSet(address indexed controller);
    event Deposited(address indexed lp, uint256 shares);
    event Withdrawn(address indexed lp, uint256 shares);
    event RewardAllocated(uint256 indexed windowId, uint256 amount, uint64 snapshotBlock, uint256 snapshotSupply);
    event RewardClaimed(uint256 indexed windowId, address indexed lp, uint256 amount);

    modifier onlyController() {
        if (msg.sender != controller) revert Unauthorized();
        _;
    }

    constructor(IERC20 liquidityToken_, IERC20 bidToken_) {
        if (address(liquidityToken_) == address(0) || address(bidToken_) == address(0)) revert Unauthorized();
        owner = msg.sender;
        liquidityToken = liquidityToken_;
        bidToken = bidToken_;
    }

    function setController(address controller_) external {
        if (msg.sender != owner || controller != address(0) || controller_ == address(0)) revert Unauthorized();
        controller = controller_;
        emit ControllerSet(controller_);
    }

    function deposit(uint256 shares) external {
        if (shares == 0) revert InvalidAmount();
        if (!liquidityToken.transferFrom(msg.sender, address(this), shares)) revert TransferFailed();
        balanceOf[msg.sender] += shares;
        totalSupply += shares;
        _write(accountCheckpoints[msg.sender], balanceOf[msg.sender]);
        _write(supplyCheckpoints, totalSupply);
        emit Deposited(msg.sender, shares);
    }

    function withdraw(uint256 shares) external {
        if (shares == 0 || balanceOf[msg.sender] < shares) revert InvalidAmount();
        balanceOf[msg.sender] -= shares;
        totalSupply -= shares;
        _write(accountCheckpoints[msg.sender], balanceOf[msg.sender]);
        _write(supplyCheckpoints, totalSupply);
        if (!liquidityToken.transfer(msg.sender, shares)) revert TransferFailed();
        emit Withdrawn(msg.sender, shares);
    }

    function balanceOfAt(address account, uint64 blockNumber) public view returns (uint256) {
        return _lookup(accountCheckpoints[account], blockNumber);
    }

    function totalSupplyAt(uint64 blockNumber) external view returns (uint256) {
        return _lookup(supplyCheckpoints, blockNumber);
    }

    function allocateReward(uint256 windowId, uint256 amount, uint64 snapshotBlock, uint256 snapshotSupply)
        external onlyController
    {
        if (rewards[windowId].allocated || amount == 0 || snapshotSupply == 0) revert AlreadyAllocated();
        rewards[windowId] = Reward({
            index: amount * INDEX_SCALE / snapshotSupply,
            amount: amount,
            snapshotBlock: snapshotBlock,
            allocated: true
        });
        emit RewardAllocated(windowId, amount, snapshotBlock, snapshotSupply);
    }

    function claim(uint256 windowId) external returns (uint256 amount) {
        Reward memory reward = rewards[windowId];
        if (!reward.allocated || claimed[windowId][msg.sender]) revert AlreadyClaimed();
        claimed[windowId][msg.sender] = true;
        amount = balanceOfAt(msg.sender, reward.snapshotBlock) * reward.index / INDEX_SCALE;
        if (amount != 0 && !bidToken.transfer(msg.sender, amount)) revert TransferFailed();
        emit RewardClaimed(windowId, msg.sender, amount);
    }

    function _write(Checkpoint[] storage checkpoints, uint256 value) private {
        uint64 currentBlock = uint64(block.number);
        uint256 length = checkpoints.length;
        if (length != 0 && checkpoints[length - 1].fromBlock == currentBlock) {
            checkpoints[length - 1].value = uint192(value);
        } else {
            checkpoints.push(Checkpoint({fromBlock: currentBlock, value: uint192(value)}));
        }
    }

    function _lookup(Checkpoint[] storage checkpoints, uint64 blockNumber) private view returns (uint256) {
        uint256 length = checkpoints.length;
        if (length == 0 || checkpoints[0].fromBlock > blockNumber) return 0;
        uint256 low;
        uint256 high = length;
        while (low < high) {
            uint256 middle = (low + high) / 2;
            if (checkpoints[middle].fromBlock <= blockNumber) low = middle + 1;
            else high = middle;
        }
        return checkpoints[low - 1].value;
    }
}
