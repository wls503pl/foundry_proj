# Foundry FundMe Development Guide

## 1. Project Initialization

```bash
mkdir foundry_fund_me && cd foundry_fund_me
forge init
forge test  # Verify default project works
```

Delete Foundry's auto-generated files:

```bash
rm src/*.sol script/*.sol test/*.sol
```

## 2. Create Contracts

Create **FundMe.sol** and **PriceConverter.sol** in `src/` directory.

## 3. Solve Compilation Errors

Run `forge compile` and you'll encounter import errors:

![forge_compiling_errors.png](./img/test_issues_solution/forge_compiling_errors.png)

**Solution**: Install Chainlink dependencies

```bash
forge install smartcontractkit/chainlink-brownie-contracts@1.3.0
```

The missing file path:

```
lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol
```

**Configure remappings** in `foundry.toml`:

```toml
remappings = ["@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/"]
```

Now `forge compile` should pass.

## 4. Importance of Testing

> **Key Points**:
>
> -   Deploying smart contracts without tests will be rejected in audits
> -   No tests = immature code
> -   Writing excellent tests differentiates great developers from mediocre ones

## 5. Write Tests

Create **FundMeTest.t.sol** in `test/`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    function setUp() external {
        fundMe = new FundMe();
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.i_owner(), address(this));
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }
}
```

Run tests with visibility flag:

```bash
forge test -vv
```

![vv_show.png](./img/test_issues_solution/vv_show.png)

## 6. Understanding EVM Revert Error

The `testPriceFeedVersionIsAccurate()` test fails:

![evm_revert_error.png](./img/test_issues_solution/evm_revert_error.png)

Check details with `-vvv`:

![vvv_show.png](./img/test_issues_solution/vvv_show.png)

**Root Cause**: When running `forge test` without specifying an RPC URL, Foundry spins up a temporary blank Anvil chain and deletes it after testing. The hardcoded Chainlink price feed address doesn't exist on this blank chain.

**Solution**: Fork a real network

Create `.env`:

```bash
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
```

Load and run:

```bash
source .env
forge test -vvv --fork-url $SEPOLIA_RPC_URL
```

Test now passes:

![run_test_specified_chain.png](./img/test_issues_solution/run_test_specified_chain.png)

## 7. Four Types of Tests

-   **Unit**: Testing a specific part of code
-   **Integration**: Testing how code works with other parts
-   **Forked**: Testing code on a simulated real environment
-   **Staging**: Testing code in a real environment (not production)

## 8. Making Contracts Modular and Chain-Agnostic

### Problem with Hardcoded Addresses

The initial contract implementation hardcodes the Chainlink price feed address for Sepolia network, making it deployable only to Sepolia. This lack of modularity prevents deployment to other networks like Ethereum mainnet, Polygon, or local Anvil chains.

### Solution: Constructor-Based Configuration

To make the contract modular and deployable across different chains, we refactor it to accept the price feed address as a constructor parameter. This allows us to specify the appropriate address for each network at deployment time.

### Key Changes

#### 8.1 FundMe Contract Refactoring

**Add state variable for price feed:**

```solidity
AggregatorV3Interface public s_priceFeed;
```

**Modify constructor to accept address:**

```solidity
constructor(address priceFeed) {
    i_owner = msg.sender;
    s_priceFeed = AggregatorV3Interface(priceFeed);
}
```

**Update functions to use instance variable:**

```solidity
function fund() public payable {
    require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
    addressToAmountFunded[msg.sender] += msg.value;
    funders.push(msg.sender);
}

function getVersion() public view returns (uint256) {
    return s_priceFeed.version();
}
```

#### 8.2 PriceConverter Library Updates

**Pass price feed as parameter to functions:**

```solidity
function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
    (, int256 answer, , , ) = priceFeed.latestRoundData();
    return uint256(answer * 10000000000);
}

function getConversionRate(
    uint256 ethAmount,
    AggregatorV3Interface priceFeed
) internal view returns (uint256) {
    uint256 ethPrice = getPrice(priceFeed);
    uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
    return ethAmountInUsd;
}
```

#### 8.3 Deployment Script Enhancement

**Update DeployFundMe.s.sol:**

```solidity
function run() external returns (FundMe) {
    vm.startBroadcast();
    FundMe fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    vm.stopBroadcast();
    return fundMe;
}
```

The deployment script now:

-   Returns the deployed `FundMe` instance for testing purposes
-   Passes the price feed address during contract instantiation
-   Can be easily modified to use different addresses for different networks

#### 8.4 Test File Updates

**Update FundMeTest.t.sol:**

```solidity
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.i_owner(), msg.sender);
    }

    // Other tests remain the same
}
```

**Key test changes:**

-   Tests now use the deployment script instead of directly instantiating `FundMe`
-   Owner assertion updated from `address(this)` to `msg.sender` to reflect proper deployment flow
-   This approach ensures tests mirror actual deployment behavior

### Benefits of This Refactoring

1. **Multi-chain Support**: Can deploy to any network by providing the correct price feed address
2. **Better Testing**: Can test on local Anvil chains with mock price feeds
3. **Cleaner Architecture**: Separation of concerns between contract logic and network configuration
4. **Maintainability**: Easy to update addresses without modifying core contract code
5. **Reusability**: Same contract code works across all EVM-compatible chains
