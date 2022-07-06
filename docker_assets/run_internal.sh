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

# the setup for local testing
avalanchego \
    --genesis="/rust_container_runner/docker_assets/ETHGenesis.json" \
    --network-id=15 \
    --build-dir="/avalanchego/build/" \
    --public-ip=127.0.0.1 \
    --http-port=8545 \
    --db-type=memdb \
    --staking-enabled=false &> /rust_container_runner/docker_assets/avalanchego.log &

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
#    --http.port="18545" \
#    --http.api="eth,debug,net,admin,web3,personal,txpool,ftm,dag" \
#    --datadir="/opera_datadir" &> /rust_container_runner/docker_assets/opera.log &

#opera --fakenet 1/1 \
#    --genesis.allowExperimental \
#    --genesis="/rust_container_runner/docker_assets/test_genesis.g" \
#    --nodiscover \
#    --http \
#    --http.addr="localhost" \
#    --http.port="18545" \
#    --http.api="eth,debug,net,admin,web3,personal,txpool,ftm,dag" \
#    --datadir="/opera_datadir" &> /rust_container_runner/docker_assets/opera.log &

RUST_LOG="TRACE" RUST_BACKTRACE=full /rust_container_runner/docker_assets/internal_runner
