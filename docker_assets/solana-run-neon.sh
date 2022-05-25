#!/usr/bin/env bash

# we needed to customize `SOLANA_URL`

set -e

SOLANA_BIN=/opt/solana/bin
NEON_BIN=/opt

if [ -z "$SOLANA_URL" ]; then
  echo "SOLANA_URL is not set"
  exit 1
fi

cd ${SOLANA_BIN}

function deploy_tokens() {
    # deploy tokens needed by Neon EVM
    export SKIP_EVM_DEPLOY="YES"
    export SOLANA_URL=$SOLANA_URL

    cd ${NEON_BIN}
    ./wait-for-solana.sh 20
    ./deploy-evm.sh
}

deploy_tokens &

# run Solana with Neon EVM in genesis

EVM_LOADER_SO=evm_loader.so
EVM_LOADER=$(${SOLANA_BIN}/solana address -k ${NEON_BIN}/evm_loader-keypair.json)
EVM_LOADER_PATH=${NEON_BIN}/${EVM_LOADER_SO}

cp ${EVM_LOADER_PATH} .

NEON_BPF_ARGS=(
    --bpf-program ${EVM_LOADER} BPFLoader2111111111111111111111111111111111 ${EVM_LOADER_SO}
)

NEON_VALIDATOR_ARGS=(
    --gossip-host $(hostname -i)
)

export SOLANA_RUN_SH_GENESIS_ARGS="${NEON_BPF_ARGS[@]}"
export SOLANA_RUN_SH_VALIDATOR_ARGS="${NEON_VALIDATOR_ARGS[@]}"

./solana-run.sh
