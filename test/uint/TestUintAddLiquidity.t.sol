// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {DexFactory} from "../../src/DexFactory.sol";
import {ERC20Mock} from "../mock/ERC20Mock.sol";
import {HelperConfig} from "../../script/HelperConfig.sol";
import {DexRouter} from "../../src/DexRouter.sol";
import {DexTotalLibraries} from "../../src/libraries/DexTotalLibraries.sol";

contract TestUintAddliquidity is Test {
    DexFactory factory;
    DexRouter router;

    address user = address(1);
    HelperConfig config;
    address weth;
    address wbtc;
    address wsol;

    function setUp() external {
        factory = new DexFactory(user);
        config = new HelperConfig();
        (weth, wbtc, wsol) = config.getNetWorkConfig();
        ERC20Mock(weth).mint(user, 10 ether);
        ERC20Mock(wbtc).mint(user, 10 ether);
        ERC20Mock(wsol).mint(user, 10 ether);
        router = new DexRouter(address(factory), weth);

        vm.deal(user, 10 ether);
    }

    function testSortToken() public {
        (weth, wsol) = weth < wsol ? (weth, wsol) : (wsol, weth);
        (address actualTokenA, ) = DexTotalLibraries.sortToken(weth, wsol);
        if (weth < wsol) {
            assertEq(actualTokenA, weth);
        } else {
            assertEq(actualTokenA, wsol);
        }
    }

    function testSortAmountAndToken() public {
        uint256 _amountADesired = 5e18;
        uint256 _amountBDesired = 9e18;
        (weth, wsol) = weth < wsol ? (weth, wsol) : (wsol, weth);
        (address actualTokenA, ) = DexTotalLibraries.sortToken(weth, wsol);

        // (uint256 amountADesired, uint256 amountBDesired) = actualTokenA == weth
        //     ? (_amountADesired, _amountBDesired)
        //     : (_amountBDesired, _amountADesired);
        (uint256 amountADesired, uint256 amountBDesired) = DexTotalLibraries
            .sortAmount(_amountADesired, _amountBDesired, weth, actualTokenA);

        if (weth < wsol) {
            assertEq(_amountADesired, amountADesired);
        } else {
            assertEq(_amountADesired, amountBDesired);
        }
    }
}
