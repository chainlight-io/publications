# Jumbled Otter Problem

Our goal is to pwn a Solana program to create an account at a [program-derived address (PDA)](https://solanacookbook.com/core-concepts/pdas.html#facts) that has an account data length of 0x1337 and 0x4337 written to offset 0.

```rust
//
// challenge framework
//
let flag = Pubkey::create_program_address(&["FLAG".as_ref()], &chall::ID)?;

if let Some(acct) = chall.ctx.banks_client.get_account(flag).await? {
    if acct.data.len() == 0x1337
        && u64::from_le_bytes(acct.data[..8].try_into().unwrap()) == 0x4337
    {
        writeln!(socket, "congrats!")?;
        if let Ok(flag) = env::var("FLAG") {
            writeln!(socket, "flag: {:?}", flag)?;
        } else {
            writeln!(socket, "flag not found, please contact admin")?;
        }
    }
}
```

The challenge binary fearlessly uses unsafe Rust, which allows the caller to call arbitrary pointers with controlled arguments and overwrite any memory with controlled values.

```rust
//
// challenge contract code
//
use solana_program::{instruction::Instruction, program::invoke_signed_unchecked, pubkey, account_info::AccountInfo, entrypoint, entrypoint::ProgramResult, pubkey::Pubkey};

pub const ID: Pubkey = pubkey!("osecio1111111111111111111111111111111111111");

// declare and export the program's entrypoint
entrypoint!(process_instruction);


#[inline(never)]
pub fn process(mut data: &[u8]) {
    unsafe {
        let ptr = std::mem::transmute::<[u8; 8], fn(u64)>(data[..8].try_into().unwrap());
        let val = std::mem::transmute::<[u8; 8], u64>(data[8..16].try_into().unwrap());
        ptr(val);

        data = &data[16..];

        let ptr = std::mem::transmute::<[u8; 8], fn(u64)>(data[..8].try_into().unwrap());
        let val = std::mem::transmute::<[u8; 8], u64>(data[8..16].try_into().unwrap());
        ptr(val);
    }
}

#[inline(never)]
pub fn write(data: &[u8]) {
    unsafe {
        let ptr = std::mem::transmute::<[u8; 8], *mut u64>(data[..8].try_into().unwrap());
        let val = std::mem::transmute::<[u8; 8], u64>(data[8..16].try_into().unwrap());
        ptr.write_volatile(val);
    }

}
#[inline(never)]
pub fn process_instruction(
    _: &Pubkey,
    _: &[AccountInfo],
    data: &[u8]
) -> ProgramResult {
    if data[0] == 0 {
        write(data);
    } else if data[0] == 1 {
        call(data);
    } else {
        process(data);
    }

    Ok(())
}


#[inline(never)]
pub fn call(data: &[u8]) {
    let ix = Instruction {
        program_id: pubkey!("osecio5555555555555551111111111111111111111"),
        data: data.try_into().unwrap(),
        accounts: vec![]
    };

    invoke_signed_unchecked(
        &ix,
        &[],
        &[],
    ).unwrap();
}
```

Note that `process()` function has two arbitrary calls. We used the first call to perform an arbitrary action and the second call to call `process()` again with `data[16..]`. This allows us to chain arbitrary calls as many times as we want (this behavior and the challenge name's acronym, JOP, are probably indicators to jump-oriented programming technique).

In addition, at 885 (see [chall-dump.txt](./chall-dump.txt)), there's a powerful primitive that pops addresses from stack memory and call `sol_invoke_signed_rust`. Since `process()` lets us control `r1` with the function parameter, it give us full control of the syscall parameters.

```
     885	79 a2 78 ff 00 00 00 00	r2 = *(u64 *)(r10 - 0x88)
     886	79 a3 80 ff 00 00 00 00	r3 = *(u64 *)(r10 - 0x80)
     887	79 a4 68 ff 00 00 00 00	r4 = *(u64 *)(r10 - 0x98)
     888	79 a5 70 ff 00 00 00 00	r5 = *(u64 *)(r10 - 0x90)
     889	85 10 00 00 ff ff ff ff	call -0x1 ; sol_invoke_signed_rust
```

Combining these two primitives conceptually leads to the solution. However, the difficult part of this problem is preparing the correct register values and the memory layouts so that it matches [Solana's syscall layout](https://github.com/solana-labs/solana/blob/cdc284189a042b7a4e2c44b99c2bc36da7566524/programs/bpf_loader/src/syscalls/cpi.rs#L1188-L1197).

```rust
/// Call process instruction, common to both Rust and C
fn cpi_common<S: SyscallInvokeSigned>(
    invoke_context: &mut InvokeContext,
    instruction_addr: u64,
    account_infos_addr: u64,
    account_infos_len: u64,
    signers_seeds_addr: u64,
    signers_seeds_len: u64,
    memory_mapping: &MemoryMapping,
) -> Result<u64, Error>
```

We built [a local testing environment](./solver-local.rs), overrode Solana's BPF executor using [Cargo's dependency overriding feature](./Cargo.toml), and debugged our exploit by [adding lots of print statements in the BPF executor code](./rbpf.diff). After a prolonged and painful debugging session, we finally solved the problem, got the first-blood, and became happy.

Flag: `PCTF{jump1ng_b4ck_4nd_40rt5_83y1927}`
