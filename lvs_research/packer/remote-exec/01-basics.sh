#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail
set -x

apk --no-cache add \
    bash bat \
    curl \
    e2fsprogs-extra \
    fd \
    gawk \
    gzip \
    htop \
    iftop iproute2 iptables ipvsadm \
    jq \
    mc \
    nethogs nmap nmap-ncat \
    openssh-client \
    pv python3 \
    ripgrep \
    sudo \
    tar tcpdump tmux \
    vim \
    xfsprogs-extra \
    zip \
    zstd

sync
