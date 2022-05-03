#!/bin/bash

# so that database related folders are not spawning in the scripts folder
pushd /

/rust_container_runner/docker_assets/geth --identity "GravityTestnet" --nodiscover \
    --networkid 15 \
    --mine \
    --http \
    --http.addr="0.0.0.0" \
    --http.vhosts="*" \
    --http.corsdomain="*" \
    --miner.threads=1 \
    --nousb \
    --verbosity=5 \
    --miner.etherbase=0xBf660843528035a5A4921534E156a27e64B231fE &> /rust_container_runner/docker_assets/geth.log &

# the setup for local testing
# see avalanchego/genesis/genesis_local.go to see default genesis
#/avalanchego/build/avalanchego \
#    --network-id=local \
#    --public-ip=127.0.0.1 \
#    --http-port=9650 \
#    --db-dir=memdb \
#    --staking-enabled=false &> /rust_container_runner/docker_assets/avalanchego.log &

#/rust_container_runner/docker_assets/opera --fakenet 1/1 \
#    --nodiscover \
#    --http \
#    --http.addr="localhost" \
#    --http.port="18545" \
#    --http.api="eth,debug,net,admin,web3,personal,txpool,ftm,dag" \
#    --datadir="/opera_datadir" &> //rust_container_runner/docker_assets/opera.log &

RUST_LOG="TRACE" RUST_BACKTRACE=full /rust_container_runner/docker_assets/internal_runner
