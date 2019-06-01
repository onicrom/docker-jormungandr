#!/bin/bash
#
# creates the certs, accounts, and keys to run a node
# creates genesis config from template
# creates genesis block
# create node config(s) from template
#

[ $# -ne 3 ] && echo "usage: $0 <dir> <number-of-nodes> <number-of-wallets>" && exit 1

dir=$1
nodes=$2
accts=$3
max_nodes=9
rmnode1="ed25519_pk1yugkqlrwag93czzvp2wex4zvn8f2fucu7ga6w3au4gpjj99mxqcsek4u0q"
rmnode2="ed25519_pk156ykp5w3dkmx9r54h4v6ttj5p2wkd4mx9hc33f5hq7xfsg9m68dq6hr67n"
mkdir -p ${dir}/log ${dir}/etc/cert ${dir}/etc/key

# the docker image should have copied in files and created a dir structure
# if this file is missing something has gone horribly awry
[ ! -f ${dir}/etc/config_node1.yaml ] && printf "\n####\n# [ERROR] - missing some important template files\n####\n\n" && exit 1

# let's make sure the proper args were passed
if [ ${nodes} -ge 1 -a ${nodes} -le ${max_nodes} ]; then
  echo "[INFO] - creating a network of ${nodes} node(s)"
elif [ ${nodes} -gt ${max_nodes} ]; then
  printf "\n####\n# [ERROR] - currently this script only support ${max_nodes} and you asked for ${nodes}\n####\n\n"
  exit 2
else
  printf "\n####\n# [ERROR] - argument ${nodes} not a number\n####\n\n"
  exit 3
fi

# let's make sure the proper args were passed
if ! [[ "${accts}" =~ ^[1-9]+$ ]]; then
  printf "\n####\n# [ERROR] - argument ${accts} is either 0 or not a number\n####\n\n"
  exit 4
else
  echo "[INFO] - creating ${accts} pre-funded wallet(s)"
fi

# let's make sure rust is installed and the env is setup
if [ -f ${HOME}/.cargo/env ]; then
  source ${HOME}/.cargo/env
else
  printf "\n####\n# [ERROR] - is rust properly installed?\n####\n\n"
  exit 5
fi

# generate the genesis template file
jcli genesis init > ${dir}/etc/template_genesis.yaml
if [ -f ${dir}/etc/template_genesis.yaml ]; then 
  echo "[INFO] - created the genesis TEMPLATE file successfully"
else
 printf "\n####\n# [ERROR] - something went wrong creating the genesis template\n####\n\n"
 exit 6
fi

if ! grep -q ${rmnode1} ${dir}/etc/template_genesis.yaml; then
  printf "\n####\n# [ERROR] - template is different from expected, this branch might have made changes. EXITING...\n####\n\n"
  exit 7
fi

if ! grep -q ${rmnode2} ${dir}/etc/template_genesis.yaml; then
  printf "\n####\n# [ERROR] - template is different from expected, this branch might have made changes. EXITING...\n####\n\n"
  exit 8
fi

# removing the default template nodes
sed -e "/${rmnode1}/d" ${dir}/etc/template_genesis.yaml > ${dir}/etc/genesis.yaml
if [ $? -eq 0 ]; then
  echo "[INFO] - created genesis from template and removed rmnode1: ${rmnode1} from consensus_leader_ids array"
else
  printf "\n####\n# [ERROR] - something went wrong updating genesis consensus_leader_id array EXITING...\n####\n\n"
  exit 9
fi

sed -i "/${rmnode2}/d" ${dir}/etc/genesis.yaml
if [ $? -eq 0 ]; then
  echo "[INFO] - removed rmnode2: ${rmnode2} from consensus_leader_ids array"
else
  printf "\n####\n# [ERROR] - something went wrong updating genesis consensus_leader_id array EXITING...\n####\n\n"
  exit 10
fi

# add a config file with the number of nodes to be started in this network
# this will be used by the start nodes script to know how many instances to start
echo ${nodes} > ${dir}/etc/number_of_nodes

# create the pub and private keys for the nodes in this network
for node in `seq 1 ${nodes}`
do
  echo "[INFO] - creating pub and priv keys and secrets for node ${node}"
  jcli key generate --type=Ed25519Extended > ${dir}/etc/key/node${node}.key
  cat ${dir}/etc/key/node${node}.key | jcli key to-public > ${dir}/etc/cert/node${node}.pub

  # need these values
  node_key=$(cat ${dir}/etc/key/node${node}.key)
  node_pub=$(cat ${dir}/etc/cert/node${node}.pub)

  # building secret file from template
  sed -e "s/xNODESECRETx/${node_key}/g" ${dir}/etc/template_secret.yaml > ${dir}/etc/key/node${node}_secret.yaml
  node_keys+="    - ${node_pub}\n"

  # building node config file from template
  if [ ${node} -gt 1 ];then 
    sed -e "s/xNODEIDx/${node}/g" ${dir}/etc/template_config_node.yaml > ${dir}/etc/config_node${node}.yaml
    if [ $? -eq 0 ]; then
      echo "[INFO] - successfully create config_node${node}.yaml node config"
    else
      printf "\n####\n# [ERROR] - something went wrong creating config_node${node}.yaml EXITING...\n####\n\n"
      exit 11
    fi
  fi
done

# create some accounts that can be prefunded in genesis
for acct in `seq 1 ${accts}`
do
  echo "[INFO] - creating pub and priv keys and addrs for account ${acct}"
  jcli key generate --type=Ed25519Extended > ${dir}/etc/key/acct${acct}.key
  cat ${dir}/etc/key/acct${acct}.key | jcli key to-public > ${dir}/etc/cert/acct${acct}.pub
  jcli address account --testing `cat ${dir}/etc/cert/acct${acct}.pub` > ${dir}/etc/cert/acct${acct}.addr
  acct_addr=$(cat ${dir}/etc/cert/acct${acct}.addr)
  acct_addrs+="  - address: ${acct_addr}\n    value: 1000000000\n"
done 

# adding our node pub keys to the consensus_leader_ids array
sed -i "/consensus_leader_ids:/a \\${node_keys}" ${dir}/etc/genesis.yaml
if [ $? -eq 0 ]; then
  echo "[INFO] - updated the genesis template consensus_leader_id array with our node(s)"
else
  printf "\n####\n# [ERROR] - something went wrong updating genesis template consensus_leader_id array EXITING...\n####\n\n"
  exit 12
fi

# adding our prefunded wallets to initial_finds array
sed -i "/value: 10000/a \\${acct_addrs}" ${dir}/etc/genesis.yaml
if [ $? -eq 0 ]; then
  echo "[INFO] - updated the genesis template initial_finds array with our wallet(s)"
else
  printf "\n####\n# [ERROR] - something went wrong updating the genesis template initial_finds array EXITING...\n####\n\n"
  exit 13
fi

# creating the genesis block file
jcli genesis encode --input ${dir}/etc/genesis.yaml --output ${dir}/etc/block-0.bin
if [ $? -eq 0 ]; then
  echo "[INFO] - create the genesis block wooooooo -- ready to start the chain"
  hash=$(jcli genesis hash --input ${dir}/etc/block-0.bin)
  echo "[INFO] - the hash for this network is ${hash} - Required for connecting remote nodes"
  echo ${hash} > ${dir}/etc/block-0.bin.hash
  echo "[INFO] - hash also located in file ${dir}/etc/block-0.bin.hash"
else
  printf "\n####\n# [ERROR] - something went wrong creating the genesis block EXITING...\n####\n\n"
  exit 14
fi
