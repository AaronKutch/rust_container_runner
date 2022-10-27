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

LODESTAR_VERSION=v1.1.1

set +e
docker network rm testnet
set -e
# insure everything is self contained
docker network create --internal testnet

#DOCKER_ID_TCP=$(docker create --rm --network=testnet --hostname="host_tcp" ${VOLUME_ARGS} ${PLATFORM_CMD} rust_test_runner_image ${RUN_ARGS_TCP})

DOCKER_ID_ETH_RPC=$(docker create --network=testnet --hostname="host_eth_rpc" --name="host_eth_rpc" ${PLATFORM_CMD} ${VOLUME_ARGS} rust_test_runner_image ${RUN_ARGS_ETH_RPC})

docker start $DOCKER_ID_ETH_RPC
docker attach $DOCKER_ID_ETH_RPC &> $DOCKERFOLDER/host_eth_rpc.log &

DOCKER_ID_LODESTAR_BEACON=$(docker create --network=testnet --hostname="host_lodestar" --name="host_lodestar" ${PLATFORM_CMD} ${VOLUME_ARGS} chainsafe/lodestar:${LODESTAR_VERSION} dev --genesisValidators 4 --genesisTime 0 --startValidators 0..4 --enr.ip 127.0.0.1 --rest.address 0.0.0.0 --rest.port 9596 --params.ALTAIR_FORK_EPOCH 0 --params.BELLATRIX_FORK_EPOCH 0 --terminal-total-difficulty-override 0 --suggestedFeeRecipient 0xBf660843528035a5A4921534E156a27e64B231fE --execution.urls https://host_eth_rpc:8545)

docker start $DOCKER_ID_LODESTAR_BEACON
docker attach $DOCKER_ID_LODESTAR_BEACON &> $DOCKERFOLDER/host_lodestar.log &

# {"data":{"peer_id":"16Uiu2HAmLLP2GcPBELTN4spLxB7Lfe1REDF4NZgEPoQJ6c11NgBR","enr":"enr:-La4QGT-m9zM1XmuFA3N_E_ZUWpfN6SLVdyJimkF43zz9t3uFCwDOa5CUCE1ga-MTQGTSb_nMOnRBjEKpiKQe7hZnrQFh2F0dG5ldHOIAAAAAAAAAACEZXRoMpCFKNLJAgAAAf__________gmlkgnY0gmlwhH8AAAGJc2VjcDI1NmsxoQNyGRhuGmIqrEttr0Ll7qmAD8bs7bsRQmZugfZP3dpWYIhzeW5jbmV0c4gAAAAAAAAAAA","p2p_addresses":["/ip4/127.0.0.1/tcp/9000","/ip4/172.25.0.3/tcp/9000"],"discovery_addresses":[],"metadata":{"seq_number":"0","attnets":"0x0000000000000000","syncnets":"0x00"}}}

LODESTAR_ENR='{"data":{"peer_id":"16Uiu2HAmMnQSXsUBzKoCBRkWSPsGUCF95ZhxsmfbxzhExK6NjEFM","enr":"enr:-La4QEdn4PlVChPxKuxkDxUVroDUt-84p8wWT0VmTLMcwJvHdL1Y6sTs0aOCTvP_faTSFZ1_t5hCaVzBw7u6InVJvAgFh2F0dG5ldHOIAAAAAAAAAACEZXRoMpCFKNLJAgAAAf__________gmlkgnY0gmlwhH8AAAGJc2VjcDI1NmsxoQOHn3yywAuL7ADBJJPG2oYbBPerP8GOr_ozl-nP9E6CFIhzeW5jbmV0c4gAAAAAAAAAAA","p2p_addresses":["/ip4/127.0.0.1/tcp/9000","/ip4/172.26.0.3/tcp/9000"],"discovery_addresses":[],"metadata":{"seq_number":"0","attnets":"0x0000000000000000","syncnets":"0x00"}}}'
#$LOG_FOLDER/lodestar_enr

DOCKER_ID_LODESTAR_VALIDATORS=$(docker create --network=testnet --hostname="host_lodestar_validators" --name="host_lodestar_validators" ${PLATFORM_CMD} ${VOLUME_ARGS} chainsafe/lodestar:${LODESTAR_VERSION} dev --genesisValidators 4 --genesisTime 0 --port 9001 --rest.port 9597 --server="https://host_lodestar:9596" --params.ALTAIR_FORK_EPOCH 0 --params.BELLATRIX_FORK_EPOCH 0 --terminal-total-difficulty-override 0 --suggestedFeeRecipient 0xBf660843528035a5A4921534E156a27e64B231fE --execution.urls https://host_eth_rpc:8545)

docker start $DOCKER_ID_LODESTAR_VALIDATORS
docker attach $DOCKER_ID_LODESTAR_VALIDATORS &> $DOCKERFOLDER/host_lodestar_validators.log &

read -p "Press Return to Close..."

#curl -s --header "Content-Type: application/json" --data '{"method":"eth_blockNumber","params":[],"id":93,"jsonrpc":"2.0"}' http://host_proxy:8545/solana
#curl -s --header "Content-Type: application/json" --data '{"method":"eth_syncing","params":[],"id":93,"jsonrpc":"2.0"}' http://host_proxy:8545/solana

#curl -s --header "Content-Type: application/json" --data '{"method":"eth_getBlockByNumber","params":["finalized",false],"id":99,"jsonrpc":"2.0"}' http://localhost:8545
#curl -s --header "Content-Type: application/json" --data '{"method":"eth_getBlockByNumber","params":["latest",false],"id":99,"jsonrpc":"2.0"}' http://localhost:8545
#curl -s --header "Content-Type: application/json" --data '{"method":"eth_getBalance","params":["0xBf660843528035a5A4921534E156a27e64B231fE"],"id":99,"jsonrpc":"2.0"}' http://localhost:8545
#curl -s --header "content-type: application/json" --data '{"id":12,"jsonrpc":"2.0","method":"eth_sendRawTransaction","params":["0xf86f808506fc23ac00825dc094b3d82b1367d362de99ab59a658165aff520cbd4d8b084595161401484a0000008025a075f7149a8b51b5d8808d8ec06af765f754d0a841e55a6d5e86a671fb262d5daea035fa0f2a06a501f776b121388784e98a91d526c663133e49367a783a94608b62"]}' http://localhost:8545
#curl -s --header "Content-Type: application/json" --data '{"method":"net_version","params":[],"id":99,"jsonrpc":"2.0"}' http://localhost:8545

#docker rm -f $DOCKER_ID_TCP
docker rm -f $DOCKER_ID_ETH_RPC
docker rm -f $DOCKER_ID_LODESTAR_BEACON
docker rm -f $DOCKER_ID_LODESTAR_VALIDATORS
