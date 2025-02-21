// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Script} from "forge-std/Script.sol";
import {DexFactory} from "../../src/DexFactory.sol";
import {ERC20Mock} from "../test/mock/ERC20Mock.sol";

contract HelperConfig is Script {
    struct NetWorkConfig {
        address weth;
        address wbtc;
        address wsol;
    }
    NetWorkConfig config;

    function getNetWorkConfig() public returns (address, address, address) {
        ERC20Mock wethErc20Mock = new ERC20Mock(
            "WETH",
            "WETH",
            msg.sender,
            1e18
        );
        ERC20Mock wbtcErc20Mock = new ERC20Mock(
            "WBTC",
            "WBTC",
            msg.sender,
            1e18
        );
        ERC20Mock wsolErc20Mock = new ERC20Mock(
            "WSOL",
            "WSOL",
            msg.sender,
            1e18
        );
        address weth = address(wethErc20Mock);
        address wbtc = address(wbtcErc20Mock);
        address wsol = address(wsolErc20Mock);
        return (weth, wbtc, wsol);
    }
}
