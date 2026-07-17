source(testthat::test_path("..", "..", "R", "site_mapping_helpers.R"))

flow_metadata <- function(flow_input = NULL) {
  metadata <- data.frame(
    biol_site_id = "BIO001",
    flow_site_id = "00123",
    wq_site_id = "WQ001",
    rhs_survey_id = "RHS001",
    stringsAsFactors = FALSE
  )
  if (!is.null(flow_input)) {
    metadata$flow_input <- flow_input
  }
  metadata
}

testthat::test_that("missing flow_input defaults to HDE", {
  result <- normalise_site_metadata_flow_input(flow_metadata())
  provenance <- site_metadata_flow_input_provenance(result)

  testthat::expect_identical(result$flow_input, "HDE")
  testthat::expect_identical(provenance$flow_input_value, "HDE")
  testthat::expect_identical(provenance$flow_input_source, "defaulted")
})

testthat::test_that("blank and NA flow_input values default to HDE", {
  metadata <- flow_metadata()
  metadata <- metadata[rep(1, 3), , drop = FALSE]
  metadata$flow_input <- c("", "   ", NA_character_)
  result <- normalise_site_metadata_flow_input(metadata)
  provenance <- site_metadata_flow_input_provenance(result)

  testthat::expect_identical(result$flow_input, rep("HDE", 3))
  testthat::expect_identical(provenance$flow_input_source, rep("defaulted", 3))
})

testthat::test_that("valid flow_input values normalise to uppercase", {
  metadata <- flow_metadata()
  metadata <- metadata[rep(1, 4), , drop = FALSE]
  metadata$flow_input <- c("hde", "nrfa", "HDE", "NRFA")
  result <- normalise_site_metadata_flow_input(metadata)
  provenance <- site_metadata_flow_input_provenance(result)

  testthat::expect_identical(result$flow_input, c("HDE", "NRFA", "HDE", "NRFA"))
  testthat::expect_identical(provenance$flow_input_source, rep("explicit", 4))
})

testthat::test_that("mixed flow_input rows retain row-level provenance", {
  metadata <- flow_metadata()
  metadata <- metadata[rep(1, 4), , drop = FALSE]
  metadata$flow_input <- c("HDE", "", NA_character_, "nrfa")
  result <- normalise_site_metadata_flow_input(metadata)
  provenance <- site_metadata_flow_input_provenance(result)

  testthat::expect_identical(provenance$flow_input_value, c("HDE", "HDE", "HDE", "NRFA"))
  testthat::expect_identical(provenance$flow_input_source, c("explicit", "defaulted", "defaulted", "explicit"))
  testthat::expect_false("flow_input_source" %in% names(result))
})

testthat::test_that("invalid non-empty flow_input is rejected", {
  testthat::expect_error(
    normalise_site_metadata_flow_input(flow_metadata("LOCAL")),
    "Invalid flow_input value(s): LOCAL.",
    fixed = TRUE
  )
})

testthat::test_that("parsed metadata can be normalised for downstream use", {
  parsed <- parse_site_metadata("biol_site_id,flow_site_id,wq_site_id,rhs_survey_id\nBIO001,00123,WQ001,RHS001")
  result <- normalise_site_metadata_flow_input(parsed$data)

  testthat::expect_null(parsed$error)
  testthat::expect_identical(result$flow_site_id, "00123")
  testthat::expect_identical(result$flow_input, "HDE")
})
