// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Script} from "forge-std/Script.sol";
import {DexFactory} from "../../src/DexFactory.sol";
import {DexPair} from "../src/DexPair.sol";
import {DexRouter} from "../src/DexRouter.sol";
import {ERC20Mock} from "../test/mock/ERC20Mock.sol";

contract DeployDEX is Script {
    ERC20Mock public weth;
    address private sepoliaWethAddr =
        0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14;

    function run() external returns (DexFactory, DexRouter) {
        vm.startBroadcast();
        DexFactory dexFactory = new DexFactory(msg.sender);
        DexRouter dexRouter = new DexRouter(
            address(dexFactory),
            sepoliaWethAddr
        );
        vm.stopBroadcast();
        return (dexFactory, dexRouter);
    }
}
