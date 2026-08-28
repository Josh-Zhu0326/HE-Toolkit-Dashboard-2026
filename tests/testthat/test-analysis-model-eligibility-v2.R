testthat::test_that("Raw Q95 is eligible for single-site models at every supported lag", {
  n <- 20L
  data <- data.frame(
    biol_site_id = rep("B1", n),
    sampling_year = rep(2015:2019, length.out = n),
    LIFE_F_OE = 0.9 + 0.03 * sin(seq_len(n)) + seq_len(n) / 200,
    stringsAsFactors = FALSE
  )
  for (lag in SUPPORTED_FLOW_LAGS) {
    field <- paste0("Q95_lag", lag)
    data[[field]] <- log(seq_len(n) + 1) + lag / 100
    result <- run_analysis_model(
      data,
      list(response = "LIFE_F_OE", flow_predictors = field)
    )
    testthat::expect_identical(result$status, "success", info = field)
    testthat::expect_match(result$formula, field, fixed = TRUE, info = field)
  }
})

testthat::test_that("multiple-site models reject Raw Q95 before fitting", {
  data <- data.frame(
    biol_site_id = rep(paste0("B", 1:5), each = 4),
    sampling_year = rep(2018:2021, times = 5),
    LIFE_F_OE = seq(0.8, 1.2, length.out = 20),
    Q95_lag3 = seq(1, 3, length.out = 20),
    Q95z_lag3 = seq(-1, 1, length.out = 20),
    stringsAsFactors = FALSE
  )

  result <- run_analysis_model(
    data,
    list(response = "LIFE_F_OE", flow_predictors = "Q95_lag3")
  )

  testthat::expect_identical(result$status, "blocked")
  testthat::expect_identical(result$model_path, "multi_site_mixed")
  testthat::expect_match(result$messages, "only standardised", fixed = TRUE)
})

testthat::test_that("unsupported Flow lag submissions are blocked server-side", {
  data <- data.frame(
    biol_site_id = rep("B1", 10),
    sampling_year = rep(2018:2022, each = 2),
    LIFE_F_OE = seq(0.8, 1.2, length.out = 10),
    Q95_lag2 = seq(1, 3, length.out = 10),
    stringsAsFactors = FALSE
  )

  result <- run_analysis_model(
    data,
    list(response = "LIFE_F_OE", flow_predictors = "Q95_lag2")
  )

  testthat::expect_identical(result$status, "blocked")
  testthat::expect_match(result$messages, "Ineligible Flow predictor", fixed = TRUE)
})
