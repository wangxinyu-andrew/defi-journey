# MiniVault 调试笔记

保留原调试记录中可复用的错误与修复。原记录日期为 2026-06-20，记载当时已在 Remix 编译成功；这不等于当前版本已经通过自动化行为测试。

## 1. 导入文件名不一致

- **现象**：导入 `MiniStablecoin.sol` 失败。
- **原因**：实际文件名写成了 `MiniStablcoin.sol`，与 import 不匹配。
- **修复**：文件名统一为 `MiniStablecoin.sol`，使用 `import "./MiniStablecoin.sol";`。
- **复用要点**：检查文件名、相对路径和大小写是否完全一致。

## 2. 把 `address(this)` 写反

- **现象**：编译报错 `This expression is not callable`。
- **原因**：写成 `this(address)`，把 `this` 当成可调用的表达式。
- **修复**：改为 `address(this)`。
- **复用要点**：`address(this)` 表示当前合约地址；在 MiniVault 的还款和清算中，它是接收并销毁 mUSD 的 Vault 地址。

## 3. 原生 ETH 转账改用 `call`

- **现象**：原 Remix 记录出现原生 ETH `.transfer()` 的弃用警告。
- **原因**：当时使用的编译器提示更换该发送方式；`pragma ^0.8.20` 表示允许的版本范围，不等于实际编译器一定是 0.8.20。
- **修复**：`withdraw` 和 `liquidate` 使用低级 `call`，并检查返回值。
- **复用要点**：低级调用失败不会自动让调用者回滚，必须处理 `success`；向合约发送 ETH 可能触发接收方代码，需要考虑重入。

```solidity
(bool success, ) = payable(msg.sender).call{value: amount}("");
require(success, "ETH transfer failed");
```

`call` 返回 `(bool success, bytes memory data)`。`(bool success, )` 忽略第二个返回值；`{value: amount}` 指定发送多少 wei；`""` 表示空 calldata，两者不是同一个“留空”。

Checks-Effects-Interactions（CEI）的顺序是检查条件、更新状态、执行外部交互。当前代码在发送 ETH 前更新抵押记录；仅有这个顺序或编译成功，都不能替代针对完整调用流程的安全测试。
