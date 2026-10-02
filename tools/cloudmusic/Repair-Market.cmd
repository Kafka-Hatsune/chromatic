@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-BetterNCM.ps1" -MarketOnly -Restart
set "result=%errorlevel%"
echo.
if not "%result%"=="0" echo Market repair failed. Read the message above and README.md.
pause
exit /b %result%
