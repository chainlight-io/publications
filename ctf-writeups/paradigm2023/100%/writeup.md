# 100%

This challenge is to steal all ETH that went into the split wallet. In `Deploy.s.sol`, we see that the value of `addrs[1]` is `address(0)`. `Split.distribute()` withdraws ETH to `SplitWallet` as a `Split` contract. We see that `_hashSplit()` uses `abi.encodePacked()`, and we thought we could use that to manipulate the `percents`. When we checked it out, We realized there was no other input validation besides the hash, so We went from thinking to being convinced.

Attack Scenarios:
1. The attacker calls `distribute()` to withdraw ETH from the victim's split wallet to the `Split` contract.
2. The attacker creates a split wallet, where `addrs[1]` contains the value of `percents[0]` to be manipulated in the future.
3. The attacker deposits 100 ether into the created split wallet.
4. The attacker called by manipulating the arguments to `distribute()` to put the value of `addrs[1]` into `percents[0]`. The hash is the same, so `percents[0]` has been manipulated.
5. The attacker's `balance` was made incredibly large by the manipulated `percents`. Drain all the money with `withdraw()`.

Finally we get the flag: PCTF{gU355_7H3r3_w45n7_3nOUgH_1NpU7_V4L1D471ON}