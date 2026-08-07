# duplicate_choice_helpers.R
# WK8-16: detect same-site same-day/month-year biology duplicate groups and apply only
# explicit user choices. These helpers never auto-delete or aggregate records.

DUPLICATE_CHOICE_LOG_COLUMNS <- c(
  "record_id", "duplicate_group_id", "duplicate_period", "site_id", "sample_id", "date",
  "action", "reason", "user_comment"
)

duplicate_record_ids <- function(data) {
  if ("record_id" %in% names(data)) {
    return(as.character(data$record_id))
  }
  if ("sample_id" %in% names(data)) {
    return(as.character(data$sample_id))
  }
  stop("Biology data must contain record_id or sample_id for duplicate choice tracking.", call. = FALSE)
}

duplicate_sample_ids <- function(data) {
  if ("sample_id" %in% names(data)) {
    return(as.character(data$sample_id))
  }
  duplicate_record_ids(data)
}

empty_duplicate_detection <- function(status, messages) {
  list(
    status = status,
    messages = messages,
    groups = data.frame(),
    records = data.frame(),
    needs_choice = FALSE
  )
}

empty_duplicate_groups_table <- function() {
  data.frame(
    duplicate_group_id = character(),
    duplicate_period = character(),
    site_id = character(),
    date = character(),
    month_year = character(),
    record_count = integer(),
    stringsAsFactors = FALSE
  )
}

empty_duplicate_records_table <- function() {
  data.frame(
    duplicate_group_id = character(),
    duplicate_period = character(),
    record_id = character(),
    site_id = character(),
    sample_id = character(),
    date = character(),
    row_number = integer(),
    stringsAsFactors = FALSE
  )
}

empty_duplicate_choice_log <- function() {
  out <- data.frame(
    matrix(character(0), nrow = 0, ncol = length(DUPLICATE_CHOICE_LOG_COLUMNS)),
    stringsAsFactors = FALSE
  )
  names(out) <- DUPLICATE_CHOICE_LOG_COLUMNS
  out
}

new_duplicate_choice_result <- function(message = "No biology duplicate choices have been applied.") {
  list(
    status = "info",
    messages = message,
    kept = NULL,
    excluded = NULL,
    log = empty_duplicate_choice_log()
  )
}

detect_biology_duplicates <- function(data,
                                      site_col = "biol_site_id",
                                      date_col = "date",
                                      periods = c("same_day", "same_month_year")) {
  if (is.null(data) || nrow(data) == 0) {
    return(empty_duplicate_detection("info", "No biology records are available for duplicate checking."))
  }

  missing <- setdiff(c(site_col, date_col), names(data))
  if (length(missing) > 0) {
    return(empty_duplicate_detection(
      "error",
      paste0("Duplicate check is missing required column(s): ", paste(missing, collapse = ", "), ".")
    ))
  }

  sites <- trimws(as.character(data[[site_col]]))
  dates <- as.Date(data[[date_col]])
  record_ids <- duplicate_record_ids(data)
  sample_ids <- duplicate_sample_ids(data)
  periods <- intersect(periods, c("same_day", "same_month_year"))
  if (length(periods) == 0L) {
    periods <- "same_day"
  }

  records_list <- list()
  groups_list <- list()
  group_count <- 0L

  for (period in periods) {
    period_key <- if (identical(period, "same_day")) {
      as.character(dates)
    } else {
      ifelse(is.na(dates), NA_character_, format(dates, "%Y-%m"))
    }
    valid_key <- !is.na(sites) & nzchar(sites) & !is.na(period_key)
    key <- paste(sites, period_key, sep = "||")
    key[!valid_key] <- NA_character_
    duplicated_key <- !is.na(key) & (duplicated(key) | duplicated(key, fromLast = TRUE))

    if (!any(duplicated_key)) {
      next
    }

    duplicate_keys <- unique(key[duplicated_key])
    group_ids <- paste0(
      if (identical(period, "same_day")) "DUPD" else "DUPM",
      sprintf("%03d", seq_len(length(duplicate_keys)) + group_count)
    )
    group_count <- group_count + length(duplicate_keys)
    group_lookup <- stats::setNames(group_ids, duplicate_keys)
    group_id_by_row <- unname(group_lookup[key[duplicated_key]])

    records <- data.frame(
      duplicate_group_id = group_id_by_row,
      duplicate_period = period,
      record_id = record_ids[duplicated_key],
      site_id = sites[duplicated_key],
      sample_id = sample_ids[duplicated_key],
      date = as.character(dates[duplicated_key]),
      row_number = which(duplicated_key),
      stringsAsFactors = FALSE
    )
    groups <- stats::aggregate(
      record_id ~ duplicate_group_id + duplicate_period + site_id,
      data = records,
      FUN = length
    )
    names(groups)[names(groups) == "record_id"] <- "record_count"
    if (identical(period, "same_day")) {
      group_dates <- stats::aggregate(date ~ duplicate_group_id, data = records, FUN = function(x) x[[1]])
      groups <- merge(groups, group_dates, by = "duplicate_group_id", all.x = TRUE)
      groups$month_year <- NA_character_
    } else {
      month_year <- stats::aggregate(date ~ duplicate_group_id, data = records, FUN = function(x) format(as.Date(x[[1]]), "%Y-%m"))
      names(month_year)[names(month_year) == "date"] <- "month_year"
      groups <- merge(groups, month_year, by = "duplicate_group_id", all.x = TRUE)
      groups$date <- NA_character_
    }

    records_list[[length(records_list) + 1L]] <- records
    groups_list[[length(groups_list) + 1L]] <- groups
  }

  if (length(records_list) == 0L) {
    return(empty_duplicate_detection(
      status = "success",
      messages = "No same-day or same-month biology duplicate samples were detected."
    ))
  }

  records <- do.call(rbind, records_list)
  groups <- do.call(rbind, groups_list)
  groups <- groups[, c("duplicate_group_id", "duplicate_period", "site_id", "date", "month_year", "record_count")]

  list(
    status = "blocked",
    messages = paste0(
      "Same-day or same-month biology duplicate samples were detected in ",
      nrow(groups),
      " group(s). Choose keep_all or keep_record for each group before final analysis."
    ),
    groups = groups,
    records = records,
    needs_choice = TRUE
  )
}

