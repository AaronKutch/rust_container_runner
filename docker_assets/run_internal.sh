#!/bin/bash

# so that database related folders are not spawning in the scripts folder
pushd /


# we may not need nearup
#RUN dnf install -y python3-pip
#RUN pip3 install --user nearup
#RUN mv ~/.local/bin/nearup /usr/local/bin/nearup

# note: we get the address from `aurora encode-address test.near`
# which returns 0xCBdA96B3F2B8eb962f97AE50C3852CA976740e2B
# there is also things like `get-balance` and `get-code`
#
# 0x56EFf90C050eb23446Cad8a8eF499769A1820146

export NEAR_ENV=localnet
export NEAR_URL=http://localhost:3030

# TODO I have run
# cp ~/nearcore/target/quick-release/neard ~/rust_container_runner/docker_assets/neard

# remove old files
rm -rf /rust_container_runner/docker_assets/near_config/.near/*
# this is what generates the config, genesis, and key files
/rust_container_runner/docker_assets/neard init --chain-id 15
# note: only for tests, do not do this in production of course
chmod +r /rust_container_runner/docker_assets/near_config/.near/node_key.json
chmod +r /rust_container_runner/docker_assets/near_config/.near/validator_key.json
/rust_container_runner/docker_assets/neard run &> /rust_container_runner/docker_assets/host_neard.log &
echo "waiting for neard to come online"
until $(curl --output /dev/null --fail --silent http://localhost:3030/status); do
    sleep 1
done

# curl --header "content-type: application/json" --data '{"method":"eth_blockNumber","params":[],"id":1,"jsonrpc":"2.0"}' http://localnet_endpoint:8545
# curl --header "content-type: application/json" --data '{"method":"eth_getBalance","params":["0x56EFf90C050eb23446Cad8a8eF499769A1820146", "latest"],"id":1,"jsonrpc":"2.0"}' http://localnet_endpoint:8545

near create-account aurora.test.near --master-account=test.near --initial-balance 900000000

# aurora `install` seems to have trouble, `near deploy` works
near deploy --account-id=aurora.test.near --wasm-file=/rust_container_runner/docker_assets/localnet-release.wasm

#aurora initialize --chain 15 --owner test.near
#aurora --signer aurora.test.near --engine aurora.test.near install --chain 15 --owner test.near /rust_container_runner/docker_assets/localnet-release.wasm

# echo "waiting for aurora-relayer to come online"
until $(curl --output /dev/null --fail --silent --header "content-type: application/json" --data '{"method":"eth_blockNumber","params":[],"id":1,"jsonrpc":"2.0"}' http://localnet_endpoint:8545); do
    sleep 1
done
# echo "waiting for aurora-relayer to sync"
until [ "$(curl -s --header "content-type: application/json" --data '{"id":1,"jsonrpc":"2.0","method":"eth_syncing","params":[]}' http://localnet_endpoint:8545)" == '{"jsonrpc":"2.0","id":1,"result":false}' ]; do
    sleep 1
done

RUST_LOG="INFO" RUST_BACKTRACE=full /rust_container_runner/docker_assets/internal_runner > /rust_container_runner/docker_assets/host_eth_rpc.log &
sleep infinity
