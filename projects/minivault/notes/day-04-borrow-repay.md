# Day 04: Borrow and Repay

## Borrow Flow

1. User calls borrow
2. Debt increases
3. Vault checks whether the position is healthy
4. Vault mints mUSD to the user

## Repay Flow

1. User approves the vault to spend mUSD
2. User calls repay
3. Vault pulls mUSD from the user
4. Vault burns mUSD
5. Debt decreases

## Key Insight

Borrowing creates debt. Repaying destroys debt.