# 사주MRI 프로젝트 — 새 대화 시작용 지침

## 프로젝트 개요
- **앱 이름**: 사주 맞짱 (사주MRI)
- **GitHub**: https://github.com/hwakia/saju-web-app
- **배포**: Streamlit Cloud (자동 배포, push하면 1~2분 내 반영)
- **Flutter 앱**: Play Store 출시 준비 중 (WebView 기반)
- **로컬 경로**: `C:\Users\hwaki\OneDrive\문서\GitHub\saju-web-app`

---

## 현재 아키텍처

```
Flutter 앱 (Android WebView)
    ↓ ?app_ok=1 파라미터로 접속
Streamlit Cloud (app.py) — 미국 서버
    ↓ psycopg2 → supabase-py로 전환 완료
Supabase (PostgreSQL) — 맞짱/케미방 데이터
    URL: https://jnukrudxgwgegjclaywr.supabase.co
```

---

## Streamlit Cloud Secrets (이미 설정됨)
```toml
SUPABASE_URL = "https://jnukrudxgwgegjclaywr.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

## Supabase 테이블 (이미 생성됨)
- `chemistry_rooms` — 케미 방
- `battle_rooms` — 맞짱 방
- `battles` — 맞짱 결과
- `app_events` — 애널리틱스

---

## 최근 완료된 작업 (정상 작동)

### ✅ Supabase 연결 수정 (commit: bed9b73)
- `psycopg2` → `supabase-py`로 전환
- `requirements.txt`: `psycopg2-binary` → `supabase`
- 맞짱방/케미방/애널리틱스 DB 함수 전면 재작성

### ✅ 오행 칩 시인성 개선
- 텍스트 색상 검정(`#111111`)으로 변경
- 금(金) 셀 배경: 다크 스틸 블루(`#3a3c50`)

### ✅ 내 사주 진단 입력 화면
- "용어 뜻 —" 텍스트 제거 (quest_title에서 terms 파라미터 제거)

### ✅ 내 사주 불러오기 (session_state 기반)
- 분석 완료 + "내 사주 브라우저에 저장" 체크 시 → `st.session_state["_my_saju_saved_url_v1"]`에 저장
- 입력 페이지 재진입 시 → `st.button("⭐ 저장된 내 사주 바로 불러오기")` 표시

---

## 미해결 문제 (핵심 과제)

### ❌ Flutter WebView에서 st.columns() 버튼이 세로로 쌓임

**증상**: 결과 화면의 네비게이션 버튼(메인/진단/케미/모임/맞짱)과 탭 버튼(진단서/사주예보/원국/상세)이 세로로 쌓임

**근본 원인 분석**:
1. `st.components.v1.html()` 안에서 CSS/JavaScript를 주입해도 Flutter WebView에서 `window.parent.document` 접근이 차단됨
2. `st.markdown()` CSS도 `!important` 써도 Streamlit 자체 CSS가 덮어씀
3. `window.parent.location.href` 네비게이션도 Flutter WebView에서 차단됨

**시도했으나 실패한 것들**:
- CSS 임계값 변경 (360px → 320px)
- `st.columns()` 전역 flex CSS 주입
- HTML flexbox 버튼 (시각적으로는 가로지만 클릭 이벤트가 Streamlit에 전달 안 됨)
- `window.parent.location.href`로 URL 변경 후 query_params 처리

**현재 상태**: `render_mode_jump_buttons()`와 `render_single_page_buttons()`는 `st.button()` + `st.columns()` 그대로 유지 중. 기능은 작동하지만 시각적으로 세로로 쌓임.

**가능한 해결 방향**:
1. **`st.tabs()` 사용** (탭 메뉴에 한해): `st.columns()` 대신 `st.tabs()` 사용하면 Streamlit이 자체적으로 가로 배열 보장. 단 내용이 모두 렌더링됨.
2. **Flutter 앱 수정**: `home_screen.dart`의 WebView 설정에서 JavaScript 채널 추가하여 state 변경 허용
3. **`st.radio(horizontal=True)` 사용**: 탭처럼 동작하는 가로 라디오 버튼

---

## 중요 함수 위치 (app.py)

| 함수 | 줄 번호 | 설명 |
|------|---------|------|
| `render_mode_jump_buttons()` | ~11842 | 결과 화면 상단 네비 (메인/진단/케미/모임/맞짱) |
| `render_single_page_buttons()` | ~22342 | 결과 탭 (진단서/사주예보/원국/상세) |
| `render_my_saju_browser_storage_widget()` | ~11442 | 내 사주 저장/불러오기 위젯 |
| `render_my_saju_save_link_tool()` | ~11528 | 저장 트리거 (결과 화면에서 호출) |
| `_get_pg()` | ~3608 | Supabase 클라이언트 반환 |
| `sb_create_battle_room()` | ~14791 | 맞짱 방 생성 |
| `sb_create_room()` | ~14655 | 케미 방 생성 |

---

## Flutter 앱 경로
- `C:\Users\hwaki\OneDrive\문서\Claude\Projects\사주MRI 플레이스토어 앱 출시\saju_mri`
- `lib/screens/home_screen.dart` — WebView 설정
- `lib/screens/consent_screen.dart` — 동의 화면

## Git 작업 시 주의사항
- index.lock 파일이 생길 수 있음: `del .git\index.lock` 먼저 실행
- 샌드박스에서 git push 안 됨 → 항상 PowerShell에서 push
- LF/CRLF 경고는 무시해도 됨

---

## 새 대화에서 할 수 있는 작업 제안

1. **Flutter WebView st.columns 문제 근본 해결**
   - `home_screen.dart`에 `JavascriptChannel` 추가 → JavaScript에서 Flutter로 메시지 전달 가능하게
   - 또는 `st.tabs()` 전면 도입

2. **Play Store 출시 준비**
   - AAB 빌드 (`flutter build appbundle --release`)
   - Play Console 스토어 등록정보 작성
   - 스크린샷 준비

3. **Oracle Cloud VM 설정 (선택)**
   - 국내 서버 이전용 (개인정보보호법 준수)
   - Oracle Cloud Shell에서 루프 실행 중이었으나 진행 안 됨
