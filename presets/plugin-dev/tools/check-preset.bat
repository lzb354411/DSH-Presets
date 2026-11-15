@echo off
chcp 65001 >nul
setlocal
set "PS1=%~dp0check-preset.ps1"
if not exist "%PS1%" (
  echo missing check-preset.ps1 next to this file
  pause
  exit /b 2
)
where pwsh >nul 2>nul
if not errorlevel 1 (
  pwsh -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
)
set "CODE=%ERRORLEVEL%"
echo.
pause
exit /b %CODE%
