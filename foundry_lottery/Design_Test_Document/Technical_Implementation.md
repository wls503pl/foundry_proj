# Raffle Contract - Technical Documentation

## Overview

**Contract**: Raffle  
**Version**: 1.3 (VRF + Chainlink Automation + Automated Funding)  
**Solidity**: ^0.8.18  
**License**: MIT  
**Author**: Peile Wu (<peile.wu.1990@gmail.com>)

A fully automated decentralized lottery contract using Chainlink VRF 2.5 for provably fair random number generation and Chainlink Automation for autonomous operation.

---

## Chainlink VRF Setup

### Creating a Subscription

Visit <https://docs.chain.link/vrf/v2-5/getting-started> and click the subscription manager link to access <https://vrf.chain.link/>

1. Click "Create Subscription" button
2. Connect MetaMask wallet
3. Complete the transaction to create subscription
4. Add funds (Sepolia LINK or ETH)

![Chainlink VRF Subscription](../img/chainlink_vrf/chainlink_vrf_subscription.png)

### Automated Subscription Creation

The deployment script automatically creates a VRF subscription if one doesn't exist.

**Implementation in DeployRaffle.s.sol**:

```solidity
if (config.subscriptionId == 0) {
    // Create subscription
    CreateSubscription createSubscription = new CreateSubscription();
    (config.subscriptionId, config.vrfCoordinator) =
        createSubscription.createSubscription(config.vrfCoordinator);

    // Fund the subscription
    FundSubscription fundSubscription = new FundSubscription();
    fundSubscription.fundSubscription(
        config.vrfCoordinator,
        config.subscriptionId,
        config.link
    );
}
```

**CreateSubscription Contract (Interactions.s.sol)**:

```solidity
contract CreateSubscription is Script {
    function createSubscription(address vrfCoordinator)
        public returns(uint256, address)
    {
        console2.log("Creating subscription on chain Id: ", block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console2.log("Your subscription Id is: ", subId);
        console2.log("Please update the subscription Id in your HelperConfig.s.sol");
        return (subId, vrfCoordinator);
    }
}
```

### Automated Subscription Funding

The `FundSubscription` contract handles automatic funding of VRF subscriptions with different logic for local and testnet environments.

**FundSubscription Contract (Interactions.s.sol)**:

```solidity
contract FundSubscription is Script, CodeConstants {
    uint256 public constant FUND_AMOUNT = 3 ether; // 3 LINKs

    function fundSubscription(
        address vrfCoordinator,
        uint256 subscriptionId,
        address linkToken
    ) public {
        console2.log("Funding subscription: ", subscriptionId);
        console2.log("Using vrfCoordinator: ", vrfCoordinator);
        console2.log("On ChainId: ", block.chainid);

        if (block.chainid == LOCAL_CHAIN_ID) {
            // Local: Use VRF mock's fundSubscription
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subscriptionId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            // Testnet/Mainnet: Use LINK token's transferAndCall
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(
                vrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subscriptionId)
            );
            vm.stopBroadcast();
        }
    }
}
```

**Key Features**:

-   **Network Detection**: Automatically uses appropriate funding method based on chain ID
-   **Local Networks**: Directly calls VRF mock's `fundSubscription()` function
-   **Test/Main Networks**: Uses LINK token's `transferAndCall()` with encoded subscription ID
-   **Standard Amount**: Funds with 3 LINK tokens by default

### Installing Required Dependencies

**LinkToken Mock Contract**:

The project uses a mock LINK token contract for local testing. It implements the ERC677 standard (ERC20 extension) with the `transferAndCall` function required by Chainlink VRF.

```bash
# Install solmate (for ERC20 implementation)
forge install transmissions11/solmate@v6
```

**Update foundry.toml**:

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
remappings = [
    "@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/",
    "@solmate=lib/solmate/src",
]
```

**LinkToken Features**:

-   Implements ERC677 `transferAndCall()` for VRF subscription funding
-   Mints initial supply for testing
-   Used only in local Anvil networks (real LINK token used on testnets)

### Manual Funding via Script

You can manually fund subscriptions using the standalone script:

**Create .env file** with your RPC URL:

```bash
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
```

**Setup Keystore Account**:

If using the default account causes errors:

![Default Account Error](../img/chainlink_vrf/default_account_error.png)

Create a test account and import your private key:

```bash
# Create and import account
cast wallet import myAccount --interactive

