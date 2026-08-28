wq_contract_empty_result <- function(status = "info", messages = character(0)) {
  list(data = data.frame(), status = status, messages = messages)
}

wq_contract_min_date <- function() {
  as.Date("2000-01-01")
}

wq_contract_det_registry <- function() {
  data.frame(
    det_id = c("0180", "0111"),
    summary_field = c("orthophosphate_mean", "ammonia_p90"),
    label = c("Orthophosphate mean", "Ammonia P90"),
    canonical_determinand = c(
      "Orthophosphate reactive as P",
      "Ammoniacal Nitrogen as N"
    ),
    canonical_unit = c("mg/L", "mg/L"),
    aggregation = c("mean", "p90"),
    stringsAsFactors = FALSE
  )
}

wq_normalise_det_id <- function(value) {
  value <- trimws(as.character(value))
  value[!nzchar(value)] <- NA_character_
  numeric_like <- grepl("^[0-9]+$", value)
  value[numeric_like] <- sprintf("%04d", as.integer(value[numeric_like]))
  value
}

wq_normalise_unit <- function(value) {
  source <- trimws(as.character(value))
  source[is.na(value) | !nzchar(source)] <- NA_character_
  normalised <- source
  mg_l <- toupper(source) %in% c("MG/L", "MG/LITRE", "MILLIGRAM PER LITRE")
  normalised[mg_l] <- "mg/L"
  normalised
}

wq_normalise_determinand_text <- function(value) {
  value <- tolower(trimws(as.character(value)))
  value[is.na(value) | !nzchar(value)] <- NA_character_
  value
}

wq_first_matching_column <- function(names_lower, candidates) {
  candidates <- tolower(candidates)
  match_index <- match(candidates, names_lower, nomatch = 0L)
  if (!any(match_index > 0L)) {
    return(NA_character_)
  }
  names(names_lower)[match_index[match_index > 0L][[1]]]
}

wq_apply_contract_column_aliases <- function(data) {
  names(data) <- trimws(names(data))
  names_lower <- stats::setNames(tolower(names(data)), names(data))
  aliases <- list(
    wq_site_id = c("wq_site_id", "sample.samplingpoint.notation", "samplingpoint.notation", "monitoring_site_id", "site_id"),
    date_time = c("date_time", "date", "sample.sampledatetime", "sample.sampledate", "sample_date", "sample_datetime"),
    det_id = c("det_id", "determinand.notation", "determinand_notation", "determinandid"),
    determinand = c("determinand", "det_label", "determinand.label", "determinand.preflabel", "determinand_definition"),
    result = c("result", "value", "measurement", "analysis_value"),
    unit = c("unit", "determinand.unit.label", "determinand_unit", "result_unit"),
    qualifier = c("qualifier", "resultqualifier.notation", "result_qualifier"),
    observation = c("observation", "notes", "codedresultinterpretation.interpretation")
  )

  for (target in names(aliases)) {
    if (target %in% names(data)) {
      next
    }
    source <- wq_first_matching_column(names_lower, aliases[[target]])
    if (!is.na(source) && !target %in% names(data)) {
      names(data)[names(data) == source] <- target
    }
  }

  data
}

normalise_wq_preview_records <- function(data) {
  if (is.null(data) || !is.data.frame(data)) {
    return(data)
  }

  data <- wq_apply_contract_column_aliases(data)
  if ("det_id" %in% names(data)) {
    data$det_id <- wq_normalise_det_id(data$det_id)
  }
  data
}

wq_is_below_detection <- function(qualifier) {
  qualifier <- trimws(as.character(qualifier))
  qualifier_lower <- tolower(qualifier)
  !is.na(qualifier) & qualifier_lower %in% c("<", "less than", "below detection limit")
}

wq_contract_provenance_text <- function(det_id, aggregation, record_count, below_detection_count, start, end) {
  paste0(
    "det_id ", det_id,
    "; aggregation=", aggregation,
    "; window=", format(start, "%Y-%m-%d"), " to ", format(end, "%Y-%m-%d"),
    "; included_records=", record_count,
    "; below_detection_transformed=", below_detection_count,
    "; unit=mg/L"
  )
}

