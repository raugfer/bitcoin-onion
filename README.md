# Bitcoin Onion

This repository provides the setup needed to run a Bitcoin block explorer on
the Tor network, with minimal effort.

## Usage

First, make sure you have [Docker installed](https://github.com/raugfer/bitcoin-onion#prerequisite).

Clone this repository and enter its folder:

    $ git clone https://github.com/raugfer/bitcoin-onion && cd bitcoin-onion

To initiate the block explorer, use the following command:

    $ ./bitcoin-start --daemon

To terminate the block explorer, gracefully, use the following command:

    $ ./bitcoin-stop

To retrieve the block explorer .onion address, use the following command:

    $ cat datadir/onion/hostname

Be aware that, at first run, it needs to download and build the software. This
may take several minutes.

One can then access the block explorer by accessing this .onion address via a
web browser that supports Tor, such as the [Brave Browser](https://brave.com).

Be patient, it may take several hours before the service is fully synchronized
with the Bitcoin network. You will also need to have enough disk space to store
the full blockchain and its indexed database (1.3TB as of December/2023).

## Overview

This is a Docker image furnished with a couple of scripts to start and stop it.

The image is composed of 3 components: the Bitcoin full node (Bitcoin Core),
the Bitcoin block explorer front-end (Blockbook), and the Tor network
proxy (Tor).

| Component                                                        | Version                                                                                                                     |
| ---------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| [Bitcoin Core](https://bitcoincore.org/)                         | [26.0](https://bitcoincore.org/bin/bitcoin-core-26.0/bitcoin-26.0-x86_64-linux-gnu.tar.gz)                                  |
| [Blockbook](https://trezor.io/learn/a/trezor-blockbook-explorer) | [Commit f4d06ab](https://github.com/trezor/blockbook/commit/f4d06ab)                                                        |
| [Tor](https://www.torproject.org/)                               | [13.0.7](https://archive.torproject.org/tor-package-archive/torbrowser/13.0.7/tor-expert-bundle-linux-x86_64-13.0.7.tar.gz) |

Both the full node and the block explorer run as Tor hidden services (.onion
top-level domain). The setup is intended to force all network traffic
via a Tor proxy, including blockchain synchronization.

DNS query for seed nodes is disabled. To bootstrap peers, it relies solely
on hard-coded .onion addresses provided by bitcoind.

The hidden service configuration for the full node resides inside the Docker
container, its .onion address is lost/refreshed on every start/stop cycle.
The hidden service configuration for the block explorer is stored in the
host's data folder, its .onion address is kept across runs.

During execution, the full node becomes available as a peer on the Bitcoin
network, but it does not expose REST/RPC services. On the other hand, the block
explorer exposes its web front and [REST API](https://github.com/trezor/blockbook/blob/master/docs/api.md).
From the point of view of an outsider, they are different and unrelated nodes
in the Tor network.

As the full node is used solely as back-end for the block explorer, its wallet
functionality is disabled.

## Prerequisite

In order to run the application, it is necessary to
[install the Docker engine](https://docs.docker.com/engine/install/)
on the host machine. On Debian-based systems, it suffices to install the
default distribution version by running:

    $ sudo apt-get install -y docker.io

It also makes sense to set up the Docker engine to
[start on boot](https://docker-docs.uclv.cu/engine/install/linux-postinstall/#configure-docker-to-start-on-boot).
On systems using `systemd` that can be achieved by running:

    $ sudo systemctl enable docker

Finally, if you intend to [run docker on a non-root account](https://docker-docs.uclv.cu/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user),
please add the account to the docker group by running:

    $ sudo usermod -aG docker $USER

You may need to log out and log back in to your session for this last change
to take effect.

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

_(Tested with Docker 24.0.7 on Ubuntu 22.04)_
