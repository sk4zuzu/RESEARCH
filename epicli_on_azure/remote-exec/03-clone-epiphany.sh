#!/usr/bin/env bash

: ${EPIPHANY_WORKSPACE:=${HOME}/epiphany}
: ${EPIPHANY_REMOTE:=https://github.com/epiphany-platform/epiphany.git}
: ${EPIPHANY_BRANCH:=develop}

set -o errexit -o nounset -o pipefail
set -x

install -d ${EPIPHANY_WORKSPACE}/

cd ${EPIPHANY_WORKSPACE}/

git clone --branch=${EPIPHANY_BRANCH} ${EPIPHANY_REMOTE} . || git fetch origin ${EPIPHANY_BRANCH}

git checkout ${EPIPHANY_BRANCH}

git clean -df

git reset --hard origin/${EPIPHANY_BRANCH}

sync
