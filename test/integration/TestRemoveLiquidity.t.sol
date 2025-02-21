// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {DexFactory} from "../../src/DexFactory.sol";
import {ERC20Mock} from "../mock/ERC20Mock.sol";
import {HelperConfig} from "../../script/HelperConfig.sol";
import {DexRouter} from "../../src/DexRouter.sol";
import {DexTotalLibraries} from "../../src/libraries/DexTotalLibraries.sol";
import {DexPair} from "../../src/DexPair.sol";

contract TestRemoveLiquidity is Test {
    DexFactory factory;
    DexRouter router;

    address user = address(3);
    address alex = address(2);
    HelperConfig config;
    address weth;
    address wbtc;
    address wsol;
    uint256 liquidity;
    uint256 amountADesired;
    uint256 amountBDesired;
    uint256 amountAMin;
    uint256 amountBMin;
    uint256 deadline;

    function setUp() external {
        vm.deal(user, 10 ether);
        vm.deal(alex, 10 ether);
        vm.prank(alex);
        factory = new DexFactory(alex); //确保 msg.sender ==user
        config = new HelperConfig();

        (weth, wbtc, wsol) = config.getNetWorkConfig(); //get address
        router = new DexRouter(address(factory), weth);

        ERC20Mock(weth).mint(user, 10 ether);
        ERC20Mock(wbtc).mint(user, 10 ether);

        ERC20Mock(weth).mint(alex, 10 ether);
        ERC20Mock(wbtc).mint(alex, 10 ether);
    }

    modifier addLiquidity() {
        amountADesired = 1e18;
        amountBDesired = 1e18; //0.0307 *1e18=3e16
        amountAMin = 1;
        amountBMin = 1;
        deadline = block.timestamp;
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(router), 10 ether);
        ERC20Mock(wbtc).approve(address(router), 10 ether);
        liquidity = router.addLiquidity(
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            weth,
            wbtc,
            deadline
        );
        vm.stopPrank();
        console.log("liquidity", liquidity);
        _;
    }
    modifier addLiquidityEth() {
        amountBDesired = 1e18;
        amountAMin = 1;
        amountBMin = 1;
        deadline = block.timestamp;
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(router), 10 ether);
        ERC20Mock(wbtc).approve(address(router), 10 ether);
        liquidity = router.addLiquidityETH{value: 1 ether}({
            _amountBDesired: amountBDesired,
            _amountEthMin: amountAMin,
            _amountBMin: amountBMin,
            _token: wbtc,
            deadline: deadline
        });
        console.log("liquidity", liquidity);
        vm.stopPrank();
        _;
    }

    function testRemoveliquidithCanWork() public addLiquidity {
        //Arrange
        uint256 beforBalanceA = ERC20Mock(weth).balanceOf(user);
        uint256 beforBalanceB = ERC20Mock(wbtc).balanceOf(user);
        console.log("balanceA", beforBalanceA);
        console.log("balanceB", beforBalanceB);

        address pair = factory.getPairAddress(weth, wbtc);

        //Act
        vm.startPrank(user);
        DexPair(pair).approve(address(router), liquidity);

        router.removeLiquidity({
            _liquidity: liquidity,
            _tokenA: weth,
            _tokenB: wbtc,
            to: user
        });

        //Assert
        uint256 afterBalanceA = ERC20Mock(weth).balanceOf(user);
        uint256 afterBalanceB = ERC20Mock(wbtc).balanceOf(user);
        console.log("balanceA", afterBalanceA);
        console.log("balanceB", afterBalanceB);
        vm.stopPrank();
    }

    /**
     * addLiquidityEth 和 addLiquidity 因为都是一个weth的地址，所以测试一样
     */
    function testRemoveLiquidityEth() public addLiquidityEth {
        //Arrange
        uint256 beforBalanceA = ERC20Mock(weth).balanceOf(user);
        uint256 beforBalanceB = ERC20Mock(wbtc).balanceOf(user);
        console.log("balanceA", beforBalanceA);
        console.log("balanceB", beforBalanceB);

        address pair = factory.getPairAddress(weth, wbtc);

        //Act
        vm.startPrank(user);
        DexPair(pair).approve(address(router), liquidity);

        router.removeLiquidityETH({
            _liquidity: liquidity,
            _token: wbtc,
            to: user
        });

        //Assert
        uint256 afterBalanceA = ERC20Mock(weth).balanceOf(user) - 1e18;
        uint256 afterBalanceB = ERC20Mock(wbtc).balanceOf(user);
        console.log("FINbalanceA", afterBalanceA);
        console.log("FINbalanceB", afterBalanceB);
    }
}
