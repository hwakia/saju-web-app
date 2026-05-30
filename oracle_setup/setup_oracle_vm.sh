#!/bin/bash
# 사주MRI Oracle Cloud Free Tier (Ubuntu 22.04 ARM) 초기 셋업 스크립트
# 사용법: chmod +x setup_oracle_vm.sh && sudo ./setup_oracle_vm.sh
set -e

echo "=== 사주MRI Oracle VM 셋업 시작 ==="

# ── 1. 시스템 업데이트 ────────────────────────────────────────────
echo "[1/7] 시스템 업데이트..."
apt-get update -y
apt-get upgrade -y

# ── 2. 자동 보안 업데이트 설정 ────────────────────────────────────
echo "[2/7] 자동 보안 패치 설정..."
apt-get install -y unattended-upgrades
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
systemctl enable --now unattended-upgrades
echo "[2/7] 자동 보안 업데이트 활성화 완료"

# ── 3. Docker 설치 ────────────────────────────────────────────────
if ! command -v docker &> /dev/null; then
    echo "[3/7] Docker 설치 중..."
    apt-get install -y ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    usermod -aG docker ubuntu
    # Docker 로그 회전 설정 (디스크 보호)
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json <<'DOCKEREOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
DOCKEREOF
    systemctl restart docker
    echo "[3/7] Docker 설치 완료"
else
    echo "[3/7] Docker 이미 설치됨"
fi

# ── 4. SSH 강화 ────────────────────────────────────────────────────
echo "[4/7] SSH 보안 강화..."
SSHD_CONFIG="/etc/ssh/sshd_config"
# 비밀번호 인증 비활성화 (공개키 전용)
sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication no/' "$SSHD_CONFIG"
# root SSH 로그인 비활성화
sed -i 's/^#*PermitRootLogin .*/PermitRootLogin no/' "$SSHD_CONFIG"
# 빈 비밀번호 로그인 비활성화
sed -i 's/^#*PermitEmptyPasswords .*/PermitEmptyPasswords no/' "$SSHD_CONFIG"
# X11 포워딩 비활성화
sed -i 's/^#*X11Forwarding .*/X11Forwarding no/' "$SSHD_CONFIG"
systemctl restart ssh
echo "[4/7] SSH 강화 완료 (공개키 인증 전용, root 로그인 차단)"

# ── 5. fail2ban 설치 (SSH 브루트포스 방어) ───────────────────────
echo "[5/7] fail2ban 설치..."
apt-get install -y fail2ban
cat > /etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 5

[sshd]
enabled  = true
port     = ssh
logpath  = %(sshd_log)s
backend  = %(sshd_backend)s
maxretry = 3
EOF
systemctl enable --now fail2ban
echo "[5/7] fail2ban 설치 완료 (SSH 5분 내 3회 실패 시 1시간 차단)"

# ── 6. UFW 방화벽 설정 ─────────────────────────────────────────────
echo "[6/7] 방화벽 설정..."
apt-get install -y ufw
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh                 # SSH (22)
ufw allow 80/tcp              # HTTP  (Nginx → Let's Encrypt ACME)
ufw allow 443/tcp             # HTTPS (Nginx 리버스 프록시)
# ⚠️  8501(Streamlit)과 5432(PostgreSQL)은 외부에 열지 않음
#    Streamlit은 Nginx가 내부(localhost)로만 프록시
#    PostgreSQL은 Docker 내부 네트워크에서만 접근
ufw --force enable
echo "[6/7] UFW 방화벽 설정 완료 (80, 443, SSH만 허용 / 8501·5432 차단)"

# ── 7. iptables 허용 (Oracle VM 기본 차단 해제) ──────────────────
echo "[7/7] iptables 포트 허용..."
apt-get install -y iptables-persistent netfilter-persistent 2>/dev/null || true
iptables -I INPUT 6 -m state --state NEW -p tcp --dport 80  -j ACCEPT
iptables -I INPUT 6 -m state --state NEW -p tcp --dport 443 -j ACCEPT
# SSH는 이미 Oracle 기본 규칙에 포함돼 있으나 명시적으로 추가
iptables -I INPUT 6 -m state --state NEW -p tcp --dport 22  -j ACCEPT
netfilter-persistent save 2>/dev/null || iptables-save > /etc/iptables/rules.v4 || true
echo "[7/7] iptables 설정 완료 (재부팅 후에도 유지)"

# ── 앱 디렉토리 생성 ──────────────────────────────────────────────
mkdir -p /opt/saju-mri
chown ubuntu:ubuntu /opt/saju-mri

echo ""
echo "=== ✅ Oracle VM 셋업 완료 ==="
echo ""
echo "=== ⚠️  Oracle Cloud 콘솔에서도 Ingress 규칙 확인 필요 ==="
echo "  Networking → VCN → Security List → Ingress Rules:"
echo "  - TCP 22   (SSH)"
echo "  - TCP 80   (HTTP)"
echo "  - TCP 443  (HTTPS)"
echo "  ※ 8501(Streamlit), 5432(PostgreSQL)은 추가하지 마세요."
echo ""
echo "=== 다음 단계 ==="
echo "  1. git clone https://github.com/hwakia/saju-web-app.git /opt/saju-mri"
echo "  2. cd /opt/saju-mri"
echo "  3. cp .env.example .env && nano .env   # DB 비밀번호 설정"
echo "  4. docker compose up -d"
echo "  5. docker compose logs -f app          # 시작 확인"
echo ""
echo "=== SSL 인증서 (Let's Encrypt) — 도메인 연결 후 실행 ==="
echo "  snap install --classic certbot"
echo "  certbot --nginx -d 도메인명"
