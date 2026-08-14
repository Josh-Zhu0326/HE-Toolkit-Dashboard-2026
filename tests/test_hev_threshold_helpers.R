# test_hev_threshold_helpers.R
# Expect: "test_hev_threshold_helpers.R: all checks passed"

source(file.path("R", "hev_threshold_helpers.R"))

bands <- hev_whpt_status_bands()
aspt <- bands[bands$metric == "WHPT_ASPT_OE", ]
ntaxa <- bands[bands$metric == "WHPT_NTAXA_OE", ]

stopifnot(identical(aspt$status, c("High", "Good", "Moderate", "Poor", "Bad")))
stopifnot(identical(aspt$low_bound, c(0.97, 0.86, 0.72, 0.59, -Inf)))
stopifnot(identical(aspt$high_bound, c(Inf, 0.97, 0.86, 0.72, 0.59)))

stopifnot(identical(ntaxa$status, c("High", "Good", "Moderate", "Poor", "Bad")))
stopifnot(identical(ntaxa$low_bound, c(0.80, 0.68, 0.56, 0.47, -Inf)))
stopifnot(identical(ntaxa$high_bound, c(Inf, 0.80, 0.68, 0.56, 0.47)))

non_chalk_thresholds <- hev_life_psi_thresholds("non-chalk")
chalk_thresholds <- hev_life_psi_thresholds("chalk")

stopifnot(identical(non_chalk_thresholds$threshold, c(0.94, 0.70)))
stopifnot(identical(chalk_thresholds$threshold, c(1.00, 0.70)))
stopifnot(identical(normalise_hev_river_type(NULL), "non_chalk"))
stopifnot(identical(normalise_hev_river_type("non-chalk"), "non_chalk"))
stopifnot(inherits(try(normalise_hev_river_type("limestone"), silent = TRUE), "try-error"))

base_plot <- ggplot2::ggplot(data.frame(x = 1, y = 1), ggplot2::aes(x, y)) +
  ggplot2::geom_point()
with_whpt_layers <- add_hev_status_layers(
  base_plot,
  metric = "WHPT_ASPT_OE",
  rangeratio = 10,
  minadj = 0,
  biol_min = 0.5,
  biol_max = 1.1
)
with_life_layer <- add_hev_status_layers(
  base_plot,
  metric = "LIFE_F_OE",
  rangeratio = 10,
  minadj = 0,
  biol_min = 0.5,
  biol_max = 1.1,
  river_type = "chalk"
)

stopifnot(inherits(with_whpt_layers, "ggplot"))
stopifnot(length(with_whpt_layers$layers) > length(base_plot$layers))
stopifnot(inherits(with_life_layer, "ggplot"))
stopifnot(length(with_life_layer$layers) > length(base_plot$layers))

cat("test_hev_threshold_helpers.R: all checks passed\n")
