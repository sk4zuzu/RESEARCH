#!/usr/bin/env bash

set -o errexit -o pipefail

which base64 jq kubectl >/dev/null 2>&1

eval "$(jq -r '@sh "readonly KUBECONFIG=\(.kubeconfig) CONTEXT=\(.context) NAMESPACE=\(.namespace) PATTERN=\(.pattern)"')"

readonly VAULT_HELM_SECRET_NAME=$(
    kubectl \
        --kubeconfig $KUBECONFIG \
        --context $CONTEXT \
        --namespace $NAMESPACE \
        get secrets \
        --output json \
    | jq --arg pattern "$PATTERN" -r '.items[].metadata | select(.name | startswith($pattern)).name'
)

readonly TOKEN_REVIEW_JWT=$(
    kubectl \
        --kubeconfig $KUBECONFIG \
        --context $CONTEXT \
        --namespace $NAMESPACE \
        get secret/$VAULT_HELM_SECRET_NAME \
        --output 'go-template={{ .data.token }}' \
    | base64 --decode
)

jq -n --arg token "$TOKEN_REVIEW_JWT" '{"token_reviewer_jwt": $token}'
