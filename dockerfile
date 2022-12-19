FROM fedora:34
RUN dnf install -y git make cmake gcc gcc-c++ which iproute iputils procps-ng vim-minimal tmux net-tools htop tar jq npm openssl-devel perl rust cargo golang

# only required for deployment script
RUN npm install -g ts-node && npm install -g typescript
# for ethers-rs based runtime
RUN npm install -g solc

# ADD https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.10.26-e5eb32ac.tar.gz /geth/
# RUN cd /geth && tar -xvf * && mv /geth/**/geth /usr/bin/geth

COPY --from=avaplatform/avalanchego:v1.9.4 /avalanchego/ /avalanchego/
RUN mv /avalanchego/build/avalanchego /usr/bin/avalanchego

#ADD https://github.com/AaronKutch/go-opera/releases/download/onomy_release_94738741/opera.tar.gz /opera/
#RUN cd /opera && tar -xvf * && mv /opera/opera /usr/bin/opera
