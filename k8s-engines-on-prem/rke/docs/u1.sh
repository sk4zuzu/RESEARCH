#!/usr/bin/env bash

: ${RECORDING:=$1}

set -o errexit -o nounset -o pipefail

if [[ "$RECORDING" != true ]]; then
    which realpath xargs dirname asciinema time make kubectl
    exec asciinema rec --overwrite $0.cast -c "$0 true"
fi

SELF=$(realpath $0 | xargs dirname) && cd $SELF/../

time make u1prereq

time make u1

sleep 30

kubectl --kubeconfig kube_config_u1.yml get nodes,pods -A

time make u1upgrade

sleep 30

kubectl --kubeconfig kube_config_u1.yml get nodes,pods -A
