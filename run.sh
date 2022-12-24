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

export NEON_EVM_COMMIT="efaf1cca168284333adde179faf3dfc993c1ffc4"
export PROXY_REVISION="e93af21dbf9596085a54495dfb53f5e166406299"
export FAUCET_COMMIT="v0.12.0"
export USE_LOCAL_ARTIFACTS=${USE_LOCAL_ARTIFACTS:-0}
export VOLUME_ARGS
export RUN_ARGS


# Remove existing container instance
set +e
docker-compose -f docker-compose.yml down
docker rm -f rust_test_runner_container
set -e

set +e
docker network rm net
set -e
docker network create net

#docker-compose -f docker-compose.yml build

docker build -t rust_test_runner_container $PLATFORM_CMD .

set +e
#docker-compose -f docker-compose.yml up -d --force-recreate
set -e

# Run new test container instance
docker run --name rust_test_runner_container --network net --hostname test $VOLUME_ARGS $PLATFORM_CMD --cap-add=NET_ADMIN -t rust_test_runner_container $RUN_ARGS
