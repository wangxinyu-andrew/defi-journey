# MiniVault 机制笔记

## 1. 合约定义、部署与调用者

```solidity
MiniStablecoin public stablecoin;

constructor() {
    stablecoin = new MiniStablecoin();
}
```

`MiniStablecoin` 是合约类型，`stablecoin` 是保存合约引用的状态变量；声明变量本身不会部署代币。`new MiniStablecoin()` 才创建一个拥有独立地址和存储的实例，其 `constructor` 在部署时执行一次。

用户部署 MiniVault，MiniVault 再部署 MiniStablecoin。因此在代币的构造函数里，`msg.sender` 是 MiniVault，`vault = msg.sender` 就确定了铸币和销毁权限。

`msg.sender` 是本次调用的直接调用者；`address(this)` 是当前正在执行的合约地址。它们不能混用。

## 2. 实际资产与分户账

```solidity
function deposit() external payable {
    require(msg.value > 0, "Need ETH");
    collateralETH[msg.sender] += msg.value;
}
```

`payable` 允许调用附带 ETH。ETH 的移动由 EVM 处理，`msg.value` 是本次附带的 wei 数量；mapping 更新负责登记抵押物属于谁。`address(this).balance` 是合约实际 ETH 总余额，不能代替用户分户账。

连续存款必须用 `+=`，使用 `=` 会覆盖旧记录。代币余额和债务也是两本不同的账：把 mUSD 转给别人，不会把自己的债务一起转走。

## 3. 授权与还款

```solidity
allowance[owner][spender]
```

Alice 授权 MiniVault 后，额度记录在 `allowance[Alice][MiniVault]`。当 MiniVault 调用 `transferFrom(Alice, address(this), amount)` 时，代币合约中的 `from` 是 Alice，`msg.sender` 是 MiniVault，因此查询 `allowance[from][msg.sender]`。

`approve` 设置额度，不转移代币；新额度覆盖旧额度，`approve(spender, 0)` 用于清零。`transfer` 使用调用者自己的余额，`transferFrom` 使用 `from` 的余额及对应授权。代币数量为 `uint256`，不能表示负数。

还款依次完成：用户授权、Vault 拉取 mUSD、销毁 Vault 收到的 mUSD、减少用户债务。省略债务更新会留下已经付款却仍然欠债的记录。

## 4. 健康检查与回滚

```solidity
require(条件表达式, "错误提示");
```

条件为真继续执行，为假则 revert。下面检查的是增加债务后的仓位；检查失败，这次新增的债务也回滚：

```solidity
debt[msg.sender] += amount;
require(_isHealthy(msg.sender), "Not enough collateral");
stablecoin.mint(msg.sender, amount);
```

`withdraw` 同理：先减少抵押记录，再检查健康度，最后发送 ETH。存款和还款改善仓位；借款和提款可能降低抵押率，所以必须检查操作后的状态。

## 5. 单位与边界

ETH 与 mUSD 都以 `1e18` 个最小单位表示一个完整单位。`_collateralValue` 先把抵押物换算成 mUSD 价值；抵押率则是以 `1e18` 缩放的百分数：

```solidity
collateralValue = collateralETH[user] * ETH_PRICE / 1e18;
ratio = collateralValue * 100e18 / debt[user]; // debt > 0
```

1 ETH、固定价格 3,000、债务 2,000 mUSD 对应 `150e18`，正好满足 `>= MIN_COLLATERAL_RATIO`。债务为零时无需除法：`_isHealthy` 返回 `true`，查询函数用 `type(uint256).max` 表示无需担心抵押不足。

拆出 `_collateralValue` 是为了明确单位并复用公式。整数除法会截断，中间乘法也可能溢出，合并公式时必须重新检查，不能只在纸面上约分。

## 6. 当前清算条件不可达

v0 的价格固定、债务不自动计息，借款和提款又会拒绝不健康结果。因此正常流程无法从健康仓位留下不健康仓位；调用 `liquidate` 会在最初的健康检查处回滚。

未来接入可变价格后，仓位可以在借款时健康、价格下跌后不健康。市场价格必须通过预言机传入合约，合约不会自行感知行情。这是后续清算测试需要引入价格变化的原因。

清算若成功，必须同时完成五项记账：清算人的 mUSD 减少、mUSD 总供应减少、借款人的债务减少、借款人的抵押记录减少、清算人收到 ETH。价格换算和奖励分别为：

```solidity
collateralToSeize = repayAmount * 1e18 / ETH_PRICE;
bonus = collateralToSeize * LIQUIDATION_BONUS_BPS / BPS_DENOMINATOR;
```

`10_000 BPS = 100%`，因此 `1_000 BPS = 10%`。`repayAmount` 可以小于总债务；清算激励本身不保证足额偿债，也不保证每次部分清算后仓位立即恢复健康。

## 7. 容易混淆的语法

| 写法 | 含义 |
| --- | --- |
| 状态变量 | 保存在合约 storage 中，跨调用保留；局部变量和参数只用于本次执行 |
| `public` / `external` | 函数可由外部调用；`public` 还可在内部直接调用，`external` 不可直接内部调用 |
| `internal` / `private` | 函数只能内部调用；`internal` 也可供派生合约使用，`private` 限于定义它的合约 |
| `view` | 函数可以读取状态，但不能修改状态 |
| `returns (类型)` / `return 值` | 前者声明返回类型，后者返回实际结果 |
| `onlyVault` 中的 `_` | 在这个位置执行被修饰函数的函数体 |
| `public` mapping | 编译器生成查询函数；不会允许外部直接修改 mapping |

原生 ETH 的 `call{value: ...}("")` 与代币合约的 `transfer` 是两种操作。`call` 可能执行接收方代码，必须处理失败和重入；具体语法见 [调试笔记](DEBUGGING.md)。
