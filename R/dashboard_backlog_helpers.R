read_dashboard_csv <- function(path, label) {
  if (is.null(path) || !file.exists(path)) {
    return(list(data = NULL, status = "error", messages = paste0(label, " CSV could not be found.")))
  }

  data <- tryCatch(
    data.table::fread(path, colClasses = "character", data.table = FALSE, encoding = "UTF-8"),
    error = function(e) NULL
  )

  if (is.null(data)) {
    return(list(data = NULL, status = "error", messages = paste0(label, " CSV could not be read. Please upload a valid CSV file.")))
  }

  if (nrow(data) == 0 || ncol(data) == 0) {
    return(list(data = data, status = "error", messages = paste0(label, " CSV appears to be empty.")))
  }

  list(data = data, status = "success", messages = paste0(label, " CSV loaded successfully."))
}

validate_supporting_mapping <- function(mapping) {
  required <- c("biol_site_id", "flow_site_id", "wq_site_id", "rhs_survey_id")
  if (is.null(mapping) || nrow(mapping) == 0) {
    return(list(status = "error", messages = "Mapping data are missing."))
  }

  names_lower <- tolower(names(mapping))
  if ("rhs_site_id" %in% names_lower) {
    message <- if ("rhs_survey_id" %in% names_lower) {
      "Mapping CSV must not contain both rhs_survey_id and rhs_site_id. Remove rhs_site_id."
    } else {
      "Mapping CSV contains unsupported rhs_site_id. Replace it with rhs_survey_id."
    }
    return(list(status = "error", messages = message))
  }

  missing_columns <- setdiff(required, names_lower)
  messages <- character(0)
  status <- "success"

  if (length(missing_columns) > 0) {
    return(list(
      status = "error",
      messages = paste0("Mapping CSV is missing required column(s): ", paste(missing_columns, collapse = ", "), ".")
    ))
  }

  normalised <- mapping
  names(normalised) <- names_lower
  normalised[] <- lapply(normalised, function(column) trimws(as.character(column)))
  normalised <- tryCatch(
    normalise_site_metadata_flow_input(normalised),
    error = function(e) e
  )
  if (inherits(normalised, "error")) {
    return(list(status = "error", messages = conditionMessage(normalised)))
  }

  if (any(!nzchar(normalised$biol_site_id) | is.na(normalised$biol_site_id))) {
    status <- "warning"
    messages <- c(messages, "Some rows have missing biol_site_id values.")
  }

  duplicated_biol <- unique(normalised$biol_site_id[duplicated(normalised$biol_site_id) & nzchar(normalised$biol_site_id)])
  if (length(duplicated_biol) > 0) {
    status <- "warning"
    messages <- c(messages, paste0("Duplicated biol_site_id value(s) found: ", paste(duplicated_biol, collapse = ", "), "."))
  }

  if (any(!nzchar(normalised$wq_site_id) | is.na(normalised$wq_site_id) | toupper(normalised$wq_site_id) == "TBC")) {
    status <- "warning"
    messages <- c(messages, "Some rows have missing or TBC wq_site_id values. WQ mapping will be incomplete for those rows.")
  }

  if (any(!nzchar(normalised$rhs_survey_id) | is.na(normalised$rhs_survey_id) | toupper(normalised$rhs_survey_id) == "TBC")) {
    status <- "warning"
    messages <- c(messages, "Some rows have missing or TBC rhs_survey_id values. RHS import and mapping will skip those rows safely.")
  }

  if (length(messages) == 0) {
    messages <- "Mapping CSV passed validation."
  }

  list(status = status, messages = messages)
}

validate_local_invertebrate <- function(data) {
  required <- c("biol_site_id", "date", "taxon", "abundance")
  if (is.null(data)) {
    return(list(status = "info", messages = "No local invertebrate CSV uploaded yet."))
  }

  missing_columns <- setdiff(required, tolower(names(data)))
  if (length(missing_columns) > 0) {
    return(list(status = "error", messages = paste0("Local invertebrate CSV is missing required column(s): ", paste(missing_columns, collapse = ", "), ".")))
  }

  list(status = "success", messages = "Local invertebrate CSV passed basic validation. It is previewed separately and is not used in O:E unless a future explicit workflow maps it into the required HE Toolkit format.")
}

