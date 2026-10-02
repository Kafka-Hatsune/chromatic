@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-BetterNCM.ps1" -Restart
set "result=%errorlevel%"
echo.
if not "%result%"=="0" echo Installation failed. Read the message above and README.md.
pause
exit /b %result%
