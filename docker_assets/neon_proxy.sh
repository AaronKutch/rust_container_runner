
cd /opt/

export POSTGRES_DB="host_db"
export POSTGRES_USER=neon-proxy
export POSTGRES_PASSWORD=neon-proxy-pass
bash proxy/run-dbcreation.sh

#export EVM_LOADER=$(solana address -k /spl/bin/evm_loader-keypair.json)
#export $(/spl/bin/neon-cli --commitment confirmed --url $SOLANA_URL --evm_loader="$EVM_LOADER" neon-elf-params)

[[ -z "$SOLANA_URL"                   ]] && export SOLANA_URL="http://host_solana:8899"
[[ -z "$EXTRA_GAS"                    ]] && export EXTRA_GAS=0
[[ -z "$NEON_CLI_TIMEOUT"             ]] && export NEON_CLI_TIMEOUT="0.9"
[[ -z "$MINIMAL_GAS_PRICE"            ]] && export MINIMAL_GAS_PRICE=1
[[ -z "$POSTGRES_HOST"                ]] && export POSTGRES_HOST="host_db"
[[ -z "$CANCEL_TIMEOUT"               ]] && export CANCEL_TIMEOUT=10
[[ -z "$RETRY_ON_FAIL"                ]] && export RETRY_ON_FAIL=10
[[ -z "$FINALIZED"                    ]] && export FINALIZED="finalized"
[[ -z "$START_SLOT"                   ]] && export START_SLOT=0
[[ -z "$CONFIRM_TIMEOUT"              ]] && export CONFIRM_TIMEOUT=10
[[ -z "$PERM_ACCOUNT_LIMIT"           ]] && export PERM_ACCOUNT_LIMIT=2

export PROMETHEUS_MULTIPROC_DIR=$(mktemp -d)

python3 -m proxy --hostname 0.0.0.0 --port 8545 --enable-web-server --plugins proxy.plugin.NeonRpcApiPlugin --timeout 20
