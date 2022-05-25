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

VOLUME_ARGS="${REPOFOLDER}:/rust_container_runner"

RUN_ARGS=""
if [[ "${TEST_TYPE:-}" == "NO_SCRIPTS" ]]; then
   echo "Running container instance without starting scripts"
else
   RUN_ARGS="/bin/bash /rust_container_runner/docker_assets/run_internal.sh"
fi

# getting the `test-runner` binary with the x86_64-linux-musl, because the tests will be running on linux
PATH=$PATH:$HOME/.cargo/bin CROSS_COMPILE=$CROSS_COMPILE cargo build --release --target=$RCR_TARGET
# note --out-dir is unstable currently
# because the binaries are put in different directories depending on $RCR_TARGET, copy them to a common place
cp $REPOFOLDER/target/$RCR_TARGET/release/rust_container_runner $DOCKERFOLDER/internal_runner

EVM_LOADER_IMAGE="neonlabsorg/evm_loader:d10ea83c02257b885d71fb3d62d64f9d28f4507d"
PROXY_IMAGE="neonlabsorg/proxy:5fe50d3b6d050fc6c44c6b0e5097de89ea3da2c5"
# there are scripts still hardcoded with 8899
SOLANA_URL="http://localhost:8899"

EVM_LOADER_IMAGE=$EVM_LOADER_IMAGE PROXY_IMAGE=$PROXY_IMAGE SOLANA_URL=$SOLANA_URL RUN_ARGS=$RUN_ARGS VOLUME_ARGS=$VOLUME_ARGS docker-compose down

set +e
EVM_LOADER_IMAGE=$EVM_LOADER_IMAGE PROXY_IMAGE=$PROXY_IMAGE SOLANA_URL=$SOLANA_URL RUN_ARGS=$RUN_ARGS VOLUME_ARGS=$VOLUME_ARGS docker-compose up -d
set -e

#error trying to connect: tcp connect error: Cannot assign requested address

read -p "Press Return to Close..."

EVM_LOADER_IMAGE=$EVM_LOADER_IMAGE PROXY_IMAGE=$PROXY_IMAGE SOLANA_URL=$SOLANA_URL RUN_ARGS=$RUN_ARGS VOLUME_ARGS=$VOLUME_ARGS docker-compose down
