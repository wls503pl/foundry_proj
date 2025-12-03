# Foundry Integration Testing Guide

## What is Integration Testing?

**Simple explanation**: Integration testing tests how different parts of your code work **together** in a real-world scenario.

-   **Unit tests** → Test individual functions in isolation
-   **Integration tests** → Test complete workflows (deploy → fund → withdraw)

Think of it like testing a car:

-   Unit test: Does the engine start?
-   Integration test: Can you drive from point A to point B?

---

## Why Do We Need Integration Tests?

In our FundMe project, we want to test the **complete user journey**:

1. ✅ Deploy the FundMe contract
2. ✅ Users can fund the contract
3. ✅ Owner can withdraw funds

Integration tests simulate **real usage** to make sure everything works together correctly.

---

## Project Structure

Here's how we organize integration tests:

![Project Structure](img/broadcast_chainId.png)

```
foundry_fund_me/
├── script/
│   ├── DeployFundMe.s.sol      # Deploys the contract
│   └── Interactions.s.sol       # Fund & Withdraw scripts
├── test/
│   ├── unit/                    # Unit tests (individual functions)
│   └── integration/             # Integration tests (complete workflows)
│       └── InteractionsTest.t.sol
└── broadcast/                   # Deployment records (used by foundry-devops)
```

---

## Step 1: Create Interaction Scripts

**Goal**: Create reusable scripts for funding and withdrawing.

### What is `Interactions.s.sol`?

This file contains two scripts:

1. `FundFundMe` - Funds the contract with ETH
2. `WithdrawFundMe` - Withdraws all funds (owner only)

```solidity
// script/Interactions.s.sol
contract FundFundMe is Script {
    uint256 constant SEND_VALUE = 0.01 ether;

    function fundFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}();
        vm.stopBroadcast();
        console.log("Funded FundMe with %s", SEND_VALUE);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        );
        fundFundMe(mostRecentlyDeployed);
    }
}
```

**Key points**:

-   `vm.startBroadcast()` / `vm.stopBroadcast()` → Marks which code sends real transactions
-   `fundFundMe(address)` → Can be called from tests with a specific contract address
-   `run()` → Can be called from command line to interact with deployed contracts

---

## Step 2: Install Foundry DevOps

**What is foundry-devops?**

A tool that **automatically finds your most recently deployed contract** so you don't need to manually copy/paste addresses.

### Installation

```bash
forge install ChainAccelOrg/foundry-devops --no-commit
```

After installation, you'll see it in `lib/`:

![Foundry DevOps Installation](img/foundry_devops_installation.png)

### How Does It Work?

```solidity
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
    "FundMe",        // Contract name
    block.chainid    // Network ID (31337 for Anvil, 11155111 for Sepolia)
);
```

**Behind the scenes**:

1. Looks in the `broadcast/` folder
2. Finds the folder matching your `chainid`
3. Opens `run-latest.json`
4. Returns the most recent contract address

---

## Step 3: Enable FFI in foundry.toml

**What is FFI?**

FFI (Foreign Function Interface) allows Foundry to **execute external programs**.

### Why Do We Need It?

`foundry-devops` reads files from your filesystem, which requires FFI access.

### Enable FFI

```toml
# foundry.toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
remappings = ["@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/"]
ffi = true  # ← Add this line
```

### ⚠️ Security Warning

**FFI can execute ANY system command**, so:

-   ✅ Only use in **local testing**
-   ❌ **NEVER** use in production or mainnet
-   ✅ Review all code that uses `vm.ffi()`

---

## Step 4: Write Integration Tests

**Goal**: Test the complete fund → withdraw workflow.

```solidity
// test/integration/InteractionsTest.t.sol
contract InteractionsTest is Test {
    FundMe fundMe;

    function setUp() external {
        // Deploy a fresh contract for testing
        DeployFundMe deploy = new DeployFundMe();
        fundMe = deploy.run();
    }

    function testUserCanFundAndWithdraw() public {
        // 1. Fund the contract using the script
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(address(fundMe));

        // 2. Verify funding worked
        assertEq(address(fundMe).balance, 0.01 ether);

        // 3. Withdraw using the script
        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        // 4. Verify withdrawal worked
        assertEq(address(fundMe).balance, 0);
    }
}
```

---

## Understanding the Flow

### What Happens When You Run the Test?

```
1. setUp() runs
   └─> DeployFundMe deploys FundMe contract

2. testUserCanFundAndWithdraw() runs
   └─> Creates FundFundMe script
   └─> Calls fundFundMe(address)
       └─> vm.startBroadcast() starts recording
       └─> FundMe.fund{value: 0.01 ether}() sends ETH
       └─> vm.stopBroadcast() stops recording

3. Check: Does contract have 0.01 ETH? ✅

4. Creates WithdrawFundMe script
   └─> Calls withdrawFundMe(address)
       └─> FundMe.withdraw() withdraws all funds

5. Check: Does contract have 0 ETH? ✅
```

---

## Common Confusion Explained

### Why Don't We Use `vm.prank(USER)`?

**Wrong approach** (what you might think):

```solidity
function testUserCanFundInteractions() public {
    vm.prank(USER);  // ❌ This doesn't work as expected
    fundFundMe.fundFundMe(address(fundMe));
}
```

**Why it fails**:

-   `vm.prank(USER)` only affects the **immediate next call**
-   But `fundFundMe()` internally calls `vm.startBroadcast()` which resets the sender
-   The actual sender becomes `msg.sender` (the test contract), not `USER`

**Correct approach**:

```solidity
function testUserCanFundInteractions() public {
    // Test the SCRIPT itself, don't simulate users
    fundFundMe.fundFundMe(address(fundMe));
    assertEq(address(fundMe).balance, 0.01 ether);
}
```

**Key insight**: Integration tests test **scripts**, not user behavior. If you want to test user behavior, write unit tests.

---

## Running the Tests

### Run All Integration Tests

```bash
forge test --match-path test/integration/*
```

### Run Specific Test

```bash
forge test --match-test testUserCanFundAndWithdraw
```

### Run with Detailed Output

```bash
forge test --match-test testUserCanFundAndWithdraw -vvv
```

### Expected Output

```
[⠊] Compiling...
[⠒] Solc 0.8.28 finished in 848.90ms
Compiler run successful!

Ran 1 test for test/integration/InteractionsTest.t.sol:InteractionsTest
[PASS] testUserCanFundAndWithdraw() (gas: 245890)
  Funded FundMe with 10000000000000000
  Withdrew from FundMe

Suite result: ok. 1 passed; 0 failed; 0 skipped
```

---

## Summary

### What We Built

1. **Interaction Scripts** (`Interactions.s.sol`)

    - Reusable scripts for funding and withdrawing
    - Can be used in tests AND from command line

2. **Integration Tests** (`InteractionsTest.t.sol`)

    - Tests complete workflows
    - Ensures all parts work together

3. **Foundry DevOps**
    - Automatically finds deployed contracts
    - No manual address copying needed

### Key Concepts

| Concept                                    | What It Does                                       |
| ------------------------------------------ | -------------------------------------------------- |
| `vm.startBroadcast()`                      | Marks code that sends real transactions            |
| `DevOpsTools.get_most_recent_deployment()` | Finds your latest deployed contract                |
| `ffi = true`                               | Allows Foundry to read files (needed for devops)   |
| Integration Test                           | Tests complete workflows, not individual functions |

### The Difference

```
Unit Test:
  ✓ Can function X do Y correctly?

Integration Test:
  ✓ Can users complete the entire journey from A to Z?
```
