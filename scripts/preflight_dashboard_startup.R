preflight_dashboard_startup <- function(project_dir) {
  if (!dir.exists(project_dir)) {
    stop("The dashboard project directory does not exist: ", project_dir,
         call. = FALSE)
  }

  project_dir <- normalizePath(project_dir, winslash = "/", mustWork = TRUE)
  old_working_directory <- setwd(project_dir)
  on.exit(setwd(old_working_directory), add = TRUE)

  required_files <- c(
    "global.R",
    "ui.R",
    "server.R",
    file.path("scripts", "setup_dashboard_dependencies.R")
  )
  missing_files <- required_files[!file.exists(required_files)]
  if (length(missing_files)) {
    stop("Required application files are missing: ",
         paste(missing_files, collapse = ", "), call. = FALSE)
  }
  if (!dir.exists("R")) {
    stop("The required R helper directory is missing: R", call. = FALSE)
  }
  if (!dir.exists("www")) {
    stop("The required dashboard resource directory is missing: www", call. = FALSE)
  }

  helper_files <- sort(list.files("R", pattern = "[.]R$", full.names = TRUE))
  if (!length(helper_files)) {
    stop("No R helper files were found under R/.", call. = FALSE)
  }

  parse_files <- c("global.R", "ui.R", "server.R", helper_files)
  for (path in parse_files) {
    tryCatch(
      parse(file = path, keep.source = FALSE),
      error = function(error) {
        stop("R syntax check failed for ", path, ": ", conditionMessage(error),
             call. = FALSE)
      }
    )
  }
  cat("Parsed", length(helper_files), "R helper files and all application entry files.\n")

  dependency_definitions <- new.env(parent = baseenv())
  sys.source(
    file.path("scripts", "setup_dashboard_dependencies.R"),
    envir = dependency_definitions
  )
  startup_packages <- dependency_definitions$dashboard_startup_packages
  if (!length(startup_packages)) {
    stop("The startup dependency definition is empty.", call. = FALSE)
  }

  load_failures <- character()
  for (package in startup_packages) {
    failure <- tryCatch(
      {
        suppressPackageStartupMessages(
          library(package, character.only = TRUE, quietly = TRUE, warn.conflicts = FALSE)
        )
        NULL
      },
      error = function(error) conditionMessage(error)
    )
    if (!is.null(failure)) {
      load_failures <- c(load_failures, sprintf("%s (%s)", package, failure))
    }
  }
  if (length(load_failures)) {
    stop("Startup packages could not be loaded: ",
         paste(load_failures, collapse = "; "), call. = FALSE)
  }
  cat("Loaded", length(startup_packages), "startup-required packages.\n")

  app_environment <- new.env(parent = globalenv())
  tryCatch(
    sys.source("global.R", envir = app_environment),
    error = function(error) {
      stop("global.R startup execution failed: ", conditionMessage(error),
           call. = FALSE)
    }
  )
  cat("global.R executed successfully from the project root.\n")

  ui_result <- tryCatch(
    source("ui.R", local = app_environment, chdir = FALSE)$value,
    error = function(error) {
      stop("ui.R startup evaluation failed: ", conditionMessage(error),
           call. = FALSE)
    }
  )
  if (is.null(ui_result)) {
    stop("ui.R did not produce a Shiny UI object.", call. = FALSE)
  }
  cat("ui.R evaluated successfully.\n")

  server_result <- tryCatch(
    source("server.R", local = app_environment, chdir = FALSE)$value,
    error = function(error) {
      stop("server.R startup evaluation failed: ", conditionMessage(error),
           call. = FALSE)
    }
  )
  if (!is.function(server_result)) {
    stop("server.R did not produce a Shiny server function.", call. = FALSE)
  }
  cat("server.R evaluated successfully and produced a server function.\n")
  cat("Dashboard startup preflight passed.\n")
  invisible(TRUE)
}

arguments <- commandArgs(trailingOnly = TRUE)
project_directory <- if (length(arguments)) arguments[[1L]] else getwd()

status <- tryCatch(
  {
    preflight_dashboard_startup(project_directory)
    0L
  },
  error = function(error) {
    message("Dashboard startup check failed: ", conditionMessage(error))
    1L
  }
)
quit(save = "no", status = status, runLast = FALSE)
