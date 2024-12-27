# Build and containerize bitcoind

This creates a tor-enabled bitcoin-core container with daemon, cli, wallet, and other utilities.

## Creating the container
The `Dockerfile` currently builds `v28.0` by default, and the container can be built via:

```podman build . -t bitcoin:v28.0```

### Building a different commit
If you want to build a different tag or commit, specify it using the `BITCOIN_TAG` build-arg:

```podman build --build-arg=BITCOIN_TAG=v28.1rc2 . -t bitcoin:v28.1rc2```

## Running the container
The container expects volumes at `/data` and `/wallets`, corresponding to your desired storage location for the bitcoin `datadir` and `walletdir`.
Note these examples use `--rm` which creates an ephemeral container (i.e., it's deleted when it exits). This does not affect the two data directories.

### Executing with terminal output (useful for debugging or running in screen/tmux)

```
podman run -it --rm --name bitcoind -v /srv/crypto/btc/data:/data -v /home/foo/.bitcoin/wallets:/wallets localhost/bitcoin:v28.0
```

This stores blockchain data in `/srv/crypto/btc/data` and wallets in `/home/foo/.bitcoin/wallets`

### Enabling RPC connections into the container
If you've enabled rpcauth in your bitcoind configuration, you can expose port 8332 when creating the container:

```
podman run -it --rm --name bitcoind -v /srv/crypto/btc/data:/data -v /home/foo/.bitcoin/wallets:/wallets -p 8332:8332/tcp localhost/bitcoin:v28.0
```

## Running bitcoin-cli
`bitcoin-cli` is included and can be executed from the running bitcoind container, for example:

```
podman exec -it bitcoind /app/bitcoin-cli listwallets
```

## Configure bitcoind to use the tor instance
Modify your `settings.json` and add the `proxy` config option, e.g.,:

```
{
    "proxy": "127.0.0.1:9050",
    "server": true
}
