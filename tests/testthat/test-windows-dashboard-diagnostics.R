testthat::test_that("Windows customer diagnostic assets are complete", {
  root <- normalizePath(testthat::test_path("..", ".."), winslash = "/", mustWork = TRUE)
  paths <- file.path(
    root,
    c(
      "03_Run_Dashboard_With_Diagnostics.cmd",
      "scripts/dashboard_diagnostic_helpers.ps1",
      "scripts/preflight_dashboard_diagnostics.R",
      "scripts/run_dashboard_diagnostics.ps1",
      "scripts/run_dashboard_for_diagnostics.R",
      "docs/operations/windows-customer-crash-diagnostics.md",
      "tests/powershell/test_dashboard_diagnostic_helpers.ps1"
    )
  )

  testthat::expect_true(all(file.exists(paths)))
})

testthat::test_that("the monitor distinguishes a live busy process from a crash", {
  root <- normalizePath(testthat::test_path("..", ".."), winslash = "/", mustWork = TRUE)
  monitor <- paste(
    readLines(file.path(root, "scripts/run_dashboard_diagnostics.ps1"), warn = FALSE),
    collapse = "\n"
  )
  helper <- paste(
    readLines(file.path(root, "scripts/dashboard_diagnostic_helpers.ps1"), warn = FALSE),
    collapse = "\n"
  )

  testthat::expect_match(monitor, "STILL RUNNING", fixed = TRUE)
  testthat::expect_match(monitor, "BUSY_OR_UNRESPONSIVE", fixed = TRUE)
  testthat::expect_match(monitor, "ProcessAlive = \\$true")
  testthat::expect_match(monitor, "Threads.Count", fixed = TRUE)
  testthat::expect_match(monitor, "PrivateMemorySize64", fixed = TRUE)
  testthat::expect_match(monitor, "Get-WinEvent", fixed = TRUE)
  testthat::expect_match(monitor, "Compress-Archive", fixed = TRUE)
  testthat::expect_match(helper, "MEMORY_CRASH_CONFIRMED", fixed = TRUE)
  testthat::expect_match(helper, "NATIVE_CRASH_CONFIRMED", fixed = TRUE)
  testthat::expect_match(helper, "UNEXPECTED_EXIT", fixed = TRUE)
})

testthat::test_that("PowerShell helper classifications pass on Windows", {
  testthat::skip_if(.Platform$OS.type != "windows")

  powershell <- Sys.which("powershell.exe")
  testthat::skip_if(!nzchar(powershell), "Windows PowerShell is unavailable")

  script <- normalizePath(
    testthat::test_path("..", "powershell", "test_dashboard_diagnostic_helpers.ps1"),
    winslash = "\\",
    mustWork = TRUE
  )
  output <- system2(
    powershell,
    c("-NoLogo", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", shQuote(script)),
    stdout = TRUE,
    stderr = TRUE
  )
  status <- attr(output, "status")
  if (is.null(status)) status <- 0L

  testthat::expect_equal(status, 0L, info = paste(output, collapse = "\n"))
  testthat::expect_true(any(grepl("PASS: dashboard diagnostic helper tests", output, fixed = TRUE)))
})
