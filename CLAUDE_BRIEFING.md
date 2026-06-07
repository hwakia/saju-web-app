# 사주키링 프로젝트 — 새 대화 인수인계 지침

> **이 파일을 새 대화창에 붙여넣거나, "saju-web-app 폴더의 CLAUDE_BRIEFING.md 읽고 시작해"라고 말하세요.**

---

## 0. 프로젝트 개요

- **앱 이름**: 사주키링 (구 사주끼리 / 사주맞짱 / 사주MRI) — 슬로건 "사주로 보는 우리 사이"
- **GitHub**: https://github.com/hwakia/saju-web-app
- **배포**: Streamlit Cloud (push 시 1~2분 자동 반영). 앱 URL `https://saju-web-app-hwaki.streamlit.app/?app_ok=1`
- **단계**: Google Play **비공개(closed) 테스트** 진행 중. 정식 출시 준비.
- **로컬 경로**: `C:\Users\hwaki\OneDrive\문서\GitHub\saju-web-app`

## 1. 아키텍처

```
Flutter 앱 (Android WebView)  →  Streamlit Cloud(app.py, 미국)  →  Supabase(PostgreSQL)
- 앱은 WebView로 streamlit.app?app_ok=1 을 띄움 (app_ok=1 = 동의 게이트 우회)
- DB: 케미방/맞짱방/맞짱결과/애널리틱스. supabase-py 사용
- Supabase URL: https://jnukrudxgwgegjclaywr.supabase.co
- Streamlit Secrets에 SUPABASE_URL / ANON_KEY / SERVICE_KEY 설정됨
```

## 2. ⚠️ 작업 시 핵심 규칙

- **app.py 수정 = 웹**: `git push`만 하면 모든 사용자에게 즉시 반영. 빌드 불필요.
- **saju_mri 폴더 수정 = 앱 껍데기**: 재빌드 + Play Console 새 버전 업로드 필요.
- **"맞짱"은 기능 이름** (대결 기능). 현재 앱 이름은 "사주키링" — 기능명 맞짱은 그대로 둘 것.
- **OneDrive 동기화 함정**: 샌드박스 bash가 app.py를 잘린 채로 읽어 가짜 SyntaxError/nullbyte가 자주 남. 호스트 파일은 Edit 도구로 수정하면 정상. **push 전 PowerShell에서 반드시 문법 검증**:
  `python -c "import ast; ast.parse(open('app.py',encoding='utf-8').read()); print('APP OK')"`
- **.git/index.lock** 생기면 PowerShell에서 `del .git\index.lock` 먼저.
- **git push는 PowerShell에서** (샌드박스 push 불가).

## 3. 빌드/배포 절차 (Flutter 앱)

빌드는 한글·OneDrive 경로 문제로 **영문 경로 `C:\dev\saju-battle`** 에서 함:
```powershell
robocopy "C:\Users\hwaki\OneDrive\문서\GitHub\saju-web-app\saju_mri\lib" "C:\dev\saju-battle\lib" /E
robocopy "C:\Users\hwaki\OneDrive\문서\GitHub\saju-web-app\saju_mri\android\app\src\main\res" "C:\dev\saju-battle\android\app\src\main\res" /E
robocopy "C:\Users\hwaki\OneDrive\문서\GitHub\saju-web-app\saju_mri\assets" "C:\dev\saju-battle\assets" /E
Copy-Item "C:\Users\hwaki\OneDrive\문서\GitHub\saju-web-app\saju_mri\android\app\src\main\AndroidManifest.xml" "C:\dev\saju-battle\android\app\src\main\AndroidManifest.xml" -Force
Copy-Item "C:\Users\hwaki\OneDrive\문서\GitHub\saju-web-app\saju_mri\pubspec.yaml" "C:\dev\saju-battle\pubspec.yaml" -Force
cd C:\dev\saju-battle; flutter clean; flutter build appbundle --release
```
- AAB 위치: `C:\dev\saju-battle\build\app\outputs\bundle\release\app-release.aab`
- 패키지명: **com.hwakia.saju** (변경 불가 — 이걸로 빌드해야 업로드됨)
- keystore: `saju_mri/android/key.properties` + `my-release-key.jks` (상대경로라 복사해도 작동)
- 출시 노트 형식: `<ko-KR>내용</ko-KR>` (언어 태그 필수)

## 4. 현재 버전 상태

