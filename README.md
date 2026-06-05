# platform-deploy

Deployment repository for Platform Starter Kit.

## Scope
- `helm`: shared Helm chart and templates
- `environments/dev`: development values
- `environments/stg`: staging values
- `environments/prd`: production values
- `argocd`: ArgoCD Application manifests

## GitOps Responsibilities
- Store desired deployment state
- Track image tags produced by Jenkins
- Provide environment-specific configuration
- Let ArgoCD synchronize k3s workloads from Git

## Day 4 Helm Deploy
Render and validate the chart:

```bash
helm lint helm/platform-app
helm template platform helm/platform-app -n dev -f environments/dev/values.yaml
```

Deploy to the local k3s `dev` namespace:

```bash
export GHCR_PAT='<github-pat-with-read-packages>'
kubectl -n dev create secret docker-registry ghcr-token \
  --docker-server=ghcr.io \
  --docker-username=paddyKim \
  --docker-password="$GHCR_PAT" \
  --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install platform helm/platform-app -n dev -f environments/dev/values.yaml
```

Check rollout:

```bash
kubectl -n dev get pods,svc
kubectl -n dev rollout status deploy/platform-api
kubectl -n dev rollout status deploy/platform-web
```

Port-forward for browser/API verification:

```bash
kubectl -n dev port-forward svc/platform-api 8080:8080
kubectl -n dev port-forward svc/platform-web 3000:80
```

Verify the API:

```bash
curl http://localhost:8080/actuator/health
curl http://localhost:8080/api/tasks
```
