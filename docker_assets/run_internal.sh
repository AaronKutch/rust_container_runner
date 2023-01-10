#!/bin/bash

# so that database related folders are not spawning in the scripts folder
pushd /

echo "waiting for neon to come online"
until $(curl --output /dev/null --fail --silent --header "content-type: application/json" --data '{"method":"eth_blockNumber","params":[],"id":1,"jsonrpc":"2.0"}' http://proxy:9090/solana); do
    sleep 1
done
echo "waiting for neon to sync"
until [ "$(curl -s --header "content-type: application/json" --data '{"id":1,"jsonrpc":"2.0","method":"eth_syncing","params":[]}' http://proxy:9090/solana)" == '{"jsonrpc": "2.0", "id": 1, "result": false}' ]; do
    sleep 1
done
# request funds for the test account
echo "waiting for faucet"
until $(curl --output /dev/null --fail --silent -X POST -d '{"wallet": "0xBf660843528035a5A4921534E156a27e64B231fE", "amount": 100000000}' 'http://faucet:3333/request_neon'); do
    sleep 1
done

# geth --identity "GravityTestnet" \
#     --nodiscover \
#     --networkid 15 \
#     init /rust_container_runner/docker_assets/ETHGenesis.json

# geth --identity "GravityTestnet" --nodiscover \
#     --networkid 15 \
#     --mine \
#     --http \
#     --http.addr="0.0.0.0" \
#     --http.vhosts="*" \
#     --http.corsdomain="*" \
#     --miner.threads=1 \
#     --nousb \
#     --verbosity=5 \
#     --miner.etherbase=0xBf660843528035a5A4921534E156a27e64B231fE &> /rust_container_runner/docker_assets/geth.log &

# echo "waiting for geth to come online"
# until $(curl --output /dev/null --fail --silent --header "content-type: application/json" --data '{"method":"eth_blockNumber","params":[],"id":1,"jsonrpc":"2.0"}' http://localhost:8545); do
#     sleep 1
# done
# echo "waiting for geth to sync"
# until [ "$(curl -s --header "content-type: application/json" --data '{"id":1,"jsonrpc":"2.0","method":"eth_syncing","params":[]}' http://localhost:8545)" == '{"jsonrpc":"2.0","id":1,"result":false}' ]; do
#     sleep 1
# done

RUST_LOG="INFO" RUST_BACKTRACE=full /rust_container_runner/docker_assets/internal_runner > /rust_container_runner/docker_assets/host_eth_rpc.log &
sleep 10000