# Enter your private key and password when prompted
```

**Run Funding Script**:

```bash
forge script script/Interactions.s.sol:FundSubscription \
  --rpc-url $SEPOLIA_RPC_URL \
  --account myAccount \
  --broadcast
```

**Successful Output**:

![Fund Subscription Success](../img/chainlink_vrf/fundsubscription_succeed.png)

**Verify Subscription Balance**:

After successful funding, check the subscription balance on <https://vrf.chain.link/>:

![Subscription Balance Added](../img/chainlink_vrf/subscription_balance_added.png)

### Adding Consumer Contract

After deploying the Raffle contract, add it as a consumer to your subscription.

Click on the subscription ID to open the consumer management interface:

![Subscription ID](../img/chainlink_vrf/subscription_id.png)

This opens the Add Consumer interface where you can add your deployed contract address:

![Add Consumer Interface](../img/chainlink_vrf/add_consumer_interface.png)

---

## Chainlink Automation Setup

### Why Chainlink Automation?

To enable periodic, autonomous lottery draws without manual intervention, we use **Chainlink Automation** (formerly Chainlink Keepers). This allows the raffle to run continuously and automatically select winners at specified intervals.

**Reference**: <https://remix.ethereum.org/#url=https://docs.chain.link/samples/Automation/AutomationCounter.sol>

### How It Works

Chainlink Automation nodes continuously monitor your contract by calling `checkUpKeep()`. When all conditions are met, they automatically trigger `performUpkeep()` to execute the winner selection process.

![Chainlink Keeper](../img/chainlink_automation/chainlink_keeper.png)

### Registration Process

1. Visit <https://automation.chain.link/>
2. Connect your MetaMask wallet
3. Click "Register New Upkeep"

![Register New Upkeeper](../img/chainlink_automation/register_newUpKeepper.png)

1. Select trigger mechanism:

    - **Custom logic**: Uses your `checkUpKeep()` function (recommended for this contract)
    - **Time-based**: Runs at fixed intervals
    - **Log trigger**: Responds to emitted events

2. Configure upkeep parameters:

    - **Target contract address**: Your deployed Raffle contract address
    - **Upkeep name**: e.g., "Raffle Lottery Automation"
    - **Gas limit**: Recommended 500,000
    - **Starting balance**: Add LINK tokens to cover automation fees

3. Fund the upkeep with LINK tokens

### Integration Benefits

-   **Fully autonomous**: No manual intervention needed to pick winners
-   **Decentralized**: Multiple Chainlink nodes monitor and execute
-   **Reliable**: Guaranteed execution when conditions are met
-   **Cost-effective**: Only pays gas when `performUpkeep()` is triggered

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
remappings = [
    "@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/",
    "@solmate=lib/solmate/src",
]
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

### Raffle State Management

```solidity
enum RaffleState {
    OPEN,         // Raffle is accepting entries
    CALCULATING   // Raffle is selecting winner (locked)
}

RaffleState private s_raffleState;
```

**Purpose**: Prevents users from entering while winner selection is in progress, avoiding race conditions and ensuring fair gameplay.

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
-   LINK Token: `0x779877A7B0D9E8603169DdbD7836e478b4624789`
-   Callback Gas Limit: `500000` (recommended)

### Runtime State

```solidity
address payable[] private s_players;       // Array of participants
uint256 private s_lastTimeStamp;           // Last drawing timestamp
address private s_recentWinner;            // Most recent winner address
```

---

## Custom Errors

```solidity
error Raffle__notEnoughFeesToEnterRaffle();  // Insufficient entry fee
error Raffle__TransferFailed();              // Prize transfer failed
error Raffle__RaffleNotOpen();               // Raffle is closed for entries
error Raffle__UpkeepNotNeeded(               // Conditions not met for upkeep
    uint256 balance,
    uint256 playersLength,
    uint256 raffleState
);
```

Custom errors provide gas-efficient error handling compared to `require` statements with string messages.

**Naming Convention**: `ContractName__ErrorDescription` (note the capital first letter)

**UpkeepNotNeeded Error**: Provides detailed debugging information:

-   `balance`: Current contract balance
-   `playersLength`: Number of players entered
-   `raffleState`: Current state (0=OPEN, 1=CALCULATING)

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
| `interval`         | uint256 | Drawing interval in seconds | `30` (30 seconds)              |
| `vrfCoordinator`   | address | VRF Coordinator address     | `0x9DdfaCa8...`                |
| `gasLane`          | bytes32 | Gas lane key hash           | `0x787d74...`                  |
| `subscriptionId`   | uint256 | Your VRF subscription ID    | Auto-generated or manual       |
| `callbackGasLimit` | uint32  | Max gas for callback        | `500000`                       |

### Initialization

The constructor initializes:

-   All immutable VRF parameters
-   `s_lastTimeStamp` to current block timestamp
-   `s_raffleState` to `OPEN` (ready to accept entries)

---

## Core Functions

### enterRaffle()

```solidity
function enterRaffle() external payable
```

Allows users to enter the lottery by paying the entrance fee.

**Process**:

1. Validates payment amount meets minimum fee
2. Checks raffle is in OPEN state
3. Adds `msg.sender` to participants array
4. Emits `RaffleEntered` event

**State Protection**: Users cannot enter while winner is being calculated, preventing invalid entries.

**Usage**:

```javascript
await raffle.enterRaffle({ value: ethers.utils.parseEther("0.01") });
```

---

### checkUpKeep()

```solidity
function checkUpKeep(bytes memory /* checkData */)
    public
    view
    returns (bool upkeepNeeded, bytes memory /* performData */)
