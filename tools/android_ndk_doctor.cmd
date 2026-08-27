@echo off
REM ============================================================================
REM  android_ndk_doctor.cmd - NDK diagnosis for wedding_time (run from anywhere)
REM
REM  Prints exactly where every potential android.ndkVersion source lives:
REM    [1] repo commit + working tree state
REM    [2] every ndkVersion / 27.0.12077973 / flutter.ndkVersion pin in the repo
REM    [3] the machine-global %USERPROFILE%\.gradle\gradle.properties (if any)
REM    [4] android\local.properties (sdk.dir / ndk.dir / flutter.sdk)
REM    [5] every NDK installed under <sdk>\ndk\ (reads Pkg.Revision)
REM  ...and prints the exact fix commands for the [CXX1104] ndk.dir vs
REM  android.ndkVersion mismatch.
REM
REM  Repo gradle logic (android\build.gradle.kts) picks, in order:
REM    ndk.dir revision  >  27.0.12077973 IF installed  >  newest installed  >  none
REM  so after this doctor, run:  tools\android_build_release.cmd
REM ============================================================================
setlocal EnableExtensions
chcp 65001 >nul
cd /d "%~dp0.."
echo ============================================================
echo  wedding_time - ANDROID NDK DOCTOR
echo  repo: %cd%
echo ============================================================

echo.
echo [1] repo state
echo ------------------------------------------------------------
git log --oneline -1
git status --short
echo.

echo [2] ndkVersion pins inside the repo (android folder)
echo ------------------------------------------------------------
echo search: ndkVersion / 27.0.12077973 / flutter.ndkVersion
findstr /s /n /i "ndkVersion 27.0.12077973" android\*.kts android\*.properties 2>nul
echo.

echo [3] machine-global gradle properties (outside the repo!)
echo ------------------------------------------------------------
if exist "%USERPROFILE%\.gradle\gradle.properties" (
    echo file: %USERPROFILE%\.gradle\gradle.properties
    findstr /i "ndk" "%USERPROFILE%\.gradle\gradle.properties" 2>nul
) else (
    echo no file: %USERPROFILE%\.gradle\gradle.properties
)
echo.

echo [4] android\local.properties
echo ------------------------------------------------------------
if exist "android\local.properties" (
    findstr /i "sdk.dir ndk.dir flutter.sdk" "android\local.properties" 2>nul
) else (
    echo missing: android\local.properties
)
echo.

echo [5] SDK + installed NDKs
echo ------------------------------------------------------------
set "SDK_DIR="
for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "$m = Select-String -LiteralPath 'android\local.properties' -Pattern '^sdk\.dir\s*=\s*(.+?)\s*$' -ErrorAction SilentlyContinue; if ($m) { $m.Matches[0].Groups[1].Value -replace '\\\\','\' -replace '\\:',':' }"`) do set "SDK_DIR=%%i"
if not defined SDK_DIR if defined ANDROID_HOME set "SDK_DIR=%ANDROID_HOME%"
if not defined SDK_DIR if defined ANDROID_SDK_ROOT set "SDK_DIR=%ANDROID_SDK_ROOT%"
if not defined SDK_DIR if defined LOCALAPPDATA set "SDK_DIR=%LOCALAPPDATA%\Android\Sdk"
echo sdk:      %SDK_DIR%
echo ANDROID_HOME=%ANDROID_HOME%
if defined SDK_DIR if exist "%SDK_DIR%\ndk" (
    for /d %%D in ("%SDK_DIR%\ndk\*") do call :showndk "%%D"
) else (
    echo no ndk folder under "%SDK_DIR%\ndk"
)
echo.

echo [6] what the gradle build will pin (priority: ndk.dir ^> 27.0-if-installed ^> newest)
echo ------------------------------------------------------------
echo The root build prints this at configuration time, e.g.:
echo    root: NDK installed=[...] ndk.dir=... -^> using '...'
echo    android/app: pinning installed NDK ...
echo Just run a build and read those lines - they are the ground truth.
echo.

echo [7] fix commands for [CXX1104] ndk.dir vs android.ndkVersion
echo ------------------------------------------------------------
echo A) stop stale daemons, rebuild:
echo      cd android
echo      gradlew --stop
echo      gradlew :app:bundleRelease --stacktrace
echo.
echo B) one-shot override test (no repo change needed):
echo      cd android
echo      set "ORG_GRADLE_PROJECT_android.ndkVersion=^<installed-revision^>"
echo      gradlew --stop
echo      gradlew :app:bundleRelease --stacktrace
echo.
echo C) make it permanent on THIS machine only (global gradle.properties):
echo      powershell -NoProfile -Command "$gp=$env:USERPROFILE+'\.gradle\gradle.properties'; New-Item -ItemType Directory -Force -Path (Split-Path $gp) ^| Out-Null; $line='android.ndkVersion=^<installed-revision^>'; $c=(Test-Path $gp) ? (Get-Content $gp -Raw) : ''; if($c -match '(?m)^android\.ndkVersion='){$c=[regex]::Replace($c,'(?m)^android\.ndkVersion=.*$',$line)}else{$c=$c.TrimEnd()+\"`r`n\"+$line+\"`r`n\"}; Set-Content -Path $gp -Value $c -Encoding ASCII"
echo.
echo D) or simply:  tools\android_build_release.cmd
echo    (repo gradle already aligns app AND plugin modules to an installed NDK)
echo.
echo ============================================================
echo  replace ^<installed-revision^> above with one shown in [5]
echo ============================================================
endlocal
exit /b 0

:showndk
set "NDK_DOCTOR_REV="
for /f "tokens=2 delims==" %%a in ('findstr /b /c:"Pkg.Revision=" "%~1\source.properties" 2^>nul') do set "NDK_DOCTOR_REV=%%a"
if defined NDK_DOCTOR_REV (
    echo NDK:      %~1  revision=%NDK_DOCTOR_REV%
) else (
    echo NDK:      %~1  revision=?: no readable source.properties
)
exit /b 0
