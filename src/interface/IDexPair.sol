// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IDexPair {
    ////////////////////////////
    //////    Errors      //////
    ////////////////////////////
    error DexPair__OnlyOwner();
    error DexPair__LiquidityIsNotEnough();
    error DexPair__InvalidSwap();

    ////////////////////////////
    //////    Events      //////
    ////////////////////////////
    event SharesMinted(address indexed to, uint256 indexed liquidity);
    event SuccessfulSwap(address indexed to, uint256 indexed amountOut);

    ////////////////////////////
    //////    Functions   //////
    ////////////////////////////

    /// @notice 初始化交易对（仅 Factory 可调用）
    function initialize(address tokenA, address tokenB) external;

    /// @notice 铸造流动性代币
    /// @param to LP 接收地址
    /// @return liquidity 铸造的流动性数量
    function mintShares(address to) external returns (uint256 liquidity);

    /// @notice 执行代币交换
    /// @param amountOut 期望输出的代币数量
    /// @param to 接收输出代币的地址
    /// @return 实际输出的代币数量
    function swap(uint256 amountOut, address to) external returns (uint256);

    /// @notice 销毁流动性代币（需优化实现）
    /// @param to 接收底层代币的地址
    /// @param liquidity 销毁的流动性数量
    /// @return amountA 需要返回给用户的 代币A 的数量
    /// @return amountB 需要返回给用户的 代币B 的数量
    function burnShares(
        address to,
        uint256 liquidity
    ) external returns (uint256 amountA, uint256 amountB);

    /// @notice 获取当前储备量
    /// @return reserveA 代币 A 储备量
    /// @return reserveB 代币 B 储备量
    function getReserve()
        external
        view
        returns (uint256 reserveA, uint256 reserveB);

    /////////////////////////////////
    //////   ERC20 标准接口   //////
    /////////////////////////////////
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
