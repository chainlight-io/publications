# AddressGame

This challenge is inspired by [The Password Game](https://neal.fun/password-game/); you need to generate a vanity contract address that satisfies:

- the address has `box(seed, 0) % 2` vowels (0xA, 0xE),
- the address has `box(seed, 1) % 3` consonant (0xB, 0xC, 0xD, 0xF),
- all digits in the address (0x0 ~ 0x9) sums up to `25 + seed % 50`.

To generate, you can write your own miner that satisfies the conditions above.
Also, while the `box()` returns `uint256`, you can use `uint64` instead since the modulo fits in 64-bits.

See [the patch](./profanity2.patch) for the vanity address generator ([profanity2](https://github.com/1inch/profanity2)) and [the solve script](./Solve.t.sol) for `0xB49bf876BE26435b6fae1Ef42C3c82c5867Fa149`.
