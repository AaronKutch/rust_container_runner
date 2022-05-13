#!/bin/bash

# so that database related folders are not spawning in the scripts folder
pushd /

#/rust_container_runner/docker_assets/geth --identity "GravityTestnet" --nodiscover \
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
# see avalanchego/genesis/genesis_local.go to see default genesis
#/avalanchego/build/avalanchego \
#    --network-id=local \
#    --public-ip=127.0.0.1 \
#    --http-port=9650 \
#    --db-dir=memdb \
#    --staking-enabled=false &> /rust_container_runner/docker_assets/avalanchego.log &

# Run
# `MINER_PRIVATE_KEY=0x163F5F0F9A621D72FEDD85FFCA3D08D131AB4E812181E0D30FFD1C885D20AAC7 bash run.sh NO_SCRIPTS`
# and get a command prompt to the running container. In the container run
# `bash /rust_container_runner/docker_assets/run_internal.sh` and wait for a transaction
# Then in the container `pkill opera` and run
# `opera --datadir /opera_datadir/ export genesis /rust_container_runner/docker_assets/test_genesis.g --export.evm.mode=ext-mpt`
# which will convert the state of the testchain up to that point into a new genesis that we
# use for normal runs. Commit the `test_genesis.g` and undo the other changes.

# for generating genesis file
opera --fakenet 1/1 \
    --nodiscover \
    --http \
    --http.addr="localhost" \
    --http.port="18545" \
    --http.api="eth,debug,net,admin,web3,personal,txpool,ftm,dag" \
    --datadir="/opera_datadir" &> /rust_container_runner/docker_assets/opera.log &

# for normal test operation
#opera --genesis="/rust_container_runner/docker_assets/test_genesis.g" \
#    --genesis.allowExperimental=true \
#    --nodiscover \
#    --http \
#    --http.addr="localhost" \
#    --http.port="18545" \
#    --http.api="eth,debug,net,admin,web3,personal,txpool,ftm,dag" \
#    --datadir="/opera_datadir" &> /rust_container_runner/docker_assets/opera.log &

RUST_LOG="TRACE" RUST_BACKTRACE=full /rust_container_runner/docker_assets/internal_runner
