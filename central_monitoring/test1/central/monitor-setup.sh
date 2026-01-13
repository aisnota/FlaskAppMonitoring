#!/bin/bash

# 1. 네임스페이스 생성 및 레포 업데이트
kubectl create namespace monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

s

# 3. 설치 실행
helm install central-monitor prometheus-community/kube-prometheus-stack \
  -f central-hub-values.yaml \
  -n monitoring

# 4. 입구(Service) 열기 (Remote Write용)
kubectl patch svc central-monitor-kube-prome-prometheus -n monitoring -p '{"spec": {"type": "NodePort"}}'

# grapana 접속
echo "--------------------------------------------------"
echo "설치 완료! Grafana 접속: http://$(hostname -I | awk '{print $1}'):32300"
echo "ID: admin / PW:admin"
echo "--------------------------------------------------"
