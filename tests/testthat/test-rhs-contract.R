source(testthat::test_path("..", "..", "R", "site_mapping_helpers.R"))
source(testthat::test_path("..", "..", "R", "dashboard_backlog_helpers.R"))

rhs_contract_fixture <- function(name) {
  testthat::test_path("..", "fixtures", "rhs_contract", name)
}

testthat::test_that("complete metadata accepts rhs_survey_id as the only RHS identifier", {
  parsed <- read_site_metadata_csv(rhs_contract_fixture("canonical_rhs_survey_id.csv"))

  testthat::expect_null(parsed$error)
  testthat::expect_true("rhs_survey_id" %in% names(parsed$data))
  testthat::expect_false("rhs_site_id" %in% names(parsed$data))
  testthat::expect_identical(validate_supporting_mapping(parsed$data)$status, "success")
  testthat::expect_null(validate_dashboard_site_metadata(parsed$data))
})

testthat::test_that("metadata containing rhs_site_id without rhs_survey_id is rejected", {
  parsed <- read_site_metadata_csv(rhs_contract_fixture("rhs_site_id_only.csv"))

  testthat::expect_null(parsed$data)
  testthat::expect_match(parsed$error, "Replace it with rhs_survey_id", fixed = TRUE)
})

testthat::test_that("metadata containing matching RHS identifier columns is rejected", {
  parsed <- read_site_metadata_csv(rhs_contract_fixture("both_rhs_ids_matching.csv"))

  testthat::expect_null(parsed$data)
  testthat::expect_match(parsed$error, "Remove rhs_site_id", fixed = TRUE)
})

testthat::test_that("metadata containing different RHS identifier columns is rejected", {
  parsed <- read_site_metadata_csv(rhs_contract_fixture("both_rhs_ids_different.csv"))

  testthat::expect_null(parsed$data)
  testthat::expect_match(parsed$error, "Remove rhs_site_id", fixed = TRUE)
})

testthat::test_that("external Survey.ID normalises to rhs_survey_id without legacy columns", {
  external_rhs <- data.frame(Survey.ID = "RHS001", HQA = 50, stringsAsFactors = FALSE)
  normalised <- normalise_rhs_records(external_rhs, allow_external_survey_id = TRUE)

  testthat::expect_identical(normalised$rhs_survey_id, "RHS001")
  testthat::expect_false("Survey.ID" %in% names(normalised))
  testthat::expect_false("rhs_site_id" %in% names(normalised))
})

testthat::test_that("default local RHS normalisation does not accept Survey.ID", {
  local_rhs <- data.frame(Survey.ID = "RHS001", HQA = 50, stringsAsFactors = FALSE)

  testthat::expect_error(
    normalise_rhs_records(local_rhs),
    "Survey.ID is accepted only from the external RHS interface",
    fixed = TRUE
  )
})
