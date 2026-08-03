# duplicate_choice_helpers.R
# WK8-16: detect same-site, same-day biology duplicate groups and apply only
# explicit user choices. These helpers never auto-delete or aggregate records.
# Same-month/year duplicate policy is outside this WK8-16 implementation.

DUPLICATE_CHOICE_LOG_COLUMNS <- c(
  "record_id", "duplicate_group_id", "site_id", "sample_id", "date",
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

detect_same_day_duplicates <- function(data,
                                       site_col = "biol_site_id",
                                       date_col = "date") {
  if (is.null(data) || nrow(data) == 0) {
    return(list(
      status = "info",
      messages = "No biology records are available for duplicate checking.",
      groups = data.frame(),
      records = data.frame(),
      needs_choice = FALSE
    ))
  }

  missing <- setdiff(c(site_col, date_col), names(data))
  if (length(missing) > 0) {
    return(list(
      status = "error",
      messages = paste0(
        "Duplicate check is missing required column(s): ",
        paste(missing, collapse = ", "), "."
      ),
      groups = data.frame(),
      records = data.frame(),
      needs_choice = FALSE
    ))
  }

  sites <- trimws(as.character(data[[site_col]]))
  dates <- as.Date(data[[date_col]])
  valid_key <- !is.na(sites) & nzchar(sites) & !is.na(dates)
  key <- paste(sites, dates, sep = "||")
  key[!valid_key] <- NA_character_
  duplicated_key <- !is.na(key) & (duplicated(key) | duplicated(key, fromLast = TRUE))

  if (!any(duplicated_key)) {
    return(list(
      status = "success",
      messages = "No same-day duplicate biology samples were detected.",
      groups = data.frame(),
      records = data.frame(),
      needs_choice = FALSE
    ))
  }

  duplicate_keys <- unique(key[duplicated_key])
  group_ids <- paste0("DUP", sprintf("%03d", seq_along(duplicate_keys)))
  group_lookup <- stats::setNames(group_ids, duplicate_keys)
  group_id_by_row <- unname(group_lookup[key[duplicated_key]])
  record_ids <- duplicate_record_ids(data)
  sample_ids <- duplicate_sample_ids(data)

  records <- data.frame(
    duplicate_group_id = group_id_by_row,
    record_id = record_ids[duplicated_key],
    site_id = sites[duplicated_key],
    sample_id = sample_ids[duplicated_key],
    date = as.character(dates[duplicated_key]),
    row_number = which(duplicated_key),
    stringsAsFactors = FALSE
  )
  groups <- stats::aggregate(
    record_id ~ duplicate_group_id + site_id + date,
    data = records,
    FUN = length
  )
  names(groups)[names(groups) == "record_id"] <- "record_count"

  list(
    status = "blocked",
    messages = paste0(
      "Same-day duplicate biology samples were detected in ",
      nrow(groups),
      " group(s). Choose keep_all or keep_record for each group before final analysis."
    ),
    groups = groups,
    records = records,
    needs_choice = TRUE
  )
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

apply_duplicate_choices <- function(data,
                                    choices,
                                    duplicate_result = detect_same_day_duplicates(data)) {
  if (is.null(data) || nrow(data) == 0) {
    return(list(
      kept = data,
      excluded = data.frame(),
      log = data.frame(),
      status = "info",
      messages = "No biology records are available for duplicate choices."
    ))
  }

  if (!isTRUE(duplicate_result$needs_choice)) {
    return(list(
      kept = data,
      excluded = data.frame(),
      log = data.frame(),
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
      log = data.frame(),
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
        site_id = group_records$site_id,
        sample_id = group_records$sample_id,
        date = group_records$date,
        action = "kept",
        reason = "Same-day duplicate group explicitly kept by user.",
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
        log = data.frame(),
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
      site_id = group_records$site_id,
      sample_id = group_records$sample_id,
      date = group_records$date,
      action = ifelse(group_records$record_id == selected, "kept", "excluded"),
      reason = paste0("Same-day duplicate group explicitly resolved by keeping record ", selected, "."),
      user_comment = choice$user_comment,
      stringsAsFactors = FALSE
    )
  }

  keep <- !record_ids %in% remove_ids
  kept <- data[keep, , drop = FALSE]
  excluded <- data[!keep, , drop = FALSE]
  log <- if (length(log_rows) > 0) {
    do.call(rbind, log_rows)
  } else {
    data.frame(matrix(character(0), ncol = length(DUPLICATE_CHOICE_LOG_COLUMNS)))
  }
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
