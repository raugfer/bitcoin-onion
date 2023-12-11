FROM ubuntu:22.04 AS builder
RUN apt-get update && apt-get upgrade -y && apt-get install -y g++ git liblz4-dev libsnappy-dev libzmq3-dev libzstd-dev make pkg-config wget zlib1g-dev && apt-get clean
RUN git clone -b 'v7.7.2' --depth 1 https://github.com/facebook/rocksdb.git /opt/rocksdb/
RUN cd /opt/rocksdb/ && make release
RUN wget -O- 'https://dl.google.com/go/go1.21.4.linux-amd64.tar.gz' | tar xz -C /opt/ && ln -s /opt/go/bin/go /usr/bin/go
RUN git clone https://github.com/trezor/blockbook.git /opt/blockbook/ && cd /opt/blockbook/ && git checkout f4d06ab
RUN cd /opt/blockbook/ && CGO_CFLAGS='-I/opt/rocksdb/include/' CGO_LDFLAGS='-L/opt/rocksdb/' go build -o /usr/bin/blockbook -ldflags='-s -w -X github.com/trezor/blockbook/common.version=0.4.0 -X github.com/trezor/blockbook/common.gitcommit=f4d06ab -X github.com/trezor/blockbook/common.buildtime=2023-12-05T10:58:21+00:00'

FROM ubuntu:22.04
RUN apt-get update && apt-get upgrade -y && apt-get install -y libsnappy1v5 libzmq5 wget && apt-get clean
RUN wget -O- 'https://bitcoincore.org/bin/bitcoin-core-25.1/bitcoin-25.1-x86_64-linux-gnu.tar.gz' | tar xz -C /usr/bin/ 'bitcoin-25.1/bin/bitcoind' --strip-components=2
RUN wget -O- 'https://archive.torproject.org/tor-package-archive/torbrowser/13.0.6/tor-expert-bundle-linux-x86_64-13.0.6.tar.gz' | tar xz -C /usr/bin/ 'tor/tor' 'tor/libevent-2.1.so.7' --strip-components=1 && mv /usr/bin/libevent-2.1.so.7 /usr/lib/ && chmod 755 /usr/bin/tor /usr/lib/libevent-2.1.so.7
COPY --from=builder /usr/bin/blockbook /usr/bin/blockbook
COPY bitcoin.conf /etc/bitcoin/bitcoin.conf
COPY torrc-bitcoin /etc/tor/torrc
COPY torrc-tbitcoin /etc/tor/testnet3/torrc
COPY blockchaincfg-bitcoin.json /etc/blockbook/blockchaincfg.json
COPY blockchaincfg-tbitcoin.json /etc/blockbook/testnet3/blockchaincfg.json
RUN useradd -U -m ubuntu
USER ubuntu
WORKDIR /home/ubuntu/
COPY --from=builder /opt/blockbook/static/ /home/ubuntu/static/
ENV TESTNET=
ENTRYPOINT \
	tor -f /etc/tor${TESTNET:+/testnet3}/torrc & \
	bitcoind -conf=/etc/bitcoin/bitcoin.conf -nodebuglogfile ${TESTNET:+-testnet} & \
	blockbook -blockchaincfg=/etc/blockbook${TESTNET:+/testnet3}/blockchaincfg.json -datadir=/home/ubuntu/datadir/blockbook${TESTNET:+/testnet3}/ -enablesubnewtx -extendedindex -logtostderr -public=127.0.0.1:${TESTNET:+1}9130 -sync & \
	wait
