# Foundry FundMe Development Guide

## 1. Project Initialization

```bash
mkdir foundry_fund_me && cd foundry_fund_me
forge init
forge test  # Verify default project works
rm src/*.sol script/*.sol test/*.sol  # Clean auto-generated files
```

## 2. Create Contracts

Create **FundMe.sol** and **PriceConverter.sol** in `src/` directory.

## 3. Solve Compilation Errors

Run `forge compile` and you'll encounter import errors.

**Solution**: Install Chainlink dependencies

```bash
forge install smartcontractkit/chainlink-brownie-contracts@1.3.0
```

**Configure remappings** in `foundry.toml`:

```toml
remappings = ["@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/"]
```

## 4. Importance of Testing

> **Key Points**: Deploying smart contracts without tests will be rejected in audits. Writing excellent tests differentiates great developers from mediocre ones.

## 5. Write Tests

Create **FundMeTest.t.sol** in `test/`. Run tests:

```bash
forge test -vv
```

## 6. Understanding EVM Revert Error

The `testPriceFeedVersionIsAccurate()` test fails with EVM revert.

**Root Cause**: Foundry spins up a blank Anvil chain for testing. The hardcoded Chainlink price feed address doesn't exist on this blank chain.

**Solution**: Fork a real network

```bash
# Create .env
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY

# Run tests
source .env
forge test -vvv --fork-url $SEPOLIA_RPC_URL
```

## 7. Four Types of Tests

- **Unit**: Testing a specific part of code
- **Integration**: Testing how code works with other parts
- **Forked**: Testing code on a simulated real environment
- **Staging**: Testing code in a real environment (not production)

## 8. Making Contracts Modular and Chain-Agnostic

### Problem
The initial implementation hardcodes the Chainlink price feed address for Sepolia, preventing deployment to other networks.

### Solution
Refactor to accept the price feed address as a constructor parameter.

### Key Changes

#### 8.1 FundMe Contract

Add state variable and modify constructor:

```solidity
AggregatorV3Interface public s_priceFeed;

constructor(address priceFeed) {
    i_owner = msg.sender;
    s_priceFeed = AggregatorV3Interface(priceFeed);
}
```

Update functions to use `s_priceFeed`:

```solidity
function fund() public payable {
    require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "...");
    // ...
}

function getVersion() public view returns (uint256) {
    return s_priceFeed.version();
}
```

#### 8.2 PriceConverter Library

Pass price feed as parameter:

```solidity
function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
    (, int256 answer, , , ) = priceFeed.latestRoundData();
    return uint256(answer * 10000000000);
}

function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) 
    internal view returns (uint256) {
    uint256 ethPrice = getPrice(priceFeed);
    // ...
}
```

#### 8.3 Deployment Script

Initially still hardcoded:

```solidity
function run() external returns (FundMe) {
    vm.startBroadcast();
    FundMe fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    vm.stopBroadcast();
    return fundMe;
}
```

This accepts constructor parameters but the address is still hardcoded. We need a configuration management system.

#### 8.4 Test File Updates

Update `setUp()` to use deployment script:

```solidity
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

function setUp() external {
    DeployFundMe deployFundMe = new DeployFundMe();
    fundMe = deployFundMe.run();
}
```

Update owner assertion:

```solidity
function testOwnerIsMsgSender() public {
    assertEq(fundMe.i_owner(), msg.sender);  // Changed from address(this)
}
```

## 9. Implementing HelperConfig for Multi-Chain Deployment

### The Problem
Even with constructor parameters, our deployment script still hardcodes addresses. We need automatic network detection.

### 9.1 Create HelperConfig

Create `script/HelperConfig.s.sol`:

```solidity
contract HelperConfig is Script {
    struct NetworkConfig {
        address priceFeed;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = getAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
    }

    function getAnvilEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({priceFeed: address(0)});  // Placeholder
    }
}
```

**Key Design Points:**
- **Struct**: Groups network-specific addresses
- **Auto-detection**: Uses `block.chainid` to determine network
- **Public variable**: `activeNetworkConfig` gets auto-generated getter function

### 9.2 Update DeployFundMe

```solidity
import {HelperConfig} from "./HelperConfig.s.sol";

function run() external returns (FundMe) {
    // Before startBroadcast -> No gas cost
    HelperConfig helperConfig = new HelperConfig();
    address ethUsdPriceFeed = helperConfig.activeNetworkConfig();

    vm.startBroadcast();
    FundMe fundMe = new FundMe(ethUsdPriceFeed);
    vm.stopBroadcast();
    return fundMe;
}
```

