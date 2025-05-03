// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    // 事件定义，用于记录存款和提取操作（与 WETH 标准一致）
    event Deposit(address indexed dst, uint256 amount);
    event Withdrawal(address indexed src, uint256 amount);

    constructor(
        string memory name,
        string memory symbol,
        address initialAccount,
        uint256 initialBalance
    ) payable ERC20(name, symbol) {
        _mint(initialAccount, initialBalance);
    }

    // 铸造代币（仅用于测试）
    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    // 存款函数：将 ETH 转换为 WETH
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        _mint(msg.sender, msg.value); // 按 1:1 比例铸造 WETH
        emit Deposit(msg.sender, msg.value);
    }

    // 提取函数：将 WETH 转换为 ETH 并发送到指定地址
    function withdraw(uint256 amount) public {
        require(amount > 0, "Withdraw amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient WETH balance");
        require(
            address(this).balance >= amount,
            "Insufficient ETH balance in contract"
        );

        _burn(msg.sender, amount); // 销毁调用者的 WETH
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ETH transfer failed");
        emit Withdrawal(msg.sender, amount);
    }

    // 销毁代币（仅用于测试）
    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }

    // 内部转账（仅用于测试）
    function transferInternal(address from, address to, uint256 value) public {
        _transfer(from, to, value);
    }

    // 内部授权（仅用于测试）
    function approveInternal(
        address owner,
        address spender,
        uint256 value
    ) public {
        _approve(owner, spender, value);
    }
}
