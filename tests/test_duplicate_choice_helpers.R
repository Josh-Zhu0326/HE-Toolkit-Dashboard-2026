# test_duplicate_choice_helpers.R
# Run in RStudio: open the project, then Source this file.
# Expect: "test_duplicate_choice_helpers.R: all checks passed"

source(file.path("R", "duplicate_choice_helpers.R"))

biology <- data.frame(
  biol_site_id = c("291", "291", "292", "292", "292"),
  sample_id = c("S001", "S002", "S003", "S004", "S005"),
  date = c("2024-05-01", "2024-05-01", "2024-05-02", "2024-05-03", "2024-05-03"),
  WHPT_ASPT = c(6.2, 6.3, 5.9, 7.1, 7.2),
  stringsAsFactors = FALSE
)

# --- 1. Detection blocks final analysis and reports groups -------------------
detected <- detect_same_day_duplicates(biology)
stopifnot(identical(detected$status, "blocked"))
stopifnot(isTRUE(detected$needs_choice))
stopifnot(nrow(detected$groups) == 2)
stopifnot(all(detected$groups$record_count == 2))
stopifnot(all(c("duplicate_group_id", "record_id", "site_id", "sample_id", "date") %in% names(detected$records)))

# --- 2. Missing choices do not change data ----------------------------------
missing_choice <- apply_duplicate_choices(
  biology,
  data.frame(duplicate_group_id = detected$groups$duplicate_group_id[1], choice = "keep_all"),
  detected
)
stopifnot(identical(missing_choice$status, "blocked"))
stopifnot(is.null(missing_choice$kept))
stopifnot(is.null(missing_choice$excluded))

# --- 3. keep_all keeps every row but records explicit provenance -------------
keep_all <- data.frame(
  duplicate_group_id = detected$groups$duplicate_group_id,
  choice = "keep_all",
  user_comment = "both samples valid",
  stringsAsFactors = FALSE
)
kept_result <- apply_duplicate_choices(biology, keep_all, detected)
stopifnot(identical(kept_result$status, "success"))
stopifnot(nrow(kept_result$kept) == nrow(biology))
stopifnot(nrow(kept_result$excluded) == 0)
stopifnot(all(kept_result$log$action == "kept"))

# --- 4. keep_record excludes only the non-selected rows ----------------------
choices <- data.frame(
  duplicate_group_id = detected$groups$duplicate_group_id,
  choice = c("keep_record", "keep_record"),
  selected_record_id = c("S001", "S004"),
  user_comment = c("lab replicate chosen", "field note chosen"),
  stringsAsFactors = FALSE
)
resolved <- apply_duplicate_choices(biology, choices, detected)
stopifnot(identical(resolved$status, "success"))
stopifnot(nrow(resolved$kept) == 3)
stopifnot(nrow(resolved$excluded) == 2)
stopifnot(all(c("S002", "S005") %in% resolved$excluded$sample_id))
stopifnot(identical(names(resolved$log), DUPLICATE_CHOICE_LOG_COLUMNS))
stopifnot(all(resolved$log$action %in% c("kept", "excluded")))

# --- 5. Explicit record_id is supported as the stable identifier -------------
with_record_id <- biology
with_record_id$record_id <- paste0("R", seq_len(nrow(with_record_id)))
record_detected <- detect_same_day_duplicates(with_record_id)
stopifnot(all(c("R1", "R2", "R4", "R5") %in% record_detected$records$record_id))

# --- 6. Clean data passes without requiring choices --------------------------
clean <- biology[c(1, 3, 4), ]
clean_detected <- detect_same_day_duplicates(clean)
stopifnot(identical(clean_detected$status, "success"))
stopifnot(!isTRUE(clean_detected$needs_choice))

cat("test_duplicate_choice_helpers.R: all checks passed\n")
