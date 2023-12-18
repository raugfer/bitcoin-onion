# Bitcoin Onion

This repository provides the setup needed for running a Bitcoin block explorer
on the Tor network, with minimal effort.

## Overview

This is a Docker image furnished with a couple of scripts to start and stop it.

The image is composed of 3 components: the Bitcoin full node (Bitcoin Core),
the Bitcoin block explorer front-end (Blockbook), and the Tor network
proxy (Tor).

| Component                                                        | Version                                                                                                                     |
| ---------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| [Bitcoin Core](https://bitcoincore.org/)                         | [25.1](https://bitcoincore.org/bin/bitcoin-core-25.1/bitcoin-25.1-x86_64-linux-gnu.tar.gz)                                  |
| [Blockbook](https://trezor.io/learn/a/trezor-blockbook-explorer) | [Commit f4d06ab](https://github.com/trezor/blockbook.git)                                                                   |
| [Tor](https://www.torproject.org/)                               | [13.0.6](https://archive.torproject.org/tor-package-archive/torbrowser/13.0.6/tor-expert-bundle-linux-x86_64-13.0.6.tar.gz) |

Both the full node and the block explorer run as Tor hidden services (.onion
top-level domain). The setup is intended to force all network traffic
via a Tor proxy, including blockchain synchronization.

To avoid clearnet traffic, DNS query for seed nodes is disabled. To bootstrap
peers it relies solely on hardcoded .onion addresses provided by bitcoind.

The hidden services configuration for the full node resides inside the Docker
container, its .onion address is lost/refreshed on every start/stop cycle.
The hidden services configuration for the block explorer is stored in the
host's data folder, its .onion address is kept accross runs.

During execution, the full node becomes available as a peer on the Bitcoin
network, but it does expose REST/RPC services. On the other hand, the block
explorer exposes its web front-end and REST API. From the point of view of
an outsider, they are different and unrelated nodes in the Tor network.

## Prerequisite

In order to run the application it is necessary to
[install the Docker engine](https://docs.docker.com/engine/install/)
on the host machine. On Debian-based systems it suffices to install the
default distribution version by running:

    $ sudo apt-get install -y docker.io

It also makes sense to setup the Docker engine to
[start on boot](https://docker-docs.uclv.cu/engine/install/linux-postinstall/#configure-docker-to-start-on-boot).
On systems using the systemd that can be achieved by running:

    $ sudo systemctl enable docker

Finally, if you intend to [run docker on a non-root account](https://docker-docs.uclv.cu/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user),
please add the account to the docker group by running (you may need to log out
and log back into your session for this change to take effect):

    $ sudo usermod -aG docker $USER

## Usage

To initiate the block explorer, use the following command:

    $ ./bitcoin-start --daemon

To terminate the block explorer, gracefully, use the following command:

    $ ./bitcoin-stop

To retrieve the block explorer .onion address, use the following command:

    $ cat datadir/onion/hostname

## Storage

The application data, including the full Bitcoin blockchain, is stored
under the host's `datadir` folder. It has 3 subfolders:

- `datadir/bitcoin`: holds the full node state and database files
- `datadir/blockbook`: holds the block explorer database files
- `datadir/onion`: holds the block explorer hidden service configuration

The `datadir/onion` folder contains the hidden service private key which
prescribes its .onion address. It may be a good idea to back it up and take
security measures to keep it secret.

The other two folders contain public data that can be safely recreated from the
blockchain via synchronization.

_(Docker 24.0.7 on Ubuntu 22.04)_
