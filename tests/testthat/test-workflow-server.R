project_root <- normalizePath(testthat::test_path("..", ".."), winslash = "/", mustWork = TRUE)
workflow_dashboard_server <- local({
  previous_dir <- getwd()
  setwd(project_root)
  on.exit(setwd(previous_dir), add = TRUE)
  source("global.R")
  source("server.R")$value
})

muffle_interrupted_workflow_promise <- function(expression) {
  withCallingHandlers(
    expression,
    warning = function(warning) {
      if (grepl("restarting interrupted promise evaluation", conditionMessage(warning), fixed = TRUE)) {
        invokeRestart("muffleWarning")
      }
    }
  )
}

testthat::test_that("Task selection and stage navigation use the shared workflow session", {
  shiny::testServer(workflow_dashboard_server, {
    testthat::expect_null(workflow_session$task_id)
    muffle_interrupted_workflow_promise(session$flushReact())

    muffle_interrupted_workflow_promise(session$setInputs(`select_task__generate_hev` = 1))
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_identical(workflow_session$task_id, "generate_hev")
    testthat::expect_identical(workflow_session$stage_index, 1L)

    muffle_interrupted_workflow_promise(session$setInputs(workflow_stage_4 = 1))
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_identical(workflow_session$stage_index, 4L)
  })
})

testthat::test_that("Change Task preserves reusable runtime artifacts", {
  shiny::testServer(workflow_dashboard_server, {
    muffle_interrupted_workflow_promise(session$flushReact())
    muffle_interrupted_workflow_promise(session$setInputs(`select_task__ecological_condition` = 1))
    muffle_interrupted_workflow_promise(session$flushReact())

    registry <- set_he_artifact_status(
      workflow_artifacts(),
      "processed_biology",
      "complete",
      data_source = "test fixture",
      history_summary = "Validated once"
    )
    workflow_artifacts(registry)

    muffle_interrupted_workflow_promise(session$setInputs(change_task = 1))
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_null(workflow_session$task_id)
    testthat::expect_identical(workflow_session$stage_index, 1L)
    testthat::expect_identical(workflow_artifacts()$processed_biology$status, "complete")
    testthat::expect_identical(workflow_artifacts()$processed_biology$output_revision, 1L)
  })
})

testthat::test_that("Resume uses reusable artifact state instead of returning to Stage 1", {
  shiny::testServer(workflow_dashboard_server, {
    muffle_interrupted_workflow_promise(session$flushReact())

    registry <- set_he_artifact_status(
      workflow_artifacts(),
      "joined_core",
      "complete",
      data_source = "processed checkpoint"
    )
    registry <- set_he_artifact_status(
      registry,
      "analysis_dataset",
      "complete",
      data_source = "processed checkpoint"
    )
    workflow_artifacts(registry)

    muffle_interrupted_workflow_promise(session$setInputs(`select_task__generate_hev` = 1))
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_identical(workflow_session$task_id, "generate_hev")
    testthat::expect_identical(workflow_session$stage_index, 4L)
  })
})

