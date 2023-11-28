# PairAssetManager

## Challenge Background
This challenge questions your understanding of UniswapV2. By solving this challenge, you will learn about the operational logic of UniswapV2 factory and CPMM.

## Solve Challenge
The challenge's goal is to drain both the `curtaUSD` and `curtaStUSD` from `keeper`, which is responsible for pricing the pair.

The existing vulnerabilities in the challenge are
1. In `onlyUniswapV2Pair()`, verification with `codeHash` can be bypassed by deploying `UniswapV2Pair` directly.
2. In `uniswapV2Call()`, if `amountIn` is greater than `maxAmountIn`, it should be reverted.
3. In `uniswapV2Call()`, the token address passed as `data` may not be the same as the token of the called pair.
4. If you deposit a token different from the initial token specified by `_createUser()` in `deposit()`, the share of the initial tokens pair will be increased. (optional)

In addition to the minimum requirement, vulnerability #4 can steal additional `curtaUSD` and `curtaStUSD` from `owner`, with the amount of `1 ether - MINIMUM_LIQUIDITY`.

The attack scenario is as follows:

1. The attacker creates a fake token and directly deploys `UniswapV2Pair`.
2. The attacker `mint()` and `sync()` the fake tokens with the fake pair, scaling them so that the `PairAssetManager._getAmountIn()` of one token results in a large value.
3. Call `initialize()` to change the tokens to `curtaUSD` and `curtaStUSD`. In the usual case that the pair is deployed through the factory, this function is called only once to create the pair, but the attacker can call this multiple times as it is self-deployed.
4. Call `swap()` on the `UniswapV2Pair` you deployed, specifying `to` as `PairAssetManager` and `data` as the token addresses to steal + the number of tokens the `keeper` has. The attacker can drain the token from the keeper with a large `_getAmountIn()`.
5. `burn()` all the fake tokens held by the fake pair and call `sync()` to set the `reserve` to zero.
6. Call `initialize()` to replace the token with the fake token again, and `mint()` and `sync()` the other token so that its `PairAssetManager._getAmountIn()` enlarges.
7. Again, 4 and 5, and bring all tokens via `skim()`.
