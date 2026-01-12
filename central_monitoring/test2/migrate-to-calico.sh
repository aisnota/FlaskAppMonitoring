#!/bin/bash
set -e

echo "1. Flannel 리소스 삭제 중..."
kubectl delete -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml || true

echo "2. 네트워크 인터페이스 및 설정 정리..."
sudo ip link delete flannel.1 || true
sudo rm -rf /etc/cni/net.d/10-flannel.conflist
sudo rm -rf /var/lib/cni/flannel

echo "3. Calico Operator 설치 중..."
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml

echo "4. Calico 기본 리소스 배포 중..."
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/custom-resources.yaml

echo "5. MTU 1450 설정 적용 중..."
# Operator가 준비될 때까지 잠시 대기
sleep 20
kubectl patch installation default --type=merge -p '{"spec": {"calicoNetwork": {"mtu": 1450}}}'

echo "6. 모든 노드 재부팅 권장 또는 Kubelet 재시작"
# sudo systemctl restart kubelet