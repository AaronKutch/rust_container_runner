#!/bin/bash

# so that database related folders are not spawning in the scripts folder
pushd /

#geth --identity "GravityTestnet" --nodiscover \
#    --networkid 15 \
#    --mine \
#    --http \
#    --http.addr="0.0.0.0" \
#    --http.vhosts="*" \
#    --http.corsdomain="*" \
#    --miner.threads=1 \
#    --nousb \
#    --verbosity=5 \
#    --miner.etherbase=0xBf660843528035a5A4921534E156a27e64B231fE &> /rust_container_runner/docker_assets/geth.log &

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
# command below and edit `test_runner/src/main.rs` by changing `MINER_PRIVATE_KEY`
# to use 0x163F5F0F9A621D72FEDD85FFCA3D08D131AB4E812181E0D30FFD1C885D20AAC7
# and uncommenting the special `send_eth_bulk` that sends tokens to the address we
# want to use. Uncomment the other `opera` command below which will use Fantom's
# default genesis. Then, run `USE_LOCAL_ARTIFACTS=1 bash tests/all-up-test.sh NO_SCRIPTS`
# and get a command prompt to the running container. In the container run
# `bash /gravity/tests/container-scripts/all-up-test-internal.sh 4` and wait for the panic
# "sent eth to default address" (or for some reason the test runner can hang, look at
# `opera.log` to see if the transaction has happened and then kill the test runner).
# Then in the container `pkill opera` and run
# `opera --datadir /opera_datadir/ export genesis /gravity/tests/assets/test_genesis.g --export.evm.mode=ext-mpt`
# which will convert the state of the testchain up to that point into a new genesis that we
# use for normal runs. Commit the `test_genesis.g` and undo the other changes.

opera --fakenet 1/1 \
    --nodiscover \
    --http \
    --http.addr="localhost" \
    --http.port="8545" \
    --http.api="eth,debug,net,admin,web3,personal,txpool,ftm,dag" \
    --verbosity 5 \
    --datadir="/opera_datadir" &> /rust_container_runner/docker_assets/opera.log &

# The fakenet chain id is 4003, which is different from the production id of 250
#opera --genesis="/gravity/tests/assets/test_genesis.g" \
#    --genesis.allowExperimental=true \
#    --nodiscover \
#    --http \
#    --http.addr="localhost" \
#    --http.port="8545" \
#    --http.api="eth,debug,net,admin,web3,personal,txpool,ftm,dag" \
#    --datadir="/opera_datadir" &> /opera.log &

