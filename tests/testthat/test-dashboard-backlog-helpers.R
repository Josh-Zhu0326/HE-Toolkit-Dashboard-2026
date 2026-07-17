source(testthat::test_path("..", "..", "R", "site_mapping_helpers.R"))
source(testthat::test_path("..", "..", "R", "dashboard_backlog_helpers.R"))

testthat::test_that("mapping validation reports a missing biol_site_id column", {
  mapping <- utils::read.csv(
    testthat::test_path("..", "fixtures", "metadata", "missing_biol_site_id.csv"),
    stringsAsFactors = FALSE
  )
  result <- validate_supporting_mapping(mapping)

  testthat::expect_identical(result$status, "error")
  testthat::expect_identical(
    result$messages,
    "Mapping CSV is missing required column(s): biol_site_id."
  )
})
