@echo off
REM ============================================================================
REM  android_build_release.cmd - one-shot Android release build (wedding_time)
REM  Repo: OpsyCore/wedding-time-app        Run from anywhere; it finds the repo.
REM
REM  What it does (idempotent - safe to run repeatedly):
REM    1. Renames conflicting %USERPROFILE%\.gradle\init.gradle to init.gradle.bak
REM    2. Reads flutter.sdk and sdk.dir from android\local.properties
REM       (defaults: C:\src\flutter, %LOCALAPPDATA%\Android\Sdk)
REM    3. NDK check: prints installed NDK revisions. Nothing is downloaded.
REM       The app gradle only pins an NDK that already exists on this machine.
REM       INSTALLNDK=1  -> if no NDK is installed, download android-ndk-r27c
REM                        from the first reachable mirror (Huawei, Tencent,
REM                        Google) into <sdk>\ndk\<revision> using curl+tar
REM                        that ship with Windows 10/11.
REM    4. Patches the Flutter SDK's bundled flutter_tools gradle build
REM       (machine-local, marker ARENA-MIRRORS, originals kept as *.arena.bak).
REM    5. flutter pub get
REM    6. flutter build appbundle --release  (attempt 2 auto-purges possibly
REM       poisoned Gradle module-cache entries first; attempt 3 is a plain
REM       retry for transient mirror 502s)
REM    7. flutter build apk --release        (skipped if SKIPAPK=1)
REM    8. Prints artifact paths. On failure, probes mirrors for the exact
REM       artifacts and prints next-step guidance.
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

REM ---- 2) flutter.sdk + sdk.dir ------------------------------------------------
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

set "SDK_DIR="
for /f "usebackq delims=" %%i in (`powershell -NoProfile -Command "$m = Select-String -LiteralPath 'android\local.properties' -Pattern '^sdk\.dir\s*=\s*(.+?)\s*$' -ErrorAction SilentlyContinue; if ($m) { $m.Matches[0].Groups[1].Value -replace '\\\\','\' -replace '\\:',':' }"`) do set "SDK_DIR=%%i"
if not defined SDK_DIR if defined ANDROID_HOME set "SDK_DIR=%ANDROID_HOME%"
if not defined SDK_DIR if defined ANDROID_SDK_ROOT set "SDK_DIR=%ANDROID_SDK_ROOT%"
if not defined SDK_DIR if defined LOCALAPPDATA set "SDK_DIR=%LOCALAPPDATA%\Android\Sdk"
echo [info] SDK_DIR=%SDK_DIR%

REM ---- 3) NDK status (no downloads unless INSTALLNDK=1) ------------------------
set "NDKLIST="
if defined SDK_DIR if exist "%SDK_DIR%\ndk" for /d %%D in ("%SDK_DIR%\ndk\*") do call :ndkrev "%%D"
if defined NDKLIST (
    echo [ndk]  installed NDK revisions: %NDKLIST%
    echo [ndk]  app gradle pins the best installed one; nothing to download.
) else (
    echo [ndk]  no NDK installed under "%SDK_DIR%\ndk"
    echo [ndk]  fine for this app: plugins ship prebuilt .so files, no NDK needed.
)
if /i "%INSTALLNDK%"=="1" call :install_ndk
if /i "%INSTALLNDK%"=="1" if errorlevel 1 exit /b 1

REM ---- 4) patch flutter_tools gradle build (machine-local, idempotent) ---------
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
if "%CLEANDEPS%"=="1" call :purgecache

REM ---- 5) pub get ----------------------------------------------------------------
echo.
echo [build] flutter pub get
call "%FLUTTER_BIN%" pub get
if errorlevel 1 (
    echo [ERROR] flutter pub get failed.
    echo         Check PUB_HOSTED_URL / FLUTTER_STORAGE_BASE_URL mirror env vars.
    exit /b 1
)

REM ---- 6) AAB ---------------------------------------------------------------------
set "AAB=%cd%\build\app\outputs\bundle\release\app-release.aab"
echo.
echo [build] attempt 1: flutter build appbundle --release
call "%FLUTTER_BIN%" build appbundle --release
if not errorlevel 1 goto aab_ok
echo [retry] attempt 1 failed. purging possibly-poisoned Gradle cache entries...
call :purgecache
echo [retry] attempt 2: flutter build appbundle --release
call "%FLUTTER_BIN%" build appbundle --release
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

