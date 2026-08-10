# MiniVault

MiniVault is a minimal overcollateralized stablecoin protocol for learning DeFi.

## Core Question

Why does DeFi lending need liquidation?

## Architecture

- MiniStablecoin: a simplified ERC-20 stablecoin
- MiniVault: manages collateral, debt, borrowing, repayment, and liquidation

## User Flow

### 1. Deposit

User deposits ETH as collateral.

### 2. Borrow

User borrows mUSD against collateral.

### 3. Repay

User repays mUSD to reduce debt.

### 4. Withdraw

User withdraws ETH if the position remains healthy.

### 5. Liquidate

If the position becomes unhealthy, a liquidator repays debt and receives collateral.

## Known Limitations

- ETH price is fixed
- No real oracle
- No events
- No tests
- No reentrancy protection
- No production-level ERC-20 implementation
- Liquidation logic is simplified

## Next Steps

- Add MockOracle
- Simulate ETH price drop
- Add events
- Add tests
- Improve liquidation logic