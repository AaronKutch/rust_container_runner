FROM fedora:34
RUN dnf install -y git make gcc gcc-c++ which iproute iputils procps-ng vim-minimal tmux net-tools htop tar jq npm openssl-devel perl rust cargo golang
# needed for `bor`
#RUN dnf install -y musl-devel

#ADD https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.10.10-bb74230f.tar.gz /geth/
#RUN cd /geth && tar -xvf * && mv /geth/**/geth /usr/bin/geth

#COPY --from=maticnetwork/bor:v0.2.16 /usr/local/bin/bor /usr/bin/bor

#COPY --from=avaplatform/avalanchego:v1.7.11-rc.4 /avalanchego/ /avalanchego/
#RUN mv /avalanchego/build/avalanchego /usr/bin/avalanchego

#ADD https://github.com/AaronKutch/go-opera/releases/download/onomy_release_94738741/opera.tar.gz /opera/
#RUN cd /opera && tar -xvf * && mv /opera/opera /usr/bin/opera
