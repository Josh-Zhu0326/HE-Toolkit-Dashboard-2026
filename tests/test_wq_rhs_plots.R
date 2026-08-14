source(file.path("R", "csv_input_helpers.R"))
source(file.path("R", "site_mapping_helpers.R"))
source(file.path("R", "wq_contract_helpers.R"))
source(file.path("R", "wq_rhs_plot_helpers.R"))

mapping_text <- paste(
  "biol_site_id,flow_site_id,flow_input,wq_site_id,rhs_survey_id",
  "291,27090,NRFA,SW-A4070115,TBC",
  "292,27091,NRFA,SW-A4070116,RHS001",
  sep = "\n"
)

wq_data <- data.frame(
  wq_site_id = c("SW-A4070115", "SW-A4070115", "SW-A4070116"),
  date = c("2024-01-01", "2024-02-01", "2024-01-01"),
  pH = c(7.2, 7.4, 6.9),
  nitrate = c(3.1, 2.9, 4.2),
  phosphate = c(0.08, 0.07, 0.12),
  stringsAsFactors = FALSE
)

rhs_data <- data.frame(
  rhs_survey_id = c("RHS001", "RHS001"),
  habitat_score = c(55, 58),
  channel_type = c("natural", "natural"),
  stringsAsFactors = FALSE
)

mapping <- parse_site_metadata(mapping_text)
stopifnot(is.null(mapping$error))

mapped_wq <- map_wq_records_to_biology(wq_data, mapping$data)
stopifnot(nrow(mapped_wq) == 3)
stopifnot(setequal(mapped_wq$biol_site_id, c("291", "292")))
stopifnot("date" %in% wq_rhs_date_columns(mapped_wq))
stopifnot(all(c("pH", "nitrate", "phosphate") %in% wq_rhs_numeric_columns(mapped_wq)))

wq_time_series <- build_wq_plot(mapped_wq, "Time series", "pH", "date", "biol_site_id")
stopifnot(inherits(wq_time_series$plot, "ggplot"))

wq_boxplot <- build_wq_plot(mapped_wq, "Boxplot by biological site ID", "nitrate", NULL, "biol_site_id")
stopifnot(inherits(wq_boxplot$plot, "ggplot"))

wq_bar <- build_wq_plot(mapped_wq, "Mean bar chart by biological site ID", "phosphate", NULL, "biol_site_id")
stopifnot(inherits(wq_bar$plot, "ggplot"))

contract_wq <- data.frame(
  biol_site_id = c("291", "291", "292"),
  wq_site_id = c("WQ01", "WQ01", "WQ02"),
  date_time = c("2024-01-01", "2024-02-01", "2024-03-01"),
  det_id = c("0180", "0111", "0180"),
  result = c(0.08, 0.12, 0.10),
  wq_easting = c(410000, 410000, 420000),
  wq_northing = c(220000, 220000, 230000),
  stringsAsFactors = FALSE
)
contract_spec <- wq_preview_filter_spec(contract_wq)
stopifnot(contract_spec$determinand_col == "det_id")
stopifnot(contract_spec$site_col == "wq_site_id")
stopifnot(contract_spec$date_col == "date_time")
stopifnot(contract_spec$value_col == "result")
stopifnot(contract_spec$group_col == "biol_site_id")
stopifnot(!contract_spec$value_col %in% c("wq_easting", "wq_northing"))

numeric_det_id <- contract_wq
numeric_det_id$det_id <- c(180, 111, 180)
numeric_det_id <- normalise_wq_preview_records(numeric_det_id)
stopifnot(identical(numeric_det_id$det_id, c("0180", "0111", "0180")))

contract_filtered <- filter_wq_preview_data(
  contract_wq,
  determinant = "0180",
  site = "WQ02",
  date_range = as.Date(c("2024-02-01", "2024-03-31"))
)
stopifnot(nrow(contract_filtered) == 1L)
stopifnot(contract_filtered$wq_site_id == "WQ02")
stopifnot(contract_filtered$det_id == "0180")

long_site_wq <- data.frame(
  biol_site_id = sprintf("BIO_SITE_%02d_LONG_LABEL", 1:12),
  date = "2024-01-01",
  pH = seq(7, 8.1, length.out = 12),
  stringsAsFactors = FALSE
)
long_site_wq_bar <- build_wq_plot(long_site_wq, "Mean bar chart by biological site ID", "pH", NULL, "biol_site_id")
stopifnot(inherits(long_site_wq_bar$plot$coordinates, "CoordFlip"))
stopifnot(grepl("Long biol_site_id values are truncated", long_site_wq_bar$plot$labels$caption, fixed = TRUE))

