parse_site_metadata <- function(text) {
  if (is.null(text) || !nzchar(trimws(text))) {
    return(list(data = NULL, error = "Please add site metadata.", warnings = character(0)))
  }

  data <- tryCatch(
    data.table::fread(text = text, colClasses = "character", data.table = FALSE),
    error = function(e) NULL
  )

  if (is.null(data) || nrow(data) == 0 || ncol(data) == 0) {
    return(list(data = NULL, error = "Site metadata could not be read. Please paste a CSV header and at least one data row.", warnings = character(0)))
  }

  names(data) <- tolower(trimws(names(data)))
  if (anyDuplicated(names(data))) {
    return(list(data = NULL, error = "Site metadata contains duplicate column names.", warnings = character(0)))
  }

  warnings <- character(0)
  if ("rhs_site_id" %in% names(data)) {
    if ("rhs_survey_id" %in% names(data)) {
      return(list(
        data = NULL,
        error = "Use rhs_survey_id only. Remove the legacy rhs_site_id column.",
        warnings = character(0)
      ))
    }

    names(data)[names(data) == "rhs_site_id"] <- "rhs_survey_id"
    warnings <- "The legacy rhs_site_id column was interpreted as rhs_survey_id. RHS imports use survey IDs."
  }

  if ("biol_site_id" %in% names(data) && anyDuplicated(data$biol_site_id)) {
    return(list(
      data = NULL,
      error = "Each biol_site_id must appear once in the main metadata table. Use a separate mapping table for multiple WQ sites or RHS surveys.",
      warnings = warnings
    ))
  }

  list(data = data, error = NULL, warnings = warnings)
}

usable_mapping_ids <- function(metadata, column) {
  if (is.null(metadata) || !column %in% names(metadata)) {
    return(character(0))
  }

  values <- trimws(as.character(metadata[[column]]))
  unique(values[!is.na(values) & nzchar(values) & toupper(values) != "TBC"])
}

map_wq_records_to_biology <- function(wq_data, metadata) {
  required <- c("biol_site_id", "wq_site_id")
  if (!all(required %in% names(metadata)) || is.null(wq_data) || nrow(wq_data) == 0) {
    return(data.frame())
  }

  bridge <- metadata[, required, drop = FALSE]
  bridge <- bridge[bridge$wq_site_id %in% usable_mapping_ids(metadata, "wq_site_id"), , drop = FALSE]
  bridge <- unique(bridge)
  dplyr::inner_join(bridge, wq_data, by = "wq_site_id")
}

normalise_rhs_records <- function(rhs_data) {
  id_columns <- intersect(c("rhs_survey_id", "Survey.ID", "SURVEY_ID"), names(rhs_data))
  if (length(id_columns) == 0) {
    stop("RHS data does not contain a survey identifier column.")
  }

  names(rhs_data)[names(rhs_data) == id_columns[[1]]] <- "rhs_survey_id"
  rhs_data$rhs_survey_id <- as.character(rhs_data$rhs_survey_id)
  rhs_data
}

map_rhs_records_to_biology <- function(rhs_data, metadata) {
  required <- c("biol_site_id", "rhs_survey_id")
  if (!all(required %in% names(metadata)) || is.null(rhs_data) || nrow(rhs_data) == 0) {
    return(data.frame())
  }

  rhs_data <- normalise_rhs_records(rhs_data)
  bridge <- metadata[, required, drop = FALSE]
  bridge <- bridge[bridge$rhs_survey_id %in% usable_mapping_ids(metadata, "rhs_survey_id"), , drop = FALSE]
  bridge <- unique(bridge)
  dplyr::inner_join(bridge, rhs_data, by = "rhs_survey_id")
}

import_rhs_in_temp_directory <- function(surveys, importer = hetoolkit::import_rhs) {
  import_dir <- tempfile("hetoolkit-rhs-")
  dir.create(import_dir, recursive = TRUE)
  on.exit(unlink(import_dir, recursive = TRUE, force = TRUE), add = TRUE)

  previous_dir <- getwd()
  setwd(import_dir)
  on.exit(setwd(previous_dir), add = TRUE)

  rhs_data <- importer(
    source = NULL,
    surveys = surveys,
    save = FALSE,
    save_dwnld = FALSE,
    save_dir = import_dir
  )

  normalise_rhs_records(rhs_data)
}
