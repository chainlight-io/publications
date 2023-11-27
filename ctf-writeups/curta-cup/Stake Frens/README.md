# Stake Frens

## Challenge Background

This challenge is roughly based on an idea to use proofs of log emissions (using
e.g. [Relic Protocol](https://docs.relicprotocol.com)) from the ETH2 deposit contract
to build a simple staking pool contract. The idea has a few flaws, but the
implementation used in this challenge has a major flaw: the address which emitted the
log is not validated to equal the deposit contract. As a result, an attacker can create
a contract which emits a `DepositEvent` without actually requiring an ETH2 deposit.

To simplify the challenge and enable an atomic solution, the goal of the challenge is
simply to convince a wrapper contract that the "deposit contract" reverted due to
an impossible failure (ETH deposited is greater than 2^64 gwei). Instead, the
attacker's fake deposit contract can be writted to revert with this same message.
This highlights that revert messages should almost never be used to infer an actual
failure reason.

## Solve Challenge

The attacker creates a contract which emits a fake `DepositEvent` matching the validation
logic for some `FrenPool`. The `get_deposit_root()` method of this contract should be
written to revert with the required message.

Once the crafted event is included on chain, the [Relic SDK](https://docs.relicprotocol.com/sdk/client-sdk#proving-log-emissions) can be used to fetch a proof of this log emission, which can
be passed to the `FrenPool` to perform the attack.

If the attack is performed correctly, 16 ETH is required to be passed to the contract, but it
will all be returned to the attacker. As a result, a zero-fee flashloan can be used to perform
this attack with minimal ETH requirements.

Check out our [solve script](./Solve.s.sol) for more details. Note that to simplify testing,
our solve script includes some Foundry hacks for mocking out the Relic proofs. When performing
the attack on-chain, these portions must be done in separate transactions using an actual
proof constructed for Relic Protocol.
