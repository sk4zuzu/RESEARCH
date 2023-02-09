#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

stat /tmp/asd.0 || dd if=/dev/urandom bs=1024 count=$(( 16 * 1024 )) >/tmp/asd.0
stat /tmp/asd.1 || cat /tmp/asd.{0,0} >/tmp/asd.1
stat /tmp/asd.2 || cat /tmp/asd.{1,0} >/tmp/asd.2
stat /tmp/asd.3 || cat /tmp/asd.{2,0} >/tmp/asd.3

restic backup --compression=off /tmp/asd.0
restic backup --compression=off /tmp/asd.1
restic backup --compression=off /tmp/asd.2
restic backup --compression=off /tmp/asd.3
restic prune

ls -lha /tmp/asd.*
