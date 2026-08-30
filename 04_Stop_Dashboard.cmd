@echo off
setlocal EnableExtensions
chcp 65001 >nul
title HE Toolkit Dashboard - Stop App

set "APP_PORT=3838"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "RUN_DIR=%LOCALAPPDATA%\HE-Toolkit\run"
set "STOP_SCRIPT=%SCRIPT_DIR%\scripts\windows\stop_dashboard_process.ps1"

echo ============================================================
echo   HE Toolkit Dashboard - Stop App
echo ============================================================
echo.
echo Stopping the HE Toolkit Dashboard...
echo.

if not exist "%STOP_SCRIPT%" (
  echo [ERROR] The Dashboard stop helper could not be found.
  echo No process was stopped.
  goto :failed
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%STOP_SCRIPT%" -RuntimeDirectory "%RUN_DIR%" -ExpectedProjectDirectory "%SCRIPT_DIR%" -ExpectedPort %APP_PORT%
if errorlevel 1 goto :failed

echo.
pause
exit /b 0

:failed
echo.
echo The Dashboard could not be stopped safely.
echo No unrelated R process was intentionally stopped.
echo.
pause
exit /b 1
