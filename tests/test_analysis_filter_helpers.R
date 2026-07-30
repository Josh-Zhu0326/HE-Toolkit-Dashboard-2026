# test_analysis_filter_helpers.R
# Run in RStudio: open the project, then Source this file.
# Expect: "test_analysis_filter_helpers.R: all checks passed"

source(file.path("R", "analysis_filter_helpers.R"))

joined <- read.csv(file.path("tests", "fixtures", "analysis_dataset.csv"),
                   stringsAsFactors = FALSE, colClasses = c(SAMPLE_ID = "character"))

# --- 1. Empty selection keeps everything ------------------------------------
sel <- new_filter_selection()
r <- apply_filter_selection(joined, sel)
stopifnot(r$n_kept == nrow(joined))
stopifnot(r$n_excluded == 0)
stopifnot(nrow(build_analysis_exclusion_log(sel)) == 0)

# --- 2. Exclude one record -> it leaves the analysis, joined is untouched ----
sel <- exclude_record(sel, record_id = "S002", site_id = "291", sample_id = "S002",
                      reason = "User excluded record", timestamp = "2026-07-23 10:00:00")
r <- apply_filter_selection(joined, sel)
stopifnot(r$n_kept == nrow(joined) - 1)
stopifnot(!("S002" %in% r$analysis_dataset$SAMPLE_ID))
stopifnot(nrow(joined) == 5)                      # source never changed

log <- build_analysis_exclusion_log(sel)
stopifnot(nrow(log) == 1)
stopifnot(identical(names(log), ANALYSIS_EXCLUSION_LOG_COLUMNS))  # DC-07 schema
stopifnot(log$current_status == "excluded")

# --- 3. Restore the record -> it comes back, log shows restored --------------
sel <- restore_record(sel, record_id = "S002", timestamp = "2026-07-23 10:05:00")
r <- apply_filter_selection(joined, sel)
stopifnot(r$n_kept == nrow(joined))               # rebuilt analysis includes it again
stopifnot("S002" %in% r$analysis_dataset$SAMPLE_ID)

log <- build_analysis_exclusion_log(sel)
stopifnot(nrow(log) == 2)                          # exclude event + restore event
stopifnot(all(log$current_status == "restored"))  # record is currently restored

# --- 4. Re-excluding after restore works ------------------------------------
sel <- exclude_record(sel, record_id = "S002", timestamp = "2026-07-23 10:10:00")
r <- apply_filter_selection(joined, sel)
stopifnot(!("S002" %in% r$analysis_dataset$SAMPLE_ID))
stopifnot(tail(active_excluded_ids(sel), 1) == "S002")

# --- 5. Falls back to row number when the id column is missing ---------------
no_id <- joined[, setdiff(names(joined), "SAMPLE_ID")]
sel2 <- exclude_record(new_filter_selection(), record_id = "3")
r2 <- apply_filter_selection(no_id, sel2, id_col = "SAMPLE_ID")
stopifnot(r2$id_col == "row_number")
stopifnot(r2$n_kept == nrow(no_id) - 1)

cat("test_analysis_filter_helpers.R: all checks passed\n")
