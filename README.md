## Setup Infrastructure

```sh
# Create cluster
cluster/create.sh

# After cluster creation, a verification script will run repeatedly and fail some
# tests for a while, but should eventually succeed if everything worked.

# Login
./cluster/argocd-login.sh

# Deploy the example service
argocd app create -f example-service-deploy/argocd-application.yaml

# Show credentials
./cluster/show-credentials.sh
```
