#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail
set -x

onemarket create /dev/fd/0 <<EOF
NAME              = S3MinioMarket
ACCESS_KEY_ID     = "asd"
SECRET_ACCESS_KEY = "asdasdasd"
BUCKET            = "backups"
ENDPOINT          = "http://10.23.45.86:9000"
FORCE_PATH_STYLE  = "YES"
MARKET_MAD        = s3
REGION            = "default"
SIGNATURE_VERSION = s3
AWS               = no
EOF

onetemplate update -a alpine314 /dev/fd/0 <<EOF
BACKUP=[
  FREQUENCY_SECONDS="300",
  MARKETPLACE_ID="100" ]
EOF
