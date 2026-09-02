task_workflow_evidence_or <- function(value, fallback) {
  if (is.null(value) || length(value) == 0L) fallback else value
}

task_workflow_evidence_is_sha <- function(value) {
  length(value) == 1L &&
    !is.na(value) &&
    grepl("^[0-9a-fA-F]{40}$", value)
}

task_workflow_evidence_normalise_path <- function(path, must_work = FALSE) {
  path <- path.expand(path)
  if (must_work || file.exists(path) || dir.exists(path)) {
    return(normalizePath(path, winslash = "/", mustWork = must_work))
  }

  parent <- dirname(path)
  if (identical(parent, path)) {
    return(normalizePath(path, winslash = "/", mustWork = FALSE))
  }
  file.path(
    task_workflow_evidence_normalise_path(parent, must_work = FALSE),
    basename(path)
  )
}

task_workflow_evidence_path_is_absolute <- function(path) {
  grepl("^(/|[A-Za-z]:[/\\\\]|\\\\\\\\)", path.expand(path))
}

task_workflow_evidence_path_is_within <- function(path, parent) {
  path <- task_workflow_evidence_normalise_path(path, must_work = FALSE)
  parent <- task_workflow_evidence_normalise_path(parent, must_work = TRUE)
  identical(path, parent) || startsWith(path, paste0(parent, "/"))
}

task_workflow_evidence_validate_request <- function(
    expected_sha,
    output_dir,
    repo_root,
    head_sha,
    origin_main_sha,
    git_status) {
  if (!task_workflow_evidence_is_sha(expected_sha)) {
    stop("BASELINE_SHA must be a complete 40-character hexadecimal commit SHA.",
         call. = FALSE)
  }

  expected_sha <- tolower(expected_sha)
  if (!identical(tolower(head_sha), expected_sha)) {
    stop("HEAD does not match BASELINE_SHA.", call. = FALSE)
  }
  if (!identical(tolower(origin_main_sha), expected_sha)) {
    stop("origin/main does not match BASELINE_SHA.", call. = FALSE)
  }
  if (length(git_status) > 0L && any(nzchar(git_status))) {
    stop("The task-oriented workflow evidence run requires a clean worktree.",
         call. = FALSE)
  }

  if (!task_workflow_evidence_path_is_absolute(output_dir)) {
    stop("The evidence output directory must be an absolute path.",
         call. = FALSE)
  }
  output_dir <- task_workflow_evidence_normalise_path(output_dir, must_work = FALSE)
  if (task_workflow_evidence_path_is_within(output_dir, repo_root)) {
    stop("The evidence output directory must be outside the repository.",
         call. = FALSE)
  }
  if (file.exists(output_dir) || dir.exists(output_dir)) {
    stop("The evidence output directory already exists; attempts are immutable.",
         call. = FALSE)
  }

  list(
    expected_sha = expected_sha,
    output_dir = output_dir,
    repo_root = task_workflow_evidence_normalise_path(repo_root, must_work = TRUE)
  )
}

