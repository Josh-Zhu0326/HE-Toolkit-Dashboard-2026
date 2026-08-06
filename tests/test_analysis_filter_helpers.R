# test_analysis_filter_helpers.R
# Run in RStudio: open the project, then Source this file.
# Expect: "test_analysis_filter_helpers.R: all checks passed"

source(file.path("R", "analysis_filter_helpers.R"))

joined <- data.frame(
  biol_site_id = rep("291", 5),
  sample_id = paste0("S00", 1:5),
  date = sprintf("%d-05-01", 2020:2024),
  sampling_year = 2020:2024,
  LIFE_F_OE = c(0.98, 1.01, 0.95, 1.03, 0.99),
  WHPT_ASPT_OE = c(1.02, 0.99, 1.05, 0.97, 1.00),
  Q10_lag0 = c(12.1, 13.4, 11.2, 14.0, 12.8),
  Q95_lag0 = c(3.2, 2.9, 3.6, 2.7, 3.1),
  stringsAsFactors = FALSE
)

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
stopifnot(!("S002" %in% r$analysis_dataset$sample_id))
stopifnot(nrow(joined) == 5)                      # source never changed

log <- build_analysis_exclusion_log(sel)
stopifnot(nrow(log) == 1)
stopifnot(identical(names(log), ANALYSIS_EXCLUSION_LOG_COLUMNS))  # DC-07 schema
stopifnot(log$current_status == "excluded")

# --- 3. Restore the record -> it comes back, log shows restored --------------
sel <- restore_record(sel, record_id = "S002", timestamp = "2026-07-23 10:05:00")
r <- apply_filter_selection(joined, sel)
stopifnot(r$n_kept == nrow(joined))               # rebuilt analysis includes it again
stopifnot("S002" %in% r$analysis_dataset$sample_id)

log <- build_analysis_exclusion_log(sel)
stopifnot(nrow(log) == 2)                          # exclude event + restore event
stopifnot(all(log$current_status == "restored"))  # record is currently restored

# the restore event keeps the site/sample context (not NA) - Di review point
restore_row <- log[log$exclusion_reason == "User restored record", ]
stopifnot(restore_row$site_id == "291")
stopifnot(restore_row$sample_id == "S002")

# --- 4. Re-excluding after restore works ------------------------------------
sel <- exclude_record(sel, record_id = "S002", timestamp = "2026-07-23 10:10:00")
r <- apply_filter_selection(joined, sel)
stopifnot(!("S002" %in% r$analysis_dataset$sample_id))
stopifnot(tail(active_excluded_ids(sel), 1) == "S002")

# --- 5. Canonical lowercase sample_id is the expected DC-11 identifier --------
stopifnot(r$id_col == "sample_id")

# --- 6. Missing stable ID blocks DC-11 filtering -----------------------------
no_id <- joined[, setdiff(names(joined), "sample_id")]
sel2 <- exclude_record(new_filter_selection(), record_id = "3")
r2 <- apply_filter_selection(no_id, sel2, id_col = "sample_id")
stopifnot(identical(r2$status, "error"))
stopifnot(is.null(r2$analysis_dataset))

cat("test_analysis_filter_helpers.R: all checks passed\n")
