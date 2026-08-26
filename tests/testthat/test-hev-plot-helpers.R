testthat::test_that("HEV axis transforms are invertible for the current metric", {
  transform <- hev_axis_transform(
    flow_values = c(10, 15, 20),
    biology_values = c(100, 150, 300)
  )

  biology_values <- c(100, 150, 300)
  testthat::expect_equal(
    transform$inverse(transform$forward(biology_values)),
    biology_values
  )
  testthat::expect_equal(transform$inverse(c(10, 20)), c(100, 300))
})

testthat::test_that("each of four HEV metrics owns its secondary-axis transform", {
  data <- data.frame(
    date = as.Date("2024-01-01") + 0:3,
    Q95 = c(10, 13, 17, 20),
    Q10 = c(20, 21, 24, 30),
    metric_1 = c(0, 1, 2, 3),
    metric_2 = c(10, 20, 30, 40),
    metric_3 = c(-1, 0, 1, 2),
    metric_4 = c(100, 150, 250, 300),
    Season = c("Winter", "Spring", "Summer", "Autumn"),
    stringsAsFactors = FALSE
  )
  metrics <- paste0("metric_", 1:4)

  grDevices::pdf(file = NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  plots <- plot_hev_dash(
    data = data,
    date_col = "date",
    flow_stat = c("Q95", "Q10"),
    biol_metric = metrics,
    multiplot = FALSE,
    clr_by = "Season"
  )

  testthat::expect_length(plots, 4L)
  testthat::expect_true(all(vapply(plots, inherits, logical(1), "ggplot")))
  for (index in seq_along(metrics)) {
    metric <- metrics[[index]]
    secondary_axis <- plots[[index]]$scales$get_scales("y")$secondary.axis
    testthat::expect_identical(secondary_axis$name, metric)
    testthat::expect_equal(
      secondary_axis$trans(c(10, 30)),
      range(data[[metric]]),
      info = metric
    )
  }

  metric_4_axis <- plots[[4L]]$scales$get_scales("y")$secondary.axis
  testthat::expect_equal(metric_4_axis$trans(c(10, 30)), c(100, 300))

  combined_plot <- plot_hev_dash(
    data = data,
    date_col = "date",
    flow_stat = c("Q95", "Q10"),
    biol_metric = metrics,
    multiplot = TRUE,
    clr_by = "Season"
  )
  testthat::expect_s3_class(combined_plot, "ggplot")
})

testthat::test_that("HEV plots reject undefined dual-axis ranges", {
  testthat::expect_error(
    hev_axis_transform(c(1, 1), c(0.5, 0.8)),
    "Flow values must contain more than one distinct finite value",
    fixed = TRUE
  )
  testthat::expect_error(
    hev_axis_transform(c(1, 2), c(0.5, 0.5)),
    "biology metric must contain more than one distinct finite value",
    fixed = TRUE
  )
})
