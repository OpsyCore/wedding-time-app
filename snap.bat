@echo off
chcp 65001 >nul
cd /d C:\Users\pcgadjet\Desktop\wedding_time
if not exist handoff_dump mkdir handoff_dump

set OUT=handoff_dump\PROJECT_SNAPSHOT.txt
echo Creating snapshot...
echo WEDDING TIME PROJECT SNAPSHOT > "%OUT%"
echo Date: %date% %time% >> "%OUT%"
echo Root: %cd% >> "%OUT%"
echo. >> "%OUT%"

echo ===== 1) ROOT DIR ===== >> "%OUT%"
dir /b >> "%OUT%"
echo. >> "%OUT%"

echo ===== 2) LIB TREE ===== >> "%OUT%"
tree /f lib >> "%OUT%"
echo. >> "%OUT%"

echo ===== 3) WEB TREE ===== >> "%OUT%"
tree /f web >> "%OUT%"
echo. >> "%OUT%"

echo ===== 4) GUEST PORTAL CHECK ===== >> "%OUT%"
call :chk lib\screens\guest_portal\guest_auth_gate.dart
call :chk lib\screens\guest_portal\guest_login_screen.dart
call :chk lib\screens\guest_portal\guest_portal_shell.dart
call :chk lib\screens\guest_portal\guest_home_tab.dart
call :chk lib\screens\guest_portal\guest_timeline_tab.dart
call :chk lib\screens\guest_portal\guest_gallery_tab.dart
call :chk lib\screens\guest_portal\guest_gifts_tab.dart
call :chk lib\models\gift_item_model.dart
call :chk lib\services\gift_registry_service.dart
call :chk lib\screens\gift_manage_screen.dart
echo. >> "%OUT%"

echo ===== 5) CORE CHECK ===== >> "%OUT%"
call :chk lib\main.dart
call :chk lib\screens\public_invite_screen.dart
call :chk lib\screens\login_screen.dart
call :chk lib\screens\plans_screen.dart
call :chk lib\screens\plans_admin_screen.dart
call :chk lib\services\plans_service.dart
call :chk lib\core\app_plans.dart
call :chk lib\core\app_config.dart
call :chk lib\core\app_theme.dart
call :chk firestore.rules
call :chk web\index.html
call :chk web\_redirects
echo. >> "%OUT%"

echo ===== 6) MAIN.DART INVITE ROUTE ===== >> "%OUT%"
findstr /n /i /c:"GuestAuthGate" /c:"PublicInviteScreen" /c:"invite" lib\main.dart >> "%OUT%" 2>&1
echo. >> "%OUT%"

echo ===== 7) DANGER: famous-shortbread ===== >> "%OUT%"
findstr /s /n /i /c:"famous-shortbread" lib\*.dart web\index.html >> "%OUT%" 2>&1
echo. >> "%OUT%"

echo ===== 8) DANGER: applyMode ===== >> "%OUT%"
findstr /s /n /i /c:"applyMode" lib\*.dart >> "%OUT%" 2>&1
echo. >> "%OUT%"

echo ===== 9) DANGER: firebase_storage ===== >> "%OUT%"
findstr /s /n /i /c:"firebase_storage" lib\*.dart >> "%OUT%" 2>&1
echo. >> "%OUT%"

echo ===== 10) PORTAL SYMBOLS ===== >> "%OUT%"
findstr /s /n /i /c:"GuestAuthGate" /c:"GuestPortalShell" /c:"GiftRegistryService" /c:"GiftManageScreen" lib\*.dart >> "%OUT%" 2>&1
echo. >> "%OUT%"

echo ===== 11) RULES KEYWORDS ===== >> "%OUT%"
findstr /n /i /c:"gifts" /c:"giftSettings" /c:"isAdmin" /c:"guestMedia" /c:"timeline" /c:"plan_reviews" /c:"app_config" firestore.rules >> "%OUT%" 2>&1
echo. >> "%OUT%"

echo ===== 12) INDEX.HTML OG ===== >> "%OUT%"
findstr /n /i /c:"og:" /c:"canonical" /c:"wedding-time" /c:"famous-shortbread" /c:"netlify" web\index.html >> "%OUT%" 2>&1
echo. >> "%OUT%"

echo ===== 13) PUBSPEC ===== >> "%OUT%"
type pubspec.yaml >> "%OUT%"
echo. >> "%OUT%"

echo ===== 14) FLUTTER ANALYZE ===== >> "%OUT%"
call flutter analyze >> "%OUT%" 2>&1
echo. >> "%OUT%"

echo ===== DONE ===== >> "%OUT%"
echo.
echo SAVED:
echo %cd%\%OUT%
dir "%OUT%"
echo.
echo ----- PREVIEW -----
powershell -NoProfile -Command "Get-Content -Path '%OUT%' -TotalCount 120"
echo.
pause
goto :eof

:chk
if exist "%~1" (
  echo [OK] %~1 >> "%OUT%"
) else (
  echo [MISSING] %~1 >> "%OUT%"
)
goto :eof