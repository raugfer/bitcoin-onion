FROM ubuntu:22.04 AS builder
RUN apt-get update && apt-get upgrade -y && apt-get install -y autoconf g++ git golang libboost-dev libevent-dev liblz4-dev libsnappy-dev libssl-dev libtool libzmq3-dev libzstd-dev make pkg-config wget zlib1g-dev && apt-get clean
RUN git clone https://gitlab.torproject.org/tpo/core/tor.git /opt/tor/ && cd /opt/tor/ && git checkout '680415826c5fd7862e65eeeefe0d98b905714f83'
RUN git clone https://github.com/bitcoin/bitcoin.git /opt/bitcoin/ && cd /opt/bitcoin/ && git checkout '44d8b13c81e5276eb610c99f227a4d090cc532f6'
RUN git clone https://github.com/facebook/rocksdb.git /opt/rocksdb/ && cd /opt/rocksdb/ && git checkout '59495ff26a410eab30dab4f76b76ec5ba4ad293b'
RUN git clone https://github.com/trezor/blockbook.git /opt/blockbook/ && cd /opt/blockbook/ && git checkout 'f4d06ab08d2e883ac63bc4a62de65a8afb5b51c5'
RUN cd /opt/tor/ && ./autogen.sh && ./configure --disable-asciidoc --disable-unittests && make && make install
RUN cd /opt/bitcoin/ && ./autogen.sh && ./configure CXXFLAGS='-O2' CFLAGS='-O2' --disable-wallet --disable-bench --disable-tests --disable-fuzz-binary --without-gui --without-natpmp --without-miniupnpc --without-utils --without-libs --enable-reduce-exports && make && make install
RUN cd /opt/rocksdb/ && make release
RUN cd /opt/blockbook/ && CGO_CFLAGS='-I/opt/rocksdb/include/' CGO_LDFLAGS='-L/opt/rocksdb/' go build -o /usr/bin/blockbook -ldflags='-s -w -X github.com/trezor/blockbook/common.version=0.4.0 -X github.com/trezor/blockbook/common.gitcommit=f4d06ab -X github.com/trezor/blockbook/common.buildtime=2023-12-05T10:58:21+00:00'

FROM ubuntu:22.04
RUN apt-get update && apt-get upgrade -y && apt-get install -y libevent-dev libsnappy1v5 libzmq5 supervisor && apt-get clean
COPY --from=builder /usr/local/bin/tor /usr/bin/tor
COPY --from=builder /usr/local/bin/bitcoind /usr/bin/bitcoind
COPY --from=builder /usr/bin/blockbook /usr/bin/blockbook
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY torrc /etc/tor/torrc
COPY bitcoin.conf /etc/bitcoin/bitcoin.conf
COPY blockchaincfg.json /etc/blockbook/blockchaincfg.json
COPY testnet3/supervisord.conf /etc/supervisor/conf.d/testnet3/supervisord.conf
COPY testnet3/torrc /etc/tor/testnet3/torrc
COPY testnet3/bitcoin.conf /etc/bitcoin/testnet3/bitcoin.conf
COPY testnet3/blockchaincfg.json /etc/blockbook/testnet3/blockchaincfg.json
RUN useradd -U -m ubuntu
USER ubuntu
WORKDIR /home/ubuntu/
COPY --from=builder --chown=ubuntu:ubuntu /opt/blockbook/static/ /home/ubuntu/static/
COPY base.html /home/ubuntu/static/templates/
COPY index.html /home/ubuntu/static/templates/
RUN rm /home/ubuntu/static/favicon.ico
ENV TESTNET=
ENTRYPOINT supervisord -c /etc/supervisor/conf.d${TESTNET:+/testnet3}/supervisord.conf
