#!/bin/bash

# 1. 네임스페이스 생성
kubectl create namespace monitoring

# 2. Helm 레포지토리 추가 및 업데이트
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 3. 중앙 모니터링 스택 설치
# Grafana 비번은 admin / admin123으로 설정 (학습용)
# 다른 클러스터에서 지표를 보낼 수 있도록 remote-write 수신 활성화
# 내부 테스트이기 때문에 nodeport로 진행
# Cluster 2, 3에서 보낸 지표 데이터 받는 옵션
helm upgrade --install central-mon prometheus-community/kube-prometheus-stack \
  -f central-hub-stack-values.yaml \
  -n monitoring

# 4. 서비스 확인
echo "--------------------------------------------------"
echo "설치 완료! 서비스 상태를 확인합니다."
kubectl get pods -n monitoring