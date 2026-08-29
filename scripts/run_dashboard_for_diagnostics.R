args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2L) {
  stop("Usage: run_dashboard_for_diagnostics.R <project-directory> <port>")
}

project_dir <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
port <- suppressWarnings(as.integer(args[[2L]]))

if (is.na(port) || port < 1L || port > 65535L) {
  stop("The diagnostic launcher received an invalid port.")
}

options(
  shiny.fullstacktrace = TRUE,
  shiny.sanitize.errors = FALSE,
  warn = 1
)

write_marker <- function(name, value = "") {
  timestamp <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
  cat(sprintf("HE_TOOLKIT_DIAGNOSTIC|%s|%s|%s\n", timestamp, name, value))
  flush.console()
}

write_marker("R_START", paste(R.version.string, R.version$arch, sep = " | "))
write_marker("PROJECT_DIR", project_dir)
write_marker("PORT", port)

packages <- c("shiny", "hetoolkit", "DT", "dplyr", "shinybusy")
for (package in packages) {
  version <- if (requireNamespace(package, quietly = TRUE)) {
    as.character(utils::packageVersion(package))
  } else {
    "NOT_INSTALLED"
  }
  write_marker("PACKAGE", paste(package, version, sep = "="))
}

if (!requireNamespace("shiny", quietly = TRUE)) {
  write_marker("STARTUP_FAILURE", "The shiny package is not installed.")
  quit(save = "no", status = 20L, runLast = FALSE)
}

status <- tryCatch(
  {
    write_marker("RUN_APP", "starting")
    shiny::runApp(
      appDir = project_dir,
      port = port,
      host = "127.0.0.1",
      launch.browser = FALSE
    )
    write_marker("RUN_APP", "stopped normally")
    0L
  },
  error = function(error) {
    write_marker("FATAL_R_ERROR", conditionMessage(error))
    calls <- sys.calls()
    if (length(calls) > 0L) {
      cat("HE_TOOLKIT_DIAGNOSTIC|CALL_STACK_BEGIN\n", file = stderr())
      for (call in utils::tail(calls, 30L)) {
        cat(paste(deparse(call), collapse = " "), "\n", file = stderr())
      }
      cat("HE_TOOLKIT_DIAGNOSTIC|CALL_STACK_END\n", file = stderr())
    }
    flush(stderr())
    70L
  }
)

quit(save = "no", status = status, runLast = FALSE)
