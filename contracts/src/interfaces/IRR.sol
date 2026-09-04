// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IRebalanceAuction {
    function finalize(uint256 windowId) external returns (address winner, uint256 amount);
    function releaseToVault(uint256 windowId) external returns (uint256 amount);
    function refundExpired(uint256 windowId) external;
}

interface ILpRewardVault {
    function totalSupplyAt(uint64 blockNumber) external view returns (uint256);
    function allocateReward(uint256 windowId, uint256 amount, uint64 snapshotBlock, uint256 snapshotSupply) external;
}

interface IRebalanceController {
    function consumePermit(bytes32 poolId, uint256 windowId, uint64 permitNonce, address winner, bool increasePrice, uint256 amountIn, uint160 newPrice) external;
    function permitValid(bytes32 poolId, uint256 windowId, uint64 permitNonce, address winner, bool increasePrice, uint256 amountIn) external view returns (bool);
    function recordPoolObservation(bytes32 poolId, uint160 priceE18, int24 tick) external;
}
