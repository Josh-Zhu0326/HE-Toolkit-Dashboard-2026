source(file.path("R", "site_mapping_helpers.R"))
source(file.path("R", "wq_rhs_plot_helpers.R"))
source(file.path("R", "wq_contract_helpers.R"))

wq_contract_data <- data.frame(
  biol_site_id = rep("B1", 7),
  wq_site_id = rep("WQ1", 7),
  date_time = c(
    "2022-01-01",
    "2023-06-01",
    "2024-12-31",
    "2021-12-31",
    "2024-01-01",
    "2024-02-01",
    "2024-03-01"
  ),
  det_id = c("180", "0180", "0111", "0180", "0111", "0119", "0111"),
  determinand = c(
    "Orthophosphate reactive as P",
    "Orthophosphate reactive as P",
    "Ammoniacal Nitrogen as N",
    "Orthophosphate reactive as P",
    "Ammoniacal Nitrogen as N",
    "Nitrogen 0119",
    "Ammoniacal Nitrogen as N"
  ),
  result = c(0.10, 0.20, 2.0, 999, 4.0, 8.0, 10.0),
  unit = c("mg/l", "MILLIGRAM PER LITRE", "mg/L", "mg/L", "mg/L", "mg/L", "mg/L"),
  qualifier = c("", "<", "", "", "", "", "<"),
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
stopifnot(summary_data$wq_window_end == as.Date("2024-12-31"))
stopifnot(summary_data$orthophosphate_record_count == 2)
stopifnot(summary_data$ammonia_record_count == 3)
stopifnot(summary_data$orthophosphate_below_detection_count == 1)
stopifnot(summary_data$ammonia_below_detection_count == 1)
stopifnot(summary_data$orthophosphate_det_id == "0180")
stopifnot(summary_data$ammonia_det_id == "0111")
stopifnot(grepl("included_records=2", summary_data$orthophosphate_provenance, fixed = TRUE))
stopifnot(grepl("included_records=3", summary_data$ammonia_provenance, fixed = TRUE))
stopifnot(grepl("not_ready_open_02", summary_data$wq_summary_provenance, fixed = TRUE))
stopifnot(isTRUE(all.equal(summary_data$orthophosphate_mean, 0.10)))
stopifnot(isTRUE(all.equal(summary_data$ammonia_p90, 4.8)))
stopifnot(is.na(summary_data$dissolved_oxygen_p10))
stopifnot(summary_data$dissolved_oxygen_status == "not_ready_open_02")

missing_det <- wq_contract_data[, setdiff(names(wq_contract_data), "det_id"), drop = FALSE]
missing_result <- standardise_wq_contract_records(missing_det)
stopifnot(missing_result$status == "error")
stopifnot(grepl("det_id", missing_result$messages))

plot_result <- build_wq_contract_summary_plot(summary_data)
stopifnot(inherits(plot_result$plot, "ggplot"))

cat("WQ contract helper tests passed\n")
