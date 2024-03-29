#!/usr/bin/env bash

set -o errexit -o nounset
set -x

install -o 0 -g 0 -m u=rw,go=r -D /dev/fd/0 /etc/dpkg/dpkg.cfg.d/excludes <<'EOF'
path-exclude=/usr/share/man/*
path-exclude=/usr/share/locale/*/LC_MESSAGES/*.mo
path-exclude=/usr/share/doc/*
path-include=/usr/share/doc/*/copyright
path-include=/usr/share/doc/*/changelog.Debian.*
EOF

rm -rf /usr/share/man/* ||:
rm -rf /usr/share/locale/*/LC_MESSAGES/*.mo ||:

TMP_DIR=$(mktemp -d) && cd "$TMP_DIR/"
mv -f /usr/share/doc/* . ||:
cp -rf --parents */copyright /usr/share/doc/ ||:
cp -rf --parents */changelog.Debian.* /usr/share/doc/ ||:
cd - && rm -rf "$TMP_DIR/"

sync
