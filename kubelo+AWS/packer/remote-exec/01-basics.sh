#!/usr/bin/env bash

policy_rc_d_disable() (echo "exit 101" >/usr/sbin/policy-rc.d && chmod a+x /usr/sbin/policy-rc.d)
policy_rc_d_enable()  (echo "exit 0"   >/usr/sbin/policy-rc.d && chmod a+x /usr/sbin/policy-rc.d)

export DEBIAN_FRONTEND=noninteractive

set -o errexit -o nounset -o pipefail
set -x

apt-get -q update -y

policy_rc_d_disable

apt-get -q remove -y --purge \
    unattended-upgrades

apt-get -q upgrade -y

apt-get -q install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

apt-get -q install -y --no-install-recommends \
    pv \
    vim mc htop \
    net-tools iproute2 netcat nmap \
    iftop nethogs \
    jq

apt-get -q install -y --no-install-recommends \
    haproxy

apt-get -q install -y \
    python3 \
    python3-pip

policy_rc_d_enable

apt-get -q clean

pip3 --no-cache-dir install \
    azure-cli \
    openshift \
    pyyaml

sync

# vim:ts=4:sw=4:et:syn=sh:
