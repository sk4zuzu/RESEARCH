#!/usr/bin/env bash

: "${DISK:=$1}"
: "${NBDX:=7}"

set -o errexit -o nounset -o pipefail

if [[ -n "$DISK" ]]; then
    install -d "./nbd${NBDX}p1/"
    qemu-nbd --connect "/dev/nbd$NBDX" "$DISK"
    partprobe
    mount "/dev/nbd${NBDX}p1" "./nbd${NBDX}p1/"
else
    umount "./nbd${NBDX}p1/" ||:
    qemu-nbd --disconnect "/dev/nbd$NBDX"
    partprobe
fi