task_workflow_evidence_boundary_catalog <- function() {
  data.frame(
    scenario_id = sprintf("B%02d", 1:7),
    claim = c(
      "Missing prerequisite cannot produce current downstream evidence.",
      "An upstream Flow change invalidates only dependent descendants.",
      "A WQ enrichment change preserves the current core dataset.",
      "Filter exclusion and restoration rebuild analysis without mutating joined data.",
      "A model specification change makes the previous model result stale.",
      "A model failure remains explicit and supports recovery without fallback.",
      "Resume selects the earliest unmet required stage consistently."
    ),
    precondition = c(
      "O:E is current and Flow Statistics are unavailable.",
      "All workflow artifacts have current outputs.",
      "Core, enriched, analysis, HEV, and model outputs are current.",
      "Joined data and downstream analysis/model/HEV outputs are current.",
      "A current model result exists for the previous specification.",
      "Current joined and analysis outputs exist before a model attempt.",
      "A later analysis output exists while a required Stage 3 artifact is stale."
    ),
    action = c(
      "Attempt to build the Joined HE dataset.",
      "Commit a new current Flow input revision with downstream invalidation.",
      "Commit a new current WQ input revision with downstream invalidation.",
      "Exclude one observation, rebuild analysis, then restore it.",
      "Change the model specification after a successful model fit.",
      "Record a failed model attempt, then retry successfully.",
      "Select Resume for the HEV task."
    ),
    expected = c(
      "joined_core is blocked, is not current, keeps revision zero, and exposes a reason and next action.",
      "Flow-derived descendants are stale with retained revisions; Biology, Environment, and O:E remain current.",
      "joined_core remains current at the same revision while WQ enrichment and selected downstream evidence become stale.",
      "analysis_dataset revisions change, HEV/model become stale, joined data remain unchanged, and the log records exclude/restore.",
      "model_result becomes stale without changing non-model outputs or overwriting its retained revision.",
      "failed is not current, includes reason/recovery action, preserves upstream outputs, and a successful retry creates a new revision.",
      "The state function and server session both select Stage 3, the earliest unmet required stage."
    ),
    automated_test = c(
      "[B01] missing Flow Statistics block the downstream joined result",
      "[B02] upstream Flow change stales only dependent descendants",
      "[B03] WQ enrichment change preserves joined_core",
      "[B04] filter exclude and restore rebuild analysis non-destructively",
      "[B05] model specification change stales only the model result",
      "[B06] failed model evidence is explicit and recoverable",
      "[B07] Resume returns the earliest unmet required stage"
    ),
    stringsAsFactors = FALSE
  )
}

task_workflow_evidence_summarise_testthat_cases <- function(cases) {
  required <- c(
    "file", "test", "nb", "failed", "skipped", "error", "warning",
    "passed", "real"
  )
  missing <- setdiff(required, names(cases))
  if (length(missing) > 0L) {
    stop(
      sprintf("testthat results are missing columns: %s", paste(missing, collapse = ", ")),
      call. = FALSE
    )
  }

  list(
    test_files = length(unique(cases$file)),
    test_cases = nrow(cases),
    expectations = sum(cases$nb, na.rm = TRUE),
    passed = sum(cases$passed, na.rm = TRUE),
    failures = sum(cases$failed, na.rm = TRUE),
    errors = sum(as.integer(cases$error), na.rm = TRUE),
    warnings = sum(cases$warning, na.rm = TRUE),
    skipped = sum(as.integer(cases$skipped), na.rm = TRUE),
    duration_seconds = unname(sum(cases$real, na.rm = TRUE))
  )
}

task_workflow_evidence_testthat_case_status <- function(case) {
  if (isTRUE(case$error)) return("ERROR")
  if (isTRUE(case$failed > 0L)) return("FAIL")
  if (isTRUE(case$warning > 0L)) return("WARNING")
  if (isTRUE(case$skipped)) return("SKIP")
  "PASS"
}

task_workflow_evidence_testthat_case_table <- function(results) {
  cases <- as.data.frame(results)
  keep <- c(
    "file", "context", "test", "nb", "failed", "skipped", "error",
    "warning", "user", "system", "real", "passed"
  )
  cases <- cases[, keep, drop = FALSE]
  cases$status <- vapply(
    seq_len(nrow(cases)),
    function(index) task_workflow_evidence_testthat_case_status(
      cases[index, , drop = FALSE]
    ),
    character(1)
  )
  cases
}

task_workflow_evidence_testthat_expectation_location <- function(expectation) {
  srcref <- expectation$srcref
  if (is.null(srcref)) return(NA_character_)
  filename <- tryCatch(
    getSrcFilename(srcref, full.names = FALSE),
    error = function(error) ""
  )
  line <- suppressWarnings(as.integer(srcref[[1L]]))
  if (!nzchar(filename) || is.na(line)) return(NA_character_)
  sprintf("%s:%d", filename, line)
}

