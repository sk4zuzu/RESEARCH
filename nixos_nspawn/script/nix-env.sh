#!/usr/bin/env sh

set -xe

id

nix-env -i bash gnumake python3

ln -s $(which bash) /bin/bash
