source(testthat::test_path("..", "..", "R", "plot_recovery_helpers.R"))

testthat::test_that("RAW-18 plot boundary sanitises errors and rejects unusable results", {
  raw_detail <- "ggplot_build failed for C:/private/dashboard-data.csv"

  thrown <- safe_plot_result(function() stop(raw_detail, call. = FALSE))
  null_result <- safe_plot_result(function() NULL)
  unsupported <- safe_plot_result(function() data.frame(x = 1))

  testthat::expect_identical(thrown$status, "failed")
  testthat::expect_identical(thrown$failure, "plot_error")
  testthat::expect_match(thrown$diagnostic, raw_detail, fixed = TRUE)
  testthat::expect_match(thrown$message, "The plot could not be created", fixed = TRUE)
  testthat::expect_false(grepl(
    "conditionMessage|ggplot|ggplot_build|C:/private",
    thrown$message
  ))
  testthat::expect_identical(null_result$failure, "unusable_result")
  testthat::expect_identical(unsupported$failure, "unusable_result")
  testthat::expect_null(null_result$value)
  testthat::expect_null(unsupported$value)
})

testthat::test_that("RAW-18 plot boundary catches delayed ggplot rendering errors and accepts retry", {
  delayed_failure <- safe_plot_result(function() {
    ggplot2::ggplot(data.frame(x = 1), ggplot2::aes(x, missing_y)) +
      ggplot2::geom_point()
  })
  success <- safe_plot_result(function() {
    ggplot2::ggplot(data.frame(x = 1, y = 2), ggplot2::aes(x, y)) +
      ggplot2::geom_point()
  })
  matrix_success <- safe_plot_result(function() {
    GGally::ggpairs(data.frame(a = 1:6, b = c(2, 5, 1, 6, 3, 4)))
  })

  testthat::expect_identical(delayed_failure$status, "failed")
  testthat::expect_identical(delayed_failure$failure, "plot_error")
  testthat::expect_false(grepl("missing_y", delayed_failure$message, fixed = TRUE))
  testthat::expect_match(delayed_failure$diagnostic, "missing_y", fixed = TRUE)
  testthat::expect_identical(success$status, "success")
  testthat::expect_s3_class(success$value, "ggplot")
  testthat::expect_identical(matrix_success$status, "success")
  testthat::expect_s3_class(matrix_success$value, "ggmatrix")
})

testthat::test_that("RAW-18 forces grob and gtable drawing before reporting success", {
  grob <- grid::rectGrob()
  gtable <- ggplot2::ggplotGrob(
    ggplot2::ggplot(data.frame(x = 1, y = 2), ggplot2::aes(x, y)) +
      ggplot2::geom_point()
  )

  grob_result <- safe_plot_result(function() grob)
  gtable_result <- safe_plot_result(function() gtable)

  testthat::expect_identical(grob_result$status, "success")
  testthat::expect_s3_class(grob_result$value, "grob")
  testthat::expect_identical(gtable_result$status, "success")
  testthat::expect_s3_class(gtable_result$value, "gtable")
})

testthat::test_that("RAW-18 converts a grob draw-time error to controlled failure", {
  drawDetails.raw18_failing_grob <- function(x, recording) {
    stop("grid draw failed at /Library/Frameworks/private-output.pdf", call. = FALSE)
  }
  assign(
    "drawDetails.raw18_failing_grob",
    drawDetails.raw18_failing_grob,
    envir = .GlobalEnv
  )
  on.exit(rm("drawDetails.raw18_failing_grob", envir = .GlobalEnv), add = TRUE)
  failing_grob <- grid::grob(cl = "raw18_failing_grob")

  result <- safe_plot_result(function() failing_grob)

  testthat::expect_identical(result$status, "failed")
  testthat::expect_identical(result$failure, "plot_error")
  testthat::expect_null(result$value)
  testthat::expect_match(result$diagnostic, "grid draw failed", fixed = TRUE)
  testthat::expect_false(grepl("grid draw|/Library/Frameworks", result$message))
})

testthat::test_that("RAW-18 continues to force recordedplot and trellis results", {
  grDevices::pdf(file = NULL)
  recording_device <- grDevices::dev.cur()
  on.exit({
    open_devices <- grDevices::dev.list()
    if (!is.null(open_devices) && recording_device %in% open_devices) {
      grDevices::dev.off(which = recording_device)
    }
  }, add = TRUE)
  grDevices::dev.control(displaylist = "enable")
  graphics::plot(1, 1)
  recorded <- grDevices::recordPlot()
  grDevices::dev.off(which = recording_device)

  recorded_result <- safe_plot_result(function() recorded)
  trellis_result <- safe_plot_result(function() {
    lattice::xyplot(y ~ x, data.frame(x = 1:3, y = 3:1))
  })

  testthat::expect_identical(recorded_result$status, "success")
  testthat::expect_s3_class(recorded_result$value, "recordedplot")
  testthat::expect_identical(trellis_result$status, "success")
  testthat::expect_s3_class(trellis_result$value, "trellis")
})