```

**Purpose**: Called by Chainlink Automation nodes to determine if the lottery is ready for winner selection.

**Return Conditions**: Returns `true` when ALL of the following conditions are met:

1. **Time interval has passed**: `(block.timestamp - s_lastTimeStamp) >= i_interval`
2. **Lottery is open**: `s_raffleState == RaffleState.OPEN`
3. **Contract has balance**: `address(this).balance > 0`
4. **Has players**: `s_players.length > 0`
5. **Implicitly**: Your VRF subscription has LINK tokens

**Implementation**:

```solidity
function checkUpKeep(bytes memory /* checkData */)
    public view returns (bool upkeepNeeded, bytes memory)
{
    bool timeHasPassed = ((block.timestamp - s_lastTimeStamp) >= i_interval);
    bool isOpen = s_raffleState == RaffleState.OPEN;
    bool hasBalance = address(this).balance > 0;
    bool hasPlayers = s_players.length > 0;
    upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
    return (upkeepNeeded, "");
}
```

**Usage**:

-   Called automatically by Chainlink Automation nodes
-   Can also be called internally by `performUpkeep()` for validation

---

### performUpkeep()

```solidity
function performUpkeep(bytes calldata /* performData */) external
```

**Replaces**: The previous `pickWinner()` function - now integrated with Chainlink Automation for autonomous execution.

Initiates the winner selection process by requesting randomness from Chainlink VRF.

**Process**:

#### Phase 1: Validation via checkUpKeep

```solidity
(bool upkeepNeeded,) = checkUpKeep("");
if (!upkeepNeeded) {
    revert Raffle__UpkeepNotNeeded(
        address(this).balance,
        s_players.length,
        uint256(s_raffleState)
    );
}
```

Validates all conditions are met. If not, reverts with detailed state information for debugging.

#### Phase 2: Lock Raffle State

```solidity
s_raffleState = RaffleState.CALCULATING;
```

**Critical**: Locks the raffle to prevent new entries during winner selection process.

#### Phase 3: VRF Request

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

**Automated Flow**:

```
Chainlink Automation monitors checkUpKeep()
    ↓ (returns true when conditions met)
Transaction 1: Automation calls performUpkeep()
    ↓ (State: OPEN → CALCULATING)
Request sent to Chainlink VRF
    ↓
Chainlink generates random number + proof
    ↓
Transaction 2: VRF calls fulfillRandomWords()
    ↓ (State: CALCULATING → OPEN)
Winner selected and paid
    ↓
Cycle repeats automatically
```

---

### fulfillRandomWords()

```solidity
function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords)
    internal override
