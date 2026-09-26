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

testthat::test_that("Stage 5 exposes every present supported Flow lag and no absent lag", {
  lag_columns <- stats::setNames(
    replicate(length(SUPPORTED_FLOW_LAGS), c(-1, 0, 1), simplify = FALSE),
    paste0("Q95z_lag", SUPPORTED_FLOW_LAGS)
  )
  analysis_data <- data.frame(
    biol_site_id = rep("B1", 3),
    LIFE_F_OE = c(0.8, 1, 1.2),
    Q10_lag0 = c(1, 2, 3),
    Q10z_lag2 = c(-1, 0, 1),
    stringsAsFactors = FALSE
  )
  analysis_data[names(lag_columns)] <- lag_columns

  choices <- analysis_model_variable_choices(analysis_data)
  expected <- paste0("Q95z_lag", c(0, 1, 3, 6, 12))

  testthat::expect_identical(choices$model_path, "single_site_additive")
  testthat::expect_true(all(expected %in% choices$flow))
  testthat::expect_true("Q10_lag0" %in% choices$flow)
  testthat::expect_false("Q10z_lag2" %in% choices$flow)
  testthat::expect_false("Q10z_lag3" %in% choices$flow)
})

testthat::test_that("Stage 5 keeps single-site and multi-site Flow eligibility rules", {
  analysis_data <- data.frame(
    biol_site_id = rep("B1", 4),
    LIFE_F_OE = seq(0.8, 1.1, length.out = 4),
    Q95_lag0 = 1:4,
    Q95z_lag0 = seq(-1, 1, length.out = 4),
    Q10_lag12 = 4:1,
    Q10z_lag12 = seq(1, -1, length.out = 4),
    stringsAsFactors = FALSE
  )

  single <- analysis_model_variable_choices(analysis_data)
  testthat::expect_true(all(
    c("Q95z_lag0", "Q10_lag12", "Q10z_lag12") %in% single$flow
  ))
  testthat::expect_false("Q95_lag0" %in% single$flow)

  analysis_data$biol_site_id <- rep(c("B1", "B2"), each = 2)
  multi <- analysis_model_variable_choices(analysis_data)
  testthat::expect_identical(multi$model_path, "multi_site_mixed")
  testthat::expect_true(all(c("Q95z_lag0", "Q10z_lag12") %in% multi$flow))
  testthat::expect_false(any(c("Q95_lag0", "Q10_lag12") %in% multi$flow))
})

testthat::test_that("Q95z-only eligibility holds across all lags and both model paths", {
  analysis_data <- read.csv(testthat::test_path("..", "fixtures", "analysis_dataset.csv"))
  for (lag in SUPPORTED_FLOW_LAGS) {
    analysis_data[[paste0("Q95_lag", lag)]] <- analysis_data$Q95_lag0
    analysis_data[[paste0("Q95z_lag", lag)]] <- analysis_data$Q95z_lag0
  }
  raw_fields <- paste0("Q95_lag", c(0, 1, 3, 6, 12))
  z_fields <- paste0("Q95z_lag", c(0, 1, 3, 6, 12))

  for (site_count in c(1L, 2L)) {
    data <- analysis_data
    data$biol_site_id <- rep(paste0("B", seq_len(site_count)), length.out = nrow(data))
    original <- data
    choices <- analysis_model_variable_choices(data)
    testthat::expect_true(all(z_fields %in% choices$flow))
    testthat::expect_false(any(raw_fields %in% choices$flow))

    for (raw_field in raw_fields) {
      rejected <- run_analysis_model(data, list(
        response = "LIFE_F_OE", flow_predictors = raw_field
      ))
      testthat::expect_identical(rejected$status, "blocked")
      testthat::expect_match(rejected$messages, "Select Q95z", fixed = TRUE)
      testthat::expect_identical(rejected$provenance$predictors, raw_field)
      testthat::expect_null(rejected$fixed_effects)
      testthat::expect_false(analysis_model_result_is_exportable(rejected))
    }

    if (site_count == 1L) {
      for (z_field in z_fields) {
        fitted <- run_analysis_model(data, list(
          response = "LIFE_F_OE", flow_predictors = z_field
        ))
        testthat::expect_identical(fitted$status, "success")
        testthat::expect_identical(fitted$provenance$predictors, z_field)
        testthat::expect_match(fitted$formula, z_field, fixed = TRUE)
      }
    }
    testthat::expect_identical(data, original)
  }
})

testthat::test_that("Raw Q95 cannot bypass validation through optional predictor inputs", {
  data <- read.csv(testthat::test_path("..", "fixtures", "analysis_dataset.csv"))
  for (slot in c("wq_predictor", "rhs_predictor")) {
    spec <- list(response = "LIFE_F_OE", flow_predictors = "Q95z_lag0")
    spec[[slot]] <- "Q95_lag0"
    result <- run_analysis_model(data, spec)
    testthat::expect_identical(result$status, "blocked")
    testthat::expect_match(result$messages, "Select Q95z", fixed = TRUE)
  }
})
