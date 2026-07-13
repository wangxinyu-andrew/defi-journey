# Day 03: Collateral Logic

## deposit

The user sends ETH to the vault. The vault records the amount as collateral.

## withdraw

The user can withdraw collateral only if the position remains healthy after withdrawal.

## msg.value

msg.value is the amount of ETH sent with the transaction.

## Health Check

The vault checks whether the user's collateral value is high enough compared with the debt.