```

**Callback function** automatically called by Chainlink VRF when random number is ready.

**Implementation (CEI Pattern)**:

```solidity
function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
    // Checks
    // (No checks needed - only VRF can call this)

    // Effects (Update internal state first)
    uint256 indexOfWinner = randomWords[0] % s_players.length;
    address payable recentWinner = s_players[indexOfWinner];
    s_recentWinner = recentWinner;
    s_raffleState = RaffleState.OPEN;  // Reopen raffle
    s_players = new address payable[](0);  // Reset players
    s_lastTimeStamp = block.timestamp;  // Reset timer
    emit WinnerPicked(s_recentWinner);

    // Interactions (External calls last)
    (bool success,) = recentWinner.call{value: address(this).balance}("");
    if (!success) {
        revert Raffle__TransferFailed();
    }
}
```

**CEI Pattern (Checks-Effects-Interactions)**:

A security best practice to prevent reentrancy attacks:

1. **Checks**: Validate conditions (VRF handles this automatically)
2. **Effects**: Update all internal state variables first
3. **Interactions**: Make external calls (transfer prize) only after state is updated

**Why CEI Matters**: If we transferred money before updating state, a malicious contract could re-enter and exploit the old state.

**Winner Selection**:

```
randomWords[0] % s_players.length
```

Modulo operation ensures index is within array bounds, giving each participant equal probability.

**State Reset**: After winner is selected, the raffle automatically:

-   Returns to `OPEN` state (ready for new entries)
-   Clears all players
-   Resets timestamp for next round

---

### Getter Functions

```solidity
function getEntranceFee() external view returns (uint256);
function getRaffleState() external view returns (RaffleState);
function getPlayer(uint256 indexOfPlayer) external view returns (address);
```

**Purpose**: Provide frontend integration and state inspection capabilities.

---

## Events

```solidity
event RaffleEntered(address indexed player);
event WinnerPicked(address indexed winner);
```

**Purpose**:

-   `RaffleEntered`: Track participants in real-time, enable off-chain indexing
-   `WinnerPicked`: Announce winner, provide audit trail

**Usage**: Frontend applications can listen to these events to update UI in real-time.

---

## VRF Implementation Details

### Request Parameters

Reference: <https://docs.chain.link/vrf/v2-5/getting-started#initializing-the-contract>

![VRF Implementation](../img/chainlink_vrf/vrf_implementation.png)

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

1. **Transaction 1**: Contract requests randomness via `performUpkeep()`, locks raffle
2. **Off-chain**: Chainlink generates random number with cryptographic proof
3. **Transaction 2**: Chainlink calls back with verified random number via `fulfillRandomWords()`, selects winner, reopens raffle

This ensures:

-   Unpredictable outcomes
-   Verifiable fairness
-   No miner manipulation
-   No race conditions (state locking)

---

## Security Features

### 1. State Locking Mechanism

```solidity
s_raffleState = RaffleState.CALCULATING;
```

Prevents new entries during winner selection, ensuring:

-   No participants added after randomness is requested
-   Clean slate for each lottery round
-   No race conditions

### 2. CEI Pattern

Following Checks-Effects-Interactions pattern prevents reentrancy attacks during prize distribution.

### 3. Automated Validation

`checkUpKeep()` validates all conditions before allowing `performUpkeep()` to execute, preventing invalid state transitions.

### 4. Custom Errors

Gas-efficient error handling with clear, detailed error messages for debugging and user feedback.

---

## Deployment Guide

### Deployment Scripts

The project includes automated deployment scripts using Foundry:

**HelperConfig.s.sol**: Manages network-specific configurations

-   Automatically detects chain ID (Sepolia or local Anvil)
-   Provides pre-configured VRF parameters for Sepolia
-   Deploys mock VRF coordinator and LINK token for local testing
-   Supports multiple networks through mapping

**Network-Specific LINK Token Configuration**:

```solidity
// Sepolia configuration
function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
    return NetworkConfig({
        entranceFee: 0.01 ether,
        interval: 30,
        vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
        gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
        callbackGasLimit: 500000,
        subscriptionId: 0,  // Auto-create if needed
        link: 0x779877A7B0D9E8603169DdbD7836e478b4624789  // Real LINK token
    });
}

