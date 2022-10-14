#!/bin/bash

set -eux

# so that database related folders are not spawning in the scripts folder
pushd /

LOG_FOLDER=/rust_container_runner/docker_assets
source /rust_container_runner/docker_assets/lighthouse.env
DEBUG_LEVEL=info

# only for NO_SCRIPTS rerunning
DATADIR=~/.lighthouse/local-testnet
rm -rf $DATADIR

# `jwtsecret` was generated with `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"`

# `dev_keystore/dev_key.json` and `dev_password.txt` is also used

geth --identity "GravityTestnet" \
    --nodiscover \
    --networkid 15 \
    init $LOG_FOLDER/ETHGenesis.json
geth \
	--nodiscover \
	--allow-insecure-unlock \
	--unlock 0xBf660843528035a5A4921534E156a27e64B231fE \
	--keystore $LOG_FOLDER/dev_keystore \
	--password $LOG_FOLDER/dev_password.txt \
	--authrpc.addr localhost \
	--authrpc.port 8551 \
	--authrpc.vhosts localhost \
	--authrpc.jwtsecret $LOG_FOLDER/jwtsecret \
    --http \
    --http.addr="0.0.0.0" \
    --http.vhosts="*" \
    --http.corsdomain="*" \
    --verbosity=4 \
	&> $LOG_FOLDER/geth.log &

#ganache \
#	--defaultBalanceEther 1000000000 \
#	--gasLimit 1000000000 \
#	--accounts 10 \
#	--mnemonic "$ETH1_NETWORK_MNEMONIC" \
#	--port 8544 \
#	--blockTime $SECONDS_PER_ETH1_BLOCK \
#	--chain.chainId "$CHAIN_ID" \
#	&> $LOG_FOLDER/ganache.log &
sleep 10
#lcli \
#	deploy-deposit-contract \
#	--eth1-http http://localhost:8545 \
#	--confirmations 1 \
#	--validator-count 1
NOW=`date +%s`
GENESIS_TIME=`expr $NOW + $GENESIS_DELAY`
lcli \
	new-testnet \
	--spec $SPEC_PRESET \
	--deposit-contract-address $DEPOSIT_CONTRACT_ADDRESS \
	--testnet-dir $TESTNET_DIR \
	--min-genesis-active-validator-count 1 \
	--min-genesis-time $GENESIS_TIME \
	--genesis-delay $GENESIS_DELAY \
	--genesis-fork-version $GENESIS_FORK_VERSION \
	--altair-fork-epoch $ALTAIR_FORK_EPOCH \
    --merge-fork-epoch 0 \
	--eth1-id $CHAIN_ID \
	--eth1-follow-distance 1 \
	--seconds-per-slot $SECONDS_PER_SLOT \
	--seconds-per-eth1-block $SECONDS_PER_ETH1_BLOCK \
	--force
lcli \
	insecure-validators \
	--count 1 \
	--base-dir $DATADIR \
	--node-count 1
lcli \
	interop-genesis \
	--spec $SPEC_PRESET \
	--genesis-time $GENESIS_TIME \
	--testnet-dir $TESTNET_DIR \
	1
lcli \
	generate-bootnode-enr \
	--ip 127.0.0.1 \
	--udp-port $BOOTNODE_PORT \
	--tcp-port $BOOTNODE_PORT \
	--genesis-fork-version $GENESIS_FORK_VERSION \
	--output-dir $DATADIR/bootnode

bootnode_enr=`cat $DATADIR/bootnode/enr.dat`
echo "- $bootnode_enr" > $TESTNET_DIR/boot_enr.yaml

# boot node
lighthouse boot_node \
    --testnet-dir $TESTNET_DIR \
    --port $BOOTNODE_PORT \
    --listen-address 127.0.0.1 \
	--disable-packet-filter \
    --network-dir $DATADIR/bootnode \
	&> $LOG_FOLDER/boot_node.log &
# beacon node
lighthouse \
	--debug-level $DEBUG_LEVEL \
	bn \
	--datadir $DATADIR/node_1 \
	--testnet-dir $TESTNET_DIR \
	--enable-private-discovery \
    --http-allow-sync-stalled \
    --execution-endpoint http://localhost:8551 \
	--execution-jwt $LOG_FOLDER/jwtsecret \
	--terminal-block-hash-epoch-override 0 \
	--terminal-block-hash-override 0 \
    --subscribe-all-subnets \
	--staking \
	--enr-address 127.0.0.1 \
	--enr-udp-port $LIGHTHOUSE_TCP_PORT \
	--enr-tcp-port $LIGHTHOUSE_TCP_PORT \
	--port $LIGHTHOUSE_TCP_PORT \
	--http-port $LIGHTHOUSE_HTTP_PORT \
	--disable-packet-filter \
	--target-peers 1 \
	&> $LOG_FOLDER/beacon_node.log &
