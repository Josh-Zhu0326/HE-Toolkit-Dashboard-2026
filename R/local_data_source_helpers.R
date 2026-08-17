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
        "ALKALINITY", "CONDUCTIVITY", "TOTAL_HARDNESS", "CALCIUM",
        "MIN_SAMPLE_DATE", "MAX_SAMPLE_DATE",
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
      conditional_proxy = list(
        target = "ALKALINITY",
        alternatives = c("CONDUCTIVITY", "TOTAL_HARDNESS", "CALCIUM")
      ),
      identifiers = "biol_site_id"
    ),
    flow = list(
      required = c("flow_site_id", "date", "flow"),
      date = "date",
      numeric = "flow",
      identifiers = "flow_site_id"
    ),
    wq = list(
      required = c(
        "wq_site_id", "wq_site_name", "date_time", "det_id", "determinand",
        "result", "unit", "qualifier", "observation", "notes"
      ),
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

local_dataset_template_data <- function(dataset_type) {
  examples <- list(
    biology = list(
      biol_site_id = "B01", SAMPLE_ID = "S001", SAMPLE_DATE = "2024-05-01",
      WHPT_ASPT = "6.1", WHPT_N_TAXA = "", LIFE_FAMILY_INDEX = "",
      PSI_FAMILY_SCORE = "", Month = "5", Year = "2024", Season = "Spring"
    ),
    environment = list(
      biol_site_id = "B01", NGR_10_FIG = "AA00100010", ALTITUDE = "100",
      SLOPE = "1.2", DIST_FROM_SOURCE = "10", DISCHARGE = "2.5",
      WIDTH = "4", DEPTH = "0.5", BOULDERS_COBBLES = "20",
      PEBBLES_GRAVEL = "30", SAND = "25", SILT_CLAY = "25",
      ALKALINITY = "75", CONDUCTIVITY = "100",
      TOTAL_HARDNESS = "", CALCIUM = "",
      MIN_SAMPLE_DATE = "2024-01-01", MAX_SAMPLE_DATE = "2024-12-31",
      COUNT_OF_SAMPLES = "3"
    ),
    flow = list(flow_site_id = "27090", date = "2024-05-01", flow = "2.35"),
    wq = list(
      wq_site_id = "SW-A4070115", wq_site_name = "Example WQ site",
      date_time = "2024-05-01", det_id = "0180",
      determinand = "Orthophosphate reactive as P", result = "0.07",
      unit = "mg/L", qualifier = "", observation = "", notes = ""
    ),
    rhs = list(rhs_survey_id = "RHS001", HQA = "60", HMSRBB = "22")
  )
  if (!dataset_type %in% names(examples)) {
    stop(sprintf("Unknown local dataset type: %s.", dataset_type), call. = FALSE)
  }

  contract <- local_dataset_contracts()[[dataset_type]]
  template_fields <- contract$required
  example <- examples[[dataset_type]]
  missing <- setdiff(template_fields, names(example))
  if (length(missing) > 0L) {
    stop(
      sprintf(
        "Local %s template is missing example field(s): %s.",
        dataset_type,
        paste(missing, collapse = ", ")
      ),
      call. = FALSE
    )
  }
  as.data.frame(example[template_fields], stringsAsFactors = FALSE, check.names = FALSE)
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
  expected <- contract$required
  actual <- names(data)
  missing <- setdiff(expected, actual)
  unexpected <- setdiff(actual, expected)
  header_errors <- character()
  if (length(missing) > 0L) {
    header_errors <- c(
      header_errors,
      sprintf("Missing required column(s): %s.", paste(missing, collapse = ", "))
    )
  }
  if (length(unexpected) > 0L) {
    header_errors <- c(
      header_errors,
      sprintf("Unexpected column(s): %s.", paste(unexpected, collapse = ", "))
    )
  }
  if (length(missing) == 0L && length(unexpected) == 0L &&
      !identical(actual, expected)) {
    header_errors <- c(
      header_errors,
      sprintf("Columns are in the wrong order. Expected: %s.", paste(expected, collapse = ", "))
    )
  }
  if (length(header_errors) > 0L) {
    return(list(
      status = "error",
      messages = header_errors,
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

  if (!is.null(contract$conditional_proxy)) {
    proxy <- contract$conditional_proxy
    target_missing <- !local_nonblank(data[[proxy$target]])
    proxy_available <- rep(FALSE, nrow(data))
    for (column in intersect(proxy$alternatives, names(data))) {
      proxy_available <- proxy_available | local_nonblank(data[[column]])
    }
    invalid_rows <- which(target_missing & !proxy_available)
    if (length(invalid_rows) > 0L) {
      errors <- c(
        errors,
        sprintf(
          "%s is blank in row(s) %s; provide at least one of %s for those rows.",
          proxy$target,
          paste(invalid_rows, collapse = ", "),
          paste(proxy$alternatives, collapse = ", ")
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

source_resolution_provenance <- function(data) {
  attr(data, "source_provenance", exact = TRUE)
}

set_source_resolution_provenance <- function(data, provenance) {
  attr(data, "source_provenance") <- provenance
  data
}

summarise_source_resolution <- function(provenance, dataset_type = "Data") {
  if (is.null(provenance)) {
    return(sprintf("Resolved the current %s source.", dataset_type))
  }
  sprintf(
    "Resolved %d %s record(s) using '%s' mode (%d external, %d local).",
    provenance$output_rows,
    dataset_type,
    provenance$mode,
    provenance$external_rows,
    provenance$local_rows
  )
}

local_contract_key <- function(dataset_type) {
  key <- tolower(as.character(dataset_type)[[1L]])
  if (identical(key, "environmental")) {
    key <- "environment"
  }
  if (key %in% names(local_dataset_contracts())) key else NULL
}

canonical_source_fields <- function(dataset_type) {
  key <- local_contract_key(dataset_type)
  if (is.null(key)) {
    return(NULL)
  }
  fields <- local_dataset_contracts()[[key]]$required
  if (key %in% c("wq", "rhs")) {
    fields <- c("biol_site_id", fields)
  }
  fields
}

external_contract_values_equal <- function(left, right) {
  left <- as.character(left)
  right <- as.character(right)
  identical(length(left), length(right)) && all(
    (is.na(left) & is.na(right)) | (!is.na(left) & !is.na(right) & left == right)
  )
}

adapt_external_source_to_local_contract <- function(data, dataset_type) {
  key <- local_contract_key(dataset_type)
  expected <- canonical_source_fields(dataset_type)
  if (is.null(key) || !source_data_available(data)) {
    return(list(status = "success", data = data, messages = character(), dropped_fields = character()))
  }

  adapted <- data
  messages <- character()

  if (identical(key, "rhs")) {
    if ("Survey.ID" %in% names(adapted)) {
      if ("rhs_survey_id" %in% names(adapted) &&
          !external_contract_values_equal(adapted$rhs_survey_id, adapted$Survey.ID)) {
        return(list(
          status = "blocked",
          data = NULL,
          messages = "RHS external data contain conflicting Survey.ID and rhs_survey_id values.",
          dropped_fields = character()
        ))
      }
      if (!"rhs_survey_id" %in% names(adapted)) {
        names(adapted)[names(adapted) == "Survey.ID"] <- "rhs_survey_id"
      } else {
        adapted$Survey.ID <- NULL
      }
    }

    if ("HMS.Score" %in% names(adapted)) {
      if ("HMSRBB" %in% names(adapted) &&
          !external_contract_values_equal(adapted$HMSRBB, adapted$HMS.Score)) {
        return(list(
          status = "blocked",
          data = NULL,
          messages = "RHS external data contain conflicting HMS.Score and HMSRBB values.",
          dropped_fields = character()
        ))
      }
      if (!"HMSRBB" %in% names(adapted)) {
        names(adapted)[names(adapted) == "HMS.Score"] <- "HMSRBB"
        messages <- c(messages, "Normalised external RHS HMS.Score to HMSRBB.")
      } else {
        adapted$HMS.Score <- NULL
        messages <- c(messages, "Removed duplicate external RHS HMS.Score after confirming it matches HMSRBB.")
      }
    }
  }

  if (identical(key, "wq") && !"notes" %in% names(adapted)) {
    adapted$notes <- rep(NA_character_, nrow(adapted))
  }

  missing <- setdiff(expected, names(adapted))
  if (length(missing) > 0L) {
    return(list(
      status = "blocked",
      data = NULL,
      messages = sprintf(
        "%s external data cannot be converted to the canonical contract (missing: %s).",
        dataset_type,
        paste(missing, collapse = ", ")
      ),
      dropped_fields = character()
    ))
  }

  dropped_fields <- setdiff(names(adapted), expected)
  adapted <- adapted[, expected, drop = FALSE]
  list(
    status = "success",
    data = adapted,
    messages = messages,
    dropped_fields = dropped_fields
  )
}

align_source_to_local_contract <- function(data, dataset_type, source_label) {
  key <- local_contract_key(dataset_type)
  if (is.null(key) || !source_data_available(data)) {
    return(list(status = "success", data = data, messages = character()))
  }
  expected <- canonical_source_fields(dataset_type)
  actual <- names(data)
  if (!identical(actual, expected)) {
    missing <- setdiff(expected, actual)
    unexpected <- setdiff(actual, expected)
    details <- c(
      if (length(missing) > 0L) sprintf("missing: %s", paste(missing, collapse = ", ")),
      if (length(unexpected) > 0L) sprintf("unexpected: %s", paste(unexpected, collapse = ", ")),
      if (setequal(actual, expected)) "column order differs"
    )
    return(list(
      status = "blocked",
      data = NULL,
      messages = sprintf(
        "%s %s data do not match the canonical column contract (%s).",
        dataset_type,
        source_label,
        paste(details, collapse = "; ")
      )
    ))
  }
  list(status = "success", data = data, messages = character())
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
    adapted_external <- adapt_external_source_to_local_contract(external_data, dataset_type)
    if (!identical(adapted_external$status, "success")) {
      return(list(
        status = "blocked",
        messages = adapted_external$messages,
        data = NULL,
        provenance = list(
          mode = mode,
          external_rows = nrow(external_data),
          local_rows = nrow(local_data),
          output_rows = 0L
        )
      ))
    }
    aligned_external <- align_source_to_local_contract(adapted_external$data, dataset_type, "external")
    aligned_local <- align_source_to_local_contract(local_data, dataset_type, "local")
    alignment_messages <- c(
      adapted_external$messages,
      aligned_external$messages,
      aligned_local$messages
    )
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

  provenance <- list(
    mode = mode,
    external_rows = if (has_external) nrow(external_data) else 0L,
    local_rows = if (has_local) nrow(local_data) else 0L,
    output_rows = nrow(selected)
  )
  if (identical(mode, "combine")) {
    provenance$external_dropped_fields <- adapted_external$dropped_fields
    provenance$external_adapter_messages <- adapted_external$messages
  }
  selected <- set_source_resolution_provenance(selected, provenance)

  resolution_messages <- sprintf("Resolved %s using source mode '%s'.", dataset_type, mode)
  if (identical(mode, "combine")) {
    resolution_messages <- c(resolution_messages, adapted_external$messages)
  }

  list(
    status = "success",
    messages = resolution_messages,
    data = selected,
    provenance = provenance
  )
}
