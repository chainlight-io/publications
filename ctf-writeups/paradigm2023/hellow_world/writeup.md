# Hellow world

The challenge is to increase the balance of `TARGET` by at least 13.37 ETH. The `cast send --rpc-url $RPC_URL --private-key $PRIVATE_KEY $TARGET_ADDR --value 100ether` didn't work, probably because `fallback()` doesn't exist. We sent the ETH to `selfdestruct()` and solved the challenge. 

We get the flag: PCTF{w3lC0m3_T0_th3_94m3}