testthat::test_that("real business outputs advance the shared artifact registry", {
  biology_fixture <- data.frame(
    biol_site_id = "B1",
    SAMPLE_ID = paste0("S", 1:3),
    SAMPLE_DATE = as.Date(c("2020-05-01", "2021-05-01", "2022-05-01")),
    Month = 5L,
    Year = 2020:2022,
    Season = "Spring",
    WHPT_ASPT = c(4, 5, 6),
    WHPT_N_TAXA = c(20, 21, 22),
    LIFE_FAMILY_INDEX = c(6, 7, 8),
    PSI_FAMILY_SCORE = c(5, 6, 7)
  )
  environment_fixture <- data.frame(
    biol_site_id = "B1",
    NGR_10_FIG = "ST00000000",
    WFD_WATERBODY_ID = "WB1",
    ALTITUDE = 10,
    SLOPE = 1,
    DISCHARGE = 2,
    DIST_FROM_SOURCE = 3,
    WIDTH = 4,
    DEPTH = 1,
    ALKALINITY = 100,
    BOULDERS_COBBLES = 20,
    PEBBLES_GRAVEL = 30,
    SAND = 25,
    SILT_CLAY = 25,
    CONDUCTIVITY = 200,
    TOTAL_HARDNESS = 90,
    CALCIUM = 30
  )

  rlang::local_bindings(
    import_inv = function(...) biology_fixture,
    import_env = function(...) environment_fixture,
    predict_indices = function(...) {
      data.frame(
        biol_site_id = "B1",
        SEASON = 1,
        TL2_WHPT_ASPT_AbW_DistFam = 5,
        TL2_WHPT_NTAXA_AbW_DistFam = 21,
        TL3_LIFE_Fam_DistFam = 7,
        TL3_PSI_Fam = 6
      )
    },
    calc_flowstats = function(data, ...) {
      list(
        data.frame(
          flow_site_id = "F1",
          start_date = as.Date(c("2020-01-01", "2021-01-01", "2022-01-01")),
          Q95z_lag0 = c(-1, 0, 1)
        ),
        data.frame(flow_site_id = "F1", Q95z = 0)
      )
    },
    join_he = function(..., join_type) {
      if (identical(join_type, "add_flows")) {
        return(data.frame(
          biol_site_id = "B1",
          Year = 2020:2022,
          Q95z_lag0 = c(-1, 0, 1),
          LIFE_F_OE = c(0.8, 1.1, 1.2)
        ))
      }
      data.frame(
        biol_site_id = "B1",
        date = as.Date(c("2020-05-01", "2021-05-01", "2022-05-01")),
        Year = 2020:2022,
        Season = "Spring",
        win_no_lag0 = 1:3,
        Q95z_lag0 = c(-1, 0, 1),
        LIFE_F_OE = c(0.8, 1, 1.2)
      )
    },
    plot_sitepca_dash = function(...) {
      ggplot2::ggplot(data.frame(x = 1, y = 1), ggplot2::aes(x, y))
    },
    plot_hev_dash = function(...) ggplot2::ggplot(data.frame(x = 1, y = 1), ggplot2::aes(x, y)),
    .env = environment(workflow_dashboard_server)
  )

  shiny::testServer(workflow_dashboard_server, {
    local_flow_path <- testthat::test_path("..", "fixtures", "local_flow.csv")
    local_flow_input <- list(
      name = basename(local_flow_path),
      size = file.info(local_flow_path)$size,
      type = "text/csv",
      datapath = normalizePath(local_flow_path, winslash = "/", mustWork = TRUE)
    )

    muffle_interrupted_workflow_promise(session$setInputs(
      meta_paste = "biol_site_id,flow_site_id,flow_input\nB1,F1,HDE",
      local_flow_csv = local_flow_input,
      date_range_biol = as.Date(c("2020-01-01", "2022-12-31")),
      date_range_flow = as.Date(c("2020-01-01", "2022-12-31")),
      import_inv = 1,
      import_env = 1
    ))
    muffle_interrupted_workflow_promise(session$flushReact())

    muffle_interrupted_workflow_promise(session$setInputs(run_rict = 1))
    muffle_interrupted_workflow_promise(session$flushReact())
    muffle_interrupted_workflow_promise(session$setInputs(calc_OE = 1))
    muffle_interrupted_workflow_promise(session$flushReact())
    muffle_interrupted_workflow_promise(session$setInputs(
      win_width_selector = 6,
      win_step_selector = 6,
      calc_flow_stats = 1
    ))
    muffle_interrupted_workflow_promise(session$flushReact())
    muffle_interrupted_workflow_promise(session$setInputs(
      choose_lags = 0,
      choose_join_method = "A",
      join_he = 1
    ))
    muffle_interrupted_workflow_promise(session$flushReact())

    expected_current <- c(
      "site_mapping",
      "biology_input",
      "environment_input",
      "flow_input",
      "processed_biology",
      "processed_environment",
      "processed_flow",
      "oe_result",
      "flow_statistics",
      "joined_core",
      "processed_dataset_checkpoint",
      "filter_selection",
      "analysis_dataset"
    )
    testthat::expect_true(all(vapply(
      workflow_artifacts()[expected_current],
      artifact_is_current,
      logical(1)
    )))
    testthat::expect_true(workflow_task_is_complete(
      get_he_workflow_task("build_he_dataset"),
      workflow_artifacts()
    ))

    muffle_interrupted_workflow_promise(session$setInputs(
      basic_model_flow_var = "Q95z_lag0",
      basic_model_ecology_var = "LIFE_F_OE",
      run_basic_model = 1
    ))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_true(artifact_is_current(workflow_artifacts()$model_result))

    muffle_interrupted_workflow_promise(session$setInputs(
      site_selector = "B1",
      biol_metric_selector = "LIFE_F_OE",
      flow_metric_selector = "Q95z",
      HEV_date_range = c(2020, 2022),
      HEV_show_all_metrics = FALSE,
      HEV_show_high_low = FALSE,
      renderHEV = 1
    ))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_true(artifact_is_current(workflow_artifacts()$hev_result))
  })
})
