# Submerged

## Challenge Background

This challenge is based on an observation: by using single-use addresses,
you can craft transactions such that a smart contract can verify the
transaction hash of the current transaction. As a result, we can write
a contract which simulates a hypothetical `TXHASH` opcode, which other
contracts can build upon.

There are a few interesting use cases for this primitive, but this
challenge was focused primarily on having challengers construct
transactions that could be verified by the `TxHashSimulator`.

## Solve Challenge

By modifying the code from the challenge files, we can write a foundry
script which constructs the raw transaction, derives the sender, and
tells us how much ETH to fund the sender with before broadcasting the
raw transaction:

```solidity
    function deriveRawTxAndSender(
        bytes32 seed,
        uint256 gasPrice,
        uint256 gasLimit,
        address to,
        uint256 value,
        bytes memory data
    ) public view returns(bytes memory rawTx, address sender) {
        uint8 v = 27;
        bytes32 r;
        bytes32 s;
        assembly {
            mstore(0, seed)
            r := keccak256(0, 32)
            mstore(0, r)
            s := keccak256(0, 32)
        }

        bytes[] memory txList = new bytes[](9);
        txList[0] = RLP.encodeUint(0); // nonce
        txList[1] = RLP.encodeUint(gasPrice); // gas price
        txList[2] = RLP.encodeUint(gasLimit); // claimed gasLimit
        txList[3] = RLP.encodeUint(uint256(uint160(to))); // to address
        txList[4] = RLP.encodeUint(value); // tx value
        txList[5] = RLP.encodeBytes(data); // tx data
        txList[6] = RLP.encodeUint(uint256(v)); // v
        txList[7] = RLP.encodeUint(uint256(r)); // r
        txList[8] = RLP.encodeUint(uint256(s)); // s
        rawTx = RLP.encodeList(txList);

        // truncate the tx fields to exclude the signature data
        assembly {
            mstore(txList, 6)
        }
        bytes32 signingHash = keccak256(RLP.encodeList(txList));
        sender = ecrecover(signingHash, v, r, s);
        require(sender != address(0), "ecrecover failed");
    }

    function solve(address solver, Submerged submerged) public view {
        TxHashSimulator simulator = submerged.simulator();
        bytes32 seed = keccak256(abi.encode(
            keccak256(abi.encode(solver)),
            uint256(0)
        ));
        uint256 gasPrice = 20 gwei; // TODO: configure based on current gas price
        uint256 gasLimit = 120000;
        uint256 value = 0;
        (bytes memory rawTx, address sender) = deriveRawTxAndSender(
            seed,
            gasPrice,
            gasLimit,
            address(simulator),
            value,
            abi.encodePacked(
                abi.encode(seed, gasLimit, address(submerged)),
                abi.encodeWithSelector(Submerged.proveSubmergedTx.selector)
            )
        );
        console2.log("Seed: ", vm.toString(seed));
        console2.log("Sender: ", sender);
        console2.log("Transfer amount: ", gasLimit * gasPrice + value);
        console2.log("Broadcast raw tx:", vm.toString(rawTx));
    }
```

After this, it's as simple as calling the `proveSubmergedSeed` method and passing
in the raw transaction bytes.
