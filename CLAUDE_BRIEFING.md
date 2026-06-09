# 사주키링 프로젝트 — 새 대화 인수인계 지침

> **새 대화창에 "saju-web-app 폴더의 CLAUDE_BRIEFING.md 읽고 시작해"라고 말하세요.**
> 최종 갱신: 2026-06 (자두 테마 + 맞짱/케미 개편 세션 종료 시점)

---

## 0. 프로젝트 개요

- **앱 이름**: 사주키링 (구 사주끼리 / 사주맞짱 / 사주MRI) — 슬로건 "사주로 보는 우리 사이"
- **GitHub**: https://github.com/hwakia/saju-web-app
- **배포**: Streamlit Cloud (push 시 1~2분 자동 반영). 앱 URL `https://saju-web-app-hwaki.streamlit.app/?app_ok=1`
- **단계**: Google Play **비공개(closed) 테스트** 진행 중. 정식 출시 준비.
- **로컬 경로**: `C:\Users\hwaki\OneDrive\문서\GitHub\saju-web-app`

## 1. 아키텍처 & 데이터 접근

```
Flutter 앱(Android WebView) → Streamlit Cloud(app.py, 미국) → Supabase(PostgreSQL)
```
- 앱은 WebView로 `streamlit.app?app_ok=1` 을 띄움 (app_ok=1 = 동의 게이트 우회)
- **DB는 현재 Supabase** (URL: https://jnukrudxgwgegjclaywr.supabase.co). 케미방/맞짱방/맞짱결과/애널리틱스 저장.
- Streamlit Secrets에 SUPABASE_URL / ANON_KEY / SERVICE_KEY 설정됨
- **데이터 접근 방법**:
  - 코드/텍스트: 로컬 `app.py`(단일 파일 ~28,000줄)가 웹 전부. Read/Edit 도구로 접근.
  - DB 직접 조회는 Supabase 대시보드(사용자 계정). 저장 항목은 아래 9번 참고(최소화돼 있음).
  - 푸시는 PowerShell에서 git (아래 2번).

## 2. ⚠️ 작업 시 핵심 규칙 (꼭 읽기)

- **app.py 수정 = 웹**: `git push`만 하면 즉시 반영. **버전업/빌드 불필요.**
- **saju_mri 폴더 수정 = 앱 껍데기**: 재빌드 + Play Console 새 버전 업로드 필요.
- **"맞짱"은 기능 이름**(대결 기능). 현재 앱 이름은 "사주키링" — 기능명 맞짱은 유지.
- **OneDrive 동기화 함정**: 샌드박스 bash/python이 app.py를 **잘린 채로 읽어**(약 1.33MB에서 truncation) 가짜 SyntaxError/nullbyte가 남. 호스트 파일은 **Edit 도구로 수정하면 정상**. grep(라인 기반)은 전체를 읽지만 python `open().read()`는 실패할 수 있음.
- **샌드박스 Python은 3.10, 프로덕션은 3.12+**. 이 앱은 `f"...{josa(x, "이/가")}..."` 같은 **3.12 전용 중첩 따옴표 f-string**을 다수 사용 → 샌드박스 `ast.parse`는 **항상 "f-string: unmatched (" 오탐**. 진짜 문법검증은 **PowerShell(3.12)**:
  - `python -c "import ast; ast.parse(open('app.py',encoding='utf-8').read()); print('APP OK')"`
- **.git/index.lock** 생기면 PowerShell에서 `del .git\index.lock` 먼저.
- **git push는 PowerShell에서** (샌드박스 push 불가).

표준 push:
```powershell
cd C:\Users\hwaki\OneDrive\문서\GitHub\saju-web-app
python -c "import ast; ast.parse(open('app.py',encoding='utf-8').read()); print('APP OK')"
git add app.py .streamlit/config.toml
git commit -m "..."
git push
```

## 3. 빌드/배포 절차 (Flutter 앱 — 아이콘/앱명/네이티브 변경 시에만)

영문 경로 `C:\dev\saju-battle`에서 빌드(한글·OneDrive 경로 문제 회피):
```powershell
robocopy "...\saju_mri\lib" "C:\dev\saju-battle\lib" /E
robocopy "...\saju_mri\android\app\src\main\res" "C:\dev\saju-battle\android\app\src\main\res" /E
robocopy "...\saju_mri\assets" "C:\dev\saju-battle\assets" /E
Copy-Item "...\saju_mri\android\app\src\main\AndroidManifest.xml" "C:\dev\saju-battle\..." -Force
Copy-Item "...\saju_mri\pubspec.yaml" "C:\dev\saju-battle\pubspec.yaml" -Force
cd C:\dev\saju-battle; flutter clean; flutter build appbundle --release
```
- AAB: `C:\dev\saju-battle\build\app\outputs\bundle\release\app-release.aab`
- 패키지명: **com.hwakia.saju** (고정). keystore: `saju_mri/android/key.properties` + `my-release-key.jks`
- 출시 노트: `<ko-KR>내용</ko-KR>` 형식
- 직접 mipmap을 만들어 둔 상태라 `flutter_launcher_icons` 실행 불필요.

## 4. 현재 버전 상태

- pubspec: **1.0.13+14** (앱명 사주키링 + 키링 음양 아이콘). 이 버전 빌드/업로드가 마지막 앱 작업.
- **이번 세션의 모든 기능·디자인·텍스트 변경은 전부 app.py(웹)** → push만 하면 됨. 앱 빌드는 추가로 필요 없음.

## 5. 이번 세션 주요 변경 (전부 웹 = app.py)

1. **앱명 사주끼리 → 사주키링** 전면(타이틀/처리방침/공유카드/앱 라벨·동의화면 등). 기능명 맞짱은 유지.
2. **키링 음양 아이콘** — 골드 스플릿 링 + 골드 볼체인(이중 S커브) + 음양 글래스 구체. 전 해상도 mipmap/적응형/스플래시 + store_icon_512 + feature_graphic_1024x500 갱신. (생성 스크립트: `Downloads\make_feature_graphic.ps1`, 아이콘은 cairosvg로 렌더했음)
3. **자두 퍼플 테마** — 베이스 #241327, 카드 #36213c/#2b1830/#2e1b33/#3a2433, 트랙 #1c0e20. 골드 #f0c75a/#e9c068/#fde68a, 코랄 #e8738f. config.toml(bg #241327, secondary #36213c, primary #e8738f)도 변경. 콜아웃 글자(보라/녹/청/레드)·뮤트 텍스트 밝게, 밝은 크림 카드(today-quick/battle-board/pick-sealed/share-card 등) 자두로 전환. 공유 PNG 4종(진단서·심플첫공유·케미·맞짱결과)도 자두+골드. **WCAG 대비 검증 완료(전부 통과)**.
4. **친근체 통일** — 일운/예보, 신살 해설 사전, 일간강약, 통관/통로, 등급 설명, 케미 합충 해설, 맞짱 다축 리포트, 캐릭터 tips 등 결과·해설 텍스트(약 100+곳)를 "~야/~어" 친근체로. **처리방침·시스템/오류 메시지는 격식 유지**(범위: 결과·해설만).
5. **복음(伏吟)·반음(反吟)** — `today_compass_payload`(약 17796~)에 일운 간지가 원국 일주(주)/월주(보조)와 동일=복음, 정반대 충=반음 감지 추가. 합충 칩 + 처방 설명에 반영.
6. **맞짱 개편**:
   - 상극 대결 서사 `_battle_versus`(오행 상극/맞불/상생, 참가자 dom_el 기반)
   - 승자 히어로 카드 + **시상대(podium, top3)** + 점수 막대·관계 태그
   - 점수 공식 B(변동폭↑): 4운 가중치 8/12/18/26, base 38~72, **소수 1자리 반환**(`calculate_battle_power -> float`) → 동점 자동 해소
   - **1점 이내 동점 시 오행 상극 1:1 타이브레이커** `_battle_rank_sort`(net 극으로 정렬, 순환 모순 방지)
   - "오늘의 운세 대결(매일 바뀜)" 안내 3곳(생성/결과/공유PNG)
   - 저장에 **대표 오행 dom_el/weak_el** 추가(`_extract_battle_participant_data`)
7. **초대 케미(모임 케미 방) 복구** — 기존 `_reconstruct_payload_from_room_participant` **미정의 NameError로 그룹진단 크래시 + 결과 빈화면** 버그를:
   - 참가자 **인코딩 토큰(t)을 방 DB에 임시 저장**(`_extract_participant_data`)
   - `_reconstruct_payload_from_room_participant` 정의(토큰 디코드 → `analyze()` 재분석으로 오행 분포 복원)
   - 결과 화면이 저장본 없으면 **DB 토큰으로 즉석 계산**(마지막 입장자 의존 제거), 그룹진단도 동일
   - 매트릭스 aliasing 버그 수정
8. **방 보관 30분 원칙** — `sb_cleanup_expired_rooms`를 만료 즉시 삭제로(기존 만료+1시간 유예 제거). 동의/처리방침/에러 메시지의 "24시간" → "30분"으로 통일. 케미 토큰은 방과 함께 자동삭제.

## 6. 미해결 / 다음 작업 후보 (중요)

- **🔴 처리방침 사실 불일치 (우선 처리 권장)**: 처리방침(약 6927~6931)이 *"DB가 국내(춘천)에 있어 국외이전 없음"* 이라고 적혀 있으나 **실제 DB는 Supabase**(춘천 오라클 아직 미획득). 현재는 계산=Streamlit Cloud(미국) + 저장=Supabase(해외 사업자)라 **실제로 국외 처리/이전 발생** → 정책이 과소고지 상태. **현재 사실(Supabase/Streamlit 미국)에 맞게 정정 필요.** Supabase 리전(서울 vs 미국) 확인 후 문구 작성.
  - 참고: 나중에 국내 자체서버로 이전 시 국외→국내 **축소**라 통상 재동의 불필요(목적·항목 불변 + 처리방침 갱신·고지). 단 지금 "국외이전 없음"으로 미리 적어두면 현재가 거짓고지가 됨.
- **테스터 12명/14일**: 출시 핵심 과제. 옵트인 링크는 `https://play.google.com/apps/testing/com.hwakia.saju` (store/details 링크 아님!). 카운트가 줄면 옵트인 취소·계정 불일치 의심. 여유 있게 14~15명 권장.
- **Oracle Cloud A1 VM(춘천 자체서버)**: 무료 티어 아직 미획득(2 OCPU/12GB 루프 중). 잡으면 Supabase→자체 Postgres 이전 가능. 급하지 않음.
- 톤 분리(친근체↔전문 expander) 설계안(docs/톤_분리_설계검토.md) — 일부만 적용.
- 카톡 링크 미리보기 썸네일(옛 MRI 로고) — Streamlit 구조상 OG 태그 못 박음. 카카오 캐시 초기화로만 해소.

## 7. 핵심 기능별 코드 위치 (대략 줄번호 — 수정 시 grep로 재확인)

- 맞짱 점수: `def calculate_battle_power`(~14686, float 반환)
- 맞짱 타이브레이커: `def _battle_rank_sort`(~15895), 상극서사 `def _battle_versus`
- 맞짱 결과뷰: `def _render_battle_room_result_view`(~15979), 공유PNG `def make_battle_result_png_bytes`(~20023)
- 맞짱 저장: `def _extract_battle_participant_data`(~15113, dom_el 포함)
- 케미 결과뷰: `def _render_room_result_view`(~15414), 복원 `def _reconstruct_payload_from_room_participant`
- 케미 저장: `def _extract_participant_data`(토큰 t 포함), 계산 `def _compute_and_store_room_chemistry`
- 케미 그룹진단: `def group_chemistry_analysis`(~21102)
- 방 정리: `def sb_cleanup_expired_rooms`(~14781, 30분)
- 일운/예보 + 복음반음: `def today_compass_payload`(~17796)
- 처리방침: `def` 개인정보 처리방침(~6874~7010), 국외이전 조항 6927~6931
- 테마 색: app.py 전역 하드코딩(#241327 등) + `.streamlit/config.toml`

## 8. 참고 문서 (docs 폴더)

- `docs/버전업_수정이력.md` — 버전별 변경 이력
- `docs/톤_분리_설계검토.md` — 친근체/전문체 분리 설계안

## 9. 개인정보 저장 항목 요약 (현재, 코드 기준)

- 원본 생년월일시·성별: **DB 미저장**(계산 순간 메모리에만)
- Supabase 저장: 별명, 점수·등급, 대표 오행, (케미만) 간지 인코딩 토큰 — **30분 TTL 자동삭제**
- 애널리틱스: session_id·event_name·page_name·source·app_version·is_admin (개인식별 PII 없음)
- 광고(앱): AdMob → Google LLC(미국) GAID 수집 = 별도 국외이전(앱 최초 동의)
