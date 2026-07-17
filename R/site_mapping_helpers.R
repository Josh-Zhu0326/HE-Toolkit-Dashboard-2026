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
  has_rhs_site_id <- "rhs_site_id" %in% names(data)
  has_rhs_survey_id <- "rhs_survey_id" %in% names(data)
  if (has_rhs_site_id && has_rhs_survey_id) {
    return(list(
      data = NULL,
      error = "Site metadata must not contain both rhs_survey_id and rhs_site_id. Remove rhs_site_id and use rhs_survey_id only.",
      warnings = character(0)
    ))
  }
  if (has_rhs_site_id) {
    return(list(
      data = NULL,
      error = "rhs_site_id is not supported. Replace it with rhs_survey_id.",
      warnings = character(0)
    ))
  }

  biol_ids <- if ("biol_site_id" %in% names(data)) {
    values <- trimws(as.character(data$biol_site_id))
    values[!is.na(values) & nzchar(values) & toupper(values) != "TBC"]
  } else {
    character(0)
  }
  if (anyDuplicated(biol_ids)) {
    warnings <- c(
      warnings,
      "Duplicated biol_site_id values were found. This is allowed for preview, but main biology/flow imports may require one row per biology site."
    )
  }

  list(data = data, error = NULL, warnings = warnings)
}

read_site_metadata_csv <- function(path) {
  if (is.null(path) || !file.exists(path)) {
    return(list(data = NULL, error = "The selected site metadata CSV could not be found.", warnings = character(0)))
  }

  data <- tryCatch(
    data.table::fread(path, colClasses = "character", data.table = FALSE, encoding = "UTF-8"),
    error = function(e) NULL
  )

  if (is.null(data)) {
    return(list(data = NULL, error = "The selected file could not be read as CSV.", warnings = character(0)))
  }

  parse_site_metadata(readr::format_csv(data))
}

normalise_site_metadata_flow_input <- function(metadata) {
  if (is.null(metadata)) {
    stop("Site metadata are missing.", call. = FALSE)
  }

  has_flow_site_id <- "flow_site_id" %in% names(metadata)
  has_flow_input <- "flow_input" %in% names(metadata)

  if (has_flow_input && !has_flow_site_id) {
    stop("flow_input cannot be used without flow_site_id.", call. = FALSE)
  }

  if (!has_flow_site_id) {
    return(metadata)
  }

  if (!has_flow_input) {
    metadata$flow_input <- "HDE"
    return(metadata)
  }

  flow_inputs <- trimws(as.character(metadata$flow_input))
  missing_inputs <- is.na(flow_inputs) | !nzchar(flow_inputs)
  flow_inputs[missing_inputs] <- "HDE"
  flow_inputs <- toupper(flow_inputs)

  invalid_inputs <- unique(flow_inputs[!flow_inputs %in% c("NRFA", "HDE")])
  if (length(invalid_inputs) > 0) {
    stop(
      paste0("Invalid flow_input value(s): ", paste(invalid_inputs, collapse = ", "), ". Use NRFA or HDE."),
      call. = FALSE
    )
  }

  metadata$flow_input <- flow_inputs
  metadata
}

import_dashboard_flow <- function(sites, inputs, start_date, end_date) {
  hetoolkit::import_flow(
    sites = sites,
    inputs = inputs,
    start_date = start_date,
    end_date = end_date
  )
}

validate_dashboard_site_metadata <- function(metadata) {
  has_rhs_site_id <- "rhs_site_id" %in% names(metadata)
  has_rhs_survey_id <- "rhs_survey_id" %in% names(metadata)
  if (has_rhs_site_id && has_rhs_survey_id) {
    return("Site metadata must not contain both rhs_survey_id and rhs_site_id. Remove rhs_site_id and use rhs_survey_id only.")
  }
  if (has_rhs_site_id) {
    return("rhs_site_id is not supported. Replace it with rhs_survey_id.")
  }

  id_columns <- c("biol_site_id", "flow_site_id", "wq_site_id", "rhs_survey_id")
  if (!any(id_columns %in% names(metadata))) {
    return(paste0("Include at least one supported site ID column: ", paste(id_columns, collapse = ", "), "."))
  }

  flow_validation <- tryCatch(
    normalise_site_metadata_flow_input(metadata),
    error = function(e) e
  )
  if (inherits(flow_validation, "error")) {
    if (grepl("Invalid flow_input value", conditionMessage(flow_validation), fixed = TRUE)) {
      return("flow_input values must be NRFA or HDE for this dashboard workflow.")
    }
    return(conditionMessage(flow_validation))
  }

  NULL
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
  dplyr::left_join(wq_data, bridge, by = "wq_site_id") |>
    dplyr::relocate(biol_site_id, .before = wq_site_id)
}

normalise_rhs_records <- function(rhs_data, allow_external_survey_id = FALSE) {
  if ("rhs_site_id" %in% names(rhs_data)) {
    stop("rhs_site_id is not supported. Use rhs_survey_id.")
  }

  has_rhs_survey_id <- "rhs_survey_id" %in% names(rhs_data)
  has_external_survey_id <- "Survey.ID" %in% names(rhs_data)
  if (has_rhs_survey_id && has_external_survey_id) {
    stop("RHS data must not contain both rhs_survey_id and Survey.ID.")
  }
  if (has_external_survey_id && !allow_external_survey_id) {
    stop("Survey.ID is accepted only from the external RHS interface. Local RHS data must use rhs_survey_id.")
  }
  if (!has_rhs_survey_id && !has_external_survey_id) {
    stop("RHS data does not contain the required rhs_survey_id column.")
  }
  if (has_external_survey_id) {
    names(rhs_data)[names(rhs_data) == "Survey.ID"] <- "rhs_survey_id"
  }

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
  dplyr::left_join(rhs_data, bridge, by = "rhs_survey_id") |>
    dplyr::relocate(biol_site_id, .before = rhs_survey_id)
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

  normalise_rhs_records(rhs_data, allow_external_survey_id = TRUE)
}
