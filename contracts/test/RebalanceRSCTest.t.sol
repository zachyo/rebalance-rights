// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IReactive} from "reactive-lib/interfaces/IReactive.sol";
import {RebalanceRSC} from "../src/reactive/RebalanceRSC.sol";

/// @notice Exercises Reactive event matching and source-sequence deduplication without external testnet delivery.
contract RebalanceRSCTest {
    uint256 private constant SOURCE_CHAIN = 84532;
    uint256 private constant DESTINATION_CHAIN = 1301;
    address private constant REFERENCE = address(0x1001);
    address private constant HOOK = address(0x1002);
    address private constant CONTROLLER = address(0x1003);
    bytes32 private constant PAIR = keccak256("ETH-USDC");
    bytes32 private constant POOL = keccak256("POOL");

    function test_ReferenceAndPoolEventsOpenOneReactiveWindow() public {
        RebalanceRSC rsc = new RebalanceRSC(
            SOURCE_CHAIN, DESTINATION_CHAIN, REFERENCE, HOOK, CONTROLLER, PAIR, POOL, 100, 500_000
        );
        rsc.react(_poolLog(2_000e18, 1));
        rsc.react(_referenceLog(2_120e18, 1, 9));
        require(rsc.windowOpen(), "dislocation did not open RSC window");
        require(rsc.latestReferenceSequence() == 1, "reference sequence was not stored");
        require(rsc.nextCallbackNonce() == 1, "callback was not requested");

        rsc.react(_referenceLog(2_120e18, 1, 9));
        require(rsc.nextCallbackNonce() == 1, "duplicate source log requested another callback");
    }

    function _poolLog(uint160 priceX96, uint256 logIndex) private pure returns (IReactive.LogRecord memory) {
        return IReactive.LogRecord({
            chain_id: DESTINATION_CHAIN,
            _contract: HOOK,
            topic_0: uint256(keccak256("PoolObserved(bytes32,uint160,int24,uint64)")),
            topic_1: uint256(POOL),
            topic_2: 0,
            topic_3: 0,
            data: abi.encode(priceX96, int24(0), uint64(1)),
            block_number: 1,
            op_code: 0,
            block_hash: 0,
            tx_hash: 8,
            log_index: logIndex
        });
    }

    function _referenceLog(uint160 priceX96, uint64 sequence, uint256 logIndex)
        private pure returns (IReactive.LogRecord memory)
    {
        return IReactive.LogRecord({
            chain_id: SOURCE_CHAIN,
            _contract: REFERENCE,
            topic_0: uint256(keccak256("ReferencePriceUpdated(bytes32,uint160,uint64)")),
            topic_1: uint256(PAIR),
            topic_2: 0,
            topic_3: 0,
            data: abi.encode(priceX96, sequence),
            block_number: 1,
            op_code: 0,
            block_hash: 0,
            tx_hash: 9,
            log_index: logIndex
        });
    }
}
