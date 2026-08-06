# workbook_validation_helpers.R
# WK8-04 / DC-11: validation checkpoints for canonical workbook sheets and
# same-schema CSV uploads. The helpers validate names and order; they do not
# migrate legacy fields or silently bind incompatible data.

dc11_sheet_schemas <- function() {
  list(
    site_mapping = c(
      "biol_site_id", "biol_easting", "biol_northing",
      "flow_site_id", "flow_easting", "flow_northing", "flow_input",
      "wq_site_id", "wq_easting", "wq_northing",
      "rhs_survey_id", "rhs_easting", "rhs_northing"
    ),
    biology_samples = c(
      "biol_site_id", "sample_id", "date", "sampling_year", "season", "month",
      "sample_type", "sample_method",
      "WHPT_ASPT", "WHPT_NTAXA", "LIFE_F", "PSI_F", "notes"
    ),
    environmental_site_data = c(
      "biol_site_id", "WATER_BODY", "NGR_PREFIX", "EASTING", "NORTHING",
      "WFD_WATERBODY_ID", "ALTITUDE", "SLOPE", "DIST_FROM_SOURCE",
      "DISCHARGE", "WIDTH", "DEPTH", "BOULDERS_COBBLES", "PEBBLES_GRAVEL",
      "SAND", "SILT_CLAY", "ALKALINITY", "CONDUCTIVITY",
      "TOTAL_HARDNESS", "CALCIUM", "notes"
    ),
    flow_daily = c("flow_site_id", "date", "flow"),
    wq_long_standard = c(
      "wq_site_id", "wq_site_name", "date_time", "det_id", "determinand",
      "result", "unit", "qualifier", "observation", "notes"
    ),
    rhs_summary = c(
      "rhs_survey_id", "biol_site_id", "survey_date", "HMSRBB", "HMS.Class",
      "HQA", "HQA.Adjusted", "Hms.Poaching.Sub.Score",
      "Bed.Material.Description", "Predominant.Flow.Type", "habitat_notes"
    ),
    joined_dataset_optional = c(
      "biol_site_id", "sample_id", "date", "flow_site_id", "wq_site_id", "rhs_survey_id",
      "sampling_year",
      "WHPT_ASPT_OE", "WHPT_NTAXA_OE", "LIFE_F_OE", "PSI_OE",
      "Q10_lag0", "Q10z_lag0", "Q10_lag1", "Q10z_lag1",
      "Q95_lag0", "Q95z_lag0", "Q95_lag1", "Q95z_lag1",
      "flow_window_start_lag0", "flow_window_end_lag0", "flow_window_duration_lag0",
      "flow_window_start_lag1", "flow_window_end_lag1", "flow_window_duration_lag1",
      "wq_window_start", "wq_window_end", "wq_window_duration_years",
      "orthophosphate_mean", "orthophosphate_record_count",
      "ammonia_p90", "ammonia_record_count",
      "dissolved_oxygen_p10", "dissolved_oxygen_record_count",
      "HMSRBB", "HQA", "matching_notes"
    )
  )
}

dc11_metadata_sheets <- function() {
  c("README", "field_dictionary", "validation_rules")
}

dc11_checkpoint_issue <- function(sheet, severity, code, message) {
  data.frame(
    sheet = sheet,
    severity = severity,
    code = code,
    message = message,
    stringsAsFactors = FALSE
  )
}

dc11_empty_issues <- function() {
  data.frame(
    sheet = character(),
    severity = character(),
    code = character(),
    message = character(),
    stringsAsFactors = FALSE
  )
}

dc11_status_from_issues <- function(issues) {
  if (is.null(issues) || nrow(issues) == 0) {
    return("success")
  }
  if (any(issues$severity == "error")) {
    return("error")
  }
  if (any(issues$severity == "warning")) {
    return("warning")
  }
  "success"
}

dc11_nonblank <- function(values) {
  values <- trimws(as.character(values))
  !is.na(values) & nzchar(values)
}

dc11_has_nonblank_column <- function(data, column) {
  column %in% names(data) && any(dc11_nonblank(data[[column]]))
}

dc11_invalid_date <- function(values) {
  present <- dc11_nonblank(values)
  parsed <- suppressWarnings(as.Date(as.character(values)))
  present & is.na(parsed)
}

dc11_invalid_integer <- function(values) {
  present <- dc11_nonblank(values)
  numeric <- suppressWarnings(as.numeric(values))
  present & (is.na(numeric) | numeric != floor(numeric))
}

dc11_invalid_numeric <- function(values) {
  present <- dc11_nonblank(values)
  numeric <- suppressWarnings(as.numeric(values))
  present & is.na(numeric)
}

