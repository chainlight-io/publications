// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { AirdropLike, Challenge } from "../src/Challenge.sol";
import { CommonBase } from "forge-std/Base.sol";
import "forge-std/console.sol";

import { Solver } from "../src/Solver.sol";

contract Solve is CommonBase {
    Challenge chal;
    uint256 privKey;

    constructor() {
        chal = Challenge(vm.envAddress("CHAL_ADDR"));
        privKey = uint256(vm.envBytes32("PRIV_KEY"));
    }

    function randomAddress(uint256 seed) private view returns (uint256, address) {
        bytes32 v = keccak256(abi.encodePacked((seed >> 128) | (seed << 128)));
        return (uint256(keccak256(abi.encodePacked(seed))), address(bytes20(v)));
    }

    function randomUint(uint256 seed, uint256 min, uint256 max) private view returns (uint256, uint256) {
        bytes32 v = keccak256(abi.encodePacked((seed >> 128) | (seed << 128)));
        return (uint256(keccak256(abi.encodePacked(seed))), uint256(v) % (max - min) + min);
    }

    function computeContractAddress(address _origin, uint _nonce) internal pure returns (address _address) {
        bytes memory data;
        if(_nonce == 0x00)          data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, bytes1(0x80));
        else if(_nonce <= 0x7f)     data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, uint8(_nonce));
        else if(_nonce <= 0xff)     data = abi.encodePacked(bytes1(0xd7), bytes1(0x94), _origin, bytes1(0x81), uint8(_nonce));
        else if(_nonce <= 0xffff)   data = abi.encodePacked(bytes1(0xd8), bytes1(0x94), _origin, bytes1(0x82), uint16(_nonce));
        else if(_nonce <= 0xffffff) data = abi.encodePacked(bytes1(0xd9), bytes1(0x94), _origin, bytes1(0x83), uint24(_nonce));
        else                        data = abi.encodePacked(bytes1(0xda), bytes1(0x94), _origin, bytes1(0x84), uint32(_nonce));
        _address = address(bytes20(keccak256(data)<<96));
    }

    function run() public {
        vm.roll(block.number+1);
        string[] memory inputs = new string[](200);
        inputs[0] = "huffc";
        inputs[1] = vm.envString("AIRDROP");
        inputs[2] = "--bytecode";
        uint256 idx = 3;

        uint256 seed = uint256(blockhash(block.number - 1));
        address[] memory recipients = new address[](16);
        uint256[] memory amounts = new uint[](16);
        for (uint256 i = 0; i < 16; i++) {
            (seed, recipients[i]) = randomAddress(seed);
            (seed, amounts[i]) = randomUint(seed, 1 ether, 5 ether);
            inputs[idx++] = string.concat(
                string.concat(
                    string.concat(
                        "-cETH_RECIPIENT",
                        vm.toString(i)
                    ),
                    "="
                ),
                vm.toString(recipients[i])
            );
            inputs[idx++] = string.concat(
                string.concat(
                    string.concat(
                        "-cETH_AMOUNT",
                        vm.toString(i)
                    ),
                    "="
                ),
                vm.toString(bytes32(amounts[i]))
            );
        }

        for (uint256 i = 0; i < 16; i++) {
            (seed, recipients[i]) = randomAddress(seed);
            (seed, amounts[i]) = randomUint(seed, 1 ether, 5 ether);
            inputs[idx++] = string.concat(
                string.concat(
                    string.concat(
                        "-cERC20_RECIPIENT",
                        vm.toString(i)
                    ),
                    "="
                ),
                vm.toString(recipients[i])
            );
            inputs[idx++] = string.concat(
                string.concat(
                    string.concat(
                        "-cERC20_AMOUNT",
                        vm.toString(i)
                    ),
                    "="
                ),
                vm.toString(bytes32(amounts[i]))
            );
        }

        uint256 startId;
        (seed, startId) = randomUint(seed, 0, type(uint256).max);
        for (uint256 i = 0; i < 16; i++) {
            (seed, recipients[i]) = randomAddress(seed);
            amounts[i] = startId++;
            inputs[idx++] = string.concat(
                string.concat(
                    string.concat(
                        "-cERC721_RECIPIENT",
                        vm.toString(i)
                    ),
                    "="
                ),
                vm.toString(recipients[i])
            );
            inputs[idx++] = string.concat(
                string.concat(
                    string.concat(
                        "-cERC721_AMOUNT",
                        vm.toString(i)
                    ),
                    "="
                ),
                vm.toString(bytes32(amounts[i]))
            );
        }

        inputs[idx++] = string.concat("-cERC20_TOKEN=", vm.toString(computeContractAddress(address(chal), 1)));
        inputs[idx++] = string.concat("-cERC721_TOKEN=", vm.toString(computeContractAddress(address(chal), 2)));
        assembly {
            mstore(inputs, idx)
        }

        bytes memory code = vm.parseBytes(vm.toString(vm.ffi(inputs)));
        vm.txGasPrice(0x44);
        new Solver(address(chal), code);

        console.logBytes(code);
    }
}
