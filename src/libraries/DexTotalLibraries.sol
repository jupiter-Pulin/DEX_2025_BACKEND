// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {DexFactory} from "../DexFactory.sol";
import {DexPair} from "../DexPair.sol";

/**
 * @title DexTotalLibraries
 * @dev 去中心化交易所核心工具库
 * 提供以下功能：
 * - 安全代币转账
 * - 代币地址/金额排序
 * - 交易路径计算
 * - 交换金额计算（含手续费）
 */
library DexTotalLibraries {
    error DexRouter__AmountAIsZero();
    error DexRouter__TheLiquidityPoolIsEmpty();
    error DexRouter__InvalidAddress();
    error DEXRouter__LessThanYourAccept(uint256);
    error DexRouter__PathShouldMoreThanTwo();
    error DEXRouter__TransferFailed(uint256 userBal, uint256 amountToTransfer);

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) external {
        bool success = IERC20(token).transferFrom(from, to, amount);
        if (!success) {
            revert DEXRouter__TransferFailed(
                IERC20(token).balanceOf(from),
                amount
            );
        }
    }

    /**
     * @dev 代币地址排序（确保 tokenA < tokenB）
     * @param _tokenA 代币A地址
     * @param _tokenB 代币B地址
     * @return (token0, token1) 排序后的地址
     * 用途：创建交易对时保证地址顺序一致
     */
    function sortToken(
        address _tokenA,
        address _tokenB
    ) internal pure returns (address, address) {
        (address tokenA, address tokenB) = _tokenA < _tokenB
            ? (_tokenA, _tokenB)
            : (_tokenB, _tokenA);
        return (tokenA, tokenB);
    }

    /**
     * @dev 代币金额排序（与地址排序匹配）
     * @param _amountADesired 代币A期望金额
     * @param _amountBDesired 代币B期望金额
     * @param _tokenA 原始代币A地址
     * @param tokenA 排序后的代币A地址
     */
    function sortAmount(
        uint256 _amountADesired,
        uint256 _amountBDesired,
        address _tokenA,
        address tokenA
    ) internal pure returns (uint256 amountADesired, uint256 amountBDesired) {
        (amountADesired, amountBDesired) = tokenA == _tokenA
            ? (_amountADesired, _amountBDesired)
            : (_amountBDesired, _amountADesired);
    }

    /**
     * @dev 根据储备比例计算理论输出金额
     * @param amountA 输入代币A数量
     * @param reserveA 代币A的储备量
     * @param reserveB 代币B的储备量
     * @return amountB 理论输出代币B数量
     * 公式：amountB = (amountA * reserveB) / reserveA
     */
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        if (amountA == 0) revert DexRouter__AmountAIsZero();
        if (reserveA == 0 && reserveB == 0)
            revert DexRouter__TheLiquidityPoolIsEmpty();
        uint256 numerator = amountA * reserveB;
        uint256 denominator = reserveA;
        amountB = numerator / denominator;
    }

    /**
     * @dev 计算实际输出金额（含 0.3% 手续费）
     * @param amountIn 输入代币数量
     * @param reserveIn 输入代币储备量
     * @param reserveOut 输出代币储备量
     * @return amountOut 实际输出代币数量
     * 公式：amountOut = (amountIn * 997 * reserveOut) / (reserveIn * 1000 + amountIn * 997)
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        if (amountIn == 0) revert DexRouter__AmountAIsZero();
        if (reserveIn == 0 && reserveOut == 0)
            revert DexRouter__TheLiquidityPoolIsEmpty();
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    /**
     * @dev 计算交易路径中各步骤的输出金额
     * @param path 代币路径（如 [USDT, WETH, DAI]）
     * @param amountIn 输入金额
     * @param amountOutMin 最小可接受输出金额
     * @param factory 工厂合约地址
     * @return amounts 各步骤的输入/输出金额数组
     * 注意：会验证最终输出是否满足 amountOutMin
     */
    function getAmountsOut(
        address[] memory path,
        uint256 amountIn,
        uint256 amountOutMin,
        address factory
    ) internal view returns (uint256[] memory amounts) {
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;

        amounts = checkReserveIsCorrect(path, amounts, factory);

        if (amounts[path.length - 1] < amountOutMin) {
            revert DEXRouter__LessThanYourAccept(amounts[path.length - 1]);
        }

        return amounts;
    }

    /**
     * @dev 遍历交易路径验证储备并计算金额
     * @param path 代币路径
     * @param amounts 金额数组（会被修改）
     * @param factory 工厂合约地址
     * @return 更新后的金额数组
     * 核心逻辑：
     * 1. 检查每个交易对是否存在
     * 2. 获取储备量并按地址排序
     * 3. 逐步计算每个交易对的输出金额
     */
    function checkReserveIsCorrect(
        address[] memory path,
        uint256[] memory amounts,
        address factory
    ) internal view returns (uint256[] memory) {
        for (uint256 i = 0; i < path.length - 1; i++) {
            address input = path[i];
            address output = path[i + 1];
            address pairAddr = DexFactory(factory).getPairAddress(
                input,
                output
            );
            if (pairAddr == address(0)) revert DexRouter__InvalidAddress();

            (uint256 reserve0, uint256 reserve1) = DexPair(pairAddr)
                .getReserve();
            (address token0, ) = sortToken(input, output);

            uint256 reserveIn;
            uint256 reserveOut;
            if (input == token0) {
                reserveIn = reserve0;
                reserveOut = reserve1;
            } else {
                reserveIn = reserve1;
                reserveOut = reserve0;
            }

            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
        return amounts;
    }
}
