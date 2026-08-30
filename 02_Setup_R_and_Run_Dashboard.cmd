@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title HE Toolkit Dashboard - Check R and Start

set "REPO_NAME=HE-Toolkit-Dashboard-2026"
set "APP_PORT=3838"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "PROJECT_DIR=%SCRIPT_DIR%"
set "RSCRIPT_EXE="
set "R_VERSION="
set "R_VERSION_KEY="
set "R_LIBRARY_ROOT=%LOCALAPPDATA%\HE-Toolkit\R-library"
set "LOG_DIR=%LOCALAPPDATA%\HE-Toolkit\logs"
set "RUN_DIR=%LOCALAPPDATA%\HE-Toolkit\run"
set "SETUP_LOG="
set "SERVER_LOG="

echo ============================================================
echo   HE Toolkit Dashboard - Check R, Install Packages, Start App
echo ============================================================
echo.

if not exist "%PROJECT_DIR%\global.R" (
  if exist "%SCRIPT_DIR%\%REPO_NAME%\global.R" (
    set "PROJECT_DIR=%SCRIPT_DIR%\%REPO_NAME%"
  ) else (
    echo [ERROR] The dashboard project was not found beside this file.
    echo Run 01_Update_Dashboard.cmd first, then run this file from the project folder.
    goto :failed
  )
)

pushd "%PROJECT_DIR%"
if errorlevel 1 (
  echo [ERROR] The dashboard project folder could not be opened.
  goto :failed
)

powershell -NoProfile -Command "if (Get-NetTCPConnection -LocalPort %APP_PORT% -State Listen -ErrorAction SilentlyContinue) { exit 10 } else { exit 0 }"
if errorlevel 1 (
  echo.
  echo [ERROR] Port %APP_PORT% is already in use. Another Dashboard instance or program may already be running.
  echo Close the existing Dashboard or process, then run this launcher again.
  echo If it was started by this launcher, run 03_Stop_Dashboard.cmd.
  goto :failed
)

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if errorlevel 1 (
  echo [ERROR] The dashboard log folder could not be created.
  goto :failed
)
if not exist "%RUN_DIR%" mkdir "%RUN_DIR%"
if errorlevel 1 (
  echo [ERROR] The dashboard runtime folder could not be created.
  goto :failed
)
for /f "usebackq delims=" %%T in (`powershell -NoProfile -Command "Get-Date -Format 'yyyyMMdd-HHmmss-fff'"`) do set "RUN_STAMP=%%T"
if not defined RUN_STAMP set "RUN_STAMP=unknown-%RANDOM%-%RANDOM%"
set "SETUP_LOG=%LOG_DIR%\setup-preflight-%RUN_STAMP%.log"
set "SERVER_LOG=%LOG_DIR%\dashboard-server-%RUN_STAMP%.log"
>"%SETUP_LOG%" echo HE Toolkit dashboard setup and preflight log
>>"%SETUP_LOG%" echo Started: %DATE% %TIME%

call :find_r
if defined RSCRIPT_EXE goto :r_ready

echo R was not found in PATH. Checking installed programs and repairing PATH...
call :find_installed_r
if defined RSCRIPT_EXE (
  call :save_r_path
  goto :r_ready
)

echo R is not installed. Trying to install the latest R for Windows...
where winget >nul 2>&1
if errorlevel 1 (
  echo.
  echo [ERROR] Windows Package Manager is unavailable.
  echo Install R manually from https://cran.r-project.org/bin/windows/base/
  goto :failed
)

winget install --id RProject.R -e --source winget --accept-source-agreements --accept-package-agreements
if errorlevel 1 (
  echo.
  echo [ERROR] R could not be installed automatically.
  echo Install R manually from https://cran.r-project.org/bin/windows/base/
  goto :failed
)

call :find_installed_r
if not defined RSCRIPT_EXE (
  echo.
  echo R appears to be installed, but Rscript.exe could not be located.
  echo Restart Windows and run this file again.
  goto :failed
)
call :save_r_path

:r_ready
call :validate_r
if errorlevel 1 goto :failed
call :configure_r_library
if errorlevel 1 goto :failed

echo R found:
echo %RSCRIPT_EXE%
echo Detected R version: %R_VERSION%
echo R library version key: %R_VERSION_KEY%
echo Customer runtime library: %R_LIBS_USER%
echo.
echo Checking and installing required R packages. The first run may take a while.

"%RSCRIPT_EXE%" --vanilla "%PROJECT_DIR%\scripts\setup_dashboard_dependencies.R" >>"%SETUP_LOG%" 2>&1
set "INSTALL_RESULT=%ERRORLEVEL%"
if not "%INSTALL_RESULT%"=="0" (
  echo.
  echo [ERROR] Dashboard dependency setup failed.
  echo Please review the log:
  echo %SETUP_LOG%
  goto :failed
)

