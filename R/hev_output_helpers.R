# hev_output_helpers.R
# WK8-06: keep HEV output provenance and download history explicit. These
# helpers describe dashboard state; they do not change HEV plotting methods.

HEV_FLOW_MODES <- c("daily_flow", "flow_statistics")
HEV_FLOW_STAT_METRICS <- c("Q10", "Q95")
HEV_BIOLOGY_METRICS <- c("WHPT_ASPT_OE", "WHPT_NTAXA_OE", "LIFE_F_OE", "PSI_OE")

empty_hev_download_history <- function() {
  data.frame(
    downloaded_at = character(),
    format = character(),
    site_id = character(),
    flow_mode = character(),
    biology_metrics = character(),
    flow_metrics = character(),
    date_range = character(),
    source_dataset = character(),
    source_fingerprint = character(),
    filter_version = integer(),
    stringsAsFactors = FALSE
  )
}

normalise_hev_flow_mode <- function(mode) {
  if (is.null(mode) || length(mode) == 0L) {
    return("flow_statistics")
  }
  mode <- as.character(mode)[[1L]]
  if (is.na(mode) || !nzchar(mode)) {
    return("flow_statistics")
  }
  if (!mode %in% HEV_FLOW_MODES) {
    stop("HEV Flow mode must be daily_flow or flow_statistics.", call. = FALSE)
  }
  mode
}

normalise_hev_metric_selection <- function(metric) {
  metric <- trimws(as.character(metric))
  metric <- metric[!is.na(metric) & nzchar(metric)]
  unique(metric)
}

resolve_hev_biology_metrics <- function(data, selected_metric, show_all = FALSE) {
  requested <- if (isTRUE(show_all)) HEV_BIOLOGY_METRICS else selected_metric
  requested <- normalise_hev_metric_selection(requested)
  requested[requested %in% names(data)]
}

resolve_hev_flow_metrics <- function(data, selected_metric, show_high_low = FALSE,
                                     flow_mode = "flow_statistics") {
  flow_mode <- normalise_hev_flow_mode(flow_mode)
  if (identical(flow_mode, "daily_flow")) {
    return(if ("flow" %in% names(data)) "flow" else character())
  }

  selected <- normalise_hev_metric_selection(selected_metric)
  if (!isTRUE(show_high_low) || length(selected) != 1L) {
    return(selected[selected %in% names(data)])
  }

  high_low <- rev(HEV_FLOW_STAT_METRICS)
  if (all(high_low %in% names(data))) {
    return(high_low)
  }
  selected[selected %in% names(data)]
}

build_hev_daily_flow_data <- function(biology_data, flow_data, mapping) {
  required_mapping <- c("biol_site_id", "flow_site_id")
  required_flow <- c("flow_site_id", "date", "flow")
  if (!all(required_mapping %in% names(mapping))) {
    missing <- setdiff(required_mapping, names(mapping))
    stop(
      paste0("HEV daily Flow mapping is missing column(s): ", paste(missing, collapse = ", "), "."),
      call. = FALSE
    )
  }
  if (!all(required_flow %in% names(flow_data))) {
    missing <- setdiff(required_flow, names(flow_data))
    stop(
      paste0("HEV daily Flow data is missing column(s): ", paste(missing, collapse = ", "), "."),
      call. = FALSE
    )
  }
  if (!"biol_site_id" %in% names(biology_data) || !"date" %in% names(biology_data)) {
    stop("HEV daily Flow mode requires biology data with biol_site_id and date.", call. = FALSE)
  }

  mapping <- unique(mapping[, required_mapping, drop = FALSE])
  mapping$biol_site_id <- as.character(mapping$biol_site_id)
  mapping$flow_site_id <- as.character(mapping$flow_site_id)

  flow_data <- flow_data[, required_flow, drop = FALSE]
  flow_data$flow_site_id <- as.character(flow_data$flow_site_id)
  flow_data$date <- as.Date(flow_data$date)
  flow_data$flow <- suppressWarnings(as.numeric(flow_data$flow))
  flow_data <- flow_data[!is.na(flow_data$date), , drop = FALSE]

  biology_data$date <- as.Date(biology_data$date)
  biology_data$biol_site_id <- as.character(biology_data$biol_site_id)
  biology_columns <- names(biology_data)[
    !duplicated(names(biology_data)) &
      names(biology_data) %in% setdiff(names(biology_data), c("Month", "Year", "Season"))
  ]
  biology_join <- biology_data[, biology_columns, drop = FALSE]

  daily <- dplyr::inner_join(mapping, flow_data, by = "flow_site_id")
  daily$Month <- as.integer(format(daily$date, "%m"))
  daily$Year <- as.integer(format(daily$date, "%Y"))
  daily$Season <- dplyr::case_when(
    daily$Month %in% 3:5 ~ "Spring",
    daily$Month %in% 6:8 ~ "Summer",
    daily$Month %in% 9:11 ~ "Autumn",
    TRUE ~ "Winter"
  )

  dplyr::left_join(
    daily,
    biology_join,
    by = c("biol_site_id", "date")
  )
}

