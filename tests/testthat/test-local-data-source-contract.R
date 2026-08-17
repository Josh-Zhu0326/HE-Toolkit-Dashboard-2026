testthat::test_that("the five client-confirmed local CSV contracts are defined", {
  testthat::expect_identical(
    names(local_dataset_contracts()),
    c("biology", "environment", "flow", "wq", "rhs")
  )
  testthat::expect_identical(
    local_source_modes(),
    c(
      "External data only" = "external",
      "Use local data instead" = "local",
      "Combine external and local data" = "combine"
    )
  )
})

testthat::test_that("local Biology requires identifiers, dates and at least one index", {
  biology <- data.frame(
    biol_site_id = "B01",
    SAMPLE_ID = "S01",
    SAMPLE_DATE = "2024-05-01",
    WHPT_ASPT = "6.1",
    WHPT_N_TAXA = "",
    LIFE_FAMILY_INDEX = "",
    PSI_FAMILY_SCORE = "",
    Month = "5",
    Year = "2024",
    Season = "Spring",
    stringsAsFactors = FALSE
  )
  result <- validate_local_dataset(biology, "biology")
  testthat::expect_identical(result$status, "success")
  testthat::expect_s3_class(result$data$SAMPLE_DATE, "Date")
  testthat::expect_type(result$data$Year, "integer")

  no_index <- biology
  no_index[c("WHPT_ASPT", "WHPT_N_TAXA", "LIFE_FAMILY_INDEX", "PSI_FAMILY_SCORE")] <- ""
  testthat::expect_identical(
    validate_local_dataset(no_index, "biology")$status,
    "error"
  )

  missing_index_column <- biology[, setdiff(names(biology), "WHPT_N_TAXA"), drop = FALSE]
  testthat::expect_identical(
    validate_local_dataset(missing_index_column, "biology")$status,
    "error"
  )
})

testthat::test_that("local Flow preserves identifiers and rejects invalid values", {
  flow <- data.frame(
    flow_site_id = "00123",
    date = "2024-01-01",
    flow = "12.4",
    stringsAsFactors = FALSE
  )
  result <- validate_local_dataset(flow, "flow")
  testthat::expect_identical(result$status, "success")
  testthat::expect_identical(result$data$flow_site_id, "00123")
  testthat::expect_equal(result$data$flow, 12.4)

  flow$flow <- "not-a-number"
  testthat::expect_identical(validate_local_dataset(flow, "flow")$status, "error")
})

testthat::test_that("source modes replace or append without silent deduplication", {
  external <- data.frame(id = c("A", "B"), value = c(1, 2))
  local <- data.frame(id = c("B", "C"), value = c(20, 30))

  external_only <- resolve_local_data_source(external, local, "external", "dataset")
  local_only <- resolve_local_data_source(external, local, "local", "dataset")
  combined <- resolve_local_data_source(external, local, "combine", "dataset")

  testthat::expect_identical(external_only$data, external)
  testthat::expect_identical(local_only$data, local)
  testthat::expect_equal(nrow(combined$data), 4L)
  testthat::expect_equal(sum(combined$data$id == "B"), 2L)
  testthat::expect_identical(combined$provenance$output_rows, 4L)

  blocked <- resolve_local_data_source(external, NULL, "combine", "dataset")
  testthat::expect_identical(blocked$status, "blocked")
  testthat::expect_null(blocked$data)
})

testthat::test_that("combine mode aligns canonical fields and blocks schema mismatch", {
  external <- data.frame(
    flow = 9,
    date = as.Date("2024-01-01"),
    flow_site_id = "F01",
    external_note = "HDE"
  )
  local <- data.frame(
    flow_site_id = "F01",
    date = as.Date("2024-01-02"),
    flow = 10
  )
  combined <- resolve_local_data_source(external, local, "combine", "Flow")
  testthat::expect_identical(
    names(combined$data)[1:3],
    c("flow_site_id", "date", "flow")
  )
  testthat::expect_equal(nrow(combined$data), 2L)

  invalid <- external[, setdiff(names(external), "flow"), drop = FALSE]
  blocked <- resolve_local_data_source(invalid, local, "combine", "Flow")
  testthat::expect_identical(blocked$status, "blocked")
  testthat::expect_match(blocked$messages, "missing required column(s): flow", fixed = TRUE)
})
