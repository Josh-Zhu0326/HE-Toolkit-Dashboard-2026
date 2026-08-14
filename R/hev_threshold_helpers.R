# hev_threshold_helpers.R
# Client HEV threshold rules extracted from HelperFunction.R, lines 65-86.

HEV_RIVER_TYPES <- c("non_chalk", "chalk")

normalise_hev_river_type <- function(river_type) {
  if (is.null(river_type) || length(river_type) == 0L) {
    return("non_chalk")
  }
  river_type <- tolower(trimws(as.character(river_type)[[1L]]))
  river_type <- gsub("-", "_", river_type, fixed = TRUE)
  if (!river_type %in% HEV_RIVER_TYPES) {
    stop("HEV river type must be chalk or non_chalk.", call. = FALSE)
  }
  river_type
}

hev_whpt_status_bands <- function() {
  data.frame(
    metric = rep(c("WHPT_ASPT_OE", "WHPT_NTAXA_OE"), each = 5L),
    status = rep(c("High", "Good", "Moderate", "Poor", "Bad"), 2L),
    low_bound = c(0.97, 0.86, 0.72, 0.59, -Inf,
                  0.80, 0.68, 0.56, 0.47, -Inf),
    high_bound = c(Inf, 0.97, 0.86, 0.72, 0.59,
                   Inf, 0.80, 0.68, 0.56, 0.47),
    fill = rep(c("lightblue", "green", "yellow", "orange", "red"), 2L),
    stringsAsFactors = FALSE
  )
}

hev_life_psi_thresholds <- function(river_type = "non_chalk") {
  river_type <- normalise_hev_river_type(river_type)
  data.frame(
    metric = c("LIFE_F_OE", "PSI_OE"),
    threshold = c(if (identical(river_type, "chalk")) 1 else 0.94, 0.70),
    stringsAsFactors = FALSE
  )
}

hev_status_contract <- function(river_type = "non_chalk") {
  list(
    river_type = normalise_hev_river_type(river_type),
    whpt_bands = hev_whpt_status_bands(),
    thresholds = hev_life_psi_thresholds(river_type)
  )
}

transform_hev_status_value <- function(value, rangeratio, minadj) {
  value * rangeratio + minadj
}

add_hev_status_layers <- function(plot,
                                  metric,
                                  rangeratio,
                                  minadj,
                                  biol_min,
                                  biol_max,
                                  river_type = "non_chalk") {
  if (!inherits(plot, "ggplot")) {
    return(plot)
  }
  metric <- as.character(metric)[[1L]]
  if (is.na(metric) || !nzchar(metric)) {
    return(plot)
  }
  if (!is.finite(rangeratio) || identical(rangeratio, 0)) {
    return(plot)
  }
  if (!is.finite(minadj) || !is.finite(biol_min) || !is.finite(biol_max)) {
    return(plot)
  }
  if (biol_min >= biol_max) {
    return(plot)
  }

  whpt_bands <- hev_whpt_status_bands()
  metric_bands <- whpt_bands[whpt_bands$metric == metric, , drop = FALSE]
  if (nrow(metric_bands) > 0L) {
    metric_bands$low_clipped <- pmax(metric_bands$low_bound, biol_min)
    metric_bands$high_clipped <- pmin(metric_bands$high_bound, biol_max)
    metric_bands <- metric_bands[
      is.finite(metric_bands$low_clipped) &
        is.finite(metric_bands$high_clipped) &
        metric_bands$low_clipped < metric_bands$high_clipped,
      ,
      drop = FALSE
    ]
    if (nrow(metric_bands) > 0L) {
      metric_bands$ymin <- transform_hev_status_value(metric_bands$low_clipped, rangeratio, minadj)
      metric_bands$ymax <- transform_hev_status_value(metric_bands$high_clipped, rangeratio, minadj)
      plot <- plot +
        ggplot2::geom_rect(
          data = metric_bands,
          ggplot2::aes(xmin = -Inf, xmax = Inf, ymin = ymin, ymax = ymax, fill = fill),
          inherit.aes = FALSE,
          alpha = 0.12
        ) +
        ggplot2::scale_fill_identity()
    }
    return(plot)
  }

  thresholds <- hev_life_psi_thresholds(river_type)
  metric_threshold <- thresholds[thresholds$metric == metric, , drop = FALSE]
  if (nrow(metric_threshold) == 0L) {
    return(plot)
  }
  threshold <- metric_threshold$threshold[[1L]]
  if (!is.finite(threshold) || threshold < biol_min || threshold > biol_max) {
    return(plot)
  }

  plot +
    ggplot2::geom_hline(
      yintercept = transform_hev_status_value(threshold, rangeratio, minadj),
      linetype = "dashed",
      linewidth = 0.8,
      colour = "darkgreen",
      alpha = 0.5
    )
}
