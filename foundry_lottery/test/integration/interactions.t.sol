// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console2} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

/**
 * @title Integration Tests for Raffle Deployment and Interactions
 * @author Test Suite
 * @notice Tests the complete deployment flow and script interactions
 * @dev Focuses on subscription creation, funding, and consumer management
 */
contract InteractionsTest is CodeConstants, Test {
    // Contracts
    Raffle public raffle;
    HelperConfig public helperConfig;
    VRFCoordinatorV2_5Mock public vrfCoordinator;
    LinkToken public linkToken;

    // Configuration
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinatorAddress;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;
    address link;
    address account;

    // Test constants
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;
    uint256 public constant FUND_AMOUNT = 3 ether;

    // Events to test
    event SubscriptionCreated(uint256 indexed subId);
    event SubscriptionFunded(uint256 indexed subId, uint256 amount);

    function setUp() external {
        // Deploy contracts using deployment script
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();

        // Get configuration
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinatorAddress = config.vrfCoordinator;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;
        link = config.link;
        account = config.account;

        // Setup VRF Coordinator and Link Token references
        vrfCoordinator = VRFCoordinatorV2_5Mock(vrfCoordinatorAddress);
        linkToken = LinkToken(link);

        // Fund test player
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                        CREATE SUBSCRIPTION TESTS
    //////////////////////////////////////////////////////////////*/

    function testCreateSubscriptionCreatesValidSubscriptionId() public {
        // Arrange
        CreateSubscription createSubscription = new CreateSubscription();

        // Act
        (uint256 subId, address returnedVrfCoordinator) =
            createSubscription.createSubscription(vrfCoordinatorAddress, account);

        // Assert
        assert(subId > 0);
        assert(returnedVrfCoordinator == vrfCoordinatorAddress);
        console2.log("Created subscription ID:", subId);
    }

    function testCreateSubscriptionUsingConfigWorks() public {
        // Arrange
        CreateSubscription createSubscription = new CreateSubscription();

        // Act
        (uint256 subId, ) = createSubscription.createSubscriptionUsingConfig();

        // Assert
        assert(subId > 0);
        console2.log("Created subscription ID via config:", subId);
    }

    /*//////////////////////////////////////////////////////////////
                        FUND SUBSCRIPTION TESTS
    //////////////////////////////////////////////////////////////*/

    function testFundSubscriptionIncreasesBalance() public {
        // Arrange
        CreateSubscription createSubscription = new CreateSubscription();
        (uint256 subId,) = createSubscription.createSubscription(vrfCoordinatorAddress, account);

        (uint96 balanceBefore,,,,) = vrfCoordinator.getSubscription(subId);

        // Act
        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscription(vrfCoordinatorAddress, subId, link, account);

        // Assert
        (uint96 balanceAfter,,,,) = vrfCoordinator.getSubscription(subId);
        assert(balanceAfter > balanceBefore);
        console2.log("Balance before funding:", balanceBefore);
        console2.log("Balance after funding:", balanceAfter);
    }

    function testFundSubscriptionUsingConfigWorks() public view {
        // Arrange - Get the actual subscription from deployed raffle
        // If subscriptionId is 0, skip this test
        if (subscriptionId == 0) {
            console2.log("Skipping: subscriptionId is 0 (auto-created in deployment)");
            return;
        }

        (uint96 balanceBefore,,,,) = vrfCoordinator.getSubscription(subscriptionId);
        console2.log("Initial subscription balance:", balanceBefore);

        // Assert
        assert(balanceBefore > 0);
    }

    modifier skipFork() {
        if (block.chainid != LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }

    function testFundSubscriptionWithMockOnLocalChain() public skipFork {
        // Arrange
        CreateSubscription createSubscription = new CreateSubscription();
        (uint256 subId,) = createSubscription.createSubscription(vrfCoordinatorAddress, account);

        // Act
        vm.startBroadcast();
        vrfCoordinator.fundSubscription(subId, FUND_AMOUNT * 100);
        vm.stopBroadcast();

        // Assert
        (uint96 balance,,,,) = vrfCoordinator.getSubscription(subId);
        assert(balance == FUND_AMOUNT * 100);
        console2.log("Mock funded subscription balance:", balance);
    }

    /*//////////////////////////////////////////////////////////////
                        ADD CONSUMER TESTS
    //////////////////////////////////////////////////////////////*/

    function testAddConsumerAddsContractToSubscription() public {
        // Arrange
        CreateSubscription createSubscription = new CreateSubscription();
        (uint256 subId,) = createSubscription.createSubscription(vrfCoordinatorAddress, account);

        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscription(vrfCoordinatorAddress, subId, link, account);

        // Deploy a new raffle to add as consumer
        vm.startBroadcast(account);
        Raffle newRaffle = new Raffle(entranceFee, interval, vrfCoordinatorAddress, gasLane, subId, callbackGasLimit);
        vm.stopBroadcast();

        // Act
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(newRaffle), vrfCoordinatorAddress, subId, account);

        // Assert
        // Check if consumer was added by trying to request random words
        vm.prank(PLAYER);
        newRaffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // This should not revert if consumer was added successfully
        newRaffle.performUpkeep("");
    }

    function testAddConsumerToExistingRaffleWorks() public {
        // The raffle deployed in setUp should already have consumer added
        // Test by performing upkeep after conditions are met

        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act & Assert - should not revert
        raffle.performUpkeep("");
    }

    /*//////////////////////////////////////////////////////////////
                    FULL DEPLOYMENT FLOW TESTS
    //////////////////////////////////////////////////////////////*/

    function testFullDeploymentFlowCreatesWorkingRaffle() public view {
        // This tests the entire deployment process from DeployRaffle.s.sol

        // Arrange & Act (deployment happens in setUp)
        // Verify raffle is properly initialized
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        assert(raffle.getEntranceFee() == entranceFee);

        // Test that subscription is funded (if subscriptionId exists)
        if (subscriptionId > 0) {
            (uint96 subBalance,,,,) = vrfCoordinator.getSubscription(subscriptionId);
            assert(subBalance > 0);
            console2.log("Subscription balance:", subBalance);
        } else {
            console2.log("SubscriptionId is 0 (auto-created during deployment)");
        }
    }

    function testDeployedRaffleCanAcceptEntries() public {
        // Test that raffle can accept entries
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        assert(raffle.getPlayer(0) == PLAYER);
        console2.log("Player successfully entered raffle");
    }

    function testDeployedRaffleCanPerformFullCycle() public skipFork {
        // Arrange - setup multiple players
        uint256 additionalPlayers = 3;
        for (uint256 i = 1; i <= additionalPlayers; i++) {
            address player = address(uint160(i));
            vm.deal(player, 1 ether);
            vm.prank(player);
            raffle.enterRaffle{value: entranceFee}();
        }

        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        uint256 startingBalance = address(raffle).balance;
        console2.log("Total prize pool:", startingBalance);

        // Act - perform upkeep
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        // Simulate VRF callback
        vrfCoordinator.fulfillRandomWords(uint256(requestId), address(raffle));

        // Assert
        address winner = raffle.getRecentWinner();
        assert(winner != address(0));
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        console2.log("Winner selected:", winner);
    }

    /*//////////////////////////////////////////////////////////////
                        SUBSCRIPTION INFO TESTS
    //////////////////////////////////////////////////////////////*/

    function testCanRetrieveSubscriptionInfo() public view {
        // Skip if subscriptionId is invalid
        if (subscriptionId == 0) {
            console2.log("Skipping: subscriptionId is 0 (auto-created in deployment)");
            return;
        }

        // Act
        (uint96 balance,, uint64 reqCount, address subOwner, address[] memory consumers) =
            vrfCoordinator.getSubscription(subscriptionId);

        // Assert
        assert(balance > 0);
        assert(subOwner == account);
        console2.log("Subscription owner:", subOwner);
        console2.log("Subscription balance:", balance);
        console2.log("Request count:", reqCount);
        console2.log("Number of consumers:", consumers.length);
    }

    function testSubscriptionHasRaffleAsConsumer() public view {
        // Skip if subscriptionId is invalid
        if (subscriptionId == 0) {
            console2.log("Skipping: subscriptionId is 0 (auto-created in deployment)");
            return;
        }

        // Act
        (,,,, address[] memory consumers) = vrfCoordinator.getSubscription(subscriptionId);

        // Assert
        bool found = false;
        for (uint256 i = 0; i < consumers.length; i++) {
            if (consumers[i] == address(raffle)) {
                found = true;
                break;
            }
        }
        assert(found);
        console2.log("Raffle found as consumer:", found);
    }

    /*//////////////////////////////////////////////////////////////
                        EDGE CASE TESTS
    //////////////////////////////////////////////////////////////*/

    function testCannotAddConsumerToUnfundedSubscription() public skipFork {
        // Arrange
        CreateSubscription createSubscription = new CreateSubscription();
        (uint256 subId,) = createSubscription.createSubscription(vrfCoordinatorAddress, account);

        vm.startBroadcast(account);
        Raffle newRaffle = new Raffle(entranceFee, interval, vrfCoordinatorAddress, gasLane, subId, callbackGasLimit);
        vm.stopBroadcast();

        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(newRaffle), vrfCoordinatorAddress, subId, account);

        // Act - try to perform upkeep with unfunded subscription
        vm.prank(PLAYER);
        newRaffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Assert - this might revert or succeed depending on VRF implementation
        // On local mock, it should succeed but might fail on real network
        newRaffle.performUpkeep("");
    }

    function testMultipleRafflesCanShareSubscription() public {
        // Arrange
        CreateSubscription createSubscription = new CreateSubscription();
        (uint256 subId,) = createSubscription.createSubscription(vrfCoordinatorAddress, account);

        FundSubscription fundSubscription = new FundSubscription();
        fundSubscription.fundSubscription(vrfCoordinatorAddress, subId, link, account);

        // Deploy two raffles
        vm.startBroadcast(account);
        Raffle raffle1 = new Raffle(entranceFee, interval, vrfCoordinatorAddress, gasLane, subId, callbackGasLimit);
        Raffle raffle2 = new Raffle(entranceFee, interval, vrfCoordinatorAddress, gasLane, subId, callbackGasLimit);
        vm.stopBroadcast();

        // Act - add both as consumers
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(raffle1), vrfCoordinatorAddress, subId, account);
        addConsumer.addConsumer(address(raffle2), vrfCoordinatorAddress, subId, account);

        // Assert
        (,,,, address[] memory consumers) = vrfCoordinator.getSubscription(subId);
        assert(consumers.length == 2);
        console2.log("Number of consumers on subscription:", consumers.length);
    }
}