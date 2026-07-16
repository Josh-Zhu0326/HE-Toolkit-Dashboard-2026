source(file.path("R", "site_mapping_helpers.R"))
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
