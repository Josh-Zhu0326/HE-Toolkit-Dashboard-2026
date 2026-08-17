# local_data_source_helpers.R
# Shared validation and source selection for the five client-confirmed local
# CSV types. Combining sources retains every row; duplicate resolution remains
# an explicit downstream user decision.

local_dataset_contracts <- function() {
  list(
    biology = list(
      required = c(
        "biol_site_id", "SAMPLE_ID", "SAMPLE_DATE", "WHPT_ASPT",
        "WHPT_N_TAXA", "LIFE_FAMILY_INDEX", "PSI_FAMILY_SCORE",
        "Month", "Year", "Season"
      ),
      at_least_one = c(
        "WHPT_ASPT", "WHPT_N_TAXA", "LIFE_FAMILY_INDEX", "PSI_FAMILY_SCORE"
      ),
      date = "SAMPLE_DATE",
      integer = c("Month", "Year"),
      numeric = c(
        "WHPT_ASPT", "WHPT_N_TAXA", "LIFE_FAMILY_INDEX", "PSI_FAMILY_SCORE"
      ),
      identifiers = c("biol_site_id", "SAMPLE_ID")
    ),
    environment = list(
      required = c(
        "biol_site_id", "NGR_10_FIG", "ALTITUDE", "SLOPE",
        "DIST_FROM_SOURCE", "DISCHARGE", "WIDTH", "DEPTH",
        "BOULDERS_COBBLES", "PEBBLES_GRAVEL", "SAND", "SILT_CLAY",
        "ALKALINITY", "CONDUCTIVITY", "MIN_SAMPLE_DATE", "MAX_SAMPLE_DATE",
        "COUNT_OF_SAMPLES"
      ),
      date = c("MIN_SAMPLE_DATE", "MAX_SAMPLE_DATE"),
      integer = "COUNT_OF_SAMPLES",
      numeric = c(
        "ALTITUDE", "SLOPE", "DIST_FROM_SOURCE", "DISCHARGE", "WIDTH",
        "DEPTH", "BOULDERS_COBBLES", "PEBBLES_GRAVEL", "SAND",
        "SILT_CLAY", "ALKALINITY", "CONDUCTIVITY", "TOTAL_HARDNESS",
        "CALCIUM"
      ),
      identifiers = "biol_site_id"
    ),
    flow = list(
      required = c("flow_site_id", "date", "flow"),
      date = "date",
      numeric = "flow",
      identifiers = "flow_site_id",
      allow_extra = FALSE
    ),
    wq = list(
      required = c("wq_site_id", "date_time", "det_id", "qualifier", "result"),
      date = "date_time",
      numeric = "result",
      identifiers = c("wq_site_id", "det_id")
    ),
    rhs = list(
      required = c("rhs_survey_id", "HQA", "HMSRBB"),
      numeric = c("HQA", "HMSRBB"),
      identifiers = "rhs_survey_id"
    )
  )
}

local_source_modes <- function() {
  c(
    "External data only" = "external",
    "Use local data instead" = "local",
    "Combine external and local data" = "combine"
  )
}

normalise_local_source_mode <- function(mode, local_data = NULL) {
  if (is.null(mode) || length(mode) == 0L || is.na(mode[[1L]]) || !nzchar(mode[[1L]])) {
    return(if (source_data_available(local_data)) "local" else "external")
  }
  as.character(mode)[[1L]]
}

source_mode_uses_local <- function(mode) {
  mode %in% c("local", "combine")
}

source_mode_uses_external <- function(mode) {
  mode %in% c("external", "combine")
}

local_nonblank <- function(values) {
  values <- trimws(as.character(values))
  !is.na(values) & nzchar(values)
}

local_invalid_date <- function(values) {
  present <- local_nonblank(values)
  parsed <- suppressWarnings(as.Date(substr(as.character(values), 1L, 10L)))
  present & is.na(parsed)
}

local_invalid_numeric <- function(values) {
  present <- local_nonblank(values)
  parsed <- suppressWarnings(as.numeric(values))
  present & is.na(parsed)
}

local_invalid_integer <- function(values) {
  present <- local_nonblank(values)
  parsed <- suppressWarnings(as.numeric(values))
  present & (is.na(parsed) | parsed != floor(parsed))
}

