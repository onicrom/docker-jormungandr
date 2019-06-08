#!/bin/bash
#
# wrapper script to create either a bft or praos network
#

[ $# -ne 4 ] && echo "usage: $0 <bft|praos> <dir> <number-of-nodes> <number-of-wallets>" && exit 1

mode=$1
dir=$2
nodes=$3
accts=$4

do_error() {
  echo "[ERROR] - this script only supports bft or praos, not mode: ${mode}"
  exit 1
}

do_bft() {
  /bin/bash ${dir}/bin/create_bft_network.sh ${dir} ${nodes} ${accts}
  ec=$?
}

do_praos() {
  [ ${nodes} -gt 1 ] && echo "[WARN] - ${mode} only supports 1 node at this time, ignoring nodes arg ${nodes}"
  /bin/bash ${dir}/bin/create_praos_network.sh ${dir}
  ec=$?
}

case ${mode} in
  bft)
        do_bft
	;;
  praos)
	do_praos
	;;
  *)    
	do_error
	;;
esac

if [ ${ec} -eq 0 ]; then
  echo "[INFO] - mode: ${mode} -- creating node(s), account(s), certs, genesis, and block0"
else
  echo "[ERROR] - failed to create the network -- something went wrong with create_${mode}_network.sh"
  exit 1
fi
