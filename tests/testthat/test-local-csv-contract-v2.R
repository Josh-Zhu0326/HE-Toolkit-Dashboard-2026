fixture_path <- function(name) {
  testthat::test_path("..", "..", "www", "templates", "local_csv_v2", name)
}

testthat::test_that("v2 exposes exactly five primary local CSV contracts", {
  testthat::expect_identical(
    local_csv_v2_types(),
    c("biology", "environmental", "flow", "wq", "rhs")
  )
  testthat::expect_error(
    local_csv_v2_contract("workbook"),
    "Unknown local CSV data type",
    fixed = TRUE
  )
})

testthat::test_that("all five valid CSV fixtures pass independently", {
  fixture_names <- stats::setNames(
    paste0(local_csv_v2_types(), ".csv"),
    local_csv_v2_types()
  )
  for (data_type in names(fixture_names)) {
    result <- read_local_csv_v2(fixture_path(fixture_names[[data_type]]), data_type)
    testthat::expect_identical(result$status, "success", info = data_type)
    testthat::expect_s3_class(result$data, "data.frame")
    testthat::expect_gt(nrow(result$data), 0L)
  }
})

testthat::test_that("biology ingestion uses explicit canonical field mappings", {
  result <- read_local_csv_v2(fixture_path("biology.csv"), "biology")

  testthat::expect_true(all(c(
    "sample_id", "date", "LIFE_F", "PSI_F", "month", "sampling_year", "season"
  ) %in% names(result$data)))
  testthat::expect_false(any(c("SAMPLE_ID", "SAMPLE_DATE") %in% names(result$data)))
  testthat::expect_identical(result$data$sample_id[[1L]], "00017")
  testthat::expect_s3_class(result$data$date, "Date")
  testthat::expect_type(result$data$LIFE_F, "double")
})

testthat::test_that("identifier leading zeros are preserved", {
  flow <- read_local_csv_v2(fixture_path("flow.csv"), "flow")$data
  wq <- read_local_csv_v2(fixture_path("wq.csv"), "wq")$data

  testthat::expect_identical(flow$flow_site_id[[1L]], "00123")
  testthat::expect_identical(wq$det_id, c("0180", "0111"))
})

testthat::test_that("missing and duplicate headers block only that CSV", {
  valid <- read_character_csv(path = fixture_path("flow.csv"))
  missing <- valid[, setdiff(names(valid), "flow"), drop = FALSE]
  duplicate <- valid
  names(duplicate)[[3L]] <- "date"

  missing_result <- validate_local_csv_v2(missing, "flow")
  duplicate_result <- validate_local_csv_v2(duplicate, "flow")

  testthat::expect_identical(missing_result$status, "error")
  testthat::expect_true("missing_headers" %in% missing_result$issues$code)
  testthat::expect_identical(duplicate_result$status, "error")
  testthat::expect_true("duplicate_headers" %in% duplicate_result$issues$code)
})

testthat::test_that("safe extra fields are reported and ignored", {
  flow <- read_character_csv(path = fixture_path("flow.csv"))
  flow$notes <- "source note"
  result <- validate_local_csv_v2(flow, "flow")

  testthat::expect_identical(result$status, "success")
  testthat::expect_true("extra_headers_ignored" %in% result$issues$code)
  testthat::expect_false("notes" %in% names(result$data))
})

testthat::test_that("unsafe required types and blank identifiers are blocked", {
  flow <- read_character_csv(path = fixture_path("flow.csv"))
  flow$flow[[1L]] <- "not-a-number"
  flow$flow_site_id[[2L]] <- ""
  result <- validate_local_csv_v2(flow, "flow")

  testthat::expect_identical(result$status, "error")
  testthat::expect_true(all(c(
    "invalid_numeric", "blank_required_value"
  ) %in% result$issues$code))
})

testthat::test_that("biology requires a usable index and rejects uploaded O:E fields", {
  biology <- read_character_csv(path = fixture_path("biology.csv"))
  biology[c(
    "WHPT_ASPT", "WHPT_N_TAXA", "LIFE_FAMILY_INDEX", "PSI_FAMILY_SCORE"
  )] <- ""
  biology$LIFE_F_OE <- "1.1"
  result <- validate_local_csv_v2(biology, "biology")

  testthat::expect_identical(result$status, "error")
  testthat::expect_true(all(c(
    "missing_biology_index", "prohibited_oe_fields"
  ) %in% result$issues$code))
})

testthat::test_that("WQ determinand identifiers must contain four characters", {
  wq <- read_character_csv(path = fixture_path("wq.csv"))
  wq$det_id[[1L]] <- "180"
  result <- validate_local_csv_v2(wq, "wq")

  testthat::expect_identical(result$status, "error")
  testthat::expect_true("invalid_det_id" %in% result$issues$code)
})

testthat::test_that("header-only and unreadable files are blocked", {
  flow <- read_character_csv(path = fixture_path("flow.csv"))[0, , drop = FALSE]
  header_only <- validate_local_csv_v2(flow, "flow")
  unreadable <- validate_local_csv_v2(NULL, "flow")

  testthat::expect_true("no_data_rows" %in% header_only$issues$code)
  testthat::expect_true("unreadable_csv" %in% unreadable$issues$code)
  testthat::expect_null(header_only$data)
  testthat::expect_null(unreadable$data)
})
