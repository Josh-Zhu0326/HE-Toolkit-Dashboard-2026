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

testthat::test_that("joined Flow output gains ordered per-lag window provenance", {
  lags <- c(0L, 1L, 3L)
  flow_stats <- data.frame(
    flow_site_id = rep("F01", 4),
    win_no = 0:3,
    start_date = as.Date(c("2020-01-01", "2021-01-01", "2022-01-01", "2023-01-01")),
    end_date = as.Date(c("2020-12-31", "2021-12-31", "2022-12-31", "2023-12-31"))
  )
  joined <- data.frame(
    biol_site_id = "B01",
    flow_site_id = "F01",
    win_no_lag0 = 3,
    Q95_lag3 = 3, Q10_lag3 = 30, Q95z_lag3 = 0.3, Q10z_lag3 = -0.3,
    win_no_lag1 = 2,
    Q95_lag1 = 2, Q10_lag1 = 20, Q95z_lag1 = 0.2, Q10z_lag1 = -0.2,
    win_no_lag3 = 0,
    Q95_lag0 = 4, Q10_lag0 = 40, Q95z_lag0 = 0.4, Q10z_lag0 = -0.4,
    stringsAsFactors = FALSE
  )

  result <- normalise_joined_flow_contract(joined, flow_stats, lags)
  contract_fields <- c(joined_flow_fields(), joined_flow_window_fields())
  testthat::expect_identical(tail(names(result), length(contract_fields)), contract_fields)
  testthat::expect_false(any(grepl("^win_no_lag", names(result))))
  testthat::expect_identical(result$flow_window_start_lag0, as.Date("2023-01-01"))
  testthat::expect_identical(result$flow_window_end_lag3, as.Date("2020-12-31"))
  testthat::expect_equal(result$flow_window_duration_lag0, 365)
  testthat::expect_equal(result$flow_window_duration_lag3, 366)
  testthat::expect_true(all(is.na(result$Q10_lag6)))
  testthat::expect_true(all(is.na(result$flow_window_start_lag12)))
})

testthat::test_that("joined Flow provenance rejects unmatched window keys", {
  flow_stats <- data.frame(
    flow_site_id = "F01",
    win_no = 1,
    start_date = as.Date("2024-01-01"),
    end_date = as.Date("2024-12-31")
  )
  joined <- data.frame(
    flow_site_id = "F01",
    win_no_lag0 = 999,
    Q10_lag0 = 1,
    Q10z_lag0 = 0,
    Q95_lag0 = 2,
    Q95z_lag0 = 0
  )
  testthat::expect_error(
    normalise_joined_flow_contract(joined, flow_stats, 0),
    "not present in Flow Statistics"
  )
})
