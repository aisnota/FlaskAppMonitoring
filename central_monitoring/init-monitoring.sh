#!/bin/bash

echo "--- 중앙 모니터링 스택 삭제 시작 ---"

# 1. Helm 차트 삭제
helm uninstall central-monitor -n monitoring 2>/dev/null

# 2. 네임스페이스 삭제 (모든 리소스 강제 제거)
kubectl delete namespace monitoring --timeout=60s 2>/dev/null

# 3. 남아있는 CRD(Custom Resource Definitions) 삭제 
# (이걸 안 지우면 재설치 시 설정이 꼬일 수 있음)
kubectl delete crd alertmanagerconfigs.monitoring.coreos.com \
  alertmanagers.monitoring.coreos.com \
  podmonitors.monitoring.coreos.com \
  probes.monitoring.coreos.com \
  prometheusagents.monitoring.coreos.com \
  prometheuses.monitoring.coreos.com \
  prometheusrules.monitoring.coreos.com \
  servicemonitors.monitoring.coreos.com \
  thanosrulers.monitoring.coreos.com 2>/dev/null

# 4. 설정 파일 삭제 (선택 사항)
rm -f final-hub-values.yaml cluster-internal-values.yaml central-hub-values.yaml target-update.yaml

echo "--- 초기화 완료! 이제 깨끗한 상태입니다. ---"