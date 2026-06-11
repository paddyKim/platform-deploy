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

## Day 6 GitOps Deploy and Rollback
Day 6 uses ArgoCD automated sync for `dev`.

Safety defaults:
- `selfHeal: true`
- `prune: false`
- Helm release name remains `platform`

Update the deployed image tag after Jenkins pushes new images:

```bash
cd platform-deploy

NEW_TAG='<jenkins-git-short-sha>'

perl -0pi -e "s/(api:\n(?:  .*\n)*?  image:\n(?:    .*\n)*?    tag: ).*/\${1}${NEW_TAG}/" environments/dev/values.yaml
perl -0pi -e "s/(web:\n(?:  .*\n)*?  image:\n(?:    .*\n)*?    tag: ).*/\${1}${NEW_TAG}/" environments/dev/values.yaml

git diff environments/dev/values.yaml
git add environments/dev/values.yaml
git commit -m "Deploy dev image ${NEW_TAG}"
git push origin main
```

Check ArgoCD sync and rollout:

```bash
kubectl -n argocd get application platform-dev
kubectl -n argocd get application platform-dev -o jsonpath='{.status.sync.status} {.status.health.status}'

kubectl -n dev rollout status deploy/platform-api
kubectl -n dev rollout status deploy/platform-web
```

Rollback with Git revert:

```bash
cd platform-deploy

git log --oneline -5
git revert <bad-deploy-commit>
git push origin main

kubectl -n argocd get application platform-dev
kubectl -n dev rollout status deploy/platform-api
kubectl -n dev rollout status deploy/platform-web
```

## Day 7 Observability
The chart includes an optional ServiceMonitor for `platform-api`.

Current dev configuration enables:

```text
ServiceMonitor: platform-api
Scrape path: /actuator/prometheus
Prometheus selector label: release=monitoring
```

Check it:

```bash
kubectl -n dev get servicemonitor platform-api
kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090
```

PromQL:

```promql
up{service="platform-api"}
jvm_memory_used_bytes
http_server_requests_seconds_count
```

## Day 8 Failure Drill Results
Three recovery paths were verified:

| Drill | Failure Type | Recovery Owner | MTTR |
|---|---|---|---|
| Bad image tag | Bad Git desired state | Git revert + ArgoCD sync | 1m 17s |
| Replica 0 drift | Live cluster drift | ArgoCD self-heal | 33s |
| Pod deletion | Missing runtime pod | Kubernetes Deployment controller | 33s |

Important boundary:
- ArgoCD corrects Git-to-cluster drift.
- Kubernetes Deployment controller recreates missing pods to satisfy `replicas`.
- Git revert is the recovery path for bad desired state committed to this repository.

## Portfolio References
- `../docs/day-08-completion.md`
- `../docs/operations-runbook.md`
- `../docs/portfolio-summary.md`
- `../docs/demo-script.md`
