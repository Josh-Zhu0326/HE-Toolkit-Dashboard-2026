# test_workbook_validation_helpers.R
# Run in RStudio: open the project, then Source this file.
# Expect: "test_workbook_validation_helpers.R: all checks passed"

source(file.path("R", "join_contract_helpers.R"))
source(file.path("R", "workbook_validation_helpers.R"))

empty_sheet <- function(sheet_name, n = 1L) {
  out <- as.data.frame(
    stats::setNames(
      replicate(length(dc11_sheet_schemas()[[sheet_name]]), rep("", n), simplify = FALSE),
      dc11_sheet_schemas()[[sheet_name]]
    ),
    stringsAsFactors = FALSE
  )
  out
}

biology <- empty_sheet("biology_samples")
biology$biol_site_id <- "291"
biology$sample_id <- "S001"
biology$date <- "2024-05-01"
biology$sampling_year <- "2024"
biology$WHPT_ASPT <- "6.1"

biology_result <- validate_dc11_dataset(biology, "biology_samples")
stopifnot(identical(biology_result$status, "success"))

bad_biology <- biology
bad_biology$LIFE_F_OE <- "1.1"
bad_biology_result <- validate_dc11_dataset(bad_biology, "biology_samples")
stopifnot(identical(bad_biology_result$status, "error"))
stopifnot(any(bad_biology_result$issues$code == "unexpected_columns"))
stopifnot(any(bad_biology_result$issues$code == "oe_uploaded"))

no_index <- biology
no_index[, c("WHPT_ASPT", "WHPT_NTAXA", "LIFE_F", "PSI_F")] <- ""
no_index_result <- validate_dc11_dataset(no_index, "biology_samples")
stopifnot(identical(no_index_result$status, "error"))
stopifnot(any(no_index_result$issues$code == "missing_biology_index"))

flow <- empty_sheet("flow_daily")
flow$flow_site_id <- "00123"
flow$date <- "2024-01-01"
flow$flow <- "12.4"
flow_result <- validate_dc11_dataset(flow, "flow_daily")
stopifnot(identical(flow_result$status, "success"))

bad_flow_type <- flow
bad_flow_type$flow <- "not-a-number"
bad_flow_type_result <- validate_dc11_dataset(bad_flow_type, "flow_daily")
stopifnot(identical(bad_flow_type_result$status, "error"))
stopifnot(any(bad_flow_type_result$issues$code == "invalid_numeric"))

bad_flow <- flow
bad_flow$flow_input <- "HDE"
bad_flow_result <- validate_dc11_dataset(bad_flow, "flow_daily")
stopifnot(identical(bad_flow_result$status, "error"))
stopifnot(any(bad_flow_result$issues$code == "flow_input_wrong_sheet"))

wq <- empty_sheet("wq_long_standard")
wq$wq_site_id <- "WQ1"
wq$date_time <- "2024-01-01"
wq$det_id <- "0180"
wq$determinand <- "Orthophosphate reactive as P"
wq$result <- "0.1"
wq$unit <- "mg/L"
wq_result <- validate_dc11_dataset(wq, "wq_long_standard")
stopifnot(identical(wq_result$status, "success"))

bad_wq <- wq
bad_wq$area <- "10"
bad_wq_result <- validate_dc11_dataset(bad_wq, "wq_long_standard")
stopifnot(identical(bad_wq_result$status, "error"))
stopifnot(any(bad_wq_result$issues$code == "site_fields_in_wq"))

env <- empty_sheet("environmental_site_data")
env$biol_site_id <- "291"
env$NGR_PREFIX <- "SU"
env$ALKALINITY <- ""
env$CONDUCTIVITY <- "500"
env_result <- validate_dc11_dataset(env, "environmental_site_data")
stopifnot(identical(env_result$status, "success"))

bad_env_proxy <- env
bad_env_proxy$CONDUCTIVITY <- ""
bad_env_proxy$TOTAL_HARDNESS <- ""
bad_env_proxy$CALCIUM <- ""
bad_env_proxy_result <- validate_dc11_dataset(bad_env_proxy, "environmental_site_data")
stopifnot(identical(bad_env_proxy_result$status, "error"))
stopifnot(any(bad_env_proxy_result$issues$code == "alkalinity_proxy_missing"))

bad_env <- env
names(bad_env)[names(bad_env) == "NGR_PREFIX"] <- "NGR_prefix"
bad_env_result <- validate_dc11_dataset(bad_env, "environmental_site_data")
stopifnot(identical(bad_env_result$status, "error"))

workbook <- list(
  biology_samples = biology,
  flow_daily = flow,
  wq_long_standard = wq
)
workbook_result <- validate_dc11_workbook(workbook)
stopifnot(identical(workbook_result$status, "success"))
stopifnot(any(workbook_result$issues$code == "not_uploaded"))

workbook_with_metadata <- c(
  workbook,
  list(
    README = data.frame(note = "Template guidance", stringsAsFactors = FALSE),
    field_dictionary = data.frame(field = "biol_site_id", stringsAsFactors = FALSE),
    validation_rules = data.frame(rule = "DC-11", stringsAsFactors = FALSE)
  )
)
metadata_result <- validate_dc11_workbook(workbook_with_metadata)
stopifnot(identical(metadata_result$status, "success"))
stopifnot(!any(metadata_result$issues$code == "unknown_sheet"))

workbook$unexpected_sheet <- data.frame(x = 1)
unknown_result <- validate_dc11_workbook(workbook)
stopifnot(identical(unknown_result$status, "error"))
stopifnot(any(unknown_result$issues$code == "unknown_sheet"))

if (requireNamespace("openxlsx", quietly = TRUE) &&
    requireNamespace("readxl", quietly = TRUE)) {
  workbook_path <- tempfile("dc11-workbook-", fileext = ".xlsx")
  openxlsx::write.xlsx(workbook, workbook_path, overwrite = TRUE)
  workbook_file_result <- validate_dc11_workbook_file(workbook_path)
  stopifnot(identical(workbook_file_result$status, "error"))
  stopifnot(all(c("biology_samples", "flow_daily", "wq_long_standard") %in% names(workbook_file_result$sheets)))
  stopifnot(any(workbook_file_result$issues$code == "unknown_sheet"))

  workbook_valid <- workbook_with_metadata
  workbook_valid_path <- tempfile("dc11-workbook-valid-", fileext = ".xlsx")
  openxlsx::write.xlsx(workbook_valid, workbook_valid_path, overwrite = TRUE)
  workbook_valid_result <- validate_dc11_workbook_file(workbook_valid_path)
  stopifnot(identical(workbook_valid_result$status, "success"))
  stopifnot(!any(workbook_valid_result$issues$code == "unknown_sheet"))
  stopifnot(any(workbook_valid_result$issues$code == "not_uploaded"))
}

cat("test_workbook_validation_helpers.R: all checks passed\n")
