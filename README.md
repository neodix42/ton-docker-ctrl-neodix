# ton-docker-ctrl

Tested operating systems:
* Ubuntu 20.04
* Ubuntu 22.04
* Ubuntu 24.04
* Debian 11
* Debian 12

## Prerequisites
To run, you need docker-ce, docker-buildx-plugin:

* [Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)

Build environment variables are configured in the `.env `file:

* **TON_BRANCH** - when building this image you can specify which TON branch binaries will be based on. Actually it is a TAG name of TON Docker image, but it coincides with the branch name (default: **latest**, i.e. master branch)
* **GLOBAL_CONFIG_URL** - URL of the TON blockchain configuration (default: [Mainnet](https://ton.org/global.config.json))
* **MYTONCTRL_VERSION** - MyTonCtrl build branch (default **master**)
* **TELEMETRY** - Enable/Disable telemetry (default **true**)
* **IGNORE_MINIMAL_REQS** - Ignore hardware requirements (default **false**)
* **MODE** - Install MyTonCtrl with specified mode (validator or liteserver, default **validator**)
* **DUMP** - Use pre-packaged dump. Reduces duration of initial synchronization, but it takes time to download the dump. You can view the download status in the logs `docker compose logs -f`. (default **false**)
* **ARCHIVE_TTL** - Archive time-to-live in seconds for the validator (default **86400**)
* **STATE_TTL** - State time-to-live in seconds for the validator (default **86400**)
* **VERBOSITY** - Verbosity level for the validator engine (default **1**)
* **PUBLIC_IP** - Used when automatic detection of external IP does not work, e.g. in Kubernetes.
* **VALIDATOR_PORT** - Set custom validator UDP port (default **random**)
* **LITESERVER_PORT** - Set custom lite-server TCP port (default **random**)
* **VALIDATOR_CONSOLE_PORT** - Set custom validator-console TCP port (default **random**)

## Run TON node with MyTonCtrl v2

This is the simplest and the quickest way to set up and start the TON validator.
It will use a historical dump of data to speed up the initial sync process.
It will not start validation unless you top up the wallet.
This command will create two docker volumes `ton-work` and `mytoncore`. The first one will contain the blockchain data, and the second - MyTonCtrl settings and most importantly, wallets' data.
Real paths of these volumes can be found using `docker volume inspect <volume-name>` command.

We recommend changing default Docker volumes' location, since the blockchain's data can grow rapidly, 
and TON validator requires fast disks.

Also, make sure you backed up your wallet data, that can be found in `<mytoncore-volume-path>/wallets`

Download `docker-compose.yml` and `.env` files:
```bash
wget https://raw.githubusercontent.com/neodix42/ton-docker-ctrl-neodix/refs/heads/main/.env
wget https://raw.githubusercontent.com/neodix42/ton-docker-ctrl-neodix/refs/heads/main/docker-compose.yml
```
Adjust `.env` as per your needs and start the container:

To run **TESTNET** fullnode or validator change this
```bash
TON_BRANCH=testnet
GLOBAL_CONFIG_URL=https://ton.org/testnet-global.config.json
```

Now you are ready to start the container
```bash
docker compose up
```

* Watch logs: `docker logs ton-node`
* Use MyTonCtrl, go inside the container `docker exec -ti ton-node bash` and type `mytonctrl`.

## Run TON Archive node with MyTonCtrl v2

Download `docker-compose-archive.yml` and `.env` files:

```bash
wget https://raw.githubusercontent.com/neodix42/ton-docker-ctrl-neodix/refs/heads/main/.env
wget -O docker-compose.yml https://raw.githubusercontent.com/neodix42/ton-docker-ctrl-neodix/refs/heads/main/docker-compose-archive.yml
```

Edit volume creation parameters so they will point to your external storage:
```bash
volumes:
  ton:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /path/to/ton_data
  mytoncore:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /path/to/mtc_data 
```

Start archive fullnode:
```bash
docker compose up
```

## Build a Docker image from sources and run MyTonCtrl v2:

```bash
git clone https://github.com/ton-blockchain/ton-docker-ctrl.git && cd ./ton-docker-ctrl
// adjust `.env` as per your needs 
docker compose -f docker-compose.build.yml build
```

Start the container `docker exec -ti ton-node bash`

## Upgrade MyTonCtrl docker image from repository:
* Pull docker image: `docker pull docker pull ghcr.io/ton-blockchain/ton-docker-ctrl:latest`

## Migrate non-Docker fullnode or validator to a dockerized MyTonCtrl v2

Specify paths to TON binaries and sources, as well as to TON work directory, but most importantly to MyTonCtrl settings and wallets.

```bash
docker run -d --name ton-node --restart always \
-v /mnt/data/ton-work:/var/ton-work \
-v /usr/bin/ton:/usr/bin/ton \
-v /usr/src/ton:/usr/src/ton \
-v /home/<USER>/.local/share:/usr/local/bin \
ghcr.io/ton-blockchain/ton-docker-ctrl:latest
```

Read the logs
```bash
docker logs ton-node
```

Get inside the container and run MyTonCtrl
```bash
docker exec -ti ton-node bash
```

Start the container skipping original entrypoint execution
```bash
docker run -it --entrypoint=bash ghcr.io/ton-blockchain/ton-docker-ctrl:latest
```

Volume inspection
```bash

docker volume ls
docker volume inspect ton-work
docker volume inspect mytoncore
```

Uninstall the TON node

```bash
docker stop ton-node
docker rm ton-node
docker volume rm mytoncore ton-work
```