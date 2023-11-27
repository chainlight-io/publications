# Usurper's Throne

## Challenge Background

This challenge is meant to test a competitors understanding of
[SSTORE2Map](https://github.com/0xsequence/sstore2/blob/0a28fe61b6e81de9a05b462a24b9f4ba8c70d5b7/contracts/SSTORE2Map.sol). Specifically, why is the stored data [prefixed with a `00` byte](https://github.com/0xsequence/sstore2/blob/0a28fe61b6e81de9a05b462a24b9f4ba8c70d5b7/contracts/SSTORE2Map.sol#L46)? Why is it critical that the stored data cannot be executed?

To make the challenge more interesting, the logic of the [CREATE3](https://github.com/0xsequence/create3) library was also modified to `selfdestruct` the proxy contract,
allowing both the proxy contract and (potentially) the data contract to be redeployed.

In this challenge, the map was used to store DAO proposal `calldata` payloads, and
were filtered before storing. The DAO also stored proposal descriptions (string data) in this manner, but in a way that enabled collisions on the map key. As the descriptions were unfiltered, a collision between one proposals's description and another's `calldata` could cause the `calldata` to be modified after verification, allowing filtered methods to be called by the DAO.

## Solve Challenge

The challenger needs to get the DAO to call two methods: `forgeThrone` and `addUsurper`. The `forgeThrone` call is easy to execute by simply using the DAO as intended. To craft a call to `addUsurper`, you must perform the following steps:
1. Pick a arbitrary, unused proposal ID, say `x`.
2. Construct a proposal with `id = keccak256(x, x)` with payload data beginning with the `forgeThrone` selector (`0x6d2cd781`) that can be self-destructed. To do this, notice that the first byte (`6d`) is a `PUSH14` opcode, meaning that when executed, the first 15 bytes of the proposal will execute as a valid instruction. Simply placing a `selfdestruct` (`0xff`) after this instruction will suffice.
3. Execute the payload contract created above, self-destructing it.
4. Create a new proposal with `id = x` with any payload data, but with description equal to the new payload data: `abi.encodeWithSelector(Throne.addUsurper.selector, solver)`. This will recreate the payload contract for proposal `keccak(x, x)`, but with no validation checks.
5. Vote for and execute proposal id `keccak256(x, x)`.

Check out our [solve script](./Solve.s.sol) for more details.
