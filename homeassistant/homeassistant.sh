#!/usr/bin/env bash

set -e

export DEBIAN_FRONTEND=noninteractive

if ! podman version; then
    apt-get -q update -y
    apt-get -q install -y podman
fi

install -m u=rwx,go=rx -o 0 -g 0 -d /opt/homeassistant/

if ! podman container exists homeassistant; then
    podman run -d \
        --name homeassistant \
        --privileged \
        -e TZ=Europe/Warsaw \
        -v /opt/homeassistant/:/config/ \
        -v /run/dbus:/run/dbus:ro \
        --network=host \
        ghcr.io/home-assistant/home-assistant:dev
fi

podman generate systemd homeassistant > /etc/systemd/system/homeassistant.service

systemctl daemon-reload

systemctl enable homeassistant.service --now
