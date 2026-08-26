# Data Contract v2.0 validation for the five primary local CSV inputs.
# Keep this independent from the historical DC-11 workbook compatibility layer.

local_csv_v2_contracts <- function() {
  list(
    biology = list(
      fields = c(
        "biol_site_id", "SAMPLE_ID", "SAMPLE_DATE", "WHPT_ASPT",
        "WHPT_N_TAXA", "LIFE_FAMILY_INDEX", "PSI_FAMILY_SCORE",
        "Month", "Year", "Season"
      ),
      nonblank = c("biol_site_id", "SAMPLE_ID", "SAMPLE_DATE"),
      date = "SAMPLE_DATE",
      integer = c("Month", "Year"),
      numeric = c(
        "WHPT_ASPT", "WHPT_N_TAXA", "LIFE_FAMILY_INDEX",
        "PSI_FAMILY_SCORE"
      ),
      rename = c(
        SAMPLE_ID = "sample_id",
        SAMPLE_DATE = "date",
        LIFE_FAMILY_INDEX = "LIFE_F",
        PSI_FAMILY_SCORE = "PSI_F",
        Month = "month",
        Year = "sampling_year",
        Season = "season"
      )
    ),
    environmental = list(
      fields = c(
        "biol_site_id", "NGR_10_FIG", "ALTITUDE", "SLOPE",
        "DIST_FROM_SOURCE", "DISCHARGE", "WIDTH", "DEPTH",
        "BOULDERS_COBBLES", "PEBBLES_GRAVEL", "SAND", "SILT_CLAY",
        "ALKALINITY", "CONDUCTIVITY", "MIN_SAMPLE_DATE",
        "MAX_SAMPLE_DATE", "COUNT_OF_SAMPLES"
      ),
      nonblank = c("biol_site_id", "NGR_10_FIG"),
      date = c("MIN_SAMPLE_DATE", "MAX_SAMPLE_DATE"),
      integer = "COUNT_OF_SAMPLES",
      numeric = c(
        "ALTITUDE", "SLOPE", "DIST_FROM_SOURCE", "DISCHARGE", "WIDTH",
        "DEPTH", "BOULDERS_COBBLES", "PEBBLES_GRAVEL", "SAND",
        "SILT_CLAY", "ALKALINITY", "CONDUCTIVITY"
      ),
      rename = character()
    ),
    flow = list(
      fields = c("flow_site_id", "date", "flow"),
      nonblank = c("flow_site_id", "date", "flow"),
      date = "date",
      integer = character(),
      numeric = "flow",
      rename = character()
    ),
    wq = list(
      fields = c("wq_site_id", "date_time", "det_id", "qualifier", "result"),
      nonblank = c("wq_site_id", "date_time", "det_id", "result"),
      date = "date_time",
      integer = character(),
      numeric = "result",
      rename = character()
    ),
    rhs = list(
      fields = c("rhs_survey_id", "HQA", "HMSRBB"),
      nonblank = c("rhs_survey_id"),
      date = character(),
      integer = character(),
      numeric = c("HQA", "HMSRBB"),
      rename = character()
    )
  )
}

local_csv_v2_types <- function() {
  names(local_csv_v2_contracts())
}

