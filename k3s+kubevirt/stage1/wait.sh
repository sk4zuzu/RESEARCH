#!/usr/bin/env bash

set -o errexit

eval "$(jq -r '@sh "KC_BIN=\(.kc_bin)"')"

for RETRY in 9 8 7 6 5 4 3 2 1 0; do
    true && $KC_BIN -n kubevirt wait --for condition=ready pod --timeout=10s -l kubevirt.io=virt-api \
         && $KC_BIN -n kubevirt wait --for condition=ready pod --timeout=10s -l kubevirt.io=virt-controller \
         && $KC_BIN -n kubevirt wait --for condition=ready pod --timeout=10s -l kubevirt.io=virt-handler \
         && break
    sleep 30
done >/dev/null 2>&1 && [[ $RETRY -gt 0 ]]

echo '{}'
