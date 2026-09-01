# test_joined_dataset_boundary_helpers.R
# Expect: "test_joined_dataset_boundary_helpers.R: all checks passed"

source(file.path("R", "analysis_filter_helpers.R"))
source(file.path("R", "display_label_helpers.R"))
source(file.path("R", "joined_dataset_boundary_helpers.R"))

joined_core <- data.frame(
  biol_site_id = c("B001", "B002", "B003"),
  sample_id = c("S001", "S002", "S003"),
  date = c("2021-05-01", "2021-05-02", "2021-05-03"),
  WHPT_ASPT_OE = c(0.92, 1.05, 0.87),
  Q10_lag0 = c(12.3, 10.1, 8.9),
  stringsAsFactors = FALSE
)

wq_summary <- data.frame(
  biol_site_id = c("B001", "B003"),
  sample_id = c("S001", "S003"),
  date = c("2021-05-01", "2021-05-03"),
  orthophosphate_mean = c(0.04, 0.08),
  orthophosphate_record_count = c(6, 4),
  stringsAsFactors = FALSE
)

rhs_summary <- data.frame(
  biol_site_id = c("B002", "B003"),
  HMSRBB = c(12, 21),
  HQA = c(54, 47),
  rhs_survey_date = as.Date(c("2020-06-01", "2020-06-02")),
  stringsAsFactors = FALSE
)

core_before <- joined_core

prepared_wq <- prepare_wq_enrichment_summary(wq_summary, joined_core)
stopifnot("sample_id" %in% names(prepared_wq))
stopifnot("orthophosphate_mean" %in% names(prepared_wq))
stopifnot(!("date" %in% names(prepared_wq)))
stopifnot(!("biol_site_id" %in% names(prepared_wq)))

prepared_rhs <- prepare_rhs_enrichment_summary(rhs_summary, joined_core)
stopifnot(all(c("biol_site_id", "HMSRBB", "HQA") %in% names(prepared_rhs)))

# --- 1. No optional enrichment keeps the workflow on joined_core -------------
none <- build_joined_enriched(
  joined_core,
  enrichments = list(wq = wq_summary),
  selected_enrichments = character()
)
stopifnot(identical(none$status, "not_ready"))
stopifnot(is.null(none$joined_enriched))
stopifnot(identical(joined_core, core_before))
stopifnot(grepl("No optional supporting data were selected", none$messages, fixed = TRUE))
stopifnot(grepl("Core Joined HE dataset", none$messages, fixed = TRUE))
stopifnot(!grepl("joined_core|joined_enriched", paste(none$messages, collapse = " ")))

# --- 2. Successful WQ enrichment creates a separate joined_enriched ----------
wq_only <- build_joined_enriched(
  joined_core,
  enrichments = list(wq = prepared_wq),
  selected_enrichments = "wq"
)
stopifnot(identical(wq_only$status, "success"))
stopifnot(is.data.frame(wq_only$joined_enriched))
stopifnot("orthophosphate_mean" %in% names(wq_only$joined_enriched))
stopifnot(!("orthophosphate_mean" %in% names(joined_core)))
stopifnot(identical(joined_core, core_before))
stopifnot(identical(wq_only$provenance$successful_enrichments, "wq"))
stopifnot(wq_only$provenance$coverage$matched_rows == 2L)
stopifnot(grepl("Water Quality", paste(wq_only$messages, collapse = " "), fixed = TRUE))
stopifnot(!grepl("Failed|Could not add", paste(wq_only$messages, collapse = " ")))

# --- 2b. Selection/list names are normalised and value types are preserved ----
rhs_only <- build_joined_enriched(
  joined_core,
  enrichments = list(RHS = prepared_rhs),
  selected_enrichments = "RHS"
)
stopifnot(identical(rhs_only$status, "success"))
stopifnot("HMSRBB" %in% names(rhs_only$joined_enriched))
stopifnot(inherits(rhs_only$joined_enriched$rhs_survey_date, "Date"))

