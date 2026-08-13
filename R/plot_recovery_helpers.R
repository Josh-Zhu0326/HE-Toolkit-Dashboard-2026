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

draw_plot_result <- function(plot) {
  if (inherits(plot, "ggmatrix")) {
    grid::grid.draw(GGally::ggmatrix_gtable(plot))
    return(invisible(TRUE))
  }

  if (inherits(plot, "ggplot")) {
    print(plot)
    return(invisible(TRUE))
  }

  if (inherits(plot, c("grob", "gtable"))) {
    grid::grid.draw(plot)
    return(invisible(TRUE))
  }

  if (inherits(plot, "recordedplot")) {
    grDevices::replayPlot(plot)
    return(invisible(TRUE))
  }

  if (inherits(plot, "trellis")) {
    print(plot, newpage = TRUE)
    return(invisible(TRUE))
  }

  if (is.list(plot)) {
    lapply(plot, draw_plot_result)
  }

  invisible(TRUE)
}

safe_final_plot_render <- function(plot,
                                   user_message = plot_recovery_user_message()) {
  if (!plot_result_is_usable(plot)) {
    return(list(
      status = "failed",
      failure = "unusable_result",
      message = user_message,
      diagnostic = "The final plot render received a NULL or unsupported result."
    ))
  }

  tryCatch(
    {
      # This draw occurs on the graphics device already opened by renderPlot().
      # Returning invisibly prevents Shiny from drawing the object a second time.
      draw_plot_result(plot)
      list(
        status = "success",
        failure = NULL,
        message = NULL,
        diagnostic = NULL
      )
    },
    error = function(error) {
      list(
        status = "failed",
        failure = "plot_error",
        message = user_message,
        diagnostic = conditionMessage(error)
      )
    }
  )
}

safe_server_plot_result <- function(operation,
                                    user_message = plot_recovery_user_message()) {
  result <- safe_plot_result(
    operation,
    user_message = user_message
  )
  result$phase <- "validation"
  result
}

safe_server_plot_render_result <- function(plot,
                                           user_message = plot_recovery_user_message()) {
  result <- safe_final_plot_render(
    plot,
    user_message = user_message
  )
  result$value <- NULL
  result$phase <- "final_render"
  result
}

force_plot_result <- function(plot) {
  # Force the complete draw stage without creating an image file or changing
  # the caller's active graphics device after validation completes.
  grDevices::pdf(file = NULL)
  validation_device <- grDevices::dev.cur()
  on.exit({
    open_devices <- grDevices::dev.list()
    if (!is.null(open_devices) && validation_device %in% open_devices) {
      withCallingHandlers(
        grDevices::dev.off(which = validation_device),
        warning = function(warning) {
          # Preserve the draw error; grid emits this warning only while
          # releasing a device that the failed draw left locked.
          if (identical(conditionMessage(warning), "Killing locked device")) {
            invokeRestart("muffleWarning")
          }
        }
      )
    }
  }, add = TRUE)

  draw_plot_result(plot)
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
