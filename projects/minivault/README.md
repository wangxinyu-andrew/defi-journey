# MiniVault

MiniVault is an educational borrowing prototype: users deposit ETH, borrow an accounting token called mUSD, repay debt, and withdraw collateral subject to a health check. It is not a production stablecoin protocol.

## Architecture

| Contract | Responsibility |
| --- | --- |
| [MiniStablecoin.sol](contracts/MiniStablecoin.sol) | Simplified token balances, allowances, transfers, minting, and burning |
| [MiniVault.sol](contracts/MiniVault.sol) | Collateral and debt accounting, health checks, borrowing, repayment, and liquidation logic |

Deploying MiniVault creates a MiniStablecoin instance. The token records MiniVault as its authorized vault; only that vault can mint or burn mUSD.

## Current behavior: v0

| Function | Behavior on a successful call |
| --- | --- |
| `deposit()` | Receives ETH and adds `msg.value` to the caller's collateral record |
| `borrow(amount)` | Increases debt, checks the resulting position, then mints mUSD |
| `repay(amount)` | Pulls approved mUSD into the vault, burns it, then reduces debt |
| `withdraw(amount)` | Reduces the collateral record, checks the resulting position, then sends ETH |
| `collateralRatio(user)` | Returns a percentage scaled by `1e18`; returns `type(uint256).max` when debt is zero |
| `liquidate(user, repayAmount)` | Requires an unhealthy position; exchanges a liquidator's mUSD for the borrower's collateral plus a bonus |

Before repayment, the user must approve MiniVault to spend enough mUSD. For liquidation, that approval would come from the liquidator. Transferring mUSD to another address does not transfer the original borrower's debt.

### Units and health boundary

- ETH amounts are in wei; `1 ETH = 1e18 wei`.
- mUSD uses 18 decimals; `1 mUSD = 1e18` base units.
- `ETH_PRICE = 3000e18` is a fixed price in mUSD units per ETH.
- `MIN_COLLATERAL_RATIO = 150e18` represents 150%.
- The liquidation bonus is `1_000 / 10_000 = 10%`.

```solidity
collateralValue = collateralETH[user] * ETH_PRICE / 1e18;
ratio = collateralValue * 100e18 / debt[user]; // debt > 0
```

A ratio at or above 150% is healthy. With 1 ETH of collateral and the fixed price of 3,000 mUSD per ETH, 2,000 mUSD of debt is exactly the healthy boundary.

### Why liquidation cannot complete through normal v0 flows

The price is fixed and debt does not accrue interest. Both borrowing and withdrawing check the resulting health and revert the call if it would become unhealthy. Depositing and repaying cannot make a healthy position unhealthy.

Therefore, starting from a healthy position, normal v0 operations cannot produce an unhealthy position. `liquidate()` can be called, but its initial health check will revert; the successful liquidation path is not reachable this way. An example where ETH falls to 2,000 mUSD assumes a changing price source that this version does not have.

## Validation status

The original debugging record reports successful Remix compilation. This repository does not yet contain a Foundry configuration, automated tests, or deployment scripts. Successful compilation does not establish correct or safe behavior, and a successful liquidation scenario has not been validated here.

## Known limitations

- The token is a simplified implementation inspired by ERC-20, with no `Transfer` or `Approval` events and no zero-address checks. It is not a complete ERC-20 implementation.
- There is no oracle, interest accrual, or vault event logging.
- The liquidation function accepts a partial repayment amount, but has no close-factor policy, dust handling, or bad-debt resolution. If collateral cannot cover the chosen repayment plus bonus, the call reverts.
- ETH payouts check the result of low-level `call`, and collateral accounting is updated before the payout. There is no dedicated reentrancy guard or security test coverage.

## Next implementation step

1. Set up Foundry around the existing contracts.
2. Test repeated deposits, successful borrowing, borrowing beyond the limit, withdrawals, and the approval/repayment flow. Check that failed calls leave accounting unchanged.
3. Introduce a mock price source, then test a position that becomes unhealthy after a price drop and the resulting liquidation accounting.

Implementation details belong in the [learning notes](docs/LEARNING.md); past errors belong in the [debugging notes](docs/DEBUGGING.md).
