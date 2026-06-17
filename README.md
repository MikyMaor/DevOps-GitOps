# GitOps repository for ArgoCD deployments

Per-environment Helm values for `flask-aws-monitor`.

## Structure

```
flask-aws-monitor/
├── dev/values.yaml   # 1 replica, ClusterIP
├── qa/values.yaml    # 2 replicas, ClusterIP
└── prd/values.yaml   # 3 replicas, LoadBalancer + Ingress
applicationsets/
└── flask-applicationset.yaml
```

## Before deploying

1. Push this folder to a **new public GitHub repo** (e.g. `MikyMaor-DevOps-GitOps`).
2. Update `applicationsets/flask-applicationset.yaml`:
   - Replace `YOUR-GITOPS-REPO` with your actual GitOps repo name.
   - Confirm the code repo URL points to your final code repository.
3. Create AWS secrets file on the cluster (not in git):
   - Use `helmchart/values.secrets.yaml` pattern from the code repo, or inject via ArgoCD secrets.

## Environment differences

| Env | Replicas | Service type | Ingress |
|-----|----------|--------------|---------|
| dev | 1 | ClusterIP | off |
| qa  | 2 | ClusterIP | off |
| prd | 3 | LoadBalancer | on |

## Apply ApplicationSet

```bash
kubectl apply -f applicationsets/flask-applicationset.yaml
argocd app list
```