REM ---- 7) APK -----------------------------------------------------------------------
if "%SKIPAPK%"=="1" goto done
set "APK=%cd%\build\app\outputs\flutter-apk\app-release.apk"
echo.
echo [build] flutter build apk --release
call "%FLUTTER_BIN%" build apk --release
if not errorlevel 1 goto apk_ok
echo [retry] apk failed once - purging cache entries and retrying
call :purgecache
call "%FLUTTER_BIN%" build apk --release
if not errorlevel 1 goto apk_ok
echo [FAIL] apk build failed. The AAB is still fine: %AAB%
call :probe
call :guidance
exit /b 1
:apk_ok
echo.
echo [OK] APK ready: %APK%

REM ---- 8) summary ---------------------------------------------------------------------
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
:ndkrev
REM %1 = path to an ndk/<folder> dir; echo its Pkg.Revision into NDKLIST
set "NDKREV_ITEM="
for /f "tokens=2 delims==" %%a in ('findstr /b /c:"Pkg.Revision=" "%~1\source.properties" 2^>nul') do set "NDKREV_ITEM=%%a"
if defined NDKREV_ITEM set "NDKLIST=%NDKLIST% %NDKREV_ITEM%"
exit /b 0

:install_ndk
echo.
echo [ndk-install] INSTALLNDK=1 - installing android-ndk-r27c (revision 27.2.12479018)
if defined NDKLIST (
    echo [ndk-install] an NDK is already installed (%NDKLIST%) - nothing to do.
    exit /b 0
)
if not defined SDK_DIR (
    echo [ndk-install] [ERROR] SDK dir unknown - set sdk.dir in android\local.properties
    exit /b 1
)
set "NDKZIP=%TEMP%\android-ndk-r27c-windows.zip"
set "NDKTMP=%TEMP%\ndk_extract_r27c"
if exist "%NDKTMP%" rd /s /q "%NDKTMP%" >nul 2>&1
mkdir "%NDKTMP%" >nul 2>&1

echo [ndk-install] trying mirrors (resume-capable, ~840 MB):
set "NDKURL="
if not defined NDKURL (
    curl.exe -L -C - --connect-timeout 20 --retry 2 --retry-delay 2 -o "%NDKZIP%" "https://mirrors.huaweicloud.com/android/repository/android-ndk-r27c-windows.zip" >nul 2>&1
    if not errorlevel 1 set "NDKURL=huaweicloud"
)
if not defined NDKURL (
    echo [ndk-install]   huaweicloud failed - trying tencent
    curl.exe -L -C - --connect-timeout 20 --retry 2 --retry-delay 2 -o "%NDKZIP%" "https://mirrors.cloud.tencent.com/AndroidSDK/android-ndk-r27c-windows.zip" >nul 2>&1
    if not errorlevel 1 set "NDKURL=tencent"
)
if not defined NDKURL (
    echo [ndk-install]   tencent failed - trying dl.google.com
    curl.exe -L -C - --connect-timeout 20 --retry 2 --retry-delay 2 -o "%NDKZIP%" "https://dl.google.com/android/repository/android-ndk-r27c-windows.zip" >nul 2>&1
    if not errorlevel 1 set "NDKURL=google"
)
if not defined NDKURL (
    echo [ndk-install] [ERROR] all mirrors failed. Check connectivity; the
    echo               partial file is kept at "%NDKZIP%" so a re-run resumes it.
    exit /b 1
)
for %%A in ("%NDKZIP%") do set "NDKZIPSIZE=%%~zA"
echo [ndk-install] downloaded via %NDKURL% (%NDKZIPSIZE% bytes)
if %NDKZIPSIZE% LSS 500000000 (
    echo [ndk-install] [ERROR] file looks too small - download failed mid-way.
    echo               Re-run with INSTALLNDK=1 to resume.
    exit /b 1
)
echo [ndk-install] extracting (tar) ...
where tar.exe >nul 2>&1
if not errorlevel 1 (
    tar.exe -xf "%NDKZIP%" -C "%NDKTMP%"
) else (
    powershell -NoProfile -Command "Expand-Archive -LiteralPath '%NDKZIP%' -DestinationPath '%NDKTMP%' -Force"
)
if not exist "%NDKTMP%\android-ndk-r27c\source.properties" (
    echo [ndk-install] [ERROR] extraction failed or unexpected zip layout.
    exit /b 1
)
set "NDKREV="
for /f "tokens=2 delims==" %%a in ('findstr /b /c:"Pkg.Revision=" "%NDKTMP%\android-ndk-r27c\source.properties"') do set "NDKREV=%%a"
if not defined NDKREV (
    echo [ndk-install] [ERROR] could not read Pkg.Revision from source.properties
    exit /b 1
)
if not exist "%SDK_DIR%\ndk" mkdir "%SDK_DIR%\ndk"
if exist "%SDK_DIR%\ndk\%NDKREV%" (
    echo [ndk-install] "%SDK_DIR%\ndk\%NDKREV%" already exists - leaving as is.
) else (
    move /y "%NDKTMP%\android-ndk-r27c" "%SDK_DIR%\ndk\%NDKREV%" >nul
    echo [ndk-install] installed to: %SDK_DIR%\ndk\%NDKREV%
)
del /q "%NDKZIP%" >nul 2>&1
rd /s /q "%NDKTMP%" >nul 2>&1
echo [ndk-install] done. Re-run this script to build (gradle auto-detects the NDK).
exit /b 0

