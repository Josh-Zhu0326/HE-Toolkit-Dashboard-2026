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
