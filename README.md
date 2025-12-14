# Foundry Projects Collection

A comprehensive collection of smart contract projects built with **Foundry**, demonstrating professional Solidity development practices from basics to advanced implementations.

## 🎯 What is This Repository?

This repository contains three progressive projects that teach blockchain development using **Foundry** - the fastest and most modern Ethereum development framework. Each project builds upon the previous one, introducing new concepts and best practices.

**Why Foundry?**
- ⚡ **Lightning Fast**: 10-100x faster than traditional frameworks
- 🧪 **Solidity Testing**: Write tests in Solidity, not JavaScript  
- 🛠️ **All-in-One Toolkit**: Build, test, deploy, and interact - all in one framework
- 🚀 **Production Ready**: Used by top DeFi protocols and auditing firms

---

## 📚 Projects Overview

### Project 1: Simple Storage
**Location**: [`foundry_simple_storage/`](./foundry_simple_storage)

**What it does**: A basic smart contract that stores and retrieves a favorite number.

**Learning Goals**:
- Introduction to Foundry framework
- Basic Solidity syntax and contract structure
- Simple deployment and interaction
- Understanding storage in smart contracts

**Key Concepts**: Contract basics, state variables, functions, Foundry CLI commands

---

### Project 2: FundMe - Crowdfunding Platform
**Location**: [`foundry_fund_me/`](./foundry_fund_me)

**What it does**: A decentralized crowdfunding contract where users can donate ETH and the owner can withdraw funds.

**Real-World Use Case**: Like Kickstarter, but on blockchain - transparent, trustless, and unstoppable.

**Key Features**:
- 💰 **Minimum Donation**: Enforces $5 minimum using Chainlink Price Feeds
- 🌍 **Multi-Chain**: Works on Sepolia testnet, mainnet, and local networks
- 👥 **Funder Tracking**: Records all contributors and their amounts
- 🔒 **Owner Control**: Only contract owner can withdraw funds
- ⚡ **Gas Optimized**: Implements caching and optimization techniques

**Learning Goals**:
- Integrate external data (Chainlink Price Feeds)
- Multi-chain deployment strategies
- Comprehensive testing (unit, integration, fork tests)
- Gas optimization techniques
- Professional project structure

**Technical Highlights**:
- Uses Chainlink oracles for ETH/USD conversion
- Demonstrates storage vs memory optimization
- Implements modular architecture with helper contracts
- Includes deployment and interaction scripts

**Test Coverage**: ~85% lines, 9 comprehensive test cases

[📖 Full Documentation](./foundry_fund_me/FoundryFundMeProject.md)

---

### Project 3: Raffle - Automated Lottery System
**Location**: [`foundry_lottery/`](./foundry_lottery)

**What it does**: A fully automated, provably fair lottery that runs itself - no human intervention needed.

**Real-World Use Case**: Like a transparent lottery that picks winners automatically every 30 seconds, pays them instantly, and starts a new round immediately.

**Key Features**:
- 🎲 **Provably Fair**: Uses Chainlink VRF for verifiable randomness
- 🤖 **Fully Automated**: Chainlink Automation triggers draws automatically
- ⏱️ **Time-Based**: Draws happen at regular intervals (configurable)
- 💸 **Instant Payouts**: Winners receive ETH immediately via smart contract
- 🔄 **Continuous**: Automatically resets and starts new rounds

**Learning Goals**:
- Advanced Chainlink integration (VRF + Automation)
- State machine design patterns
- Security best practices (CEI pattern, state locking)
- Complex testing strategies (unit, integration, fuzz, fork)
- Production-ready contract development

**Technical Highlights**:
- **Chainlink VRF**: Cryptographically secure random number generation
- **Chainlink Automation**: Self-executing smart contracts with upkeep monitoring
- **Two-Transaction Model**: Secure randomness request → callback pattern
- **State Management**: OPEN ↔ CALCULATING state transitions
- **Event-Driven**: Comprehensive event logging for frontend integration

**How It Works**:
1. Players enter by paying 0.01 ETH
2. After 30 seconds + conditions met, Automation triggers draw
3. VRF generates random number to select winner
4. Winner receives entire prize pool automatically
5. New round starts immediately

