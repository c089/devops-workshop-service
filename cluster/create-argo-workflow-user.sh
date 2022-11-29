#!/bin/sh
$(dirname "$0")/argocd-login.sh
token=$(argocd account generate-token --account argo-workflows)
kubectl create secret generic argocd-argo-workflows-token \
  --from-literal auth-token="$token"
