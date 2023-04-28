#!/usr/bin/env bash

export DEBIAN_FRONTEND=noninteractive

set -o errexit

id

apt-get update && apt-get install -y python3{,-pip}