# may need second beacon node for peering
lighthouse \
	--debug-level $DEBUG_LEVEL \
	bn \
	--datadir $DATADIR/node_2 \
	--testnet-dir $TESTNET_DIR \
	--enable-private-discovery \
    --http-allow-sync-stalled \
    --execution-endpoint http://localhost:8551 \
	--execution-jwt $LOG_FOLDER/jwtsecret \
	--terminal-block-hash-epoch-override 0 \
	--terminal-block-hash-override 0 \
    --subscribe-all-subnets \
	--staking \
	--enr-address 127.0.0.1 \
	--enr-udp-port $LIGHTHOUSE_TCP_PORT2 \
	--enr-tcp-port $LIGHTHOUSE_TCP_PORT2 \
	--port $LIGHTHOUSE_TCP_PORT2 \
	--http-port $LIGHTHOUSE_HTTP_PORT2 \
	--disable-packet-filter \
	--target-peers 1 \
	&> $LOG_FOLDER/beacon_node.log &
# validator
lighthouse \
	--debug-level $DEBUG_LEVEL \
	vc \
	--datadir $DATADIR/node_1 \
	--testnet-dir $TESTNET_DIR \
	--terminal-block-hash-epoch-override 0 \
	--terminal-block-hash-override 0 \
	--init-slashing-protection \
	--beacon-nodes http://localhost:$LIGHTHOUSE_HTTP_PORT \
	&> $LOG_FOLDER/validator_node.log &

# TODO https://github.com/sigp/lighthouse/pull/3364


#geth --identity "GravityTestnet" \
#    --nodiscover \
#    --networkid 15 \
#    init /rust_container_runner/docker_assets/ETHGenesis.json
#
#geth --identity "GravityTestnet" \
#    --nodiscover \
#    --networkid 15 \
#    --mine \
#    --miner.threads=1 \
#    --miner.etherbase=0xBf660843528035a5A4921534E156a27e64B231fE \
#    --http \
#    --http.addr="0.0.0.0" \
#    --http.vhosts="*" \
#    --http.corsdomain="*" \
#    --verbosity=5 \
#    &> /rust_container_runner/docker_assets/geth.log &

# Init the genesis block. The genesis block was made by copying `tests/bor/testdata/genesis.json`
# from the `bor` repo, editing "chainId" to 15, editing "londonBlock" and "jaipurBlock" to 0,
# adding an allocation
# `"0xBf660843528035a5A4921534E156a27e64B231fE": {
#     "balance": "0x1337000000000000000000"
# }`
# To the end of the "alloc" block, and search+replace `71562b71999873DB5b286dF957af199Ec94617F7`
# with `Bf660843528035a5A4921534E156a27e64B231fE` in a large block of hex so that our account
# can be a block producer
#bor --identity "GravityTestnet" \
#    --nodiscover --networkid 15 init /rust_container_runner/docker_assets/bor_genesis.json

# `--dev` uses its own genesis, `bor` otherwise requires a keystore with the private key for
# 0xb1bab011e03a9862664706fc3bbaa1b16651528e5f0e7fbfcbfdd8be302a13e7
# It was generated by
# `from web3 import Account`
# `import json`
# `json.dumps(Account.encrypt('0xb1bab011e03a9862664706fc3bbaa1b16651528e5f0e7fbfcbfdd8be302a13e7', 'dev'))`
# and pasting the json into dev_keystore/dev_key.json
#bor --identity "GravityTestnet" \
#    --nodiscover \
#    --networkid 15 \
#    --bor.withoutheimdall \
#    --http \
#    --http.addr="0.0.0.0" \
#    --http.vhosts="*" \
#    --http.corsdomain="*" \
#    --nousb \
#    --verbosity=5 \
#    --mine \
#    --miner.etherbase=0xBf660843528035a5A4921534E156a27e64B231fE \
#    --unlock=0xBf660843528035a5A4921534E156a27e64B231fE \
#    --allow-insecure-unlock \
#    --keystore="/rust_container_runner/docker_assets/dev_keystore" \
#    --password="/rust_container_runner/docker_assets/dev_password.txt" \
#    &> /rust_container_runner/docker_assets/bor.log &

# the setup for local testing
#avalanchego \
#    --genesis="/rust_container_runner/docker_assets/avalanchego_genesis.json" \
#    --build-dir="/avalanchego/build/" \
#    --network-id=15 \
#    --public-ip=127.0.0.1 \
#    --http-port=8545 \
#    --db-type=memdb \
#    --staking-enabled=false &> /rust_container_runner/docker_assets/avalanchego.log &

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
#    --http.port="8545" \
#    --http.api="eth,debug,net,admin,web3,personal,txpool,ftm,dag" \
#    --datadir="/opera_datadir" &> /rust_container_runner/docker_assets/opera.log &

#opera --fakenet 1/1 \
#    --genesis.allowExperimental \
#    --genesis="/rust_container_runner/docker_assets/test_genesis.g" \
#    --nodiscover \
#    --http \
#    --http.addr="localhost" \
#    --http.port="8545" \
#    --http.api="eth,debug,net,admin,web3,personal,txpool,ftm,dag" \
#    --datadir="/opera_datadir" &> /rust_container_runner/docker_assets/opera.log &

# give time for bash redirection
sleep 1
# neon
#curl -i -X POST -d '{"wallet": "0xBf660843528035a5A4921534E156a27e64B231fE", "amount": 900000000}' 'http://host_faucet:3333/request_neon'
#sleep 1

RUST_LOG="TRACE" RUST_BACKTRACE=full /rust_container_runner/docker_assets/eth_rpc
