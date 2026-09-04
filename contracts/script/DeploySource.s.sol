// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {MockReferenceMarket} from "../src/mocks/MockReferenceMarket.sol";

contract DeploySource is Script {
    function run() external returns (address) {
        address operator = vm.envAddress("REFERENCE_OPERATOR");
        vm.startBroadcast();
        MockReferenceMarket market = new MockReferenceMarket(operator);
        vm.stopBroadcast();
        return address(market);
    }
}
