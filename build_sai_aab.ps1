# ============================================================
#  SAI 앱번들(AAB) 빌드 스크립트
#  사용법: PowerShell에서  powershell -ExecutionPolicy Bypass -File .\build_sai_aab.ps1
#  (또는 PowerShell 창에서  .\build_sai_aab.ps1  실행)
#  - 레포의 최신 아이콘/리소스/코드를 빌드 폴더에 동기화
#  - 캐시 완전 제거 후 release AAB 빌드
#  - 서명은 C:\dev\saju-battle\android\key.properties + my-release-key.jks 로 자동 처리
# ============================================================

$SRC = "C:\Users\hwaki\OneDrive\문서\GitHub\saju-web-app\saju_mri"
$DST = "C:\dev\saju-battle"

Write-Host "[1/6] lib / res / assets / pubspec / Manifest 동기화..." -ForegroundColor Cyan
robocopy "$SRC\lib" "$DST\lib" /E | Out-Null
robocopy "$SRC\android\app\src\main\res" "$DST\android\app\src\main\res" /E | Out-Null
robocopy "$SRC\assets" "$DST\assets" /E | Out-Null
Copy-Item "$SRC\android\app\src\main\AndroidManifest.xml" "$DST\android\app\src\main\AndroidManifest.xml" -Force
Copy-Item "$SRC\pubspec.yaml" "$DST\pubspec.yaml" -Force

Write-Host "[2/6] 현재 버전(versionCode는 + 뒤 숫자, 14보다 커야 함):" -ForegroundColor Cyan
Select-String -Path "$DST\pubspec.yaml" -Pattern "^version:"
Write-Host "      => Play에서 '이미 사용된 버전'이라고 하면 pubspec.yaml의 +숫자를 16,17.. 로 올리고 다시 실행." -ForegroundColor DarkYellow

Write-Host "[3/6] 빌드 폴더 아이콘 확인(육안): $DST\android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png" -ForegroundColor Cyan

Write-Host "[4/6] flutter clean + build 캐시 제거..." -ForegroundColor Cyan
Set-Location $DST
flutter clean
if (Test-Path "$DST\build") { Remove-Item -Recurse -Force "$DST\build" }

Write-Host "[5/6] flutter pub get..." -ForegroundColor Cyan
flutter pub get

Write-Host "[6/6] release AAB 빌드..." -ForegroundColor Cyan
flutter build appbundle --release

$aab = "$DST\build\app\outputs\bundle\release\app-release.aab"
if (Test-Path $aab) {
    Write-Host "`n[OK] 빌드 완료:" -ForegroundColor Green
    Get-Item $aab | Select-Object FullName, @{N='MB';E={[math]::Round($_.Length/1MB,2)}}, LastWriteTime | Format-List
    Write-Host "이 파일을 Play Console 비공개 테스트 트랙에 업로드하면 됩니다." -ForegroundColor Green
} else {
    Write-Host "`n[ERROR] AAB가 생성되지 않았습니다. 위 빌드 로그의 에러 메시지를 확인하세요." -ForegroundColor Red
}
