source(testthat::test_path("..", "..", "R", "site_mapping_helpers.R"))

metadata_fixture <- function(name) {
  testthat::test_path("..", "fixtures", "metadata", name)
}

testthat::test_that("site metadata CSV is parsed into character columns", {
  result <- read_site_metadata_csv(metadata_fixture("valid_identifiers.csv"))

  testthat::expect_null(result$error)
  testthat::expect_s3_class(result$data, "data.frame")
  testthat::expect_true(all(vapply(result$data, is.character, logical(1))))
})

testthat::test_that("site metadata preserves leading-zero identifiers", {
  result <- read_site_metadata_csv(metadata_fixture("leading_zero_identifiers.csv"))

  testthat::expect_null(result$error)
  testthat::expect_identical(result$data$biol_site_id, "050101012")
  testthat::expect_identical(result$data$flow_site_id, "022001")
})

testthat::test_that("site metadata preserves mixed alphanumeric identifiers", {
  result <- read_site_metadata_csv(metadata_fixture("mixed_alphanumeric_identifiers.csv"))

  testthat::expect_null(result$error)
  testthat::expect_identical(result$data$wq_site_id, "SX26F065")
  testthat::expect_identical(result$data$rhs_survey_id, "2859TH")
})

testthat::test_that("header-only site metadata CSV is reported as empty", {
  result <- read_site_metadata_csv(metadata_fixture("header_only.csv"))

  testthat::expect_null(result$data)
  testthat::expect_identical(
    result$error,
    "Site metadata could not be read. Please paste a CSV header and at least one data row."
  )
})

testthat::test_that("unreadable site metadata CSV is reported as an error", {
  result <- read_site_metadata_csv(metadata_fixture("does_not_exist.csv"))

  testthat::expect_null(result$data)
  testthat::expect_identical(result$error, "The selected site metadata CSV could not be found.")
})
