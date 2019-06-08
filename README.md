# docker-jormungandr

Dockerfile and some scripts to create a container, compile/install [jormungandr](https://github.com/input-output-hk/jormungandr), and run one or multiple node(s).

## Disclaimer:
FYI This is alpha code (jormungandr) and NOT ready for an actual public testnet.  
Please don't consider this as any official announcement/post.  
I'm just some keyboard cowboy community member who got bored one night.  


## Instructions

### How to build

The build process creates all the artifacts required to run the node.  If you want to change parameters of the network; praos to bft, bft nodes from 1 to 3, you will need to re-build the container.

```bash
git clone https://github.com/onicrom/docker-jormungandr.git
cd docker-jormungandr
docker build -t a-fun-name:0.1 .
```

#### Options

The default build options are:
- mode: bft (supports bft or praos)
- jormungandr branch: master
- number of nodes: 1
- number of pre-funded wallets: 1

These can be overridden during the docker build process:
```bash
docker build -t a-fun-name:0.2 \
  --build-arg MODE=praos \
  --build-arg NODES=3 \
  --build-arg ACCTS=3 \
  --build-arg BRANCH=awesome-new-branch .
  ```
  
### How to run

```bash
docker run --name woo a-fun-name:0.1
```

If you plan on connecting to the rpc/rest ports of your container, outside of your container, you will need to pass the appropriate -p PORT:PORT arguments to your ```docker run ...``` command

```
# expose the rest ports
EXPOSE 4431-4439
# export the node ports
EXPOSE 8291-8299
EXPOSE 8443
```

## Limitations

- bft mode is limited to 9 nodes because I didn't want to test more
- praos mode is limited to 1 node because I have not tested running multiple nodes yet

## What's going on under the hood?

A couple template files are pushed into the container to build configuration files:
- config_node1.yaml: generic single node config
- template_config_node.yaml: a template node config for any other nodes
- template_secret.yaml: a template secrets file

A couple of scripts are pushed into the container:
- create_network.sh -- wrapper script which executes one of the below based on MODE
  - create_bft_network.sh
  - create_praos_network.sh
- start_network.sh

### create_bft_network.sh

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

### create_praos_networks.sh

This script creates the node, account, certs, genesis, and block0 files by executing the helper script provided by the jormungandr repo -- 
[stakepool-single-node-test](https://github.com/input-output-hk/jormungandr/blob/master/scripts/stakepool-single-node-test)

### start_network.sh

This script is the ENTRYPOINT for the container.  It runs a for loop, starting each of the requested nodes in the background, sending logs to stdout.

 
 
## Lovelave Community Pool 
Help support the [Lovelace Community Pool](https://lovelace.community) - a no fee staking pool run by and for the community

If this was useful and you can/want to support us, our ADA donation address is:
Ae2tdPwUPEYw3rz8KGHbnTusd9QWQ8ePhogEWkm1agugTtW51skA59DrKe8 
