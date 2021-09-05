#!/usr/bin/env bash

if [[ "$UID" != 0 ]]; then
    exec sudo "$0" "$@"
fi

set -o errexit -o nounset -o pipefail

which install mount mountpoint

set -x

install -d /etc/cni/net.d/ /opt/cni/bin/

if ! mountpoint -q /etc/cni/net.d/; then
    mount --bind /var/lib/rancher/k3s/agent/etc/cni/net.d/ /etc/cni/net.d/
fi

if ! mountpoint -q /opt/cni/bin/; then
    mount --bind /var/lib/rancher/k3s/data/current/bin/ /opt/cni/bin/
fi
