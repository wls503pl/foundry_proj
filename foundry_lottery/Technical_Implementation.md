# Raffle Contract - Technical Documentation

## Overview

**Contract**: Raffle  
**Version**: 1.0 (VRF Integrated)  
**Solidity**: ^0.8.18  
**License**: MIT  
**Author**: Peile Wu (peile.wu.1990@gmail.com)

A decentralized lottery contract using Chainlink VRF 2.5 for provably fair random number generation.

---

## Chainlink VRF Setup

### Creating a Subscription

Visit https://docs.chain.link/vrf/v2-5/getting-started and click the subscription manager link to access https://vrf.chain.link/

1. Click "Create Subscription" button
2. Connect MetaMask wallet
3. Complete the transaction to create subscription
4. Add funds (Sepolia LINK or ETH)

![Chainlink VRF Subscription](img/chainlink_vrf/chainlink_vrf_subscription.png)

### Adding Funds

After creating the subscription, you can add funds using either:

-   Sepolia LINK tokens (recommended)
-   Sepolia ETH (native payment)

### Adding Consumer Contract

After deploying the Raffle contract, you need to add it as a consumer to your subscription.

Click on the subscription ID to open the consumer management interface:

![Subscription ID](img/chainlink_vrf/subscription_id.png)

This opens the Add Consumer interface where you can add your deployed contract address:

![Add Consumer Interface](img/chainlink_vrf/add_consumer_interface.png)

---

## Why Chainlink VRF?

### The Randomness Problem

Randomness is very difficult to generate on blockchains because:

-   Every node must reach the same conclusion (consensus)
-   All computations are deterministic and reproducible
-   Block data can be manipulated by miners
-   Random numbers cannot be generated natively in smart contracts

### The VRF Solution

**Chainlink VRF** (Verifiable Random Function) solves this by:

-   Generating randomness off-chain with cryptographic proof
-   Providing verifiable proof that randomness wasn't tampered with
-   Delivering the random number through oracle callback

> **Key Principle**: Randomness cannot be stored on-chain for reference. If stored, participants can retrieve and predict outcomes. Instead, randomness must be requested from an oracle, which generates a random number with cryptographic proof, then returns the result to the requesting contract.

---

## Contract Architecture

### Dependencies

```solidity
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
```

**Installation**:

```bash
# Install Chainlink contracts
git clone --depth 1 --branch v2.17.0 \
  https://github.com/smartcontractkit/chainlink.git \
  lib/chainlink
```

**Configuration** (`foundry.toml`):

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
remappings = ["@chainlink/contracts/=lib/chainlink/contracts/"]
```

### Inheritance

```solidity
contract Raffle is VRFConsumerBaseV2Plus {
    // Implementation
}
```

The contract inherits from `VRFConsumerBaseV2Plus` to integrate Chainlink VRF functionality.

---

## State Variables

### Lottery Configuration

```solidity
uint256 private immutable i_entranceFee;  // Entry fee in wei
uint256 private immutable i_interval;     // Time between draws in seconds
```

### VRF Configuration

```solidity
bytes32 private immutable i_keyHash;           // Gas lane key hash
uint256 private immutable i_subscriptionId;    // VRF subscription ID
uint32 private immutable i_callbackGasLimit;   // Callback gas limit
uint16 private constant REQUEST_CONFIRMATIONS = 3;  // Block confirmations
uint32 private constant NUM_WORDS = 1;         // Number of random values
```

**Configuration Parameters** (Sepolia):

-   VRF Coordinator: `0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B`
-   Key Hash: `0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae`
-   Callback Gas Limit: `100000` (recommended starting point)

### Runtime State

```solidity
address payable[] private s_players;  // Array of participants
uint256 private s_lastTimeStamp;      // Last drawing timestamp
```

---

## Constructor

```solidity
constructor(
    uint256 entranceFee,
    uint256 interval,
    address vrfCoordinator,
    bytes32 gasLane,
    uint256 subscriptionId,
    uint32 callbackGasLimit
) VRFConsumerBaseV2Plus(vrfCoordinator)
```

### Parameters

| Parameter          | Type    | Description                 | Example                        |
| ------------------ | ------- | --------------------------- | ------------------------------ |
| `entranceFee`      | uint256 | Entry fee in wei            | `10000000000000000` (0.01 ETH) |
| `interval`         | uint256 | Drawing interval in seconds | `86400` (24 hours)             |
| `vrfCoordinator`   | address | VRF Coordinator address     | `0x9DdfaCa8...`                |
| `gasLane`          | bytes32 | Gas lane key hash           | `0x787d74...`                  |
| `subscriptionId`   | uint256 | Your VRF subscription ID    | From VRF UI                    |
| `callbackGasLimit` | uint32  | Max gas for callback        | `100000`                       |

---

## Core Functions

### enterRaffle()

```solidity
function enterRaffle() external payable
```

Allows users to enter the lottery by paying the entrance fee.

**Process**:

1. Validates payment amount meets minimum fee
2. Adds `msg.sender` to participants array
3. Emits `RaffleEntered` event

**Usage**:

```javascript
await raffle.enterRaffle({ value: ethers.utils.parseEther("0.01") });
```

### pickWinner()

```solidity
function pickWinner() external
```

Initiates the winner selection process by requesting randomness from Chainlink VRF.

**Two-Phase Process**:

#### Phase 1: Time Validation

```solidity
if ((block.timestamp - s_lastTimeStamp) < i_interval) {
    revert();
}
```

Ensures sufficient time has passed since last drawing.

#### Phase 2: VRF Request

```solidity
VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
    keyHash: i_keyHash,
    subId: i_subscriptionId,
    requestConfirmations: REQUEST_CONFIRMATIONS,
    callbackGasLimit: i_callbackGasLimit,
    numWords: NUM_WORDS,
    extraArgs: VRFV2PlusClient._argsToBytes(
        VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
    )
});

uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
```

**VRF Request Flow**:

```
Transaction 1: pickWinner()
    ↓
Request sent to Chainlink VRF
    ↓
Chainlink generates random number + proof
    ↓
Transaction 2: fulfillRandomWords() callback
```

### fulfillRandomWords()

```solidity
function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords)
    internal virtual override {}
```

**Current Status**: Empty implementation (to be completed)

**Required Implementation**:

```solidity
function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords)
    internal override
{
    // Select winner using modulo operation
    uint256 indexOfWinner = randomWords[0] % s_players.length;
    address payable winner = s_players[indexOfWinner];

    // Reset lottery state
    s_players = new address payable[](0);
    s_lastTimeStamp = block.timestamp;

    // Transfer prize to winner
    (bool success, ) = winner.call{value: address(this).balance}("");
    require(success, "Transfer failed");

    // Emit event
    emit WinnerPicked(winner);
}
```

**Winner Selection**:

```
randomWords[0] % s_players.length
```

Modulo operation ensures index is within array bounds, giving each participant equal probability.

### getEntranceFee()

```solidity
function getEntranceFee() external view returns (uint256)
```

Returns the entrance fee for frontend integration.

---

## Events

```solidity
event RaffleEntered(address indexed player);
```

**Purpose**:

-   Track participants in real-time
-   Enable off-chain indexing
-   Provide audit trail

**Additional Events Needed**:

```solidity
event RandomnessRequested(uint256 indexed requestId);
event WinnerPicked(address indexed winner, uint256 amount);
```

---

## Custom Errors

```solidity
error raffle__notEnoughFeesToEnterRaffle();
```

Custom errors provide gas-efficient error handling compared to `require` statements with string messages.

**Naming Convention**: `contractName__errorDescription`

---

## VRF Implementation Details

### Request Parameters

Reference: https://docs.chain.link/vrf/v2-5/getting-started#initializing-the-contract

![VRF Implementation](img/chainlink_vrf/vrf_implementation.png)

-   **keyHash**: Identifies the gas lane (max gas price)
-   **subId**: Links request to your funded subscription
-   **requestConfirmations**: Blocks to wait (3 recommended)
-   **callbackGasLimit**: Max gas for callback execution
-   **numWords**: Number of random values (1 for single winner)
-   **nativePayment**: `false` = pay with LINK, `true` = pay with ETH

### Two-Transaction Model

**Why Two Transactions?**

Blockchains are deterministic - if random number generation happened in the same transaction as the request, miners could predict and manipulate outcomes.

**Solution**:

1. **Transaction 1**: Contract requests randomness
2. **Off-chain**: Chainlink generates random number with cryptographic proof
3. **Transaction 2**: Chainlink calls back with verified random number

This ensures:

-   Unpredictable outcomes
-   Verifiable fairness
-   No miner manipulation

---

## Deployment Guide

### Prerequisites

1. Create VRF subscription at https://vrf.chain.link/
2. Fund subscription with LINK tokens
3. Note your subscription ID

### Deployment

```solidity
// Sepolia Configuration
uint256 entranceFee = 0.01 ether;
uint256 interval = 30 seconds;
address vrfCoordinator = 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B;
bytes32 gasLane = 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
uint256 subscriptionId = YOUR_SUBSCRIPTION_ID;
uint32 callbackGasLimit = 100000;

Raffle raffle = new Raffle(
    entranceFee,
    interval,
    vrfCoordinator,
    gasLane,
    subscriptionId,
    callbackGasLimit
);
```

### Post-Deployment

1. Copy deployed contract address
2. Return to VRF subscription manager
3. Add contract address as consumer

---

## Current Implementation Status

### ✅ Completed

-   VRF integration structure
-   Entry function with payment validation
-   VRF request mechanism
-   Basic time-interval validation

### ⚠️ Pending

-   Complete `fulfillRandomWords()` implementation
-   Add winner tracking state variable
-   Implement prize distribution logic
-   Add comprehensive events
-   Enhance error handling

### Suggested Improvements

```solidity
// Add state enum
enum RaffleState { OPEN, CALCULATING }
RaffleState private s_raffleState;

// Add winner tracking
address private s_recentWinner;

// Add more getters
function getPlayer(uint256 index) external view returns (address);
function getNumberOfPlayers() external view returns (uint256);
function getRecentWinner() external view returns (address);
```
