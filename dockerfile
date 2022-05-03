FROM fedora:34
RUN dnf install -y git make gcc gcc-c++ which iproute iputils procps-ng vim-minimal tmux net-tools htop tar jq npm openssl-devel perl rust cargo golang

#ADD https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.10.10-bb74230f.tar.gz /geth/
#RUN cd /geth && tar -xvf * && mv /geth/**/geth /usr/bin/geth

# Use COPY from an image to take advantage of caching
#COPY --from=avaplatform/avalanchego:v1.7.11-rc.0 /avalanchego/ /avalanchego/
