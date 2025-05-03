// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {Math} from "./libraries/Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title DexPair
 * @dev 自动化做市商（AMM）交易对合约
 * 功能包括：
 * - 流动性代币（LP）的铸造与销毁
 * - 代币交换
 * - 动态更新储备量
 * 注意：本合约需通过 DexFactory 合约部署和初始化
 */
contract DexPair is ERC20, ReentrancyGuard {
    //////////////////////////////////////////////////////////
    /////                      errors               //////////
    ////////////////////////////////////////////////////////////
    error DexPair__OnlyOwner();
    error DexPair__LiquidityIsNotEnough();
    error DexPair__InvalidSwap();
    error DexPair__transferFailed();

    //////////////////////////////////////////////////////////
    /////               State variables               //////////
    ////////////////////////////////////////////////////////////
    uint256 constant MIN_LIQUIDITY = 10 ** 3;
    uint256 s_reserveA;
    uint256 s_reserveB;
    address immutable i_factory;
    address public s_tokenA;
    address public s_tokenB;
    address s_owner;

    //////////////////////////////////////////////////////////////
    //////                         Events            ///////////
    /////////////////////////////////////////////////////////////////
    event SharesMinted(address indexed, uint256 indexed);
    event SuccessfulSwap(address indexed, uint256 indexed);
    event SharesBurned(address indexed, uint256);

    constructor() ERC20("PairPoolContract", "PPC") {
        i_factory = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != s_owner) revert DexPair__OnlyOwner();
        _;
    }

    /**
     * @dev 初始化交易对代币地址（仅允许工厂调用一次）
     * @param tokenA 代币A地址
     * @param tokenB 代币B地址
     */
    function initialize(address tokenA, address tokenB) external {
        if (msg.sender != i_factory) revert DexPair__OnlyOwner();
        s_owner = msg.sender;
        s_tokenA = tokenA;
        s_tokenB = tokenB;
    }

    //////////////////////////////////////////////////////
    ///                  mint                       //////
    //////////////////////////////////////////////////////

    /**
     * @dev 铸造流动性代币（LP）
     * @param to LP接收地址
     * @return liquidity 铸造的LP数量
     * 逻辑：
     * 1. 首次添加流动性时锁定 MIN_LIQUIDITY
     * 2. 后续添加按比例计算LP数量
     */
    function mintShares(
        address to
    ) external nonReentrant returns (uint256 liquidity) {
        (uint256 reserveA, uint256 reserveB) = getReserve();

        uint256 balanceA = IERC20(s_tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(s_tokenB).balanceOf(address(this));

        uint256 amountA = balanceA - reserveA;
        uint256 amountB = balanceB - reserveB;
        require(amountA > 0 && amountB > 0, "DexPair__InvalidAmount");

        uint256 totalSupply = totalSupply();
        if (totalSupply == 0) {
            liquidity = Math.sqrt(amountA * amountB) - MIN_LIQUIDITY;
            _mint(address(this), MIN_LIQUIDITY);
        } else {
            //s=(L1-L0)*T/L0 => Liquidity(shares)=userAmount*totalShares/L0
            liquidity = Math.min(
                (amountA * totalSupply) / reserveA,
                (amountB * totalSupply) / reserveB
            );
        }

        if (liquidity <= 0) revert DexPair__LiquidityIsNotEnough();
        _mint(to, liquidity);
        s_reserveA = balanceA; // 更新为添加流动性后的余额
        s_reserveB = balanceB;
        emit SharesMinted(to, liquidity);
        _update();
    }

    /////////////////////////////////////////////////////////////
    //////                         burn                  ////////
    /////////////////////////////////////////////////////////////

    /**
     * @dev 销毁流动性代币并返还底层资产
     * @param to 代币接收地址
     * @param liquidity 销毁的LP数量
     * @return amountA 返还的代币A数量
     * @return amountB 返还的代币B数量
     *
     */
    function burnShares(
        address to,
        uint256 liquidity
    ) external nonReentrant returns (uint256 amountA, uint256 amountB) {
        //L0-L1==S*L0/T; => amount(user)=shares*reserve/totalShares
        //S不可变，L0=balanceOf(address(this)，只要这个流动池不断增长
        //有人不断交易以及不断存钱，用户所能兑换的金额amount才会越来越worth

        uint256 balanceA = IERC20(s_tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(s_tokenB).balanceOf(address(this));

        uint256 totalSupply = totalSupply();
        amountA = (liquidity * balanceA) / totalSupply;
        amountB = (liquidity * balanceB) / totalSupply;

        _burn(address(this), liquidity);

        //IERC20(s_tokenA).transfer(to, amountA);
        _safeTransfer(s_tokenA, msg.sender, amountA);
        //IERC20(s_tokenB).transfer(to, amountB);
        _safeTransfer(s_tokenB, msg.sender, amountB);
        emit SharesBurned(msg.sender, amountB);

        _update();
    }

    //////////////////////////////////////////////////////
    ///                  swap                       //////
    //////////////////////////////////////////////////////
    /**
     * @dev 执行代币交换（需结合Router合约使用）
     * @param amountOut 输出代币数量
     * @param to 接收代币地址
     * 注意：此函数缺少输入校验，需依赖Router合约计算正确的amountOut
     */
    function swap(
        uint256 amountOut,
        address to
    ) external nonReentrant returns (uint256) {
        (uint256 reserveA, uint256 reserveB) = getReserve();
        uint256 balanceA = IERC20(s_tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(s_tokenB).balanceOf(address(this));

        uint256 amountIn;
        if (balanceA > reserveA) {
            amountIn = balanceA - reserveA;
            uint256 amountInWithFee = (amountIn * 997) / 1000; // 扣除 0.3% 手续费
            uint256 amountOutCalculated = (reserveB * amountInWithFee) /
                (reserveA + amountInWithFee);
            require(
                amountOut <= amountOutCalculated,
                "Insufficient output amount"
            );
            _safeTransfer(s_tokenB, to, amountOut);
            s_reserveA = reserveA + amountInWithFee;
            s_reserveB = reserveB - amountOut;
        } else if (balanceB > reserveB) {
            amountIn = balanceB - reserveB;
            uint256 amountInWithFee = (amountIn * 997) / 1000; // 扣除 0.3% 手续费
            uint256 amountOutCalculated = (reserveA * amountInWithFee) /
                (reserveB + amountInWithFee);
            require(
                amountOut <= amountOutCalculated,
                "Insufficient output amount"
            );
            _safeTransfer(s_tokenA, to, amountOut);
            s_reserveA = reserveA - amountOut;
            s_reserveB = reserveB + amountInWithFee;
        } else {
            revert DexPair__InvalidSwap();
        }

        emit SuccessfulSwap(to, amountOut);
        return amountOut;
    }

    //////////////////////////////////////////////////////
    ///                内部工具函数               //////////
    //////////////////////////////////////////////////////
    /**
     * @dev 更新储备量（应在每次流动性变化后调用）
     */
    function _update() private view {
        // 可留空，或者添加检查逻辑
        require(s_reserveA > 0 && s_reserveB > 0, "Invalid reserves");
    }

    /**
     * @dev 安全代币转账（检查转账是否成功）
     * @param token 代币地址
     * @param to 接收地址
     * @param amount 转账金额
     */
    function _safeTransfer(address token, address to, uint256 amount) private {
        bool success = IERC20(token).transfer(to, amount);
        if (!success) revert DexPair__transferFailed();
    }

    function transferOwnerShip(address newOwner) external onlyOwner {
        s_owner = newOwner;
    }

    /**
     * @dev 获取当前储备量
     * @return 代币A和代币B的储备量
     */
    function getReserve() public view returns (uint256, uint256) {
        return (s_reserveA, s_reserveB);
    }
}
