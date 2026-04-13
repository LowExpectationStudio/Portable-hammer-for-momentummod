@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%tools\Setup-MomentumMount.ps1" -LaunchHammer
if errorlevel 1 (
    echo.
    echo Setup failed.
    pause
)
