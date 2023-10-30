# Oven

The challenge presents a [Fiat-Shamir heuristic][fiat-shamir] implementation in Python.

We can make queries to the server as many times we want to the server. For each query, the server returns `t`, `r`, `p`, `g`, and `y` where each value is calculated as follows:

```python
def fiat_shamir():
    p = getPrime(BITS)
    g = 2
    y = pow(g, FLAG, p)

    v = random.randint(2, 2**512)

    t = pow(g, v, p)
    c = custom_hash(long_to_bytes(g) + long_to_bytes(y) + long_to_bytes(t))
    r = (v - c * FLAG) % (p - 1)

    assert t == (pow(g, r, p) * pow(y, c, p)) % p

    return (t, r), (p, g, y)
```

Observe that the bit length of `v` (512) is only the half of the prime bits (1024). Using this fact, we can construct a lattice to recover the flag value using the relation `r_i = (v_i - c_i * FLAG) % (p_i - 1)` only with `c_i`, `r_i`, and `p_i`.

```python
from pwn import *
from Crypto.Util.number import *
from tqdm import trange
​
conn = remote("oven.challenges.paradigm.xyz", 1337)
​
def get_arg(v):
    conn.recvuntil(f'{v} = '.encode())
    return int(conn.recvline().strip().decode())
​
def parse():
    t = get_arg('t')
    r = get_arg('r')
    p = get_arg('p')
    g = get_arg('g')
    y = get_arg('y')

    return t, r, p, g, y
​
def custom_hash(n):
    state = b"\x00" * 16
    for i in range(len(n) // 16):
        state = xor(state, n[i : i + 16])
​
    for _ in range(5):
        state = hashlib.md5(state).digest()
        state = hashlib.sha1(state).digest()
        state = hashlib.sha256(state).digest()
        state = hashlib.sha512(state).digest() + hashlib.sha256(state).digest()
​
    value = bytes_to_long(state)
​
    return value
​
arr = []
​
for _ in trange(20):
    conn.sendlineafter(b'Choice: ', b'1')
    t, r, p, g, y = parse()
​
    c = custom_hash(long_to_bytes(g) + long_to_bytes(y) + long_to_bytes(t))
​
    arr.append((c, r, p))
​
​
mat = []
​
mat.append([ -it[0] for it in arr ] + [1, 0])
​
for i in range(20):
    row = [0] * i + [ arr[i][2] - 1 ] + [0] * (20 - i) + [0]
    mat.append(row)
​
mat.append([ -it[1] for it in arr ] + [0, 2^512])
​
mat = Matrix(mat)
​
res = mat.LLL()
​
for row in res:
    t = int(row[-2])
    if t < 0:
        t = -t
    print(long_to_bytes(t))
```

Flag: `pctf{F1at_shAm1R_HNP_g0_Cr4ZyyYy_m0rE_1iK3_f4T_Sh4mIr}`

[fiat-shamir]: https://en.wikipedia.org/wiki/Fiat%E2%80%93Shamir_heuristic
