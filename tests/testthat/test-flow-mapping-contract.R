source(testthat::test_path("..", "..", "R", "site_mapping_helpers.R"))
source(testthat::test_path("..", "..", "R", "dashboard_backlog_helpers.R"))

flow_mapping_fixture <- function(name) {
  testthat::test_path("..", "fixtures", "flow_mapping", name)
}

expect_complete_mapping_accepted <- function(name, expected_input) {
  parsed <- read_site_metadata_csv(flow_mapping_fixture(name))

  testthat::expect_null(parsed$error)
  testthat::expect_identical(parsed$data$flow_input, expected_input)
  testthat::expect_identical(validate_supporting_mapping(parsed$data)$status, "success")
  testthat::expect_null(validate_dashboard_site_metadata(parsed$data))
}

testthat::test_that("complete mapping accepts flow_input HDE", {
  expect_complete_mapping_accepted("flow_input_hde.csv", "HDE")
})

testthat::test_that("complete mapping accepts flow_input NRFA", {
  expect_complete_mapping_accepted("flow_input_nrfa.csv", "NRFA")
})

testthat::test_that("complete mapping rejects a non-empty invalid flow_input", {
  parsed <- read_site_metadata_csv(flow_mapping_fixture("flow_input_invalid.csv"))
  supporting_validation <- validate_supporting_mapping(parsed$data)
  dashboard_validation <- validate_dashboard_site_metadata(parsed$data)

  testthat::expect_null(parsed$error)
  testthat::expect_identical(supporting_validation$status, "error")
  testthat::expect_match(supporting_validation$messages, "Invalid flow_input value(s): INVALID.", fixed = TRUE)
  testthat::expect_match(dashboard_validation, "flow_input values must be NRFA or HDE", fixed = TRUE)
})
