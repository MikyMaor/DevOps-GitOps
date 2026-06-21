# GitOps repository for ArgoCD deployments

Per-environment Helm values for `flask-aws-monitor`. Jenkins CI updates image tags here after each Docker build.

## Structure

```
flask-aws-monitor/
├── dev/values.yaml
├── qa/values.yaml
└── prd/values.yaml
rendered/                          # created/updated by Jenkins CI
├── flask-aws-monitor-dev.yaml
├── flask-aws-monitor-qa.yaml
└── flask-aws-monitor-prd.yaml
applicationsets/
└── flask-applicationset.yaml
```

## How CI updates this repo

The `Jenkinsfile` in the Code repo:

1. Builds and pushes `miky97/flask-aws-monitor:<build-number>` to Docker Hub
2. Clones this repo
3. Updates `image.tag` in `flask-aws-monitor/*/values.yaml`
4. Runs `helm template` and commits files under `rendered/`
5. Pushes to `main`

ArgoCD watches this repo and syncs deployments when these files change.

## Environment differences

| Env | Replicas | Service type | Ingress |
|-----|----------|--------------|---------|
| dev | 1 | ClusterIP | off |
| qa  | 2 | ClusterIP | off |
| prd | 3 | LoadBalancer | on |

## ArgoCD (local or cloud shell)

```bash
kubectl apply -f applicationsets/flask-applicationset.yaml
argocd app list
```

ApplicationSet sources:

- Helm chart: `MikyMaor/Docker_K8S_Helm` → `helmchart/`
- Values: this repo → `flask-aws-monitor/<env>/values.yaml`
