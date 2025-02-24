###################
# Build container #
###################

FROM ubuntu:24.04 as build

ARG BITCOIN_TAG=v28.0

WORKDIR /src
RUN apt update && apt install -y git build-essential pkg-config autoconf libtool python3 libevent-dev libboost-dev libsqlite3-dev libzmq3-dev systemtap-sdt-dev
RUN git clone -b ${BITCOIN_TAG} https://github.com/bitcoin/bitcoin.git .
RUN ./autogen.sh && ./configure --disable-tests --disable-bench --disable-gui-tests --disable-man --disable-debug --disable-fuzz-binary --disable-shared
RUN make -j24
RUN strip src/bitcoind src/bitcoin-cli src/bitcoin-tx src/bitcoin-util src/bitcoin-wallet

# Unpack s6 into the build container, which will then
# be copied to the runtime container.
RUN mkdir /s6
ARG S6_OVERLAY_VERSION=3.2.0.2
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C /s6 -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C /s6 -Jxpf /tmp/s6-overlay-x86_64.tar.xz


############################
# Create runtime container #
############################

FROM ubuntu:24.04

# install tor and library dependencies for bitcoin
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y tor libevent-2.1-7t64 libevent-core-2.1-7t64 libevent-extra-2.1-7t64 libevent-pthreads-2.1-7t64 libsqlite3-0 libzmq5 xz-utils && apt clean

# s6overlay
COPY --from=build /s6/ /

# tor service files
COPY ./s6/ /etc/s6-overlay/s6-rc.d/

# bitcoin.conf defaults
COPY ./config/ /root/.bitcoin/

WORKDIR /app
COPY --from=build /src/src/bitcoind /app/bitcoind
COPY --from=build /src/src/bitcoin-cli /app/bitcoin-cli
COPY --from=build /src/src/bitcoin-tx /app/bitcoin-tx
COPY --from=build /src/src/bitcoin-util /app/bitcoin-util
COPY --from=build /src/src/bitcoin-wallet /app/bitcoin-wallet

EXPOSE 8332

VOLUME /data
VOLUME /wallets
CMD ["/app/bitcoind", "-datadir=/data", "-walletdir=/wallets"]
ENTRYPOINT ["/init"]