testthat::test_that("RAW-18 final boundary catches a second-draw failure", {
  draw_count <- 0L
  print.raw18_second_draw_plot <- function(x, ...) {
    draw_count <<- draw_count + 1L
    if (draw_count >= 2L) {
      stop("second draw exposed C:/private/final-device.csv", call. = FALSE)
    }
    invisible(x)
  }
  assign(
    "print.raw18_second_draw_plot",
    print.raw18_second_draw_plot,
    envir = .GlobalEnv
  )
  on.exit(rm("print.raw18_second_draw_plot", envir = .GlobalEnv), add = TRUE)
  stateful_plot <- structure(
    list(),
    class = c("raw18_second_draw_plot", "trellis")
  )

  validation <- safe_plot_result(function() stateful_plot)
  testthat::expect_identical(validation$status, "success")
  testthat::expect_identical(draw_count, 1L)

  grDevices::pdf(file = NULL)
  output_device <- grDevices::dev.cur()
  on.exit({
    open_devices <- grDevices::dev.list()
    if (!is.null(open_devices) && output_device %in% open_devices) {
      grDevices::dev.off(which = output_device)
    }
  }, add = TRUE)
  devices_before <- grDevices::dev.list()

  final_render <- safe_final_plot_render(validation$value)

  testthat::expect_identical(final_render$status, "failed")
  testthat::expect_identical(final_render$failure, "plot_error")
  testthat::expect_match(final_render$diagnostic, "second draw exposed", fixed = TRUE)
  testthat::expect_false(grepl("second draw|C:/private", final_render$message))
  testthat::expect_identical(grDevices::dev.list(), devices_before)
})

testthat::test_that("RAW-18 final boundary catches nested draw failures", {
  print.raw18_nested_failing_plot <- function(x, ...) {
    stop("nested final draw failed at /tmp/private-output.pdf", call. = FALSE)
  }
  assign(
    "print.raw18_nested_failing_plot",
    print.raw18_nested_failing_plot,
    envir = .GlobalEnv
  )
  on.exit(rm("print.raw18_nested_failing_plot", envir = .GlobalEnv), add = TRUE)
  nested <- list(
    grid::rectGrob(),
    list(structure(
      list(),
      class = c("raw18_nested_failing_plot", "trellis")
    ))
  )

  grDevices::pdf(file = NULL)
  output_device <- grDevices::dev.cur()
  on.exit({
    open_devices <- grDevices::dev.list()
    if (!is.null(open_devices) && output_device %in% open_devices) {
      grDevices::dev.off(which = output_device)
    }
  }, add = TRUE)
  devices_before <- grDevices::dev.list()

  final_render <- safe_final_plot_render(nested)

  testthat::expect_identical(final_render$status, "failed")
  testthat::expect_match(final_render$diagnostic, "nested final draw failed", fixed = TRUE)
  testthat::expect_false(grepl("nested final draw|/tmp", final_render$message))
  testthat::expect_identical(grDevices::dev.list(), devices_before)
})

testthat::test_that("RAW-18 final boundary renders all accepted plot classes", {
  grDevices::pdf(file = NULL)
  recording_device <- grDevices::dev.cur()
  grDevices::dev.control(displaylist = "enable")
  graphics::plot(1, 1)
  recorded <- grDevices::recordPlot()
  grDevices::dev.off(which = recording_device)

  accepted <- list(
    ggplot = ggplot2::ggplot(
      data.frame(x = 1, y = 2),
      ggplot2::aes(x, y)
    ) + ggplot2::geom_point(),
    ggmatrix = GGally::ggpairs(data.frame(a = 1:4, b = c(2, 4, 1, 3))),
    grob = grid::rectGrob(),
    gtable = ggplot2::ggplotGrob(
      ggplot2::ggplot(data.frame(x = 1, y = 2), ggplot2::aes(x, y)) +
        ggplot2::geom_point()
    ),
    recordedplot = recorded,
    trellis = lattice::xyplot(y ~ x, data.frame(x = 1:3, y = 3:1)),
    nested = list(grid::circleGrob(), list(grid::rectGrob()))
  )

  grDevices::pdf(file = NULL)
  output_device <- grDevices::dev.cur()
  on.exit({
    open_devices <- grDevices::dev.list()
    if (!is.null(open_devices) && output_device %in% open_devices) {
      grDevices::dev.off(which = output_device)
    }
  }, add = TRUE)
  devices_before <- grDevices::dev.list()

  results <- lapply(accepted, safe_final_plot_render)

  testthat::expect_true(all(vapply(
    results,
    function(result) identical(result$status, "success"),
    logical(1)
  )))
  testthat::expect_identical(grDevices::dev.list(), devices_before)
})

testthat::test_that("RAW-18 validation devices are cleaned after success and failure", {
  devices_before <- grDevices::dev.list()
  valid <- safe_plot_result(function() grid::rectGrob())
  invalid <- safe_plot_result(function() {
    ggplot2::ggplot(data.frame(x = 1), ggplot2::aes(x, missing_y)) +
      ggplot2::geom_point()
  })

  testthat::expect_identical(valid$status, "success")
  testthat::expect_identical(invalid$status, "failed")
  testthat::expect_identical(grDevices::dev.list(), devices_before)
})
