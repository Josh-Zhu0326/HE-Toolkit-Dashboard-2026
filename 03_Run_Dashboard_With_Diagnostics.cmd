@echo off
setlocal EnableExtensions
chcp 65001 >nul
title HE Toolkit Dashboard - Diagnostic Monitor

set "REPO_NAME=HE-Toolkit-Dashboard-2026"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "PROJECT_DIR=%SCRIPT_DIR%"

if not exist "%PROJECT_DIR%\global.R" (
  if exist "%SCRIPT_DIR%\%REPO_NAME%\global.R" (
    set "PROJECT_DIR=%SCRIPT_DIR%\%REPO_NAME%"
  ) else (
    echo ============================================================
    echo   HE Toolkit Dashboard - Diagnostic Monitor
    echo ============================================================
    echo.
    echo [ERROR] The Dashboard project was not found beside this file.
    echo Keep this file in the downloaded Dashboard folder and try again.
    echo.
    pause
    exit /b 2
  )
)

if not exist "%PROJECT_DIR%\scripts\run_dashboard_diagnostics.ps1" (
  echo [ERROR] The diagnostic script is missing from the Dashboard folder.
  echo Please download a complete, current copy of the Dashboard.
  echo.
  pause
  exit /b 2
)

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PROJECT_DIR%\scripts\run_dashboard_diagnostics.ps1" -ProjectDir "%PROJECT_DIR%"
set "DIAGNOSTIC_RESULT=%ERRORLEVEL%"

echo.
if "%DIAGNOSTIC_RESULT%"=="0" (
  echo Diagnostic monitoring completed. Follow the ZIP-file instructions above.
) else (
  echo Diagnostic monitoring returned code %DIAGNOSTIC_RESULT%.
  echo Follow the ZIP-file or evidence-folder instructions above.
)
echo.
pause
exit /b %DIAGNOSTIC_RESULT%
