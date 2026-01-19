#!/usr/bin/env bash
set -euo pipefail

# =========================
# 변수 설정
# =========================
NODE_EXPORTER_VERSION="1.7.0"
MYSQL_EXPORTER_VERSION="0.15.1"

NODE_EXPORTER_URL="https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
MYSQL_EXPORTER_URL="https://github.com/prometheus/mysqld_exporter/releases/download/v${MYSQL_EXPORTER_VERSION}/mysqld_exporter-${MYSQL_EXPORTER_VERSION}.linux-amd64.tar.gz"

MYSQL_EXPORTER_USER="exporter"
MYSQL_EXPORTER_PASSWORD="exporter_password"

WORKDIR="/tmp/exporter-install"

# =========================
# 사전 체크
# =========================
if [[ $EUID -ne 0 ]]; then
  echo "❌ root 권한으로 실행해야 합니다."
  exit 1
fi

echo "✅ Exporter 설치 시작"

mkdir -p "$WORKDIR"
cd "$WORKDIR"

# =========================
# Node Exporter 설치
# =========================
echo "▶ Node Exporter 설치 중..."

wget -q "$NODE_EXPORTER_URL"
tar xvf "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
mv "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" /usr/local/bin/
chmod +x /usr/local/bin/node_exporter

# =========================
# MySQL Exporter 설치
# =========================
echo "▶ MySQL Exporter 설치 중..."

wget -q "$MYSQL_EXPORTER_URL"
tar xvf "mysqld_exporter-${MYSQL_EXPORTER_VERSION}.linux-amd64.tar.gz"
mv "mysqld_exporter-${MYSQL_EXPORTER_VERSION}.linux-amd64/mysqld_exporter" /usr/local/bin/
chmod +x /usr/local/bin/mysqld_exporter

# =========================
# MySQL Exporter 인증 정보
# =========================
echo "▶ MySQL Exporter 인증 정보 설정"

cat <<EOF > /etc/.mysqld_exporter.cnf
[client]
user=${MYSQL_EXPORTER_USER}
password=${MYSQL_EXPORTER_PASSWORD}
EOF

chmod 600 /etc/.mysqld_exporter.cnf

# =========================
# systemd 서비스 등록
# =========================
echo "▶ systemd 서비스 등록"

cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF > /etc/systemd/system/mysqld_exporter.service
[Unit]
Description=MySQL Exporter
After=network.target mysql.service

[Service]
ExecStart=/usr/local/bin/mysqld_exporter --config.my-cnf=/etc/.mysqld_exporter.cnf
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# =========================
# 서비스 실행
# =========================
echo "▶ 서비스 시작"

systemctl daemon-reload
systemctl enable --now node_exporter
systemctl enable --now mysqld_exporter

# =========================
# 상태 확인
# =========================
echo "▶ 서비스 상태 확인"
systemctl status node_exporter --no-pager
systemctl status mysqld_exporter --no-pager

echo "✅ 모든 Exporter 설치 완료"