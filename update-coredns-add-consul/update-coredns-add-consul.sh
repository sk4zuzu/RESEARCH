#!/usr/bin/env bash

# Please note this script is *idempotent* and based on >> https://www.consul.io/docs/k8s/dns <<.

: "${DRY_RUN:=client}" # set it to "none" if you want to really update
: "${CONSUL_NS:=external-apigw}"
: "${COREDNS_NS:=kube-system}"

set -o errexit -o nounset -o pipefail

which date diff jq kubectl printf sed

CONSUL_DNS_SVC_CLUSTER_IP=$(kubectl -n "$CONSUL_NS" get svc/consul-dns -o jsonpath='{.spec.clusterIP}')

COREDNS_CM_JSON=$(kubectl -n "$COREDNS_NS" get configmap/coredns -o json)

COREFILE_CFG=$(jq -r '.data.Corefile' <<< "$COREDNS_CM_JSON")

COREFILE_CFG_WITHOUT_CONSUL=$(sed -e '/^consul[^{]*[{]/,/^[}]/d' <<< "$COREFILE_CFG")

CONSUL_CFG=$(sed -ne '/^consul[^{]*[{]/,/^[}]/p' <<< "$COREFILE_CFG")

NEW_CONSUL_CFG="\
consul {
  errors
  cache 30
  forward . $CONSUL_DNS_SVC_CLUSTER_IP
}"

if diff -u <(echo "$CONSUL_CFG") <(echo "$NEW_CONSUL_CFG"); then
    echo consul {..} blocks are identical, nothing to update, skipping..
    exit 0
fi

echo "$COREDNS_CM_JSON" > "./$(date +'%Y%m%d-%H%M%S')-backup-coredns-cm.json"

NEW_COREFILE_CFG=$(printf "%s\n%s\n" "$NEW_CONSUL_CFG" "$COREFILE_CFG_WITHOUT_CONSUL")

NEW_COREDNS_CM_JSON=$(jq -r --arg new_corefile_cfg "$NEW_COREFILE_CFG" '.data.Corefile = $new_corefile_cfg' <<< "$COREDNS_CM_JSON")

kubectl -n "$COREDNS_NS" replace configmap/coredns --dry-run="$DRY_RUN" -f- <<< "$NEW_COREDNS_CM_JSON"
