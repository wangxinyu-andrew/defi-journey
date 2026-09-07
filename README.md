# DeFi Journey

Project-based learning in Solidity and DeFi, focused on lending, stablecoins, testing, and security.

## Current project

[MiniVault](projects/minivault/README.md) is a minimal ETH-collateralized borrowing prototype. The v0 contracts implement collateral accounting, mUSD issuance and repayment, health checks, and a simplified liquidation function. Automated behavior tests are the next milestone.

## Documentation

| File | Purpose |
| --- | --- |
| [MiniVault README](projects/minivault/README.md) | Architecture, current behavior, limitations, and next implementation step |
| [Learning notes](projects/minivault/docs/LEARNING.md) | Solidity concepts, accounting, and design reasoning |
| [Debugging notes](projects/minivault/docs/DEBUGGING.md) | Reusable lessons from actual errors |

The repository began with environment setup and introductory blockchain notes, then moved to project-based learning through MiniVault. Git history preserves those earlier steps and subsequent code changes.

## Next milestone

Set up Foundry in the existing MiniVault project and test its current behavior before adding a changing price source and liquidation scenarios.
