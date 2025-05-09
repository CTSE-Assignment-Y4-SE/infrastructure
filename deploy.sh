#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=argocd

echo
echo "1️⃣  Applying core infra (namespace, Argo CD, RBAC, installer jobs)…"
kubectl apply -f k8s/core/

echo
echo "2️⃣  Waiting for Argo CD server to be ready…"
kubectl rollout status deployment/argocd-server -n $NAMESPACE

echo
echo -n "🔐  Argo CD initial admin password: "
kubectl get secret argocd-initial-admin-secret -n $NAMESPACE \
  -o go-template='{{ .data.password | base64decode }}'
echo

echo "3️⃣  Waiting for database pods…"
DB_DEPS=(postgres-garage postgres-user postgres-vehicle-owner mysql-notification)
for dep in "${DB_DEPS[@]}"; do
  kubectl rollout status deployment/$dep -n $NAMESPACE
done

echo "4️⃣  Waiting for Zookeeper & Kafka…"
kubectl rollout status deployment/zookeeper -n $NAMESPACE
kubectl rollout status deployment/kafka -n $NAMESPACE

echo
echo "5️⃣  Deploying Microservices (user, vehicle-owner, garage, notification)…"
kubectl apply -f k8s/user-service/deployment.yaml \
               -f k8s/user-service/service.yaml \
               -f k8s/user-service/argocd.yaml
kubectl apply -f k8s/vehicle-owner-service/deployment.yaml \
               -f k8s/vehicle-owner-service/service.yaml \
              -f k8s/vehicle-owner-service/argocd.yaml
kubectl apply -f k8s/garage-service/deployment.yaml \
               -f k8s/garage-service/service.yaml \
               -f k8s/garage-service/argocd.yaml
kubectl apply -f k8s/notification-service/deployment.yaml \
               -f k8s/notification-service/service.yaml \
               -f k8s/notification-service/argocd.yaml

echo "   ▶️  Waiting for each microservice…"
MICROS=(user-service vehicle-owner-service garage-service notification-service)
for svc in "${MICROS[@]}"; do
  kubectl rollout status deployment/$svc -n $NAMESPACE
done

echo
echo "6️⃣  Deploying Frontend…"
kubectl apply -f k8s/frontend/deployment.yaml \
               -f k8s/frontend/service.yaml \
               -f k8s/frontend/argocd.yaml

echo "   ▶️  Waiting for frontend…"
kubectl rollout status deployment/frontend -n $NAMESPACE

echo
echo "7️⃣  Deploying API Gateway…"
kubectl apply -f k8s/gateway/gateway.yaml

echo "   ▶️  Waiting for gateway…"
kubectl rollout status deployment/gateway -n $NAMESPACE

echo
echo "8️⃣  Port‐forwarding services for local access…"
echo "    • Gateway → http://localhost:8080/"
kubectl port-forward --address 0.0.0.0 svc/gateway -n $NAMESPACE 8080:80 \
  > /dev/null 2>&1 &
PF_GATEWAY=$!

echo "    • Argo CD → http://localhost:8081/"
kubectl port-forward --address 0.0.0.0 svc/argocd-server -n $NAMESPACE 8081:80 \
  > /dev/null 2>&1 &
PF_ARGOCD=$!

echo
echo "✅ All done!"
echo "Gateway port‐forward PID: $PF_GATEWAY"
echo "Argo CD port‐forward PID: $PF_ARGOCD"
