#!/bin/bash
set -ex

# FIXME do this entirely with Rust `Command`s and multiple binaries

TEST_TYPE=$1

set -u

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOCKERFOLDER=$DIR/docker_assets
REPOFOLDER=$DIR

# setup for Mac M1 Compatibility
PLATFORM_CMD=""
CROSS_COMPILE=""
RCR_TARGET="x86_64-unknown-linux-gnu"
if [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ -n $(sysctl -a | grep brand | grep "M1") ]]; then
       echo "Setting --platform=linux/amd64 for Mac M1 compatibility"
       PLATFORM_CMD="--platform=linux/amd64";
    fi
    echo "Using x86_64-unknown-linux-musl as the target for Mac M1 compatibility"
    # MacOS `ld` doesn't support `--version-script` which leads to linker errors
    CROSS_COMPILE="x86_64-linux-musl-"
    RCR_TARGET="x86_64-unknown-linux-musl"
    # the linker is also set in `orchestrator/.cargo/config`
fi

VOLUME_ARGS="-v ${REPOFOLDER}:/rust_container_runner"

RUN_ARGS_ETH_RPC=""
RUN_ARGS_TCP=""
if [[ "${TEST_TYPE:-}" == "NO_SCRIPTS" ]]; then
   echo "Running container instance without starting scripts"
   RUN_ARGS_ETH_RPC="sleep infinity"
else
   RUN_ARGS_ETH_RPC="/bin/bash /rust_container_runner/docker_assets/run_eth_rpc.sh"
   RUN_ARGS_TCP="/bin/bash /rust_container_runner/docker_assets/run_tcp.sh"
fi

# getting the `test-runner` binary with the x86_64-linux-musl, because the tests will be running on linux
PATH=$PATH:$HOME/.cargo/bin CROSS_COMPILE=$CROSS_COMPILE cargo build --release --target=$RCR_TARGET
# note --out-dir is unstable currently
# because the binaries are put in different directories depending on $RCR_TARGET, copy them to a common place
cp $REPOFOLDER/target/$RCR_TARGET/release/eth_rpc $DOCKERFOLDER/eth_rpc
cp $REPOFOLDER/target/$RCR_TARGET/release/tcp $DOCKERFOLDER/tcp

docker rm -f rust_test_runner_image
docker build -t rust_test_runner_image $PLATFORM_CMD .

set +e
docker network rm testnet
set -e
# insure everything is self contained
docker network create --internal testnet

#DOCKER_ID_TCP=$(docker create --rm --network=testnet --hostname="host_tcp" ${VOLUME_ARGS} ${PLATFORM_CMD} rust_test_runner_image ${RUN_ARGS_TCP})

DOCKER_ID_ETH_RPC=$(docker create --network=testnet --hostname="host_eth_rpc" --name="host_eth_rpc" ${PLATFORM_CMD} ${VOLUME_ARGS} rust_test_runner_image ${RUN_ARGS_ETH_RPC})

docker start $DOCKER_ID_ETH_RPC
docker attach $DOCKER_ID_ETH_RPC &> $DOCKERFOLDER/host_eth_rpc.log &

read -p "Press Return to Close..."

#curl -s --header "Content-Type: application/json" --data '{"method":"eth_blockNumber","params":[],"id":93,"jsonrpc":"2.0"}' http://host_proxy:8545/solana
#curl -s --header "Content-Type: application/json" --data '{"method":"eth_syncing","params":[],"id":93,"jsonrpc":"2.0"}' http://host_proxy:8545/solana

#curl -s --header "Content-Type: application/json" --data '{"method":"eth_getBlockByNumber","params":["finalized",false],"id":99,"jsonrpc":"2.0"}' http://localhost:8545

#docker rm -f $DOCKER_ID_TCP
docker rm -f $DOCKER_ID_ETH_RPC
