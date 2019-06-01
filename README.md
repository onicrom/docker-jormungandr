# docker-jormungandr

Dockerfile and some scripts to build a container to run a one or multiple jormungandr (https://github.com/input-output-hk/jormungandr) node cluster.

## Instructions

How to build

```bash
git clone https://github.com/onicrom/docker-jormungandr.git
cd docker-jormungandr
docker build -t a-fun-name:0.1 .
```

How to run

```bash
docker run --name woo a-fun-name:0.1
```

## Options

The default build options are:
- jormungandr branch: master
- number of nodes: 1
- number of pre-funded wallets: 1

These can be overridden during the docker build process:
```bash
docker build -t a-fun-name:0.1 \
  --build-arg NODES=3 \
  --build-arg ACCTS=3 \
  --build-arg BRANCH=awesome-new-branch .
  ```

## What's going on under the hood?

A couple template files are pushed into the container so that we can easily build the configuration files needed to start the jormungandr node(s)
- config_node1.yaml: generic single node config
- template_config_node.yaml: a template node config for any other nodes
- template_secret.yaml: a template secrets file

A couple of scripts are pushed into the container
- create_network.sh
- start_network.sh

### create_network.sh

This script does the following:
- creates the requested ($NODES at build) number of node public and private keys
- creates the node_secret.yaml using a template, adding the node's private key
- creates the config_node.yaml using a template, updating the nodeID and tcp port
- creates the requested ($ACCTS at build) number of accounts (pub/prv keys etc..) to be pre-funded in the genesis block
- generates a genesis yaml config file template
  - removes default *consensus_leader_ids* pub keys from the config
  - adds the requested number of node pub keys to the *consensus_leader_ids* array
  - adds the the requested number of addresses to the *initial_finds* array
- creates the genesis block


### start_network.sh

This script is the ENTRYPOINT for the container.  It runs a for loop, starting each of the requested nodes in the background, sending logs to stdout
