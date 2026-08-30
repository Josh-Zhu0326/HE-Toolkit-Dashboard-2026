launcher_path <- "02_Setup_R_and_Run_Dashboard.cmd"
if (!file.exists(launcher_path)) {
  launcher_path <- file.path("..", "..", launcher_path)
}

launcher_lines <- readLines(launcher_path, warn = FALSE)

project_file <- function(...) {
  path <- file.path(...)
  if (!file.exists(path)) {
    path <- file.path("..", "..", ...)
  }
  path
}

stop_launcher_path <- project_file("03_Stop_Dashboard.cmd")
identity_helper_path <- project_file("scripts", "windows", "rscript_process_identity.ps1")
record_helper_path <- project_file("scripts", "windows", "record_dashboard_process.ps1")
stop_helper_path <- project_file("scripts", "windows", "stop_dashboard_process.ps1")

stop_launcher_lines <- readLines(stop_launcher_path, warn = FALSE)
identity_helper_lines <- readLines(identity_helper_path, warn = FALSE)
record_helper_lines <- readLines(record_helper_path, warn = FALSE)
stop_helper_lines <- readLines(stop_helper_path, warn = FALSE)

script_text <- function(lines) paste(lines, collapse = "\n")

script_line_number <- function(lines, pattern) {
  matches <- grep(pattern, lines, fixed = TRUE)
  testthat::expect_true(length(matches) > 0L, info = paste("Missing script text:", pattern))
  matches[[1L]]
}

line_number <- function(pattern) {
  matches <- grep(pattern, launcher_lines, fixed = TRUE)
  testthat::expect_true(length(matches) > 0L, info = paste("Missing launcher text:", pattern))
  matches[[1L]]
}

testthat::test_that("an occupied Dashboard port is rejected instead of reused", {
  guard_start <- line_number("Get-NetTCPConnection -LocalPort %APP_PORT%")
  setup_start <- line_number("scripts\\setup_dashboard_dependencies.R")
  occupied_port_path <- paste(launcher_lines[guard_start:(setup_start - 1L)], collapse = "\n")
  browser_opens <- grep('start "" "http://127.0.0.1:%APP_PORT%"', launcher_lines, fixed = TRUE)

  testthat::expect_match(occupied_port_path, "Port %APP_PORT% is already in use", fixed = TRUE)
  testthat::expect_match(occupied_port_path, "Close the existing Dashboard or process", fixed = TRUE)
  testthat::expect_match(occupied_port_path, "goto :failed", fixed = TRUE)
  testthat::expect_false(grepl("Invoke-WebRequest", occupied_port_path, fixed = TRUE))
  testthat::expect_false(grepl("start \"\" \"http://127.0.0.1:%APP_PORT%\"", occupied_port_path, fixed = TRUE))
  testthat::expect_false(grepl("[SUCCESS]", occupied_port_path, fixed = TRUE))
  testthat::expect_false(any(grepl("Checking the existing local website", launcher_lines, fixed = TRUE)))
  testthat::expect_false(any(grepl("existing HE Toolkit dashboard", launcher_lines, fixed = TRUE)))
  testthat::expect_length(browser_opens, 1L)
  testthat::expect_gt(browser_opens, line_number("shiny::runApp"))
})

testthat::test_that("the occupied-port guard runs before setup and preflight", {
  port_guards <- grep("Get-NetTCPConnection -LocalPort %APP_PORT%", launcher_lines, fixed = TRUE)
  dependency_setup <- line_number("scripts\\setup_dashboard_dependencies.R")
  startup_preflight <- line_number("scripts\\preflight_dashboard_startup.R")
  server_launch <- line_number("shiny::runApp")

  testthat::expect_length(port_guards, 2L)
  testthat::expect_lt(port_guards[[1L]], dependency_setup)
  testthat::expect_lt(port_guards[[1L]], startup_preflight)
  testthat::expect_gt(port_guards[[2L]], startup_preflight)
  testthat::expect_lt(port_guards[[2L]], server_launch)
})

testthat::test_that("a free port launches a fresh Rscript server with the configured runtime", {
  launch_line <- launcher_lines[grep("shiny::runApp", launcher_lines, fixed = TRUE)]

  testthat::expect_length(launch_line, 1L)
  testthat::expect_match(launch_line, 'start "HE Toolkit Dashboard Server"', fixed = TRUE)
  testthat::expect_match(launch_line, '/D "%PROJECT_DIR%"', fixed = TRUE)
  testthat::expect_match(launch_line, '"%RSCRIPT_EXE%" --vanilla', fixed = TRUE)
  testthat::expect_match(launch_line, "shiny::runApp('.',", fixed = TRUE)
  testthat::expect_match(launch_line, "port=%APP_PORT%", fixed = TRUE)
  testthat::expect_match(launch_line, "host='127.0.0.1'", fixed = TRUE)
  testthat::expect_match(launch_line, "launch.browser=FALSE", fixed = TRUE)
})

