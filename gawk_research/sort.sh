#!/usr/bin/env bash

: "${DKR_VER:=20.10}"
: "${K8S_VER:=1.21}"

set -o errexit -o pipefail

apt-cache madison docker-ce | gawk -v VER="$DKR_VER" -f /dev/fd/3 3<<'EOF'
BEGIN { sort = "sort --version-sort --reverse" }
$3 ~ VER { print $3 |& sort }
END { close(sort, "to"); sort |& getline latest; print latest }
EOF

apt-cache madison kubelet | gawk -v VER="$K8S_VER" -f /dev/fd/3 3<<'EOF'
BEGIN { sort = "sort --version-sort --reverse" }
$3 ~ VER { print $3 |& sort }
END { close(sort, "to"); sort |& getline latest; print latest }
EOF
