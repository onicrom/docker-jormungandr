#!/bin/bash
#
# start the requested nodes using the previously create genesis during the docker build
#
[ $# -ne 1 ] && echo "usage: $0 /path/to/data" && exit 1

dir=$1

[ ! -f ${dir}/etc/block-0.bin ] && printf "\n####\n# [ERROR] - cannot find genesis block EXITING...\n####\n\n" && exit 2

# let's make sure rust is installed and the env is setup
if [ -f ${HOME}/.cargo/env ]; then
  source ${HOME}/.cargo/env
else
  printf "\n####\n# [ERROR] - is rust properly installed?\n####\n\n"
  exit 5
fi

nodes=$(cat ${dir}/etc/number_of_nodes)

for node in `seq 1 ${nodes}`
do
  jormungandr --genesis-block ${dir}/etc/block-0.bin --config ${dir}/etc/config_node${node}.yaml --secret ${dir}/etc/key/node${node}_secret.yaml &
  sleep 5
done

# hack to keep the script in the foreground
sleep infinity