wq_without_date <- mapped_wq[, setdiff(names(mapped_wq), "date"), drop = FALSE]
wq_missing_date <- build_wq_plot(wq_without_date, "Time series", "pH", NULL, "biol_site_id")
stopifnot(is.null(wq_missing_date$plot))
stopifnot(grepl("date-like column", wq_missing_date$message))

wq_without_numeric <- data.frame(
  biol_site_id = c("291", "292"),
  wq_site_id = c("SW-A4070115", "SW-A4070116"),
  date = c("2024-01-01", "2024-01-01"),
  descriptor = c("clear", "cloudy"),
  stringsAsFactors = FALSE
)
wq_missing_numeric <- build_wq_plot(wq_without_numeric, "Boxplot by biological site ID", "descriptor", NULL, "biol_site_id")
stopifnot(is.null(wq_missing_numeric$plot))
stopifnot(grepl("numeric variable", wq_missing_numeric$message))

mapped_rhs <- map_rhs_records_to_biology(rhs_data, mapping$data)
stopifnot(nrow(mapped_rhs) == 2)
stopifnot(all(mapped_rhs$biol_site_id == "292"))
stopifnot("rhs_survey_id" %in% names(mapped_rhs))
stopifnot(!"rhs_site_id" %in% names(mapped_rhs))

rhs_numeric <- build_rhs_plot(mapped_rhs, "Numeric variable by biological site ID", "habitat_score", "biol_site_id")
stopifnot(inherits(rhs_numeric$plot, "ggplot"))

rhs_category <- build_rhs_plot(mapped_rhs, "Categorical count/bar plot", "channel_type", "biol_site_id")
stopifnot(inherits(rhs_category$plot, "ggplot"))

rhs_count <- build_rhs_plot(mapped_rhs, "Record count by biological site ID", NULL, "biol_site_id")
stopifnot(inherits(rhs_count$plot, "ggplot"))

long_site_rhs <- data.frame(
  biol_site_id = rep(sprintf("BIO_SITE_%02d_LONG_LABEL", 1:12), each = 2),
  rhs_survey_id = sprintf("RHS%03d", 1:24),
  habitat_score = seq(40, 63),
  channel_type = rep(sprintf("Category_%02d_LONG_LABEL", 1:12), each = 2),
  stringsAsFactors = FALSE
)
long_site_rhs_count <- build_rhs_plot(long_site_rhs, "Record count by biological site ID", NULL, "biol_site_id")
stopifnot(inherits(long_site_rhs_count$plot$coordinates, "CoordFlip"))
stopifnot(grepl("Long biol_site_id values are truncated", long_site_rhs_count$plot$labels$caption, fixed = TRUE))
long_category_rhs <- build_rhs_plot(long_site_rhs, "Categorical count/bar plot", "channel_type", "biol_site_id")
stopifnot(inherits(long_category_rhs$plot$coordinates, "CoordFlip"))
stopifnot(grepl("Long channel_type values are truncated", long_category_rhs$plot$labels$caption, fixed = TRUE))

rhs_tbc_only_mapping <- parse_site_metadata("biol_site_id,rhs_survey_id\n291,TBC")
stopifnot(is.null(rhs_tbc_only_mapping$error))
rhs_tbc_mapped <- map_rhs_records_to_biology(rhs_data, rhs_tbc_only_mapping$data)
stopifnot(nrow(rhs_tbc_mapped) == 2)
rhs_tbc_plot <- build_rhs_plot(rhs_tbc_mapped, "Record count by biological site ID", NULL, "rhs_survey_id")
stopifnot(inherits(rhs_tbc_plot$plot, "ggplot"))

rhs_without_numeric <- data.frame(
  biol_site_id = "292",
  rhs_survey_id = "RHS001",
  channel_type = "natural",
  stringsAsFactors = FALSE
)
rhs_missing_numeric <- build_rhs_plot(rhs_without_numeric, "Numeric variable by biological site ID", "channel_type", "biol_site_id")
stopifnot(is.null(rhs_missing_numeric$plot))
stopifnot(grepl("numeric variable", rhs_missing_numeric$message))

cat("WQ/RHS plot tests passed\n")