dc11_add_type_issue <- function(issues, data, sheet_name, columns, type) {
  invalid_fn <- switch(
    type,
    date = dc11_invalid_date,
    integer = dc11_invalid_integer,
    numeric = dc11_invalid_numeric
  )
  present_columns <- intersect(columns, names(data))
  invalid_columns <- present_columns[
    vapply(present_columns, function(column) {
      any(invalid_fn(data[[column]]), na.rm = TRUE)
    }, logical(1))
  ]
  if (length(invalid_columns) == 0) {
    return(issues)
  }
  rbind(issues, dc11_checkpoint_issue(
    sheet_name,
    "error",
    paste0("invalid_", type),
    paste0(
      "Column(s) contain invalid ",
      type,
      " value(s): ",
      paste(invalid_columns, collapse = ", "),
      "."
    )
  ))
}

validate_dc11_headers <- function(data, sheet_name) {
  schemas <- dc11_sheet_schemas()
  if (!sheet_name %in% names(schemas)) {
    return(dc11_checkpoint_issue(
      sheet_name,
      "error",
      "unknown_sheet",
      paste0("Unknown DC-11 sheet/dataset: ", sheet_name, ".")
    ))
  }
  if (is.null(data)) {
    return(dc11_checkpoint_issue(
      sheet_name,
      "info",
      "not_uploaded",
      paste0(sheet_name, " was not uploaded.")
    ))
  }

  expected <- schemas[[sheet_name]]
  actual <- names(data)
  issues <- dc11_empty_issues()
  missing <- setdiff(expected, actual)
  unexpected <- setdiff(actual, expected)
  if (length(missing) > 0) {
    issues <- rbind(issues, dc11_checkpoint_issue(
      sheet_name,
      "error",
      "missing_columns",
      paste0("Missing required DC-11 column(s): ", paste(missing, collapse = ", "), ".")
    ))
  }
  if (length(unexpected) > 0) {
    issues <- rbind(issues, dc11_checkpoint_issue(
      sheet_name,
      "error",
      "unexpected_columns",
      paste0("Unexpected column(s) not allowed by DC-11: ", paste(unexpected, collapse = ", "), ".")
    ))
  }
  if (identical(sort(actual), sort(expected)) && !identical(actual, expected)) {
    issues <- rbind(issues, dc11_checkpoint_issue(
      sheet_name,
      "error",
      "column_order",
      "Column names are present but not in the frozen DC-11 order."
    ))
  }
  issues
}

