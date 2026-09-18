stage4_plot_fixture <- function() {
  data <- utils::read.csv(testthat::test_path("..", "fixtures", "analysis_dataset.csv"))
  data$date <- as.Date(data$date)
  data$Year <- data$sampling_year
  data
}

testthat::test_that("Stage 4 draws correlations without lag zero or every biology metric", {
  data <- stage4_plot_fixture()
  data$WHPT_ASPT_OE <- NULL
  data$Q95z_lag3 <- data$Q95z_lag0
  data$Q10z_lag3 <- data$Q10z_lag0
  data$Q95z_lag0 <- data$Q10z_lag0 <- NULL
  spec <- analysis_correlation_spec(data)
  testthat::expect_null(spec$message)
  testthat::expect_identical(spec$columns, c("LIFE_F_OE", "Q95z_lag3", "Q10z_lag3"))
  result <- safe_server_plot_result(function() build_analysis_correlation_plot(data, spec$columns))
  testthat::expect_identical(result$status, "success")
  testthat::expect_s3_class(result$value, "ggmatrix")
})

testthat::test_that("Stage 4 handles sparse, constant and empty correlation data", {
  data <- stage4_plot_fixture()
  data$Q95z_lag0 <- c(1, 2, NA, NA, Inf)
  data$Q10z_lag0 <- c(NA, NA, 3, 4, -Inf)
  data$LIFE_F_OE <- 1
  data$WHPT_ASPT_OE <- NA_real_
  spec <- analysis_correlation_spec(data)
  testthat::expect_identical(spec$columns, c("Q95z_lag0", "Q10z_lag0"))
  result <- suppressWarnings(safe_server_plot_result(function() {
    build_analysis_correlation_plot(data, spec$columns)
  }))
  testthat::expect_identical(result$status, "success")
  testthat::expect_match(analysis_correlation_spec(data[FALSE, ])$message, "at least two")
  testthat::expect_match(analysis_correlation_spec(NULL)$message, "at least two")
})

testthat::test_that("Stage 4 prefers a complete Flow pair over an incomplete earlier lag", {
  data <- stage4_plot_fixture()
  data$Q10z_lag0 <- NULL
  data$Q95z_lag3 <- data$Q95z_lag0
  data$Q10z_lag3 <- seq_len(nrow(data))
  testthat::expect_identical(analysis_plot_fields(data)$flow, c("Q95z_lag3", "Q10z_lag3"))
})

testthat::test_that("Historical Coverage keeps Flow history and applies runtime record IDs", {
  flow <- data.frame(
    flow_site_id = "F1", win_no = 0:19,
    start_date = as.Date("2019-01-01") + 30 * (0:19),
    end_date = as.Date("2019-01-30") + 30 * (0:19),
    Q95z = sin(1:20), Q10z = cos(1:20)
  )
  biology <- data.frame(
    biol_site_id = "B1", sample_id = c("S1", "S2", "S3"),
    date = as.Date(c("2020-03-15", "2020-04-15", "2020-05-15")),
    sampling_year = 2020L, LIFE_F_OE = c(0.9, 1, 1.1)
  )
  mapping <- data.frame(biol_site_id = "B1", flow_site_id = "F1")
  coverage <- suppressWarnings(build_analysis_coverage_data(
    biology, flow, mapping, list(lags = 3L, method = "A")
  ))
  testthat::expect_equal(nrow(coverage), nrow(flow))
  testthat::expect_true(anyNA(coverage$sample_id))
  testthat::expect_identical(coverage$record_id, coverage$sample_id)
  selection <- exclude_record(new_filter_selection(), "S2", reason = "test")
  selected <- apply_selection_to_coverage(coverage, selection, "LIFE_F_OE", "record_id")
  testthat::expect_equal(nrow(selected), nrow(coverage))
  testthat::expect_identical(selected$Q95z_lag3, coverage$Q95z_lag3)
  testthat::expect_true(is.na(selected$LIFE_F_OE[which(selected$record_id == "S2")]))
  spec <- analysis_coverage_spec(selected, "LIFE_F_OE")
  testthat::expect_null(spec$message)
  testthat::expect_identical(spec$label, "sampling_year")
  result <- suppressWarnings(safe_server_plot_result(function() {
    hetoolkit::plot_rngflows(selected, spec$flow, spec$biology, label = spec$label)
  }))
  testthat::expect_identical(result$status, "success")
  restored <- apply_selection_to_coverage(
    coverage, restore_record(selection, "S2"), "LIFE_F_OE", "record_id"
  )
  testthat::expect_identical(restored, coverage)
  testthat::expect_match(analysis_coverage_spec(coverage[1:2, ], "LIFE_F_OE")$message, "more complete Flow")
})

