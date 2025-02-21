// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {DexFactory} from "../../src/DexFactory.sol";
import {ERC20Mock} from "../mock/ERC20Mock.sol";
import {HelperConfig} from "../../script/HelperConfig.sol";
import {DexRouter} from "../../src/DexRouter.sol";
import {DexTotalLibraries} from "../../src/libraries/DexTotalLibraries.sol";

contract TestSwap is Test {
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
        ERC20Mock(weth).mint(user, 100 ether);
        ERC20Mock(wbtc).mint(user, 100 ether);
        ERC20Mock(wsol).mint(user, 100 ether);
        router = new DexRouter(address(factory), weth);

        vm.deal(user, 10 ether);
        uint256 amountADesired = 1e18;
        uint256 amountBDesired = 2e18;
        uint256 amountAMin = 1;
        uint256 amountBMin = 1;
        uint256 deadline = block.timestamp;
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(router), 10 ether);
        ERC20Mock(wbtc).approve(address(router), 10 ether);
        ERC20Mock(wsol).approve(address(router), 10 ether);
        uint256 liquidity = router.addLiquidity({
            _amountADesired: amountADesired,
            _amountBDesired: amountBDesired,
            _amountAMin: amountAMin,
            _amountBMin: amountBMin,
            _tokenA: weth,
            _tokenB: wbtc,
            deadline: deadline
        });
        console.log("liquidity", liquidity);
        uint256 liquidity2 = router.addLiquidity({
            _amountADesired: 3e18,
            _amountBDesired: 9e18,
            _amountAMin: amountAMin,
            _amountBMin: amountBMin,
            _tokenA: wbtc,
            _tokenB: wsol,
            deadline: deadline
        });
        console.log("liquidity2", liquidity2);
    }

    /////////////////////////////////////
    //         swapexactTokenForTokens //
    /////////////////////////////////////
    function testSwapExactTokenForTokens() public {
        uint256 deadline = block.timestamp;
        uint256 amountIn = 1e18;
        uint256 amountOutMin = 1;
        address[] memory path = new address[](3);
        path[0] = weth;
        path[1] = wbtc;
        path[2] = wsol;

        vm.startPrank(user);
        console.log("has been called swapExactTokenForTokens");
        console.log("swaping ! ETH amountIn", amountIn);

        router.swapExactTokenForTokens({
            amountIn: amountIn,
            amountOutMin: amountOutMin,
            path: path,
            to: user,
            deadline: deadline
        });

        console.log("SOL amountOut", ERC20Mock(wsol).balanceOf(user));
    }

    /////////////////////////////////////
    //         swapETHForTokens        //
    /////////////////////////////////////
    function testSwapExactEthForTokens() public {
        uint256 deadline = block.timestamp;
        uint256 amountIn = 1e18;
        uint256 amountOutMin = 1;
        address[] memory path = new address[](3);
        path[0] = weth;
        path[1] = wbtc;
        path[2] = wsol;
        vm.startPrank(user);
        console.log("has been called swapExactEthForTokens");
        console.log("swaping! ETH amountIn", amountIn);
        console.log("SOL amountOut", ERC20Mock(wsol).balanceOf(user));
        router.swapExactEthForTokens{value: amountIn}({
            amountOutMin: amountOutMin,
            path: path,
            to: user,
            deadline: deadline
        });
        console.log("SOL amountOut", ERC20Mock(wsol).balanceOf(user));
    }
}
