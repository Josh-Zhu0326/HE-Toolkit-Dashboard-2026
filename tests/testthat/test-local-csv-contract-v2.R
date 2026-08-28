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

testthat::test_that("template headers match the frozen v2.0 schemas", {
  expected_headers <- list(
    biology = c(
      "biol_site_id", "SAMPLE_ID", "SAMPLE_DATE", "WHPT_ASPT",
      "WHPT_N_TAXA", "LIFE_FAMILY_INDEX", "PSI_FAMILY_SCORE",
      "Month", "Year", "Season"
    ),
    environmental = c(
      "biol_site_id", "NGR_10_FIG", "ALTITUDE", "SLOPE",
      "DIST_FROM_SOURCE", "DISCHARGE", "WIDTH", "DEPTH",
      "BOULDERS_COBBLES", "PEBBLES_GRAVEL", "SAND", "SILT_CLAY",
      "ALKALINITY", "CONDUCTIVITY", "MIN_SAMPLE_DATE",
      "MAX_SAMPLE_DATE", "COUNT_OF_SAMPLES"
    ),
    flow = c("flow_site_id", "date", "flow"),
    wq = c("wq_site_id", "date_time", "det_id", "qualifier", "result"),
    rhs = c("rhs_survey_id", "HQA", "HMSRBB")
  )

  for (data_type in names(expected_headers)) {
    data <- read_character_csv(path = fixture_path(paste0(data_type, ".csv")))
    testthat::expect_identical(names(data), expected_headers[[data_type]])
    testthat::expect_identical(
      local_csv_v2_contract(data_type)$fields,
      expected_headers[[data_type]]
    )
  }

  environmental <- read_character_csv(path = fixture_path("environmental.csv"))
  testthat::expect_match(environmental$NGR_10_FIG[[1L]], "^[A-Z]{2}[0-9]{10}$")
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

testthat::test_that("canonical Biology data cross the HE Toolkit boundary explicitly", {
  canonical <- read_local_csv_v2(fixture_path("biology.csv"), "biology")$data
  adapted <- local_biology_to_hetoolkit_input(canonical)

  testthat::expect_identical(names(adapted), c(
    "biol_site_id", "SAMPLE_ID", "SAMPLE_DATE", "WHPT_ASPT",
    "WHPT_N_TAXA", "LIFE_FAMILY_INDEX", "PSI_FAMILY_SCORE", "Month",
    "Year", "Season"
  ))
  testthat::expect_identical(adapted$SAMPLE_ID[[1L]], "00017")
  testthat::expect_s3_class(adapted$SAMPLE_DATE, "Date")
  testthat::expect_false(any(c("sample_id", "date", "LIFE_F") %in% names(adapted)))
  testthat::expect_error(
    local_biology_to_hetoolkit_input(canonical[, setdiff(names(canonical), "sample_id")]),
    "must pass Data Contract v2.0 normalisation",
    fixed = TRUE
  )
})

testthat::test_that("Environmental NGR values are validated before boundary conversion", {
  environmental <- read_character_csv(path = fixture_path("environmental.csv"))
  environmental$NGR_10_FIG <- "SO12345"
  result <- validate_local_csv_v2(environmental, "environmental")

  testthat::expect_identical(result$status, "error")
  testthat::expect_true("invalid_ngr_10_fig" %in% result$issues$code)
})

testthat::test_that("canonical Environmental data cross the HE Toolkit boundary explicitly", {
  canonical <- read_local_csv_v2(
    fixture_path("environmental.csv"),
    "environmental"
  )$data
  adapted <- local_environment_to_hetoolkit_input(canonical)

  testthat::expect_identical(names(adapted), c(
    "WATER_BODY", "biol_site_id", "NGR_PREFIX", "EASTING", "NORTHING",
    "WFD_WATERBODY_ID", "ALTITUDE", "SLOPE", "DIST_FROM_SOURCE",
    "DISCHARGE", "WIDTH", "DEPTH", "BOULDERS_COBBLES", "PEBBLES_GRAVEL",
    "SAND", "SILT_CLAY", "ALKALINITY", "CONDUCTIVITY", "TOTAL_HARDNESS",
    "CALCIUM", "NGR_10_FIG"
  ))
  testthat::expect_identical(adapted$NGR_PREFIX, "SO")
  testthat::expect_identical(adapted$EASTING, "12345")
  testthat::expect_identical(adapted$NORTHING, "12345")
  testthat::expect_true(all(is.na(adapted$WATER_BODY)))
  testthat::expect_true(all(is.na(adapted$TOTAL_HARDNESS)))
  testthat::expect_identical(adapted$NGR_10_FIG, canonical$NGR_10_FIG)
})

testthat::test_that("Environmental boundary output is accepted by the real RICT path", {
  canonical <- read_local_csv_v2(
    fixture_path("environmental.csv"),
    "environmental"
  )$data
  canonical$ALKALINITY <- NA_real_
  adapted <- local_environment_to_hetoolkit_input(canonical)

  predictions <- suppressWarnings(hetoolkit::predict_indices(
    env_data = adapted,
    file_format = "EDE",
    all_indices = TRUE
  ))

  testthat::expect_identical(nrow(predictions), 3L)
  testthat::expect_identical(unique(predictions$biol_site_id), "B001")
  testthat::expect_true(all(c(
    "SEASON", "TL2_WHPT_ASPT_AbW_DistFam", "TL3_LIFE_Fam_DistFam"
  ) %in% names(predictions)))
  testthat::expect_true(all(is.finite(predictions$ALKALINITY)))
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

testthat::test_that("non-Biology coordinate fields are informational only", {
  wq <- read_character_csv(path = fixture_path("wq.csv"))
  wq$easting <- "412345"
  wq$northing <- "256789"
  result <- validate_local_csv_v2(wq, "wq")

  testthat::expect_identical(result$status, "success")
  testthat::expect_true("extra_headers_ignored" %in% result$issues$code)
  testthat::expect_false(any(c("easting", "northing") %in% names(result$data)))
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

testthat::test_that("date parsing is safe and shared with normalisation", {
  flow <- read_character_csv(path = fixture_path("flow.csv"))
  flow$date[[1L]] <- "2024-02-31"
  impossible <- validate_local_csv_v2(flow, "flow")
  flow$date[[1L]] <- "31/12/2024"
  uk_date <- validate_local_csv_v2(flow, "flow")

  testthat::expect_identical(impossible$status, "error")
  testthat::expect_true("invalid_date" %in% impossible$issues$code)
  testthat::expect_identical(uk_date$status, "success")
  testthat::expect_identical(uk_date$data$date[[1L]], as.Date("2024-12-31"))

  wq <- read_local_csv_v2(fixture_path("wq.csv"), "wq")$data
  testthat::expect_s3_class(wq$date_time, "POSIXct")
  testthat::expect_identical(
    format(wq$date_time[[1L]], "%Y-%m-%d %H:%M:%S", tz = "UTC"),
    "2024-04-01 09:30:00"
  )

  invalid_wq <- read_character_csv(path = fixture_path("wq.csv"))
  invalid_wq$date_time[[1L]] <- "2024-04-01 25:00:00"
  invalid_wq_result <- validate_local_csv_v2(invalid_wq, "wq")
  testthat::expect_identical(invalid_wq_result$status, "error")
  testthat::expect_true("invalid_datetime" %in% invalid_wq_result$issues$code)
})

testthat::test_that("environmental alkalinity requires a usable proxy", {
  environmental <- read_character_csv(path = fixture_path("environmental.csv"))
  environmental$ALKALINITY <- ""
  environmental$CONDUCTIVITY <- ""
  result <- validate_local_csv_v2(environmental, "environmental")

  testthat::expect_identical(result$status, "error")
  testthat::expect_true("alkalinity_proxy_missing" %in% result$issues$code)
})

testthat::test_that("RHS applies one-way HMS.Score compatibility", {
  canonical <- read_character_csv(path = fixture_path("rhs.csv"))

  legacy_only <- canonical
  names(legacy_only)[names(legacy_only) == "HMSRBB"] <- "HMS.Score"
  legacy_result <- validate_local_csv_v2(legacy_only, "rhs")
  testthat::expect_identical(legacy_result$status, "warning")
  testthat::expect_true("rhs_legacy_hms_renamed" %in% legacy_result$issues$code)
  testthat::expect_true("HMSRBB" %in% names(legacy_result$data))
  testthat::expect_false("HMS.Score" %in% names(legacy_result$data))

  matching <- canonical
  matching$HMS.Score <- "12.0"
  matching_result <- validate_local_csv_v2(matching, "rhs")
  testthat::expect_identical(matching_result$status, "warning")
  testthat::expect_true("rhs_duplicate_hms_field" %in% matching_result$issues$code)
  testthat::expect_false("HMS.Score" %in% names(matching_result$data))

  conflicting <- canonical
  conflicting$HMS.Score <- "99"
  conflict_result <- validate_local_csv_v2(conflicting, "rhs")
  testthat::expect_identical(conflict_result$status, "error")
  testthat::expect_true("rhs_hms_field_conflict" %in% conflict_result$issues$code)
  testthat::expect_null(conflict_result$data)
})

testthat::test_that("header-only and unreadable files are blocked", {
  flow <- read_character_csv(path = fixture_path("flow.csv"))[0, , drop = FALSE]
  header_only <- validate_local_csv_v2(flow, "flow")
  unreadable <- validate_local_csv_v2(NULL, "flow")

  testthat::expect_true("no_data_rows" %in% header_only$issues$code)
  testthat::expect_true("unreadable_csv" %in% unreadable$issues$code)
  testthat::expect_null(header_only$data)
  testthat::expect_null(unreadable$data)

  throwing_reader <- function(path) stop("parser failed")
  reader_failure <- read_local_csv_v2(
    fixture_path("flow.csv"),
    "flow",
    reader = throwing_reader
  )
  testthat::expect_identical(reader_failure$status, "error")
  testthat::expect_true("unreadable_csv" %in% reader_failure$issues$code)
})
