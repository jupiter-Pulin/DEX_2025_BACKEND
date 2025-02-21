// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IDexRouter {
    /**
     * @notice 添加两种代币到流动性池中
     * @param _amountADesired 第一个代币希望的最大数量
     * @param _amountBDesired 第二个代币希望的数量
     * @param _amountAMin 第一个代币所接受的最小数量
     * @param _amountBMin 第二个代币所接收的最小数量
     * @param _tokenA 第一个代币的地址
     * @param _tokenB 第二个代币的地址
     * @param deadline 交易截止时间
     * @return liquidity 添加的流动性数量
     */
    function addLiquidity(
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _tokenA,
        address _tokenB,
        uint256 deadline
    ) external payable returns (uint256 liquidity);

    /**
     * @notice 添加ETH和另一种代币到流动性池中
     * @param _amountBDesired 第二个代币希望的数量
     * @param _amountEthMin ETH所接受的最小数量
     * @param _amountBMin 第二个代币所接收的最小数量
     * @param _token 第二个代币的地址
     * @param deadline 交易截止时间
     * @return liquidity 添加的流动性数量
     */
    function addLiquidityETH(
        uint256 _amountBDesired,
        uint256 _amountEthMin,
        uint256 _amountBMin,
        address _token,
        uint256 deadline
    ) external payable returns (uint256 liquidity);

    /**
     * @notice 从流动性池中移除指定数量的流动性
     * @param _liquidity 要移除的流动性数量
     * @param _tokenA 第一个代币的地址
     * @param _tokenB 第二个代币的地址
     * @param to 接收移除的代币的地址
     * @return amountA 移除的第一个代币的数量
     * @return amountB 移除的第二个代币的数量
     * @return latestLiquidity 移除后的剩余流动性数量
     */
    function removeLiquidity(
        uint256 _liquidity,
        address _tokenA,
        address _tokenB,
        address to
    )
        external
        returns (uint256 amountA, uint256 amountB, uint256 latestLiquidity);

    /**
     * @notice 从流动性池中移除指定数量的ETH和另一种代币的流动性
     * @param _liquidity 要移除的流动性数量
     * @param _token 另一种代币的地址
     * @param to 接收移除的代币的地址
     * @return amountToken 移除的另一种代币的数量
     * @return amountETH 移除的ETH的数量
     * @return latestLiquidity 移除后的剩余流动性数量
     */
    function removeLiquidityETH(
        uint256 _liquidity,
        address _token,
        address to
    )
        external
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 latestLiquidity
        );

    /**
     * @notice 用指定数量的代币交换其他代币
     * @param amountIn 输入的代币数量
     * @param amountOutMin 期望的最小输出代币数量
     * @param path 交换路径，即代币地址数组
     * @param to 接收交换后的代币的地址
     * @param deadline 交易截止时间
     */
    function swapExactTokenForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    /**
     * @notice 用指定数量的ETH交换其他代币
     * @param amountOutMin 期望的最小输出代币数量
     * @param path 交换路径，即代币地址数组
     * @param to 接收交换后的代币的地址
     * @param deadline 交易截止时间
     */
    function swapExactEthForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    /**
     * @notice 获取WETH的地址
     * @return WETH的地址
     */
    function getWethAddress() external view returns (address);

    /**
     * @notice 获取工厂合约的地址
     * @return 工厂合约的地址
     */
    function getFactoryAddress() external view returns (address);

    /**
     * @notice 获取指定代币对的交易对地址
     * @param tokenA 第一个代币的地址
     * @param tokenB 第二个代币的地址
     * @return 交易对的地址
     */
    function getPairAddress(
        address tokenA,
        address tokenB
    ) external view returns (address);

    function getAmountsOut(
        uint amountIn,
        address[] memory path
    ) external view returns (uint[] memory amounts);
}
