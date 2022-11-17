#!/bin/bash
set -ex

CLUSTER_DIR=$(dirname "$0")
source "${CLUSTER_DIR}/prerequisites.sh"

# create and install a default certificate
keyfile=$(mktemp)
certfile=$(mktemp)
mkcert -install -cert-file $certfile -key-file $keyfile localhost k3d.localhost \*.k3d.localhost host.k3d.internal

# create cluster
k3d cluster create \
  --agents 2 \
  -p "80:80@loadbalancer" \
  -p "443:443@loadbalancer"

# configure traefik
helm_deploy_status() {
	helm status -o json -n kube-system traefik 2> /dev/null | jq -j '.info.status'
}
echo "waiting for traefik..."
until [[ $(helm_deploy_status) = "deployed" ]]; do
  echo -n "."
	sleep 1
done

kubectl delete deployment -n kube-system traefik # workaround "cannot ugprade" issue
helm upgrade -n kube-system --values "${CLUSTER_DIR}/traefik-values.yaml" traefik traefik/traefik

# wait for trafik to install ingressroute crd
echo "waiting for crd..."
until kubectl get crd | grep ingressroute; do
  echo -n "."
	sleep 1
done

# replace traefik ingressroute
kubectl delete ingressroute -n kube-system traefik-dashboard
kubectl apply -f "${CLUSTER_DIR}/traefik-ingressroute.yaml"

# create and install a default certificate
keyfile=$(mktemp)
certfile=$(mktemp)
mkcert -install -cert-file $certfile -key-file $keyfile localhost k3d.localhost \*.k3d.localhost
# save it as secret for traefik to find
kubectl create secret -n kube-system tls tls-default-certificate --cert $certfile --key $keyfile

# cleanup
rm $keyfile
rm $certfile

until ${CLUSTER_DIR}/test.sh; do
	sleep 5
done