testthat::test_that("the spawned Rscript process writes stdout and stderr to its server log", {
  launch_line <- launcher_lines[grep("shiny::runApp", launcher_lines, fixed = TRUE)]

  testthat::expect_length(launch_line, 1L)
  testthat::expect_match(launch_line, '"%ComSpec%" /D /S /C', fixed = TRUE)
  testthat::expect_match(launch_line, '1>>"%SERVER_LOG%" 2>&1"', fixed = TRUE)
})

testthat::test_that("the launcher records the actual fresh Dashboard listener PID", {
  launcher_text <- script_text(launcher_lines)
  recorder_text <- script_text(record_helper_lines)

  testthat::expect_match(launcher_text, 'set "RUN_DIR=%LOCALAPPDATA%\\HE-Toolkit\\run"', fixed = TRUE)
  testthat::expect_match(launcher_text, 'record_dashboard_process.ps1" -Port %APP_PORT%', fixed = TRUE)
  testthat::expect_match(launcher_text, '-RscriptPath "%RSCRIPT_EXE%"', fixed = TRUE)
  testthat::expect_match(recorder_text, "Get-NetTCPConnection -LocalPort $Port -State Listen", fixed = TRUE)
  testthat::expect_match(recorder_text, "Select-Object -ExpandProperty OwningProcess -Unique", fixed = TRUE)
  testthat::expect_match(recorder_text, '$dashboardPid = [int]$ownerIds[0]', fixed = TRUE)
  testthat::expect_match(recorder_text, 'Join-Path $RuntimeDirectory "dashboard.pid"', fixed = TRUE)
  testthat::expect_match(recorder_text, 'Join-Path $RuntimeDirectory "dashboard.json"', fixed = TRUE)
})

testthat::test_that("the recorded PID is verified as Rscript rather than the cmd wrapper", {
  recorder_text <- script_text(record_helper_lines)

  testthat::expect_match(recorder_text, 'Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $dashboardPid"', fixed = TRUE)
  testthat::expect_match(recorder_text, 'if ([string]$process.Name -ine $expectedProcessName)', fixed = TRUE)
  testthat::expect_match(recorder_text, 'Test-EquivalentRscriptExecutable -ExpectedPath $expectedRscript -ActualPath $actualExecutable', fixed = TRUE)
  testthat::expect_match(recorder_text, '"shiny::runApp"', fixed = TRUE)
  testthat::expect_match(recorder_text, 'pid = $dashboardPid', fixed = TRUE)
  testthat::expect_match(recorder_text, 'launcherRscriptPath = $expectedRscript', fixed = TRUE)
  testthat::expect_match(recorder_text, 'executablePath = $actualExecutable', fixed = TRUE)
  testthat::expect_false(grepl('pid = $PID', recorder_text, fixed = TRUE))
})

testthat::test_that("Windows R bin and bin architecture executables are narrowly equivalent", {
  identity_text <- script_text(identity_helper_lines)

  testthat::expect_match(identity_text, 'FileInfo.FullName expands Windows 8.3 path segments', fixed = TRUE)
  testthat::expect_match(identity_text, '$role = "bin-front-end"', fixed = TRUE)
  testthat::expect_match(identity_text, '$directory.Name -ieq "x64" -or $directory.Name -ieq "i386"', fixed = TRUE)
  testthat::expect_match(identity_text, '$role = "architecture-runtime"', fixed = TRUE)
  testthat::expect_match(identity_text, '$expected.InstallationRoot -ieq $actual.InstallationRoot', fixed = TRUE)
  testthat::expect_match(identity_text, '$expected.FileVersion -eq $actual.FileVersion', fixed = TRUE)
})

