#!/bin/bash

# so that database related folders are not spawning in the scripts folder
pushd /
# the setup for local testing
# see avalanchego/genesis/genesis_local.go to see default genesis
# TODO do we need to simulate staking?
/avalanchego/build/avalanchego \
    --network-id=local \
    --public-ip=127.0.0.1 \
    --http-port=9650 \
    --db-dir=memdb \
    --staking-enabled=false &> /rust_container_runner/docker_assets/avalanchego.log &

RUST_LOG="TRACE" RUST_BACKTRACE=full /rust_container_runner/docker_assets/internal_runner
