wq_rhs_numeric_columns <- function(data) {
  if (is.null(data) || nrow(data) == 0) {
    return(character(0))
  }

  id_like <- stringr::str_detect(tolower(names(data)), "(^|_)id$|site_id|survey_id|flow_input")
  detected <- names(data)[vapply(data, function(column) {
    if (is.numeric(column)) {
      return(TRUE)
    }

    if (is.factor(column)) {
      column <- as.character(column)
    }

    if (!is.character(column)) {
      return(FALSE)
    }

    values <- trimws(column)
    values <- values[!is.na(values) & nzchar(values)]
    if (length(values) == 0) {
      return(FALSE)
    }

    parsed <- suppressWarnings(as.numeric(values))
    mean(!is.na(parsed)) >= 0.8
  }, logical(1))]
  setdiff(detected, names(data)[id_like])
}

wq_rhs_date_columns <- function(data) {
  if (is.null(data) || nrow(data) == 0) {
    return(character(0))
  }

  name_matches <- stringr::str_detect(tolower(names(data)), "date|time")
  value_matches <- vapply(data, function(column) {
    parsed <- wq_rhs_parse_date(column)
    mean(!is.na(parsed)) >= 0.8 && any(!is.na(parsed))
  }, logical(1))

  names(data)[name_matches | value_matches]
}

wq_rhs_categorical_columns <- function(data) {
  if (is.null(data) || nrow(data) == 0) {
    return(character(0))
  }

  numeric_cols <- wq_rhs_numeric_columns(data)
  date_cols <- wq_rhs_date_columns(data)
  id_like <- names(data)[stringr::str_detect(tolower(names(data)), "(^|_)id$|site_id|survey_id|flow_input")]
  excluded <- c(numeric_cols, date_cols, id_like)

  names(data)[vapply(names(data), function(column_name) {
    if (column_name %in% excluded) {
      return(FALSE)
    }

    column <- data[[column_name]]
    is.character(column) || is.factor(column) || is.logical(column)
  }, logical(1))]
}

wq_rhs_parse_date <- function(column) {
  if (inherits(column, "Date")) {
    return(column)
  }

  if (inherits(column, "POSIXt")) {
    return(as.Date(column))
  }

  values <- trimws(as.character(column))
  values[!nzchar(values)] <- NA_character_

  parsed <- tryCatch(
    suppressWarnings(as.Date(values)),
    error = function(e) rep(as.Date(NA), length(values))
  )
  missing <- is.na(parsed) & !is.na(values)
  if (any(missing)) {
    parsed[missing] <- suppressWarnings(lubridate::ymd(values[missing], quiet = TRUE))
  }

  missing <- is.na(parsed) & !is.na(values)
  if (any(missing)) {
    parsed[missing] <- suppressWarnings(lubridate::dmy(values[missing], quiet = TRUE))
  }

  missing <- is.na(parsed) & !is.na(values)
  if (any(missing)) {
    parsed[missing] <- suppressWarnings(lubridate::mdy(values[missing], quiet = TRUE))
  }

  parsed
}

wq_rhs_as_numeric <- function(column) {
  if (is.numeric(column)) {
    return(column)
  }

  suppressWarnings(as.numeric(trimws(as.character(column))))
}

wq_rhs_default_group <- function(data) {
  if (is.null(data)) {
    return(character(0))
  }

  preferred <- c("biol_site_id", "wq_site_id", "rhs_site_id", "rhs_survey_id")
  existing <- intersect(preferred, names(data))
  if (length(existing) > 0) {
    existing[[1]]
  } else {
    names(data)[[1]]
  }
}

