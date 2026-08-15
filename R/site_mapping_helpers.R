normalise_parsed_site_metadata <- function(data) {
  if (is.null(data)) {
    return(list(
      data = NULL,
      error = paste(
        "Site metadata could not be read or validated.",
        "Please correct the CSV structure and try again."
      ),
      warnings = character(0)
    ))
  }

  if (nrow(data) == 0 || ncol(data) == 0) {
    return(list(
      data = NULL,
      error = paste(
        "Site metadata is empty.",
        "Please provide a CSV header and at least one data row."
      ),
      warnings = character(0)
    ))
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

parse_site_metadata <- function(text) {
  if (is.null(text) || !nzchar(trimws(text))) {
    return(list(
      data = NULL,
      error = "Please add site metadata, then validate the mapping again.",
      warnings = character(0)
    ))
  }

  normalise_parsed_site_metadata(read_character_csv(text = text))
}

read_site_metadata_csv <- function(path) {
  if (is.null(path) || !file.exists(path)) {
    return(list(
      data = NULL,
      error = "The selected site metadata CSV could not be found. Please select the file and upload it again.",
      warnings = character(0)
    ))
  }

  normalise_parsed_site_metadata(read_character_csv(path = path))
}

donor_mapping_error_message <- function() {
  paste(
    "The donor mapping could not be read or validated.",
    "Please correct the two-column donor-site mapping and try again."
  )
}

parse_donor_mapping <- function(text, reader = read_character_csv) {
  if (is.null(text) || !nzchar(trimws(text))) {
    return(list(
      data = NULL,
      error = "If imputing flows please add donor mapping."
    ))
  }

  data <- tryCatch(
    reader(text = text),
    error = function(error) NULL
  )
  if (
    is.null(data) || !is.data.frame(data) || nrow(data) == 0L ||
      ncol(data) != 2L || anyDuplicated(names(data))
  ) {
    return(list(data = NULL, error = donor_mapping_error_message()))
  }

  data[] <- lapply(data, function(column) trimws(as.character(column)))
  unusable <- vapply(
    data,
    function(column) any(is.na(column) | !nzchar(column)),
    logical(1)
  )
  if (any(unusable)) {
    return(list(data = NULL, error = donor_mapping_error_message()))
  }

  list(data = data, error = NULL)
}

donor_site_list_error_message <- function() {
  paste(
    "The donor site list is invalid or could not be read.",
    "Please include a flow_site_id column, use NRFA or HDE for flow_input,",
    "and try again."
  )
}

parse_donor_site_list <- function(text, reader = read_character_csv) {
  if (is.null(text) || !nzchar(trimws(text))) {
    return(list(
      data = NULL,
      error = "If importing additional donor flows, please add the donor site list."
    ))
  }

  data <- tryCatch(
    reader(text = text),
    error = function(error) NULL
  )
  if (
    is.null(data) || !is.data.frame(data) || nrow(data) == 0L ||
      ncol(data) == 0L
  ) {
    return(list(data = NULL, error = donor_site_list_error_message()))
  }

  names(data) <- tolower(trimws(names(data)))
  if (anyDuplicated(names(data)) || !"flow_site_id" %in% names(data)) {
    return(list(data = NULL, error = donor_site_list_error_message()))
  }
  data[] <- lapply(data, function(column) trimws(as.character(column)))
  if (any(is.na(data$flow_site_id) | !nzchar(data$flow_site_id))) {
    return(list(data = NULL, error = donor_site_list_error_message()))
  }

  data <- tryCatch(
    normalise_site_metadata_flow_input(data),
    error = function(error) NULL
  )
  if (is.null(data)) {
    return(list(data = NULL, error = donor_site_list_error_message()))
  }

  list(data = data, error = NULL)
}

missing_donor_flow_sites <- function(donor_sites, available_sites) {
  donor_sites <- unique(as.character(donor_sites))
  available_sites <- unique(as.character(available_sites))
  setdiff(donor_sites[!is.na(donor_sites) & nzchar(donor_sites)], available_sites)
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

  flow_inputs <- if (has_flow_input) {
    trimws(as.character(metadata$flow_input))
  } else {
    rep(NA_character_, nrow(metadata))
  }
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
  attr(metadata, "flow_input_provenance") <- data.frame(
    flow_input_value = flow_inputs,
    flow_input_source = ifelse(missing_inputs, "defaulted", "explicit"),
    stringsAsFactors = FALSE
  )
  metadata
}

site_metadata_flow_input_provenance <- function(metadata) {
  attr(metadata, "flow_input_provenance", exact = TRUE)
}

import_dashboard_flow <- function(sites, inputs, start_date, end_date) {
  hetoolkit::import_flow(
    sites = sites,
    inputs = inputs,
    start_date = start_date,
    end_date = end_date
  )
}

import_dashboard_wq <- function(sites, start_date, end_date) {
  hetoolkit::import_wq(
    sites = sites,
    dets = "default",
    start_date = start_date,
    end_date = end_date,
    save = FALSE
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
    if (grepl("without flow_site_id", conditionMessage(flow_validation), fixed = TRUE)) {
      return("flow_input cannot be validated without flow_site_id. Add flow_site_id or remove flow_input.")
    }
    return("Site metadata could not be validated. Please correct the mapping columns and try again.")
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

import_rhs_in_temp_directory <- function(
    surveys,
    importer = hetoolkit::import_rhs,
    directory_factory = function() tempfile("hetoolkit-rhs-"),
    create_directory = function(path) dir.create(path, recursive = TRUE),
    set_working_directory = setwd,
    remove_directory = function(path) unlink(path, recursive = TRUE, force = TRUE)) {
  import_dir <- NULL
  previous_dir <- NULL
  setup_result <- safe_file_operation(function() {
    import_dir <<- directory_factory()
    created <- create_directory(import_dir)
    if (!isTRUE(created) && !dir.exists(import_dir)) {
      stop("The RHS runtime directory could not be created.", call. = FALSE)
    }
    previous_dir <<- getwd()
    set_working_directory(import_dir)
    invisible(import_dir)
  })

  if (!identical(setup_result$status, "success")) {
    if (!is.null(import_dir) && nzchar(import_dir)) {
      cleanup_result <- safe_file_operation(function() {
        remove_directory(import_dir)
        if (dir.exists(import_dir)) {
          stop("The RHS runtime directory could not be removed.", call. = FALSE)
        }
        invisible(TRUE)
      })
      if (!identical(cleanup_result$status, "success")) {
        message("RAW-21 RHS temporary-file cleanup diagnostic: ", cleanup_result$diagnostic)
      }
    }
    abort_file_operation(setup_result)
  }

  on.exit({
    restore_result <- safe_file_operation(function() set_working_directory(previous_dir))
    if (!identical(restore_result$status, "success")) {
      message("RAW-21 RHS working-directory restore diagnostic: ", restore_result$diagnostic)
    }
    cleanup_result <- safe_file_operation(function() {
      remove_directory(import_dir)
      if (dir.exists(import_dir)) {
        stop("The RHS runtime directory could not be removed.", call. = FALSE)
      }
      invisible(TRUE)
    })
    if (!identical(cleanup_result$status, "success")) {
      message("RAW-21 RHS temporary-file cleanup diagnostic: ", cleanup_result$diagnostic)
    }
  }, add = TRUE)

  rhs_data <- importer(
    source = NULL,
    surveys = surveys,
    save = FALSE,
    save_dwnld = FALSE,
    save_dir = import_dir
  )

  normalise_rhs_records(rhs_data, allow_external_survey_id = TRUE)
}