testthat::test_that("the executable relationship accepts real bin to bin x64 but rejects unrelated programs", {
  if (.Platform$OS.type != "windows") {
    testthat::skip("Windows executable-layout regression")
  }

  powershell <- Sys.which("powershell.exe")
  testthat::skip_if(!nzchar(powershell), "Windows PowerShell is unavailable")

  current_rscript <- normalizePath(Sys.which("Rscript"), winslash = "/", mustWork = TRUE)
  current_directory <- dirname(current_rscript)
  if (tolower(basename(current_directory)) %in% c("x64", "i386")) {
    installation_root <- dirname(dirname(current_directory))
    architecture <- basename(current_directory)
  } else {
    installation_root <- dirname(current_directory)
    architecture <- if (grepl("64", R.version$arch, fixed = TRUE)) "x64" else "i386"
  }

  front_end <- file.path(installation_root, "bin", "Rscript.exe")
  architecture_runtime <- file.path(installation_root, "bin", architecture, "Rscript.exe")
  testthat::skip_if(!file.exists(front_end) || !file.exists(architecture_runtime), "This R installation has no bin-to-architecture handoff")
  reported_runtime <- utils::shortPathName(architecture_runtime)

  quote_for_powershell <- function(path) gsub("'", "''", normalizePath(path, winslash = "/", mustWork = TRUE), fixed = TRUE)
  quote_existing_path <- function(path) gsub("'", "''", path, fixed = TRUE)
  command <- paste0(
    ". '", quote_for_powershell(identity_helper_path), "'; ",
    "if (-not (Test-EquivalentRscriptExecutable -ExpectedPath '", quote_for_powershell(front_end),
    "' -ActualPath '", quote_existing_path(reported_runtime), "')) { exit 1 }; ",
    "if (Test-EquivalentRscriptExecutable -ExpectedPath '", quote_for_powershell(front_end),
    "' -ActualPath $env:ComSpec) { exit 2 }; exit 0"
  )
  output <- system2(
    powershell,
    c("-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", shQuote(command)),
    stdout = TRUE,
    stderr = TRUE
  )
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L

  testthat::expect_equal(status, 0L, info = paste(output, collapse = "\n"))
})

testthat::test_that("executable mismatches report directly actionable diagnostics", {
  recorder_text <- script_text(record_helper_lines)

  testthat::expect_match(recorder_text, "Listener PID: $dashboardPid", fixed = TRUE)
  testthat::expect_match(recorder_text, "Expected Rscript executable: $expectedRscript", fixed = TRUE)
  testthat::expect_match(recorder_text, "Actual listener executable: $actualExecutable", fixed = TRUE)
})

testthat::test_that("the non-technical Dashboard stop launcher exists", {
  testthat::expect_true(file.exists(stop_launcher_path))
  stop_launcher_text <- script_text(stop_launcher_lines)

  testthat::expect_match(stop_launcher_text, "HE Toolkit Dashboard - Stop App", fixed = TRUE)
  testthat::expect_match(stop_launcher_text, "Stopping the HE Toolkit Dashboard", fixed = TRUE)
  testthat::expect_match(stop_launcher_text, "stop_dashboard_process.ps1", fixed = TRUE)
  testthat::expect_match(stop_launcher_text, "pause", fixed = TRUE)
})

testthat::test_that("the stop workflow never blanket-kills Rscript", {
  all_stop_text <- paste(script_text(stop_launcher_lines), script_text(stop_helper_lines), sep = "\n")

  testthat::expect_false(grepl("taskkill", tolower(all_stop_text), fixed = TRUE))
  testthat::expect_false(grepl("/im rscript.exe", tolower(all_stop_text), fixed = TRUE))
  testthat::expect_match(all_stop_text, 'Stop-Process -InputObject $nativeProcess', fixed = TRUE)
})

testthat::test_that("the stop workflow does not select a kill target from port 3838", {
  stop_text <- script_text(stop_helper_lines)
  stop_line <- script_line_number(stop_helper_lines, 'Stop-Process -InputObject $nativeProcess')
  port_check_line <- script_line_number(stop_helper_lines, "Get-NetTCPConnection -LocalPort $ExpectedPort")

  testthat::expect_match(stop_text, 'Get-Content -LiteralPath $pidPath -Raw', fixed = TRUE)
  testthat::expect_match(stop_text, 'Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $recordedPid"', fixed = TRUE)
  testthat::expect_gt(port_check_line, stop_line)
  testthat::expect_false(grepl("OwningProcess -Unique", stop_text, fixed = TRUE))
})

testthat::test_that("a missing PID record is a safe already-stopped result", {
  no_pid_start <- script_line_number(stop_helper_lines, 'if (-not (Test-Path -LiteralPath $pidPath -PathType Leaf))')
  pid_read <- script_line_number(stop_helper_lines, '$pidText = (Get-Content -LiteralPath $pidPath -Raw).Trim()')
  no_pid_path <- paste(stop_helper_lines[no_pid_start:(pid_read - 1L)], collapse = "\n")

  testthat::expect_match(no_pid_path, "No launcher-started Dashboard is currently recorded", fixed = TRUE)
  testthat::expect_match(no_pid_path, "The Dashboard is already stopped", fixed = TRUE)
  testthat::expect_match(no_pid_path, "exit 0", fixed = TRUE)
  testthat::expect_false(grepl("Stop-Process", no_pid_path, fixed = TRUE))
})

