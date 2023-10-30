# Black Sheep

In this challenge we have to drain the `SimpleBank.huff` contract. It has two checks in place which attempt to avoid this.

## Check 1: CHECKVALUE
```
#define macro CHECKVALUE() = takes (0) returns (0) {
    callvalue 0x10 gt over jumpi
    0x00 dup1 revert
    over:
        0x00
        0x00
        0x00
        0x00
        callvalue 0x02 mul
        caller
        0xFFFFFFFF
        call
}
```

This check will call the sender with value twice what was passed in.

## Check 2: CHECKSIG
```
#define macro CHECKSIG() = takes (0) returns (1) {
    0x04 calldataload
    0x00 mstore
    0x24 calldataload
    0x20 mstore
    0x44 calldataload
    0x40 mstore
    0x64 calldataload
    0x60 mstore
    0x20
    0x80
    0x80
    0x00
    0x1
    0xFFFFFFFF
    staticcall
    iszero invalidSigner jumpi
    0x80 mload
    0xd8dA6Bf26964AF9D7eed9e03e53415D37AA96044 eq correctSigner jumpi
    end jump

    correctSigner:
        0x00
        end jump
    invalidSigner:
        0x01
        end jump
    end:
}
```

This check attempts to verify that the calldata includes a valid signature from address 0xd8dA6Bf26964AF9D7eed9e03e53415D37AA96044. However, notice that the `invalidSigner` block is never executed in case the signature is valid, but from a different address. As a result, this huff macro will "return" an uninitialized value from the stack.

By having the call from `CHECKVALUE` revert, a 0x01 will be on top the stack since the result is completely unused, so we can pass the `CHECKSIG` by simply providing a valid signature from any addresses and ensuring the `CHECKVALUE` callback reverts.
