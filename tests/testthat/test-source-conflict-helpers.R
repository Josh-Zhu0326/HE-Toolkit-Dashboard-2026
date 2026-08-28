testthat::test_that("the five source types expose stable record identity keys", {
  fixtures <- list(
    biology = data.frame(biol_site_id = "B1", SAMPLE_ID = "S1"),
    environmental = data.frame(biol_site_id = "B1"),
    flow = data.frame(flow_site_id = "F1", date = as.Date("2024-01-01")),
    wq = data.frame(
      wq_site_id = "W1",
      date_time = as.POSIXct("2024-01-01 10:00:00", tz = "UTC"),
      det_id = "0180"
    ),
    rhs = data.frame(rhs_survey_id = "R1")
  )
  expected <- list(
    biology = c("biol_site_id", "SAMPLE_ID"),
    environmental = "biol_site_id",
    flow = c("flow_site_id", "date"),
    wq = c("wq_site_id", "date_time", "det_id"),
    rhs = "rhs_survey_id"
  )

  for (data_type in names(fixtures)) {
    testthat::expect_identical(
      source_reconciliation_key_fields(fixtures[[data_type]], fixtures[[data_type]], data_type),
      expected[[data_type]]
    )
  }
})

testthat::test_that("exact cross-source duplicates are reported and collapsed", {
  local <- data.frame(
    flow_site_id = c("F1", "F1"),
    date = as.Date(c("2024-01-01", "2024-01-02")),
    flow = c(1.5, 2.5)
  )
  explorer <- data.frame(
    flow_site_id = c("F1", "F2"),
    date = as.Date(c("2024-01-01", "2024-01-03")),
    flow = c(1.5, 3.5),
    source_note = c("Explorer", "Explorer")
  )

  result <- reconcile_source_records(local, explorer, "flow")

  testthat::expect_true(result$ready)
  testthat::expect_identical(result$status, "success")
  testthat::expect_equal(nrow(result$data), 3L)
  testthat::expect_identical(result$provenance$exact_duplicates_removed, 1L)
  testthat::expect_equal(nrow(result$conflicts), 0L)
  testthat::expect_true("source_note" %in% names(result$data))
})

testthat::test_that("conflicting records remain blocked until the user chooses", {
  local <- data.frame(
    flow_site_id = "F1",
    date = as.Date("2024-01-01"),
    flow = 1.5
  )
  explorer <- transform(local, flow = 9.5)

  unresolved <- reconcile_source_records(local, explorer, "flow")
  testthat::expect_false(unresolved$ready)
  testthat::expect_identical(unresolved$status, "conflict")
  testthat::expect_identical(unresolved$conflicts$differing_fields, "flow")
  testthat::expect_error(
    source_reconciliation_ready_data(unresolved),
    "need a source choice",
    fixed = TRUE
  )

  keep_local <- reconcile_source_records(local, explorer, "flow", "local")
  keep_explorer <- reconcile_source_records(local, explorer, "flow", "explorer")
  exclude <- reconcile_source_records(local, explorer, "flow", "exclude")
  testthat::expect_true(keep_local$ready)
  testthat::expect_identical(keep_local$data$flow, 1.5)
  testthat::expect_identical(keep_explorer$data$flow, 9.5)
  testthat::expect_equal(nrow(exclude$data), 0L)
  testthat::expect_identical(exclude$provenance$conflict_preference, "exclude")
})

testthat::test_that("ambiguous duplicate identities inside one source are rejected", {
  local <- data.frame(
    rhs_survey_id = c("R1", "R1"),
    HQA = c(10, 20)
  )
  explorer <- data.frame(rhs_survey_id = "R1", HQA = 10)

  result <- reconcile_source_records(local, explorer, "rhs")

  testthat::expect_false(result$ready)
  testthat::expect_identical(result$status, "error")
  testthat::expect_match(result$messages, "multiple non-identical rows", fixed = TRUE)
})

testthat::test_that("source conflict UI shows both values and all three decisions", {
  local <- data.frame(flow_site_id = "F1", date = as.Date("2024-01-01"), flow = 1)
  explorer <- transform(local, flow = 2)
  result <- reconcile_source_records(local, explorer, "flow")
  html <- as.character(source_conflict_resolution_panel(list(flow = result)))

  testthat::expect_match(html, "local_values", fixed = TRUE)
  testthat::expect_match(html, "explorer_values", fixed = TRUE)
  testthat::expect_match(html, "Keep Local records", fixed = TRUE)
  testthat::expect_match(html, "Keep Data Explorer records", fixed = TRUE)
  testthat::expect_match(html, "Exclude conflicting records", fixed = TRUE)
})
