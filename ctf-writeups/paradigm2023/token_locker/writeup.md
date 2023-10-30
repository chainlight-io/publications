# Token locker

This challenge is to remove all the NFTs (liquidity) from the `target` contract. If we look at the `lock()` of the `TARGET` contract, we can see that `_convertPositionToFullRange()` will `approve` the token. We were suspicious of this part. 

The challenge is based on UNCX, a multi-chain DeFi protocol. Compared to the original contracts of UNCX, `TARGET` contract trusts the return value of `_nftPositionManager.collect()`. 

Also, the `TARGET.lock()` does not validate the address `nftPositionManager`. We could solve the challenge if we put the NFT address in the `token` and make the return value of `collect()` into the nft id (which the `TARGET` contract owns). 

As NFT's ID is used as the third argument of `approve()` in `_convertPositionToFullRange()`, we can now withdraw the NFT. 

We get the flag: PCTF{0nE_T00_m4ny_945_0PT1m124T10n2}