local_csv_v2_contract <- function(data_type) {
  if (!is.character(data_type) || length(data_type) != 1L ||
      is.na(data_type) || !data_type %in% local_csv_v2_types()) {
    stop(
      paste0(
        "Unknown local CSV data type. Use one of: ",
        paste(local_csv_v2_types(), collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }
  local_csv_v2_contracts()[[data_type]]
}

local_csv_v2_empty_issues <- function() {
  data.frame(
    data_type = character(),
    severity = character(),
    code = character(),
    field = character(),
    message = character(),
    stringsAsFactors = FALSE
  )
}

local_csv_v2_issue <- function(data_type, severity, code, message, field = NA_character_) {
  data.frame(
    data_type = data_type,
    severity = severity,
    code = code,
    field = field,
    message = message,
    stringsAsFactors = FALSE
  )
}

local_csv_v2_status <- function(issues) {
  if (nrow(issues) == 0L || !any(issues$severity %in% c("error", "warning"))) {
    return("success")
  }
  if (any(issues$severity == "error")) "error" else "warning"
}

local_csv_v2_nonblank <- function(values) {
  values <- trimws(as.character(values))
  !is.na(values) & nzchar(values)
}

local_csv_v2_invalid_date <- function(values) {
  present <- local_csv_v2_nonblank(values)
  parsed <- suppressWarnings(as.POSIXct(as.character(values), tz = "UTC"))
  present & is.na(parsed)
}

local_csv_v2_invalid_numeric <- function(values) {
  present <- local_csv_v2_nonblank(values)
  parsed <- suppressWarnings(as.numeric(values))
  present & (!is.finite(parsed) | is.na(parsed))
}

local_csv_v2_invalid_integer <- function(values) {
  present <- local_csv_v2_nonblank(values)
  parsed <- suppressWarnings(as.numeric(values))
  present & (!is.finite(parsed) | is.na(parsed) | parsed != floor(parsed))
}

local_csv_v2_add_field_issues <- function(
    issues,
    data,
    data_type,
    fields,
    invalid,
    code,
    label) {
  for (field in intersect(fields, names(data))) {
    invalid_rows <- which(invalid(data[[field]]))
    if (length(invalid_rows) > 0L) {
      issues <- rbind(issues, local_csv_v2_issue(
        data_type,
        "error",
        code,
        sprintf(
          "%s contains invalid %s value(s) in row(s): %s.",
          field,
          label,
          paste(utils::head(invalid_rows, 10L), collapse = ", ")
        ),
        field
      ))
    }
  }
  issues
}

local_csv_v2_prohibited_fields <- function(data_type, fields) {
  if (!identical(data_type, "biology")) {
    return(character())
  }
  fields[grepl("(^|_)(OE|O_E|O:E)($|_)", fields, ignore.case = TRUE)]
}

validate_local_csv_v2 <- function(data, data_type) {
  contract <- local_csv_v2_contract(data_type)
  issues <- local_csv_v2_empty_issues()

  if (is.null(data) || !is.data.frame(data)) {
    issues <- rbind(issues, local_csv_v2_issue(
      data_type,
      "error",
      "unreadable_csv",
      "The CSV could not be read as a table."
    ))
    return(list(
      status = "error",
      messages = issues$message,
      issues = issues,
      data = NULL
    ))
  }

  actual_fields <- names(data)
  if (is.null(actual_fields) || anyDuplicated(actual_fields)) {
    duplicate_fields <- unique(actual_fields[duplicated(actual_fields)])
    issues <- rbind(issues, local_csv_v2_issue(
      data_type,
      "error",
      "duplicate_headers",
      paste0(
        "Duplicate CSV header(s): ",
        paste(duplicate_fields, collapse = ", "),
        "."
      )
    ))
  }

  missing_fields <- setdiff(contract$fields, actual_fields)
  if (length(missing_fields) > 0L) {
    issues <- rbind(issues, local_csv_v2_issue(
      data_type,
      "error",
      "missing_headers",
      paste0(
        "Missing required CSV header(s): ",
        paste(missing_fields, collapse = ", "),
        "."
      )
    ))
  }

  prohibited_fields <- local_csv_v2_prohibited_fields(data_type, actual_fields)
  if (length(prohibited_fields) > 0L) {
    issues <- rbind(issues, local_csv_v2_issue(
      data_type,
      "error",
      "prohibited_oe_fields",
      paste0(
        "Biology O:E fields are Dashboard outputs and must not be uploaded: ",
        paste(prohibited_fields, collapse = ", "),
        "."
      )
    ))
  }

  extra_fields <- setdiff(actual_fields, c(contract$fields, prohibited_fields))
  if (length(extra_fields) > 0L) {
    issues <- rbind(issues, local_csv_v2_issue(
      data_type,
      "info",
      "extra_headers_ignored",
      paste0(
        "Extra non-conflicting header(s) will be ignored: ",
        paste(extra_fields, collapse = ", "),
        "."
      )
    ))
  }

  if (nrow(data) == 0L) {
    issues <- rbind(issues, local_csv_v2_issue(
      data_type,
      "error",
      "no_data_rows",
      "The CSV contains headers but no data rows."
    ))
  }

  if (length(missing_fields) == 0L && nrow(data) > 0L && !anyDuplicated(actual_fields)) {
    for (field in contract$nonblank) {
      blank_rows <- which(!local_csv_v2_nonblank(data[[field]]))
      if (length(blank_rows) > 0L) {
        issues <- rbind(issues, local_csv_v2_issue(
          data_type,
          "error",
          "blank_required_value",
          sprintf(
            "%s is blank in row(s): %s.",
            field,
            paste(utils::head(blank_rows, 10L), collapse = ", ")
          ),
          field
        ))
      }
    }

    issues <- local_csv_v2_add_field_issues(
      issues, data, data_type, contract$date,
      local_csv_v2_invalid_date, "invalid_date", "date/time"
    )
    issues <- local_csv_v2_add_field_issues(
      issues, data, data_type, contract$integer,
      local_csv_v2_invalid_integer, "invalid_integer", "integer"
    )
    issues <- local_csv_v2_add_field_issues(
      issues, data, data_type, contract$numeric,
      local_csv_v2_invalid_numeric, "invalid_numeric", "numeric"
    )

    if (identical(data_type, "biology")) {
      index_fields <- contract$numeric
      has_index <- Reduce(`|`, lapply(index_fields, function(field) {
        values <- suppressWarnings(as.numeric(data[[field]]))
        local_csv_v2_nonblank(data[[field]]) & is.finite(values)
      }))
      if (!any(has_index)) {
        issues <- rbind(issues, local_csv_v2_issue(
          data_type,
          "error",
          "missing_biology_index",
          paste0(
            "At least one supported biological index must contain a usable value: ",
            paste(index_fields, collapse = ", "),
            "."
          )
        ))
      } else if (any(!has_index)) {
        issues <- rbind(issues, local_csv_v2_issue(
          data_type,
          "warning",
          "row_missing_biology_index",
          "Some Biology rows contain no usable supported index value."
        ))
      }
    }

    if (identical(data_type, "wq")) {
      invalid_det <- which(
        local_csv_v2_nonblank(data$det_id) & nchar(as.character(data$det_id)) != 4L
      )
      if (length(invalid_det) > 0L) {
        issues <- rbind(issues, local_csv_v2_issue(
          data_type,
          "error",
          "invalid_det_id",
          paste0(
            "det_id must contain exactly four characters in row(s): ",
            paste(utils::head(invalid_det, 10L), collapse = ", "),
            "."
          ),
          "det_id"
        ))
      }
    }
  }

  status <- local_csv_v2_status(issues)
  list(
    status = status,
    messages = if (nrow(issues) == 0L) {
      sprintf("The %s CSV passed Data Contract v2.0 validation.", data_type)
    } else {
      issues$message
    },
    issues = issues,
    data = if (identical(status, "error")) NULL else normalise_local_csv_v2(data, data_type)
  )
}

normalise_local_csv_v2 <- function(data, data_type) {
  contract <- local_csv_v2_contract(data_type)
  if (!is.data.frame(data) || !all(contract$fields %in% names(data))) {
    stop("Only a structurally valid local CSV can be normalised.", call. = FALSE)
  }

  normalised <- data[, contract$fields, drop = FALSE]
  if (length(contract$rename) > 0L) {
    for (source_field in names(contract$rename)) {
      names(normalised)[names(normalised) == source_field] <- contract$rename[[source_field]]
    }
  }

  renamed <- function(fields) {
    unname(ifelse(fields %in% names(contract$rename), contract$rename[fields], fields))
  }
  for (field in renamed(contract$date)) {
    if (identical(data_type, "wq") && identical(field, "date_time")) {
      normalised[[field]] <- as.POSIXct(normalised[[field]], tz = "UTC")
    } else {
      normalised[[field]] <- as.Date(normalised[[field]])
    }
  }
  for (field in renamed(contract$integer)) {
    normalised[[field]] <- as.integer(normalised[[field]])
  }
  for (field in renamed(contract$numeric)) {
    normalised[[field]] <- as.numeric(normalised[[field]])
  }
  normalised
}

read_local_csv_v2 <- function(path, data_type, reader = read_character_csv) {
  if (!is.character(path) || length(path) != 1L || is.na(path) || !file.exists(path)) {
    return(validate_local_csv_v2(NULL, data_type))
  }
  validate_local_csv_v2(reader(path = path), data_type)
}