detect_same_day_duplicates <- function(data,
                                       site_col = "biol_site_id",
                                       date_col = "date") {
  detect_biology_duplicates(data, site_col = site_col, date_col = date_col, periods = "same_day")
}

normalise_duplicate_choices <- function(choices) {
  if (is.null(choices) || nrow(choices) == 0) {
    return(data.frame(
      duplicate_group_id = character(),
      choice = character(),
      selected_record_id = character(),
      user_comment = character(),
      stringsAsFactors = FALSE
    ))
  }

  required <- c("duplicate_group_id", "choice")
  missing <- setdiff(required, names(choices))
  if (length(missing) > 0) {
    stop(
      paste0("Duplicate choices are missing required column(s): ", paste(missing, collapse = ", "), "."),
      call. = FALSE
    )
  }

  out <- as.data.frame(choices, stringsAsFactors = FALSE)
  if (!"selected_record_id" %in% names(out)) {
    out$selected_record_id <- NA_character_
  }
  if (!"user_comment" %in% names(out)) {
    out$user_comment <- ""
  }
  out$duplicate_group_id <- trimws(as.character(out$duplicate_group_id))
  out$choice <- trimws(tolower(as.character(out$choice)))
  out$selected_record_id <- trimws(as.character(out$selected_record_id))
  out$selected_record_id[!nzchar(out$selected_record_id)] <- NA_character_
  out$user_comment <- as.character(out$user_comment)
  out
}

parse_duplicate_choice_csv_text <- function(text) {
  text <- paste(as.character(text), collapse = "\n")
  if (!nzchar(trimws(text))) {
    stop("Paste duplicate choices CSV before applying choices.", call. = FALSE)
  }
  choices <- tryCatch(
    data.table::fread(text = text, colClasses = "character", data.table = FALSE),
    error = function(error) NULL
  )
  if (is.null(choices) || nrow(choices) == 0L || ncol(choices) == 0L) {
    stop("Duplicate choices CSV could not be read. Check the header and rows.", call. = FALSE)
  }
  choices
}

build_keep_all_duplicate_choices <- function(duplicate_result,
                                             user_comment = "All duplicate records retained after review.") {
  if (is.null(duplicate_result$groups) || nrow(duplicate_result$groups) == 0L) {
    return(normalise_duplicate_choices(NULL))
  }
  data.frame(
    duplicate_group_id = duplicate_result$groups$duplicate_group_id,
    choice = "keep_all",
    selected_record_id = NA_character_,
    user_comment = user_comment,
    stringsAsFactors = FALSE
  )
}

