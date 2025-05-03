// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {DexFactory} from "../../src/DexFactory.sol";
import {ERC20Mock} from "../mock/ERC20Mock.sol";
import {HelperConfig} from "../../script/HelperConfig.sol";
import {DexRouter} from "../../src/DexRouter.sol";
import {DexTotalLibraries} from "../../src/libraries/DexTotalLibraries.sol";

contract TestAddliquidity is Test {
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

    function testAddliquidithCanWork() public {
        uint256 amountADesired = 1e18;
        uint256 amountBDesired = 9e18;
        uint256 amountAMin = 1;
        uint256 amountBMin = 1;
        uint256 deadline = block.timestamp;
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(router), 10 ether);
        ERC20Mock(wbtc).approve(address(router), 9 ether);
        uint256 liquidity = router.addLiquidity(
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            weth,
            wbtc,
            deadline
        );
        console.log("liquidity", liquidity);
    }

    function testAddLiquidityEth() public {
        uint256 amountBDesired = 1e18;
        uint256 amountAMin = 1;
        uint256 amountBMin = 1;
        uint256 deadline = block.timestamp;
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(router), 10 ether);
        ERC20Mock(wbtc).approve(address(router), 10 ether);
        console.log("balance", ERC20Mock(weth).balanceOf(address(router)));
        uint256 liquidity = router.addLiquidityETH{value: 1 ether}({
            _amountBDesired: amountBDesired,
            _amountEthMin: amountAMin,
            _amountBMin: amountBMin,
            _token: wbtc,
            deadline: deadline
        });
        console.log("liquidity", liquidity);
        console.log("balance", ERC20Mock(weth).balanceOf(address(router)));
    }
}
