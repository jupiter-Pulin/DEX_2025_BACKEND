// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
//  network
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
//repo contracts
import {DexPair} from "./DexPair.sol";
import {DexFactory} from "./DexFactory.sol";
//Libraries
import {DexTotalLibraries} from "./libraries/DexTotalLibraries.sol";
//interface
import {IWETH} from "./interface/IWETH.sol";
import {IDexPair} from "./interface/IDexPair.sol";

/*
 * @title DEXRouter
 * @author Pu Lin
 *
 * @notice This contract is used to route the swap of tokens
 * @notice 在这个合约里用户能够进行token的交换
 * @dev 并且能够进行添加流动性，消除流动性；交换代币等用途。
 *
 * @dev 需要注意的是，每一个函数最多允许九个变量的命名，如果超过就会显示 stack to deep
 */
contract DexRouter is ReentrancyGuard {
    /////////////////////////
    ////        errors //////
    /////////////////////////

    error DEXRouter__LessThanYourAmountMinimum(uint256);
    error DEXRouter__ExcessAmount();
    error DexRouter__EXPIRED();
    error DEXRouter_InvalidPath();
    error DEXRouter__TransferFailed();
    error DEXRouter_InvalidLiquidity();

    //////////////////////////////////////
    ////       state variables      //////
    //////////////////////////////////////
    address private immutable i_factory;
    address private immutable i_weth;

    constructor(address _factory, address weth) {
        i_factory = _factory;
        i_weth = weth;
        // IWETH iWeth=new IWETH();
    }

    //////////////////////////////////////
    ////       EVENT                //////
    //////////////////////////////////////
    event LiquidityAdded(
        address indexed user,
        uint256 amountTokenA,
        uint256 amountTokenB,
        address indexed pairAddr,
        uint256 liquidityShares
    );
    event ExactTokensForTokensSwaped(
        uint256 amountIn,
        address indexed to,
        uint256 amountOut
    );
    event LiquidityRemoved(
        address indexed to,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    ////////////////////////////////////////////////
    //                modifier                  ////
    ////////////////////////////////////////////////
    modifier ensure(uint256 deadline) {
        if (deadline < block.timestamp) revert DexRouter__EXPIRED();
        //require(deadline >= block.timestamp, ": EXPIRED");
        _;
    }

    ///////////////////////////////////////////////////////////////////////////
    /////////////          addLiquidity                           /////////////
    ///////////////////////////////////////////////////////////////////////////

    function _addLiquidity(
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address tokenA, // 已排序的代币地址
        address tokenB
    ) internal returns (uint256 amountA, uint256 amountB) {
        address pair = DexFactory(i_factory).getPairAddress(tokenA, tokenB);
        if (pair == address(0)) {
            DexFactory(i_factory).createPair(tokenA, tokenB);
            amountA = amountADesired;
            amountB = amountBDesired;
            return (amountA, amountB);
        }

        (uint256 reserveA, uint256 reserveB) = IDexPair(pair).getReserve();

        uint256 amountBOptimal = DexTotalLibraries.quote(
            amountADesired,
            reserveA,
            reserveB
        ); // amountA * reserveB / reserveA
        if (amountBOptimal <= amountBDesired) {
            if (amountBOptimal < amountBMin) {
                revert DEXRouter__LessThanYourAmountMinimum(amountBOptimal);
            }
            amountA = amountADesired;
            amountB = amountBOptimal;
        } else {
            uint256 amountAOptimal = DexTotalLibraries.quote(
                amountBDesired,
                reserveB,
                reserveA
            );
            if (amountAOptimal < amountAMin) {
                revert DEXRouter__LessThanYourAmountMinimum(amountAOptimal);
            }
            if (amountAOptimal > amountADesired) {
                revert DEXRouter__ExcessAmount();
            }
            amountA = amountAOptimal;
            amountB = amountBDesired;
        }
    }

    /**
     * 该函数用于添加两种代币进流动性池子
     * dy=y0*dx/x0
     * dx=x0*dy/y0
     * @param _amountADesired 第一个代币希望的最大数量
     * @param _amountBDesired 第二个代币希望的数量
     * @param _amountAMin 第一个代币所接受的最小数量
     * @param _amountBMin 第二个代币所接收的最小数量
     * @param _tokenA 第一个代币的地址
     * @param _tokenB 第二个代币的地址
     */
    function addLiquidity(
        uint256 _amountADesired,
        uint256 _amountBDesired,
        uint256 _amountAMin,
        uint256 _amountBMin,
        address _tokenA,
        address _tokenB,
        uint256 deadline
    ) external ensure(deadline) nonReentrant returns (uint256 liquidity) {
        // 在用户传入的地址和代币账户进行排序
        (address tokenA, address tokenB) = DexTotalLibraries.sortToken(
            _tokenA,
            _tokenB
        );
        (uint256 amountADesired, uint256 amountBDesired) = DexTotalLibraries
            .sortAmount(_amountADesired, _amountBDesired, _tokenA, tokenA);
        (uint256 amountAMin, uint256 amountBMin) = DexTotalLibraries.sortAmount(
            _amountAMin,
            _amountBMin,
            _tokenA,
            tokenA
        );

        // 调用内部函数，传入排序后的代币地址
        (uint256 amountA, uint256 amountB) = _addLiquidity(
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            tokenA,
            tokenB
        );

        address pair = DexFactory(i_factory).getPairAddress(tokenA, tokenB);

        /* bool success 的判断在safeTransferFrom已经写了 */
        DexTotalLibraries.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        DexTotalLibraries.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        // 调用内部函数，将流动性添加到池子中
        liquidity = IDexPair(pair).mintShares(msg.sender);
        emit LiquidityAdded(msg.sender, amountA, amountB, pair, liquidity);
    }

    function addLiquidityETH(
        uint256 _amountBDesired,
        uint256 _amountEthMin,
        uint256 _amountBMin,
        address _token,
        uint256 deadline
    )
        external
        payable
        ensure(deadline)
        nonReentrant
        returns (uint256 liquidity)
    {
        // 首先需要将 ETH 转换为 WETH
        IWETH(i_weth).deposit{value: msg.value}();

        //将weth和tokenB通过计算获得最佳输入金额，后传给pair合约
        (address weth, address tokenB) = DexTotalLibraries.sortToken(
            i_weth,
            _token
        );
        (uint256 amountADesired, uint256 amountBDesired) = DexTotalLibraries
            .sortAmount(msg.value, _amountBDesired, i_weth, weth);
        (uint256 amountAMin, uint256 amountBMin) = DexTotalLibraries.sortAmount(
            _amountEthMin,
            _amountBMin,
            i_weth,
            weth
        );
        // 调用内部函数，传入排序后的代币地址
        (uint256 amountA, uint256 amountB) = _addLiquidity(
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            weth,
            tokenB
        );
        address pair = DexFactory(i_factory).getPairAddress(weth, tokenB);

        /* bool success 的判断在safeTransferFrom已经写了 */
        DexTotalLibraries.safeTransferFrom(weth, msg.sender, pair, amountA);
        DexTotalLibraries.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        // 调用内部函数，将流动性添加到池子中
        liquidity = IDexPair(pair).mintShares(msg.sender);
        emit LiquidityAdded(msg.sender, amountA, amountB, pair, liquidity);
    }

    ///////////////////////////////////////////////////////////////////////////
    /////////////          RemoveLiquidity                        /////////////
    ///////////////////////////////////////////////////////////////////////////
    function removeLiquidity(
        uint256 _liquidity,
        address _tokenA,
        address _tokenB,
        address to
    )
        external
        nonReentrant
        returns (uint256 amountA, uint256 amountB, uint256 latestLiquidity)
    {
        //user输入自身的liquidity数量，传入pair合约，通过函数burn销毁liquidity，销毁的同时，返回用户的amountA和amountB
        //这个liquidity并非要全额消除，而是看看用户到底想要消除多少
        //amountAdesired和amountBdesired是用户希望的数量，而amountAmin和amountBmin是用户接受的最小数量
        //(amountA,amountB)_removeLiquidity
        address pair = DexFactory(i_factory).getPairAddress(_tokenA, _tokenB);

        //avoid deep stack
        if (_liquidity > IDexPair(pair).balanceOf(msg.sender))
            revert DEXRouter_InvalidLiquidity();
        latestLiquidity = IDexPair(pair).balanceOf(msg.sender) - _liquidity;

        bool success = IDexPair(pair).transferFrom(
            msg.sender,
            pair,
            _liquidity
        );
        if (!success) revert DEXRouter__TransferFailed();

        (uint256 _amountA, uint256 _amountB) = IDexPair(pair).burnShares(
            to,
            _liquidity
        );

        (address token0, ) = DexTotalLibraries.sortToken(_tokenA, _tokenB);

        (amountA, amountB) = token0 == _tokenA
            ? (_amountA, _amountB)
            : (_amountB, _amountA);
        emit LiquidityRemoved(to, amountA, amountB, latestLiquidity);
    }

    function removeLiquidityETH(
        uint256 _liquidity,
        address _token,
        address to
    )
        external
        nonReentrant
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 latestLiquidity
        )
    {
        address pair = DexFactory(i_factory).getPairAddress(i_weth, _token);
        //avoid deep stack
        if (_liquidity > IDexPair(pair).balanceOf(msg.sender))
            revert DEXRouter_InvalidLiquidity();

        latestLiquidity = IDexPair(pair).balanceOf(msg.sender) - _liquidity;
        bool success = IDexPair(pair).transferFrom(
            msg.sender,
            pair,
            _liquidity
        );
        if (!success) revert DEXRouter__TransferFailed();

        (uint256 _amountA, uint256 _amountB) = IDexPair(pair).burnShares(
            to,
            _liquidity
        );
        (address token0, ) = DexTotalLibraries.sortToken(i_weth, _token);
        (amountETH, amountToken) = token0 == i_weth
            ? (_amountA, _amountB)
            : (_amountB, _amountA);
        IWETH(i_weth).withdraw(amountETH, to);
        emit LiquidityRemoved(to, amountETH, amountToken, latestLiquidity);
    }

    ///////////////////////////////////////////////////////////////////////////
    /////////////          SwapExactTokenForTokens                /////////////
    ///////////////////////////////////////////////////////////////////////////
    function _swap(
        uint256[] memory amounts,
        address _to,
        address[] memory path
    ) private {
        address nextPair;

        //1.有amountIn，有amountOut，要让每一个地址都能正常的交换
        //先从两个地址开始算起
        //确定传入的是to还是传到下个pair地址合约
        for (uint256 i = 0; i < path.length - 1; i++) {
            address pair = DexFactory(i_factory).getPairAddress(
                path[i],
                path[i + 1]
            );

            nextPair = i < path.length - 2
                ? nextPair = DexFactory(i_factory).getPairAddress(
                    path[i + 1],
                    path[i + 2]
                )
                : address(0);

            address to = i < path.length - 2 ? nextPair : _to;
            uint256 amountOut = amounts[i + 1];
            IDexPair(pair).swap(amountOut, to);
        }
    }

    function swapExactTokenForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) nonReentrant {
        if (path.length < 1) revert DEXRouter_InvalidPath();

        uint256[] memory amounts = DexTotalLibraries.getAmountsOut(
            path,
            amountIn,
            amountOutMin,
            i_factory
        );

        address pair = DexFactory(i_factory).getPairAddress(path[0], path[1]);
        //IERC20(path[0]).transferFrom(msg.sender, pair, amountIn);
        DexTotalLibraries.safeTransferFrom(path[0], msg.sender, pair, amountIn);
        _swap(amounts, to, path);
        emit ExactTokensForTokensSwaped(
            amountIn,
            to,
            amounts[amounts.length - 1]
        );
    }

    function swapExactEthForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable ensure(deadline) nonReentrant {
        if (path.length < 1) revert DEXRouter_InvalidPath();

        if (path[0] != i_weth) revert DEXRouter_InvalidPath();

        IWETH(i_weth).deposit{value: msg.value}();

        uint256[] memory amounts = DexTotalLibraries.getAmountsOut({
            path: path,
            amountIn: msg.value,
            amountOutMin: amountOutMin,
            factory: i_factory
        });

        address pair = DexFactory(i_factory).getPairAddress(i_weth, path[1]);
        /*这里不用transferFrom，因为是eth传到此路由合约，且传入的msg.value就是amountIn，确保用户确实有这笔钱
        而weth却不一样，用户在传参可以让amountIn完全大于自己真正拥有的值
        同理，addliquidity也是如此，如果算出来的amountA和amountB大于了自己的userBal，
        所以我才不打算在DEXRouter__TransferFailed这里传参数
        因为userBal和amount 都是msg.value*/
        bool success = IWETH(i_weth).transfer(pair, msg.value);
        if (!success) revert DEXRouter__TransferFailed();

        _swap(amounts, to, path);
        emit ExactTokensForTokensSwaped(
            msg.value,
            to,
            amounts[amounts.length - 1]
        );
    }

    ///////////////////////////////////////////////////////////////////////////
    /////////////          getters                               /////////////
    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) public pure returns (uint amountB) {
        return DexTotalLibraries.quote(amountA, reserveA, reserveB);
    }

    function getWethAddress() public view returns (address) {
        return i_weth;
    }

    function getFactoryAddress() public view returns (address) {
        return i_factory;
    }

    // 新增的 getAmountsOut 函数
    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) public view returns (uint256[] memory amounts) {
        if (path.length < 2) revert("DEXRouter: INVALID_PATH");
        // 调用 DexTotalLibraries.getAmountsOut，传入 amountOutMin 为 0（仅查询，不检查最小值）
        amounts = DexTotalLibraries.getAmountsOut(path, amountIn, 0, i_factory);
        return amounts;
    }
}
