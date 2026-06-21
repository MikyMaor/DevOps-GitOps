# DevOps GitOps

Per-environment Helm values for ArgoCD. Jenkins updates `image.tag` here after each build.

## Structure

```
flask-aws-monitor/{dev,qa,prd}/values.yaml
rendered/                              # helm template output from CI
applicationsets/flask-applicationset.yaml
argocd/setup.ps1                       # local ArgoCD install
```

| Env | Replicas | Service |
|-----|----------|---------|
| dev | 1 | ClusterIP |
| qa  | 2 | ClusterIP |
| prd | 3 | LoadBalancer |

## ArgoCD

Requires Kubernetes (Docker Desktop). From `argocd/`:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
kubectl port-forward svc/argocd-server -n argocd 8081:443
```

UI: https://localhost:8081 (user `admin`)

ApplicationSet uses chart from `Docker_K8S_Helm/helmchart` + values from this repo.
