@echo off
title St-Philopateer Screens Launcher

echo Opening screens display in kiosk fullscreen mode...
set "URL=https://st-philopateer.github.io/Screens/front/index.html"

:: Permanent user data directory on C: drive (protected from Windows Temp Cleaners)
set "PROFILE_DIR=%LOCALAPPDATA%\ScreensKioskProfile"
if not exist "%PROFILE_DIR%" mkdir "%PROFILE_DIR%"

set "FLAGS=--kiosk --autoplay-policy=no-user-gesture-required --disable-background-timer-throttling --disable-backgrounding-occluded-windows --disable-renderer-backgrounding --disk-cache-size=1073741824 --media-cache-size=1073741824"

if exist "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe" (
    start "" "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe" %FLAGS% --user-data-dir="%PROFILE_DIR%" "%URL%"
    goto next
)
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" %FLAGS% --user-data-dir="%PROFILE_DIR%" "%URL%"
    goto next
)
if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
    start "" "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" %FLAGS% --user-data-dir="%PROFILE_DIR%" "%URL%"
    goto next
)
if exist "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" (
    start "" "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" %FLAGS% --user-data-dir="%PROFILE_DIR%" "%URL%"
    goto next
)
if exist "C:\Program Files\Microsoft\Edge\Application\msedge.exe" (
    start "" "C:\Program Files\Microsoft\Edge\Application\msedge.exe" %FLAGS% --user-data-dir="%PROFILE_DIR%" "%URL%"
    goto next
)
if exist "C:\Program Files (x86)\BraveSoftware\Brave-Browser\Application\brave.exe" (
    start "" "C:\Program Files (x86)\BraveSoftware\Brave-Browser\Application\brave.exe" %FLAGS% --user-data-dir="%PROFILE_DIR%" "%URL%"
    goto next
)

:: Fallback if no known browser found
start "" "%URL%"

:next
echo Preparing companion script...
set "LOCAL_COMPANION=%~dp0companion.ps1"
set "CACHED_COMPANION=%PROFILE_DIR%\companion.ps1"

:: Clean up obsolete VBScript file to prevent any Windows Script Host dialogs
del "%TEMP%\launch.vbs" >nul 2>&1

:: If companion.ps1 exists locally next to this bat file, use it and update cache
if exist "%LOCAL_COMPANION%" (
    copy /y "%LOCAL_COMPANION%" "%CACHED_COMPANION%" >nul 2>&1
) else (
    :: Try downloading from GitHub in background, but do NOT block or fail if offline!
    powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri 'https://st-philopateer.github.io/Screens/front/companion.ps1' -OutFile '%CACHED_COMPANION%' -TimeoutSec 3 } catch {}"
)

:: Launch companion script natively in background (hidden, silent, zero VBScript errors)
if exist "%CACHED_COMPANION%" (
    powershell -NoProfile -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%CACHED_COMPANION%\"' -WindowStyle Hidden"
)
exit
