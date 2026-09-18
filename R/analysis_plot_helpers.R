# Stage 4 uses the fields present in the current join, including non-zero lags.
analysis_plot_fields <- function(data) {
  numeric_fields <- names(data)[vapply(data, is.numeric, logical(1))]
  biology <- intersect(
    c("LIFE_F_OE", "WHPT_ASPT_OE", "WHPT_NTAXA_OE", "PSI_OE"),
    numeric_fields
  )
  flow <- character()
  for (lag in SUPPORTED_FLOW_LAGS) {
    present <- intersect(paste0(c("Q95z", "Q10z"), "_lag", lag), numeric_fields)
    if (length(present) > length(flow)) {
      flow <- present
    }
    if (length(flow) == 2L) {
      break
    }
  }
  list(biology = biology, flow = flow)
}

analysis_correlation_spec <- function(data) {
  fields <- analysis_plot_fields(data)
  candidates <- c(fields$biology, fields$flow)
  usable <- candidates[vapply(candidates, function(column) {
    values <- data[[column]]
    length(unique(values[is.finite(values)])) >= 2L
  }, logical(1))]
  columns <- c(head(intersect(fields$biology, usable), 2L), intersect(fields$flow, usable))
  list(
    columns = columns,
    message = if (length(columns) < 2L) {
      paste(
        "Pairwise Correlations needs at least two numeric biology or Flow variables",
        "with two distinct finite values. Include more samples or rebuild the Stage 3 dataset."
      )
    } else NULL
  )
}

analysis_empty_pair_panel <- function(data, mapping, ...) {
  ggplot2::ggplot() +
    ggplot2::annotate("text", x = 0.5, y = 0.5,
      label = "Insufficient\npaired values", size = 3) +
    ggplot2::xlim(0, 1) + ggplot2::ylim(0, 1) + ggplot2::theme_void()
}

analysis_correlation_panel <- function(data, mapping, ...) {
  x <- rlang::eval_tidy(mapping$x, data)
  y <- rlang::eval_tidy(mapping$y, data)
  paired <- is.finite(x) & is.finite(y)
  if (sum(paired) < 3L || length(unique(x[paired])) < 2L ||
      length(unique(y[paired])) < 2L) {
    return(analysis_empty_pair_panel(data, mapping))
  }
  GGally::ggally_cor(data[paired, , drop = FALSE], mapping, ...)
}

build_analysis_correlation_plot <- function(data, columns) {
  plot_data <- data[, columns, drop = FALSE]
  plot_data[] <- lapply(plot_data, function(values) {
    values[!is.finite(values)] <- NA_real_
    values
  })
  GGally::ggpairs(
    plot_data,
    upper = list(continuous = analysis_correlation_panel, na = analysis_empty_pair_panel),
    diag = list(continuous = GGally::wrap("densityDiag", na.rm = TRUE)),
    lower = list(continuous = GGally::wrap("points", na.rm = TRUE), na = analysis_empty_pair_panel),
    progress = FALSE
  ) + ggplot2::theme(text = ggplot2::element_text(size = 12))
}

build_analysis_coverage_data <- function(biology, flow_stats, mapping, settings) {
  # add_biol already preserves the full Flow history. Synthetic biology rows
  # introduce missing dates and are unnecessary for this join.
  result <- hetoolkit::join_he(
    biol_data = biology, flow_stats = flow_stats, mapping = mapping,
    lags = settings$lags, method = settings$method, join_type = "add_biol"
  )
  # Match the ID created by prepare_analysis_filter_data(), preserving history
  # rows with no biological sample. Those rows must not enter the filter helper.
  if (!"record_id" %in% names(result) && "sample_id" %in% names(result)) {
    result$record_id <- trimws(as.character(result$sample_id))
  }
  result
}

analysis_coverage_spec <- function(data, biology_metric) {
  fields <- analysis_plot_fields(data)
  message <- NULL
  if (length(fields$flow) != 2L || length(biology_metric) != 1L ||
      !biology_metric %in% names(data)) {
    message <- paste(
      "Historical Coverage needs a biology O:E metric and both Q95z and Q10z",
      "for the same lag. Rebuild the Stage 3 dataset with these fields."
    )
  } else {
    finite_flow <- is.finite(data[[fields$flow[[1L]]]]) &
      is.finite(data[[fields$flow[[2L]]]])
    # plot_rngflows counts the full-history and sampled layers together.
    plot_points <- sum(finite_flow) + sum(finite_flow & !is.na(data[[biology_metric]]))
    if (plot_points < 5L) {
      message <- paste(
        "Historical Coverage needs more complete Flow records.",
        "Use a longer Flow period or a lag with more complete data."
      )
    }
  }
  labels <- intersect(c("Year", "sampling_year"), names(data))
  list(flow = fields$flow, biology = biology_metric,
       label = if (length(labels)) labels[[1L]] else NULL, message = message)
}
