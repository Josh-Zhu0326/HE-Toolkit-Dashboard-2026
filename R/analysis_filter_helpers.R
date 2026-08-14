# analysis_filter_helpers.R
# This is for WK8-07. It lets the user drop records from the analysis and add
# them back later.
#
# How it works:
# The user's choices are saved in a "filter selection". To get the
# analysis_dataset, we take the joined data and remove the records that are
# currently dropped. We never change the joined data itself. Every drop and
# restore is written to a log so the user can undo it.
#
# Things I assumed (please tell me if they should change):
# - DC-11 supplies sample_id. The analysis boundary adds record_id so filtering
#   has one stable runtime identifier without renaming the source sample field.
# - Duplicate detection is handled outside this filtering helper. WK8-16 covers
#   same-site, same-day biology duplicates only.

# the columns the exclusion log should have
ANALYSIS_EXCLUSION_LOG_COLUMNS <- c(
  "record_id", "site_id", "sample_id",
  "exclusion_reason", "trigger", "user_comment", "timestamp", "current_status"
)

analysis_record_id_column <- function(data, preferred = NULL, allow_row_number = FALSE) {
  if (is.null(data) || nrow(data) == 0) {
    return(if (is.null(preferred)) "record_id" else preferred)
  }

  candidates <- unique(c(preferred, "record_id", "sample_id"))
  candidates <- candidates[!is.na(candidates) & nzchar(candidates)]
  match <- candidates[candidates %in% names(data)]
  if (length(match) > 0) {
    return(match[[1]])
  }
  NA_character_
}

prepare_analysis_filter_data <- function(data) {
  if (is.null(data) || !is.data.frame(data) || nrow(data) == 0L) {
    return(data)
  }

  if (!"sample_id" %in% names(data)) {
    stop("Analysis data must contain DC-11 sample_id before record filtering.", call. = FALSE)
  }
  data$sample_id <- trimws(as.character(data$sample_id))
  invalid_sample <- is.na(data$sample_id) | !nzchar(data$sample_id)
  if (any(invalid_sample)) {
    stop("Analysis sample_id values must not be missing or blank.", call. = FALSE)
  }

  if (!"record_id" %in% names(data)) {
    data$record_id <- data$sample_id
  } else {
    data$record_id <- trimws(as.character(data$record_id))
  }

  invalid <- is.na(data$record_id) | !nzchar(data$record_id)
  if (any(invalid)) {
    stop("Analysis record_id values must not be missing or blank.", call. = FALSE)
  }
  if (anyDuplicated(data$record_id)) {
    stop("Analysis record_id values must be unique before records can be excluded or restored.", call. = FALSE)
  }

  data
}

analysis_record_context <- function(data, record_id) {
  prepared <- prepare_analysis_filter_data(data)
  record_id <- trimws(as.character(record_id))
  index <- match(record_id, prepared$record_id)
  if (length(record_id) != 1L || is.na(index)) {
    stop("The selected record_id does not exist in the current analysis source.", call. = FALSE)
  }

  site_col <- intersect(c("biol_site_id", "site_id"), names(prepared))
  list(
    record_id = prepared$record_id[[index]],
    sample_id = prepared$sample_id[[index]],
    site_id = if (length(site_col) == 0L) NA_character_ else as.character(prepared[[site_col[[1L]]]][[index]])
  )
}

analysis_record_ids <- function(data, preferred = NULL) {
  data <- prepare_analysis_filter_data(data)
  as.character(data$record_id)
}

analysis_record_selector_spec <- function(data) {
  if (is.null(data) || !is.data.frame(data) || nrow(data) == 0L) {
    return(list(
      id_column = NA_character_,
      label = "Record identifier",
      choices = character(),
      placeholder = "Joined HE dataset required",
      hint = "Build or load a Joined HE dataset before selecting a record."
    ))
  }

  prepared <- tryCatch(
    prepare_analysis_filter_data(data),
    error = function(error) error
  )
  if (inherits(prepared, "error")) {
    return(list(
      id_column = NA_character_,
      label = "Record identifier",
      choices = character(),
      placeholder = "No record identifier available",
      hint = conditionMessage(prepared)
    ))
  }

  id_column <- "record_id"
  choices <- trimws(as.character(prepared$record_id))
  choices <- unique(choices[!is.na(choices) & nzchar(choices)])
  label <- "Record ID"

  list(
    id_column = id_column,
    label = label,
    choices = choices,
    placeholder = sprintf("Choose a %s", tolower(label)),
    hint = "Choose the identifier shown in the current Joined HE dataset."
  )
}

# start an empty filter selection. `events` just keeps a list of every
# exclude/restore the user did, in order.
new_filter_selection <- function() {
  list(events = data.frame(
    record_id = character(),
    site_id = character(),
    sample_id = character(),
    exclusion_reason = character(),
    trigger = character(),
    user_comment = character(),
    timestamp = character(),
    action = character(),          # "exclude" or "restore"
    stringsAsFactors = FALSE
  ))
}

