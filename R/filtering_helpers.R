# filtering_helpers.R
# -----------------------------------------------------------------------------
# Row-level filtering for local invertebrate (biology) data.
#
# Complements validate_local_invertebrate() in dashboard_backlog_helpers.R:
#   - validate_local_invertebrate() checks the FILE has the right columns.
#   - filter_records() checks each ROW and separates clean rows from bad rows.
#
# It never deletes bad rows silently. Excluded rows are returned with an
# `exclusion_reason` and `severity` column so the exclusion-log step can
# display and download them.
#
# Severity follows docs/week06/warning-error-rule-list.md:
#   Error   -> row removed from analysis (kept out).
#   Warning -> row kept, but flagged (e.g. small site, id converted to text).
#
# Thresholds that still need client/Di confirmation are function ARGUMENTS,
# so they are easy to change once confirmed:
#   min_records_per_site : sites with fewer rows than this get a Warning.
#   max_abundance        : abundance above this is treated as an Error outlier
#                          (NA = no upper cap).
# -----------------------------------------------------------------------------

filter_records <- function(data,
                           min_records_per_site = 1L,
                           max_abundance = NA_real_) {

  required <- c("biol_site_id", "date", "taxon", "abundance")

  # --- Guard: nothing to filter -------------------------------------------
  if (is.null(data) || nrow(data) == 0) {
    return(list(
      kept = NULL, excluded = NULL, log = NULL,
      status = "info",
      messages = "No invertebrate data provided to filter."
    ))
  }

  # --- Guard: required columns must exist (column-level check) -------------
  names_lower <- tolower(names(data))
  missing_columns <- setdiff(required, names_lower)
  if (length(missing_columns) > 0) {
    return(list(
      kept = NULL, excluded = NULL, log = NULL,
      status = "error",
      messages = paste0(
        "Invertebrate data is missing required column(s): ",
        paste(missing_columns, collapse = ", "), "."
      )
    ))
  }

  # --- Normalise -----------------------------------------------------------
  df <- data
  names(df) <- names_lower
  df <- df[, required, drop = FALSE]

  # Site IDs / taxon should be text (rule doc, section A). Track if we convert.
  id_was_numeric <- is.numeric(df$biol_site_id)
  df$biol_site_id <- trimws(as.character(df$biol_site_id))
  df$taxon        <- trimws(as.character(df$taxon))
  df$date         <- trimws(as.character(df$date))
  abundance_num   <- suppressWarnings(as.numeric(df$abundance))
  parsed_date     <- as.Date(df$date, format = "%Y-%m-%d")

  n <- nrow(df)
  reason    <- rep(NA_character_, n)
  severity  <- rep(NA_character_, n)
  offending <- rep(NA_character_, n)   # the actual value that triggered the rule

  flag <- function(cond, sev, msg, value = NULL) {
    # only flag rows not already flagged, so the FIRST reason wins
    idx <- which(cond & is.na(reason))
    if (length(idx) > 0) {
      reason[idx]   <<- msg
      severity[idx] <<- sev
      if (!is.null(value)) offending[idx] <<- as.character(value[idx])
    }
  }

  # --- Row-level ERROR rules (row will be excluded) ------------------------
  flag(!nzchar(df$biol_site_id) | is.na(df$biol_site_id), "Error", "Missing biol_site_id", df$biol_site_id)
  flag(!nzchar(df$taxon)        | is.na(df$taxon),        "Error", "Missing taxon", df$taxon)
  flag(!nzchar(df$date) | is.na(parsed_date),             "Error", "Missing or invalid date (expected YYYY-MM-DD)", df$date)
  flag(is.na(abundance_num),                              "Error", "Abundance is missing or not a number", df$abundance)
  flag(!is.na(abundance_num) & abundance_num < 0,         "Error", "Abundance is negative", abundance_num)
  if (!is.na(max_abundance)) {
    flag(!is.na(abundance_num) & abundance_num > max_abundance,
         "Error", paste0("Abundance exceeds allowed maximum (", max_abundance, ")"), abundance_num)
  }

  is_error <- !is.na(severity) & severity == "Error"

  # --- Duplicate rows -> Warning, keep first occurrence --------------------
  dup <- duplicated(df) & !is_error
  flag(dup, "Warning", "Duplicate row (only the first copy is kept)", df$biol_site_id)

  # --- Small-site rule -> Warning (row kept) -------------------------------
  # count valid (non-error, non-dup) rows per site
  valid_for_count <- !is_error & !dup
  site_counts <- table(df$biol_site_id[valid_for_count])
  small_sites <- names(site_counts)[site_counts < min_records_per_site]
  if (length(small_sites) > 0) {
    flag(valid_for_count & df$biol_site_id %in% small_sites,
         "Warning",
         paste0("Site has fewer than ", min_records_per_site, " records"),
         df$biol_site_id)
  }

  # --- Split kept vs excluded ---------------------------------------------
  remove_row <- is_error | dup            # rows that leave the analysis
  kept_idx   <- which(!remove_row)
  excl_idx   <- which(remove_row)

  kept <- data[kept_idx, , drop = FALSE]

  excluded <- NULL
  if (length(excl_idx) > 0) {
    excluded <- data[excl_idx, , drop = FALSE]
    excluded$excluded_value   <- offending[excl_idx]
    excluded$exclusion_reason <- reason[excl_idx]
    excluded$severity         <- severity[excl_idx]
  }

  # --- Warnings that did NOT remove the row (kept but flagged) --------------
  kept_warn_idx <- which(!remove_row & !is.na(severity))
  log <- NULL
  if (length(kept_warn_idx) > 0) {
    log <- data.frame(
      row_number = kept_warn_idx,
      biol_site_id = df$biol_site_id[kept_warn_idx],
      date = df$date[kept_warn_idx],
      excluded_value = offending[kept_warn_idx],
      severity = severity[kept_warn_idx],
      reason = reason[kept_warn_idx],
      stringsAsFactors = FALSE
    )
  }

  # --- Summary status + message -------------------------------------------
  n_err  <- length(excl_idx)
  n_warn <- length(kept_warn_idx)
  status <- if (n_err > 0 || n_warn > 0) "warning" else "success"
  messages <- if (n_err == 0 && n_warn == 0) {
    "All records passed filtering."
  } else {
    paste0(
      "Filtering complete. Kept ", nrow(kept), " of ", n, " rows. ",
      "Excluded ", n_err, " row(s); flagged ", n_warn, " kept row(s) with warnings."
    )
  }

  # Note (not a per-row warning) if site IDs were auto-converted to text.
  if (id_was_numeric) {
    messages <- paste0(messages,
      " Note: biol_site_id was stored as a number and converted to text.")
  }

  list(
    kept = kept,
    excluded = excluded,   # feeds the exclusion-log table (Error + dropped rows)
    log = log,             # kept-but-flagged rows (Warnings)
    status = status,
    messages = messages
  )
}
