// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test{
    FundMe fundMe;

    // Set up a mock user
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    // Here we deploy the contract
    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);    // give USER some ETH
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        
        if (block.chainid == 11155111) {
            // Sepolia
            assertEq(version, 4);
        } else if (block.chainid == 1) {
            // Mainnet
            assertEq(version, 6);
        } else {
            // Anvil mock
            assertTrue(version > 0);
        }
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();  // expect rhe next line to revert
        // assert this tx fails/reverts
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // next tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testAddsFunderToArrayOfFunders() public {
        // prank the tx sender to be USER
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        // vm.prank will be ignored by vm.expectRevert
        vm.prank(USER);
        // USER is not the owner, it can't withdraw money, so this should revert
        fundMe.withdraw();
    }

    function testWithDrawWithASingleFunder() public funded {
        // Arrange: check balance before withdraw

        // owner balance in his own wallet
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        // balance of the FundMe contract
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act: ensure it is owner can withdraw
        uint256 gasStart = gasleft();   // gasleft() is a solidity built-in function, telling how many gas left after tx call
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;    // tx.gasprice buildt in solidity, telling current gas price
        console.log(gasUsed);

        // Assert:
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        // Withdraw all funds in the contract at once
        assertEq(endingFundMeBalance, 0);

        // Owner balance should increase by the amount withdrawn
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        // uint160 to avoid overflow when converting to address
        // ask claude for details
        uint160 numberOfFunders = 10;
        // Sometimes, address 0 is inverted, and no operations are allowed on it.
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // hoax: Sets up a prank from an address that has some ether.
            // See "book.getfoundry.sh/reference/forge-std/hoax"

            // vm.prank new address
            // vm.deal new address
            hoax(address(i), SEND_VALUE);

            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        assertEq(address(fundMe).balance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, fundMe.getOwner().balance);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        // uint160 to avoid overflow when converting to address
        // ask claude for details
        uint160 numberOfFunders = 10;
        // Sometimes, address 0 is inverted, and no operations are allowed on it.
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // hoax: Sets up a prank from an address that has some ether.
            // See "book.getfoundry.sh/reference/forge-std/hoax"

            // vm.prank new address
            // vm.deal new address
            hoax(address(i), SEND_VALUE);

            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert
        assertEq(address(fundMe).balance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, fundMe.getOwner().balance);
    }
}