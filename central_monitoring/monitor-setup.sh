#!/bin/bash

# 1. 네임스페이스 생성 및 레포 업데이트
kubectl create namespace monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 2. 중앙 집중형 설정 파일 생성 (IP 부분만 본인 환경에 맞게 수정)
if [[ ! -f central-hub-values.yaml ]]; then
    cat <<EOF > central-hub-values.yaml
prometheus:
  prometheusSpec:
    enableRemoteWriteReceiver: true
    retention: 10d
    # 클러스터 내부 노드(VM1,2,3) 및 앱 자동 수집 설정
    serviceMonitorSelectorNilUsesHelmValues: false
    podMonitorSelectorNilUsesHelmValues: false
    

grafana:
  service:
    type: NodePort
    nodePort: 32300
EOF
else
  echo "central-hub-values.yaml already exists (skipped)"
fi

# 3. 설치 실행
helm install central-monitor prometheus-community/kube-prometheus-stack \
  -f central-hub-values.yaml \
  -n monitoring

# 4. 입구(Service) 열기 (Remote Write용)
kubectl patch svc central-monitor-kube-prome-prometheus -n monitoring -p '{"spec": {"type": "NodePort"}}'

# grapana 접속
echo "--------------------------------------------------"
echo "설치 완료! Grafana 접속: http://$(hostname -I | awk '{print $1}'):32300"
echo "ID: admin / PW:
kubectl get secret --namespace monitoring central-monitor-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
echo "--------------------------------------------------"