### 9.3 Understanding Auto-Getter

When you declare:
```solidity
NetworkConfig public activeNetworkConfig;
```

Solidity auto-generates:
```solidity
function activeNetworkConfig() public view returns (NetworkConfig memory)
```

That's why you can call `helperConfig.activeNetworkConfig()` with parentheses.

**Note**: The code `address ethUsdPriceFeed = helperConfig.activeNetworkConfig();` works due to Solidity's implicit conversion when struct has one field. For clarity and future-proofing, using `.priceFeed` explicitly is recommended.

### 9.4 Deployment Examples

```bash
# Deploy to Sepolia - auto-detects chainid 11155111
forge script script/DeployFundMe.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast

# Deploy to Mainnet - auto-detects chainid 1
forge script script/DeployFundMe.s.sol --rpc-url $MAINNET_RPC_URL --broadcast

# Local tests - uses Anvil config
forge test
```

### Benefits
- Zero manual configuration per deployment
- Single source of truth for addresses
- Easy to extend with new networks
- Same script works across all environments

## 10. Mock Contracts for Local Testing

### The Problem
Running `forge test` locally fails because Anvil (local chain) doesn't have Chainlink contracts. We need mock contracts to simulate price feeds without forking testnets.

### 10.1 Create Mock Price Feed

Create `test/mocks/MockV3Aggregator.sol` - a simplified version of Chainlink's aggregator for testing.

### 10.2 Update HelperConfig

Import mock and add constants:

```solidity
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;  // $2000 per ETH
```

Rename and implement `getOrCreateAnvilEthConfig()`:

```solidity
function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
    // Check if already deployed
    if (activeNetworkConfig.priceFeed != address(0)) {
        return activeNetworkConfig;
    }

    // Deploy mock
    vm.startBroadcast();
    MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
    vm.stopBroadcast();

    return NetworkConfig({priceFeed: address(mockPriceFeed)});
}
```

**Key points:**
- Check if mock already exists to avoid re-deployment
- Use `vm.startBroadcast()` to deploy mock to Anvil
- Returns mock address as price feed

### 10.3 Fix Version Test for Multiple Networks

Update test to handle different networks:

```solidity
function testPriceFeedVersionIsAccurate() public {
    uint256 version = fundMe.getVersion();
    
    if (block.chainid == 11155111) {
        assertEq(version, 4);  // Sepolia
    } else if (block.chainid == 1) {
        assertEq(version, 6);  // Mainnet
    } else {
        assertTrue(version > 0);  // Anvil mock
    }
}
```

## 11. Writing Comprehensive Tests

### 11.1 Improve Contract Testability

**Make state variables private** and add getter functions:

```solidity
// Before: public (exposes internal state)
mapping(address => uint256) public addressToAmountFunded;
address[] public funders;

// After: private with getters (better encapsulation)
mapping(address => uint256) private s_addressToAmountFunded;
address[] private s_funders;
AggregatorV3Interface private s_priceFeed;

function getAddressToAmountFunded(address fundingAddress) external view returns (uint256) {
    return s_addressToAmountFunded[fundingAddress];
}

function getFunder(uint256 index) external view returns (address) {
    return s_funders[index];
}
```

### 11.2 Setup Test Infrastructure

```solidity
contract FundMeTest is Test {
    FundMe fundMe;
    
    address USER = makeAddr("user");  // Create test address
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);  // Give USER test ETH
    }
}
```

### 11.3 Test Fund Function

**Test insufficient ETH revert:**

```solidity
function testFundFailsWithoutEnoughETH() public {
    vm.expectRevert();  // Expect next line to revert
    fundMe.fund();  // Send 0 ETH, should fail
}
```

**Test fund updates data structure:**

```solidity
function testFundUpdatesFundedDataStructure() public {
    vm.prank(USER);  // Next tx sent by USER
    fundMe.fund{value: SEND_VALUE}();

    uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
    assertEq(amountFunded, SEND_VALUE);
}
```

### 11.4 Run Tests

```bash
# Run all tests
forge test

# Run specific test
forge test -mt testFundFailsWithoutEnoughETH

# Run with detailed output
forge test -vvv

# Check test coverage
forge coverage
```

### Current Test Coverage

![forge_coverage.png](./img/test_issues_solution/forge_coverage.png)

**Key Cheat Codes Used:**
- `makeAddr("name")`: Create labeled test address
- `vm.deal(address, amount)`: Give address ETH
- `vm.prank(address)`: Next call sent by address
- `vm.expectRevert()`: Expect next call to fail