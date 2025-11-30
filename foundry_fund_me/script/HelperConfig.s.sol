// SPDX_License-Identifier: MIT
pragma solidity ^0.8.18;

// Deploy mocks when on a local anvil chain
// Keep track of contract addresses across different chains

// Sepolia ETH/USD Price Feed Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
// Mainnet ETH/USD Price Feed Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419

import {Script} from "forge-std/Script.sol";

contract HelperConfig {
    // If on a local anvil, deploy mocks
    // Otherwise, grab the existing address from the live network

    struct NetworkConfig {
        address priceFeed;  // ETH/USD price feed address
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
        // price feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        // price feed address
        NetworkConfig memory ethConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return ethConfig;
    }

    function getAnvilEthConfig() public pure returns (NetworkConfig memory) {
        // price feed address
        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306  // Use Sepolia address as placeholder
        });
        return anvilConfig;
    }
}