# Raffle Contract - Testing Documentation

## Overview

This project uses **Foundry** for smart contract testing. Tests are organized into unit and integration tests to ensure contract reliability and security.

---

## Test Structure

```
test/
├── integration/     # Integration tests (end-to-end scenarios)
└── unit/           # Unit tests (individual function testing)
    └── RaffleTest.t.sol
```

---

## Unit Tests

Unit tests verify individual functions work correctly in isolation.

**Test File**: `test/unit/RaffleTest.t.sol`

### Test Setup

The `setUp()` function runs before each test:

-   Deploys Raffle contract using deployment scripts
-   Loads network-specific configuration (entrance fee, interval, VRF params)
-   Creates test player address with 10 ETH balance

---

### Test Cases

#### 1. Initialization Test

**testRaffleInitializesInOpenState()**

Verifies the raffle starts in OPEN state after deployment.

---

#### 2. Entry Fee Validation

**testRaffleRevertsWhenYouDontPayEnough()**

Ensures the contract reverts with `Raffle__notEnoughFeesToEnterRaffle` error when payment is insufficient.

**Key assertion:**

```solidity
vm.expectRevert(Raffle.Raffle__notEnoughFeesToEnterRaffle.selector);
raffle.enterRaffle();  // No payment sent
```

---

#### 3. Player Recording

**testRaffleRecordsPlayersWhenTheyEnter()**

Confirms players are correctly stored in the players array when they enter with valid payment.

---

#### 4. Event Emission

**testEnteringRaffleEmitsEvent()**

Verifies the `RaffleEntered` event is emitted with correct parameters when a player enters.

**Key assertion:**

```solidity
vm.expectEmit(true, false, false, false, address(raffle));
emit RaffleEntered(PLAYER);
```

---

#### 5. State Locking

**testDontAllowPlayersToEnterWhileRaffleIsCalculating()**

Tests that entries are blocked during the winner calculation phase.

**Test flow:**

1. Player enters raffle
2. Fast-forward time past interval using `vm.warp()` and `vm.roll()`
3. Call `performUpkeep()` to transition state to CALCULATING
4. Verify new entries revert with `Raffle__RaffleNotOpen` error

---

## Running Tests

### Basic Commands

```bash
# Run all tests
forge test

# Run with detailed output
forge test -vvv

# Run specific test
forge test --match-test testRaffleInitializesInOpenState

# Run only unit tests
forge test --match-path test/unit/**

# Check coverage
forge coverage
```

---

## Key Testing Utilities

### Foundry Cheatcodes

| Cheatcode                  | Purpose                        |
| -------------------------- | ------------------------------ |
| `vm.prank(address)`        | Set `msg.sender` for next call |
| `vm.deal(address, amount)` | Give ETH to address            |
| `vm.warp(timestamp)`       | Set `block.timestamp`          |
| `vm.roll(blockNumber)`     | Set `block.number`             |
| `vm.expectRevert(error)`   | Expect next call to revert     |
| `vm.expectEmit(...)`       | Expect event emission          |

### Test Helpers

```solidity
address public PLAYER = makeAddr("player");  // Deterministic test address
vm.deal(PLAYER, 10 ether);                   // Fund test account
```

---

## Test Coverage

**Tested Areas:**

-   ✅ Contract initialization and default state
-   ✅ Entry fee validation and access control
-   ✅ Player recording and data integrity
-   ✅ Event emission and logging
-   ✅ State transitions and locking mechanism

**Testing Approach:**

-   Arrange-Act-Assert pattern for clarity
-   Isolated tests for independence
-   Explicit error condition verification
-   Use of Foundry cheatcodes for blockchain state manipulation
