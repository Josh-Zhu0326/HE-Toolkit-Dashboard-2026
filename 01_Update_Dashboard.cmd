@echo off
setlocal EnableExtensions
chcp 65001 >nul
title HE Toolkit Dashboard - Download or Update

set "REPO_URL=https://github.com/Josh-Zhu0326/HE-Toolkit-Dashboard-2026.git"
set "REPO_NAME=HE-Toolkit-Dashboard-2026"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "PROJECT_DIR=%SCRIPT_DIR%"

echo ============================================================
echo   HE Toolkit Dashboard - Download or Update
echo ============================================================
echo.

where git >nul 2>&1
if errorlevel 1 (
  echo Git is not installed. Trying to install Git for Windows...
  where winget >nul 2>&1
  if errorlevel 1 (
    echo.
    echo [ERROR] Git and Windows Package Manager were not found.
    echo Please install Git from https://git-scm.com/download/win
    goto :failed
  )

  winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements
  if errorlevel 1 (
    echo.
    echo [ERROR] Git could not be installed automatically.
    echo Please install Git from https://git-scm.com/download/win and run this file again.
    goto :failed
  )

  set "PATH=%PATH%;%ProgramFiles%\Git\cmd;%LocalAppData%\Programs\Git\cmd"
  where git >nul 2>&1
  if errorlevel 1 (
    echo.
    echo Git was installed, but Windows has not refreshed PATH yet.
    echo Close this window and run this file again.
    goto :failed
  )
)

if exist "%SCRIPT_DIR%\.git\" goto :update_current

if exist "%SCRIPT_DIR%\%REPO_NAME%\.git\" (
  set "PROJECT_DIR=%SCRIPT_DIR%\%REPO_NAME%"
  goto :update_project
)

echo The dashboard is not present yet. It will be downloaded to:
echo   %SCRIPT_DIR%\%REPO_NAME%
echo.
git clone "%REPO_URL%" "%SCRIPT_DIR%\%REPO_NAME%"
if errorlevel 1 (
  echo.
  echo [ERROR] Download failed. Check the internet connection and GitHub access.
  goto :failed
)
set "PROJECT_DIR=%SCRIPT_DIR%\%REPO_NAME%"
goto :success

:update_current
set "PROJECT_DIR=%SCRIPT_DIR%"

:update_project
echo Updating the existing dashboard in:
echo   %PROJECT_DIR%
echo.
git -C "%PROJECT_DIR%" status --short
git -C "%PROJECT_DIR%" pull --ff-only
if errorlevel 1 (
  echo.
  echo [ERROR] The update was not applied.
  echo Local edits or a network problem may need attention. No files were overwritten.
  goto :failed
)

:success
echo.
echo [SUCCESS] The dashboard files are ready.
echo Project folder:
echo   %PROJECT_DIR%
echo.
echo Next, run 02_Setup_R_and_Run_Dashboard.cmd from the project folder.
echo.
pause
exit /b 0

:failed
echo.
echo Nothing else will be changed. You can close this window or try again.
echo.
pause
exit /b 1
