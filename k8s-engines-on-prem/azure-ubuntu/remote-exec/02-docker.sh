#!/usr/bin/env bash

if [[ "${UID}" != 0 ]]; then
    exec sudo "$0" "$@"
fi

: ${DOCKER_CE_VERSION_APT:=5:19.03.13~3-0~ubuntu-bionic}
: ${CONTAINERD_IO_VERSION_APT:=1.3.7-1}
: ${DOCKER_COMPOSE_VERSION:=1.27.4}

export DEBIAN_FRONTEND=noninteractive

set -o errexit -o nounset -o pipefail
set -x

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

apt-get -q update -y

apt-get -q install -y \
    docker-ce{,-cli}=${DOCKER_CE_VERSION_APT} \
    containerd.io=${CONTAINERD_IO_VERSION_APT}

apt-mark hold \
    docker-ce{,-cli} \
    containerd.io

# setup "systemd" as cgroup driver
install -d /etc/docker/ && cat >/etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

curl -fsSL https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-Linux-x86_64 \
     -o /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose

usermod -aG docker ubuntu

sync