build_hev_output_provenance <- function(analysis_context,
                                        plot_data,
                                        site_id,
                                        date_range,
                                        biology_metrics,
                                        flow_metrics,
                                        flow_mode = "flow_statistics",
                                        flow_source_revision = NA_integer_,
                                        show_all_metrics = FALSE,
                                        show_high_low = FALSE,
                                        show_status = FALSE,
                                        river_type = "non_chalk",
                                        generated_at = Sys.time()) {
  flow_mode <- normalise_hev_flow_mode(flow_mode)
  river_type <- if (exists("normalise_hev_river_type", mode = "function")) {
    normalise_hev_river_type(river_type)
  } else {
    as.character(river_type)[[1L]]
  }
  list(
    source_dataset = analysis_context$source_dataset,
    source_fingerprint = analysis_context$source_fingerprint,
    filter_version = analysis_context$filter_version,
    analysis_rows = analysis_context$analysis_rows,
    flow_mode = flow_mode,
    flow_source_revision = flow_source_revision,
    hev_rows = if (is.null(plot_data)) 0L else nrow(plot_data),
    site_id = as.character(site_id),
    date_range = paste(as.character(date_range), collapse = "-"),
    biology_metrics = biology_metrics,
    flow_metrics = flow_metrics,
    show_all_metrics = isTRUE(show_all_metrics),
    show_high_low = isTRUE(show_high_low),
    show_status = isTRUE(show_status),
    river_type = river_type,
    generated_at = format(generated_at, "%Y-%m-%d %H:%M:%S")
  )
}

summarise_hev_provenance <- function(provenance) {
  if (is.null(provenance)) {
    return("No current HEV provenance is available.")
  }
  status_note <- if (isTRUE(provenance$show_status)) {
    sprintf("; status boundaries: %s", provenance$river_type)
  } else {
    ""
  }
  sprintf(
    "Current HEV source: %s; Flow mode: %s; filter version: %s; site: %s; biology: %s; flow: %s; date range: %s%s.",
    provenance$source_dataset,
    normalise_hev_flow_mode(provenance$flow_mode),
    provenance$filter_version,
    provenance$site_id,
    paste(provenance$biology_metrics, collapse = ", "),
    paste(provenance$flow_metrics, collapse = ", "),
    provenance$date_range,
    status_note
  )
}

append_hev_download_history <- function(history, provenance, format, downloaded_at = Sys.time()) {
  if (is.null(history) || !is.data.frame(history)) {
    history <- empty_hev_download_history()
  }
  if (is.null(provenance)) {
    return(history)
  }

  rbind(
    history,
    data.frame(
      downloaded_at = format(downloaded_at, "%Y-%m-%d %H:%M:%S"),
      format = toupper(as.character(format)),
      site_id = as.character(provenance$site_id),
      flow_mode = normalise_hev_flow_mode(provenance$flow_mode),
      biology_metrics = paste(provenance$biology_metrics, collapse = ", "),
      flow_metrics = paste(provenance$flow_metrics, collapse = ", "),
      date_range = as.character(provenance$date_range),
      source_dataset = as.character(provenance$source_dataset),
      source_fingerprint = as.character(provenance$source_fingerprint),
      filter_version = as.integer(provenance$filter_version),
      stringsAsFactors = FALSE
    )
  )
}