// Local Anvil configuration
function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
    if (localNetworkConfig.vrfCoordinator != address(0)) {
        return localNetworkConfig;
    }

    vm.startBroadcast();
    VRFCoordinatorV2_5Mock vrfCoordinatorMock =
        new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UINT_LINK);
    LinkToken linkToken = new LinkToken();  // Deploy mock LINK token
    vm.stopBroadcast();

    localNetworkConfig = NetworkConfig({
        entranceFee: 0.01 ether,
        interval: 30,
        vrfCoordinator: address(vrfCoordinatorMock),
        gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
        callbackGasLimit: 500000,
        subscriptionId: 0,
        link: address(linkToken)  // Mock LINK token
    });
    return localNetworkConfig;
}
```

**DeployRaffle.s.sol**: Handles contract deployment

-   Uses HelperConfig to get network-specific settings
-   **Automatically creates VRF subscription if `subscriptionId` is 0**
-   **Automatically funds subscription with 3 LINK**
-   Deploys Raffle contract with correct parameters
-   Returns deployed contract instances for testing

**Interactions.s.sol**: Provides subscription management utilities

-   `CreateSubscription`: Creates VRF subscriptions programmatically
-   `FundSubscription`: Funds subscriptions with network-aware logic
-   Useful for automated deployment pipelines
-   Works with both real networks and local mocks

### Prerequisites

1. Install dependencies (Chainlink contracts and Solmate)
2. Set up environment variables (`.env` file)
3. Create keystore account for deployment
4. Ensure sufficient ETH and LINK for deployment and funding

### Network Configurations

**Sepolia Testnet** (Chain ID: 11155111):

```solidity
entranceFee: 0.01 ether
interval: 30 seconds
vrfCoordinator: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B
gasLane: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae
callbackGasLimit: 500000
subscriptionId: 0  // Auto-create and fund if not set
link: 0x779877A7B0D9E8603169DdbD7836e478b4624789
```

**Local Anvil** (Chain ID: 31337):

-   Automatically deploys VRFCoordinatorV2_5Mock and LinkToken mock
-   Uses same parameters as Sepolia for consistency
-   Mock funding: 3 LINK via VRF mock's `fundSubscription()`

### Deployment Commands

**Deploy to Sepolia**:

```bash
forge script script/DeployRaffle.s.sol:DeployRaffle \
  --rpc-url $SEPOLIA_RPC_URL \
  --account myAccount \
  --broadcast \
  --verify
```

**Deploy to Local Anvil**:

```bash
# Start Anvil in one terminal
anvil

# Deploy in another terminal
forge script script/DeployRaffle.s.sol:DeployRaffle \
  --rpc-url http://localhost:8545 \
  --broadcast
```

### Automated Deployment Flow

The deployment process now includes automatic subscription creation and funding:

1. **Check Subscription ID**: If `subscriptionId` is 0, proceed with auto-creation
2. **Create Subscription**: Call `CreateSubscription` to generate new subscription
3. **Fund Subscription**: Call `FundSubscription` to add 3 LINK tokens
4. **Deploy Contract**: Deploy Raffle with funded subscription
5. **Add Consumer**: Manually add contract as consumer (required step)

**Note**: Even with automated funding, you still need to manually add the deployed contract as a consumer to the subscription via <https://vrf.chain.link/>

### Post-Deployment Steps

1. **Add VRF Consumer** (Required):

    - Copy deployed contract address from deployment output
    - Go to <https://vrf.chain.link/>
    - Find your subscription (auto-created or existing)
    - Add contract address as consumer

2. **Register Chainlink Automation**:

    - Go to <https://automation.chain.link/>
    - Click "Register New Upkeep"
    - Select "Custom logic" trigger
    - Enter your contract address
    - Set gas limit to 500,000
    - Fund with LINK tokens
    - Confirm registration

3. **Verify Setup**:
    - Your lottery is now fully automated!
    - Chainlink Automation will call `performUpkeep()` when conditions are met
    - Winners will be selected and paid automatically

### Troubleshooting

**If funding fails with "ERC20: transfer amount exceeds balance"**:

-   Ensure your deployment account has sufficient LINK tokens
-   Get LINK from <https://faucets.chain.link> for Sepolia testnet
-   Check your account balance before deployment

**If keystore errors occur**:

```bash
# Create new keystore account
cast wallet import myAccount --interactive

# Or use existing account
cast wallet list
```

---

## Implementation Status

### ✅ Completed

-   VRF integration for provably fair randomness
-   Entry function with payment validation
-   State management with locking mechanism
-   Complete winner selection logic
-   Prize distribution with CEI pattern
-   Comprehensive error handling with detailed state info
-   Winner tracking
-   **Chainlink Automation integration (`checkUpKeep` + `performUpkeep`)**
-   **Fully autonomous operation**
-   **Automated VRF subscription creation**
-   **Automated subscription funding with network-aware logic**
-   **LINK token mock for local testing**
-   **Standalone funding script for manual operations**
-   Time-interval validation
-   Getter functions for state inspection

### 🎯 Suggested Future Improvements

```solidity
// Additional getter functions for enhanced frontend integration
function getNumberOfPlayers() external view returns (uint256);
function getRecentWinner() external view returns (address);
function getLastTimeStamp() external view returns (uint256);
function getInterval() external view returns (uint256);
```

### Testing Recommendations

**Unit Tests**:

1. Test entry during CALCULATING state (should fail)
2. Test winner selection with multiple participants
3. Test prize transfer failure scenarios
4. Test time interval validation
5. Verify state transitions (OPEN ↔ CALCULATING)
6. Test `checkUpKeep()` returns false when conditions not met
7. Test `performUpkeep()` reverts with `UpkeepNotNeeded` when called prematurely
8. Test automated subscription creation flow
9. Test funding logic for both local and testnet environments

**Integration Tests**:

1. Deploy to local Anvil and test full cycle with mocks
2. Verify VRF mock returns random numbers correctly
3. Test multiple raffle rounds with state resets
4. Test LinkToken mock's `transferAndCall` function
5. Verify subscription funding with correct amounts

**Testnet Verification**:

1. Deploy to Sepolia testnet with auto-creation
2. Verify subscription is created and funded
3. Add contract as consumer manually
4. Register with Chainlink Automation
5. Verify full automated cycle end-to-end

**Test Commands**:

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test
forge test --match-test testFunctionName

# Check coverage
forge coverage
```

