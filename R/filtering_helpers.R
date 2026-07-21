# filtering_helpers.R
# This file checks each row of the local invertebrate data and splits it into
# good rows (kept) and bad rows (excluded).
# validate_local_invertebrate() in dashboard_backlog_helpers.R only checks the
# file has the right columns. This goes further and checks the actual rows.
# Bad rows are not deleted quietly, they come back with a reason and a severity
# so the exclusion log can show them.
# Error means the row is removed. Warning means the row is kept but flagged.
# min_records_per_site and max_abundance are arguments so we can change the
# thresholds later once Di confirms them.

filter_records <- function(data,
                           min_records_per_site = 1L,
                           max_abundance = NA_real_) {

  required <- c("biol_site_id", "date", "taxon", "abundance")

  # if there is no data, just return empty and stop here
  if (is.null(data) || nrow(data) == 0) {
    return(list(
      kept = NULL, excluded = NULL, log = NULL,
      status = "info",
      messages = "No invertebrate data provided to filter."
    ))
  }

  # if a required column is missing we can't filter, so return an error
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

  # tidy up the columns before checking them
  df <- data
  names(df) <- names_lower
  df <- df[, required, drop = FALSE]

  # site id and taxon should be text. remember if we had to convert the id.
  id_was_numeric <- is.numeric(df$biol_site_id)
  df$biol_site_id <- trimws(as.character(df$biol_site_id))
  df$taxon        <- trimws(as.character(df$taxon))
  df$date         <- trimws(as.character(df$date))
  abundance_num   <- suppressWarnings(as.numeric(df$abundance))
  parsed_date     <- as.Date(df$date, format = "%Y-%m-%d")

  n <- nrow(df)
  reason    <- rep(NA_character_, n)
  severity  <- rep(NA_character_, n)
  offending <- rep(NA_character_, n)   # the value that caused the problem

  # small helper: mark the rows that match a rule.
  # it skips rows that already have a reason, so the first rule wins.
  flag <- function(cond, sev, msg, value = NULL) {
    idx <- which(cond & is.na(reason))
    if (length(idx) > 0) {
      reason[idx]   <<- msg
      severity[idx] <<- sev
      if (!is.null(value)) offending[idx] <<- as.character(value[idx])
    }
  }

  # error rules. these rows get removed.
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

  # duplicate rows are a warning. we keep the first copy and drop the rest.
  dup <- duplicated(df) & !is_error
  flag(dup, "Warning", "Duplicate row (only the first copy is kept)", df$biol_site_id)

  # small-site rule is a warning. the row stays but gets flagged.
  # count the good rows per site first.
  valid_for_count <- !is_error & !dup
  site_counts <- table(df$biol_site_id[valid_for_count])
  small_sites <- names(site_counts)[site_counts < min_records_per_site]
  if (length(small_sites) > 0) {
    flag(valid_for_count & df$biol_site_id %in% small_sites,
         "Warning",
         paste0("Site has fewer than ", min_records_per_site, " records"),
         df$biol_site_id)
  }

  # split into kept rows and excluded rows.
  remove_row <- is_error | dup            # these rows leave the analysis
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

  # rows we kept but still want to warn about (like small sites)
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

  # build the summary message
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

  # add a note if we had to turn the site id into text
  if (id_was_numeric) {
    messages <- paste0(messages,
      " Note: biol_site_id was stored as a number and converted to text.")
  }

  list(
    kept = kept,
    excluded = excluded,   # goes to the exclusion log (removed rows)
    log = log,             # kept rows that still got a warning
    status = status,
    messages = messages
  )
}
