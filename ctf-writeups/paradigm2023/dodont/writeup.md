# dodont

This challenge is to steal all the WETH that goes into the DVM contract. 

The vulnerability existed in `init` function, which had no access control, and could be called multiple times. 

Therefore, we can call `init()` to change the base and quote token, then call `sync()` to update the reserve balance (`=0`). When we called `init()` again to replace the base token with WETH, we could withdraw all the WETH with `flashloan()`.

We get the flag: PCTF{UNpr0t3cT3D_INITI4Liz3Rs_4r3_s0_L4ST_Y34R}