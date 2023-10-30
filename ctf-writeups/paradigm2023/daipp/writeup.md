# DAI++

The challenge's goal is minting `1_000_000_000_000 * 1e18` "USDS" stablecoin (the token contract is also given by the authors).

In this challenge, `Account` contract can be opened by `AccountManager` contract, which uses
`CloneWithImmutableArgs` with user-controlled arguments. `AccountManager` can mint tokens from
the given stablecoin contract, while increasing debts for each account by calling `increaseDebt`
before the mint. When the minting amount is 1.5x larger than its collateral (1000 eth is given),
it reverts. `Account` reads the constant 1.5 from the configuration contract passed via `CloneWithImmutableArgs`.

```js
    function isHealthy(uint256 collateralDecrease, uint256 debtIncrease) public view returns (bool) {
        SystemConfiguration configuration = SystemConfiguration(_getArgAddress(0));
...
        return totalBalance * ethPrice / 1e8 >= totalDebt * configuration.getCollateralRatio() / 10000;
    }
```

The problem is that `CloneWithImmutableArgs` deploys proxy that passes contract-specific
immutable arguments as its calldata to the implementation, and the size of immutable data is
specified in 16bits at the end of the calldata.

```
------------------------------------------
| msg.data ... | ... extra data ... | sz |
------------------------------------------

sz: len(extra data) in 16bits
```

If the immutable data is larger than 0x10000, the size above is truncated.
Also, the size specified in the proxy is also truncated since `CloneWithImmutableArgs` replaces
the `...` part of the following instruction with `sz`:

```
PUSH2 0x.... // added to len(msg.data) later
...

CALL
```

As a result, only `sz mod 0x10000` bytes of the calldata is sent to the implementation.
It means that the implementation can wrongly fetch `sz` from the middle of `msg.data` or `extra data`.

However, there are a lot of `0x00`s in `msg.data` and `extra data` because it passes
an array of `address` which is 160 bits. The only way to make `sz` other than `0` was
making the proxy truncate the middle of first 2 addresses in the `extra data`, that is
the owner of the account. `sz` becomes `address(owner) >> 0x80` truncated to an 16bit integer.

AccountManager:

```solidity
    function _openAccount(address owner, address[] calldata recoveryAddresses) private returns (Account) {
        Account account = Account(
            SYSTEM_CONFIGURATION.getAccountImplementation().clone(
            	// `sz` will point the middle of `owner` address when passing 2046 addresses
                abi.encodePacked(SYSTEM_CONFIGURATION, owner, recoveryAddresses.length, recoveryAddresses)
            )
        );
```

Also `AccountManager.mintStablecoin` forwards user-controlled, arbitrary data `memo` to `increaseDebt`.
Therefore, if we specify the new `sz` bytes as `memo`, we can also control the `configuration` contract used in `isHealthy`;
we set the collateral ratio to 0 which allows infinite minting of the stablecoin.

Flag: `PCTF{0V3RFl0W5_WH3r3_Y0u_L3a57_3xp3C7_17}`