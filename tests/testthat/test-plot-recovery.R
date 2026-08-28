source(testthat::test_path("..", "..", "R", "plot_recovery_helpers.R"))

testthat::test_that("Flow heatmap helper returns a drawable plot result", {
  flow_data <- expand.grid(
    flow_site_id = c("27090", "27034"),
    date = seq.Date(as.Date("2024-01-01"), as.Date("2024-12-01"), by = "month"),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  flow_data$flow <- seq_len(nrow(flow_data))

  result <- safe_server_plot_result(function() build_flow_heatmap_plot(flow_data))

  testthat::expect_identical(result$status, "success")
  testthat::expect_true(plot_result_is_usable(result$value))
})

testthat::test_that("Flow heatmap download supports PDF, CSV and PNG", {
  flow_data <- expand.grid(
    flow_site_id = c("27090", "27034"),
    date = seq.Date(as.Date("2024-01-01"), as.Date("2024-06-01"), by = "month"),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  flow_data$flow <- seq_len(nrow(flow_data))
  plot_value <- build_flow_heatmap_plot(flow_data)
  formats <- c(PDF = "pdf", CSV = "csv", PNG = "png")
  output_paths <- file.path(
    tempdir(),
    sprintf("flow-heatmap-%s.%s", tolower(names(formats)), unname(formats))
  )
  on.exit(unlink(output_paths, force = TRUE), add = TRUE)

  shiny::testServer(
    downloadServer,
    args = list(
      id = "flow_heatmap_download_test",
      plot = function() plot_value,
      download_data = function() flow_data,
      context = "Flow heatmap"
    ),
    {
      api <- session$getReturned()
      for (index in seq_along(formats)) {
        testthat::expect_error(
          api$write_download(output_paths[[index]], names(formats)[[index]]),
          NA
        )
        testthat::expect_true(file.exists(output_paths[[index]]))
        testthat::expect_gt(file.info(output_paths[[index]])$size, 0)
        if (identical(names(formats)[[index]], "CSV")) {
          exported <- utils::read.csv(output_paths[[index]], stringsAsFactors = FALSE)
          testthat::expect_identical(names(exported), names(flow_data))
          testthat::expect_equal(nrow(exported), nrow(flow_data))
        }
      }
    }
  )
})

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

testthat::test_that("RAW-18 shared creation preserves the plot before final render", {
  draw_count <- 0L
  print.raw18_shared_second_draw_plot <- function(x, ...) {
    draw_count <<- draw_count + 1L
    if (draw_count >= 2L) {
      stop("shared final draw exposed C:/private/server-output.csv", call. = FALSE)
    }
    invisible(x)
  }
  assign(
    "print.raw18_shared_second_draw_plot",
    print.raw18_shared_second_draw_plot,
    envir = .GlobalEnv
  )
  on.exit(rm("print.raw18_shared_second_draw_plot", envir = .GlobalEnv), add = TRUE)
  stateful_plot <- structure(
    list(),
    class = c("raw18_shared_second_draw_plot", "trellis")
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

  creation <- safe_server_plot_result(function() stateful_plot)

  testthat::expect_identical(draw_count, 1L)
  testthat::expect_identical(creation$status, "success")
  testthat::expect_identical(creation$phase, "validation")
  testthat::expect_identical(creation$value, stateful_plot)

  final_render <- safe_server_plot_render_result(creation$value)

  testthat::expect_identical(draw_count, 2L)
  testthat::expect_identical(final_render$status, "failed")
  testthat::expect_identical(final_render$phase, "final_render")
  testthat::expect_identical(final_render$failure, "plot_error")
  testthat::expect_null(final_render$value)
  testthat::expect_match(final_render$diagnostic, "shared final draw exposed", fixed = TRUE)
  testthat::expect_false(grepl("shared final draw|C:/private", final_render$message))
  testthat::expect_identical(grDevices::dev.list(), devices_before)
})

testthat::test_that("RAW-18 final server boundary alone suppresses Shiny redraw", {
  plots <- list(
    normal = ggplot2::ggplot(
      data.frame(x = 1, y = 2),
      ggplot2::aes(x, y)
    ) + ggplot2::geom_point(),
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

  creation_results <- lapply(plots, function(plot) {
    safe_server_plot_result(function() plot)
  })

  testthat::expect_true(all(vapply(
    creation_results,
    function(result) identical(result$status, "success"),
    logical(1)
  )))
  testthat::expect_true(all(vapply(
    creation_results,
    function(result) identical(result$phase, "validation"),
    logical(1)
  )))
  testthat::expect_true(all(vapply(
    creation_results,
    function(result) plot_result_is_usable(result$value),
    logical(1)
  )))

  render_results <- lapply(creation_results, function(result) {
    safe_server_plot_render_result(result$value)
  })

  testthat::expect_true(all(vapply(
    render_results,
    function(result) identical(result$status, "success"),
    logical(1)
  )))
  testthat::expect_true(all(vapply(
    render_results,
    function(result) identical(result$phase, "final_render"),
    logical(1)
  )))
  testthat::expect_true(all(vapply(
    render_results,
    function(result) is.null(result$value),
    logical(1)
  )))
  testthat::expect_identical(grDevices::dev.list(), devices_before)
})

testthat::test_that("RAW-18 WQ reactive retains the contracted downloadable plot", {
  mapping <- paste(
    "biol_site_id,flow_site_id,wq_site_id,rhs_survey_id",
    "291,27090,SW-A4070115,TBC",
    "292,27091,SW-A4070116,RHS001",
    sep = "\n"
  )
  wq_path <- tempfile("mapped-wq-", fileext = ".png")
  on.exit(unlink(wq_path, force = TRUE), add = TRUE)

  shiny::testServer(workflow_dashboard_server, {
    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = mapping,
      wq_csv = shiny_upload_input(testthat::test_path("..", "fixtures", "wq.csv")),
      wq_plot_type = "Boxplot",
      wq_determinand_filter = "0180",
      wq_site_filter = "__all__",
      wq_plot_date_range = as.Date(c("2024-01-01", "2024-12-31"))
    )
    muffle_interrupted_workflow_promise(session$flushReact())

    wq_plot <- current_wq_plot()
    testthat::expect_s3_class(wq_plot, "ggplot")
    testthat::expect_false(is.null(wq_plot))
    testthat::expect_error(
      ggplot2::ggsave(wq_path, plot = wq_plot, width = 10, height = 5, dpi = 150),
      NA
    )
    testthat::expect_true(file.exists(wq_path) && file.info(wq_path)$size > 0)
  })
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
