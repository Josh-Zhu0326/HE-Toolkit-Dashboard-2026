script_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_argument) != 1L) {
  stop(
    "Unable to resolve scripts/run_task_oriented_workflow_evidence.R.",
    call. = FALSE
  )
}
script_path <- normalizePath(
  sub("^--file=", "", script_argument),
  winslash = "/",
  mustWork = TRUE
)
repo_root_from_script <- dirname(dirname(script_path))
source(file.path(
  repo_root_from_script,
  "scripts",
  "task_oriented_workflow_evidence_helpers.R"
))

task_workflow_evidence_run_git_command <- function(arguments, repo_root) {
  output <- suppressWarnings(system2(
    "git",
    c("-C", shQuote(repo_root), arguments),
    stdout = TRUE,
    stderr = TRUE
  ))
  status <- task_workflow_evidence_or(attr(output, "status"), 0L)
  if (!identical(as.integer(status), 0L)) {
    stop(
      "Git metadata could not be collected for task-oriented workflow evidence.",
      call. = FALSE
    )
  }
  output
}

task_workflow_evidence_format_child_environment <- function(values) {
  paste0(names(values), "=", vapply(values, shQuote, character(1)))
}

task_workflow_evidence_run_logged_command <- function(
    command,
    arguments,
    log_path,
    env = character()) {
  started <- Sys.time()
  raw_log <- tempfile("hetoolkit-command-", fileext = ".log")
  on.exit(unlink(raw_log, force = TRUE), add = TRUE)
  status <- suppressWarnings(system2(
    command,
    arguments,
    stdout = raw_log,
    stderr = raw_log,
    env = env
  ))
  status <- task_workflow_evidence_or(
    attr(status, "status"),
    task_workflow_evidence_or(status, 0L)
  )
  status <- as.integer(status)
  lines <- if (file.exists(raw_log)) readLines(raw_log, warn = FALSE) else character()
  writeLines(c(
    sprintf("Command: %s %s", command, paste(arguments, collapse = " ")),
    sprintf("Started UTC: %s", format(started, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")),
    sprintf("Exit status: %d", status),
    "",
    lines
  ), log_path, useBytes = TRUE)
  list(
    status = status,
    duration_seconds = unname(difftime(Sys.time(), started, units = "secs")),
    warning_detected = task_workflow_evidence_log_has_warning(lines),
    log = log_path
  )
}

task_workflow_evidence_write_sha256_manifest <- function(output_dir) {
  files <- list.files(output_dir, recursive = TRUE, full.names = TRUE)
  files <- files[file.info(files)$isdir %in% FALSE]
  files <- files[basename(files) != "SHA256SUMS"]
  relative <- substring(files, nchar(output_dir) + 2L)
  rows <- vapply(seq_along(files), function(index) {
    output <- system2(
      "shasum",
      c("-a", "256", shQuote(files[[index]])),
      stdout = TRUE,
      stderr = TRUE
    )
    status <- task_workflow_evidence_or(attr(output, "status"), 0L)
    if (!identical(as.integer(status), 0L) || length(output) != 1L) {
      stop(sprintf("Unable to checksum %s.", relative[[index]]), call. = FALSE)
    }
    checksum <- strsplit(output, "[[:space:]]+")[[1L]][[1L]]
    sprintf("%s  %s", checksum, relative[[index]])
  }, character(1))
  writeLines(rows, file.path(output_dir, "SHA256SUMS"), useBytes = TRUE)
}

task_workflow_evidence_collect_package_versions <- function(
    runtime_library,
    output_path) {
  setup_environment <- new.env(parent = baseenv())
  sys.source(
    file.path(repo_root_from_script, "scripts", "setup_dashboard_dependencies.R"),
    envir = setup_environment
  )
  required <- setup_environment$dashboard_required_packages
  installed <- utils::installed.packages(
    lib.loc = unique(c(runtime_library, .Library)),
    fields = c("RemoteSha", "RemoteRef", "RemoteRepo", "RemoteUsername")
  )
  packages <- data.frame(
    package = rownames(installed),
    version = installed[, "Version"],
    library = installed[, "LibPath"],
    built = installed[, "Built"],
    remote_sha = installed[, "RemoteSha"],
    remote_ref = installed[, "RemoteRef"],
    remote_repo = installed[, "RemoteRepo"],
    remote_username = installed[, "RemoteUsername"],
    direct_runtime_dependency = rownames(installed) %in% required,
    stringsAsFactors = FALSE
  )
  packages <- packages[order(!packages$direct_runtime_dependency, packages$package), ]
  utils::write.csv(packages, output_path, row.names = FALSE, na = "")
  packages
}

task_workflow_evidence_run_testthat_child <- function(output_dir) {
  if (!requireNamespace("testthat", quietly = TRUE)) {
    stop("testthat is required for the evidence test child.", call. = FALSE)
  }
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("jsonlite is required for the evidence test child.", call. = FALSE)
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  options(device = function(...) grDevices::pdf(file = NULL))
  results <- testthat::test_dir(
    file.path(repo_root_from_script, "tests", "testthat"),
    reporter = "summary",
    stop_on_failure = FALSE
  )
  saveRDS(results, file.path(output_dir, "testthat-results.rds"))
  cases <- task_workflow_evidence_testthat_case_table(results)
  events <- task_workflow_evidence_testthat_event_table(results)
  summary <- task_workflow_evidence_summarise_testthat_cases(cases)
  boundaries <- task_workflow_evidence_boundary_result_table(cases)
  utils::write.csv(cases, file.path(output_dir, "testthat-cases.csv"), row.names = FALSE)
  utils::write.csv(events, file.path(output_dir, "testthat-events.csv"), row.names = FALSE)
  utils::write.csv(
    boundaries,
    file.path(output_dir, "boundary-scenarios.csv"),
    row.names = FALSE
  )
  jsonlite::write_json(
    summary,
    file.path(output_dir, "testthat-summary.json"),
    auto_unbox = TRUE,
    pretty = TRUE
  )
  writeLines(
    task_workflow_evidence_render_boundary_markdown(
      boundaries,
      Sys.getenv("HETOOLKIT_TASK_WORKFLOW_EVIDENCE_SHA", unset = "UNKNOWN")
    ),
    file.path(output_dir, "boundary-scenarios.md"),
    useBytes = TRUE
  )
  failed <- summary$failures > 0L || summary$errors > 0L ||
    any(boundaries$status %in% c("FAIL", "ERROR", "MISSING"))
  if (failed) 1L else 0L
}

task_workflow_evidence_run <- function(arguments) {
  if (length(arguments) != 2L) {
    stop(
      paste(
        paste0(
          "Usage: Rscript --vanilla ",
          "scripts/run_task_oriented_workflow_evidence.R"
        ),
        "<BASELINE_SHA> <ABSOLUTE_OUTPUT_DIRECTORY>"
      ),
      call. = FALSE
    )
  }

  previous_dir <- getwd()
  setwd(repo_root_from_script)
  on.exit(setwd(previous_dir), add = TRUE)

  expected_sha <- arguments[[1L]]
  requested_output <- arguments[[2L]]
  head_sha <- trimws(task_workflow_evidence_run_git_command(
    c("rev-parse", "HEAD"),
    repo_root_from_script
  ))
  origin_main_sha <- trimws(task_workflow_evidence_run_git_command(
    c("rev-parse", "origin/main"),
    repo_root_from_script
  ))
  git_status_before <- task_workflow_evidence_run_git_command(
    c("status", "--porcelain=v1", "--untracked-files=all"),
    repo_root_from_script
  )
  request <- task_workflow_evidence_validate_request(
    expected_sha,
    requested_output,
    repo_root_from_script,
    head_sha,
    origin_main_sha,
    git_status_before
  )
  output_dir <- request$output_dir
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(output_dir, "logs"), showWarnings = FALSE)
  dir.create(file.path(output_dir, "logs", "standalone"), showWarnings = FALSE)

  generated_at <- Sys.time()
  commit_record <- task_workflow_evidence_run_git_command(
    c("show", "--no-patch", "--format=fuller", head_sha),
    repo_root_from_script
  )
  remote_url <- trimws(task_workflow_evidence_run_git_command(
    c("remote", "get-url", "origin"),
    repo_root_from_script
  ))
  merge_base <- trimws(task_workflow_evidence_run_git_command(
    c("merge-base", "HEAD", "origin/main"),
    repo_root_from_script
  ))
  writeLines(c(
    sprintf("Task-oriented workflow baseline SHA: %s", head_sha),
    sprintf("Execution date UTC: %s", format(generated_at, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")),
    sprintf("Execution date local: %s", format(generated_at, "%Y-%m-%d %H:%M:%S %Z")),
    "Source branch: main (detached checkout permitted)",
    sprintf("origin/main: %s", origin_main_sha),
    sprintf("Merge base: %s", merge_base),
    sprintf("Remote: %s", remote_url),
    "Worktree before run: clean",
    "",
    commit_record
  ), file.path(output_dir, "task-workflow-baseline.txt"), useBytes = TRUE)

  runtime_root <- tempfile(paste0("hetoolkit-final-runtime-", substr(head_sha, 1L, 12L), "-"))
  runtime_library <- file.path(runtime_root, "library")
  runtime_site <- file.path(runtime_root, "site-library")
  dir.create(runtime_library, recursive = TRUE, showWarnings = FALSE)
  dir.create(runtime_site, recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(runtime_root, recursive = TRUE, force = TRUE), add = TRUE)
  child_values <- c(
    R_LIBS_USER = runtime_library,
    R_LIBS_SITE = runtime_site,
    R_ENVIRON_USER = "/dev/null",
    R_PROFILE_USER = "/dev/null",
    HETOOLKIT_TASK_WORKFLOW_EVIDENCE_SHA = head_sha,
    TZ = "UTC"
  )
  child_env <- task_workflow_evidence_format_child_environment(child_values)
  rscript <- file.path(R.home("bin"), "Rscript")

  setup_result <- task_workflow_evidence_run_logged_command(
    rscript,
    c("--vanilla", "scripts/setup_dashboard_dependencies.R"),
    file.path(output_dir, "logs", "dependency-install.log"),
    env = child_env
  )
  if (setup_result$status != 0L) {
    writeLines(
      "FAIL: dependency installation did not complete successfully.",
      file.path(output_dir, "run-status.txt")
    )
    task_workflow_evidence_write_sha256_manifest(output_dir)
    return(1L)
  }

  .libPaths(unique(c(runtime_library, .Library)))
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("jsonlite was not available after dependency installation.", call. = FALSE)
  }
  package_versions <- task_workflow_evidence_collect_package_versions(
    runtime_library,
    file.path(output_dir, "package-versions.csv")
  )

  session_values <- c(
    child_values,
    HETOOLKIT_SESSION_INFO_PATH = file.path(output_dir, "session-info.txt")
  )
  session_result <- task_workflow_evidence_run_logged_command(
    rscript,
    c(
      "--vanilla", "-e",
      shQuote(paste(
        "capture.output(utils::sessionInfo(),",
        "file = Sys.getenv('HETOOLKIT_SESSION_INFO_PATH'))"
      ))
    ),
    file.path(output_dir, "logs", "session-info-command.log"),
    env = task_workflow_evidence_format_child_environment(session_values)
  )

  preflight_result <- task_workflow_evidence_run_logged_command(
    rscript,
    c("--vanilla", "scripts/preflight_dashboard_startup.R"),
    file.path(output_dir, "logs", "startup-preflight.log"),
    env = child_env
  )

  testthat_dir <- file.path(output_dir, "automated-tests")
  testthat_result <- task_workflow_evidence_run_logged_command(
    rscript,
    c(
      "--vanilla", shQuote(script_path), "--testthat-child",
      shQuote(testthat_dir)
    ),
    file.path(output_dir, "logs", "testthat.log"),
    env = child_env
  )

  standalone_scripts <- sort(list.files(
    file.path(repo_root_from_script, "tests"),
    pattern = "^test_.*[.]R$",
    full.names = TRUE,
    recursive = FALSE
  ))
  standalone_rows <- lapply(seq_along(standalone_scripts), function(index) {
    standalone_script <- standalone_scripts[[index]]
    standalone_name <- basename(standalone_script)
    standalone_values <- c(
      child_values,
      HETOOLKIT_STANDALONE_SCRIPT = standalone_script
    )
    result <- task_workflow_evidence_run_logged_command(
      rscript,
      c(
        "--vanilla", "-e",
        shQuote(paste(
          "options(device = function(...) grDevices::pdf(file = NULL));",
          "source(Sys.getenv('HETOOLKIT_STANDALONE_SCRIPT'), chdir = FALSE)"
        ))
      ),
      file.path(output_dir, "logs", "standalone", paste0(standalone_name, ".log")),
      env = task_workflow_evidence_format_child_environment(standalone_values)
    )
    data.frame(
      script = file.path("tests", standalone_name),
      exit_status = result$status,
      duration_seconds = result$duration_seconds,
      warning_detected = result$warning_detected,
      log = file.path("logs", "standalone", paste0(standalone_name, ".log")),
      stringsAsFactors = FALSE
    )
  })
  standalone <- do.call(rbind, standalone_rows)
  utils::write.csv(
    standalone,
    file.path(output_dir, "standalone-summary.csv"),
    row.names = FALSE
  )

  git_status_after <- task_workflow_evidence_run_git_command(
    c("status", "--porcelain=v1", "--untracked-files=all"),
    repo_root_from_script
  )
  worktree_clean_after <- length(git_status_after) == 0L ||
    !any(nzchar(git_status_after))
  writeLines(
    if (worktree_clean_after) "CLEAN" else git_status_after,
    file.path(output_dir, "git-status-after.txt"),
    useBytes = TRUE
  )

  testthat_summary_path <- file.path(testthat_dir, "testthat-summary.json")
  testthat_summary <- if (file.exists(testthat_summary_path)) {
    jsonlite::read_json(testthat_summary_path, simplifyVector = TRUE)
  } else {
    list(
      test_files = NA_integer_, test_cases = NA_integer_, expectations = NA_integer_,
      passed = NA_integer_, failures = NA_integer_, errors = NA_integer_,
      warnings = NA_integer_, skipped = NA_integer_, duration_seconds = NA_real_
    )
  }
  boundary_path <- file.path(testthat_dir, "boundary-scenarios.csv")
  boundaries <- if (file.exists(boundary_path)) {
    utils::read.csv(boundary_path, stringsAsFactors = FALSE)
  } else {
    data.frame(status = "MISSING", stringsAsFactors = FALSE)
  }
  task_workflow_evidence_write_boundary_ui_templates(output_dir, head_sha)

  hard_failures <- c(
    if (session_result$status != 0L) "session-info command failed",
    if (preflight_result$status != 0L) "startup preflight failed",
    if (testthat_result$status != 0L) "testthat suite failed",
    if (any(standalone$exit_status != 0L)) "one or more standalone scripts failed",
    if (any(boundaries$status %in% c("FAIL", "ERROR", "MISSING"))) "one or more B01-B07 scenarios failed",
    if (!worktree_clean_after) "tests changed the Git worktree"
  )
  review_items <- c(
    if (setup_result$warning_detected) "dependency-install warnings require review",
    if (session_result$warning_detected) "session-info warnings require review",
    if (preflight_result$warning_detected) "startup-preflight warnings require review",
    if (testthat_result$warning_detected) "testthat log warning text requires review",
    if (isTRUE(testthat_summary$warnings > 0L)) "testthat warnings require explanation",
    if (isTRUE(testthat_summary$skipped > 0L)) "testthat skips require explanation",
    if (any(standalone$warning_detected)) "standalone warning text requires review"
  )
  overall_status <- if (length(hard_failures) > 0L) {
    "FAIL"
  } else if (length(review_items) > 0L) {
    "PASS_REVIEW_REQUIRED"
  } else {
    "PASS"
  }

  direct_packages <- package_versions[package_versions$direct_runtime_dependency, , drop = FALSE]
  manifest <- list(
    schema_version = "1.0",
    evidence_kind = "task-oriented-workflow-engineering-evidence",
    generated_at_utc = format(generated_at, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    baseline = list(
      commit = head_sha,
      origin_main = origin_main_sha,
      merge_base = merge_base,
      remote = remote_url,
      clean_before = TRUE,
      clean_after = worktree_clean_after
    ),
    environment = list(
      r_version = R.version.string,
      platform = R.version$platform,
      os = unname(Sys.info()[["sysname"]]),
      os_release = unname(Sys.info()[["release"]]),
      dependency_lock = "No renv.lock; exact installed versions are recorded.",
      direct_runtime_packages = split(direct_packages$version, direct_packages$package)
    ),
    commands = list(
      dependency_install = setup_result,
      session_info = session_result,
      startup_preflight = preflight_result,
      testthat = testthat_result
    ),
    testthat = testthat_summary,
    standalone = list(
      scripts = nrow(standalone),
      passed = sum(standalone$exit_status == 0L),
      failed = sum(standalone$exit_status != 0L),
      warnings_requiring_review = sum(standalone$warning_detected)
    ),
    boundary_scenarios = boundaries,
    overall_status = overall_status,
    hard_failures = hard_failures,
    review_items = review_items,
    reproducibility_boundary = paste(
      "Primary evidence covers this macOS and R environment.",
      "It does not claim Windows launcher or authorised external-service validation."
    )
  )
  jsonlite::write_json(
    manifest,
    file.path(output_dir, "manifest.json"),
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null",
    na = "null"
  )
  writeLines(c(
    sprintf("Overall status: %s", overall_status),
    if (length(hard_failures) > 0L) paste("Failure:", hard_failures) else "No hard failures.",
    if (length(review_items) > 0L) paste("Review:", review_items) else "No warning/skip review required."
  ), file.path(output_dir, "run-status.txt"), useBytes = TRUE)
  task_workflow_evidence_write_sha256_manifest(output_dir)

  if (identical(overall_status, "FAIL")) 1L else if (
    identical(overall_status, "PASS_REVIEW_REQUIRED")
  ) 2L else 0L
}

if (sys.nframe() == 0L) {
  arguments <- commandArgs(trailingOnly = TRUE)
  status <- tryCatch(
    {
      if (length(arguments) >= 1L && identical(arguments[[1L]], "--testthat-child")) {
        if (length(arguments) != 2L) {
          stop("--testthat-child requires an output directory.", call. = FALSE)
        }
        task_workflow_evidence_run_testthat_child(arguments[[2L]])
      } else {
        task_workflow_evidence_run(arguments)
      }
    },
    error = function(error) {
      message(
        "Task-oriented workflow evidence run failed: ",
        conditionMessage(error)
      )
      if (length(arguments) >= 1L) {
        output_candidate <- tail(arguments, 1L)
        if (task_workflow_evidence_path_is_absolute(output_candidate)) {
          output_candidate <- task_workflow_evidence_normalise_path(
            output_candidate,
            must_work = FALSE
          )
          if (dir.exists(output_candidate)) {
            writeLines(
              paste("FAIL:", conditionMessage(error)),
              file.path(output_candidate, "run-status.txt"),
              useBytes = TRUE
            )
            try(
              task_workflow_evidence_write_sha256_manifest(output_candidate),
              silent = TRUE
            )
          }
        }
      }
      1L
    }
  )
  quit(save = "no", status = status, runLast = FALSE)
}
