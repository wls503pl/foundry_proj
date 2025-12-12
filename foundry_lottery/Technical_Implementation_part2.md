# Raffle Contract - Deployment Automation Improvements

**Continuation of `Technical_Implementation.md`**

---

## Overview

This document analyzes recent improvements to the deployment automation system, focusing on automated consumer registration and enhanced testing.

---

## Automated Consumer Registration

### AddConsumer Contract

**File**: `script/Interactions.s.sol` (New)

```solidity
contract AddConsumer is Script {
    function addConsumer(address contractToAddtoVrf, address vrfCoordinator, uint256 subId) public {
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddtoVrf);
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}
```

**Purpose**: Automatically adds deployed contract as VRF consumer.

**Mechanism**: Uses `DevOpsTools.get_most_recent_deployment()` to find deployed contract address.

### Integration

**File**: `script/DeployRaffle.s.sol`

```diff
+import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";

+AddConsumer addConsumer = new AddConsumer();
+addConsumer.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId);
```

**File**: `script/DeployRaffle.s.sol` - FundSubscription

```diff
+FundSubscription fundSubscription = new FundSubscription();
+fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link);
```

---

## Configuration

### File System Permissions

**File**: `foundry.toml`

```diff
+fs_permissions = [
+    { access = "read", path = "./broadcast" },
+    { access = "read", path = "./reports" },
+]
```

### Fuzz Testing Configuration

**File**: `foundry.toml`

```diff
+[fuzz]
+runs = 1024
```

**Purpose**: Sets number of random inputs generated per fuzz test (default: 256).

**Required Dependency**:

```bash
forge install Cyfrin/foundry-devops@0.2.2 --no-commit
```

---

## New Event

**File**: `src/Raffle.sol`

```diff
+event RequestedRaffleWinner(uint256 indexed requestId);

 uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
+emit RequestedRaffleWinner(requestId);
```

**Purpose**: Emits VRF request ID for tracking and testing.

---

## Enhanced Testing

### Import Additions

```diff
+import {Vm} from "forge-std/Vm.sol";
+import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
```

### New Tests

**1. CheckUpKeep - No Balance**

```solidity
function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);
    (bool upkeepNeeded,) = raffle.checkUpKeep("");
    assert(!upkeepNeeded);
}
```

**2. CheckUpKeep - Wrong State**

```solidity
function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() public {
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);
    raffle.performUpkeep("");

    (bool upkeepNeeded,) = raffle.checkUpKeep("");
    assert(!upkeepNeeded);
}
```

**3. PerformUpkeep - Success**

```solidity
function testPerformUpkeepCanOnlyRunIfCheckUpkeepIsTrue() public {
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);
    raffle.performUpkeep("");
}
```

**4. PerformUpkeep - Revert**

```solidity
function testPerformUpkeepRevertsIfCheckUpkeepIsFalse() public {
    uint256 currentBalance = 0;
    uint256 numPlayers = 0;
    Raffle.RaffleState rState = raffle.getRaffleState();

    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    currentBalance = currentBalance + entranceFee;
    numPlayers = 1;

    vm.expectRevert(
        abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance, numPlayers, rState)
    );
    raffle.performUpkeep("");
}
```

**5. PerformUpkeep - Event and State**

```solidity
function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public raffleEntered {
    vm.recordLogs();
    raffle.performUpkeep("");
    Vm.Log[] memory entries = vm.getRecordedLogs();
    bytes32 requestId = entries[1].topics[1];

    Raffle.RaffleState raffleState = raffle.getRaffleState();
    assert(uint256(requestId) > 0);
    assert(uint256(raffleState) == 1);
}
```

**6. FulfillRandomWords - Fuzz Test**

```solidity
function testFulfillrandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId)
    public raffleEntered
{
    vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
    VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(randomRequestId, address(raffle));
}
```

**Purpose**: Tests that `fulfillRandomWords()` reverts for all invalid request IDs. Foundry automatically runs this test 1024 times with different `randomRequestId` values.

### Test Modifier

```solidity
modifier raffleEntered() {
    vm.prank(PLAYER);
    raffle.enterRaffle{value: entranceFee}();
    vm.warp(block.timestamp + interval + 1);
    vm.roll(block.number + 1);
    _;
}
```

**Purpose**: Reduces code duplication for common test setup.

---

## Fuzz Testing

### How It Works

Add a parameter to the test function:

```solidity
function testSomething(uint256 randomValue) public {
    // Foundry generates random values for randomValue
}
```

Foundry automatically:

-   Generates 1024 different values (configured in `foundry.toml`)
-   Runs the test with each value
-   Tries to find inputs that break the test

### Run with Verbosity

```bash
forge test --match-test testFulfillrandomWords -vvv
```

**Output**:

```
[PASS] testFulfillrandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256) (runs: 1024, μ: 25841, ~: 25841)
```

-   `runs: 1024`: Tested with 1024 random inputs
-   `μ`: Average gas used
-   `~`: Median gas used

---

## Technical Details

### DevOpsTools Discovery

```solidity
DevOpsTools.get_most_recent_deployment("Raffle", block.chainid)
```

Reads `./broadcast/DeployRaffle.s.sol/{chainId}/run-latest.json` to find deployed address.

### Event Recording

```solidity
vm.recordLogs();
raffle.performUpkeep("");
Vm.Log[] memory entries = vm.getRecordedLogs();
bytes32 requestId = entries[1].topics[1];
```

-   `entries[0]`: VRF coordinator event
-   `entries[1]`: RequestedRaffleWinner event
-   `topics[1]`: requestId parameter

---

## Deployment

### Commands

```bash
# Prerequisites
forge install Cyfrin/foundry-devops@0.2.2 --no-commit

# Deploy to Sepolia
forge script script/DeployRaffle.s.sol:DeployRaffle \
  --rpc-url $SEPOLIA_RPC_URL \
  --account myAccount \
  --broadcast \
  --verify

# Deploy to Anvil
anvil
forge script script/DeployRaffle.s.sol:DeployRaffle \
  --rpc-url http://localhost:8545 \
  --broadcast
```

### Automation Status

| Step                | Status       |
| ------------------- | ------------ |
| Create Subscription | ✅ Automated |
| Fund Subscription   | ✅ Automated |
| Deploy Contract     | ✅ Automated |
| Add Consumer        | ✅ Automated |
| Register Automation | ⚠️ Manual    |

---

## Troubleshooting

**"No deployment found for contract 'Raffle'"**

```bash
ls -la broadcast/DeployRaffle.s.sol/*/
forge script script/DeployRaffle.s.sol:DeployRaffle --broadcast
```

**"Access to path './broadcast' denied"**

```toml
fs_permissions = [{ access = "read", path = "./broadcast" }]
```
