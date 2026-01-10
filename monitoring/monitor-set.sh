#!/usr/bin/env bash
set -euo pipefail

# ===============
# Config
# ===============
NAMESPACE="monitoring"
RELEASE="monitoring"
CHART="prometheus-community/kube-prometheus-stack"

# ===============
# 1) Helm 설치(없으면 설치)
# ===============
echo "[1/6] Helm 설치 여부 확인"
if command -v helm >/dev/null 2>&1; then
  echo "  - Helm already installed: $(helm version --short || true)"
else
  echo "  - Helm not found. Installing Helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  echo "  - Helm installed: $(helm version --short || true)"
fi

# ===============
# 2) Helm Repo 추가/업데이트
# ===============
echo "[2/6] Helm repo 추가/업데이트"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update

# ===============
# 3) Namespace 생성
# ===============
echo "[3/6] Namespace 생성/확인: ${NAMESPACE}"
kubectl get ns "${NAMESPACE}" >/dev/null 2>&1 || kubectl create namespace "${NAMESPACE}"

# ===============
# 4) 설치/업그레이드 (idempotent)
# ===============
echo "[4/6] kube-prometheus-stack 설치/업그레이드: release=${RELEASE}, ns=${NAMESPACE}"
helm install "${RELEASE}" "${CHART}" \
  -n "${NAMESPACE}" \
  -f values.yaml \
  --wait \
  --timeout 10m

# ===============
# 5) 상태 확인
# ===============
echo "[5/6] 리소스 상태 확인"
kubectl get pods -n "${NAMESPACE}"
kubectl get svc  -n "${NAMESPACE}"

# ===============
# 6) 설치 결과 출력
# ===============
echo "[6/6] 설치 완료"
echo "Grafana/Prometheus/Alertmanager Service 목록:"
kubectl get svc -n "${NAMESPACE}" | egrep 'grafana|prometheus|alertmanager|NAME' || true

# ===============
# 7) 비밀번호 확인
# ===============
echo "해당 비밀번호를 이용해 grapana에 접속하세요"
kubectl get secret --namespace monitoring monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo