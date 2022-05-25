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

EVM_LOADER_IMAGE="neonlabsorg/evm_loader:d10ea83c02257b885d71fb3d62d64f9d28f4507d"
PROXY_IMAGE="neonlabsorg/proxy:5fe50d3b6d050fc6c44c6b0e5097de89ea3da2c5"
# there are scripts still hardcoded with 8899
SOLANA_URL="http://solana:8899"

RUN_ARGS_SOLANA="/opt/solana/bin/solana-run-neon.sh"

#docker rm -f rust_test_runner_image
#docker build -t rust_test_runner_image $PLATFORM_CMD .

# docker-compose has too many problems with conditionally propogating env variables to it and
# subcommands, so we manually compose a network

set +e
docker network rm testnet
set -e
# insure everything is self contained
docker network create --internal testnet

DOCKER_ID_TCP=$(docker create --rm --network=testnet --hostname="host_tcp" ${VOLUME_ARGS} ${PLATFORM_CMD} rust_test_runner_image ${RUN_ARGS_TCP})
#DOCKER_ID_SOLANA=$(docker create --network=testnet --hostname="host_solana" ${PLATFORM_CMD} --entrypoint="/opt/solana/bin/solana-run-neon.sh" ${EVM_LOADER_IMAGE} ${RUN_ARGS_SOLANA})
DOCKER_ID_ETH_RPC=$(docker create --network=testnet --hostname="host_eth_rpc" ${VOLUME_ARGS} ${PLATFORM_CMD} rust_test_runner_image ${RUN_ARGS_ETH_RPC})

# delayed start to wait for everything to be pulled and created
docker start $DOCKER_ID_TCP
# there is unfortunately a small period of time where stdout could be lost, but there seems to be no
# way around this, redirecting anywhere else gets the wrong stdout
docker attach $DOCKER_ID_TCP &> $DOCKERFOLDER/host_tcp.log &
docker start $DOCKER_ID_ETH_RPC
docker attach $DOCKER_ID_ETH_RPC &> $DOCKERFOLDER/host_eth_rpc.log &

read -p "Press Return to Close..."

docker rm -f $DOCKER_ID_TCP
docker rm -f $DOCKER_ID_ETH_RPC
