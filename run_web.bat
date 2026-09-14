@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

if not exist local_key.txt goto ASK

set /p KEY=<local_key.txt
if "!KEY!"=="" goto ASK
goto RUN

:ASK
echo.
echo === ImgBB API key setup ===
echo Paste your ImgBB API key and press Enter.
echo (Asked only once - saved to local_key.txt, which is NOT committed to git)
echo.
set /p KEY=Key:
echo !KEY!>local_key.txt

:RUN
echo.
echo Starting the app in Chrome...
flutter run -d chrome --dart-define=IMGBB_API_KEY=!KEY!
endlocal
