// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//import './interfaces/IUniswapV2Factory.sol';
//import './UniswapV2Pair.sol';
import {DexPair} from "./DexPair.sol";

contract DexFactory {
    address public feeTo;
    address public feeToSetter;

    mapping(address => mapping(address => address)) public s_getPair;
    address[] public allPairs;

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    function getPairAddress(
        address token0,
        address token1
    ) public view returns (address) {
        return s_getPair[token0][token1];
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair) {
        require(tokenA != tokenB, "Dex: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "Dex: ZERO_ADDRESS");
        require(s_getPair[token0][token1] == address(0), "Dex: PAIR_EXISTS"); // single check is sufficient
        bytes memory bytecode = type(DexPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        DexPair(pair).initialize(token0, token1); //已经分过类了，所以可以直接初始化
        DexPair(pair).transferOwnerShip(msg.sender);
        s_getPair[token0][token1] = pair;
        s_getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "Dex: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, "Dex: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
}
