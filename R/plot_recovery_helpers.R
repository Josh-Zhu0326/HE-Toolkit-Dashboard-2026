# RAW-18 plot recovery boundary. Keep this focused on plot creation/results;
# data imports and other application operations use their own contracts.

plot_recovery_user_message <- function() {
  paste(
    "The plot could not be created because the required data is missing or invalid.",
    "Check the plot inputs and current results, then try again."
  )
}

plot_result_is_usable <- function(plot) {
  if (is.null(plot)) {
    return(FALSE)
  }

  if (inherits(plot, c(
    "ggplot", "ggmatrix", "grob", "gtable", "recordedplot", "trellis"
  ))) {
    return(TRUE)
  }

  is.list(plot) && length(plot) > 0L &&
    all(vapply(plot, plot_result_is_usable, logical(1)))
}

force_plot_result <- function(plot) {
  if (inherits(plot, "ggmatrix")) {
    GGally::ggmatrix_gtable(plot)
    return(invisible(TRUE))
  }

  if (inherits(plot, "ggplot")) {
    ggplot2::ggplot_build(plot)
    return(invisible(TRUE))
  }

  if (is.list(plot) && !inherits(plot, c("grob", "gtable"))) {
    lapply(plot, force_plot_result)
  }

  invisible(TRUE)
}

safe_plot_result <- function(operation,
                             plot_value = identity,
                             user_message = plot_recovery_user_message()) {
  if (!is.function(operation) || !is.function(plot_value)) {
    stop("Plot recovery requires operation and plot_value functions.", call. = FALSE)
  }

  outcome <- tryCatch(
    {
      value <- operation()
      plot <- plot_value(value)
      if (!plot_result_is_usable(plot)) {
        return(list(
          status = "failed",
          failure = "unusable_result",
          value = NULL,
          message = user_message,
          diagnostic = "The plot operation returned a NULL or unsupported result."
        ))
      }
      force_plot_result(plot)
      list(
        status = "success",
        failure = NULL,
        value = value,
        message = NULL,
        diagnostic = NULL
      )
    },
    error = function(error) {
      list(
        status = "failed",
        failure = "plot_error",
        value = NULL,
        message = user_message,
        diagnostic = conditionMessage(error)
      )
    }
  )

  outcome
}