**Test Coverage**: 68% lines, 14 integration tests + 12 unit tests + 1024 fuzz runs

**Demo Balances**:
- VRF Subscription: 12 LINK + 0.1 ETH (pays for randomness)
- Automation Upkeep: 1.5 LINK (pays for automatic execution)

[📖 Full Documentation](./foundry_lottery/README.md)

---

## 🎓 Learning Path

**Recommended Order**:

1. **Start with Project 1** (Simple Storage)
   - Get familiar with Foundry basics
   - Learn contract deployment and interaction
   - Understand basic Solidity syntax

2. **Progress to Project 2** (FundMe)
   - Learn oracle integration
   - Practice professional testing
   - Master gas optimization
   - Understand multi-chain development

3. **Advance to Project 3** (Raffle)
   - Master advanced Chainlink features
   - Implement complex state machines
   - Build production-ready contracts
   - Deploy fully automated systems

---

## 🚀 Quick Start

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Basic understanding of blockchain concepts
- MetaMask wallet (for testnet deployments)

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd foundry_proj

# Navigate to any project
cd foundry_lottery  # or foundry_fund_me, foundry_simple_storage

# Install dependencies
forge install

# Build contracts
forge build

# Run tests
forge test

# Run tests with details
forge test -vvv
```

### Testing Commands

```bash
# Run all tests
forge test

# Run with gas reporting
forge test --gas-report

# Run with coverage
forge coverage

# Fork test on Sepolia
forge test --fork-url $SEPOLIA_RPC_URL

# Run specific test
forge test --match-test testFunctionName -vvv
```

---

## 📊 Projects Comparison

| Feature | Simple Storage | FundMe | Raffle |
|---------|---------------|---------|---------|
| **Complexity** | Beginner | Intermediate | Advanced |
| **External Integrations** | None | Chainlink Price Feeds | VRF + Automation |
| **Testing Types** | Basic | Unit + Integration + Fork | Unit + Integration + Fuzz + Fork |
| **Gas Optimization** | None | Yes (caching) | Yes (immutables, custom errors) |
| **State Management** | Simple | Moderate | Complex (state machine) |
| **Automation** | Manual | Manual | Fully Automated |
| **Real-World Ready** | Learning Only | Yes | Yes |

---

## 🛠️ What You'll Master

By completing these projects, you'll learn:

### Foundry Framework
- ⚡ Fast compilation and testing
- 🧪 Solidity-based testing
- 📜 Deployment scripts
- 🔧 CLI tools (forge, cast, anvil)

### Smart Contract Development
- 📝 Solidity best practices
- 🔒 Security patterns (CEI, state locking)
- ⚙️ Gas optimization techniques
- 🎯 Custom errors and events

### Chainlink Services
- 📊 Price Feeds (decentralized data)
- 🎲 VRF (verifiable randomness)
- 🤖 Automation (self-executing contracts)

### Testing Strategies
- 🧪 Unit testing (isolated functions)
- 🔗 Integration testing (full workflows)
- 🎲 Fuzz testing (random inputs)
- 🍴 Fork testing (real network simulation)

### Professional Practices
- 📁 Project organization
- 🌍 Multi-chain deployment
- 📚 Comprehensive documentation
- ✅ High test coverage

---

## 📖 Additional Resources

### Foundry
- [Foundry Book](https://book.getfoundry.sh/) - Official documentation
- [Foundry GitHub](https://github.com/foundry-rs/foundry) - Source code

### Chainlink
- [Chainlink Documentation](https://docs.chain.link/) - All services
- [VRF Documentation](https://docs.chain.link/vrf) - Randomness
- [Automation Documentation](https://docs.chain.link/chainlink-automation) - Upkeep

### Solidity
- [Solidity Documentation](https://docs.soliditylang.org/) - Official docs
- [Ethereum.org](https://ethereum.org/en/developers/) - Developer resources

---

## 📄 License

MIT License - See individual project directories for details.

## 👨‍💻 Author

**Peile Wu**  
Email: peile.wu.1990@gmail.com

---

**Ready to Start?** Begin with [Simple Storage](./foundry_simple_storage) and work your way up! 🚀