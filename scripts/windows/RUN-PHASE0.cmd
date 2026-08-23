@echo off
REM Clean-host E2E Phase 0 launcher (ASCII-only). Accept UAC if prompted.
cd /d %~dp0
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0phase0-setup.ps1"
echo.
echo Exit code: %ERRORLEVEL%
pause
