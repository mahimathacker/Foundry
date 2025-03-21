// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe public fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;

    uint256 STARTING_BALANCE = 10 ether;
    uint256 GAS_PRICE = 1;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); //Send Fake money
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        console.log(fundMe.getOwner());
        console.log(msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund(); //Send 0 value
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        //Arrange
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = address(fundMe.getOwner()).balance;

        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        //Assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = address(fundMe.getOwner()).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        //USe uint160 to generate random address instead of address(i)
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint256 i = startingFunderIndex; i < numberOfFunders; i++) {
            //prank //hoax does both => creates and send funds.
            //deal
            hoax(address(uint160(i)), SEND_VALUE);
            //fund the fundMe
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingContractBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = address(fundMe.getOwner()).balance;

        //Act
        uint256 gasStart = gasleft(); //to get the left gas price
        vm.txGasPrice(GAS_PRICE);
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);
        vm.stopPrank();

        //ASSERT
        assert(address(fundMe).balance == 0);
        assert(
            startingOwnerBalance + startingContractBalance ==
                address(fundMe.getOwner()).balance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        //USe uint160 to generate random address instead of address(i)
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint256 i = startingFunderIndex; i < numberOfFunders; i++) {
            //prank //hoax does both => creates and send funds.
            //deal
            hoax(address(uint160(i)), SEND_VALUE);
            //fund the fundMe
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingContractBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = address(fundMe.getOwner()).balance;

        //Act
        uint256 gasStart = gasleft(); //to get the left gas price
        vm.txGasPrice(GAS_PRICE);
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);
        vm.stopPrank();

        //ASSERT
        assert(address(fundMe).balance == 0);
        assert(
            startingOwnerBalance + startingContractBalance ==
                address(fundMe.getOwner()).balance
        );
    }

    //steps tpo test
    //forge test -vvv
    //source .env
    //echo $SEPOLIA_RPC_URL
    //forge test --fork-url $SEPOLIA_RPC_URL
    //forge coverage --fork-url $SEPOLIA_RPC_URL
    //forge test --mt testPriceFeedVersionIsAccurate --fork-url $SEPOLIA_RPC_URL
    //forge coverage
    //https://book.getfoundry.sh/cheatcodes/
    //chisel -> A testing tool for terminal
    /* 
    forge snapshot --mt testWithdrawFromMultipleFunders
    To get gasprice in the .gas-snapshot file
    */

    /* 
   
   Storage optimization:- 

    - global variables are stored in the storage of the contract with hax like [0] - 0x-113 
    
    */
}
