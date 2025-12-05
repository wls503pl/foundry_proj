// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title Lottery activity contract
 * @author Peile Wu(peile.wu.1990@gmail.com)
 * @notice This contract is for creating a sample raffle
 * @dev Implements Chainlink VRFv2.5
 */
contract Raffle {
    // Custom errors definition
    error raffle__notEnoughFeesToEnterRaffle();

    // Fee to buy a ticket which will be stored in the prize pool
    uint256 private immutable i_entranceFee;

    // The duration of the lottery in seconds
    uint256 private immutable i_interval;

    // Record player entering this game
    address payable[] private s_players;

    uint256 private s_lastTimeStamp;

    // Events
    event RaffleEntered(address indexed player);

    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    // People buy tickets and participate in this lottery.
    function enterRaffle() external payable {
        // to save gas, using custom error instead of require(..., string)
        if (msg.value < i_entranceFee)
        {
            revert raffle__notEnoughFeesToEnterRaffle();
        }
        s_players.push(payable(msg.sender));

        emit RaffleEntered(msg.sender);
    }

    /**
     * Select the winner and award him/her.
     * Steps:
     * 1. Get a random number
     * 2. Use that number to pick a player
     * 3. Be automatically called
     */
    function pickWinner() external {
        // check to see if enough time has passed
        if ((block.timestamp - s_lastTimeStamp) < i_interval) {
            revert();
        }

        /**
         * Get random number
         * Obtaining random numbers on a blockchain is quite difficult, primarily because a blockchain is a deterministic system by default.
         * You need to go to https://docs.chain.link/vrf to use Chain Link VRF 2.5 to actually obtain a provable random number.
         *
         * Obtaining a random number actually involves two transactions.
         * 1. First, a transaction must be made to request RNG.
         * 2. In the second transaction, the chained oracle will actually send us a transaction (or generate some random numbers on the chain).
         */
    }

    /**
     * Getter Functions
     */
    function getEntranceFee() external view returns (uint256)
    {
        return i_entranceFee;
    }
}
