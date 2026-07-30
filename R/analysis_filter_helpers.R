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
# - Each record is found by one id column. I used "SAMPLE_ID" (it's in the
#   joined data). If that column is missing, I use the row number instead.
# - I did not decide the same-day/same-month duplicate rule here. That one is
#   Di's task (WK8-16).

# the columns the exclusion log should have
ANALYSIS_EXCLUSION_LOG_COLUMNS <- c(
  "record_id", "site_id", "sample_id",
  "exclusion_reason", "trigger", "user_comment", "timestamp", "current_status"
)

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

# restore one record. just appends a "restore" event.
restore_record <- function(selection, record_id, user_comment = "", timestamp = NULL) {
  ev <- data.frame(
    record_id = as.character(record_id),
    site_id = NA_character_,
    sample_id = NA_character_,
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
apply_filter_selection <- function(joined, selection, id_col = "SAMPLE_ID") {
  if (is.null(joined) || nrow(joined) == 0) {
    return(list(analysis_dataset = joined, n_source = 0L, n_excluded = 0L,
                n_kept = 0L, id_col = id_col, filter_version = nrow(selection$events)))
  }

  # get the id for each row (use the row number if the id column isn't there)
  if (id_col %in% names(joined)) {
    ids <- as.character(joined[[id_col]])
  } else {
    id_col <- "row_number"
    ids <- as.character(seq_len(nrow(joined)))
  }

  excluded <- active_excluded_ids(selection)
  keep <- !ids %in% excluded
  analysis <- joined[keep, , drop = FALSE]

  list(
    analysis_dataset = analysis,
    n_source = nrow(joined),
    n_excluded = sum(!keep),
    n_kept = sum(keep),
    id_col = id_col,
    filter_version = nrow(selection$events)   # how many filter actions so far
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
