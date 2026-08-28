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

wq_rhs_group_axis_labels <- function(values, max_width = 28L) {
  labels <- stringr::str_trunc(as.character(values), width = max_width)
  make.unique(labels, sep = "...")
}

wq_rhs_needs_horizontal_group_axis <- function(values, long_width = 14L, many_count = 8L) {
  values <- unique(as.character(values))
  length(values) > many_count || any(nchar(values, type = "width") > long_width, na.rm = TRUE)
}

wq_rhs_group_axis_caption <- function(group_col) {
  paste0("Long ", group_col, " values are truncated in the plot; full values remain available in the mapped table and CSV.")
}

wq_preview_first_column <- function(data, candidates) {
  if (is.null(data) || length(names(data)) == 0L) {
    return(NA_character_)
  }

  names_lower <- tolower(names(data))
  match_index <- match(tolower(candidates), names_lower, nomatch = 0L)
  match_index <- match_index[match_index > 0L]
  if (length(match_index) == 0L) NA_character_ else names(data)[match_index[[1L]]]
}

wq_preview_filter_spec <- function(data) {
  if (is.null(data) || !is.data.frame(data) || nrow(data) == 0L) {
    return(list(
      determinant_col = NA_character_,
      site_col = NA_character_,
      date_col = NA_character_,
      value_col = NA_character_,
      group_col = NA_character_,
      determinant_choices = character(),
      site_choices = character(),
      date_min = as.Date(NA),
      date_max = as.Date(NA)
    ))
  }

  determinant_col <- wq_preview_first_column(
    data,
    "det_id"
  )
  site_col <- wq_preview_first_column(
    data,
    "wq_site_id"
  )
  date_col <- wq_preview_first_column(
    data,
    "date_time"
  )
  value_col <- wq_preview_first_column(data, "result")
  group_col <- wq_preview_first_column(data, "wq_site_id")

  clean_choices <- function(column_name) {
    if (is.na(column_name)) {
      return(character())
    }
    values <- trimws(as.character(data[[column_name]]))
    sort(unique(values[!is.na(values) & nzchar(values)]))
  }

  dates <- if (is.na(date_col)) rep(as.Date(NA), nrow(data)) else wq_rhs_parse_date(data[[date_col]])
  valid_dates <- dates[!is.na(dates) & dates >= as.Date("2000-01-01")]

  list(
    determinant_col = determinant_col,
    site_col = site_col,
    date_col = date_col,
    value_col = value_col,
    group_col = group_col,
    determinant_choices = clean_choices(determinant_col),
    site_choices = clean_choices(site_col),
    date_min = if (length(valid_dates) == 0L) as.Date(NA) else min(valid_dates),
    date_max = if (length(valid_dates) == 0L) as.Date(NA) else max(valid_dates)
  )
}

filter_wq_preview_data <- function(
    data,
    determinant = "__all__",
    site = "__all__",
    date_range = NULL,
    spec = wq_preview_filter_spec(data)) {
  if (is.null(data) || !is.data.frame(data) || nrow(data) == 0L) {
    return(data)
  }

  keep <- rep(TRUE, nrow(data))
  selected <- function(value) {
    length(value) == 1L && !is.na(value) && nzchar(value) && !identical(value, "__all__")
  }

  if (selected(determinant) && !is.na(spec$determinant_col)) {
    keep <- keep & as.character(data[[spec$determinant_col]]) == determinant
  }
  if (selected(site) && !is.na(spec$site_col)) {
    keep <- keep & as.character(data[[spec$site_col]]) == site
  }
  if (!is.null(date_range) && length(date_range) == 2L &&
      all(!is.na(as.Date(date_range))) && !is.na(spec$date_col)) {
    dates <- wq_rhs_parse_date(data[[spec$date_col]])
    keep <- keep & !is.na(dates) & dates >= as.Date(date_range[[1L]]) & dates <= as.Date(date_range[[2L]])
  }

  data[keep, , drop = FALSE]
}

build_wq_plot <- function(data,
                          plot_type,
                          numeric_var = "result",
                          date_col = "date_time",
                          group_col = "wq_site_id") {
  if (is.null(data) || nrow(data) == 0) {
    return(list(plot = NULL, message = "No mapped WQ data are available yet. Import or upload WQ data first."))
  }

  numeric_var <- "result"
  date_col <- "date_time"
  group_col <- "wq_site_id"
  missing_fields <- setdiff(c(numeric_var, date_col, group_col), names(data))
  if (length(missing_fields) > 0L) {
    return(list(
      plot = NULL,
      message = paste0(
        "WQ plots require the contracted field(s): ",
        paste(missing_fields, collapse = ", "),
        "."
      )
    ))
  }

  plot_data <- data
  plot_data$.numeric_value <- wq_rhs_as_numeric(plot_data[[numeric_var]])
  plot_data$.group_value <- as.factor(plot_data[[group_col]])
  plot_data$.date_value <- wq_rhs_parse_date(plot_data[[date_col]])
  plot_data <- plot_data[
    !is.na(plot_data$.numeric_value) &
      !is.na(plot_data$.date_value) &
      plot_data$.date_value >= as.Date("2000-01-01"),
    ,
    drop = FALSE
  ]
  group_levels <- unique(as.character(plot_data$.group_value))
  group_labels <- wq_rhs_group_axis_labels(group_levels)
  plot_data$.group_label <- factor(
    group_labels[match(as.character(plot_data$.group_value), group_levels)],
    levels = group_labels
  )
  horizontal_group_axis <- wq_rhs_needs_horizontal_group_axis(group_levels)

  if (nrow(plot_data) == 0) {
    return(list(plot = NULL, message = paste0("The selected WQ variable '", numeric_var, "' does not contain plottable numeric values.")))
  }

  if (identical(plot_type, "Time series")) {
    plot <- ggplot2::ggplot(plot_data, ggplot2::aes(x = .date_value, y = .numeric_value, colour = .group_value, group = .group_value)) +
      ggplot2::geom_line(na.rm = TRUE) +
      ggplot2::geom_point(na.rm = TRUE) +
      ggplot2::labs(x = date_col, y = numeric_var, colour = group_col, title = paste(numeric_var, "over time")) +
      ggplot2::theme_minimal()
    return(list(plot = plot, message = NULL))
  }

  if (identical(plot_type, "Boxplot")) {
    plot <- ggplot2::ggplot(plot_data, ggplot2::aes(x = .group_label, y = .numeric_value)) +
      ggplot2::geom_boxplot(na.rm = TRUE, fill = "#d8efe2", colour = "#006b44") +
      ggplot2::labs(x = group_col, y = numeric_var, title = paste(numeric_var, "by", group_col)) +
      ggplot2::theme_minimal() +
      ggplot2::theme(
        axis.text.x = ggplot2::element_text(size = if (horizontal_group_axis) 8 else 10),
        axis.title.y = ggplot2::element_text(margin = ggplot2::margin(r = if (horizontal_group_axis) 12 else 0))
      )
    if (horizontal_group_axis) {
      plot <- plot +
        ggplot2::coord_flip() +
        ggplot2::labs(caption = wq_rhs_group_axis_caption(group_col))
    }
    return(list(plot = plot, message = NULL))
  }
  list(plot = NULL, message = "WQ plot type must be Time series or Boxplot.")
}
