@echo off
chcp 65001 >nul
setlocal
where pwsh >nul 2>nul
if errorlevel 1 (
  echo PowerShell 7 ^(pwsh^) not found.
  echo Install PowerShell 7 or run the .ps1 with powershell.exe manually.
  pause
  exit /b 1
)
pwsh -NoProfile -ExecutionPolicy Bypass -File "%~dp0repair-install-preset-0.1.3.ps1" %*
echo.
pause
