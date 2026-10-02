@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-RefinedRomaji.ps1" -Restart
if errorlevel 1 echo Installation failed. Read the error above before retrying.
pause
