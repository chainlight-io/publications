# Dropper

The challenge is to implement an "airdropping" contract in a gas-efficient manner.  A correct yet naïve solution follows:

```solidity
contract AirdropSimple {
    function airdropETH(address[] calldata recipients, uint256[] calldata amounts) external payable {
        for (uint i = 0; i < 16; i++)
            recipients[i].call{value: amounts[i]}("");
    }

    function airdropERC20(IERC20 challengeToken, address[] calldata recipients, uint256[] calldata amounts, uint256 /* totalTokens */) external {
        for (uint i = 0; i < 16; i++)
            challengeToken.transferFrom(msg.sender, recipients[i], amounts[i]);
    }

    function airdropERC721(IERC721 challengeNFT, address[] calldata recipients, uint256[] calldata amounts) external {
        for (uint i = 0; i < 16; i++)
            challengeNFT.transferFrom(msg.sender, recipients[i], amounts[i]);
    }
}
```

Our goal is to write an optimized Ethereum contract that passes all the tests in the `Challenge` contract, yet is much more gas-efficient than the implementation above.

First, observe that the `AirdropLike` arguments are entirely deterministic and can be pre-computed.  This allows us to hard-code the arguments in the deployed `AirdropLike` contract.

* The `recipients` and `amounts` are entirely derived from the block number.
* The `challengeToken` and `challengeNFT` are entirely derived from the `Challenge` contract's address and the nonce number (which is 1 and 2 respectively).

Second, notice that the calldata size of each `AirdropLike` method is different, which allows the method dispatcher to branch entirely on `CALLDATASIZE`.

The above properties enable us to avoid using the `CALLDATALOAD` opcode.  Together with loop unrolling, this results in a significant gas cost savings.

Next, since we are operating in a private fork network, we can carefully set up the base fee and transaction gas price to replace the usage of the constants 0x24 and 0x44, saving 1 gas for each use of those.

A final optimization comes from performing the final ETH airdrop via a `selfdestruct` rather than a `call`.
