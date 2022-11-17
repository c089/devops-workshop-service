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

# install prometheus, alertmanager, grafana
helm upgrade --install --atomic --create-namespace \
	--namespace observability \
  --values "${CLUSTER_DIR}/kube-prometheus-stack-values.yaml" \
	kube-prometheus-stack prometheus-community/kube-prometheus-stack

kubectl apply -f "${CLUSTER_DIR}/kube-prometheus-stack-ingressroutes.yaml"

# install loki and prommtail
helm upgrade --install --atomic --create-namespace \
	--namespace observability \
  loki-stack grafana/loki-stack

# install blackbox-exporter
kubectl create configmap \
  -n observability \
  certificate-host.k3d.internal \
  --from-file "host.k3d.internal.crt=$certfile"

helm upgrade --install --atomic \
  --namespace observability \
  --values "${CLUSTER_DIR}/prometheus-blackbox-exporter-values.yaml" \
  prometheus-blackbox-exporter \
  prometheus-community/prometheus-blackbox-exporter

kubectl apply -f "${CLUSTER_DIR}/prometheus-blackbox-exporter-ingressroute.yaml"

# install argocd
helm install \
  -n argocd \
  --create-namespace \
  argo-cd \
  argo/argo-cd \
  --values "${CLUSTER_DIR}/argocd-values.yaml"
kubectl apply -f "${CLUSTER_DIR}/argocd-ingressroute.yaml"

# cleanup
rm $keyfile
rm $certfile

until ${CLUSTER_DIR}/test.sh; do
	(${CLUSTER_DIR}/test.sh) && break
	sleep 5
done
