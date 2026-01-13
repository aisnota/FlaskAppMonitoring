# 1. 방화벽 비활성화 (테스트 환경이므로 간섭 최소화를 위해 끕니다)
sudo ufw disable

# 2. Swap 메모리 비활성화 (K8s 성능 및 안정성 이슈 방지)
sudo swapoff -a
sudo sed -i '/swap/s/^/#/' /etc/fstab

# 3. 브릿지 트래픽이 iptables를 거치도록 설정 (네트워크 통신 필수 설정)
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system