# hev_output_helpers.R
# WK8-06: keep HEV output provenance and download history explicit. These
# helpers describe dashboard state; they do not change HEV plotting methods.

empty_hev_download_history <- function() {
  data.frame(
    downloaded_at = character(),
    format = character(),
    site_id = character(),
    biology_metrics = character(),
    flow_metrics = character(),
    date_range = character(),
    source_dataset = character(),
    source_fingerprint = character(),
    filter_version = integer(),
    stringsAsFactors = FALSE
  )
}

normalise_hev_metric_selection <- function(metric) {
  metric <- trimws(as.character(metric))
  metric <- metric[!is.na(metric) & nzchar(metric)]
  unique(metric)
}

resolve_hev_biology_metrics <- function(data, selected_metric, show_all = FALSE) {
  all_metrics <- c("WHPT_ASPT_OE", "WHPT_NTAXA_OE", "LIFE_F_OE", "PSI_OE")
  requested <- if (isTRUE(show_all)) all_metrics else selected_metric
  requested <- normalise_hev_metric_selection(requested)
  requested[requested %in% names(data)]
}

resolve_hev_flow_metrics <- function(data, selected_metric, show_high_low = FALSE) {
  selected <- normalise_hev_metric_selection(selected_metric)
  if (!isTRUE(show_high_low) || length(selected) != 1L) {
    return(selected[selected %in% names(data)])
  }

  high_low <- if (stringr::str_detect(selected, "z$")) c("Q95z", "Q10z") else c("Q95", "Q10")
  if (all(high_low %in% names(data))) {
    return(high_low)
  }
  selected[selected %in% names(data)]
}

build_hev_output_provenance <- function(analysis_context,
                                        plot_data,
                                        site_id,
                                        date_range,
                                        biology_metrics,
                                        flow_metrics,
                                        show_all_metrics = FALSE,
                                        show_high_low = FALSE,
                                        show_status = FALSE,
                                        generated_at = Sys.time()) {
  list(
    source_dataset = analysis_context$source_dataset,
    source_fingerprint = analysis_context$source_fingerprint,
    filter_version = analysis_context$filter_version,
    analysis_rows = analysis_context$analysis_rows,
    hev_rows = if (is.null(plot_data)) 0L else nrow(plot_data),
    site_id = as.character(site_id),
    date_range = paste(as.character(date_range), collapse = "-"),
    biology_metrics = biology_metrics,
    flow_metrics = flow_metrics,
    show_all_metrics = isTRUE(show_all_metrics),
    show_high_low = isTRUE(show_high_low),
    show_status = isTRUE(show_status),
    generated_at = format(generated_at, "%Y-%m-%d %H:%M:%S")
  )
}

summarise_hev_provenance <- function(provenance) {
  if (is.null(provenance)) {
    return("No current HEV provenance is available.")
  }
  sprintf(
    "Current HEV source: %s; filter version: %s; site: %s; biology: %s; flow: %s; date range: %s.",
    provenance$source_dataset,
    provenance$filter_version,
    provenance$site_id,
    paste(provenance$biology_metrics, collapse = ", "),
    paste(provenance$flow_metrics, collapse = ", "),
    provenance$date_range
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
