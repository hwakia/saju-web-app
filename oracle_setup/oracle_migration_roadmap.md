# 사주MRI — Oracle Cloud Seoul 마이그레이션 로드맵

> **목표**: Supabase(미국) → Oracle Cloud Seoul (ap-seoul-1)
> **이유**: 개인정보보호법 제28조의8 국외 이전 리스크 제거
> **비용**: ₩0 (Oracle Always Free Tier) · 데이터 위치: 서울
> **현재 상태**: 코드 교체 완료 (v5.219), 인프라 파일 준비 완료

---

## 아키텍처

```
사용자 (스마트폰/PC)
       ↓  HTTPS
Oracle ARM VM (ap-seoul-1)   ← 월 ₩0 · 4코어 24GB
  ├── Nginx (80/443)
  ├── Streamlit 앱 (Docker, port 8501)
  └── PostgreSQL DB (Docker, port 5432 내부)
```

---

## 단계별 로드맵

### 단계 1 — Oracle Cloud 계정 및 VM 준비 (사용자 직접, 약 1시간)

**1.1 계정 생성**
- https://cloud.oracle.com 접속
- 회원가입 시 **Region: ap-Seoul-1 (서울)** 반드시 선택
- 신용카드 등록 필요 (과금 없는 Always Free 확인)

**1.2 Always Free ARM VM 생성**
- Compute → Instances → Create Instance
- Image: Ubuntu 22.04 (Canonical)
- Shape: `VM.Standard.A1.Flex` (Ampere A1 ARM)
  - OCPUs: **4** / Memory: **24 GB** (Always Free 최대치)
- 네트워킹: 새 VCN 자동 생성
- SSH 키: 기존 키 업로드 또는 새로 생성 후 저장
- Boot Volume: 50GB (기본값)

**1.3 보안 그룹(Ingress Rules) 추가**
Oracle Cloud 콘솔 → Networking → VCN → Security List → Ingress Rules:

| 프로토콜 | 포트 | 설명 |
|---------|------|------|
| TCP | 22   | SSH |
| TCP | 80   | HTTP |
| TCP | 443  | HTTPS (SSL) |
| TCP | 8501 | Streamlit 직접 테스트용 (선택) |

---

### 단계 2 — VM 환경 구성 (스크립트 제공, 약 30분)

SSH 접속 후 셋업 스크립트 실행:

```bash
ssh -i ~/.ssh/your_key.pem ubuntu@[VM_PUBLIC_IP]

# 리포지토리 클론
git clone https://github.com/hwakia/saju-web-app.git /opt/saju-mri
cd /opt/saju-mri

# 셋업 스크립트 (Docker 설치 + 방화벽)
sudo chmod +x oracle_setup/setup_oracle_vm.sh
sudo ./oracle_setup/setup_oracle_vm.sh
```

완료 후 **재로그인** (docker 그룹 적용):
```bash
exit
ssh -i ~/.ssh/your_key.pem ubuntu@[VM_PUBLIC_IP]
```

---

### 단계 3 — 환경 변수 설정 및 앱 실행 (약 10분)

```bash
cd /opt/saju-mri

# .env 파일 생성
cp .env.example .env
nano .env
```

`.env` 파일 내용:
```
POSTGRES_PASSWORD=강력한비밀번호_여기입력
ADMIN_KEY=관리자키_여기입력
```

```bash
# 앱 실행
docker compose up -d

# 로그 확인
docker compose logs -f app
```

브라우저에서 `http://[VM_PUBLIC_IP]` 접속 확인.

---

### 단계 4 — SSL 인증서 발급 (도메인 있을 경우, 약 15분)

도메인 DNS → VM Public IP 연결 후:

```bash
# nginx.conf에서 도메인 설정
nano oracle_setup/nginx.conf
# server_name _ 를 실제 도메인으로 변경

# certbot으로 SSL 발급
docker compose run --rm certbot certonly \
  --webroot -w /var/www/certbot \
  -d yourdomain.com -d www.yourdomain.com \
  --email your@email.com --agree-tos

# nginx.conf에서 HTTPS 블록 주석 해제 후 재시작
docker compose restart nginx
```

---

### 단계 5 — Streamlit Cloud 비밀(Secrets) 업데이트

Oracle VM으로 DB를 이전한 뒤, **Streamlit Cloud에서도 Oracle PostgreSQL을 사용**하게 설정할 수 있습니다 (Streamlit Cloud → Oracle DB 직접 연결).

Streamlit Cloud → Settings → Secrets:
```toml
# 기존 Supabase 키 삭제 후:
ADMIN_KEY = "관리자키"
PG_DATABASE_URL = "postgresql://saju_app:비밀번호@[VM_PUBLIC_IP]:5432/saju_db"
```

이 경우 PostgreSQL 포트 5432를 외부에 추가로 열어야 합니다:
- Oracle Security List에 TCP 5432 Ingress 추가
- `docker-compose.yml`의 postgres 서비스에 `ports: ["5432:5432"]` 추가

---

## 파일 구조

```
saju-web-app/
├── app.py                        ← 메인 앱 (v5.219, psycopg2 기반)
├── requirements.txt              ← supabase 제거, psycopg2-binary 추가
├── Dockerfile                    ← Streamlit 앱 컨테이너
├── docker-compose.yml            ← 전체 스택 (PostgreSQL + 앱 + Nginx)
├── .env.example                  ← 환경변수 템플릿
└── oracle_setup/
    ├── init.sql                  ← DB 스키마 (자동 적용)
    ├── nginx.conf                ← Nginx 설정
    ├── streamlit_config.toml     ← Streamlit 서버 설정
    ├── setup_oracle_vm.sh        ← VM 초기화 스크립트
    └── oracle_migration_roadmap.md  ← 이 파일
```

---

## 코드 변경 내역 (v5.218 → v5.219)

| 항목 | 변경 전 | 변경 후 |
|------|---------|---------|
| DB 클라이언트 | `supabase` Python 패키지 | `psycopg2-binary` |
| 연결 방식 | Supabase REST API (HTTP) | 직접 PostgreSQL TCP 연결 |
| 환경 변수 | `SUPABASE_URL` + `SUPABASE_ANON_KEY` | `PG_DATABASE_URL` 하나 |
| 데이터 위치 | Supabase 미국 서버 | Oracle Cloud **서울** |
| Analytics | HTTP REST → Supabase | psycopg2 → PostgreSQL |
| 에러 메시지 | "Supabase 연동 필요" | "PG_DATABASE_URL 설정 필요" |
| requirements.txt | `supabase` | `psycopg2-binary` |

---

## 비용 비교

| 항목 | Supabase Free | Oracle Free |
|------|--------------|-------------|
| DB 서버 위치 | 미국 (법적 리스크) | **서울** ✅ |
| 월 비용 | ₩0 | **₩0** |
| RAM | 500MB | **24GB** |
| CPU | 공유 | **4코어 ARM** |
| 스토리지 | 500MB | **50GB** |
| 만료 | 없음 | **없음 (Always Free)** |
| 개인정보보호법 | ⚠️ 국외 이전 리스크 | ✅ 국내 처리 |
