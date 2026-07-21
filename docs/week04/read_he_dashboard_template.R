read_he_dashboard_template <- function(path) {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop("Package 'readxl' is required to read the dashboard template.")
  }
  if (!requireNamespace("dplyr", quietly = TRUE)) {
    stop("Package 'dplyr' is required to validate the dashboard template.")
  }

  required_sheets <- c(
    "site_mapping",
    "biology_samples",
    "environmental_site_data",
    "flow_daily",
    "wq_long_standard",
    "rhs_summary"
  )

  sheets <- readxl::excel_sheets(path)
  missing_sheets <- setdiff(required_sheets, sheets)
  if (length(missing_sheets) > 0) {
    stop("Template is missing required sheet(s): ", paste(missing_sheets, collapse = ", "))
  }

  read_sheet <- function(sheet) {
    readxl::read_excel(path, sheet = sheet, .name_repair = "minimal")
  }

  data <- list(
    site_mapping = read_sheet("site_mapping"),
    biology_samples = read_sheet("biology_samples"),
    environmental_site_data = read_sheet("environmental_site_data"),
    flow_daily = read_sheet("flow_daily"),
    wq_long_standard = read_sheet("wq_long_standard"),
    rhs_summary = read_sheet("rhs_summary")
  )

  required_cols <- list(
    site_mapping = c("biol_site_id", "flow_site_id", "flow_input"),
    biology_samples = c("biol_site_id", "date"),
    environmental_site_data = c(
      "biol_site_id",
      "EASTING",
      "NORTHING",
      "ALTITUDE",
      "SLOPE",
      "DIST_FROM_SOURCE",
      "DISCHARGE",
      "WIDTH",
      "DEPTH",
      "BOULDERS_COBBLES",
      "PEBBLES_GRAVEL",
      "SAND",
      "SILT_CLAY",
      "ALKALINITY",
      "CONDUCTIVITY",
      "TOTAL_HARDNESS",
      "CALCIUM"
    ),
    flow_daily = c("flow_site_id", "date", "flow"),
    wq_long_standard = c("wq_site_id", "date_time", "determinand", "result"),
    rhs_summary = c("rhs_survey_id")
  )

  for (sheet in names(required_cols)) {
    missing_cols <- setdiff(required_cols[[sheet]], names(data[[sheet]]))
    if (length(missing_cols) > 0) {
      stop(sheet, " is missing required column(s): ", paste(missing_cols, collapse = ", "))
    }
  }

  data$biology_samples <- data$biology_samples |>
    dplyr::mutate(
      biol_site_id = as.character(.data$biol_site_id),
      date = as.Date(.data$date)
    )

  data$flow_daily <- data$flow_daily |>
    dplyr::mutate(
      flow_site_id = as.character(.data$flow_site_id),
      date = as.Date(.data$date),
      flow = as.numeric(.data$flow),
      source_file = if ("source_file" %in% names(data$flow_daily)) as.character(.data$source_file) else NA_character_
    )

  data$environmental_site_data <- data$environmental_site_data |>
    dplyr::mutate(
      biol_site_id = as.character(.data$biol_site_id),
      EASTING = as.character(.data$EASTING),
      NORTHING = as.character(.data$NORTHING),
      dplyr::across(
        c(
          "ALTITUDE",
          "SLOPE",
          "DIST_FROM_SOURCE",
          "DISCHARGE",
          "WIDTH",
          "DEPTH",
          "BOULDERS_COBBLES",
          "PEBBLES_GRAVEL",
          "SAND",
          "SILT_CLAY",
          "ALKALINITY",
          "CONDUCTIVITY",
          "TOTAL_HARDNESS",
          "CALCIUM"
        ),
        as.numeric
      )
    )

  data$site_mapping <- data$site_mapping |>
    dplyr::mutate(
      biol_site_id = as.character(.data$biol_site_id),
      flow_site_id = as.character(.data$flow_site_id),
      flow_input = as.character(.data$flow_input)
    )

  data$wq_long_standard <- data$wq_long_standard |>
    dplyr::mutate(
      wq_site_id = as.character(.data$wq_site_id),
      date_time = as.POSIXct(.data$date_time, tz = "UTC"),
      result = as.numeric(.data$result),
      qualifier = if ("qualifier" %in% names(data$wq_long_standard)) as.character(.data$qualifier) else NA_character_,
      observation = if ("observation" %in% names(data$wq_long_standard)) as.character(.data$observation) else NA_character_
    )

  data$rhs_summary <- data$rhs_summary |>
    dplyr::mutate(
      rhs_survey_id = as.character(.data$rhs_survey_id),
      survey_date = if ("survey_date" %in% names(data$rhs_summary)) as.Date(.data$survey_date) else as.Date(NA)
    )

  data$validation_summary <- list(
    n_biology_samples = nrow(data$biology_samples),
    n_environmental_sites = nrow(data$environmental_site_data),
    n_flow_records = nrow(data$flow_daily),
    n_wq_records = nrow(data$wq_long_standard),
    n_rhs_records = nrow(data$rhs_summary),
    n_site_mappings = nrow(data$site_mapping),
    biology_sites_without_mapping = setdiff(
      unique(data$biology_samples$biol_site_id),
      unique(data$site_mapping$biol_site_id)
    ),
    biology_sites_without_environmental_data = setdiff(
      unique(data$biology_samples$biol_site_id),
      unique(data$environmental_site_data$biol_site_id)
    ),
    flow_sites_without_mapping = setdiff(
      unique(data$flow_daily$flow_site_id),
      unique(data$site_mapping$flow_site_id)
    )
  )

  data
}

# Example:
# template <- read_he_dashboard_template(
#   "/Users/deng/Documents/Codex/2026-06-25/xi/outputs/HE_Toolkit_dashboard_standard_data_template.xlsx"
# )
# str(template$validation_summary)
