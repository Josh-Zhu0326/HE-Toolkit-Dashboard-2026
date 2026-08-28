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
  wq_site_id = sprintf("WQ_SITE_%02d_LONG_LABEL", 1:12),
  date_time = dates,
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
wq_data$result <- round(runif(nrow(wq_data), 0.02, 1.1), 3)
wq_data$det_id <- sample(c("0180", "0111"), nrow(wq_data), replace = TRUE)

wq_time <- build_wq_plot(
  wq_data,
  plot_type = "Time series"
)$plot
save_plot("wq_preview_time_series_many_sites", wq_time, 12, 6)

wq_box <- build_wq_plot(
  wq_data,
  plot_type = "Boxplot"
)$plot
save_plot("wq_preview_boxplot_long_site_ids", wq_box, 12, 6)

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