validate_dc11_sheet_rules <- function(data, sheet_name) {
  issues <- dc11_empty_issues()
  if (is.null(data)) {
    return(issues)
  }
  if (nrow(data) == 0) {
    return(rbind(issues, dc11_checkpoint_issue(
      sheet_name,
      "info",
      "header_only",
      paste0(sheet_name, " contains headers only and no data rows.")
    )))
  }

  if (identical(sheet_name, "site_mapping")) {
    invalid_flow <- dc11_nonblank(data$flow_input) &
      !toupper(trimws(as.character(data$flow_input))) %in% c("HDE", "NRFA")
    if (any(invalid_flow, na.rm = TRUE)) {
      issues <- rbind(issues, dc11_checkpoint_issue(
        sheet_name,
        "error",
        "invalid_flow_input",
        "flow_input must be blank, HDE, or NRFA in site_mapping."
      ))
    }
    issues <- dc11_add_type_issue(
      issues,
      data,
      sheet_name,
      c("biol_easting", "biol_northing", "flow_easting", "flow_northing", "wq_easting", "wq_northing", "rhs_easting", "rhs_northing"),
      "numeric"
    )
  }

  if (identical(sheet_name, "biology_samples")) {
    prohibited <- grep("(_OE$|O:E|OE_RATIO)", names(data), value = TRUE, ignore.case = TRUE)
    if (length(prohibited) > 0) {
      issues <- rbind(issues, dc11_checkpoint_issue(
        sheet_name,
        "error",
        "oe_uploaded",
        paste0("O:E columns must not be uploaded in biology_samples: ", paste(prohibited, collapse = ", "), ".")
      ))
    }
    if ("sample_year" %in% names(data)) {
      issues <- rbind(issues, dc11_checkpoint_issue(
        sheet_name,
        "error",
        "sample_year_alias",
        "sample_year is not accepted; use the DC-11 column sampling_year."
      ))
    }
    index_cols <- c("WHPT_ASPT", "WHPT_NTAXA", "LIFE_F", "PSI_F")
    has_index <- Reduce(`|`, lapply(index_cols, function(column) dc11_nonblank(data[[column]])))
    if (!any(has_index)) {
      issues <- rbind(issues, dc11_checkpoint_issue(
        sheet_name,
        "error",
        "missing_biology_index",
        "At least one supported biology index value is required: WHPT_ASPT, WHPT_NTAXA, LIFE_F, or PSI_F."
      ))
    } else if (any(!has_index)) {
      issues <- rbind(issues, dc11_checkpoint_issue(
        sheet_name,
        "warning",
        "row_missing_biology_index",
        "Some biology rows have no supported index value."
      ))
    }
    issues <- dc11_add_type_issue(issues, data, sheet_name, "date", "date")
    issues <- dc11_add_type_issue(issues, data, sheet_name, c("sampling_year", "month"), "integer")
    issues <- dc11_add_type_issue(issues, data, sheet_name, index_cols, "numeric")
  }

  if (identical(sheet_name, "environmental_site_data")) {
    if ("NGR_prefix" %in% names(data)) {
      issues <- rbind(issues, dc11_checkpoint_issue(
        sheet_name,
        "error",
        "ngr_prefix_case",
        "NGR_prefix is not accepted; use exact DC-11 column NGR_PREFIX."
      ))
    }
    alkalinity_blank <- !dc11_nonblank(data$ALKALINITY)
    proxy_available <- dc11_nonblank(data$CONDUCTIVITY) |
      dc11_nonblank(data$TOTAL_HARDNESS) |
      dc11_nonblank(data$CALCIUM)
    if (any(alkalinity_blank & !proxy_available, na.rm = TRUE)) {
      issues <- rbind(issues, dc11_checkpoint_issue(
        sheet_name,
        "error",
        "alkalinity_proxy_missing",
        "Some rows have blank ALKALINITY and no conductivity/hardness/calcium proxy value, so predict_indices() cannot safely derive alkalinity."
      ))
    }
    issues <- dc11_add_type_issue(
      issues,
      data,
      sheet_name,
      c("EASTING", "NORTHING", "ALTITUDE", "SLOPE", "DIST_FROM_SOURCE", "DISCHARGE", "WIDTH", "DEPTH", "BOULDERS_COBBLES", "PEBBLES_GRAVEL", "SAND", "SILT_CLAY", "ALKALINITY", "CONDUCTIVITY", "TOTAL_HARDNESS", "CALCIUM"),
      "numeric"
    )
  }

  if (identical(sheet_name, "flow_daily")) {
    if ("flow_input" %in% names(data)) {
      issues <- rbind(issues, dc11_checkpoint_issue(
        sheet_name,
        "error",
        "flow_input_wrong_sheet",
        "flow_input is not allowed in flow_daily; it belongs only to site_mapping."
      ))
    }
    issues <- dc11_add_type_issue(issues, data, sheet_name, "date", "date")
    issues <- dc11_add_type_issue(issues, data, sheet_name, "flow", "numeric")
  }

  if (identical(sheet_name, "wq_long_standard")) {
    forbidden <- intersect(c("area", "easting", "northing", "wq_area"), names(data))
    if (length(forbidden) > 0) {
      issues <- rbind(issues, dc11_checkpoint_issue(
        sheet_name,
        "error",
        "site_fields_in_wq",
        paste0("Site-level field(s) do not belong in wq_long_standard: ", paste(forbidden, collapse = ", "), ".")
      ))
    }
    issues <- dc11_add_type_issue(issues, data, sheet_name, "date_time", "date")
    issues <- dc11_add_type_issue(issues, data, sheet_name, "result", "numeric")
  }

  if (identical(sheet_name, "rhs_summary")) {
    issues <- dc11_add_type_issue(issues, data, sheet_name, "survey_date", "date")
    issues <- dc11_add_type_issue(issues, data, sheet_name, c("HMSRBB", "HQA", "HQA.Adjusted", "Hms.Poaching.Sub.Score"), "numeric")
  }

  if (identical(sheet_name, "joined_dataset_optional")) {
    issues <- dc11_add_type_issue(
      issues,
      data,
      sheet_name,
      c("date", "flow_window_start_lag0", "flow_window_end_lag0", "flow_window_start_lag1", "flow_window_end_lag1", "wq_window_start", "wq_window_end"),
      "date"
    )
    issues <- dc11_add_type_issue(issues, data, sheet_name, "sampling_year", "integer")
    issues <- dc11_add_type_issue(
      issues,
      data,
      sheet_name,
      c("WHPT_ASPT_OE", "WHPT_NTAXA_OE", "LIFE_F_OE", "PSI_OE", "Q10_lag0", "Q10z_lag0", "Q10_lag1", "Q10z_lag1", "Q95_lag0", "Q95z_lag0", "Q95_lag1", "Q95z_lag1", "flow_window_duration_lag0", "flow_window_duration_lag1", "wq_window_duration_years", "orthophosphate_mean", "orthophosphate_record_count", "ammonia_p90", "ammonia_record_count", "dissolved_oxygen_p10", "dissolved_oxygen_record_count", "HMSRBB", "HQA"),
      "numeric"
    )
  }

  issues
}

