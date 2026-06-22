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
echo R found:
"%RSCRIPT_EXE%" --version
echo.
echo Checking and installing required R packages. The first run may take a while.

set "R_LIBS_USER=%LOCALAPPDATA%\HE-Toolkit\R-library"
if not exist "%R_LIBS_USER%" mkdir "%R_LIBS_USER%"
if errorlevel 1 (
  echo [ERROR] A writable personal R package folder could not be created.
  goto :failed
)

set "SETUP_R=%TEMP%\he_toolkit_setup_%RANDOM%_%RANDOM%.R"
>"%SETUP_R%" echo options(repos = c(CRAN = "https://cloud.r-project.org"), timeout = 1200, pkgType = "binary")
>>"%SETUP_R%" echo dir.create(Sys.getenv("R_LIBS_USER"), recursive = TRUE, showWarnings = FALSE)
>>"%SETUP_R%" echo .libPaths(c(Sys.getenv("R_LIBS_USER"), .libPaths()))
>>"%SETUP_R%" echo cran_packages ^<- c("shiny", "bslib", "rsconnect", "shinybusy", "shinyWidgets", "shinyalert", "fontawesome", "dplyr", "tidyr", "purrr", "stringr", "sjmisc", "naniar", "DT", "data.table", "kableExtra", "ggplot2", "gridExtra", "GGally", "leaflet", "rnrfa", "plotly", "viridis", "ggnewscale", "ggpubr", "lubridate", "readr", "tibble", "RColorBrewer", "remotes")
>>"%SETUP_R%" echo missing ^<- cran_packages[vapply(cran_packages, requireNamespace, logical(1), quietly = TRUE) == FALSE]
>>"%SETUP_R%" echo if (length(missing)) install.packages(missing, dependencies = NA, type = "binary")
>>"%SETUP_R%" echo if (requireNamespace("hetoolkit", quietly = TRUE) == FALSE) remotes::install_github("APEM-LTD/hetoolkit", dependencies = NA, upgrade = "never")
>>"%SETUP_R%" echo required ^<- c(setdiff(cran_packages, "remotes"), "hetoolkit")
>>"%SETUP_R%" echo still_missing ^<- required[vapply(required, requireNamespace, logical(1), quietly = TRUE) == FALSE]
>>"%SETUP_R%" echo if (length(still_missing)) stop("Missing packages after installation: ", paste(still_missing, collapse = ", "))
>>"%SETUP_R%" echo cat("All required R packages are available.\n")

"%RSCRIPT_EXE%" "%SETUP_R%"
set "INSTALL_RESULT=%ERRORLEVEL%"
del "%SETUP_R%" >nul 2>&1
if not "%INSTALL_RESULT%"=="0" (
  echo.
  echo [ERROR] One or more R packages could not be installed.
  echo Check the messages above and the internet connection, then run this file again.
  goto :failed
)

echo.
echo Checking the dashboard files for R syntax errors...
"%RSCRIPT_EXE%" --vanilla -e "invisible(lapply(c('global.R','ui.R','server.R'), parse)); cat('Syntax check passed.\n')"
if errorlevel 1 (
  echo.
  echo [ERROR] The dashboard contains an R syntax error and was not started.
  goto :failed
)

powershell -NoProfile -Command "if (Get-NetTCPConnection -LocalPort %APP_PORT% -State Listen -ErrorAction SilentlyContinue) { exit 10 } else { exit 0 }"
if "%ERRORLEVEL%"=="10" (
  echo.
  echo Port %APP_PORT% is already in use. Checking the existing local website...
  powershell -NoProfile -Command "$r=Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:%APP_PORT%' -TimeoutSec 5; if($r.StatusCode -eq 200 -and $r.Content -match 'HE Toolkit|Hydro-Ecology'){exit 0}else{exit 1}"
  if errorlevel 1 (
    echo [ERROR] Port %APP_PORT% is being used by another program or an unresponsive website.
    echo Close that program, then run this file again.
    goto :failed
  )
  start "" "http://127.0.0.1:%APP_PORT%"
  echo The existing HE Toolkit dashboard responded successfully and was opened.
  goto :success
)

echo.
echo Starting the dashboard at http://127.0.0.1:%APP_PORT%
echo Keep the new R window open while using the dashboard.
start "HE Toolkit Dashboard Server" /D "%PROJECT_DIR%" "%RSCRIPT_EXE%" --vanilla -e "shiny::runApp('.', port=%APP_PORT%, host='127.0.0.1', launch.browser=FALSE)"

echo Waiting for the dashboard to become ready...
powershell -NoProfile -Command "$url='http://127.0.0.1:%APP_PORT%'; for($i=0;$i -lt 60;$i++){ try { $r=Invoke-WebRequest -UseBasicParsing -Uri $url -TimeoutSec 2; if($r.StatusCode -ge 200 -and $r.StatusCode -lt 500){ exit 0 } } catch {}; Start-Sleep -Seconds 1 }; exit 1"
if errorlevel 1 (
  echo.
  echo [ERROR] The website did not respond within 60 seconds.
  echo Review the messages in the R server window.
  goto :failed
)

start "" "http://127.0.0.1:%APP_PORT%"
echo The dashboard responded successfully and has been opened in your browser.

:success
echo.
echo [SUCCESS] Environment check completed.
echo.
pause
exit /b 0

:find_r
for /f "delims=" %%R in ('where Rscript.exe 2^>nul') do if not defined RSCRIPT_EXE set "RSCRIPT_EXE=%%R"
exit /b 0

:find_installed_r
for /f "usebackq delims=" %%R in (`powershell -NoProfile -Command "$c=@(); $roots=@((Join-Path $env:ProgramFiles 'R'),(Join-Path $env:LOCALAPPDATA 'Programs\R')); foreach($root in $roots){if(Test-Path $root){$c += Get-ChildItem $root -Directory -ErrorAction SilentlyContinue ^| Sort-Object Name -Descending ^| ForEach-Object {Join-Path $_.FullName 'bin\Rscript.exe'}}}; $reg=@('HKLM:\SOFTWARE\R-core\R','HKLM:\SOFTWARE\WOW6432Node\R-core\R','HKCU:\SOFTWARE\R-core\R'); foreach($key in $reg){if(Test-Path $key){$p=(Get-ItemProperty $key).InstallPath; if($p){$c += Join-Path $p 'bin\Rscript.exe'}}}; $c ^| Where-Object {Test-Path $_} ^| Select-Object -First 1"`) do if not defined RSCRIPT_EXE set "RSCRIPT_EXE=%%R"
exit /b 0

:save_r_path
for %%D in ("%RSCRIPT_EXE%") do set "R_BIN=%%~dpD"
set "PATH=!R_BIN!;!PATH!"
powershell -NoProfile -Command "$bin=$env:R_BIN.TrimEnd('\'); $user=[Environment]::GetEnvironmentVariable('Path','User'); $parts=@($user -split ';' ^| Where-Object { $_ }); if($parts -notcontains $bin){[Environment]::SetEnvironmentVariable('Path',(($parts + $bin) -join ';'),'User'); Write-Host 'R was added to your user PATH.'} else {Write-Host 'R is already present in your user PATH.'}"
exit /b 0

:failed
echo.
echo The dashboard was not started. No project data was deleted.
echo.
pause
exit /b 1
