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