validate_dc11_dataset <- function(data, sheet_name) {
  header_issues <- validate_dc11_headers(data, sheet_name)
  missing_header <- any(header_issues$code == "missing_columns")
  if (missing_header || is.null(data)) {
    issues <- header_issues
  } else {
    issues <- rbind(header_issues, validate_dc11_sheet_rules(data, sheet_name))
  }
  status <- dc11_status_from_issues(issues)
  messages <- if (nrow(issues) == 0) {
    paste0(sheet_name, " passed DC-11 validation.")
  } else {
    issues$message
  }
  list(status = status, messages = messages, issues = issues)
}

validate_dc11_workbook <- function(sheets) {
  schemas <- dc11_sheet_schemas()
  if (is.null(sheets) || length(sheets) == 0) {
    return(list(
      status = "error",
      messages = "No workbook sheets were provided for validation.",
      sheet_results = list(),
      issues = dc11_checkpoint_issue("workbook", "error", "empty_workbook", "No workbook sheets were provided.")
    ))
  }

  sheet_results <- lapply(names(schemas), function(sheet_name) {
    validate_dc11_dataset(sheets[[sheet_name]], sheet_name)
  })
  names(sheet_results) <- names(schemas)

  provided_unknown <- setdiff(names(sheets), c(names(schemas), dc11_metadata_sheets()))
  issues <- do.call(rbind, lapply(sheet_results, `[[`, "issues"))
  if (length(provided_unknown) > 0) {
    issues <- rbind(issues, dc11_checkpoint_issue(
      "workbook",
      "error",
      "unknown_sheet",
      paste0("Unknown workbook sheet(s): ", paste(provided_unknown, collapse = ", "), ".")
    ))
  }

  status <- dc11_status_from_issues(issues)
  messages <- if (nrow(issues) == 0) {
    "Workbook passed DC-11 validation."
  } else {
    issues$message
  }
  list(status = status, messages = messages, sheet_results = sheet_results, issues = issues)
}

read_dc11_workbook <- function(path) {
  if (!is.character(path) || length(path) != 1L || is.na(path) || !file.exists(path)) {
    return(list(
      status = "error",
      messages = "DC-11 workbook file was not found.",
      sheets = list(),
      issues = dc11_checkpoint_issue("workbook", "error", "file_not_found", "DC-11 workbook file was not found.")
    ))
  }

  if (!requireNamespace("readxl", quietly = TRUE)) {
    return(list(
      status = "error",
      messages = "The readxl package is required to read DC-11 Excel workbooks.",
      sheets = list(),
      issues = dc11_checkpoint_issue("workbook", "error", "readxl_missing", "The readxl package is required to read DC-11 Excel workbooks.")
    ))
  }

  sheet_names <- tryCatch(
    readxl::excel_sheets(path),
    error = function(error) error
  )
  if (inherits(sheet_names, "error")) {
    return(list(
      status = "error",
      messages = "The uploaded file could not be read as an Excel workbook.",
      sheets = list(),
      issues = dc11_checkpoint_issue("workbook", "error", "workbook_read_error", "The uploaded file could not be read as an Excel workbook.")
    ))
  }

  sheets <- list()
  read_issues <- dc11_empty_issues()
  for (sheet_name in sheet_names) {
    sheet_data <- tryCatch(
      readxl::read_excel(
        path,
        sheet = sheet_name,
        col_types = "text",
        .name_repair = "minimal"
      ),
      error = function(error) error
    )
    if (inherits(sheet_data, "error")) {
      read_issues <- rbind(read_issues, dc11_checkpoint_issue(
        sheet_name,
        "error",
        "sheet_read_error",
        paste0("Sheet could not be read from workbook: ", sheet_name, ".")
      ))
    } else {
      sheets[[sheet_name]] <- as.data.frame(sheet_data, stringsAsFactors = FALSE)
    }
  }

  status <- dc11_status_from_issues(read_issues)
  messages <- if (nrow(read_issues) == 0) {
    paste0("Read ", length(sheets), " workbook sheet(s).")
  } else {
    read_issues$message
  }

  list(status = status, messages = messages, sheets = sheets, issues = read_issues)
}

validate_dc11_workbook_file <- function(path) {
  read_result <- read_dc11_workbook(path)
  if (!identical(read_result$status, "success")) {
    return(list(
      status = read_result$status,
      messages = read_result$messages,
      sheets = read_result$sheets,
      sheet_results = list(),
      issues = read_result$issues
    ))
  }

  validation <- validate_dc11_workbook(read_result$sheets)
  validation$issues <- rbind(read_result$issues, validation$issues)
  validation$status <- dc11_status_from_issues(validation$issues)
  validation$messages <- if (nrow(validation$issues) == 0) {
    "Workbook passed DC-11 validation."
  } else {
    validation$issues$message
  }
  validation$sheets <- read_result$sheets
  validation
}
