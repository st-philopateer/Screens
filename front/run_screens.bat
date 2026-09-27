@echo off
title St-Philopateer Screens Launcher

echo Opening screens display in kiosk fullscreen mode...
set "URL=https://st-philopateer.github.io/Screens/front/index.html"

set "FLAGS=--kiosk --autoplay-policy=no-user-gesture-required --disable-background-timer-throttling --disable-backgrounding-occluded-windows --disable-renderer-backgrounding"

if exist "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe" (
    start "" "C:\Program Files\BraveSoftware\Brave-Browser\Application\brave.exe" %FLAGS% --user-data-dir="%TEMP%\BraveKioskProfile" "%URL%"
    goto next
)
if exist "C:\Program Files\Google\Chrome\Application\chrome.exe" (
    start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" %FLAGS% --user-data-dir="%TEMP%\ChromeKioskProfile" "%URL%"
    goto next
)
if exist "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" (
    start "" "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" %FLAGS% --user-data-dir="%TEMP%\ChromeKioskProfile" "%URL%"
    goto next
)
if exist "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" (
    start "" "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" %FLAGS% --user-data-dir="%TEMP%\EdgeKioskProfile" "%URL%"
    goto next
)
if exist "C:\Program Files\Microsoft\Edge\Application\msedge.exe" (
    start "" "C:\Program Files\Microsoft\Edge\Application\msedge.exe" %FLAGS% --user-data-dir="%TEMP%\EdgeKioskProfile" "%URL%"
    goto next
)
if exist "C:\Program Files (x86)\BraveSoftware\Brave-Browser\Application\brave.exe" (
    start "" "C:\Program Files (x86)\BraveSoftware\Brave-Browser\Application\brave.exe" %FLAGS% --user-data-dir="%TEMP%\BraveKioskProfile" "%URL%"
    goto next
)

:: Fallback if no known browser found
start "" "%URL%"

:next
echo Preparing companion script...
powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://st-philopateer.github.io/Screens/front/companion.ps1' -OutFile '%TEMP%\companion.ps1'"

if not exist "%TEMP%\companion.ps1" goto error

echo Set WshShell = CreateObject("WScript.Shell") > "%TEMP%\launch.vbs"
echo WshShell.Run "powershell -ExecutionPolicy Bypass -File ""%TEMP%\companion.ps1""", 0, false >> "%TEMP%\launch.vbs"
wscript "%TEMP%\launch.vbs"
del "%TEMP%\launch.vbs"
exit

:error
echo Error: Failed to download companion script from GitHub Pages.
pause
exit
