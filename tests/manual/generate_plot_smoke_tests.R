local_lib <- file.path(Sys.getenv("LOCALAPPDATA"), "HE-Toolkit", "R-library")
if (dir.exists(local_lib)) {
  .libPaths(c(local_lib, .libPaths()))
}

source("global.R")

out_dir <- file.path("tests", "manual", "plot_smoke")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

save_plot <- function(name, plot, width = 11, height = 6) {
  path <- normalizePath(file.path(out_dir, paste0(name, ".png")), mustWork = FALSE)
  ggplot2::ggsave(path, plot = plot, width = width, height = height, dpi = 160)
  message(path)
}

set.seed(20260723)

site_ids <- sprintf("BIO_SITE_%02d_LONG_LABEL", 1:24)
dates <- seq.Date(as.Date("2022-01-01"), as.Date("2024-12-31"), by = "month")
wq_data <- expand.grid(
  biol_site_id = site_ids[1:12],
  sample_date = dates,
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
wq_data$result_value <- round(runif(nrow(wq_data), 0.02, 1.1), 3)
wq_data$det_id <- sample(c("0180", "0111"), nrow(wq_data), replace = TRUE)

wq_time <- build_wq_plot(
  wq_data,
  plot_type = "Time series",
  numeric_var = "result_value",
  date_col = "sample_date",
  group_col = "biol_site_id"
)$plot
save_plot("wq_preview_time_series_many_sites", wq_time, 12, 6)

wq_box <- build_wq_plot(
  wq_data,
  plot_type = "Boxplot by biological site ID",
  numeric_var = "result_value",
  group_col = "biol_site_id"
)$plot
save_plot("wq_preview_boxplot_long_site_ids", wq_box, 12, 6)

wq_mean <- build_wq_plot(
  wq_data,
  plot_type = "Mean bar plot by biological site ID",
  numeric_var = "result_value",
  group_col = "biol_site_id"
)$plot
save_plot("wq_preview_mean_bar_long_site_ids", wq_mean, 12, 6)

summary_data <- data.frame(
  biol_site_id = site_ids,
  orthophosphate_mean = round(runif(length(site_ids), 0.01, 0.7), 3),
  ammonia_p90 = round(runif(length(site_ids), 0.05, 1.3), 3),
  orthophosphate_record_count = sample(1:40, length(site_ids), replace = TRUE),
  ammonia_record_count = sample(1:40, length(site_ids), replace = TRUE),
  wq_window_start = as.Date("2022-01-01"),
  wq_window_end = as.Date("2024-12-31")
)
wq_contract <- build_wq_contract_summary_plot(summary_data)$plot
save_plot("wq_contract_summary_many_long_sites", wq_contract, 13, 7)

rhs_data <- data.frame(
  biol_site_id = rep(site_ids[1:18], each = 6),
  rhs_survey_id = sprintf("RHS_%03d", seq_len(108)),
  hqa_score = round(rnorm(108, 55, 12), 1),
  channel_type = sample(sprintf("Category_%02d_long_name", 1:18), 108, replace = TRUE),
  stringsAsFactors = FALSE
)

rhs_numeric <- build_rhs_plot(
  rhs_data,
  plot_type = "Numeric variable by biological site ID",
  variable = "hqa_score",
  group_col = "biol_site_id"
)$plot
save_plot("rhs_numeric_boxplot_long_site_ids", rhs_numeric, 12, 6)

rhs_category <- build_rhs_plot(
  rhs_data,
  plot_type = "Categorical count/bar plot",
  variable = "channel_type",
  group_col = "biol_site_id"
)$plot
save_plot("rhs_categorical_many_categories", rhs_category, 12, 6)

rhs_count <- build_rhs_plot(
  rhs_data,
  plot_type = "Record count by biological site ID",
  group_col = "biol_site_id"
)$plot
save_plot("rhs_record_count_long_site_ids", rhs_count, 12, 6)

env_data <- data.frame(
  biol_site_id = site_ids[1:18],
  ALTITUDE = rnorm(18, 80, 20),
  SLOPE = rnorm(18, 2, 0.5),
  WIDTH = rnorm(18, 6, 1.5),
  DEPTH = rnorm(18, 0.4, 0.1),
  ALKALINITY = rnorm(18, 120, 25),
  DISCHARGE = rnorm(18, 3, 1),
  TEMPERATURE = rnorm(18, 12, 2),
  group = rep(c("North", "South", "Central"), each = 6)
)
pca_labels <- plot_sitepca_dash(
  env_data,
  vars = c("ALTITUDE", "SLOPE", "WIDTH", "DEPTH", "ALKALINITY", "DISCHARGE", "TEMPERATURE"),
  label_by = "biol_site_id",
  colour_by = "group"
)
save_plot("env_pca_long_labels", pca_labels, 10, 7)

flow_data <- expand.grid(
  date = seq.Date(as.Date("2021-01-01"), as.Date("2024-12-31"), by = "month"),
  flow_site_id = sprintf("FLOW_SITE_%02d_LONG_LABEL", 1:36),
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
flow_data$flow <- round(rlnorm(nrow(flow_data), log(4), 0.6), 2)
heatmap_plot <- plot_heatmap_dash(
  data = flow_data,
  x = "date",
  y = "flow_site_id",
  fill = "flow",
  dual = FALSE,
  list_out = TRUE
)[[1]]
save_plot("flow_heatmap_many_sites", heatmap_plot, 12, 7)

model_data <- data.frame(
  Q95z_lag0 = rnorm(220),
  WHPT_ASPT_OE = rnorm(220, 0.75, 0.08)
)
model_result <- run_model(
  model_data,
  list(flow_var = "Q95z_lag0", ecology_var = "WHPT_ASPT_OE", model_type = "linear")
)
save_plot("basic_model_dense_points", model_result$plot, 9, 6)