echo "waiting for go-opera to come online"
until $(curl --output /dev/null --fail --silent --header "content-type: application/json" --data '{"method":"eth_blockNumber","params":[],"id":1,"jsonrpc":"2.0"}' http://localhost:8545); do
    sleep 1
done
# go-opera takes a few seconds to sync
echo "waiting for go-opera to sync"
until [ "$(curl -s --header "content-type: application/json" --data '{"id":1,"jsonrpc":"2.0","method":"eth_syncing","params":[]}' http://localhost:8545)" == '{"jsonrpc":"2.0","id":1,"result":false}' ]; do
    sleep 1
done

# send from dev account (priv 0x163F5F0F9A621D72FEDD85FFCA3D08D131AB4E812181E0D30FFD1C885D20AAC7/pub 0x239fA7623354eC26520dE878B52f13Fe84b06971) to 0xBf660843528035a5A4921534E156a27e64B231fE
curl -s --header "content-type: application/json" --data '{"id":12,"jsonrpc":"2.0","method":"eth_sendRawTransaction","params":["0xf871808506fc23ac00825dc094bf660843528035a5a4921534e156a27e64b231fe8b52b7d2dcc80cd2e400000080821f6aa020bac4e3944d6b12075eee0e58ec9e40270a9a977feba34362190a825575f550a07272d97392a1a7d0bda2a0bb62da49b45275f873259a16e463603a60abf9a5cf"]}' http://localhost:8545

echo "waiting for transaction to account 0xBf6608..."
until [ "$(curl -s --header "content-type: application/json" --data '{"id":1,"jsonrpc":"2.0","method":"eth_getBalance","params":["0xBf660843528035a5A4921534E156a27e64B231fE","latest"]}' http://localhost:8545)" == '{"jsonrpc":"2.0","id":1,"result":"0x52b7d2dcc80cd2e4000000"}' ]; do
     sleep 1
done

#curl -s --header "content-type: application/json" --data '{"id":14,"jsonrpc":"2.0","method":"eth_getTransactionCount","params":["0xf870808506fc23ac00825dc094bf660843528035a5a4921534e156a27e64b231fe8ad3c21bcecceda100000080820a25a0828252174fcb379be0317d4448bf0ca5296873422a9d19bf1418cc36c447c955a0127c426b2e1e5be9f30f37b2d04ebf7ed75686d43253d25deb90f0445deb2745"]}' http://localhost:8545


#curl -s --header "content-type: application/json" --data '{"id":14,"jsonrpc":"2.0","method":"eth_sendRawTransaction","params":["0xf870808506fc23ac00825dc094bf660843528035a5a4921534e156a27e64b231fe8ad3c21bcecceda100000080820a25a0828252174fcb379be0317d4448bf0ca5296873422a9d19bf1418cc36c447c955a0127c426b2e1e5be9f30f37b2d04ebf7ed75686d43253d25deb90f0445deb2745"]}' http://localhost:8545

# {"id":14,"jsonrpc":"2.0","method":"eth_sendRawTransaction","params":["0xf870808506fc23ac00825dc094bf660843528035a5a4921534e156a27e64b231fe8ad3c21bcecceda100000080820a25a0828252174fcb379be0317d4448bf0ca5296873422a9d19bf1418cc36c447c955a0127c426b2e1e5be9f30f37b2d04ebf7ed75686d43253d25deb90f0445deb2745"]}

#curl -s --header "content-type: application/json" --data "{\"id\":10,\"jsonrpc\":\"2.0\",\"method\":\"eth_chainId\",\"params\":[]}" http://localhost:8545

# transfer funds from Alith account to account used by bridge
#curl -s --header "content-type: application/json" --data "{\"id\":10,\"jsonrpc\":\"2.0\",\"method\":\"eth_sendRawTransaction\",\"params\":[\"0xf870808506fc23ac00825dc094bf660843528035a5a4921534e156a27e64b231fe8ae8ef1e96ae389780000080820a25a03c8d2c425d0b408b4b9084de247f9051854598dc4a3ab0803ee0aa4fe20a8c1aa06e12623f17b9c830c696a538cad8af562ec750e4fd9bdc94302b29fe871495cf\"]}" http://localhost:8545
#sleep 1000

#curl -s --header "content-type: application/json" --data "{\"id\":10,\"jsonrpc\":\"2.0\",\"method\":\"eth_getBlockByNumber\",\"params\":[\"latest\",false]}" http://localhost:8545

#curl -s --header "content-type: application/json" --data '{"jsonrpc":"2.0","result":{"author":"0xf24ff3a9cf04c71dbc94d0b566f7a27b94566cac","baseFeePerGas":"0x3b9aca00","difficulty":"0x0","extraData":"0x","gasLimit":"0xe4e1c0","gasUsed":"0x0","hash":"0x5d74beb91b07d959fc0173e6ccdaf0cecd71c111a8a002c33c4262f3f8dbd35d","logsBloom":"0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000","miner":"0xf24ff3a9cf04c71dbc94d0b566f7a27b94566cac","number":"0x8","parentHash":"0xa2ce0891a1f1de59cc3923cbaa66d38f6f40ac4f2877f7a90636992c27e1db48","receiptsRoot":"0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421","sealFields":["0x0000000000000000000000000000000000000000000000000000000000000000","0x0000000000000000"],"sha3Uncles":"0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347","size":"0x1fe","stateRoot":"0x664b7374999c57cf45e312d2248f75a49a5ce103a73c2e975c8dad3d2dcabb9d","timestamp":"0x62acf17e","totalDifficulty":"0x0","transactions":[],"transactionsRoot":"0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421","uncles":[]},"id":25}' http://localhost:8545

RUST_LOG="TRACE" RUST_BACKTRACE=full /rust_container_runner/docker_assets/eth_rpc

#sleep infinity

#curl -s --header "content-type: application/json" --data '{"id":14,"jsonrpc":"2.0","method":"eth_syncing","params":[]}' http://localhost:8545
#curl -s --header "content-type: application/json" --data '{"id":14,"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["finalized",false]}' http://localhost:8545

