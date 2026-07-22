# test_exclusion_log_helpers.R
# Run in RStudio: open the project, then Source this file.
# Expect: "test_exclusion_log_helpers.R: all checks passed"

source(file.path("R", "dashboard_backlog_helpers.R"))
source(file.path("R", "filtering_helpers.R"))
source(file.path("R", "exclusion_log_helpers.R"))

inv <- read_dashboard_csv(file.path("tests", "fixtures", "local_invertebrate.csv"),
                          "Local invertebrate")

# character-typed base so injected bad strings don't clash with fread's Date col
base <- data.frame(
  biol_site_id = as.character(inv$data$biol_site_id),
  date         = as.character(inv$data$date),
  taxon        = as.character(inv$data$taxon),
  abundance    = as.numeric(inv$data$abundance),
  stringsAsFactors = FALSE
)

# --- 1. Clean data -> empty log with correct columns ------------------------
log_clean <- build_exclusion_log(filter_records(inv$data))
stopifnot(nrow(log_clean) == 0)
stopifnot(identical(names(log_clean), EXCLUSION_LOG_COLUMNS))

# --- 2. Bad rows -> one log entry per excluded row, correct fields -----------
bad <- rbind(
  base,
  data.frame(biol_site_id = "",    date = "2024-01-01", taxon = "Baetidae",     abundance = 5,  stringsAsFactors = FALSE),
  data.frame(biol_site_id = "293", date = "2024-01-01", taxon = "Baetidae",     abundance = -3, stringsAsFactors = FALSE),
  data.frame(biol_site_id = "293", date = "not-a-date", taxon = "Chironomidae", abundance = 4,  stringsAsFactors = FALSE),
  data.frame(biol_site_id = "293", date = "2024-01-01", taxon = "",             abundance = 7,  stringsAsFactors = FALSE)
)
res <- filter_records(bad)
log <- build_exclusion_log(res)

stopifnot(nrow(log) == 4)                                   # 4 excluded rows -> 4 log rows
stopifnot(identical(names(log), EXCLUSION_LOG_COLUMNS))     # fixed schema
stopifnot(all(log$severity == "Error"))
stopifnot(all(nzchar(log$timestamp)))                       # every row timestamped
stopifnot(all(!is.na(log$rule)))                            # every row has a reason
stopifnot("-3" %in% log$excluded_value)                    # negative abundance captured
stopifnot("not-a-date" %in% log$excluded_value)            # bad date value captured

# --- 3. Warning (kept-but-flagged) rows also appear in the log --------------
res_warn <- filter_records(inv$data, min_records_per_site = 5)
log_warn <- build_exclusion_log(res_warn)
stopifnot(nrow(log_warn) > 0)
stopifnot(all(log_warn$severity == "Warning"))

# --- 4. Summary message is Info-level and counts correctly ------------------
summ <- exclusion_log_summary(log)
stopifnot(identical(summ$status, "info"))
stopifnot(grepl("4 record", summ$messages))

summ_empty <- exclusion_log_summary(log_clean)
stopifnot(grepl("No records", summ_empty$messages))

# --- 5. Fixed timestamp override is respected (deterministic) ---------------
log_ts <- build_exclusion_log(res, timestamp = "2026-01-01 00:00:00")
stopifnot(all(log_ts$timestamp == "2026-01-01 00:00:00"))

cat("test_exclusion_log_helpers.R: all checks passed\n")
