FROM fedora:34
RUN dnf install -y git make gcc gcc-c++ which iproute iputils procps-ng vim-minimal tmux net-tools htop tar jq npm openssl-devel perl rust cargo golang

# Use COPY from an image to take advantage of caching
COPY --from=avaplatform/avalanchego:v1.7.11-rc.0 /avalanchego/ /avalanchego/

ENV PATH=$PATH:/rust_container_runner/docker_assets
