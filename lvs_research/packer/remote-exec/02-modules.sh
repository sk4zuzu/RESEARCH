#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail
set -x

cat >/etc/modules-load.d/tun.conf <<EOF
tun
EOF

sync
