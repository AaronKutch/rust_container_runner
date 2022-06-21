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

#DB_IMAGE="postgres:14.0"
#EVM_LOADER_IMAGE="neonlabsorg/evm_loader:fdcd80bd38d0fdc4d03fedc6d57b48f590590812"
#PROXY_IMAGE="neonlabsorg/proxy:5dc2bdf1cde01dfd97f313d91a7450a0d952093c"
#FAUCET_IMAGE="neonlabsorg/faucet:19a661e04545f3a880efc04f9b7924ba7c0d92cb"

#docker rm -f rust_test_runner_image
#docker-compose -f docker-compose-neon2.yml down

#docker build -t rust_test_runner_image $PLATFORM_CMD .

set +e
docker network rm net
set -e
# insure everything is self contained
docker network create --internal net

#DOCKER_ID_TCP=$(docker create --rm --network=net --hostname="host_tcp" ${VOLUME_ARGS} ${PLATFORM_CMD} rust_test_runner_image ${RUN_ARGS_TCP})

# NOTE: this local setup is different from the production setup.
# https://docs.neon-labs.org/docs/developing/dev_environment/solana_cluster/cluster_installation

# DOCKER_ID_DB=$(docker create --network=testnet --hostname="host_db" --name="host_db" ${PLATFORM_CMD} --env="POSTGRES_DB=neon-db" --env="POSTGRES_USER=neon-proxy" --env="POSTGRES_PASSWORD=neon-proxy-pass" ${DB_IMAGE})

# DOCKER_ID_SOLANA=$(docker create --network=testnet --hostname="host_solana" --name="host_solana" --env="RUST_LOG=solana_runtime::system_instruction_processor=info,solana_runtime::message_processor=info,solana_bpf_loader=info,solana_rbpf=info" --env="SOLANA_URL=http://host_solana:8899" --health-cmd=[CMD-SHELL,"./wait-for-neon.sh"] --health-interval=5s --health-timeout=5s --health-retries=20 --health-start-period=5s ${VOLUME_ARGS} ${EVM_LOADER_IMAGE} bash /rust_container_runner/docker_assets/solana-run-neon.sh)
#--workdir="/"

#DOCKER_ID_FAUCET=$(docker create --network=testnet --hostname="host_faucet" --name="host_faucet" ${PLATFORM_CMD} --env="FAUCET_RPC_BIND=0.0.0.0" --env="FAUCET_RPC_PORT=3333" --env="SOLANA_URL=http://host_solana:8899" --env="NEON_ETH_MAX_AMOUNT=900000000" --env="EVM_LOADER=53DfF883gyixYNXnM7s5xhdeyV8mVk9T4i2hGV9vG9io" --env="FAUCET_WEB3_ENABLE=false" --env="FAUCET_SOLANA_ENABLE=true" --env="NEON_OPERATOR_KEYFILE=/root/.config/solana/id.json" --env="SOLANA_COMMITMENT=confirmed" --env="TEST_FAUCET_INIT_NEON_BALANCE=100000000" --env="NEON_TOKEN_MINT=HPsV9Deocecw3GeZv1FkAPNCBRfuVyfw9MMwjwRe1xaU" --env="NEON_TOKEN_MINT_DECIMALS=9" --env="SOLANA_COMMITMENT=confirmed" --env="NEON_ERC20_TOKENS=[\"0xB521b9F3484deF53545F276F1DAA50ef0Ca82E2d\",\"0x8a2a66CA0E5D491A001957edD45A6350bC76D708\",\"0x914782059DC42d4E590aeFCfdbF004B2EcBB9fAA\",\"0x7A7510b9b18241C788a7aAE8299D1fA6010D8128\"]" --entrypoint="./run-test-faucet.sh" ${VOLUME_ARGS} ${FAUCET_IMAGE})
#--env="FAUCET_RPC_ALLOWED_ORIGINS=http://host_eth_rpc"

# database creation is also handled here
#DOCKER_ID_PROXY=$(docker create --network=testnet --hostname="host_proxy" --name="host_proxy" ${PLATFORM_CMD} --env="SOLANA_URL=http://host_solana:8899" --env="EVM_LOADER=53DfF883gyixYNXnM7s5xhdeyV8mVk9T4i2hGV9vG9io" --entrypoint="" ${VOLUME_ARGS} ${PROXY_IMAGE} bash /rust_container_runner/docker_assets/neon_proxy.sh)

#DOCKER_ID_ETH_RPC=$(docker create --network=testnet --hostname="host_eth_rpc" --name="host_eth_rpc" ${PLATFORM_CMD} ${VOLUME_ARGS} rust_test_runner_image ${RUN_ARGS_ETH_RPC})

# delayed start to wait for everything to be pulled and created
#docker start $DOCKER_ID_TCP
# there is unfortunately a small period of time where stdout could be lost, but there seems to be no
# way around this, redirecting anywhere else gets the wrong stdout
#docker attach $DOCKER_ID_TCP &> $DOCKERFOLDER/host_tcp.log &
#docker start $DOCKER_ID_DB
#docker attach $DOCKER_ID_DB &> $DOCKERFOLDER/host_db.log &
# docker start $DOCKER_ID_SOLANA
# docker attach $DOCKER_ID_SOLANA &> $DOCKERFOLDER/host_solana.log &
# docker exec host_solana ./wait-for-neon.sh 100
#docker start $DOCKER_ID_FAUCET
#docker attach $DOCKER_ID_FAUCET &> $DOCKERFOLDER/host_faucet.log &
#docker start $DOCKER_ID_PROXY
#docker attach $DOCKER_ID_PROXY &> $DOCKERFOLDER/host_proxy.log &

# sleep 10

#docker start $DOCKER_ID_ETH_RPC
#docker attach $DOCKER_ID_ETH_RPC &> $DOCKERFOLDER/host_eth_rpc.log &

export NEON_EVM_COMMIT="v0.8.1"
export REVISION="v0.8.1"
export FAUCET_COMMIT=19a661e04545f3a880efc04f9b7924ba7c0d92cb
docker-compose -f docker-compose-neon.yml build
# set so Ctrl-C force kills containers but not the whole script
set +e
docker-compose -f docker-compose-neon.yml up --force-recreate
set -e

read -p "Press enter to end"

docker-compose -f docker-compose-neon.yml down

#curl --header "Content-Type: application/json" --data '{"method":"eth_blockNumber","params":[],"id":93,"jsonrpc":"2.0"}' http://proxy:9090/solana
#curl --header "Content-Type: application/json" --data '{"method":"eth_blockNumber","params":[],"id":93,"jsonrpc":"2.0"}' http://localhost:9090/solana
#curl --header "Content-Type: application/json" --data '{"method":"eth_blockNumber","params":[],"id":93,"jsonrpc":"2.0"}' http://solana:8899/solana

#docker rm -f $DOCKER_ID_TCP
#docker rm -f $DOCKER_ID_DB
# docker rm -f $DOCKER_ID_SOLANA
#docker rm -f $DOCKER_ID_FAUCET
#docker rm -f $DOCKER_ID_PROXY
#docker rm -f $DOCKER_ID_ETH_RPC
