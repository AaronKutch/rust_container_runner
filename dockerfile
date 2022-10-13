FROM fedora:34
RUN dnf install -y git make cmake gcc gcc-c++ which iproute iputils procps-ng vim-minimal tmux net-tools htop tar jq npm openssl-devel perl rust cargo golang
# needed for `bor`
#RUN dnf install -y musl-devel

RUN npm install ganache --global
COPY --from=sigp/lighthouse:v3.1.2 /usr/local/bin/lighthouse /usr/bin/lighthouse
COPY --from=sigp/lcli:v3.1.2 /usr/local/bin/lcli /usr/bin/lcli
#RUN git clone https://github.com/sigp/lighthouse.git
ADD https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.10.25-69568c55.tar.gz /geth/
RUN cd /geth && tar -xvf * && mv /geth/**/geth /usr/bin/geth

#COPY --from=maticnetwork/bor:v0.2.16 /usr/local/bin/bor /usr/bin/bor

#COPY --from=avaplatform/avalanchego:v1.7.11-rc.4 /avalanchego/ /avalanchego/
#RUN mv /avalanchego/build/avalanchego /usr/bin/avalanchego

#ADD https://github.com/AaronKutch/go-opera/releases/download/onomy_release_94738741/opera.tar.gz /opera/
#RUN cd /opera && tar -xvf * && mv /opera/opera /usr/bin/opera
