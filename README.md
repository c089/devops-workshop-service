## Setup Infrastructure

Create cluster:
```sh
cluster/create.sh
```

Verify installation:
```sh
cluster/test.sh
```

Login to Argo-CD:
```sh
argocd login argocd.k3d.localhost --username admin --password $(kubectl get secret -n argocd argocd-initial-admin-secret -o json|jq .data.password -j | base64 -d)
```

Create the example app:

```sh
argocd app create -f example-service-deploy/argocd-application.yaml
```

## Credentials

Grafana: admin / prom-operator
Argocd: `kubectl get secret -n argocd argocd-initial-admin-secret -o json|jq .data.password -j | base64 -d`
