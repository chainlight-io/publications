# 100%

This challenge is to drain all the ETH that goes into the split wallet. 

In `Deploy.s.sol`, we observed that the value of `addrs[1]` is address(0), and `Split.distribute()` withdraws ETH to `SplitWallet` as a `Split` contract. As `_hashSplit()` uses `abi.encodePacked()`, and we thought the function could be used to manipulate `percents`, which is the percentage of asset distributed into the split wallet. Also, we found out that no other input validation existed on the hash.

Attack Scenarios:
1. The attacker calls `distribute()` to withdraw ETH from the victim's split wallet to the `Split` contract.
2. The attacker creates a split wallet, where `addrs[1]` contains the value of `percents[0]` to be manipulated in the future.
3. The attacker deposits 100 ether into the created split wallet.
4. The attacker calls `distribute()`, manipulating the arguments to put the value of `addrs[1]` into `percents[0]`. The hash is the same, so `percents[0]` has been manipulated.
5. The attacker's `balance` becomes incredibly large by the manipulated `percents`, and the attacker drains all the money with `withdraw()`.

Finally we get the flag: PCTF{gU355_7H3r3_w45n7_3nOUgH_1NpU7_V4L1D471ON}