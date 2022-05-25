#!/bin/bash

# so that database related folders are not spawning in the scripts folder
pushd /

#geth --identity "GravityTestnet" --nodiscover \
#    --networkid 15 \
#    --mine \
#    --http \
#    --http.addr="0.0.0.0" \
#    --http.vhosts="*" \
#    --http.corsdomain="*" \
#    --miner.threads=1 \
#    --nousb \
#    --verbosity=5 \
#    --miner.etherbase=0xBf660843528035a5A4921534E156a27e64B231fE &> /rust_container_runner/docker_assets/geth.log &

# Init the genesis block. The genesis block was made by copying `tests/bor/testdata/genesis.json`
# from the `bor` repo, editing "chainId" to 15, editing "londonBlock" and "jaipurBlock" to 0,
# adding an allocation
# `"0xBf660843528035a5A4921534E156a27e64B231fE": {
#     "balance": "0x1337000000000000000000"
# }`
# To the end of the "alloc" block, and search+replace `71562b71999873DB5b286dF957af199Ec94617F7`
# with `Bf660843528035a5A4921534E156a27e64B231fE` in a large block of hex so that our account
# can be a block producer
#bor --identity "GravityTestnet" \
#    --nodiscover --networkid 15 init /rust_container_runner/docker_assets/bor_genesis.json

# `--dev` uses its own genesis, `bor` otherwise requires a keystore with the private key for
# 0xb1bab011e03a9862664706fc3bbaa1b16651528e5f0e7fbfcbfdd8be302a13e7
# It was generated by
# `from web3 import Account`
# `import json`
# `json.dumps(Account.encrypt('0xb1bab011e03a9862664706fc3bbaa1b16651528e5f0e7fbfcbfdd8be302a13e7', 'dev'))`
# and pasting the json into dev_keystore/dev_key.json
#bor --identity "GravityTestnet" \
#    --nodiscover \
#    --networkid 15 \
#    --bor.withoutheimdall \
#    --http \
#    --http.addr="0.0.0.0" \
#    --http.vhosts="*" \
#    --http.corsdomain="*" \
#    --nousb \
#    --verbosity=5 \
#    --mine \
#    --miner.etherbase=0xBf660843528035a5A4921534E156a27e64B231fE \
#    --unlock=0xBf660843528035a5A4921534E156a27e64B231fE \
#    --allow-insecure-unlock \
#    --keystore="/rust_container_runner/docker_assets/dev_keystore" \
#    --password="/rust_container_runner/docker_assets/dev_password.txt" \
#    &> /rust_container_runner/docker_assets/bor.log &

# the setup for local testing
#avalanchego \
#    --genesis="/rust_container_runner/docker_assets/avalanchego_genesis.json" \
#    --build-dir="/avalanchego/build/" \
#    --network-id=15 \
#    --public-ip=127.0.0.1 \
#    --http-port=8545 \
#    --db-type=memdb \
#    --staking-enabled=false &> /rust_container_runner/docker_assets/avalanchego.log &

# To make a custom genesis file for `go-opera`, comment out the normal `opera`
# command below and change `MINER_PRIVATE_KEY`
# to use 0x163F5F0F9A621D72FEDD85FFCA3D08D131AB4E812181E0D30FFD1C885D20AAC7
# and uncommenting the special `send_eth_bulk` that sends tokens to the address we
# want to use. Uncomment the other `opera` command below which will use Fantom's
# default genesis. Then, run `bash run.sh NO_SCRIPTS`
# and get a command prompt to the running container. In the container run
# `bash /rust_container_runner/docker_assets/run_internal.sh` and wait for it to finish
# Then in the container `pkill opera` and run
# `opera --datadir /opera_datadir/ export genesis /rust_container_runner/docker_assets/test_genesis.g --export.evm.mode=ext-mpt`
# which will convert the state of the testchain up to that point into a new genesis that we
# use for normal runs. Commit the `test_genesis.g` and undo the other changes.
#opera --fakenet 1/1 \
#    --nodiscover \
#    --http \
#    --http.addr="localhost" \
#    --http.port="8545" \
#    --http.api="eth,debug,net,admin,web3,personal,txpool,ftm,dag" \
#    --datadir="/opera_datadir" &> /rust_container_runner/docker_assets/opera.log &

#opera --fakenet 1/1 \
#    --genesis.allowExperimental \
#    --genesis="/rust_container_runner/docker_assets/test_genesis.g" \
#    --nodiscover \
#    --http \
#    --http.addr="localhost" \
#    --http.port="8545" \
#    --http.api="eth,debug,net,admin,web3,personal,txpool,ftm,dag" \
#    --datadir="/opera_datadir" &> /rust_container_runner/docker_assets/opera.log &

RUST_LOG="TRACE" RUST_BACKTRACE=full /rust_container_runner/docker_assets/eth_rpc