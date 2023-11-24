# LatentRisk

## Challenge Background
Numerous projects have suffered exploits due to the round-down vulnerability from the very early stages of Web3. This challenge was inspired by an incident that happened in the CompoundV2 fork. The challenge is crafted to inform potential threats that exist in the prominent, solid protocol called CompoundV2. (Please note that CompoundV2 has known about this for a long time, has never encountered any problems due to this.) I hope every builder acknowledges this latent risk and does not reproduce the same crisis anymore.

## Solve Challenge
CompoundV2 utilizes ibTokens named `cToken` to manage lender and borrower positions. The comptroller, the controller in CompoundV2, can manage these `cToken`s.
However, if you accept `cToken` as collateral before any issuance of `cToken`, you can exploit a round-down vulnerability to drain all other underlying assets of `cToken`s.

The root cause is that the exchange rate of `cToken` can be manipulated at the attacker's will when no liquidity exists, and a round-down occurs in the `redeemUnderlying()`.
As a result, an attacker can borrow other underlying assets of `cToken`s without collateral.

If you are interested in learning more, check out our blog post.
- [ChainLight Blog Post](https://medium.com/chainlight/patch-thursday-security-risks-due-to-exchange-rate-manipulation-of-ibtoken-ebf8e8cb165a)

