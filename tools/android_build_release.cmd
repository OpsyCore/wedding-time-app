@echo off
REM ============================================================================
REM  android_build_release.cmd - one-shot Android release build (wedding_time)
REM  Repo: OpsyCore/wedding-time-app        Run from anywhere; it finds the repo.
REM
REM  What it does (idempotent - safe to run repeatedly):
REM    1. Renames conflicting %USERPROFILE%\.gradle\init.gradle to init.gradle.bak
REM    2. Reads flutter.sdk from android\local.properties (default C:\src\flutter)
REM    3. Patches the Flutter SDK's bundled flutter_tools gradle build (this is a
REM       MACHINE-LOCAL file, not in git):
REM         %FLUTTER_SDK%\packages\flutter_tools\gradle\settings.gradle.kts
REM             -> replaced with multi-mirror version (marker: ARENA-MIRRORS)
REM         %FLUTTER_SDK%\packages\flutter_tools\gradle\build.gradle.kts
REM             -> repositories block appended (marker: ARENA-MIRRORS)
REM       Originals are kept as *.arena.bak next to the files.
REM    4. flutter pub get
REM    5. flutter build appbundle --release   (3 attempts, see strategy below)
REM    6. flutter build apk --release         (skipped if SKIPAPK=1)
REM    7. Prints artifact paths. On failure, probes every mirror for the exact
REM       artifacts that fail and prints next-step guidance.
REM
REM  Retry strategy:
REM    attempt 1: plain build
REM    attempt 2: --refresh-dependencies  (bypasses stale/poisoned metadata cache)
REM    attempt 3: plain again             (transient 502s are common on mirrors)
REM
REM  Optional flags (set in cmd before running this script):
REM    set CLEANDEPS=1   purge possibly-poisoned Gradle module cache entries first
REM    set SKIPAPK=1     build AAB only
REM ============================================================================
setlocal EnableExtensions
chcp 65001 >nul
cd /d "%~dp0.."
echo ============================================================
echo  wedding_time - Android release build unblock
echo  repo: %cd%
echo ============================================================

REM ---- 1) init.gradle conflict ------------------------------------------------
if exist "%USERPROFILE%\.gradle\init.gradle" (
    echo [fix] renaming %USERPROFILE%\.gradle\init.gradle to init.gradle.bak
    echo       it can force repository-mode settings that break the flutter build
    move /y "%USERPROFILE%\.gradle\init.gradle" "%USERPROFILE%\.gradle\init.gradle.bak" >nul
)
if exist "%USERPROFILE%\.gradle\init.d" (
    echo [warn] %USERPROFILE%\.gradle\init.d exists. If the build still fails with
    echo        repository-mode errors, temporarily move its scripts out of there.
)