echo.
echo Running the dashboard startup check...
"%RSCRIPT_EXE%" --vanilla "%PROJECT_DIR%\scripts\preflight_dashboard_startup.R" "%PROJECT_DIR%" >>"%SETUP_LOG%" 2>&1
if errorlevel 1 (
  echo.
  echo [ERROR] Dashboard startup check failed.
  echo Please review the log:
  echo %SETUP_LOG%
  goto :failed
)

powershell -NoProfile -Command "if (Get-NetTCPConnection -LocalPort %APP_PORT% -State Listen -ErrorAction SilentlyContinue) { exit 10 } else { exit 0 }"
if errorlevel 1 (
  echo.
  echo [ERROR] Port %APP_PORT% became occupied during setup. Another Dashboard instance or program may now be running.
  echo Close the existing Dashboard or process, then run this launcher again.
  echo If it was started by this launcher, run 03_Stop_Dashboard.cmd.
  goto :failed
)

echo.
echo Starting the dashboard at http://127.0.0.1:%APP_PORT%
echo Keep the new R window open while using the dashboard.
>"%SERVER_LOG%" echo HE Toolkit dashboard server log
>>"%SERVER_LOG%" echo Started: %DATE% %TIME%
>>"%SERVER_LOG%" echo Rscript: %RSCRIPT_EXE%
>>"%SERVER_LOG%" echo R version: %R_VERSION%
>>"%SERVER_LOG%" echo R library version key: %R_VERSION_KEY%
>>"%SERVER_LOG%" echo Customer runtime library: %R_LIBS_USER%
start "HE Toolkit Dashboard Server" /D "%PROJECT_DIR%" "%ComSpec%" /D /S /C ""%RSCRIPT_EXE%" --vanilla -e "shiny::runApp('.', port=%APP_PORT%, host='127.0.0.1', launch.browser=FALSE)" 1>>"%SERVER_LOG%" 2>&1"

