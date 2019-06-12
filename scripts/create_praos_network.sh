#!/bin/bash
#
# run the facny script the iohk devs provided to do all the heavy lifting
#

[ $# -ne 1 ] && echo "usage: $0 <dir>" && exit 1

dir=$1

# let's make sure rust is installed and the env is setup
if [ -f ${HOME}/.cargo/env ]; then
  source ${HOME}/.cargo/env
else
  printf "\n####\n# [ERROR] - is rust properly installed?\n####\n\n"
  exit 5
fi

# make sure the script to create all the things exists
[ ! -f ${dir}/src/jormungandr/scripts/bootstrap ] && echo "[ERROR] - fancy iohk script missing, are you using the correct git branch?" && exit 1

cd ${dir}/etc
/bin/bash ${dir}/src/jormungandr/scripts/bootstrap

# small hacks to support the stuff required in start_network.sh
# i will fix this later...lol riiiiiiight
mkdir -p ${dir}/key
cp ${dir}/etc/poolsecret1.yaml ${dir}/etc/key/node1_secret.yaml
cp ${dir}/etc/config.yaml ${dir}/etc/config_node1.yaml 
echo 1 > ${dir}/etc/number_of_nodes

