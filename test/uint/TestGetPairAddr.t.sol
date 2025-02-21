// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {DexFactory} from "../../src/DexFactory.sol";
import {ERC20Mock} from "../mock/ERC20Mock.sol";
import {HelperConfig} from "../../script/HelperConfig.sol";

contract TestGetPairAddr is Test {
    DexFactory factory;
    address user = address(1);
    HelperConfig config;
    address weth;
    address wbtc;
    address wsol;

    //测试getPairAddr能否正确的映射合约的地址

    function setUp() external {
        factory = new DexFactory(user);
        config = new HelperConfig();
        (weth, wbtc, wsol) = config.getNetWorkConfig();

        vm.deal(user, 10 ether);
    }

    function testGetPairAddress() public {
        address actualPairAddr = factory.createPair(weth, wbtc);
        address expectpairAddr = factory.getPairAddress(weth, wbtc);
        assertEq(actualPairAddr, expectpairAddr);
    }

    function testGetPairAddressForSortToken() public {
        address pair = factory.createPair(weth, wbtc);
        console.log("pair addr:", pair);

        address expectpairAddr = factory.getPairAddress(weth, wbtc);
        console.log("expectpairAddr:", expectpairAddr);
        address actualPairAddr = factory.getPairAddress(wbtc, weth);
        console.log("actualPairAddr:", actualPairAddr);
        assertEq(actualPairAddr, expectpairAddr);
    }
}
