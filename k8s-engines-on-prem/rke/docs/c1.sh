#!/usr/bin/env bash

: ${RECORDING:=$1}

set -o errexit -o nounset -o pipefail

if [[ "$RECORDING" != true ]]; then
    which realpath xargs dirname asciinema time make kubectl
    exec asciinema rec --overwrite $0.cast -c "$0 true"
fi

SELF=$(realpath $0 | xargs dirname) && cd $SELF/../

time make c1prereq

time make c1

sleep 30

kubectl --kubeconfig kube_config_c1.yml get nodes,pods -A

time make c1upgrade

sleep 30

kubectl --kubeconfig kube_config_c1.yml get nodes,pods -A
