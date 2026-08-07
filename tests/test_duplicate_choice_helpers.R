# test_duplicate_choice_helpers.R
# Run in RStudio: open the project, then Source this file.
# Expect: "test_duplicate_choice_helpers.R: all checks passed"

source(file.path("R", "duplicate_choice_helpers.R"))
source(file.path("R", "analysis_filter_helpers.R"))

biology <- data.frame(
  biol_site_id = c("291", "291", "292", "292", "292"),
  sample_id = c("S001", "S002", "S003", "S004", "S005"),
  date = c("2024-05-01", "2024-05-01", "2024-05-02", "2024-05-03", "2024-05-03"),
  WHPT_ASPT = c(6.2, 6.3, 5.9, 7.1, 7.2),
  stringsAsFactors = FALSE
)

# --- 1. Detection blocks final analysis and reports groups -------------------
detected <- detect_biology_duplicates(biology)
stopifnot(identical(detected$status, "blocked"))
stopifnot(isTRUE(detected$needs_choice))
stopifnot(nrow(detected$groups) == 4)
stopifnot(all(c("same_day", "same_month_year") %in% detected$groups$duplicate_period))
stopifnot(all(c("duplicate_group_id", "duplicate_period", "record_id", "site_id", "sample_id", "date") %in% names(detected$records)))

same_day_only <- detect_same_day_duplicates(biology)
stopifnot(nrow(same_day_only$groups) == 2)
stopifnot(all(same_day_only$groups$record_count == 2))

# --- 2. Missing choices do not change data ----------------------------------
missing_choice <- apply_duplicate_choices(
  biology,
  data.frame(duplicate_group_id = same_day_only$groups$duplicate_group_id[1], choice = "keep_all"),
  same_day_only
)
stopifnot(identical(missing_choice$status, "blocked"))
stopifnot(is.null(missing_choice$kept))
stopifnot(is.null(missing_choice$excluded))

# --- 3. keep_all keeps every row but records explicit provenance -------------
keep_all <- data.frame(
  duplicate_group_id = same_day_only$groups$duplicate_group_id,
  choice = "keep_all",
  user_comment = "both samples valid",
  stringsAsFactors = FALSE
)
kept_result <- apply_duplicate_choices(biology, keep_all, same_day_only)
stopifnot(identical(kept_result$status, "success"))
stopifnot(nrow(kept_result$kept) == nrow(biology))
stopifnot(nrow(kept_result$excluded) == 0)
stopifnot(all(kept_result$log$action == "kept"))

# --- 4. keep_record excludes only the non-selected rows ----------------------
choices <- data.frame(
  duplicate_group_id = same_day_only$groups$duplicate_group_id,
  choice = c("keep_record", "keep_record"),
  selected_record_id = c("S001", "S004"),
  user_comment = c("lab replicate chosen", "field note chosen"),
  stringsAsFactors = FALSE
)
resolved <- apply_duplicate_choices(biology, choices, same_day_only)
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

# --- 7. Same-month duplicates are detected even when dates differ ------------
month_only <- biology[c(1, 3, 4), ]
month_detected <- detect_biology_duplicates(month_only)
stopifnot(identical(month_detected$status, "blocked"))
stopifnot(any(month_detected$groups$duplicate_period == "same_month_year"))
month_keep_all <- data.frame(
  duplicate_group_id = month_detected$groups$duplicate_group_id,
  choice = "keep_all",
  stringsAsFactors = FALSE
)
month_kept <- apply_duplicate_choices(month_only, month_keep_all, month_detected)
stopifnot(identical(month_kept$status, "success"))
stopifnot(nrow(month_kept$kept) == nrow(month_only))

# --- 8. UI-facing choice helpers keep server glue thin -----------------------
choice_text <- "duplicate_group_id,choice,selected_record_id,user_comment\nDUPD001,keep_record,S001,manual decision"
parsed_choices <- parse_duplicate_choice_csv_text(choice_text)
stopifnot(identical(parsed_choices$duplicate_group_id, "DUPD001"))
stopifnot(identical(parsed_choices$choice, "keep_record"))

built_keep_all <- build_keep_all_duplicate_choices(same_day_only)
stopifnot(nrow(built_keep_all) == nrow(same_day_only$groups))
stopifnot(all(built_keep_all$choice == "keep_all"))

selection <- new_filter_selection()
selection <- apply_duplicate_exclusions_to_selection(selection, resolved, timestamp = "2026-08-08 12:00:00")
selection_log <- build_analysis_exclusion_log(selection)
stopifnot(nrow(selection_log) == nrow(resolved$excluded))
stopifnot(all(selection_log$trigger == "duplicate_choice"))
stopifnot(all(selection_log$current_status == "excluded"))

cat("test_duplicate_choice_helpers.R: all checks passed\n")
