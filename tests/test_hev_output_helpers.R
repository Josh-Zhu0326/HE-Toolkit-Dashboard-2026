# test_hev_output_helpers.R
# Expect: "test_hev_output_helpers.R: all checks passed"

source(file.path("R", "hev_output_helpers.R"))

hev_data <- data.frame(
  biol_site_id = c("B001", "B001"),
  Year = c(2021, 2022),
  WHPT_ASPT_OE = c(0.9, 1.1),
  LIFE_F_OE = c(0.8, 1.0),
  Q95z = c(-0.4, -0.2),
  Q10z = c(0.5, 0.7),
  stringsAsFactors = FALSE
)

biology_one <- resolve_hev_biology_metrics(hev_data, "LIFE_F_OE", show_all = FALSE)
stopifnot(identical(biology_one, "LIFE_F_OE"))

biology_all <- resolve_hev_biology_metrics(hev_data, "LIFE_F_OE", show_all = TRUE)
stopifnot(identical(biology_all, c("WHPT_ASPT_OE", "LIFE_F_OE")))

flow_high_low <- resolve_hev_flow_metrics(hev_data, "Q95z", show_high_low = TRUE)
stopifnot(identical(flow_high_low, c("Q95z", "Q10z")))

flow_fallback <- resolve_hev_flow_metrics(hev_data[, names(hev_data) != "Q10z"], "Q95z", show_high_low = TRUE)
stopifnot(identical(flow_fallback, "Q95z"))

analysis_context <- list(
  source_dataset = "joined_enriched",
  source_fingerprint = "3::5::example",
  filter_version = 2L,
  analysis_rows = 10L
)
provenance <- build_hev_output_provenance(
  analysis_context = analysis_context,
  plot_data = hev_data,
  site_id = "B001",
  date_range = c(2021, 2022),
  biology_metrics = biology_one,
  flow_metrics = flow_high_low,
  generated_at = as.POSIXct("2026-08-06 12:00:00", tz = "UTC")
)

stopifnot(identical(provenance$source_dataset, "joined_enriched"))
stopifnot(identical(provenance$filter_version, 2L))
stopifnot(identical(provenance$site_id, "B001"))
stopifnot(grepl("joined_enriched", summarise_hev_provenance(provenance), fixed = TRUE))

history <- append_hev_download_history(
  empty_hev_download_history(),
  provenance,
  "PNG",
  downloaded_at = as.POSIXct("2026-08-06 12:05:00", tz = "UTC")
)
stopifnot(nrow(history) == 1L)
stopifnot(identical(history$format, "PNG"))
stopifnot(identical(history$source_dataset, "joined_enriched"))
stopifnot(identical(history$filter_version, 2L))

cat("test_hev_output_helpers.R: all checks passed\n")
