# Skill based game

This challenge is to win a blackjack game and take all the ETH. 

`deal()` generates a random number with `block.number` and `block.timestamp`, which are on-chain data. It is well-known that random number generated only with on-chain data is vulnerable, since it is deterministic.

So we know when a blackjack is made (the sum of cards is equal to 21), and generate a winning sequence to drain all the Ethereum from the contract.

We get the flag: PCTF{0n_chA1N_rAnd0Mn355_15_hArD}