---

## Quick Reference

### Contract States

| State       | Description       | Can Enter? | Can Perform Upkeep?        |
| ----------- | ----------------- | ---------- | -------------------------- |
| OPEN        | Accepting entries | ✅ Yes     | ✅ Yes (if conditions met) |
| CALCULATING | Selecting winner  | ❌ No      | ❌ No                      |

### Error Codes

| Error                                | Meaning               | Common Cause                                             |
| ------------------------------------ | --------------------- | -------------------------------------------------------- |
| `Raffle__notEnoughFeesToEnterRaffle` | Payment too low       | Sent less than entrance fee                              |
| `Raffle__RaffleNotOpen`              | Raffle is locked      | Tried to enter during winner selection                   |
| `Raffle__TransferFailed`             | Prize transfer failed | Winner contract rejected payment                         |
| `Raffle__UpkeepNotNeeded`            | Cannot perform upkeep | Time not passed / No players / No balance / State locked |

### Funding Methods by Network

| Network       | Chain ID | Method                        | LINK Source                  |
| ------------- | -------- | ----------------------------- | ---------------------------- |
| Local (Anvil) | 31337    | VRF Mock `fundSubscription()` | Mock LinkToken               |
| Sepolia       | 11155111 | LINK `transferAndCall()`      | Real LINK (0x779877A7B0D...) |
| Mainnet       | 1        | LINK `transferAndCall()`      | Real LINK                    |

### Automation Checklist

-   [ ] Dependencies installed (Chainlink + Solmate)
-   [ ] Environment variables configured (.env)
-   [ ] Keystore account created and funded with ETH/LINK
-   [ ] Contract deployed (subscription auto-created if needed)
-   [ ] Subscription automatically funded with 3 LINK
-   [ ] Contract manually added as VRF consumer
-   [ ] Chainlink Automation upkeep registered
-   [ ] Automation upkeep funded with LINK
-   [ ] Test entry and verify participants tracking
-   [ ] Verify automated winner selection on testnet

### Key Files Structure

```
foundry_lottery/
├── src/
│   └── Raffle.sol                    # Main lottery contract
├── script/
│   ├── DeployRaffle.s.sol           # Deployment with auto-funding
│   ├── HelperConfig.s.sol           # Network configurations
│   └── Interactions.s.sol           # Subscription management
├── test/
│   ├── unit/
│   │   └── RaffleTest.t.sol         # Unit tests
│   └── mocks/
│       └── LinkToken.sol             # LINK token mock (ERC677)
├── lib/
│   ├── chainlink/                    # Chainlink contracts
│   └── solmate/                      # Solmate (ERC20 base)
├── foundry.toml                      # Foundry config with remappings
└── .env                              # Environment variables

```

---

## Summary

This Raffle contract provides a complete, production-ready decentralized lottery solution with:

✅ **Provably Fair Randomness**: Chainlink VRF ensures tamper-proof winner selection  
✅ **Full Automation**: Chainlink Automation handles periodic draws autonomously  
✅ **Automated Deployment**: Scripts handle subscription creation and funding  
✅ **Network Flexibility**: Works on local Anvil, Sepolia testnet, and mainnet  
✅ **Security First**: State locking, CEI pattern, and comprehensive validation  
✅ **Developer Friendly**: Clear errors, detailed logging, and complete documentation  
✅ **Gas Optimized**: Custom errors and efficient state management

The contract is ready for deployment and requires minimal manual intervention - just deploy, add as consumer, and register with Automation. The lottery will run continuously, selecting winners fairly and automatically.
