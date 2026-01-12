#!/bin/bash
echo ">>> [Agent Cluster] 에이전트 삭제 시작..."

# 1. Helm 릴리스 삭제
helm uninstall prom-agent -n monitoring

# 2. 네임스페이스 삭제
kubectl delete namespace monitoring

echo ">>> 에이전트 초기화 완료."