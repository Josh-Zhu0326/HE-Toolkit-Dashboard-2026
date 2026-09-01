source(testthat::test_path("..", "..", "scripts", "final_evidence_helpers.R"))

testthat::test_that("final evidence request enforces SHA, clean state, and external immutable output", {
  fake_repo <- tempfile("final-evidence-repo-")
  dir.create(fake_repo)
  on.exit(unlink(fake_repo, recursive = TRUE, force = TRUE), add = TRUE)
  sha <- paste(rep("a", 40L), collapse = "")
  output <- tempfile("final-evidence-output-")

  validated <- validate_final_evidence_request(
    sha,
    output,
    fake_repo,
    sha,
    sha,
    character()
  )
  testthat::expect_identical(validated$expected_sha, sha)
  testthat::expect_false(final_evidence_path_is_within(validated$output_dir, fake_repo))

  testthat::expect_error(
    validate_final_evidence_request(
      "abc", output, fake_repo, sha, sha, character()
    ),
    "complete 40-character",
    fixed = TRUE
  )
  testthat::expect_error(
    validate_final_evidence_request(
      sha, output, fake_repo, paste(rep("b", 40L), collapse = ""), sha,
      character()
    ),
    "HEAD does not match",
    fixed = TRUE
  )
  testthat::expect_error(
    validate_final_evidence_request(
      sha, output, fake_repo, sha, paste(rep("b", 40L), collapse = ""),
      character()
    ),
    "origin/main does not match",
    fixed = TRUE
  )
  testthat::expect_error(
    validate_final_evidence_request(
      sha, output, fake_repo, sha, sha, "?? local-evidence.txt"
    ),
    "clean worktree",
    fixed = TRUE
  )
  testthat::expect_error(
    validate_final_evidence_request(
      sha, file.path(fake_repo, "evidence"), fake_repo, sha, sha, character()
    ),
    "outside the repository",
    fixed = TRUE
  )
  testthat::expect_error(
    validate_final_evidence_request(
      sha, "relative/evidence", fake_repo, sha, sha, character()
    ),
    "absolute path",
    fixed = TRUE
  )

  dir.create(output)
  on.exit(unlink(output, recursive = TRUE, force = TRUE), add = TRUE)
  testthat::expect_error(
    validate_final_evidence_request(
      sha, output, fake_repo, sha, sha, character()
    ),
    "attempts are immutable",
    fixed = TRUE
  )
})

testthat::test_that("testthat evidence summary uses explicit reporting fields", {
  cases <- data.frame(
    file = c("test-a.R", "test-b.R"),
    test = c("passes", "review"),
    nb = c(3L, 2L),
    failed = c(0L, 0L),
    skipped = c(FALSE, TRUE),
    error = c(FALSE, FALSE),
    warning = c(0L, 1L),
    passed = c(3L, 1L),
    real = c(0.1, 0.2),
    stringsAsFactors = FALSE
  )
  summary <- summarise_testthat_cases(cases)

  testthat::expect_identical(summary$test_files, 2L)
  testthat::expect_identical(summary$test_cases, 2L)
  testthat::expect_identical(summary$expectations, 5L)
  testthat::expect_identical(summary$passed, 4L)
  testthat::expect_identical(summary$failures, 0L)
  testthat::expect_identical(summary$errors, 0L)
  testthat::expect_identical(summary$warnings, 1L)
  testthat::expect_identical(summary$skipped, 1L)
  testthat::expect_equal(summary$duration_seconds, 0.3)
})

testthat::test_that("boundary catalogue maps exactly B01 through B07", {
  catalog <- final_evidence_boundary_catalog()
  cases <- data.frame(
    file = rep("test-dissertation-boundary-evidence.R", nrow(catalog)),
    context = "",
    test = catalog$automated_test,
    nb = rep(2L, nrow(catalog)),
    failed = 0L,
    skipped = FALSE,
    error = FALSE,
    warning = 0L,
    user = 0,
    system = 0,
    real = 0.01,
    passed = 2L,
    status = "PASS",
    stringsAsFactors = FALSE
  )
  boundaries <- boundary_result_table(cases, catalog)

  testthat::expect_identical(boundaries$scenario_id, sprintf("B%02d", 1:7))
  testthat::expect_true(all(boundaries$status == "PASS"))
  testthat::expect_true(all(boundaries$expectations == 2L))
  testthat::expect_identical(anyDuplicated(boundaries$automated_test), 0L)
})

testthat::test_that("UI templates and warning detection remain auditable", {
  output <- tempfile("final-evidence-ui-")
  dir.create(output)
  on.exit(unlink(output, recursive = TRUE, force = TRUE), add = TRUE)
  sha <- paste(rep("c", 40L), collapse = "")
  write_boundary_ui_templates(output, sha)

  records <- list.files(
    file.path(output, "ui"),
    pattern = "record[.]md$",
    recursive = TRUE,
    full.names = TRUE
  )
  testthat::expect_length(records, 7L)
  testthat::expect_true(all(vapply(
    records,
    function(path) any(grepl(sha, readLines(path, warn = FALSE), fixed = TRUE)),
    logical(1)
  )))
  testthat::expect_true(final_evidence_log_has_warning("Warning message: review me"))
  testthat::expect_false(final_evidence_log_has_warning("all checks passed"))
})
