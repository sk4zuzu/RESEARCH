#!/usr/bin/env sh

set -e

exec kill -STOP "$(cat /mesh-retry/main.py.pid)"