apply_duplicate_choices <- function(data,
                                    choices,
                                    duplicate_result = detect_biology_duplicates(data)) {
  if (is.null(data) || nrow(data) == 0) {
    return(list(
      kept = data,
      excluded = data.frame(),
      log = empty_duplicate_choice_log(),
      status = "info",
      messages = "No biology records are available for duplicate choices."
    ))
  }

  if (!isTRUE(duplicate_result$needs_choice)) {
    return(list(
      kept = data,
      excluded = data.frame(),
      log = empty_duplicate_choice_log(),
      status = duplicate_result$status,
      messages = duplicate_result$messages
    ))
  }

  choices <- normalise_duplicate_choices(choices)
  valid_choices <- c("keep_all", "keep_record")
  invalid <- unique(choices$choice[!choices$choice %in% valid_choices])
  if (length(invalid) > 0) {
    stop(
      paste0("Unsupported duplicate choice(s): ", paste(invalid, collapse = ", "), "."),
      call. = FALSE
    )
  }

  required_groups <- unique(duplicate_result$groups$duplicate_group_id)
  missing_groups <- setdiff(required_groups, choices$duplicate_group_id)
  if (length(missing_groups) > 0) {
    return(list(
      kept = NULL,
      excluded = NULL,
      log = empty_duplicate_choice_log(),
      status = "blocked",
      messages = paste0(
        "Duplicate choices are missing for group(s): ",
        paste(missing_groups, collapse = ", "),
        "."
      )
    ))
  }

  records <- duplicate_result$records
  remove_ids <- character()
  log_rows <- list()
  record_ids <- duplicate_record_ids(data)

  for (group_id in required_groups) {
    group_records <- records[records$duplicate_group_id == group_id, , drop = FALSE]
    choice <- choices[choices$duplicate_group_id == group_id, , drop = FALSE][1, , drop = FALSE]

    if (identical(choice$choice, "keep_all")) {
      log_rows[[length(log_rows) + 1L]] <- data.frame(
        record_id = group_records$record_id,
        duplicate_group_id = group_id,
        duplicate_period = group_records$duplicate_period,
        site_id = group_records$site_id,
        sample_id = group_records$sample_id,
        date = group_records$date,
        action = "kept",
        reason = "Biology duplicate group explicitly kept by user.",
        user_comment = choice$user_comment,
        stringsAsFactors = FALSE
      )
      next
    }

    selected <- choice$selected_record_id
    if (is.na(selected) || !selected %in% group_records$record_id) {
      return(list(
        kept = NULL,
        excluded = NULL,
        log = empty_duplicate_choice_log(),
        status = "blocked",
        messages = paste0(
          "Choice keep_record for ",
          group_id,
          " must select one record_id from that duplicate group."
        )
      ))
    }

    group_remove_ids <- setdiff(group_records$record_id, selected)
    remove_ids <- c(remove_ids, group_remove_ids)
    log_rows[[length(log_rows) + 1L]] <- data.frame(
      record_id = group_records$record_id,
      duplicate_group_id = group_id,
      duplicate_period = group_records$duplicate_period,
      site_id = group_records$site_id,
      sample_id = group_records$sample_id,
      date = group_records$date,
      action = ifelse(group_records$record_id == selected, "kept", "excluded"),
      reason = paste0("Biology duplicate group explicitly resolved by keeping record ", selected, "."),
      user_comment = choice$user_comment,
      stringsAsFactors = FALSE
    )
  }

  keep <- !record_ids %in% remove_ids
  kept <- data[keep, , drop = FALSE]
  excluded <- data[!keep, , drop = FALSE]
  log <- if (length(log_rows) > 0) do.call(rbind, log_rows) else empty_duplicate_choice_log()
  names(log) <- DUPLICATE_CHOICE_LOG_COLUMNS

  list(
    kept = kept,
    excluded = excluded,
    log = log,
    status = "success",
    messages = paste0(
      "Duplicate choices applied. Kept ",
      nrow(kept),
      " of ",
      nrow(data),
      " biology record(s); excluded ",
      nrow(excluded),
      " by explicit user choice."
    )
  )
}

apply_duplicate_exclusions_to_selection <- function(selection,
                                                    duplicate_choice_result,
                                                    timestamp = NULL) {
  log <- duplicate_choice_result$log
  if (is.null(log) || nrow(log) == 0L || !"action" %in% names(log)) {
    return(selection)
  }

  excluded <- log[log$action == "excluded", , drop = FALSE]
  if (nrow(excluded) == 0L) {
    return(selection)
  }

  for (row_index in seq_len(nrow(excluded))) {
    selection <- exclude_record(
      selection,
      record_id = excluded$record_id[[row_index]],
      site_id = excluded$site_id[[row_index]],
      sample_id = excluded$sample_id[[row_index]],
      reason = excluded$reason[[row_index]],
      trigger = "duplicate_choice",
      user_comment = excluded$user_comment[[row_index]],
      timestamp = timestamp
    )
  }
  selection
}