# --- 3. One success and one failure keeps successful enrichment only ----------
partial <- build_joined_enriched(
  joined_core,
  enrichments = list(wq = prepared_wq, rhs = NULL),
  selected_enrichments = c("wq", "rhs")
)
stopifnot(identical(partial$status, "warning"))
stopifnot("orthophosphate_mean" %in% names(partial$joined_enriched))
stopifnot(!("HMSRBB" %in% names(partial$joined_enriched)))
stopifnot(identical(partial$provenance$successful_enrichments, "wq"))
stopifnot(identical(partial$provenance$failed_enrichments, "rhs"))
stopifnot(grepl("Added: Water Quality", paste(partial$messages, collapse = " "), fixed = TRUE))
stopifnot(grepl("Could not add: River Habitat Survey", paste(partial$messages, collapse = " "), fixed = TRUE))
stopifnot(!grepl("wq|rhs", paste(partial$messages, collapse = " ")))

# --- 4. All selected enrichment failing does not create joined_enriched -------
all_failed <- build_joined_enriched(
  joined_core,
  enrichments = list(rhs = NULL),
  selected_enrichments = "rhs"
)
stopifnot(identical(all_failed$status, "warning"))
stopifnot(is.null(all_failed$joined_enriched))
stopifnot(identical(joined_core, core_before))
stopifnot(!grepl("Added:", paste(all_failed$messages, collapse = " "), fixed = TRUE))
stopifnot(grepl("Could not add: River Habitat Survey", paste(all_failed$messages, collapse = " "), fixed = TRUE))

# --- 5. Duplicate enrichment keys are rejected rather than duplicated ---------
bad_wq <- rbind(wq_summary, wq_summary[1, , drop = FALSE])
bad_wq <- prepare_wq_enrichment_summary(bad_wq, joined_core)
bad_result <- build_joined_enriched(
  joined_core,
  enrichments = list(wq = bad_wq),
  selected_enrichments = "wq"
)
stopifnot(identical(bad_result$status, "warning"))
stopifnot(is.null(bad_result$joined_enriched))
stopifnot(grepl("not unique", bad_result$provenance$failure_reasons$wq, fixed = TRUE))

# --- 6. Analysis can be explicitly derived from core or enriched --------------
core_analysis <- derive_analysis_dataset(joined_core, wq_only$joined_enriched, use_enriched = FALSE)
stopifnot(identical(core_analysis$source_dataset, "joined_core"))
stopifnot(is.character(core_analysis$source_fingerprint))
stopifnot(nzchar(core_analysis$source_fingerprint))
stopifnot(!("orthophosphate_mean" %in% names(core_analysis$analysis_dataset)))

enriched_analysis <- derive_analysis_dataset(joined_core, wq_only$joined_enriched, use_enriched = TRUE)
stopifnot(identical(enriched_analysis$source_dataset, "joined_enriched"))
stopifnot(!identical(enriched_analysis$source_fingerprint, core_analysis$source_fingerprint))
stopifnot("orthophosphate_mean" %in% names(enriched_analysis$analysis_dataset))
stopifnot(identical(joined_dataset_display_label("joined_core"), "Core Joined HE dataset"))
stopifnot(identical(
  joined_dataset_display_label("joined_enriched"),
  "Joined HE dataset with optional supporting data"
))
stopifnot(identical(
  optional_supporting_data_display_labels(c("wq", "rhs")),
  c("Water Quality", "River Habitat Survey")
))
stopifnot(enrichment_result_matches_selection(wq_only, "wq"))
stopifnot(!enrichment_result_matches_selection(wq_only, c("wq", "rhs")))

selection <- exclude_record(new_filter_selection(), record_id = "S002")
filtered <- derive_analysis_dataset(joined_core, wq_only$joined_enriched, use_enriched = TRUE, filter_selection = selection)
stopifnot(identical(filtered$source_dataset, "joined_enriched"))
stopifnot(filtered$analysis_rows == 2L)
stopifnot(!("S002" %in% filtered$analysis_dataset$sample_id))
stopifnot(nrow(wq_only$joined_enriched) == 3L)

cat("test_joined_dataset_boundary_helpers.R: all checks passed\n")