# helper: the current time as text (can be overridden for tests)
.now <- function(timestamp = NULL) {
  if (is.null(timestamp)) format(Sys.time(), "%Y-%m-%d %H:%M:%S") else timestamp
}

# exclude one record. just appends an "exclude" event.
exclude_record <- function(selection, record_id,
                           site_id = NA_character_, sample_id = NA_character_,
                           reason = "User excluded record", trigger = "user",
                           user_comment = "", timestamp = NULL) {
  ev <- data.frame(
    record_id = as.character(record_id),
    site_id = as.character(site_id),
    sample_id = as.character(sample_id),
    exclusion_reason = as.character(reason),
    trigger = as.character(trigger),
    user_comment = as.character(user_comment),
    timestamp = .now(timestamp),
    action = "exclude",
    stringsAsFactors = FALSE
  )
  selection$events <- rbind(selection$events, ev)
  selection
}

# restore one record. appends a "restore" event, and carries the site_id /
# sample_id from the record's most recent exclude event so the log keeps its
# site and sample context instead of showing NA.
restore_record <- function(selection, record_id, user_comment = "", timestamp = NULL) {
  record_id <- as.character(record_id)

  past <- selection$events
  prior_excludes <- past[past$record_id == record_id & past$action == "exclude", , drop = FALSE]
  site_id   <- if (nrow(prior_excludes) > 0) prior_excludes$site_id[nrow(prior_excludes)] else NA_character_
  sample_id <- if (nrow(prior_excludes) > 0) prior_excludes$sample_id[nrow(prior_excludes)] else NA_character_

  ev <- data.frame(
    record_id = record_id,
    site_id = site_id,
    sample_id = sample_id,
    exclusion_reason = "User restored record",
    trigger = "user",
    user_comment = as.character(user_comment),
    timestamp = .now(timestamp),
    action = "restore",
    stringsAsFactors = FALSE
  )
  selection$events <- rbind(selection$events, ev)
  selection
}

# find which records are dropped right now. a record is dropped if its most
# recent action was "exclude".
active_excluded_ids <- function(selection) {
  ev <- selection$events
  if (nrow(ev) == 0) return(character())
  last_action <- tapply(seq_len(nrow(ev)), ev$record_id,
                        function(idx) ev$action[idx[length(idx)]])
  names(last_action)[last_action == "exclude"]
}

# make the analysis_dataset by removing the dropped records.
# this does NOT change `joined` - it returns a new table, plus some numbers
# so the caller knows what happened.
apply_filter_selection <- function(joined, selection, id_col = NULL) {
  if (is.null(joined) || nrow(joined) == 0) {
    id_col <- analysis_record_id_column(joined, preferred = id_col)
    return(list(analysis_dataset = joined, n_source = 0L, n_excluded = 0L,
                n_kept = 0L, id_col = id_col, filter_version = nrow(selection$events)))
  }

  prepared <- tryCatch(
    prepare_analysis_filter_data(joined),
    error = function(error) error
  )
  if (inherits(prepared, "error")) {
    return(list(
      analysis_dataset = NULL,
      n_source = nrow(joined),
      n_excluded = NA_integer_,
      n_kept = NA_integer_,
      id_col = NA_character_,
      filter_version = nrow(selection$events),
      status = "error",
      messages = conditionMessage(prepared)
    ))
  }
  id_col <- "record_id"
  ids <- prepared$record_id

  excluded <- active_excluded_ids(selection)
  keep <- !ids %in% excluded
  analysis <- joined[keep, , drop = FALSE]

  list(
    analysis_dataset = analysis,
    n_source = nrow(joined),
    n_excluded = sum(!keep),
    n_kept = sum(keep),
    id_col = id_col,
    filter_version = nrow(selection$events),   # how many filter actions so far
    status = "success",
    messages = "Analysis filter selection applied."
  )
}

# build the log table. it lists every exclude/restore and whether the record
# is dropped or restored right now.
build_analysis_exclusion_log <- function(selection) {
  ev <- selection$events
  empty <- data.frame(matrix(character(0), nrow = 0,
                             ncol = length(ANALYSIS_EXCLUSION_LOG_COLUMNS)),
                      stringsAsFactors = FALSE)
  names(empty) <- ANALYSIS_EXCLUSION_LOG_COLUMNS
  if (nrow(ev) == 0) return(empty)

  active <- active_excluded_ids(selection)
  data.frame(
    record_id = ev$record_id,
    site_id = ev$site_id,
    sample_id = ev$sample_id,
    exclusion_reason = ev$exclusion_reason,
    trigger = ev$trigger,
    user_comment = ev$user_comment,
    timestamp = ev$timestamp,
    current_status = ifelse(ev$record_id %in% active, "excluded", "restored"),
    stringsAsFactors = FALSE
  )
}