testthat::test_that("Stage 4 Shiny outputs render a checkpoint and explain unavailable history", {
  checkpoint_path <- tempfile(fileext = ".rds")
  on.exit(unlink(checkpoint_path), add = TRUE)
  data <- stage4_plot_fixture()
  data$Q95z_lag3 <- data$Q95z_lag0
  data$Q10z_lag3 <- data$Q10z_lag0
  data$Q95z_lag0 <- data$Q10z_lag0 <- data$WHPT_ASPT_OE <- NULL
  write_processed_dataset_checkpoint(data, checkpoint_path)
  shiny::testServer(workflow_dashboard_server, {
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_error(output$corr_plots, "Build or load a current")
    testthat::expect_error(output$flow_hull, "Pair biology and Flow data in Stage 3")
    set_inputs_ignoring_interrupted_promises(session,
      processed_dataset_checkpoint_file = shiny_upload_input(checkpoint_path))
    set_inputs_ignoring_interrupted_promises(session, load_processed_dataset_checkpoint = 1)
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_match(output$corr_plots$src, "^data:image/png;base64,")
    testthat::expect_error(output$flow_hull, "not the full Flow history")
    set_inputs_ignoring_interrupted_promises(session,
      analysis_sample_table_rows_selected = integer(), apply_analysis_sample_selection = 1)
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_error(output$corr_plots, "at least two numeric")
    set_inputs_ignoring_interrupted_promises(session,
      analysis_sample_table_rows_selected = seq_len(nrow(data)), apply_analysis_sample_selection = 2)
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_match(output$corr_plots$src, "^data:image/png;base64,")
    testthat::expect_identical(join_data(), data)
    workflow_set_artifact("joined_core", "stale")
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_error(output$corr_plots, "Build or load a current")
  })
})

testthat::test_that("generated Stage 4 plots redraw after sample exclusion and restore", {
  flow_fixture <- data.frame(
    flow_site_id = "F1", win_no = 0:19,
    start_date = as.Date("2019-01-01") + 30 * (0:19),
    end_date = as.Date("2019-01-30") + 30 * (0:19),
    Q95z = sin(1:20), Q10z = cos(1:20)
  )
  biology_fixture <- data.frame(
    biol_site_id = "B1", sample_id = c("S1", "S2", "S3"),
    date = as.Date(c("2020-03-15", "2020-04-15", "2020-05-15")),
    Month = 3:5, Year = 2020L, Season = "Spring", LIFE_F_OE = c(0.9, 1, 1.1)
  )
  mapping_fixture <- data.frame(biol_site_id = "B1", flow_site_id = "F1")
  raw_biology_fixture <- biology_fixture
  raw_biology_fixture$SAMPLE_DATE <- raw_biology_fixture$date
  shiny::testServer(workflow_dashboard_server, {
    muffle_interrupted_workflow_promise(session$flushReact())
    # Supply processed inputs; exercise the real join, selection and renderers.
    rlang::local_bindings(
      biol_all = shiny::reactive(biology_fixture),
      biol_data = shiny::reactive(raw_biology_fixture),
      flow_stats = shiny::reactive(list(flow_fixture)),
      metadata = shiny::reactive(mapping_fixture),
      .env = session$env
    )
    workflow_complete_artifact("oe_result", "fixture", "Processed biology ready.")
    workflow_complete_artifact("flow_statistics", "fixture", "Flow history ready.")
    set_inputs_ignoring_interrupted_promises(session, choose_lags = 3, choose_join_method = "A")
    suppressWarnings(set_inputs_ignoring_interrupted_promises(session, join_he = 1))
    suppressWarnings(muffle_interrupted_workflow_promise(session$flushReact()))
    testthat::expect_true(workflow_artifact_is_current("joined_core"))
    original_coverage <- suppressWarnings(current_coverage_data())
    testthat::expect_equal(nrow(original_coverage), nrow(flow_fixture))
    original_plot <- suppressWarnings(output$flow_hull)$src
    testthat::expect_match(original_plot, "^data:image/png;base64,")
    testthat::expect_match(output$corr_plots$src, "^data:image/png;base64,")
    suppressWarnings(set_inputs_ignoring_interrupted_promises(session,
      analysis_record_id = "S2", exclude_analysis_record = 1))
    muffle_interrupted_workflow_promise(session$flushReact())
    excluded <- current_coverage_data()
    testthat::expect_true(is.na(excluded$LIFE_F_OE[which(excluded$record_id == "S2")]))
    testthat::expect_identical(excluded$Q95z_lag3, original_coverage$Q95z_lag3)
    testthat::expect_false(identical(suppressWarnings(output$flow_hull)$src, original_plot))
    suppressWarnings(set_inputs_ignoring_interrupted_promises(session, restore_analysis_record = 1))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_identical(current_coverage_data(), original_coverage)
    testthat::expect_match(suppressWarnings(output$flow_hull)$src, "^data:image/png;base64,")
    testthat::expect_false(session$isClosed())
  })
})
