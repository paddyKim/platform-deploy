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
