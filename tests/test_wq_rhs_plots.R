source(file.path("R", "csv_input_helpers.R"))
source(file.path("R", "site_mapping_helpers.R"))
source(file.path("R", "wq_contract_helpers.R"))
source(file.path("R", "wq_rhs_plot_helpers.R"))

mapping_text <- paste(
  "biol_site_id,flow_site_id,flow_input,wq_site_id,rhs_survey_id",
  "291,27090,NRFA,WQ01,TBC",
  "292,27091,NRFA,WQ02,RHS001",
  sep = "\n"
)
mapping <- parse_site_metadata(mapping_text)
stopifnot(is.null(mapping$error))

contract_wq <- data.frame(
  wq_site_id = c("WQ01", "WQ01", "WQ02", "WQ02"),
  date_time = c("1999-12-31", "2024-01-01", "2024-02-01", "2024-03-01"),
  det_id = c("0180", "0180", "0111", "0180"),
  result = c(9.9, 0.08, 0.12, 0.10),
  stringsAsFactors = FALSE
)
mapped_wq <- map_wq_records_to_biology(contract_wq, mapping$data)
stopifnot(nrow(mapped_wq) == 4L)

contract_spec <- wq_preview_filter_spec(mapped_wq)
stopifnot(contract_spec$determinand_col == "det_id")
stopifnot(contract_spec$site_col == "wq_site_id")
stopifnot(contract_spec$date_col == "date_time")
stopifnot(contract_spec$value_col == "result")
stopifnot(contract_spec$group_col == "wq_site_id")
stopifnot(contract_spec$date_min == as.Date("2024-01-01"))

contract_filtered <- filter_wq_preview_data(
  mapped_wq,
  determinant = "0180",
  site = "WQ02",
  date_range = as.Date(c("2024-02-01", "2024-03-31"))
)
stopifnot(nrow(contract_filtered) == 1L)
stopifnot(contract_filtered$wq_site_id == "WQ02")

wq_time_series <- build_wq_plot(mapped_wq, "Time series")
stopifnot(inherits(wq_time_series$plot, "ggplot"))
stopifnot(identical(wq_time_series$plot$labels$colour, "wq_site_id"))

wq_boxplot <- build_wq_plot(mapped_wq, "Boxplot")
stopifnot(inherits(wq_boxplot$plot, "ggplot"))
stopifnot(identical(wq_boxplot$plot$labels$x, "wq_site_id"))

wq_bar <- build_wq_plot(mapped_wq, "Mean bar chart")
stopifnot(is.null(wq_bar$plot))
stopifnot(grepl("Time series or Boxplot", wq_bar$message, fixed = TRUE))

wq_missing_result <- build_wq_plot(
  mapped_wq[, setdiff(names(mapped_wq), "result"), drop = FALSE],
  "Boxplot"
)
stopifnot(is.null(wq_missing_result$plot))
stopifnot(grepl("result", wq_missing_result$message, fixed = TRUE))

long_site_wq <- data.frame(
  wq_site_id = sprintf("WQ_SITE_%02d_LONG_LABEL", 1:12),
  date_time = "2024-01-01",
  det_id = "0180",
  result = seq(0.1, 1.2, length.out = 12),
  stringsAsFactors = FALSE
)
long_site_box <- build_wq_plot(long_site_wq, "Boxplot")
stopifnot(inherits(long_site_box$plot$coordinates, "CoordFlip"))
stopifnot(grepl("Long wq_site_id values are truncated", long_site_box$plot$labels$caption, fixed = TRUE))

rhs_data <- data.frame(
  rhs_survey_id = c("RHS001", "RHS001"),
  HQA = c(55, 58),
  HMSRBB = c(2, 3),
  stringsAsFactors = FALSE
)
mapped_rhs <- map_rhs_records_to_biology(rhs_data, mapping$data)
stopifnot(nrow(mapped_rhs) == 2L)
stopifnot(all(mapped_rhs$biol_site_id == "292"))
stopifnot("rhs_survey_id" %in% names(mapped_rhs))
stopifnot(!"rhs_site_id" %in% names(mapped_rhs))

rhs_tbc_only_mapping <- parse_site_metadata("biol_site_id,rhs_survey_id\n291,TBC")
rhs_tbc_mapped <- map_rhs_records_to_biology(rhs_data, rhs_tbc_only_mapping$data)
stopifnot(nrow(rhs_tbc_mapped) == nrow(rhs_data))
stopifnot(all(is.na(rhs_tbc_mapped$biol_site_id)))

cat("WQ plot contract and RHS table-only mapping tests passed\n")
