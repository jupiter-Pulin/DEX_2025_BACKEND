npx thirdweb deploy -k X0EKc7K3QaN8NjXJ3I89N3ICIITcQ6nchCrX2Ma5ikwiwndt6Q_TXFcRyepVpfU8GmJQke3RHlaooZ9poVdiYw

forge script script/DeployDEX.s.sol:DeployDEX --rpc-url https://eth-sepolia.g.alchemy.com/v2/w1SE_kAGD6H4oCAo9GFFkzZTVFH7ooV5 --private-key 1ba3c22f43b7798250295e3c05ff2c632bdb00dd77310e80ab8c175d896319a2 --broadcast --verify --etherscan-api-key E8ACQN3S37N1Q5PSMVT7DW5439V7WAMBFA

forge test --fork-url https://eth-sepolia.g.alchemy.com/v2/w1SE_kAGD6H4oCAo9GFFkzZTVFH7ooV5 --match-path test/integration/TestRemoveLiquidity.t.sol -vvv

这个是最新的合约地址，thirdweb 上的不是！！！！！！！！！！！！

router 合约地址:
0x1BD507a9127e11695fDe07D7de18fEf7C6D5E425

factory 合约地址：
0xD6c789404d60D3e0778b3890183FbC9F06Dd3e8F

WETH 合约地址：
0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