testthat::test_that("a stale nonexistent PID is cleaned without termination", {
  stale_start <- script_line_number(stop_helper_lines, 'if ($null -eq $nativeProcess)')
  ownership_start <- script_line_number(stop_helper_lines, '$ownershipErrors = New-Object')
  stale_path <- paste(stop_helper_lines[stale_start:(ownership_start - 1L)], collapse = "\n")

  testthat::expect_match(stale_path, "Remove-RuntimeRecord", fixed = TRUE)
  testthat::expect_match(stale_path, "already stopped", fixed = TRUE)
  testthat::expect_match(stale_path, "exit 0", fixed = TRUE)
  testthat::expect_false(grepl("Stop-Process", stale_path, fixed = TRUE))
})

testthat::test_that("PID ownership is fully verified before termination", {
  stop_line <- script_line_number(stop_helper_lines, 'Stop-Process -InputObject $nativeProcess')
  checks <- c(
    'process.Name -ine [string]$metadata.processName',
    '$actualExecutable -ine $expectedExecutable',
    'Test-EquivalentRscriptExecutable -ExpectedPath $launcherExecutable -ActualPath $actualExecutable',
    '$currentCommandLine -cne [string]$metadata.commandLine',
    '"shiny::runApp"',
    '$currentStartTimeUtc -cne [string]$metadata.processStartTimeUtc'
  )

  for (check in checks) {
    testthat::expect_lt(script_line_number(stop_helper_lines, check), stop_line)
  }
})

testthat::test_that("command-line mismatches remain fatal to ownership verification", {
  stop_line <- script_line_number(stop_helper_lines, 'Stop-Process -InputObject $nativeProcess')
  exact_command_line_check <- script_line_number(stop_helper_lines, '$currentCommandLine -cne [string]$metadata.commandLine')
  marker_loop <- script_line_number(stop_helper_lines, 'foreach ($requiredText in $requiredCommandText)')
  refusal <- script_line_number(stop_helper_lines, 'if ($ownershipErrors.Count -gt 0)')

  testthat::expect_lt(exact_command_line_check, refusal)
  testthat::expect_lt(marker_loop, refusal)
  testthat::expect_lt(refusal, stop_line)
})

testthat::test_that("a PID ownership mismatch refuses termination", {
  mismatch_start <- script_line_number(stop_helper_lines, 'if ($ownershipErrors.Count -gt 0)')
  stop_line <- script_line_number(stop_helper_lines, 'Stop-Process -InputObject $nativeProcess')
  mismatch_path <- paste(stop_helper_lines[mismatch_start:(stop_line - 1L)], collapse = "\n")

  testthat::expect_match(mismatch_path, "Process ownership could not be verified", fixed = TRUE)
  testthat::expect_match(mismatch_path, "was not stopped", fixed = TRUE)
  testthat::expect_match(mismatch_path, "throw", fixed = TRUE)
  testthat::expect_false(grepl("Remove-RuntimeRecord", mismatch_path, fixed = TRUE))
})

testthat::test_that("successful shutdown waits and then removes its runtime record", {
  stop_line <- script_line_number(stop_helper_lines, 'Stop-Process -InputObject $nativeProcess')
  wait_line <- script_line_number(stop_helper_lines, '$nativeProcess.WaitForExit(10000)')
  cleanup_lines <- grep("Remove-RuntimeRecord -PidPath", stop_helper_lines, fixed = TRUE)
  success_line <- script_line_number(stop_helper_lines, 'Write-Host "Dashboard stopped successfully."')

  testthat::expect_gt(wait_line, stop_line)
  testthat::expect_true(any(cleanup_lines > wait_line))
  testthat::expect_lt(cleanup_lines[cleanup_lines > wait_line][[1L]], success_line)
})

testthat::test_that("occupied-port protection remains intact with stop guidance", {
  first_guard <- line_number("Get-NetTCPConnection -LocalPort %APP_PORT%")
  dependency_setup <- line_number("scripts\\setup_dashboard_dependencies.R")
  occupied_path <- paste(launcher_lines[first_guard:(dependency_setup - 1L)], collapse = "\n")

  testthat::expect_match(occupied_path, "Port %APP_PORT% is already in use", fixed = TRUE)
  testthat::expect_match(occupied_path, "run 03_Stop_Dashboard.cmd", fixed = TRUE)
  testthat::expect_match(occupied_path, "goto :failed", fixed = TRUE)
  testthat::expect_false(grepl("taskkill", tolower(occupied_path), fixed = TRUE))
  testthat::expect_false(grepl("call 03_stop_dashboard.cmd", tolower(occupied_path), fixed = TRUE))
  testthat::expect_false(grepl("start 03_stop_dashboard.cmd", tolower(occupied_path), fixed = TRUE))
})
