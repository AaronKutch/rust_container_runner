#!/bin/bash

pushd /

RUST_LOG="TRACE" RUST_BACKTRACE=full /rust_container_runner/docker_assets/tcp
