$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$flutter = 'C:/Users/srika.DESKTOP-N0D5PTP.000/develop/flutter/bin/flutter.bat'
$previousUiTest = $env:CHESSVERSE_UI_TEST
Push-Location (Join-Path $projectRoot 'mobile')
try {
    $env:CHESSVERSE_UI_TEST = 'true'
    & $flutter build apk --debug --no-pub --target-platform android-arm64 '--dart-define=API_BASE_URL=https://api.chessverseai.com'
    if ($LASTEXITCODE -ne 0) { throw "Test APK build failed: $LASTEXITCODE" }
    Write-Host 'Cloud API test APK ready. Firebase auth/push for the .uitest package requires separate configuration; this build does not verify those services.'
} finally {
    $env:CHESSVERSE_UI_TEST = $previousUiTest
    Pop-Location
}
