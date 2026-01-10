#!/bin/bash

# 1. K3s 설치 (가벼운 K8s)
curl -sfL https://get.k3s.io | sh -
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $USER:$USER ~/.kube/config
export KUBECONFIG=~/.kube/config

# 2. Helm 설치
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 3. Prometheus 레포지토리 추가
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 4. 중앙 서버용 설정 파일 생성
cat <<EOF > hub-values.yaml
prometheus:
  prometheusSpec:
    enableRemoteWriteReceiver: true
    retention: 15d
    storageSpec:
      volumeClaimTemplate:
        spec:
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi
grafana:
  service:
    type: NodePort
EOF

# 5. 모니터링 스택 설치
kubectl create namespace monitoring
helm install central-monitor prometheus-community/kube-prometheus-stack \
  -f hub-values.yaml \
  -n monitoring

# 6. 결과 확인
echo "--------------------------------------------------"
echo "설치 완료! 접속 정보 확인 중..."
sleep 5
kubectl get svc -n monitoring | grep -E 'prometheus-prometheus|grafana'
