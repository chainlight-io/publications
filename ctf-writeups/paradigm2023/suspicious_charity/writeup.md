# Suspicious charity

The abi decoder `ethabi` used by `cast`, `chisel` decodes `string` as UTF-8 string.
To prevent panic during the decoding, it [intentionally uses UTF-8 lossy decoder](https://github.com/rust-ethereum/ethabi/blob/b1710adc18f5b771d2d2519c87248b1ba9430778/ethabi/src/decoder.rs#L166-L170), that decodes
invalid UTF-8 chracters into a fixed code point: 0xfeff.

Therefore, the pair name `0x80` and `0x81` returned by `PairName` contract is decoded as the same string.
To get the original value, one should interpret the `string` type returned by the contract as raw bytes instead.

`cast call` also uses the same decoder, so letting `cast` to decode the strings should be used carefully.
In this challenge, the watcher script uses `PairName` to cache each token's price assigned in each LP token contract.
Due to the incorrect decoding, the token prices of one of LP `0x80` and `0x81` is overwritten to another.

Attackers can create many pools to trigger this condition with cheap tokens and then expensive tokens
to make the calculated price of lp tokens inflated to get the flag.