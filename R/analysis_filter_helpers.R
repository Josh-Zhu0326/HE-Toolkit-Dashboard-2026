# analysis_filter_helpers.R
# WK8-07 / DEC-07: filtering at the analysis_dataset layer, plus restore.
#
# What this does (in plain terms):
# The user picks records to drop from the analysis. We keep those picks in a
# "filter selection" object, and we build the analysis_dataset by removing the
# currently-excluded records from a joined source. We never touch the joined
# source itself, and every exclude/restore is written to a log so the user can
# undo it. This follows the frozen artifact graph in workflow_state.R:
#   filter_selection -> exclusion_log
#   filter_selection + joined_core/joined_enriched -> analysis_dataset
#
# ASSUMPTIONS (please confirm with Di/Bo, easy to change here):
# - A record is identified by a single id column. Default is "SAMPLE_ID"
#   (present in the joined biology data). If it is missing we fall back to the
#   row number. Change `id_col` if the team picks another key.
# - We do not decide the sample-level duplicate rule here (that is WK8-16/Di).

# the columns of the exclusion log (DC-07 minimum record)
ANALYSIS_EXCLUSION_LOG_COLUMNS <- c(
  "record_id", "site_id", "sample_id",
  "exclusion_reason", "trigger", "user_comment", "timestamp", "current_status"
)

# an empty filter selection. `events` is an append-only log of exclude/restore.
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

# which record ids are currently excluded (last event per record is "exclude")
active_excluded_ids <- function(selection) {
  ev <- selection$events
  if (nrow(ev) == 0) return(character())
  last_action <- tapply(seq_len(nrow(ev)), ev$record_id,
                        function(idx) ev$action[idx[length(idx)]])
  names(last_action)[last_action == "exclude"]
}

# build the analysis_dataset by removing currently-excluded records.
# non-destructive: `joined` is never changed, we return a new data.frame plus
# a little provenance so the caller knows what happened.
apply_filter_selection <- function(joined, selection, id_col = "SAMPLE_ID") {
  if (is.null(joined) || nrow(joined) == 0) {
    return(list(analysis_dataset = joined, n_source = 0L, n_excluded = 0L,
                n_kept = 0L, id_col = id_col, filter_version = nrow(selection$events)))
  }

  # figure out the id for each row
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

# build the exclusion log (DC-07 schema) with a current status per event.
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
