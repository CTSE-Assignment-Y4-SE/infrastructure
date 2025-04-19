#!/usr/bin/env bash
set -euo pipefail

# 1. Apply core infra (namespace, ArgoCD, Postgres, RBAC, etc.)
echo "Applying core infrastructure…"
kubectl apply -f k8s/core/

# 2. Wait for ArgoCD server to be ready
echo "Waiting for ArgoCD server rollout…"
kubectl rollout status deployment/argocd-server -n argocd

# 3. Grab and show the initial admin password
echo -n "ArgoCD admin password: "
kubectl get secret argocd-initial-admin-secret \
  -n argocd \
  -o jsonpath="{.data.password}" | base64 -d
echo

# 4. Port‑forward ArgoCD UI (in background)
echo "Starting port‑forward to ArgoCD at http://localhost:8080…"
kubectl port-forward svc/argocd-server -n argocd 8080:443 \
  > /dev/null 2>&1 &
PF_PID=$!
echo "→ port‑forward PID: $PF_PID"

# 5. Apply all ArgoCD app manifests (frontend, user‑service, etc.)
echo "Applying all service App definitions…"
kubectl apply -R -f k8s/

echo "✅ All done! Browse to http://localhost:8080 and log in as 'admin'."
