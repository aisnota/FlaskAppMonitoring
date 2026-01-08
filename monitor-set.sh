#!/usr/bin/env bash
set -euo pipefail

# ===============
# Config (필요시 수정)
# ===============
NAMESPACE="monitoring"
RELEASE="monitoring"
CHART="prometheus-community/kube-prometheus-stack"

# kubeconfig 컨텍스트 확인 (안전장치)
echo "[1/8] kubectl context 확인"
kubectl config current-context >/dev/null
kubectl cluster-info >/dev/null
echo "  - Context: $(kubectl config current-context)"

# ===============
# 1) Helm 설치(없으면 설치)
# ===============
echo "[2/8] Helm 설치 여부 확인"
if command -v helm >/dev/null 2>&1; then
  echo "  - Helm already installed: $(helm version --short || true)"
else
  echo "  - Helm not found. Installing Helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  echo "  - Helm installed: $(helm version --short || true)"
fi

# ===============
# 2) Repo 추가/업데이트
# ===============
echo "[3/8] Helm repo 추가/업데이트"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update

# ===============
# 3) Namespace 생성
# ===============
echo "[4/8] Namespace 생성/확인: ${NAMESPACE}"
kubectl get ns "${NAMESPACE}" >/dev/null 2>&1 || kubectl create namespace "${NAMESPACE}"

# ===============
# 4) (선택) values.yaml 기본 템플릿 생성
#    - 이미 values.yaml이 있다면 이 단계는 필요 없음
# ===============
echo "[5/8] values.yaml 템플릿 생성(없을 때만)"
if [[ ! -f values.yaml ]]; then
  cat > values.yaml <<'YAML'
# kube-prometheus-stack 기본값에서 자주 손대는 포인트만 최소로 둔 템플릿입니다.
# 지금은 "설치까지" 목적이니 비워두거나 필요한 것만 추가하세요.

grafana:
  enabled: true

prometheus:
  prometheusSpec:
    # 운영/장기보관 고려 전까지는 기본값으로 두는 편이 안전
    # retention: 15d
    # storageSpec:
    #   volumeClaimTemplate:
    #     spec:
    #       storageClassName: gp2
    #       accessModes: ["ReadWriteOnce"]
    #       resources:
    #         requests:
    #           storage: 20Gi
    pass

alertmanager:
  enabled: true
YAML
  # YAML에서 "pass"는 유효하지 않으므로 제거(여기서는 템플릿 가독성용)
  # 실제 파일에 남아있으면 helm이 실패하니 반드시 제거 처리
  sed -i 's/^    pass$//' values.yaml 2>/dev/null || true
  echo "  - values.yaml created"
else
  echo "  - values.yaml already exists (skipped)"
fi

# ===============
# 5) 설치/업그레이드 (idempotent)
# ===============
echo "[6/8] kube-prometheus-stack 설치/업그레이드: release=${RELEASE}, ns=${NAMESPACE}"
helm install "${RELEASE}" "${CHART}" \
  -n "${NAMESPACE}" \
  -f values.yaml \
  --wait \
  --timeout 10m

# ===============
# 6) 상태 확인
# ===============
echo "[7/8] 리소스 상태 확인"
kubectl get pods -n "${NAMESPACE}"
kubectl get svc  -n "${NAMESPACE}"

# ===============
# 7) 설치 결과 출력
# ===============
echo "[8/8] 설치 완료"
echo "Grafana/Prometheus/Alertmanager Service 목록:"
kubectl get svc -n "${NAMESPACE}" | egrep 'grafana|prometheus|alertmanager|NAME' || true