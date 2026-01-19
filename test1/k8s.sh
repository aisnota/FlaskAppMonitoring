#!/bin/bash

MASTER_IP="192.168.13.115"
WORKERS=("192.168.13.116" "192.168.13.117")
POD_CIDR="192.168.0.0/16"

setup_node_ready() {
    local node=$1
    echo "-> $node 환경 설정 중..."
    ssh -o StrictHostKeyChecking=no $node "
        # Swap 끄기
        sudo swapoff -a
        sudo sed -i '/swap/s/^/#/' /etc/fstab

        # 커널 모듈 로드 (에러 방지 핵심)
        sudo modprobe overlay
        sudo modprobe br_netfilter

        cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
        sudo sysctl --system

        # containerd 및 k8s 설치 (이미 설치된 경우 건너뜀)
        if ! command -v containerd &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y containerd
            sudo mkdir -p /etc/containerd
            containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
            sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
            sudo systemctl restart containerd
        fi
    "
}

# 1. 모든 노드 사전 준비
setup_node_ready localhost
for worker in "${WORKERS[@]}"; do setup_node_ready $worker; done

# 2. Master 초기화 (커널 설정 적용 후 실행)
sudo kubeadm init --apiserver-advertise-address=$MASTER_IP --pod-network-cidr=$POD_CIDR --ignore-preflight-errors=FileContent--proc-sys-net-bridge-bridge-nf-call-iptables

# 3. 권한 설정
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 4. Calico CNI 설치
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
sleep 5
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml

# 5. Worker Join
JOIN_CMD=$(kubeadm token create --print-join-command)
for worker in "${WORKERS[@]}"; do
    ssh $worker "sudo $JOIN_CMD"
done

echo "Cluster setup complete. Check status with: kubectl get nodes"
