source(file.path("R", "csv_input_helpers.R"))
source(file.path("R", "site_mapping_helpers.R"))
source(file.path("R", "wq_rhs_plot_helpers.R"))
source(file.path("R", "wq_contract_helpers.R"))

wq_contract_data <- data.frame(
  biol_site_id = rep("B1", 9),
  wq_site_id = rep("WQ1", 9),
  date_time = c(
    "2022-01-01",
    "2023-06-01",
    "2024-12-31",
    "2021-12-31",
    "2024-01-01",
    "2024-02-01",
    "2024-03-01",
    "2024-04-01",
    "2024-05-01"
  ),
  det_id = c("180", "0180", "0111", "0180", "0111", "0119", "0111", "0180", "0111"),
  determinand = c(
    "Orthophosphate reactive as P",
    "Orthophosphate reactive as P",
    "Ammoniacal Nitrogen as N",
    "Orthophosphate reactive as P",
    "Ammoniacal Nitrogen as N",
    "Nitrogen 0119",
    "Ammoniacal Nitrogen as N",
    "Ammoniacal Nitrogen as N",
    "Ammoniacal Nitrogen as N"
  ),
  result = c(0.10, 0.20, 2.0, 999, 4.0, 8.0, 10.0, 10.0, 9.0),
  unit = c("mg/l", "MILLIGRAM PER LITRE", "mg/L", "mg/L", "mg/L", "mg/L", "mg/L", "mg/L", NA),
  qualifier = c("", "<", "", "", "", "", "<", "", ""),
  stringsAsFactors = FALSE
)

biology_contract_data <- data.frame(
  biol_site_id = "B1",
  sample_id = "S1",
  date = as.Date("2024-05-01"),
  sampling_year = 2024,
  stringsAsFactors = FALSE
)

standardised <- standardise_wq_contract_records(wq_contract_data)
stopifnot(standardised$status == "warning")
stopifnot("analysis_value" %in% names(standardised$data))
stopifnot(standardised$data$det_id[[1]] == "0180")
stopifnot(standardised$data$analysis_value[[2]] == 0.10)
stopifnot(standardised$data$analysis_value[[7]] == 5.00)
stopifnot(any(grepl("0119", standardised$messages)))
stopifnot(any(grepl("determinand text", standardised$messages)))
stopifnot(any(grepl("unsupported units", standardised$messages)))
stopifnot(!any(is.na(standardised$data$wq_contract_usable)))
stopifnot(!standardised$data$wq_contract_usable[[8]])
stopifnot(!standardised$data$wq_contract_usable[[9]])

hetoolkit_alias_data <- data.frame(
  `sample.samplingPoint.notation` = "WQ1",
  `sample.sampleDateTime` = "2024-01-01T10:00:00",
  `determinand.notation` = "111",
  `determinand.label` = "Ammoniacal Nitrogen as N",
  result = "2.5",
  `determinand.unit.label` = "mg/l",
  `resultQualifier.notation` = "<",
  check.names = FALSE
)
aliased <- standardise_wq_contract_records(hetoolkit_alias_data)
stopifnot(aliased$status == "warning")
stopifnot(aliased$data$wq_site_id == "WQ1")
stopifnot(aliased$data$det_id == "0111")
stopifnot(aliased$data$analysis_value == 1.25)

summary_result <- build_wq_contract_summary(wq_contract_data, biology_contract_data)
stopifnot(summary_result$status == "warning")
summary_data <- summary_result$data
stopifnot(nrow(summary_data) == 1)
stopifnot(summary_data$wq_window_start == as.Date("2022-01-01"))
stopifnot(summary_data$wq_effective_window_start == as.Date("2022-01-01"))
stopifnot(summary_data$wq_window_end == as.Date("2024-12-31"))
stopifnot(summary_data$wq_excluded_before_2000_count == 0L)
stopifnot(summary_data$orthophosphate_record_count == 2)
stopifnot(summary_data$ammonia_record_count == 3)
stopifnot(summary_data$orthophosphate_below_detection_count == 1)
stopifnot(summary_data$ammonia_below_detection_count == 1)
stopifnot(summary_data$orthophosphate_det_id == "0180")
stopifnot(summary_data$ammonia_det_id == "0111")
stopifnot(grepl("included_records=2", summary_data$orthophosphate_provenance, fixed = TRUE))
stopifnot(grepl("included_records=3", summary_data$ammonia_provenance, fixed = TRUE))
stopifnot(grepl("not_ready_open_02", summary_data$wq_summary_provenance, fixed = TRUE))
stopifnot(grepl("effective_window=2022-01-01 to 2024-12-31", summary_data$wq_summary_provenance, fixed = TRUE))
stopifnot(isTRUE(all.equal(summary_data$orthophosphate_mean, 0.10)))
stopifnot(isTRUE(all.equal(summary_data$ammonia_p90, 4.8)))
stopifnot(is.na(summary_data$dissolved_oxygen_p10))
stopifnot(summary_data$dissolved_oxygen_status == "not_ready_open_02")

early_wq <- wq_contract_data[1, , drop = FALSE]
early_wq$date_time <- "1999-12-31"
early_wq$biol_site_id <- "B1"
early_standardised <- standardise_wq_contract_records(early_wq)
stopifnot(early_standardised$status == "warning")
stopifnot(early_standardised$data$wq_before_min_date)
stopifnot(!early_standardised$data$wq_contract_usable)
stopifnot(any(grepl("retained in the source data", early_standardised$messages, fixed = TRUE)))

early_biology <- biology_contract_data
early_biology$date <- as.Date("2001-05-01")
early_biology$sampling_year <- 2001L
early_summary <- build_wq_contract_summary(rbind(wq_contract_data, early_wq), early_biology)
stopifnot(early_summary$data$wq_window_start == as.Date("1999-01-01"))
stopifnot(early_summary$data$wq_effective_window_start == as.Date("2000-01-01"))
stopifnot(early_summary$data$wq_excluded_before_2000_count == 1L)

missing_det <- wq_contract_data[, setdiff(names(wq_contract_data), "det_id"), drop = FALSE]
missing_result <- standardise_wq_contract_records(missing_det)
stopifnot(missing_result$status == "error")
stopifnot(grepl("det_id", missing_result$messages))

unmapped_wq <- wq_contract_data[, setdiff(names(wq_contract_data), "biol_site_id"), drop = FALSE]
unmapped_summary <- build_wq_contract_summary(unmapped_wq, biology_contract_data)
stopifnot(unmapped_summary$status == "error")
stopifnot(grepl(
  "Mapped WQ records must contain biol_site_id",
  unmapped_summary$messages,
  fixed = TRUE
))

cat("WQ contract helper tests passed\n")