validate_local_flow <- function(data) {
  required <- c("flow_site_id", "date", "flow")
  if (is.null(data)) {
    return(list(data = NULL, status = "info", messages = "No local flow CSV uploaded yet."))
  }

  names_lower <- tolower(names(data))
  missing_columns <- setdiff(required, names_lower)
  if (length(missing_columns) > 0) {
    return(list(data = NULL, status = "error", messages = paste0("Local flow CSV is missing required column(s): ", paste(missing_columns, collapse = ", "), ".")))
  }

  normalised <- data
  names(normalised) <- names_lower
  normalised$flow_site_id <- trimws(as.character(normalised$flow_site_id))
  if (any(is.na(normalised$flow_site_id) | !nzchar(normalised$flow_site_id))) {
    return(list(data = NULL, status = "error", messages = "Local flow CSV contains blank flow_site_id values."))
  }

  date_values <- if (inherits(normalised$date, "Date")) {
    normalised$date
  } else {
    tryCatch(
      suppressWarnings(as.Date(trimws(as.character(normalised$date)))),
      error = function(e) rep(as.Date(NA), length(normalised$date))
    )
  }
  if (any(is.na(date_values))) {
    return(list(data = NULL, status = "error", messages = "Local flow CSV contains blank or invalid date values."))
  }
  normalised$date <- date_values

  raw_flow_values <- trimws(as.character(normalised$flow))
  missing_flow_values <- is.na(raw_flow_values) | !nzchar(raw_flow_values)
  if (any(missing_flow_values)) {
    return(list(data = NULL, status = "error", messages = "Local flow CSV contains missing or blank flow values."))
  }
  flow_values <- suppressWarnings(as.numeric(raw_flow_values))
  if (any(is.na(flow_values))) {
    return(list(data = NULL, status = "error", messages = "Local flow CSV contains non-numeric flow values."))
  }
  normalised$flow <- flow_values

  list(data = normalised, status = "success", messages = "Local flow CSV passed validation and will be used as the Flow data source.")
}

build_basic_flow_ecology_model <- function(data, flow_var, ecology_var) {
  if (is.null(data) || nrow(data) == 0) {
    return(list(status = "error", messages = "Joined HE data are not available yet. Pair biology and flow data first.", plot = NULL, summary = NULL))
  }

  if (!all(c(flow_var, ecology_var) %in% names(data))) {
    return(list(status = "error", messages = "Select valid flow and ecology variables.", plot = NULL, summary = NULL))
  }

  model_data <- data.frame(
    flow = suppressWarnings(as.numeric(data[[flow_var]])),
    ecology = suppressWarnings(as.numeric(data[[ecology_var]]))
  )
  model_data <- model_data[stats::complete.cases(model_data), , drop = FALSE]

  if (nrow(model_data) < 3) {
    return(list(status = "error", messages = "At least 3 complete numeric observations are needed for a basic model.", plot = NULL, summary = NULL))
  }

  fit <- stats::lm(ecology ~ flow, data = model_data)
  model_summary <- summary(fit)
  slope <- unname(stats::coef(fit)[["flow"]])
  direction <- if (is.na(slope)) "unclear" else if (slope > 0) "positive" else if (slope < 0) "negative" else "flat"
  p_value <- coef(model_summary)[2, 4]
  r_squared <- model_summary$r.squared

  summary_table <- data.frame(
    ecology_variable = ecology_var,
    flow_variable = flow_var,
    observations = nrow(model_data),
    slope = slope,
    direction = direction,
    p_value = p_value,
    r_squared = r_squared,
    interpretation = paste0("The fitted relationship is ", direction, ". This is exploratory only and does not change O:E calculations."),
    stringsAsFactors = FALSE
  )

  plot <- ggplot2::ggplot(model_data, ggplot2::aes(x = flow, y = ecology)) +
    ggplot2::geom_point(alpha = 0.75, colour = "#008938") +
    ggplot2::geom_smooth(method = "lm", se = TRUE, colour = "#333333", formula = y ~ x) +
    ggplot2::labs(x = flow_var, y = ecology_var, title = "Basic flow-ecology relationship") +
    ggplot2::theme_minimal()

  list(status = "success", messages = "Basic model completed.", plot = plot, summary = summary_table)
}
