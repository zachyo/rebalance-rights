// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {RebalanceRSC} from "../src/reactive/RebalanceRSC.sol";

/// @notice Deploy after the source and destination addresses are recorded in deployments/testnet.json.
contract DeployReactive is Script {
    function run() external returns (address) {
        vm.startBroadcast();
        RebalanceRSC rsc = new RebalanceRSC{value: 1 ether}(
            vm.envUint("SOURCE_CHAIN_ID"),
            vm.envUint("DESTINATION_CHAIN_ID"),
            vm.envAddress("REFERENCE_MARKET"),
            vm.envAddress("HOOK"),
            vm.envAddress("CONTROLLER"),
            vm.envBytes32("PAIR_ID"),
            vm.envBytes32("POOL_ID"),
            100,
            1_000_000
        );
        vm.stopBroadcast();
        return address(rsc);
    }
}