standardise_wq_contract_records <- function(wq_data) {
  if (is.null(wq_data) || nrow(wq_data) == 0) {
    return(wq_contract_empty_result("info", "No WQ records are available."))
  }

  data <- as.data.frame(wq_data, stringsAsFactors = FALSE)
  data <- wq_apply_contract_column_aliases(data)
  required <- c("wq_site_id", "date_time", "det_id", "determinand", "result", "unit")
  missing <- setdiff(required, names(data))
  if (length(missing) > 0) {
    return(wq_contract_empty_result(
      "error",
      paste0("WQ contract input is missing required column(s): ", paste(missing, collapse = ", "), ".")
    ))
  }

  if (!"qualifier" %in% names(data)) {
    data$qualifier <- NA_character_
  }
  if (!"observation" %in% names(data)) {
    data$observation <- NA_character_
  }

  data$wq_site_id <- as.character(data$wq_site_id)
  data$det_id <- wq_normalise_det_id(data$det_id)
  data$date_time <- wq_rhs_parse_date(data$date_time)
  data$source_result <- suppressWarnings(as.numeric(data$result))
  data$source_unit <- as.character(data$unit)
  data$source_qualifier <- as.character(data$qualifier)
  data$canonical_unit <- wq_normalise_unit(data$unit)
  data$normalization_applied <- FALSE
  data$normalization_reason <- "none"
  data$analysis_value <- data$source_result

  below_detection <- wq_is_below_detection(data$source_qualifier) & !is.na(data$source_result)
  data$analysis_value[below_detection] <- data$source_result[below_detection] / 2
  data$normalization_applied[below_detection] <- TRUE
  data$normalization_reason[below_detection] <- "below_detection_limit_value_halved"

  registry <- wq_contract_det_registry()
  supported <- data$det_id %in% registry$det_id
  expected_determinand <- registry$canonical_determinand[match(data$det_id, registry$det_id)]
  determinand_conflict <- supported &
    (
      is.na(data$determinand) |
        wq_normalise_determinand_text(data$determinand) !=
          wq_normalise_determinand_text(expected_determinand)
    )
  unsupported_units <- supported & (is.na(data$canonical_unit) | data$canonical_unit != "mg/L")
  invalid_dates <- is.na(data$date_time)
  before_min_date <- !invalid_dates & data$date_time < wq_contract_min_date()
  invalid_values <- supported & is.na(data$analysis_value)

  messages <- character(0)
  status <- "success"
  if (any(!supported, na.rm = TRUE)) {
    messages <- c(messages, paste0(
      "Ignored unsupported WQ det_id value(s): ",
      paste(unique(stats::na.omit(data$det_id[!supported])), collapse = ", "),
      "."
    ))
    status <- "warning"
  }
  if (any(unsupported_units, na.rm = TRUE)) {
    messages <- c(messages, "Some supported WQ records used unsupported units and were excluded from summary calculations.")
    status <- "warning"
  }
  if (any(determinand_conflict, na.rm = TRUE)) {
    messages <- c(messages, "Some supported WQ det_id values had determinand text that did not match the contract registry and were excluded from summary calculations.")
    status <- "warning"
  }
  if (any(invalid_dates, na.rm = TRUE)) {
    messages <- c(messages, "Some WQ records had invalid dates and were excluded from summary calculations.")
    status <- "warning"
  }
  if (any(before_min_date, na.rm = TRUE)) {
    messages <- c(
      messages,
      sprintf(
        "%d WQ record(s) before 2000-01-01 were retained in the source data but excluded from the current summary.",
        sum(before_min_date, na.rm = TRUE)
      )
    )
    status <- "warning"
  }
  if (any(invalid_values, na.rm = TRUE)) {
    messages <- c(messages, "Some supported WQ records had missing or non-numeric results and were excluded from summary calculations.")
    status <- "warning"
  }
  if (any(below_detection, na.rm = TRUE)) {
    messages <- c(messages, "Below-detection WQ results were transformed to source_result / 2 for analysis_value while preserving the source result and qualifier.")
    if (identical(status, "success")) {
      status <- "warning"
    }
  }
  if (any(data$det_id == "0119", na.rm = TRUE)) {
    messages <- c(messages, "det_id 0119 is not treated as ammonia and was not included in ammonia_p90.")
    status <- "warning"
  }

  data$wq_before_min_date <- before_min_date
  data$wq_contract_usable <- supported & !unsupported_units & !determinand_conflict & !invalid_dates & !before_min_date & !invalid_values
  data$wq_contract_usable[is.na(data$wq_contract_usable)] <- FALSE
  if (length(messages) == 0) {
    messages <- "WQ records were standardised successfully for the v1 WQ contract."
  }

  list(data = data, status = status, messages = messages)
}

wq_get_sampling_year <- function(biology_data) {
  if ("sampling_year" %in% names(biology_data)) {
    return(suppressWarnings(as.integer(biology_data$sampling_year)))
  }
  if ("Year" %in% names(biology_data)) {
    return(suppressWarnings(as.integer(biology_data$Year)))
  }
  if ("date" %in% names(biology_data)) {
    return(suppressWarnings(as.integer(format(as.Date(biology_data$date), "%Y"))))
  }
  rep(NA_integer_, nrow(biology_data))
}

build_wq_contract_summary <- function(wq_data, biology_data) {
  if (is.null(biology_data) || nrow(biology_data) == 0) {
    return(wq_contract_empty_result("error", "Processed biology/O:E data are required before building WQ summaries."))
  }

  standardised <- standardise_wq_contract_records(wq_data)
  if (identical(standardised$status, "error")) {
    return(standardised)
  }

  wq_all <- standardised$data
  if (!"biol_site_id" %in% names(wq_all)) {
    return(wq_contract_empty_result(
      "error",
      "Mapped WQ records must contain biol_site_id before WQ summaries can be built."
    ))
  }

  wq <- wq_all[wq_all$wq_contract_usable, , drop = FALSE]
  biology <- as.data.frame(biology_data, stringsAsFactors = FALSE)
  if (!"biol_site_id" %in% names(biology)) {
    return(wq_contract_empty_result(
      "error",
      "Processed biology/O:E data must contain biol_site_id before WQ summaries can be built."
    ))
  }
  biology$sampling_year_contract <- wq_get_sampling_year(biology)
  if (!"sample_id" %in% names(biology) && "SAMPLE_ID" %in% names(biology)) {
    biology$sample_id <- biology$SAMPLE_ID
  }
  if (!"sample_id" %in% names(biology)) {
    biology$sample_id <- seq_len(nrow(biology))
  }
  if (!"date" %in% names(biology)) {
    biology$date <- as.Date(NA)
  }

  generated_at_utc <- format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  result_rows <- lapply(seq_len(nrow(biology)), function(i) {
    row <- biology[i, , drop = FALSE]
    year <- row$sampling_year_contract
    out <- data.frame(
      biol_site_id = as.character(row$biol_site_id),
      sample_id = as.character(row$sample_id),
      date = as.character(row$date),
      sampling_year = year,
      wq_window_start = as.Date(NA),
      wq_effective_window_start = as.Date(NA),
      wq_window_end = as.Date(NA),
      wq_window_duration_years = 3L,
      wq_excluded_before_2000_count = 0L,
      wq_summary_generated_at_utc = generated_at_utc,
      orthophosphate_mean = NA_real_,
      orthophosphate_record_count = 0L,
      orthophosphate_below_detection_count = 0L,
      orthophosphate_det_id = "0180",
      orthophosphate_aggregation = "mean",
      orthophosphate_unit = "mg/L",
      orthophosphate_provenance = NA_character_,
      ammonia_p90 = NA_real_,
      ammonia_record_count = 0L,
      ammonia_below_detection_count = 0L,
      ammonia_det_id = "0111",
      ammonia_aggregation = "p90",
      ammonia_unit = "mg/L",
      ammonia_provenance = NA_character_,
      dissolved_oxygen_p10 = NA_real_,
      dissolved_oxygen_record_count = NA_integer_,
      dissolved_oxygen_status = "not_ready_open_02",
      wq_summary_provenance = NA_character_,
      stringsAsFactors = FALSE
    )

    if (is.na(year)) {
      out$wq_summary_provenance <- "WQ summary not built for this biology record because sampling_year is missing or unparseable."
      return(out)
    }

    start <- as.Date(sprintf("%d-01-01", year - 2L))
    effective_start <- max(start, wq_contract_min_date())
    end <- as.Date(sprintf("%d-12-31", year))
    window <- wq[
      as.character(wq$biol_site_id) == as.character(row$biol_site_id) &
        wq$date_time >= effective_start &
        wq$date_time <= end,
      ,
      drop = FALSE
    ]
    out$wq_window_start <- start
    out$wq_effective_window_start <- effective_start
    out$wq_window_end <- end
    out$wq_excluded_before_2000_count <- sum(
      as.character(wq_all$biol_site_id) == as.character(row$biol_site_id) &
        !is.na(wq_all$date_time) &
        wq_all$date_time >= start &
        wq_all$date_time <= end &
        wq_all$date_time < wq_contract_min_date(),
      na.rm = TRUE
    )

    orth <- window$analysis_value[window$det_id == "0180"]
    amm <- window$analysis_value[window$det_id == "0111"]
    out$orthophosphate_record_count <- length(orth)
    out$ammonia_record_count <- length(amm)
    out$orthophosphate_below_detection_count <- sum(window$det_id == "0180" & window$normalization_reason == "below_detection_limit_value_halved", na.rm = TRUE)
    out$ammonia_below_detection_count <- sum(window$det_id == "0111" & window$normalization_reason == "below_detection_limit_value_halved", na.rm = TRUE)
    if (length(orth) > 0) {
      out$orthophosphate_mean <- mean(orth)
    }
    if (length(amm) > 0) {
      out$ammonia_p90 <- as.numeric(stats::quantile(amm, probs = 0.90, type = 7, names = FALSE))
    }
    out$orthophosphate_provenance <- wq_contract_provenance_text(
      "0180", "mean", out$orthophosphate_record_count, out$orthophosphate_below_detection_count, effective_start, end
    )
    out$ammonia_provenance <- wq_contract_provenance_text(
      "0111", "p90", out$ammonia_record_count, out$ammonia_below_detection_count, effective_start, end
    )
    out$wq_summary_provenance <- paste(
      "Biology-anchored three-calendar-year WQ summary.",
      paste0(
        "requested_window=", format(start, "%Y-%m-%d"), " to ", format(end, "%Y-%m-%d"),
        "; effective_window=", format(effective_start, "%Y-%m-%d"), " to ", format(end, "%Y-%m-%d"),
        "; excluded_before_2000=", out$wq_excluded_before_2000_count,
        "; generated_at_utc=", generated_at_utc, "."
      ),
      out$orthophosphate_provenance,
      out$ammonia_provenance,
      "Dissolved oxygen P10 remains not_ready_open_02 pending OPEN-02.",
      sep = " "
    )
    out
  })

  summary <- do.call(rbind, result_rows)
  status <- standardised$status
  messages <- standardised$messages
  if (nrow(summary) > 0 && all(summary$orthophosphate_record_count == 0 & summary$ammonia_record_count == 0)) {
    status <- "warning"
    messages <- c(messages, "No supported WQ records matched the biology-anchored three-calendar-year windows.")
  }
  if (nrow(summary) > 0 && any(summary$wq_window_start < wq_contract_min_date(), na.rm = TRUE)) {
    status <- "warning"
    messages <- c(
      messages,
      "At least one biology-anchored WQ window began before 2000-01-01; the effective window was limited to available data from 2000-01-01."
    )
  }

  list(data = summary, status = status, messages = messages)
}
