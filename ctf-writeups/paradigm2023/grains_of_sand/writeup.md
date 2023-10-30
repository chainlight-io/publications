# Grains of Sand

In this challenge we need to drain some ['GoldReserve' tokens]( https://etherscan.io/address/0xC937f5027D47250Fa2Df8CbF21F6F88E98817845 )
from an existing contract known as [TokenStore]( 0x1cE7AE555139c5EF5A57CC8d814a867ee6Ee33D8 ).

First, we must identify an existing order for GoldReserve tokens that we can view, that is
not expired or fully filled. We chose to use the order revealed in [this tx](https://etherscan.io/tx/0x1483f5c6158dfb9a899b137ccfa988fb2b1f6927854dcd83e0a29caadd0e38ba).
This gives us 1900 GoldReserve tokens.

Next, we note that GoldReserve tokens charge a 0.02% fee on transfer, deducted from the sender's account.
If the sender cannot pay the fee, it is deducted from the amount they transfer.

The TokenStore contract does not properly handle either of these cases: when we request to redeem
some tokens, a little bit extra is lost for the fee, but our account receives the full amount
requeusted. If we then deposit all of our GoldReserve tokens back to the TokenStore, we actually
end up depositing less than the full 1900 tokens, but we are credited in TokenStore as if we have.
Repeating this withdrawl and deposit process as much as possible eventually drains the account. 

Finally we get the flag: PCTF{f33_70K3nS_cauS1n9_pR08L3Ms_a9a1N}
