#!/bin/bash

set -ex

command_exists() {
    local COMMAND="$1"
    if ! command -v "$COMMAND"; then
	echo "Install '${COMMAND}'"
	exit 1
    fi
}

has_helm_repo() {
    local NAME="$1"
    local URL="$2"
	set +e
	helm repo list -o json | jq -e ".[] | select(.name == \"${NAME}\" and .url == \"${URL}\")"
    if [ $? -ne 0 ]
    then
        echo "Run 'helm repo add ${NAME} ${URL}' to add the missing repo"
        exit 1
    fi
	set -e
}

command_exists "kubectl"
command_exists "jq"
command_exists "k3d"
command_exists "helm"
command_exists "mkcert"
command_exists "argo"
command_exists "argocd"

has_helm_repo "traefik" "https://traefik.github.io/charts"
has_helm_repo "prometheus-community" "https://prometheus-community.github.io/helm-charts"
has_helm_repo "grafana" "https://grafana.github.io/helm-charts"
has_helm_repo "argo" "https://argoproj.github.io/argo-helm"
has_helm_repo "gitea-charts" "https://dl.gitea.io/charts/"
