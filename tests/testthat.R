# Standalone testthat runner for this Shiny project (not an R package).
if (!requireNamespace("testthat", quietly = TRUE)) {
  stop("The testthat package is required to run tests/testthat.R.", call. = FALSE)
}

testthat::test_dir("tests/testthat", reporter = "summary")
