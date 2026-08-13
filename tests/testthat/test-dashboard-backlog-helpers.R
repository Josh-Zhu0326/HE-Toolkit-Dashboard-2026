source(testthat::test_path("..", "..", "R", "csv_input_helpers.R"))
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
    paste(
      "Site metadata is missing required column(s): biol_site_id.",
      "Please add the required mapping column(s) and validate again."
    )
  )
})

testthat::test_that("required core mapping and optional enrichment severity stay distinct", {
  missing_flow <- validate_supporting_mapping(data.frame(
    biol_site_id = "B1",
    wq_site_id = "W1",
    stringsAsFactors = FALSE
  ))
  blank_flow <- validate_supporting_mapping(data.frame(
    biol_site_id = "B1",
    flow_site_id = " ",
    stringsAsFactors = FALSE
  ))
  core_only <- validate_supporting_mapping(data.frame(
    biol_site_id = "B1",
    flow_site_id = "F1",
    stringsAsFactors = FALSE
  ))

  testthat::expect_identical(missing_flow$status, "error")
  testthat::expect_match(missing_flow$messages, "flow_site_id", fixed = TRUE)
  testthat::expect_identical(blank_flow$status, "error")
  testthat::expect_match(blank_flow$messages, "blank flow_site_id", fixed = TRUE)
  testthat::expect_identical(core_only$status, "info")
  testthat::expect_true(any(grepl(
    "Optional WQ mapping was not supplied",
    core_only$messages,
    fixed = TRUE
  )))
  testthat::expect_true(all(grepl(
    "core Biology and Flow workflow can continue",
    core_only$messages,
    fixed = TRUE
  )))
})
