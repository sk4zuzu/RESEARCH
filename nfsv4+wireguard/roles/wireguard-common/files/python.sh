#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail
set -x

apt-get update -y && apt-get install -y python3 && exit 0

# vim:ts=4:sw=4:et:syn=sh:
