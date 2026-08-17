# join_contract_helpers.R
# Shared contract for Stage 3 lag selection and derived joined-data fields.

supported_join_lags <- function() {
  c(0L, 1L, 3L, 6L, 12L)
}

normalise_join_settings <- function(lags, method) {
  lags <- sort(unique(as.integer(lags)))
  supported_lags <- supported_join_lags()

  if (length(lags) == 0L || anyNA(lags)) {
    stop(
      sprintf(
        "Select at least one supported lag (%s) before building the Joined HE Dataset.",
        paste(supported_lags, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  invalid_lags <- setdiff(lags, supported_lags)
  if (length(invalid_lags) > 0L) {
    stop(
      sprintf(
        "Supported Dashboard lags are %s.",
        paste(supported_lags, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  method <- as.character(method)[[1L]]
  if (is.na(method) || !identical(method, "A")) {
    stop("Core joined/model dataset generation must use join method A.", call. = FALSE)
  }

  list(lags = lags, method = method)
}

joined_flow_fields <- function(lags = supported_join_lags()) {
  unlist(lapply(c("Q10", "Q95"), function(metric) {
    unlist(lapply(lags, function(lag) {
      c(
        sprintf("%s_lag%d", metric, lag),
        sprintf("%sz_lag%d", metric, lag)
      )
    }), use.names = FALSE)
  }), use.names = FALSE)
}

joined_flow_window_fields <- function(lags = supported_join_lags()) {
  unlist(lapply(lags, function(lag) {
    sprintf(
      "flow_window_%s_lag%d",
      c("start", "end", "duration"),
      lag
    )
  }), use.names = FALSE)
}

joined_flow_lookup_key <- function(flow_site_id, win_no) {
  paste(as.character(flow_site_id), as.character(win_no), sep = "\034")
}

joined_flow_key_present <- function(values) {
  values <- trimws(as.character(values))
  !is.na(values) & nzchar(values)
}

normalise_joined_flow_contract <- function(joined_data, flow_stats, lags) {
  if (!is.data.frame(joined_data) || !is.data.frame(flow_stats)) {
    stop("Joined data and Flow Statistics must both be data frames.", call. = FALSE)
  }

  lags <- sort(unique(as.integer(lags)))
  invalid_lags <- setdiff(lags, supported_join_lags())
  if (length(lags) == 0L || anyNA(lags) || length(invalid_lags) > 0L) {
    stop("Joined Flow normalisation requires supported lag values.", call. = FALSE)
  }

  required_flow_stats <- c("flow_site_id", "win_no", "start_date", "end_date")
  missing_flow_stats <- setdiff(required_flow_stats, names(flow_stats))
  if (length(missing_flow_stats) > 0L) {
    stop(
      sprintf(
        "Flow Statistics are missing required window field(s): %s.",
        paste(missing_flow_stats, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  if (!"flow_site_id" %in% names(joined_data)) {
    stop("Joined data are missing flow_site_id.", call. = FALSE)
  }

  lookup_key <- joined_flow_lookup_key(flow_stats$flow_site_id, flow_stats$win_no)
  complete_lookup <- joined_flow_key_present(flow_stats$flow_site_id) &
    joined_flow_key_present(flow_stats$win_no)
  if (any(!complete_lookup)) {
    stop("Flow Statistics contain blank flow_site_id or win_no values.", call. = FALSE)
  }
  if (anyDuplicated(lookup_key)) {
    stop("Flow Statistics contain duplicate flow_site_id and win_no values.", call. = FALSE)
  }

  flow_start <- as.Date(flow_stats$start_date)
  flow_end <- as.Date(flow_stats$end_date)
  for (lag in lags) {
    win_field <- sprintf("win_no_lag%d", lag)
    if (!win_field %in% names(joined_data)) {
      stop(
        sprintf("Joined data are missing %s required for Flow-window provenance.", win_field),
        call. = FALSE
      )
    }

    row_key <- joined_flow_lookup_key(joined_data$flow_site_id, joined_data[[win_field]])
    index <- match(row_key, lookup_key)
    complete_row_key <- joined_flow_key_present(joined_data$flow_site_id) &
      joined_flow_key_present(joined_data[[win_field]])
    unmatched_rows <- which(complete_row_key & is.na(index))
    if (length(unmatched_rows) > 0L) {
      stop(
        sprintf(
          "%s contains Flow-window key(s) not present in Flow Statistics at row(s): %s.",
          win_field,
          paste(unmatched_rows, collapse = ", ")
        ),
        call. = FALSE
      )
    }
    start_field <- sprintf("flow_window_start_lag%d", lag)
    end_field <- sprintf("flow_window_end_lag%d", lag)
    duration_field <- sprintf("flow_window_duration_lag%d", lag)
    joined_data[[start_field]] <- flow_start[index]
    joined_data[[end_field]] <- flow_end[index]
    duration <- as.numeric(joined_data[[end_field]] - joined_data[[start_field]]) + 1
    duration[is.na(joined_data[[start_field]]) | is.na(joined_data[[end_field]])] <- NA_real_
    if (any(duration < 1, na.rm = TRUE)) {
      stop(sprintf("%s contains an end date before its start date.", win_field), call. = FALSE)
    }
    joined_data[[duration_field]] <- duration
  }

  selected_flow_fields <- joined_flow_fields(lags)
  missing_contract_fields <- setdiff(selected_flow_fields, names(joined_data))
  if (length(missing_contract_fields) > 0L) {
    stop(
      sprintf(
        "Joined data are missing required Flow contract field(s): %s.",
        paste(missing_contract_fields, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  all_lags <- supported_join_lags()
  contract_fields <- c(joined_flow_fields(all_lags), joined_flow_window_fields(all_lags))
  missing_flow_fields <- setdiff(joined_flow_fields(all_lags), names(joined_data))
  for (field in missing_flow_fields) {
    joined_data[[field]] <- rep(NA_real_, nrow(joined_data))
  }
  for (lag in setdiff(all_lags, lags)) {
    joined_data[[sprintf("flow_window_start_lag%d", lag)]] <- as.Date(rep(NA, nrow(joined_data)))
    joined_data[[sprintf("flow_window_end_lag%d", lag)]] <- as.Date(rep(NA, nrow(joined_data)))
    joined_data[[sprintf("flow_window_duration_lag%d", lag)]] <- rep(NA_real_, nrow(joined_data))
  }

  internal_fields <- sprintf("win_no_lag%d", all_lags)
  other_fields <- setdiff(names(joined_data), c(contract_fields, internal_fields))
  joined_data[, c(other_fields, contract_fields), drop = FALSE]
}
