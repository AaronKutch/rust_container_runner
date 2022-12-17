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
# request funds for block stimulator
curl -X POST -d '{"wallet": "0x3Cd0A705a2DC65e5b1E1205896BaA2be8A07c6e0", "amount": 100000000}' 'http://faucet:3333/request_neon'

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

# the setup for local testing. The genesis file prefunds
# 0xb1bab011e03a9862664706fc3bbaa1b16651528e5f0e7fbfcbfdd8be302a13e7
# and 0x8075991ce870b93a8870eca0c0f91913d12f47948ca0fd25b49c6fa7cdbeee8b
# avalanchego \
#     --genesis="/rust_container_runner/docker_assets/ETHGenesis.json" \
#     --chain-config-dir="/rust_container_runner/docker_assets/avalanchego_configs" \
#     --network-id=15 \
#     --build-dir="/avalanchego/build/" \
#     --public-ip=127.0.0.1 \
#     --http-port=8545 \
#     --db-type=memdb \
#     --staking-enabled=false &> /rust_container_runner/docker_assets/avalanchego.log &

# echo "waiting for avalanche to come online"
# until $(curl --output /dev/null --fail --silent --header "content-type: application/json" --data '{"method":"eth_blockNumber","params":[],"id":1,"jsonrpc":"2.0"}' http://localhost:8545/ext/bc/C/rpc); do
#     printf '.'
#     sleep 1
# done
# echo "waiting for avalanche to sync"
# until [ "$(curl -s --header "content-type: application/json" --data '{"id":1,"jsonrpc":"2.0","method":"eth_syncing","params":[]}' http://localhost:8545/ext/bc/C/rpc)" == '{"jsonrpc":"2.0","id":1,"result":false}' ]; do
#     sleep 1
# done

# sleep 10

# curl -s --header "content-type: application/json" --data "{\"id\":0,\"jsonrpc\":\"2.0\",\"method\":\"eth_gasPrice\",\"params\":[]}" http://localhost:8545/ext/bc/C/rpc

# curl -s --header "content-type: application/json" --data "{\"id\":0,\"jsonrpc\":\"2.0\",\"method\":\"eth_sendRawTransaction\",\"params\":[\"0xf86480854abd174a00825dc094798d4ba9baf0064ec19eb4f0a1a45785ae9d6dfc018041a0c6431389b47c22e22c7fafacd2f387643be587f3f147b314f6c15fd287868350a0153e20d10c482f80fa35ff3f631864730e475a04c509c412ee18a04b99251500\"]}" http://localhost:8545/ext/bc/C/rpc

# sleep 2

# curl -s --header "content-type: application/json" --data "{\"id\":0,\"jsonrpc\":\"2.0\",\"method\":\"eth_gasPrice\",\"params\":[]}" http://localhost:8545/ext/bc/C/rpc

# curl -s --header "content-type: application/json" --data "{\"id\":0,\"jsonrpc\":\"2.0\",\"method\":\"eth_sendRawTransaction\",\"params\":[\"0xf86401854abd174a00825dc094798d4ba9baf0064ec19eb4f0a1a45785ae9d6dfc018041a0b73c2e801dc4f48c5018290642acd88317191b85c033a2adf329260e9ee638faa055cc345bc16b1a7432b27eb33230af58a5611f8eaa2a9087bc02b0ee3deadcbd\"]}" http://localhost:8545/ext/bc/C/rpc

# sleep 2

# curl -s --header "content-type: application/json" --data "{\"id\":0,\"jsonrpc\":\"2.0\",\"method\":\"eth_gasPrice\",\"params\":[]}" http://localhost:8545/ext/bc/C/rpc

# sleep 2

# # use the zero gas price
# curl -s --header "content-type: application/json" --data "{\"id\":0,\"jsonrpc\":\"2.0\",\"method\":\"eth_sendRawTransaction\",\"params\":[\"0xf85f0180825dc094798d4ba9baf0064ec19eb4f0a1a45785ae9d6dfc018041a0f93ecf61786a6ce0f6a1aad869030db92082a4640a57abbaf8417be42d322500a0296848c11369ad72d01f579c609fc9d1b8baee28c06bc98a7db7570a5cee3abb\"]}" http://localhost:8545/ext/bc/C/rpc

# sleep 2

# curl -s --header "content-type: application/json" --data "{\"id\":0,\"jsonrpc\":\"2.0\",\"method\":\"eth_gasPrice\",\"params\":[]}" http://localhost:8545/ext/bc/C/rpc


# sleep 1000

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

RUST_LOG="TRACE" RUST_BACKTRACE=full /rust_container_runner/docker_assets/internal_runner > /rust_container_runner/docker_assets/host_eth_rpc.log &
sleep 10000
