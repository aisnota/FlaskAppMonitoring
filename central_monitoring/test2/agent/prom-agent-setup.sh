#!/bin/bash

# 1. 네임스페이스 생성
kubectl create namespace monitoring

# 2. Helm 레포지토리 추가
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 3. 데이터 송신기(Prometheus Agent) 설치
helm upgrade --install prom-agent prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f stack-agent-values.yaml