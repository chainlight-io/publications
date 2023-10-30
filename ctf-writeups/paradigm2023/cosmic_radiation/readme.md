# Cosmic Radiation

## Steps to grind

1. Use BigQuery
1. Use only 1 bit to flip
1. Replay Coinbase (10) deposit

## Big Query

Pay to list up the contracts by balance.

```sql
with double_entry_book as (
    -- debits
    select to_address as address, value as value
    from `bigquery-public-data.crypto_ethereum.traces`
    where to_address is not null
    and status = 1
    and (call_type not in ('delegatecall', 'callcode', 'staticcall') or call_type is null)
    and block_number <= 18437825
    union all
    -- credits
    select from_address as address, -value as value
    from `bigquery-public-data.crypto_ethereum.traces`
    where from_address is not null
    and status = 1
    and (call_type not in ('delegatecall', 'callcode', 'staticcall') or call_type is null)
    and block_number <= 18437825
    union all
    -- transaction fees debits
    select miner as address, sum(cast(receipt_gas_used as numeric) * cast(gas_price as numeric)) as value
    from `bigquery-public-data.crypto_ethereum.transactions` as transactions
    join `bigquery-public-data.crypto_ethereum.blocks` as blocks on blocks.number = transactions.block_number
    where block_number <= 18437825
    group by blocks.miner
    union all
    -- transaction fees credits
    select from_address as address, -(cast(receipt_gas_used as numeric) * cast(gas_price as numeric)) as value
    from `bigquery-public-data.crypto_ethereum.transactions` where block_number <= 18437825
)
select book.address, sum(book.value) as balance, contracts.bytecode
from double_entry_book as book
join `bigquery-public-data.crypto_ethereum.contracts` as contracts on book.address = contracts.address
where block_number <= 18437825
group by book.address, contracts.bytecode
order by balance desc
limit 10000
```

## Use only 1 bit to flip

We put "origin | selfdestruct" bytecodes at the beginning of the contract. However, it costs a lot because the first of the contract bytecodes starts with 0x6080 in most cases.
We tried to find more efficient way to drain the balance, so we decided to flip the assembly like lt, gt, push32.

Something like these:

```
calldataload
push32 0xfffff....
```
- -> calldataload | 0x7f | ....
- -> 0x7f --> 0xff (selfdestruct)

-------------

```
require(balances[msg.sender] >= amount);

//////

lt
jumpi
```
- -> lt -> gt

## Replay Coinbase (10) deposit

- [example tx](https://etherscan.io/tx/0x1a4b3aca22315af2170c33920114636ee0e210bd25135e04accbe9513886fed3)

```
cast publish --rpc-url $RPC_URL 0x02f8750180843b9aca00850c92a69c00825b0494a9d1e08c7793af67e9d92fe308d5697fb81d3e438a04ac169ba8852d105d9880c080a00f7187409d65e8241084a6f3e250835b199dd18818b7ff065a34acc81720c9d4a034c67d83b61f12c81f308baa956ec2c0c81c2a18e9bc505713d057ebfde37f6b
cast publish --rpc-url $RPC_URL 0x02f8750180843b9aca008507aef40a00825b0494a9d1e08c7793af67e9d92fe308d5697fb81d3e438a04bf27a632c77f2a13f880c080a09d5dff5a5de6d1f3283808b5c54ce5e6d2bab6c7f197237f20384750b4e4a991a049675cf539f2f0fd94be608670871fa1ecdcb1a64ce55da4428c337e2d8bd5b6
cast publish --rpc-url $RPC_URL 0x02f8750180843b9aca0085046c7cfe00825b0494a9d1e08c7793af67e9d92fe308d5697fb81d3e438a04a9fcac6485f589782f80c001a0539ae39249ac418d226cbb1a3d11f30d241aa3a1c13d6c4beacd4627df973aaca03729dd87271d555b843db02b014c0e39df65ad26176a7e9022b68dd90ee0b806
```