task_workflow_evidence_testthat_event_table <- function(results) {
  cases <- as.data.frame(results)
  rows <- list()
  for (case_index in seq_len(nrow(cases))) {
    expectations <- cases$result[[case_index]]
    for (expectation in expectations) {
      kind <- if (inherits(expectation, "expectation_skip")) {
        "skip"
      } else if (inherits(expectation, "expectation_warning")) {
        "warning"
      } else if (inherits(expectation, "expectation_failure")) {
        "failure"
      } else if (inherits(expectation, "expectation_error") ||
                 inherits(expectation, "error")) {
        "error"
      } else {
        "success"
      }
      if (identical(kind, "success")) next
      rows[[length(rows) + 1L]] <- data.frame(
        file = cases$file[[case_index]],
        test = cases$test[[case_index]],
        event = kind,
        message = as.character(task_workflow_evidence_or(
          expectation$message,
          ""
        )),
        location = task_workflow_evidence_testthat_expectation_location(
          expectation
        ),
        stringsAsFactors = FALSE
      )
    }
  }
  if (length(rows) == 0L) {
    return(data.frame(
      file = character(), test = character(), event = character(),
      message = character(), location = character(),
      stringsAsFactors = FALSE
    ))
  }
  do.call(rbind, rows)
}

task_workflow_evidence_boundary_result_table <- function(
    cases,
    catalog = task_workflow_evidence_boundary_catalog()) {
  rows <- lapply(seq_len(nrow(catalog)), function(index) {
    scenario <- catalog[index, , drop = FALSE]
    match_index <- which(cases$test == scenario$automated_test)
    if (length(match_index) != 1L) {
      return(data.frame(
        scenario,
        status = "MISSING",
        expectations = 0L,
        failures = 0L,
        errors = 0L,
        warnings = 0L,
        skipped = 0L,
        stringsAsFactors = FALSE
      ))
    }
    case <- cases[match_index, , drop = FALSE]
    data.frame(
      scenario,
      status = case$status,
      expectations = case$nb,
      failures = case$failed,
      errors = as.integer(case$error),
      warnings = case$warning,
      skipped = as.integer(case$skipped),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

task_workflow_evidence_render_boundary_markdown <- function(
    boundaries,
    baseline_sha) {
  lines <- c(
    "# Task-Oriented Workflow Boundary Scenario Summary",
    "",
    sprintf("Baseline SHA: `%s`", baseline_sha),
    "",
    "| ID | Claim | Automated result | UI evidence |",
    "|---|---|---:|---|"
  )
  for (index in seq_len(nrow(boundaries))) {
    lines <- c(lines, sprintf(
      "| %s | %s | %s | `ui/%s/record.md` |",
      boundaries$scenario_id[[index]],
      boundaries$claim[[index]],
      boundaries$status[[index]],
      boundaries$scenario_id[[index]]
    ))
  }
  c(lines, "")
}

task_workflow_evidence_write_boundary_ui_templates <- function(
    output_dir,
    baseline_sha) {
  catalog <- task_workflow_evidence_boundary_catalog()
  for (index in seq_len(nrow(catalog))) {
    scenario <- catalog[index, , drop = FALSE]
    scenario_dir <- file.path(output_dir, "ui", scenario$scenario_id)
    dir.create(scenario_dir, recursive = TRUE, showWarnings = FALSE)
    writeLines(c(
      sprintf("# %s UI Evidence Record", scenario$scenario_id),
      "",
      sprintf("Baseline SHA: `%s`", baseline_sha),
      "Execution time (UTC): TODO",
      "Execution time (local): TODO",
      "Browser and version: TODO",
      "Viewport: TODO",
      "Synthetic fixture: TODO",
      "",
      "## Claim",
      "",
      scenario$claim,
      "",
      "## Precondition",
      "",
      scenario$precondition,
      "",
      "## Action",
      "",
      scenario$action,
      "",
      "## Expected",
      "",
      scenario$expected,
      "",
      "## Observed",
      "",
      "TODO",
      "",
      "## Screenshots",
      "",
      "- TODO: add one state screenshot or a before/after pair.",
      "",
      "## Result",
      "",
      "TODO: PASS or FAIL",
      ""
    ), file.path(scenario_dir, "record.md"), useBytes = TRUE)
  }
  invisible(TRUE)
}

task_workflow_evidence_log_has_warning <- function(lines) {
  any(grepl(
    "(^|[[:space:]])Warning( message)?s?:|There were [0-9]+ warnings?",
    lines,
    ignore.case = FALSE
  ))
}