echo Waiting for the dashboard to become ready...
powershell -NoProfile -Command "$url='http://127.0.0.1:%APP_PORT%'; $deadline=[DateTime]::UtcNow.AddSeconds(180); while([DateTime]::UtcNow -lt $deadline){ $remaining=[int][Math]::Ceiling(($deadline-[DateTime]::UtcNow).TotalSeconds); if($remaining -le 0){break}; try { $r=Invoke-WebRequest -UseBasicParsing -Uri $url -MaximumRedirection 5 -TimeoutSec ([Math]::Min(30,$remaining)); if($r.StatusCode -eq 200 -and $r.Content -match 'shiny' -and $r.Content -match 'HE Toolkit|Hydro-Ecology'){ exit 0 } } catch {}; if([DateTime]::UtcNow -lt $deadline){Start-Sleep -Seconds 1} }; exit 1"
if errorlevel 1 (
  echo.
  echo [ERROR] The website did not become ready within 180 seconds.
  echo Please review the server log:
  echo %SERVER_LOG%
  echo.
  echo Recent server messages:
  powershell -NoProfile -Command "if(Test-Path -LiteralPath $env:SERVER_LOG){Get-Content -LiteralPath $env:SERVER_LOG -Tail 12}"
  goto :failed
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PROJECT_DIR%\scripts\windows\record_dashboard_process.ps1" -Port %APP_PORT% -RscriptPath "%RSCRIPT_EXE%" -ProjectDirectory "%PROJECT_DIR%" -RuntimeDirectory "%RUN_DIR%" -RunStamp "%RUN_STAMP%" -ServerLog "%SERVER_LOG%"
if errorlevel 1 (
  echo.
  echo [ERROR] The Dashboard started, but its process ownership could not be recorded safely.
  echo No process was stopped. Please review the server log:
  echo %SERVER_LOG%
  goto :untracked
)

start "" "http://127.0.0.1:%APP_PORT%"
echo The dashboard responded successfully and has been opened in your browser.
echo To stop it later, run 03_Stop_Dashboard.cmd.

:success
echo.
echo [SUCCESS] Environment check completed.
echo.
pause
exit /b 0

:untracked
echo.
echo The Dashboard may still be running, but it could not be registered for safe stopping.
echo Close the Dashboard server window to stop it before trying again.
echo No project data was deleted.
echo.
pause
exit /b 1

:find_r
for /f "delims=" %%R in ('where Rscript.exe 2^>nul') do if not defined RSCRIPT_EXE set "RSCRIPT_EXE=%%R"
exit /b 0

:find_installed_r
for /f "usebackq delims=" %%R in (`powershell -NoProfile -Command "$c=@(); $roots=@((Join-Path $env:ProgramFiles 'R'),(Join-Path $env:LOCALAPPDATA 'Programs\R')); foreach($root in $roots){if(Test-Path $root){$c += Get-ChildItem $root -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending | ForEach-Object {Join-Path $_.FullName 'bin\Rscript.exe'}}}; $reg=@('HKLM:\SOFTWARE\R-core\R','HKLM:\SOFTWARE\WOW6432Node\R-core\R','HKCU:\SOFTWARE\R-core\R'); foreach($key in $reg){if(Test-Path $key){$p=(Get-ItemProperty $key).InstallPath; if($p){$c += Join-Path $p 'bin\Rscript.exe'}}}; $c | Where-Object {Test-Path $_} | Select-Object -First 1"`) do if not defined RSCRIPT_EXE set "RSCRIPT_EXE=%%R"
exit /b 0

:save_r_path
for %%D in ("%RSCRIPT_EXE%") do set "R_BIN=%%~dpD"
set "PATH=!R_BIN!;!PATH!"
powershell -NoProfile -Command "$bin=$env:R_BIN.TrimEnd('\'); $user=[Environment]::GetEnvironmentVariable('Path','User'); $parts=@($user -split ';' | Where-Object { $_ }); if($parts -notcontains $bin){[Environment]::SetEnvironmentVariable('Path',(($parts + $bin) -join ';'),'User'); Write-Host 'R was added to your user PATH.'} else {Write-Host 'R is already present in your user PATH.'}"
exit /b 0

:validate_r
if not defined RSCRIPT_EXE (
  echo.
  echo [ERROR] Rscript.exe could not be resolved to a usable path.
  echo Please review the log:
  echo %SETUP_LOG%
  >>"%SETUP_LOG%" echo Rscript validation failed: the resolved path was empty.
  exit /b 1
)
if not exist "%RSCRIPT_EXE%" (
  echo.
  echo [ERROR] The resolved Rscript.exe file does not exist:
  echo %RSCRIPT_EXE%
  echo Please review the log:
  echo %SETUP_LOG%
  >>"%SETUP_LOG%" echo Rscript validation failed: file not found: %RSCRIPT_EXE%
  exit /b 1
)
>>"%SETUP_LOG%" echo Validating Rscript: %RSCRIPT_EXE%
"%RSCRIPT_EXE%" --version >>"%SETUP_LOG%" 2>&1
if errorlevel 1 (
  echo.
  echo [ERROR] The resolved Rscript.exe could not be executed:
  echo %RSCRIPT_EXE%
  echo Please review the log:
  echo %SETUP_LOG%
  >>"%SETUP_LOG%" echo Rscript validation failed: --version returned a non-zero exit code.
  exit /b 1
)
exit /b 0

:configure_r_library
for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "& $env:RSCRIPT_EXE --vanilla -e 'cat(as.character(getRversion()))'"`) do if not defined R_VERSION set "R_VERSION=%%V"
if not defined R_VERSION (
  echo.
  echo [ERROR] The installed R version could not be detected.
  echo Please review the log:
  echo %SETUP_LOG%
  >>"%SETUP_LOG%" echo R version detection failed for: %RSCRIPT_EXE%
  exit /b 1
)
for /f "usebackq delims=" %%K in (`powershell -NoProfile -Command "$parts=$env:R_VERSION -split '\.'; if($parts.Length -lt 2){exit 1}; '{0}.{1}' -f $parts[0],$parts[1]"`) do if not defined R_VERSION_KEY set "R_VERSION_KEY=%%K"
if not defined R_VERSION_KEY (
  echo.
  echo [ERROR] The R major/minor library version could not be derived.
  echo Please review the log:
  echo %SETUP_LOG%
  >>"%SETUP_LOG%" echo R library version-key detection failed for version: %R_VERSION%
  exit /b 1
)
set "R_LIBS_USER=%R_LIBRARY_ROOT%\%R_VERSION_KEY%"
if not exist "%R_LIBS_USER%" mkdir "%R_LIBS_USER%"
if errorlevel 1 (
  echo [ERROR] A writable version-specific R package folder could not be created.
  echo Please review the log:
  echo %SETUP_LOG%
  >>"%SETUP_LOG%" echo Customer runtime library creation failed: %R_LIBS_USER%
  exit /b 1
)
>>"%SETUP_LOG%" echo Detected R version: %R_VERSION%
>>"%SETUP_LOG%" echo R library version key: %R_VERSION_KEY%
>>"%SETUP_LOG%" echo Previous unversioned library: %R_LIBRARY_ROOT%
>>"%SETUP_LOG%" echo Customer runtime library: %R_LIBS_USER%
exit /b 0

:failed
echo.
echo The dashboard was not started. No project data was deleted.
echo.
pause
exit /b 1
