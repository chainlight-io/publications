// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {IBox, AddressGame} from "../src/Challenge.sol";

contract MyBox is IBox {
    function isSolved() external view returns (bool) {
        return true;
    }
}

contract ChallengeTest is Test {
    AddressGame public challenge;

    function setUp() public {
        challenge = new AddressGame();
    }

    function test_Solve() public {
        // Solution: see profanity2.patch and https://github.com/1inch/profanity2
        address ATTACKER = 0xB49bf876BE26435b6fae1Ef42C3c82c5867Fa149;
        address DEPLOYER = vm.createWallet(0x000039ecc4b345efae348b37e89fef3678e6ed97715a2a3b053be81f528bdad2).addr;

        uint256 seed = challenge.generate(ATTACKER);
        console2.log(seed, challenge.box(seed, 0) % 2, challenge.box(seed, 1) % 3);

        vm.startPrank(DEPLOYER);
        uint256 solution = uint256(uint160(address(new MyBox())));
        assertEq(challenge.verify(seed, solution), true);
    }
}