build_wq_plot <- function(data, plot_type, numeric_var, date_col = NULL, group_col = NULL) {
  if (is.null(data) || nrow(data) == 0) {
    return(list(plot = NULL, message = "No mapped WQ data are available yet. Import or upload WQ data first."))
  }

  numeric_cols <- wq_rhs_numeric_columns(data)
  if (length(numeric_cols) == 0) {
    return(list(plot = NULL, message = "Mapped WQ data do not contain a suitable numeric variable to plot."))
  }

  if (is.null(numeric_var) || !numeric_var %in% names(data) || !numeric_var %in% numeric_cols) {
    numeric_var <- numeric_cols[[1]]
  }

  if (is.null(group_col) || !group_col %in% names(data)) {
    group_col <- wq_rhs_default_group(data)
  }

  plot_data <- data
  plot_data$.numeric_value <- wq_rhs_as_numeric(plot_data[[numeric_var]])
  plot_data$.group_value <- as.factor(plot_data[[group_col]])
  plot_data <- plot_data[!is.na(plot_data$.numeric_value), , drop = FALSE]

  if (nrow(plot_data) == 0) {
    return(list(plot = NULL, message = paste0("The selected WQ variable '", numeric_var, "' does not contain plottable numeric values.")))
  }

  if (identical(plot_type, "Time series")) {
    date_cols <- wq_rhs_date_columns(data)
    if (length(date_cols) == 0) {
      return(list(plot = NULL, message = "A WQ time series needs a date-like column. None was detected in the mapped WQ data."))
    }

    if (is.null(date_col) || !date_col %in% date_cols) {
      date_col <- date_cols[[1]]
    }

    plot_data$.date_value <- wq_rhs_parse_date(plot_data[[date_col]])
    plot_data <- plot_data[!is.na(plot_data$.date_value), , drop = FALSE]
    if (nrow(plot_data) == 0) {
      return(list(plot = NULL, message = paste0("The selected WQ date column '", date_col, "' does not contain usable dates.")))
    }

    plot <- ggplot2::ggplot(plot_data, ggplot2::aes(x = .date_value, y = .numeric_value, colour = .group_value, group = .group_value)) +
      ggplot2::geom_line(na.rm = TRUE) +
      ggplot2::geom_point(na.rm = TRUE) +
      ggplot2::labs(x = date_col, y = numeric_var, colour = group_col, title = paste(numeric_var, "over time")) +
      ggplot2::theme_minimal()
    return(list(plot = plot, message = NULL))
  }

  if (identical(plot_type, "Boxplot by biological site ID")) {
    plot <- ggplot2::ggplot(plot_data, ggplot2::aes(x = .group_value, y = .numeric_value)) +
      ggplot2::geom_boxplot(na.rm = TRUE, fill = "#d8efe2", colour = "#006b44") +
      ggplot2::labs(x = group_col, y = numeric_var, title = paste(numeric_var, "by", group_col)) +
      ggplot2::theme_minimal()
    return(list(plot = plot, message = NULL))
  }

  summary_data <- stats::aggregate(.numeric_value ~ .group_value, data = plot_data, FUN = mean, na.rm = TRUE)
  if (nrow(summary_data) == 0) {
    return(list(plot = NULL, message = "There are no WQ records available after summarising the selected numeric variable."))
  }

  plot <- ggplot2::ggplot(summary_data, ggplot2::aes(x = .group_value, y = .numeric_value)) +
    ggplot2::geom_col(fill = "#008938") +
    ggplot2::labs(x = group_col, y = paste("Mean", numeric_var), title = paste("Mean", numeric_var, "by", group_col)) +
    ggplot2::theme_minimal()
  list(plot = plot, message = NULL)
}

build_rhs_plot <- function(data, plot_type, variable = NULL, group_col = NULL) {
  if (is.null(data) || nrow(data) == 0) {
    return(list(plot = NULL, message = "No mapped RHS data are available yet. Import or upload RHS data first."))
  }

  if (is.null(group_col) || !group_col %in% names(data)) {
    group_col <- wq_rhs_default_group(data)
  }

  numeric_cols <- wq_rhs_numeric_columns(data)
  categorical_cols <- wq_rhs_categorical_columns(data)

  if (identical(plot_type, "Numeric variable by biological site ID")) {
    if (length(numeric_cols) == 0) {
      return(list(plot = NULL, message = "Mapped RHS data do not contain a suitable numeric variable to plot."))
    }

    if (is.null(variable) || !variable %in% numeric_cols) {
      variable <- numeric_cols[[1]]
    }

    plot_data <- data
    plot_data$.numeric_value <- wq_rhs_as_numeric(plot_data[[variable]])
    plot_data$.group_value <- as.factor(plot_data[[group_col]])
    plot_data <- plot_data[!is.na(plot_data$.numeric_value), , drop = FALSE]
    if (nrow(plot_data) == 0) {
      return(list(plot = NULL, message = paste0("The selected RHS variable '", variable, "' does not contain plottable numeric values.")))
    }

    plot <- ggplot2::ggplot(plot_data, ggplot2::aes(x = .group_value, y = .numeric_value)) +
      ggplot2::geom_boxplot(na.rm = TRUE, fill = "#d8efe2", colour = "#006b44") +
      ggplot2::geom_point(position = ggplot2::position_jitter(width = 0.08, height = 0), alpha = 0.7, na.rm = TRUE) +
      ggplot2::labs(x = group_col, y = variable, title = paste(variable, "by", group_col)) +
      ggplot2::theme_minimal()
    return(list(plot = plot, message = NULL))
  }

  if (identical(plot_type, "Categorical count/bar plot")) {
    if (length(categorical_cols) == 0) {
      return(list(plot = NULL, message = "Mapped RHS data do not contain a suitable categorical variable to plot."))
    }

    if (is.null(variable) || !variable %in% categorical_cols) {
      variable <- categorical_cols[[1]]
    }

    plot_data <- data
    plot_data$.category_value <- as.factor(plot_data[[variable]])
    plot <- ggplot2::ggplot(plot_data, ggplot2::aes(x = .category_value)) +
      ggplot2::geom_bar(fill = "#008938") +
      ggplot2::labs(x = variable, y = "Record count", title = paste("RHS count by", variable)) +
      ggplot2::theme_minimal()
    return(list(plot = plot, message = NULL))
  }

  plot_data <- data
  plot_data$.group_value <- as.factor(plot_data[[group_col]])
  plot <- ggplot2::ggplot(plot_data, ggplot2::aes(x = .group_value)) +
    ggplot2::geom_bar(fill = "#008938") +
    ggplot2::labs(x = group_col, y = "Record count", title = paste("RHS record count by", group_col)) +
    ggplot2::theme_minimal()
  list(plot = plot, message = NULL)
}
