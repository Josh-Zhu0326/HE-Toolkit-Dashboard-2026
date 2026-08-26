source(testthat::test_path("..", "..", "R", "workflow_config.R"))

testthat::test_that("hetoolkit materialises flow statistics for every supported lag", {
  testthat::skip_if_not_installed("hetoolkit")

  flow_stats <- data.frame(
    flow_site_id = "F1",
    win_no = 0:19,
    start_date = as.Date("2019-01-01") + 30 * (0:19),
    end_date = as.Date("2019-01-30") + 30 * (0:19),
    Q10 = 101:120,
    Q10z = seq(-1, 1, length.out = 20),
    Q95 = 201:220,
    Q95z = seq(1, -1, length.out = 20)
  )
  biology <- data.frame(
    biol_site_id = "B1",
    date = as.Date("2020-05-15")
  )
  mapping <- data.frame(
    biol_site_id = "B1",
    flow_site_id = "F1"
  )

  joined <- suppressWarnings(
    hetoolkit::join_he(
      biol_data = biology,
      flow_stats = flow_stats,
      mapping = mapping,
      method = "A",
      lags = SUPPORTED_FLOW_LAGS,
      join_type = "add_flows"
    )
  )
  expected_fields <- unlist(lapply(
    SUPPORTED_FLOW_LAGS,
    function(lag) paste0(c("Q10", "Q10z", "Q95", "Q95z"), "_lag", lag)
  ), use.names = FALSE)

  testthat::expect_true(all(expected_fields %in% names(joined)))
})
