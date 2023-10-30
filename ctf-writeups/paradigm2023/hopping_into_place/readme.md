# Hopping into Place

In this challenge, we need to drain the entire balance of the Hop Bridge contract.
The author gave us the governance permission of the birdge. So the goal is to figure out the way to drain the bridge asset when you get the governance power.

First, we listed up the functions that governance can do:

- addBonder | removeBonder
- rescueTransferRoot
- setCrossDomainMessengerWrapper
- setChainIdDepositsPaused
- setChallengePeriod
- setChallengeResolutionPeriod
- setMinTransferRootBondDelay

`rescueTransferRoot` allows the governance to rescue the transfer root if it has not been processed for 8 weeks.
However the 8 weeks of minimum resuce delay is not feasible, so we turned around to find out another methods.

The governance can add a bonder to the contract. You can get more information about Hop bridge's bonder at here:
[What does the bonder do?](https://help.hop.exchange/hc/en-us/articles/4406109294221-What-does-The-Bonder-do-)

At a first glance, it is impossible to drain the bridge's balance even if you are a bonder because the bonder must stake collateral to be used as credit. Therefore, the maximum amount of the bonder can withdraw cannot be greater than than the amount of collateral that they have staked. This is done by checking a simple equation; collateral >= debt.

However, if we set the challenge period to the zero, the we can always make a debt to always zero. If we can transfer any bond, it also means  that we (another bonder) can always win the challenge. The challenge requires 10% of the bond amount, and gives back 175% of the amount that I used in the challenge as a reward if we win.

Repeating this, the bond transfer and challenge process as much as possible eventually drains the bridge.

The lesson we take from this challenge is that two malicious bonders can drain the assets of the Hop Bridge if the `challengePeriod` is set to the zero.

Flag: PCTF{90v3rNANc3_Unm1n1m12At10n}