validate_local_dataset <- function(data, dataset_type) {
  contracts <- local_dataset_contracts()
  if (!dataset_type %in% names(contracts)) {
    stop(sprintf("Unknown local dataset type: %s.", dataset_type), call. = FALSE)
  }

  if (is.null(data)) {
    return(list(status = "info", messages = "No local CSV uploaded yet.", data = NULL))
  }
  if (!is.data.frame(data) || nrow(data) == 0L) {
    return(list(status = "error", messages = "The local CSV contains no data rows.", data = data))
  }

  contract <- contracts[[dataset_type]]
  missing <- setdiff(contract$required, names(data))
  if (length(missing) > 0L) {
    return(list(
      status = "error",
      messages = sprintf("Missing required column(s): %s.", paste(missing, collapse = ", ")),
      data = data
    ))
  }

  errors <- character()
  warnings <- character()
  for (column in intersect(contract$identifiers, names(data))) {
    if (any(!local_nonblank(data[[column]]))) {
      errors <- c(errors, sprintf("%s contains blank identifier value(s).", column))
    }
    data[[column]] <- as.character(data[[column]])
  }

  if (!is.null(contract$at_least_one)) {
    available <- intersect(contract$at_least_one, names(data))
    has_supported_value <- length(available) > 0L && any(vapply(
      available,
      function(column) any(local_nonblank(data[[column]])),
      logical(1)
    ))
    if (!has_supported_value) {
      errors <- c(
        errors,
        sprintf(
          "At least one supported Biology index is required: %s.",
          paste(contract$at_least_one, collapse = ", ")
        )
      )
    }
  }

  type_checks <- list(
    date = local_invalid_date,
    numeric = local_invalid_numeric,
    integer = local_invalid_integer
  )
  for (type in names(type_checks)) {
    columns <- intersect(contract[[type]], names(data))
    invalid <- columns[vapply(
      columns,
      function(column) any(type_checks[[type]](data[[column]])),
      logical(1)
    )]
    if (length(invalid) > 0L) {
      errors <- c(
        errors,
        sprintf("Invalid %s value(s) in: %s.", type, paste(invalid, collapse = ", "))
      )
    }
  }

  if (length(errors) > 0L) {
    return(list(status = "error", messages = errors, data = data))
  }

  for (column in intersect(contract$numeric, names(data))) {
    data[[column]] <- suppressWarnings(as.numeric(data[[column]]))
  }
  for (column in intersect(contract$integer, names(data))) {
    data[[column]] <- suppressWarnings(as.integer(data[[column]]))
  }
  for (column in intersect(contract$date, names(data))) {
    if (!identical(column, "date_time")) {
      data[[column]] <- as.Date(substr(as.character(data[[column]]), 1L, 10L))
    }
  }

  if (identical(contract$allow_extra, FALSE)) {
    extra <- setdiff(names(data), contract$required)
    if (length(extra) > 0L) {
      warnings <- sprintf(
        "Ignored unsupported column(s): %s.",
        paste(extra, collapse = ", ")
      )
      data <- data[, contract$required, drop = FALSE]
    }
  }

  list(
    status = if (length(warnings) > 0L) "warning" else "success",
    messages = c(sprintf("Local %s CSV passed validation.", dataset_type), warnings),
    data = data
  )
}

validated_local_upload_data <- function(upload) {
  if (is.null(upload) || is.null(upload$validation) ||
      !upload$validation$status %in% c("success", "warning")) {
    return(NULL)
  }
  upload$data
}

source_data_available <- function(data) {
  is.data.frame(data) && nrow(data) > 0L
}

local_contract_key <- function(dataset_type) {
  key <- tolower(as.character(dataset_type)[[1L]])
  if (identical(key, "environmental")) {
    key <- "environment"
  }
  if (key %in% names(local_dataset_contracts())) key else NULL
}

align_source_to_local_contract <- function(data, dataset_type, source_label) {
  key <- local_contract_key(dataset_type)
  if (is.null(key) || !source_data_available(data)) {
    return(list(status = "success", data = data, messages = character()))
  }
  required <- local_dataset_contracts()[[key]]$required
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    return(list(
      status = "blocked",
      data = NULL,
      messages = sprintf(
        "%s %s data are missing required column(s): %s.",
        dataset_type,
        source_label,
        paste(missing, collapse = ", ")
      )
    ))
  }
  ordered <- c(required, setdiff(names(data), required))
  list(status = "success", data = data[, ordered, drop = FALSE], messages = character())
}

resolve_local_data_source <- function(external_data = NULL,
                                      local_data = NULL,
                                      mode = "external",
                                      dataset_type = "dataset") {
  mode <- as.character(mode)[[1L]]
  if (!mode %in% unname(local_source_modes())) {
    stop(sprintf("Unsupported %s source mode: %s.", dataset_type, mode), call. = FALSE)
  }

  has_external <- source_data_available(external_data)
  has_local <- source_data_available(local_data)
  required_sources_present <- switch(
    mode,
    external = has_external,
    local = has_local,
    combine = has_external && has_local
  )
  if (!required_sources_present) {
    needed <- switch(
      mode,
      external = "external data",
      local = "a valid local CSV",
      combine = "both external data and a valid local CSV"
    )
    return(list(
      status = "blocked",
      messages = sprintf("%s requires %s.", dataset_type, needed),
      data = NULL,
      provenance = list(
        mode = mode,
        external_rows = if (has_external) nrow(external_data) else 0L,
        local_rows = if (has_local) nrow(local_data) else 0L,
        output_rows = 0L
      )
    ))
  }

  if (identical(mode, "combine")) {
    aligned_external <- align_source_to_local_contract(external_data, dataset_type, "external")
    aligned_local <- align_source_to_local_contract(local_data, dataset_type, "local")
    alignment_messages <- c(aligned_external$messages, aligned_local$messages)
    if (!identical(aligned_external$status, "success") ||
        !identical(aligned_local$status, "success")) {
      return(list(
        status = "blocked",
        messages = alignment_messages,
        data = NULL,
        provenance = list(
          mode = mode,
          external_rows = nrow(external_data),
          local_rows = nrow(local_data),
          output_rows = 0L
        )
      ))
    }
    external_data <- aligned_external$data
    local_data <- aligned_local$data
  }

  selected <- switch(
    mode,
    external = external_data,
    local = local_data,
    combine = dplyr::bind_rows(external_data, local_data)
  )

  list(
    status = "success",
    messages = sprintf("Resolved %s using source mode '%s'.", dataset_type, mode),
    data = selected,
    provenance = list(
      mode = mode,
      external_rows = if (has_external) nrow(external_data) else 0L,
      local_rows = if (has_local) nrow(local_data) else 0L,
      output_rows = nrow(selected)
    )
  )
}