- pubspec: **1.0.13+14** (앱명 사주끼리 → **사주키링** 변경). 이 버전 빌드/업로드 필요.
- 버전코드는 13까지 사용 예정 → 다음 빌드는 14(=1.0.13) 이상으로 올려야 업로드 가능.
- **app.py 미push 변경**: 브랜드명 사주키링 일괄 교체 + 맞짱방/케미방 초대 메시지·안내 배너 + 맞짱 결과 이미지 공유. push 필요:
  `git add -A; git commit -m "feat: 앱명 사주키링 변경 + 초대 안내/결과 이미지"; git push`

## 5. 이번 세션 주요 변경 이력 (상세는 docs/버전업_수정이력.md)

**웹(app.py, push로 반영)**:
- 네비/탭 버튼 가로배열(st.segmented_control), 내 사주 localStorage 영구저장,
  모임케미 공유링크 nullsrcdoc 오류 수정, 1:1 케미 결과 빈화면 복원,
  종합예보 일운 문단 추가, 4운 합충에 형·해·파 추가(일지+년지 이중기준),
  신살 보강(현침/양인/괴강/백호), 용신·기신 모순 수정, 시인성/친근체 개선,
  만료방 자동삭제, 처리방침 닫기버튼, 첫화면 공지 제거, 사주예보 메뉴 순서변경,
  앱명 사주키링(서비스명/타이틀/처리방침 — 기능명 맞짱은 유지).

**앱(saju_mri, 빌드 필요)**:
- 동의화면 스크롤 수정, 스플래시 제거, 뒤로가기 WebView 연동+종료 개선,
  연결 끊김 자동복구, 광고 빈도 5→10, 앱명 사주키링, 아이콘 전면 교체.
- **최종 아이콘**: 비비드 글래스 음양(노을 그라데이션 배경 + 흰/보라 음양, 블러).
  적응형 XML(mipmap-anydpi-v26/ic_launcher.xml)에서 inset 제거, 배경=전경 처리.

## 6. 스토어 등록정보 (Play Console에서 직접 업로드 — 빌드와 별개)

- 앱 아이콘 512: `saju-web-app/store_icon_512.png` (비비드 글래스 음양)
- 그래픽 1024x500: `saju-web-app/feature_graphic_1024x500.png` (노을+사주키링)
- **앱 이름**: 콘솔 기본 스토어 등록정보에서 "사주키링"으로 직접 변경 필요
- 한글 그래픽 재생성 필요시: Noto Sans CJK KR 폰트가
  `Downloads/저작권법_검토요청.../03_폰트(선택사항)/` 폴더에 있음. PIL로 렌더 가능.

## 7. 가장 급한 과제 (출시까지)

1. **테스터 12명 채우기** (현재 약 7명). 본인 제외 12명 권장. 안드로이드 유저만 유효.
   - Play Console 대시보드 "앱 테스트 요구사항" 카드에서 진행상황 확인.
   - 12명 옵트인된 날부터 **14일 연속** 유지돼야 프로덕션 신청 가능.
2. 14일 충족 → 프로덕션 액세스 신청 (테스트 피드백·개선 서술 필요 → docs 이력 활용).
3. 프로덕션 전 스토어 아이콘/그래픽/앱이름 교체 확인.

## 8. Oracle Cloud VM (선택 — 출시와 무관한 보너스)

- 무료 A1 VM 받으려고 PC에서 OCI CLI 루프 실행 중. **현재 2 OCPU/12GB**로 도전(4/24는 일주일+ 실패).
- OCI CLI 인증 완료됨(passphrase 없는 키, config 저장, 공개키 콘솔 등록 완료).
- 실행: `Downloads\오라클_루프_시작.bat` 더블클릭 (oci_loop2.ps1 호출, 2/12 사양).
  바탕화면에도 꺼내둠. 절전 끄기 영구 설정됨. VM 잡히면 삑삑 소리. 로그: `~/oci_loop.log`.
- 용도: 잡으면 사주키링+다른 앱 돌리는 범용 서버. 급하지 않음.

## 9. 알려진 이슈 / 다음 후보

- 톤 분리(친근체↔전문체) 설계안 검토 완료(docs/톤_분리_설계검토.md). 미적용.
  → 진단서=순수 친근체 / 상세=전문 expander 이동. 케미는 이미 모범구현 상태.
- 작은 화면(48px)에서 아이콘 디테일 뭉개짐(모든 정교한 아이콘의 숙명).

## 10. 참고 문서 (docs 폴더)

- `docs/버전업_수정이력.md` — 1.0.1~1.0.12 버전별 상세 변경 이력
- `docs/톤_분리_설계검토.md` — 친근체/전문체 분리 설계안
