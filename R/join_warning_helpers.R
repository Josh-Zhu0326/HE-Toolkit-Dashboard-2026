normalise_join_warning_dates <- function(values) {
  if (inherits(values, "Date")) {
    parsed <- values
  } else if (inherits(values, "POSIXt")) {
    parsed <- as.Date(values)
  } else if (is.numeric(values)) {
    parsed <- as.Date(values, origin = "1970-01-01")
  } else {
    parsed <- suppressWarnings(as.Date(
      trimws(as.character(values)),
      format = "%Y-%m-%d"
    ))
  }

  invalid <- is.na(parsed) | !is.finite(as.numeric(parsed))
  parsed[invalid] <- as.Date(NA)
  parsed
}

earliest_available_date <- function(values) {
  values <- normalise_join_warning_dates(values)
  available <- values[!is.na(values)]
  if (length(available) == 0L) {
    return(as.Date(NA))
  }
  min(available)
}

biology_flow_start_diagnostics <- function(biology_data, flow_stats, mapping) {
  biology_starts <- biology_data %>%
    dplyr::transmute(
      biol_site_id = as.character(.data$biol_site_id),
      biol_start = normalise_join_warning_dates(.data$SAMPLE_DATE),
      missing_biol_start = is.na(.data$biol_start)
    ) %>%
    dplyr::group_by(.data$biol_site_id) %>%
    dplyr::summarise(
      biol_start = earliest_available_date(.data$biol_start),
      missing_biol_start = any(.data$missing_biol_start),
      .groups = "drop"
    )

  flow_starts <- flow_stats %>%
    dplyr::transmute(
      flow_site_id = as.character(.data$flow_site_id),
      flow_start = normalise_join_warning_dates(.data$start_date),
      missing_flow_start = is.na(.data$flow_start)
    ) %>%
    dplyr::group_by(.data$flow_site_id) %>%
    dplyr::summarise(
      flow_start = earliest_available_date(.data$flow_start),
      missing_flow_start = any(.data$missing_flow_start),
      flow_window_count = dplyr::n(),
      .groups = "drop"
    )

  mapped_starts <- biology_starts %>%
    dplyr::left_join(
      mapping %>%
        dplyr::transmute(
          biol_site_id = as.character(.data$biol_site_id),
          flow_site_id = as.character(.data$flow_site_id)
        ),
      by = "biol_site_id"
    ) %>%
    dplyr::left_join(flow_starts, by = "flow_site_id")

  missing_mapping <- is.na(mapped_starts$flow_site_id) |
    !nzchar(trimws(mapped_starts$flow_site_id))
  missing_flow_windows <- !missing_mapping & is.na(mapped_starts$flow_window_count)
  missing_flow_start <- !missing_mapping &
    !missing_flow_windows &
    mapped_starts$missing_flow_start %in% TRUE
  precedes_flow <- !is.na(mapped_starts$biol_start) &
    !is.na(mapped_starts$flow_start) &
    mapped_starts$biol_start < mapped_starts$flow_start

  list(
    preceding_sites = unique(mapped_starts$biol_site_id[precedes_flow]),
    missing_biology_date_sites = unique(
      mapped_starts$biol_site_id[mapped_starts$missing_biol_start %in% TRUE]
    ),
    missing_flow_mapping_sites = unique(mapped_starts$biol_site_id[missing_mapping]),
    missing_flow_window_sites = unique(mapped_starts$biol_site_id[missing_flow_windows]),
    missing_flow_start_sites = unique(mapped_starts$biol_site_id[missing_flow_start])
  )
}

biology_flow_start_warning_messages <- function(diagnostics) {
  messages <- character()
  add_site_message <- function(sites, message) {
    sites <- sort(unique(sites[!is.na(sites) & nzchar(sites)]))
    if (length(sites) == 0L) {
      return(character())
    }
    paste0(message, paste(sites, collapse = ", "), ".")
  }

  messages <- c(
    messages,
    add_site_message(
      diagnostics$missing_biology_date_sites,
      "Biology sample dates are missing for site(s): "
    ),
    add_site_message(
      diagnostics$missing_flow_mapping_sites,
      "Biology-to-Flow mapping is missing for Biology site(s): "
    ),
    add_site_message(
      diagnostics$missing_flow_window_sites,
      "No Flow Statistics window is available for Biology site(s): "
    ),
    add_site_message(
      diagnostics$missing_flow_start_sites,
      "Flow Statistics window start dates are missing for Biology site(s): "
    ),
    add_site_message(
      diagnostics$preceding_sites,
      "Biology samples precede the earliest Flow Statistics window for site(s): "
    )
  )

  messages[nzchar(messages)]
}
