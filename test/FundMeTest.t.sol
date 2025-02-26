// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe public fundMe;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        // vm.deal(address(this), 100 ether);
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        console.log(fundMe.i_owner());
        console.log(msg.sender);
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }
}
//steps tpo test
//forge test -vvv
//source .env
//echo $SEPOLIA_RPC_URL
//forge test --fork-url $SEPOLIA_RPC_URL
//forge coverage --fork-url $SEPOLIA_RPC_URL
//forge test --mt testPriceFeedVersionIsAccurate --fork-url $SEPOLIA_RPC_URL
