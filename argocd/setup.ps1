#Requires -Version 5.1
$ErrorActionPreference = "Stop"

function Write-Step($Message) {
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Ensure-Helm {
    if (Get-Command helm -ErrorAction SilentlyContinue) {
        return
    }
    Write-Step "Installing Helm via winget"
    winget install --id Helm.Helm -e --accept-source-agreements --accept-package-agreements
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
        throw "Helm not found after install. Open a new terminal and run setup again."
    }
}

function Ensure-KubeContext {
    Write-Step "Checking Kubernetes cluster"
    $kubeConfig = Join-Path $env:USERPROFILE ".kube\config"
    if (-not (Test-Path $kubeConfig)) {
        throw @"
kubeconfig not found at $kubeConfig

Enable Kubernetes in Docker Desktop:
  Settings -> Kubernetes -> Enable Kubernetes -> Apply & Restart
Wait until 'Kubernetes running' appears, then run this script again.
"@
    }

    $contexts = kubectl config get-contexts -o name 2>$null
    if (-not $contexts) {
        throw "No kubectl contexts found. Enable Kubernetes in Docker Desktop."
    }

    $preferred = @("docker-desktop", "kind-kind", "minikube")
    $selected = $null
    foreach ($name in $preferred) {
        if ($contexts -contains $name) {
            $selected = $name
            break
        }
    }
    if (-not $selected) {
        $selected = ($contexts | Select-Object -First 1)
    }

    kubectl config use-context $selected | Out-Null
    Write-Host "Using context: $selected"

    kubectl get nodes
    if ($LASTEXITCODE -ne 0) {
        throw "kubectl cannot reach the cluster. Is Kubernetes running in Docker Desktop?"
    }
}

function Install-ArgoCD {
    Write-Step "Installing ArgoCD"
    # Idempotent: create namespace if missing (avoid PowerShell treating NotFound as fatal)
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create namespace argocd"
    }

    kubectl apply --server-side --force-conflicts -n argocd -f "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"

    Write-Host "Waiting for argocd-server rollout..."
    kubectl rollout status deployment/argocd-server -n argocd --timeout=300s
    kubectl rollout status deployment/argocd-applicationset-controller -n argocd --timeout=300s
}

function Apply-ApplicationSet {
    Write-Step "Applying ApplicationSet"
    $appSet = Join-Path $PSScriptRoot "..\applicationsets\flask-applicationset.yaml"
    kubectl apply -f $appSet
    Start-Sleep -Seconds 5
    kubectl get applicationsets -n argocd
    kubectl get applications -n argocd
}

function Show-ArgoCDAccess {
    Write-Step "ArgoCD access"
    $password = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>$null
    if ($password) {
        $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($password))
        Write-Host "Username: admin"
        Write-Host "Password: $decoded"
    } else {
        Write-Host "Could not read initial admin password yet. Retry:"
        Write-Host "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | ForEach-Object { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(`$_)) }"
    }

    Write-Host @"

Next steps:
  1. New terminal: kubectl port-forward svc/argocd-server -n argocd 8081:443
  2. Open: https://localhost:8081  (accept self-signed cert)
  3. Watch apps sync in the UI, or run: kubectl get applications -n argocd -w
  4. App access (dev): kubectl port-forward svc/flask-dev-flask-aws-monitor -n dev 5001:5001
"@
}

Write-Step "Final Exam - ArgoCD setup"
Ensure-KubeContext
Ensure-Helm
Install-ArgoCD
Apply-ApplicationSet
Show-ArgoCDAccess
Write-Step "Done"
