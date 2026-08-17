testthat::test_that("the client-confirmed modelling lags are canonical", {
  testthat::expect_identical(supported_join_lags(), c(0L, 1L, 3L, 6L, 12L))
  testthat::expect_identical(
    normalise_join_settings(c(12, 3, 1, 3, 0, 6), "A"),
    list(lags = c(0L, 1L, 3L, 6L, 12L), method = "A")
  )
  testthat::expect_error(
    normalise_join_settings(2, "A"),
    "Supported Dashboard lags are 0, 1, 3, 6, 12",
    fixed = TRUE
  )
  testthat::expect_error(
    normalise_join_settings(integer(), "A"),
    "Select at least one supported lag",
    fixed = TRUE
  )
})

testthat::test_that("joined flow and window fields cover every supported lag", {
  expected_flow_fields <- unlist(lapply(c("Q10", "Q95"), function(metric) {
    unlist(lapply(supported_join_lags(), function(lag) {
      c(sprintf("%s_lag%d", metric, lag), sprintf("%sz_lag%d", metric, lag))
    }), use.names = FALSE)
  }), use.names = FALSE)
  expected_window_fields <- unlist(lapply(supported_join_lags(), function(lag) {
    sprintf("flow_window_%s_lag%d", c("start", "end", "duration"), lag)
  }), use.names = FALSE)

  testthat::expect_identical(joined_flow_fields(), expected_flow_fields)
  testthat::expect_identical(joined_flow_window_fields(), expected_window_fields)
  testthat::expect_true(all(c(expected_flow_fields, expected_window_fields) %in%
    dc11_sheet_schemas()$joined_dataset_optional))
})
