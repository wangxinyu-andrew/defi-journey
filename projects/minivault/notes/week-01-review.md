# Weekly Review: 2026-06-15 to 2026-06-21

## What I shipped

- Initialized the MiniVault project
- Wrote `MiniStablecoin`
- Wrote `MiniVault`
- Added deposit, withdraw, borrow, repay, and liquidation logic
- Added collateral ratio and health-check logic
- Added liquidation bonus using basis points (BPS)
- Compiled the contracts successfully in Remix
- Fixed compilation errors and deprecated ETH transfer syntax
- Wrote learning notes and a debug log
- Updated README

## What I understood

- ERC-20 is a token interface standard, while `MiniStablecoin` is my own simplified implementation
- A Solidity `contract` definition becomes a deployed contract instance only after deployment
- Each deployed contract instance has its own address and storage
- `constructor` runs once during deployment and is commonly used for initialization
- `modifier` can wrap reusable checks around a function, and `_` represents the original function body
- State variables persist in contract storage, while local variables only exist during a function call
- A contract name such as `MiniStablecoin` can also be used as a contract type
- `MiniStablecoin public stablecoin` is a contract-typed state variable that stores a reference to a deployed `MiniStablecoin` instance
- `new MiniStablecoin()` deploys a new `MiniStablecoin` instance and returns its contract reference
- `msg.sender` is the direct caller of the current call, while `address(this)` is the address of the currently executing contract
- `msg.value` is the amount of ETH sent with the current call, measured in wei
- `public`, `external`, `internal`, and `private` control function visibility
- `view` means a function may read contract state but cannot modify it
- `returns (...)` declares the return type, while `return ...` returns the actual value
- Solidity uses integer arithmetic, so DeFi protocols often use fixed-point scaling such as `1e18`
- BPS provides an integer-based way to represent percentages, where `10_000 BPS = 100%`
- `approve` gives a spender an allowance, and `transferFrom` uses that allowance to move tokens
- Repayment requires the user to approve MiniVault before MiniVault can pull mUSD with `transferFrom`
- Repayment pulls mUSD into MiniVault, burns it, and then reduces the user's debt
- `type(uint256).max` can be used as a sentinel value to represent an effectively infinite collateral ratio when debt is zero
- ETH transfers can use low-level `call{value: amount}("")`, which returns a success flag that must be checked

## What confused me

### Mostly clarified this week

- The difference between a contract definition, deployment, a deployed contract instance, and a contract reference
- Why `MiniStablecoin` can be used as a variable type even though `contract` itself is not a normal variable type
- What exactly `MiniStablecoin public stablecoin` stores
- Why `stablecoin = new MiniStablecoin()` is needed after declaring the `stablecoin` state variable
- The difference between state variables, local variables, parameters, and return values
- The roles of `constructor`, `modifier`, `internal`, `public`, `view`, `payable`, `returns`, and `return`
- The difference between `msg.sender`, `msg.value`, and `address(this)`
- Why `address(this)` is used when MiniVault temporarily receives mUSD during repayment
- Why repayment needs `approve -> transferFrom -> burn -> reduce debt`
- Why Solidity cannot directly use normal decimal arithmetic for collateral ratios
- Why collateral ratio calculations use `1e18` scaling
- Why `repayAmount * 1e18 / ETH_PRICE` is needed to preserve ETH precision
- Why liquidation bonus is represented with BPS instead of a decimal such as `1.1`
- Why multiplication is usually performed before division in integer arithmetic
- Why a debt-free account returns `type(uint256).max` in `collateralRatio`
- The difference between ERC-20 `transfer()` and native ETH transfers
- How `call{value: amount}("")` works
- Why `call` returns `(bool success, bytes memory data)`
- Why `(bool success, )` ignores the second return value
- The difference between empty calldata `""` and ignoring the second return value
- Why ETH transfer failure through `call` must be checked manually with `require(success, ...)`

### Still need deeper understanding

- Oracle design and how real protocols obtain changing ETH prices
- How liquidation behaves when ETH price falls in real time
- Liquidation edge cases, including partial liquidation and insufficient remaining collateral
- Reentrancy and why low-level external calls introduce additional security risks
- The Checks-Effects-Interactions (CEI) pattern
- Whether MiniVault needs `nonReentrant`
- More realistic permission design for `mint` and `burn`
- Events and how they are used by frontends, indexers, and block explorers
- The difference between code that merely compiles and code that is actually safe
- How to systematically test `deposit`, `withdraw`, `borrow`, `repay`, and `liquidate`

## Debugging Lessons

- Import paths and file names must match exactly
- `address(this)` is correct; `this(address)` is not callable
- Compiler warnings can reveal outdated or unsafe patterns even when the syntax is valid
- Deprecated `.transfer()` calls were replaced with `call{value: ...}("")`
- Successful compilation means the contracts are syntactically and type-correct, but does not prove the protocol logic is correct

## Known Limitations

- Fixed ETH price
- No MockOracle
- No automated test framework
- Simplified liquidation model
- No partial liquidation rules
- No events
- No reentrancy protection
- Simplified token implementation
- Simplified access control
- Not production-ready

## Next Week

- Add `MockOracle`
- Replace the fixed ETH price with an oracle price
- Simulate an ETH price drop
- Make liquidation actually testable
- Add events
- Test the complete approve -> repay flow
- Test successful and failed liquidation cases
- Learn basic reentrancy and CEI
- Start learning Foundry or Hardhat