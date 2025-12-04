# Foundry FundMe Project

A decentralized crowdfunding smart contract built with Foundry that demonstrates professional Solidity development practices, comprehensive testing strategies, and gas optimization techniques.

## Overview

FundMe is a smart contract that allows users to send ETH and enables the contract owner to withdraw collected funds. The project showcases multi-chain deployment, proper testing methodologies, and real-world optimization patterns.

## Key Features

-   **Multi-Chain Support**: Deploy to any EVM network (Sepolia, Mainnet, local Anvil) with automatic network detection
-   **Chainlink Integration**: Uses Chainlink Price Feeds to enforce minimum USD funding requirements
-   **Modular Architecture**: Chain-agnostic design with configurable price feed addresses
-   **Comprehensive Testing**: Unit tests, integration tests, and forked network testing
-   **Gas Optimized**: Implements storage caching and other optimization techniques

## Project Structure

```
foundry_fund_me/
├── src/
│   ├── FundMe.sol              # Main crowdfunding contract
│   └── PriceConverter.sol      # ETH/USD price conversion library
├── script/
│   ├── DeployFundMe.s.sol      # Deployment script
│   ├── HelperConfig.s.sol      # Multi-chain configuration
│   └── Interactions.s.sol      # Fund & withdraw scripts
├── test/
│   ├── unit/                   # Unit tests for individual functions
│   ├── integration/            # End-to-end workflow tests
│   └── mocks/                  # Mock contracts for local testing
└── foundry.toml                # Foundry configuration
```

## Quick Start

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd foundry_fund_me

# Install dependencies
forge install

# Compile contracts
forge build
```

### Testing

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vv

# Run specific test types
forge test --match-path test/unit/*
forge test --match-path test/integration/*

# Check test coverage
forge coverage

# Create gas snapshot
forge snapshot
```

### Deployment

```bash
# Local deployment (Anvil)
forge script script/DeployFundMe.s.sol

# Testnet deployment (e.g., Sepolia)
forge script script/DeployFundMe.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

### Interactions

```bash
# Fund the contract
forge script script/Interactions.s.sol:FundFundMe --rpc-url $RPC_URL --broadcast

# Withdraw funds
forge script script/Interactions.s.sol:WithdrawFundMe --rpc-url $RPC_URL --broadcast
```

## Core Concepts Demonstrated

### 1. Multi-Chain Configuration

The `HelperConfig` contract automatically detects the network and provides appropriate addresses:

-   **Sepolia**: Uses real Chainlink price feed
-   **Mainnet**: Uses production Chainlink price feed
-   **Anvil**: Deploys mock contracts for local testing

### 2. Testing Strategy

**Unit Tests** - Test individual contract functions in isolation

-   Minimum USD requirement validation
-   Owner-only withdrawal restrictions
-   Funder tracking accuracy

**Integration Tests** - Test complete user workflows

-   Deploy → Fund → Withdraw cycle
-   Multi-user funding scenarios
-   Script execution validation

**Forked Tests** - Test on simulated real networks

```bash
forge test --fork-url $SEPOLIA_RPC_URL
```

### 3. Gas Optimization

The project demonstrates practical gas optimization:

```solidity
// Before: Reads storage every loop iteration
for (uint256 i = 0; i < s_funders.length; i++) { ... }

// After: Caches storage in memory once
uint256 fundersLength = s_funders.length;
for (uint256 i = 0; i < fundersLength; i++) { ... }
```

**Gas Savings**: Verified using `forge snapshot`

### 4. Best Practices

-   ✅ Private state variables with public getters for better encapsulation
-   ✅ Custom errors for gas-efficient reverts
-   ✅ Immutable variables for deployment-time constants
-   ✅ Modifiers for access control and code reuse
-   ✅ Events for off-chain tracking (not shown in snippets)

## Key Dependencies

-   **Foundry**: Smart contract development framework
-   **Chainlink Contracts**: Price feed integrations
-   **Foundry DevOps**: Automatic contract address detection for scripts

## Testing Coverage

Current test coverage: **~85% lines, ~91% statements**

Test suite includes:

-   ✅ 9 comprehensive test cases
-   ✅ Unit tests for core functionality
-   ✅ Integration tests for complete workflows
-   ✅ Gas optimization validations
-   ✅ Multi-network compatibility checks

## Configuration

### foundry.toml

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
remappings = ["@chainlink/contracts/=lib/chainlink-brownie-contracts/contracts/"]
ffi = true  # Required for foundry-devops

[profile.zksync]
# ZKSync-specific configuration (if needed)
```

### Environment Variables

```bash
SEPOLIA_RPC_URL=<your-rpc-url>
PRIVATE_KEY=<your-private-key>
ETHERSCAN_API_KEY=<your-api-key>
```

## Learning Outcomes

This project teaches:

1. **Professional Testing**: How to write comprehensive test suites that auditors expect
2. **Multi-Chain Development**: Building contracts that work across different networks
3. **Gas Optimization**: Practical techniques to reduce transaction costs
4. **Development Workflow**: Using scripts for deployment and interaction automation
5. **Code Organization**: Structuring projects for maintainability and scalability

## Resources

-   [Foundry Book](https://book.getfoundry.sh/)
-   [Chainlink Documentation](https://docs.chain.link/)
-   [Solidity Gas Optimization](https://www.evm.codes/)
-   [Solidity Storage Layout](https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html)

## License

MIT

---

**Note**: This is an educational project demonstrating best practices in smart contract development. Always conduct thorough audits before deploying to mainnet.
