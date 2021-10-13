#!/usr/bin/env sh

set -e

exec kill -CONT "$(cat /mesh-retry/main.py.pid)"