REM ---- 2) flutter.sdk ----------------------------------------------------------
set "FLUTTER_SDK="
for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "$m = Select-String -LiteralPath 'android\local.properties' -Pattern '^flutter\.sdk\s*=\s*(.+?)\s*$' -ErrorAction SilentlyContinue; if ($m) { $m.Matches[0].Groups[1].Value -replace '\\\\','\' -replace '\\:',':' }"`) do set "FLUTTER_SDK=%%i"
if not defined FLUTTER_SDK set "FLUTTER_SDK=C:\src\flutter"
set "FLUTTER_BIN=%FLUTTER_SDK%\bin\flutter.bat"
echo [info] FLUTTER_SDK=%FLUTTER_SDK%
if not exist "%FLUTTER_BIN%" (
    echo [ERROR] flutter.bat not found at "%FLUTTER_BIN%"
    echo         fix flutter.sdk in android\local.properties and re-run.
    exit /b 1
)

REM ---- 3) patch flutter_tools gradle build (machine-local, idempotent) ---------
set "FTG=%FLUTTER_SDK%\packages\flutter_tools\gradle"
set "PATCHDIR=%~dp0flutter_tools_patches"
if not exist "%FTG%\settings.gradle.kts" (
    echo [ERROR] flutter_tools gradle dir not found: "%FTG%"
    echo         Is "%FLUTTER_SDK%" a real Flutter SDK?
    exit /b 1
)

findstr /c:"ARENA-MIRRORS" "%FTG%\settings.gradle.kts" >nul 2>&1
if errorlevel 1 (
    echo [patch] %FTG%\settings.gradle.kts - installing multi-mirror version
    if not exist "%FTG%\settings.gradle.kts.arena.bak" copy /y "%FTG%\settings.gradle.kts" "%FTG%\settings.gradle.kts.arena.bak" >nul
    copy /y "%PATCHDIR%\flutter_tools_gradle_settings.gradle.kts" "%FTG%\settings.gradle.kts" >nul
) else (
    echo [skip] flutter_tools settings.gradle.kts already patched
)

findstr /c:"ARENA-MIRRORS" "%FTG%\build.gradle.kts" >nul 2>&1
if errorlevel 1 (
    echo [patch] %FTG%\build.gradle.kts - appending repositories block
    if not exist "%FTG%\build.gradle.kts.arena.bak" copy /y "%FTG%\build.gradle.kts" "%FTG%\build.gradle.kts.arena.bak" >nul
    >> "%FTG%\build.gradle.kts" echo(
    >> "%FTG%\build.gradle.kts" type "%PATCHDIR%\ft_build_repositories_block.txt"
    echo [info] original kept as build.gradle.kts.arena.bak
) else (
    echo [skip] flutter_tools build.gradle.kts already patched
)

REM ---- optional: purge possibly-poisoned module cache entries -------------------
if "%CLEANDEPS%"=="1" (
    echo [clean] purging possibly-poisoned Gradle module cache entries
    rd /s /q "%USERPROFILE%\.gradle\caches\modules-2\files-2.1\com.android.tools.build" 2>nul
    rd /s /q "%USERPROFILE%\.gradle\caches\modules-2\files-2.1\androidx.annotation" 2>nul
    rd /s /q "%USERPROFILE%\.gradle\caches\modules-2\files-2.1\com.google.gms" 2>nul
    echo [clean] done - Gradle will re-download these on next build
)

REM ---- 4) pub get ----------------------------------------------------------------
echo.
echo [build] flutter pub get
call "%FLUTTER_BIN%" pub get
if errorlevel 1 (
    echo [ERROR] flutter pub get failed.
    echo         Check PUB_HOSTED_URL / FLUTTER_STORAGE_BASE_URL mirror env vars.
    exit /b 1
)

REM ---- 5) AAB ---------------------------------------------------------------------
set "AAB=%cd%\build\app\outputs\bundle\release\app-release.aab"
echo.
echo [build] attempt 1: flutter build appbundle --release
call "%FLUTTER_BIN%" build appbundle --release
if not errorlevel 1 goto aab_ok
echo [retry] attempt 1 failed. attempt 2: --refresh-dependencies
call "%FLUTTER_BIN%" build appbundle --release --refresh-dependencies
if not errorlevel 1 goto aab_ok
echo [retry] attempt 2 failed. attempt 3: plain again - transient 502s are common
call "%FLUTTER_BIN%" build appbundle --release
if not errorlevel 1 goto aab_ok
echo.
echo [FAIL] appbundle failed after 3 attempts. Evidence below.
call :probe
call :guidance
exit /b 1
:aab_ok
echo.
echo [OK] AAB ready: %AAB%
if not exist "%AAB%" echo [WARN] expected AAB file not found - check log above

REM ---- 6) APK -----------------------------------------------------------------------
if "%SKIPAPK%"=="1" goto done
set "APK=%cd%\build\app\outputs\flutter-apk\app-release.apk"
echo.
echo [build] flutter build apk --release
call "%FLUTTER_BIN%" build apk --release
if not errorlevel 1 goto apk_ok
echo [retry] apk failed once - trying with --refresh-dependencies
call "%FLUTTER_BIN%" build apk --release --refresh-dependencies
if not errorlevel 1 goto apk_ok
echo [FAIL] apk build failed. The AAB is still fine: %AAB%
call :probe
call :guidance
exit /b 1
:apk_ok
echo.
echo [OK] APK ready: %APK%

REM ---- 7) summary ---------------------------------------------------------------------
:done
echo.
echo ============================================================
echo  ARTIFACTS
echo  AAB  for Google Play  : %cd%\build\app\outputs\bundle\release\app-release.aab
echo  APK  for Cafe Bazaar  : %cd%\build\app\outputs\flutter-apk\app-release.apk
echo  signing               : android\key.properties + upload-keystore.jks
echo ============================================================
endlocal
exit /b 0

REM ---- helpers -----------------------------------------------------------------------
:probe
echo.
echo [probe] reachability of the exact artifacts the build needs:
call :p "https://maven.aliyun.com/repository/google/com/android/tools/build/gradle/8.11.1/gradle-8.11.1.pom"
call :p "https://maven.aliyun.com/repository/public/androidx/annotation/annotation-jvm/1.9.1/annotation-jvm-1.9.1.pom"
call :p "https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-gradle-plugin/2.0.0/kotlin-gradle-plugin-2.0.0.pom"
call :p "https://mirrors.huaweicloud.com/repository/maven/androidx/annotation/annotation-jvm/1.9.1/annotation-jvm-1.9.1.pom"
call :p "https://mirrors.cloud.tencent.com/nexus/repository/maven-public/androidx/annotation/annotation-jvm/1.9.1/annotation-jvm-1.9.1.pom"
call :p "https://dl.google.com/android/maven2/com/android/tools/build/gradle/8.11.1/gradle-8.11.1.pom"
exit /b 0

:p
echo   - %1
curl -m 12 -s -o nul -w "    HTTP %%{http_code}  %%{time_total}s" %1
echo.
exit /b 0

:guidance
echo.
echo [next steps - in order]
echo  1. Read the [probe] results above: HTTP 200 = mirror reachable, 404 = wrong
echo     path on that mirror, 000/timeout = mirror blocked. Gradle uses the first
echo     mirror that answers, so at least one 200 must exist.
echo  2. Retry this script 1-2 more times later - 502s from mirrors are transient.
echo  3. If every probe times out, run one build on a phone hotspot or VPN to warm
echo     %%USERPROFILE%%\.gradle\caches , then future builds work from cache.
echo  4. For details re-run gradle directly:
echo     gradlew assembleRelease --info   (from the android folder^)
echo  5. To undo SDK patches: restore *.arena.bak files in
echo     %FLUTTER_SDK%\packages\flutter_tools\gradle\
exit /b 0
