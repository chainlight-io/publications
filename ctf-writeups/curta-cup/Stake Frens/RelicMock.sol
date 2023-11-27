// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {CommonBase} from "forge-std/Base.sol";
import {IReliquary} from "relic-sdk/packages/contracts/interfaces/IReliquary.sol";
import {IProver} from "relic-sdk/packages/contracts/interfaces/IProver.sol";
import {Fact} from "relic-sdk/packages/contracts/lib/Facts.sol";

// mock prover, only used during foundry testing
contract MockProver is IProver {
    function prove(bytes calldata proof, bool ) external payable returns (Fact memory fact) {
        fact = abi.decode(proof, (Fact));
    }
}

contract RelicMock is CommonBase {
    IReliquary immutable reliquary;
    address immutable governor;

    constructor(IReliquary _reliquary, address _governor) {
        reliquary = _reliquary;
        governor = _governor;
    }

    function setupMockProver() internal returns (address prover) {
        MockProver mock = new MockProver();
        prover = address(mock);

        vm.prank(governor);
        reliquary.addProver(prover, 0x133333337);
        vm.warp(block.timestamp + reliquary.DELAY() + 1);
        reliquary.activateProver(prover);
        vm.prank(governor);
        reliquary.setProverFee(
            prover,
            IReliquary.FeeInfo(
                uint8(IReliquary.FeeFlags.FeeNone),
                0,
                0,
                0,
                0
            ),
            address(0)
        );

        return address(mock);
    }

    function mockProof(Fact memory fact) public pure returns (bytes memory proof) {
        proof = abi.encode(fact);
    }
}
