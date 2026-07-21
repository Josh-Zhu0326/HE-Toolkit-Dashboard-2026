# test_filtering_helpers.R
# Run in RStudio: open the project, then Source this file (Ctrl/Cmd+Shift+S)
# or click "Source". Working directory must be the project root.
# If all checks pass you will see "test_filtering_helpers.R: all checks passed".

source(file.path("R", "dashboard_backlog_helpers.R"))
source(file.path("R", "filtering_helpers.R"))

# --- 1. Clean fixture data should pass with no exclusions --------------------
inv <- read_dashboard_csv(file.path("tests", "fixtures", "local_invertebrate.csv"),
                          "Local invertebrate")
stopifnot(identical(inv$status, "success"))

clean <- filter_records(inv$data)
stopifnot(identical(clean$status, "success"))
stopifnot(is.null(clean$excluded))
stopifnot(nrow(clean$kept) == nrow(inv$data))

# Build a character-typed copy so rbind never tries to coerce a bad string
# (e.g. "not-a-date") into fread's Date column, which would throw charToDate.
base <- data.frame(
  biol_site_id = as.character(inv$data$biol_site_id),
  date         = as.character(inv$data$date),
  taxon        = as.character(inv$data$taxon),
  abundance    = as.numeric(inv$data$abundance),
  stringsAsFactors = FALSE
)

# --- 2. Inject bad rows and confirm they are excluded with reasons ----------
bad <- rbind(
  base,
  data.frame(biol_site_id = "",    date = "2024-01-01", taxon = "Baetidae",  abundance = 5,  stringsAsFactors = FALSE),  # missing site id
  data.frame(biol_site_id = "293", date = "2024-01-01", taxon = "Baetidae",  abundance = -3, stringsAsFactors = FALSE),  # negative abundance
  data.frame(biol_site_id = "293", date = "not-a-date", taxon = "Chironomidae", abundance = 4, stringsAsFactors = FALSE), # bad date
  data.frame(biol_site_id = "293", date = "2024-01-01", taxon = "",          abundance = 7,  stringsAsFactors = FALSE)   # missing taxon
)

res <- filter_records(bad)
stopifnot(identical(res$status, "warning"))
stopifnot(!is.null(res$excluded))
stopifnot(nrow(res$excluded) == 4)                      # exactly the 4 bad rows
stopifnot(all(res$excluded$severity == "Error"))
stopifnot("exclusion_reason" %in% names(res$excluded))  # reason column exists for the log
stopifnot(nrow(res$kept) == nrow(inv$data))             # original good rows all survive

# --- 3. Duplicate row -> Warning, first copy kept ---------------------------
dup <- rbind(inv$data, inv$data[1, ])
res_dup <- filter_records(dup)
stopifnot(nrow(res_dup$kept) == nrow(inv$data))         # duplicate removed
stopifnot(any(grepl("Duplicate", res_dup$excluded$exclusion_reason)))

# --- 4. Outlier cap (optional threshold) ------------------------------------
res_cap <- filter_records(inv$data, max_abundance = 20)
stopifnot(!is.null(res_cap$excluded))                   # abundance 30 row excluded
stopifnot(any(grepl("exceeds allowed maximum", res_cap$excluded$exclusion_reason)))

# --- 5. Small-site warning keeps the row but logs it ------------------------
res_small <- filter_records(inv$data, min_records_per_site = 5)
stopifnot(!is.null(res_small$log))                      # flagged, not removed
stopifnot(nrow(res_small$kept) == nrow(inv$data))

cat("test_filtering_helpers.R: all checks passed\n")