:purgecache
echo [clean] purging possibly-poisoned Gradle module cache entries
rd /s /q "%USERPROFILE%\.gradle\caches\modules-2\files-2.1\com.android.tools.build" 2>nul
rd /s /q "%USERPROFILE%\.gradle\caches\modules-2\files-2.1\androidx.annotation" 2>nul
rd /s /q "%USERPROFILE%\.gradle\caches\modules-2\files-2.1\com.google.gms" 2>nul
echo [clean] done - Gradle will re-download these through the mirrors
exit /b 0

:probe
echo.
echo [probe] reachability of the exact artifacts the build needs:
call :p "https://maven.aliyun.com/repository/google/com/android/tools/build/gradle/8.11.1/gradle-8.11.1.pom"
call :p "https://maven.aliyun.com/repository/public/androidx/annotation/annotation-jvm/1.9.1/annotation-jvm-1.9.1.pom"
call :p "https://repo1.maven.org/maven2/org/jetbrains/kotlin/kotlin-gradle-plugin/2.0.0/kotlin-gradle-plugin-2.0.0.pom"
call :p "https://mirrors.huaweicloud.com/repository/maven/androidx/annotation/annotation-jvm/1.9.1/annotation-jvm-1.9.1.pom"
call :p "https://mirrors.cloud.tencent.com/nexus/repository/maven-public/androidx/annotation/annotation-jvm/1.9.1/annotation-jvm-1.9.1.pom"
call :p "https://dl.google.com/android/maven2/com/android/tools/build/gradle/8.11.1/gradle-8.11.1.pom"
echo.
echo [probe] NDK zip mirrors (HEAD only - no download):
call :ph "https://mirrors.huaweicloud.com/android/repository/android-ndk-r27c-windows.zip"
call :ph "https://mirrors.cloud.tencent.com/AndroidSDK/android-ndk-r27c-windows.zip"
call :ph "https://dl.google.com/android/repository/android-ndk-r27c-windows.zip"
exit /b 0

:p
echo   - %1
curl -m 12 -s -o nul -w "    HTTP %%{http_code}  %%{time_total}s" %1
echo.
exit /b 0

:ph
echo   - %1
curl -m 12 -s -I -o nul -w "    HTTP %%{http_code}  %%{time_total}s" %1
echo.
exit /b 0

:guidance
echo.
echo [next steps - in order]
echo  1. Read the [probe] results above: HTTP 200 = mirror reachable, 404 = wrong
echo     path on that mirror, 000/timeout = mirror blocked. Gradle uses the first
echo     mirror that answers, so at least one 200 must exist.
echo  2. If the error says "NDK not configured ... Preferred NDK version": either
echo     let the build pin nothing (current app gradle does that when no NDK is
echo     installed - make sure you merged the latest repo files) or install one:
echo        set INSTALLNDK=1
echo        tools\android_build_release.cmd
echo  3. Retry this script 1-2 more times later - 502s from mirrors are transient.
echo  4. If every probe times out, run one build on a phone hotspot or VPN to warm
echo     %%USERPROFILE%%\.gradle\caches , then future builds work from cache.
echo  5. For details re-run gradle directly:
echo     gradlew assembleRelease --info   (from the android folder^)
echo  6. To undo SDK patches: restore *.arena.bak files in
echo     %FLUTTER_SDK%\packages\flutter_tools\gradle\
exit /b 0
