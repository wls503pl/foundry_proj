# Foundry Lottery

## What is This?

A fully automated, blockchain-based lottery system built with **Foundry** - a blazingly fast, modern Ethereum development framework. Anyone can participate and winners are selected through verifiable randomness. Think of it as a transparent, tamper-proof raffle that runs itself.

## Why This Matters

Traditional lotteries require trust in the organizers. With blockchain technology and cryptographic randomness, this lottery is:

-   **Provably Fair**: Every draw uses Chainlink's verifiable random numbers - no one can manipulate the outcome
-   **Fully Transparent**: All transactions and participants are visible on the blockchain
-   **Automated**: No human intervention needed - the lottery runs itself at fixed intervals
-   **Trustless**: Smart contracts guarantee the winner receives the prize automatically

## How It Works

1. **Enter the Raffle**: Pay the entrance fee to buy a ticket
2. **Wait for the Draw**: The lottery automatically draws a winner after a set time period
3. **Winner Selected**: A random winner is chosen using Chainlink VRF (Verifiable Random Function)
4. **Prize Awarded**: The winner automatically receives the entire prize pool
5. **New Round Starts**: The lottery resets and a new round begins immediately

## Key Features

-   🎫 **Simple Entry**: Just send the entrance fee to participate
-   ⏰ **Time-Based Rounds**: Predictable drawing schedule
-   🎲 **True Randomness**: Powered by Chainlink VRF 2.5
-   🔄 **Continuous Operation**: Automatically starts new rounds after each draw
-   💰 **Instant Payouts**: Winners receive funds immediately via smart contract
-   ⚡ **Built with Foundry**: Enjoy rapid development, testing, and deployment

## Technology Stack

-   **Development Framework**: Foundry - Fast, portable, and modular toolkit for Ethereum application development
    -   Written in Rust for maximum performance
    -   Built-in testing with Solidity
    -   Lightning-fast compilation and testing
    -   No JavaScript dependencies required
-   **Smart Contracts**: Solidity ^0.8.18
-   **Randomness Provider**: Chainlink VRF 2.5
-   **Blockchain**: Ethereum-compatible networks

## Project Status

🚧 **In Development** - Currently implementing Chainlink VRF integration for random winner selection.

## Getting Started

### Prerequisites

-   [Foundry](https://book.getfoundry.sh/getting-started/installation)
-   Basic understanding of Ethereum and smart contracts

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd foundry_lottery

# Install dependencies (Foundry automatically manages Solidity dependencies)
forge install

# Build the project (Foundry compiles at lightning speed!)
forge build

# Run tests (Foundry's native Solidity testing - no JavaScript needed)
forge test

# Run tests with gas reporting
forge test --gas-report

# Deploy to local testnet
anvil  # Start local Ethereum node
forge script script/DeployRaffle.s.sol --rpc-url http://localhost:8545 --broadcast
```

### Why Foundry?

This project leverages Foundry's powerful features:

-   **⚡ Speed**: 10-100x faster than Hardhat/Truffle
-   **🧪 Solidity Testing**: Write tests in Solidity, not JavaScript
-   **🔧 Built-in Tools**: Anvil (local node), Cast (CLI interactions), Forge (build/test)
-   **📦 Simple Dependencies**: Git submodules for easy package management
-   **🎯 Developer Experience**: Fast iteration cycles and excellent debugging

## License

MIT License

## Author

Peile Wu (peile.wu.1990@gmail.com)

## Learn More

-   [What is Blockchain?](https://ethereum.org/en/developers/docs/intro-to-ethereum/)
-   [How Does Chainlink VRF Work?](https://docs.chain.link/vrf)
-   [Smart Contract Security](https://ethereum.org/en/developers/docs/smart-contracts/security/)
