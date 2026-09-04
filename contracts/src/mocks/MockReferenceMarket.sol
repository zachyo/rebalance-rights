// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/// @notice Controlled reference source for the testnet demo; it is not a production oracle.
contract MockReferenceMarket {
    error Unauthorized();

    address public immutable operator;
    mapping(bytes32 => uint160) public priceE18;
    mapping(bytes32 => uint64) public sequence;

    event ReferencePriceUpdated(bytes32 indexed pairId, uint160 priceE18, uint64 sequence);

    constructor(address operator_) {
        if (operator_ == address(0)) revert Unauthorized();
        operator = operator_;
    }

    function setPrice(bytes32 pairId, uint160 nextPriceE18) external {
        if (msg.sender != operator || nextPriceE18 == 0) revert Unauthorized();
        uint64 nextSequence = ++sequence[pairId];
        priceE18[pairId] = nextPriceE18;
        emit ReferencePriceUpdated(pairId, nextPriceE18, nextSequence);
    }
}
