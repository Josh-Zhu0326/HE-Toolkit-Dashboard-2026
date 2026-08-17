testthat::test_that("analysis record selector follows the dataset identifier column", {
  sample_spec <- analysis_record_selector_spec(data.frame(
    sample_id = c("S002", "S001"),
    stringsAsFactors = FALSE
  ))
  testthat::expect_identical(sample_spec$id_column, "record_id")
  testthat::expect_identical(sample_spec$label, "Record ID")
  testthat::expect_identical(sample_spec$choices, c("S002", "S001"))

  record_spec <- analysis_record_selector_spec(data.frame(
    record_id = c("R1", "R2"),
    sample_id = c("S1", "S2"),
    stringsAsFactors = FALSE
  ))
  testthat::expect_identical(record_spec$id_column, "record_id")
  testthat::expect_identical(record_spec$label, "Record ID")
  testthat::expect_identical(record_spec$choices, c("R1", "R2"))

  empty_spec <- analysis_record_selector_spec(NULL)
  testthat::expect_true(is.na(empty_spec$id_column))
  testthat::expect_length(empty_spec$choices, 0L)
  testthat::expect_identical(empty_spec$placeholder, "Joined HE dataset required")
  testthat::expect_identical(
    empty_spec$hint,
    "Build or load a Joined HE dataset before selecting a record."
  )
})

testthat::test_that("RAW-23 workbook preview observer accepts missing and empty sheet input", {
  shiny::testServer(workflow_dashboard_server, {
    testthat::expect_warning(
      muffle_interrupted_workflow_promise(session$flushReact()),
      NA
    )
    testthat::expect_warning(
      muffle_interrupted_workflow_promise(
        session$setInputs(dc11_workbook_preview_sheet = character(0))
      ),
      NA
    )
    testthat::expect_warning(
      muffle_interrupted_workflow_promise(session$flushReact()),
      NA
    )
    testthat::expect_warning(
      muffle_interrupted_workflow_promise(
        session$setInputs(dc11_workbook_preview_sheet = NA_character_)
      ),
      NA
    )
    testthat::expect_warning(
      muffle_interrupted_workflow_promise(
        session$setInputs(dc11_workbook_preview_sheet = "")
      ),
      NA
    )
    testthat::expect_warning(
      muffle_interrupted_workflow_promise(
        session$setInputs(dc11_workbook_preview_sheet = "not_a_workbook_sheet")
      ),
      NA
    )
    testthat::expect_warning(
      muffle_interrupted_workflow_promise(session$flushReact()),
      NA
    )

    artifact_statuses <- vapply(
      workflow_artifacts(),
      function(artifact) artifact$status,
      character(1)
    )
    testthat::expect_false(any(artifact_statuses %in% c("running", "busy")))
  })
})

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

testthat::test_that("Flow display controls match the selected table or heatmap view", {
  shiny::testServer(workflow_dashboard_server, {
    set_inputs_ignoring_interrupted_promises(
      session,
      flow_data_display = "Completeness stats",
      imp_flow_data_display = "Completeness stats"
    )
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_false(showHeatmap())
    testthat::expect_false(showHeatmapimp())

    set_inputs_ignoring_interrupted_promises(
      session,
      flow_data_display = "Heatmap",
      imp_flow_data_display = "Heatmap"
    )
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_true(showHeatmap())
    testthat::expect_true(showHeatmapimp())
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

testthat::test_that("Status announcement reacts to artifact state and next action", {
  shiny::testServer(workflow_dashboard_server, {
    muffle_interrupted_workflow_promise(session$flushReact())
    muffle_interrupted_workflow_promise(
      session$setInputs(`select_task__ecological_condition` = 1)
    )
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_match(
      output$workflow_status_announcement,
      "Stage status: not started",
      fixed = TRUE
    )

    registry <- set_he_artifact_status(
      workflow_artifacts(),
      "biology_input",
      "blocked",
      blocking_reason = "One biology site is not mapped.",
      next_action = "Add the missing site mapping and validate again."
    )
    workflow_artifacts(registry)
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_match(
      output$workflow_status_announcement,
      "Stage status: blocked",
      fixed = TRUE
    )
    testthat::expect_match(
      output$workflow_status_announcement,
      "Add the missing site mapping and validate again.",
      fixed = TRUE
    )
  })
})

testthat::test_that("Flow-statistics attempt without Flow input becomes recoverably blocked", {
  shiny::testServer(workflow_dashboard_server, {
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_identical(
      workflow_artifacts()$flow_statistics$status,
      "not_started"
    )

    muffle_interrupted_workflow_promise(session$setInputs(
      win_width_selector = 6,
      win_step_selector = 6,
      calc_flow_stats = 1
    ))
    muffle_interrupted_workflow_promise(session$flushReact())

    artifact <- workflow_artifacts()$flow_statistics
    testthat::expect_identical(artifact$status, "blocked")
    testthat::expect_match(
      artifact$blocking_reason,
      "require current validated Flow data",
      fixed = TRUE
    )
    testthat::expect_match(
      artifact$next_action,
      "Upload or import Flow data",
      fixed = TRUE
    )
    testthat::expect_null(flow_stats_revision())
  })
})

testthat::test_that("RAW-04 donor inputs reject all-whitespace text and allow in-session retry", {
  reader_calls <- 0L
  rlang::local_bindings(
    read_character_csv = function(path = NULL, text = NULL) {
      reader_calls <<- reader_calls + 1L
      data.table::fread(text = text, colClasses = "character", data.table = FALSE)
    },
    .env = environment(workflow_dashboard_server)
  )

  shiny::testServer(workflow_dashboard_server, {
    muffle_interrupted_workflow_promise(session$flushReact())
    registry <- set_he_artifact_status(
      workflow_artifacts(),
      "flow_statistics",
      "complete",
      data_source = "retained test Flow Statistics",
      history_summary = "Generated before donor validation."
    )
    workflow_artifacts(registry)

    whitespace_inputs <- c("", "   ", "\t", "\n", " \t\n ")
    for (value in whitespace_inputs) {
      muffle_interrupted_workflow_promise(session$setInputs(
        donor_mapping_paste = value,
        donor_list_paste = value
      ))
      muffle_interrupted_workflow_promise(session$flushReact())

      mapping_message <- tryCatch(
        {
          donor_mapping()
          NULL
        },
        error = conditionMessage
      )
      list_message <- tryCatch(
        {
          donor_list()
          NULL
        },
        error = conditionMessage
      )
      testthat::expect_match(
        mapping_message,
        "If imputing flows please add donor mapping.",
        fixed = TRUE
      )
      testthat::expect_match(
        list_message,
        "please add the donor site list",
        fixed = TRUE
      )
      testthat::expect_true(artifact_is_current(workflow_artifacts()$flow_statistics))
      testthat::expect_false(identical(workflow_artifacts()$flow_statistics$status, "running"))
    }
    testthat::expect_identical(reader_calls, 0L)

    muffle_interrupted_workflow_promise(session$setInputs(
      donor_mapping_paste = paste(
        "donee_flow_site_id,donor_flow_site_id",
        "F1,F2",
        sep = "\n"
      ),
      donor_list_paste = paste(
        "flow_site_id,flow_input",
        "F2,HDE",
        sep = "\n"
      )
    ))
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_identical(donor_mapping()$donor_flow_site_id, "F2")
    testthat::expect_identical(donor_list()$flow_site_id, "F2")
    testthat::expect_identical(donor_list()$flow_input, "HDE")
    testthat::expect_identical(reader_calls, 2L)
    testthat::expect_true(artifact_is_current(workflow_artifacts()$flow_statistics))
  })
})

testthat::test_that("Join-setting changes stale current outputs without rerunning them", {
  shiny::testServer(workflow_dashboard_server, {
    muffle_interrupted_workflow_promise(session$flushReact())
    muffle_interrupted_workflow_promise(session$setInputs(
      choose_lags = 0,
      choose_join_method = "A"
    ))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_identical(
      workflow_artifacts()$joined_core$status,
      "not_started"
    )
    testthat::expect_null(join_request())

    registry <- workflow_artifacts()
    for (artifact_id in c(
      "flow_statistics",
      "joined_core",
      "joined_enriched",
      "processed_dataset_checkpoint",
      "filter_selection",
      "analysis_dataset",
      "hev_result",
      "model_spec",
      "model_result"
    )) {
      registry <- set_he_artifact_status(
        registry,
        artifact_id,
        "complete",
        data_source = "test fixture",
        history_summary = sprintf("Generated %s once.", artifact_id)
      )
    }
    workflow_artifacts(registry)
    built_request <- list(
      flow_revision = flow_source_revision(),
      settings = normalise_join_settings(0, "A"),
      request_id = 1
    )
    join_request(built_request)
    join_revision(built_request)
    hev_revision(built_request)
    join_settings_used(built_request$settings)
    revisions_before <- vapply(
      workflow_artifacts(),
      `[[`,
      integer(1),
      "output_revision"
    )

    # A duplicate/reordered lag selection is the same canonical setting.
    muffle_interrupted_workflow_promise(
      session$setInputs(choose_lags = c(0, 0))
    )
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_true(artifact_is_current(workflow_artifacts()$joined_core))
    testthat::expect_identical(join_revision(), built_request)

    testthat::expect_identical(
      normalise_join_settings(c(12, 3, 1, 3, 0, 6), "A")$lags,
      c(0L, 1L, 3L, 6L, 12L)
    )

    muffle_interrupted_workflow_promise(
      session$setInputs(choose_lags = 1)
    )
    muffle_interrupted_workflow_promise(session$flushReact())

    expected_stale <- c(
      "joined_core",
      "joined_enriched",
      "processed_dataset_checkpoint",
      "analysis_dataset",
      "hev_result",
      "model_result"
    )
    testthat::expect_true(all(vapply(
      workflow_artifacts()[expected_stale],
      function(artifact) identical(artifact$status, "stale"),
      logical(1)
    )))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$flow_statistics))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$filter_selection))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$model_spec))
    testthat::expect_identical(
      workflow_artifacts()$joined_core$data_source,
      "test fixture"
    )
    testthat::expect_identical(
      vapply(workflow_artifacts(), `[[`, integer(1), "output_revision"),
      revisions_before
    )
    testthat::expect_identical(
      join_settings_used(),
      normalise_join_settings(0, "A")
    )
    testthat::expect_null(join_revision())
    testthat::expect_null(hev_revision())

    # Further edits do not recalculate or increment any retained output.
    muffle_interrupted_workflow_promise(session$setInputs(choose_lags = 1))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_identical(
      vapply(workflow_artifacts(), `[[`, integer(1), "output_revision"),
      revisions_before
    )
  })
})

testthat::test_that("RAW-12 to RAW-18 prerequisites and plot failures recover in session", {
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

  join_calls <- 0L
  hev_plot_mode <- new.env(parent = emptyenv())
  hev_plot_mode$value <- "success"
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
          Q95_lag0 = c(1.2, 1.1, 1.0),
          Q10_lag0 = c(8.1, 8.2, 8.3),
          Q95z_lag0 = c(-1, 0, 1)
        ),
        data.frame(flow_site_id = "F1", Q95 = 1.1, Q10 = 8.2, Q95z = 0)
      )
    },
    join_he = function(..., join_type) {
      join_calls <<- join_calls + 1L
      if (identical(join_type, "add_flows")) {
        return(data.frame(
          biol_site_id = "B1",
          sample_id = paste0("S", 1:4),
          Year = 2020:2023,
          Q95_lag0 = c(1.2, 1.1, 1.0, 0.9),
          Q10_lag0 = c(8.1, 8.2, 8.3, 8.4),
          Q95z_lag0 = c(-1, 0.5, -0.25, 1),
          LIFE_F_OE = c(0.83, 1.06, 0.97, 1.31)
        ))
      }
      data.frame(
        biol_site_id = "B1",
        sample_id = paste0("S", 1:4),
        date = as.Date(c("2020-05-01", "2021-05-01", "2022-05-01", "2023-05-01")),
        Year = 2020:2023,
        Season = "Spring",
        win_no_lag0 = 1:4,
        Q95_lag0 = c(1.2, 1.1, 1.0, 0.9),
        Q10_lag0 = c(8.1, 8.2, 8.3, 8.4),
        Q95z_lag0 = c(-1, 0.5, -0.25, 1),
        LIFE_F_OE = c(0.83, 1.06, 0.97, 1.31)
      )
    },
    plot_sitepca_dash = function(...) {
      ggplot2::ggplot(data.frame(x = 1, y = 1), ggplot2::aes(x, y))
    },
    plot_hev_dash = function(...) {
      if (identical(hev_plot_mode$value, "error")) {
        stop("ggplot internal failure at C:/private/hev-source.csv", call. = FALSE)
      }
      if (identical(hev_plot_mode$value, "null")) {
        return(NULL)
      }
      ggplot2::ggplot(data.frame(x = 1, y = 1), ggplot2::aes(x, y))
    },
    hev_dependency_check = function(...) list(
      status = "success",
      message = "HEV plotting dependencies are available."
    ),
    .env = environment(workflow_dashboard_server)
  )

  shiny::testServer(workflow_dashboard_server, {
    local_flow_path <- tempfile("local-flow-f1-", fileext = ".csv")
    utils::write.csv(
      data.frame(
        flow_site_id = "F1",
        date = as.Date(c("2020-05-01", "2021-05-01", "2022-05-01")),
        flow = c(2.4, 2.2, 2.0)
      ),
      local_flow_path,
      row.names = FALSE
    )
    on.exit(unlink(local_flow_path, force = TRUE), add = TRUE)
    local_flow_input <- shiny_upload_input(local_flow_path)

    muffle_interrupted_workflow_promise(session$setInputs(
      meta_paste = "biol_site_id,flow_site_id,flow_input\nB1,F1,HDE",
      local_flow_csv = local_flow_input,
      date_range_biol = as.Date(c("2020-01-01", "2022-12-31")),
      date_range_flow = as.Date(c("2020-01-01", "2022-12-31")),
      import_env = 1
    ))
    muffle_interrupted_workflow_promise(session$flushReact())

    # RAW-12: missing Biology blocks O:E before running and retains other inputs.
    muffle_interrupted_workflow_promise(session$setInputs(calc_OE = 1))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_identical(workflow_artifacts()$oe_result$status, "blocked")
    testthat::expect_match(
      workflow_artifacts()$oe_result$blocking_reason,
      "Biology data are required",
      fixed = TRUE
    )
    testthat::expect_null(oe_request())
    testthat::expect_true(artifact_is_current(workflow_artifacts()$environment_input))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$flow_input))

    muffle_interrupted_workflow_promise(session$setInputs(import_inv = 1))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_true(artifact_is_current(workflow_artifacts()$biology_input))
    testthat::expect_identical(workflow_artifacts()$oe_result$status, "blocked")

    # RAW-13: missing and stale Environmental states block RICT and retain Biology.
    registry <- set_he_artifact_status(
      workflow_artifacts(),
      "environment_input",
      "not_started",
      next_action = "Import Environmental data."
    )
    workflow_artifacts(registry)
    muffle_interrupted_workflow_promise(session$setInputs(run_rict = 1))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_identical(workflow_artifacts()$processed_environment$status, "blocked")
    testthat::expect_match(
      workflow_artifacts()$processed_environment$blocking_reason,
      "Environmental data are required",
      fixed = TRUE
    )
    testthat::expect_null(rict_request())
    testthat::expect_true(artifact_is_current(workflow_artifacts()$biology_input))

    registry <- set_he_artifact_status(
      workflow_artifacts(),
      "environment_input",
      "stale",
      blocking_reason = "Synthetic stale Environmental state.",
      next_action = "Regenerate Environmental data."
    )
    workflow_artifacts(registry)
    muffle_interrupted_workflow_promise(session$setInputs(run_rict = 2))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_identical(workflow_artifacts()$processed_environment$status, "blocked")
    testthat::expect_null(rict_request())

    muffle_interrupted_workflow_promise(session$setInputs(import_env = 2))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_true(artifact_is_current(workflow_artifacts()$environment_input))

    # RAW-14: current Biology/Environment do not substitute for RICT predictions.
    muffle_interrupted_workflow_promise(session$setInputs(calc_OE = 2))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_identical(workflow_artifacts()$oe_result$status, "blocked")
    testthat::expect_match(
      workflow_artifacts()$oe_result$next_action,
      "Run RICT predictions before calculating O:E ratios.",
      fixed = TRUE
    )
    testthat::expect_null(oe_request())
    testthat::expect_true(artifact_is_current(workflow_artifacts()$biology_input))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$environment_input))

    muffle_interrupted_workflow_promise(session$setInputs(run_rict = 3))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_true(artifact_is_current(workflow_artifacts()$processed_environment))
    muffle_interrupted_workflow_promise(session$setInputs(calc_OE = 3))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_true(artifact_is_current(workflow_artifacts()$oe_result))

    # RAW-15: missing and stale Flow Statistics block join without consuming them.
    muffle_interrupted_workflow_promise(session$setInputs(
      choose_lags = 0,
      choose_join_method = "A",
      join_he = 1
    ))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_identical(workflow_artifacts()$joined_core$status, "blocked")
    testthat::expect_match(
      workflow_artifacts()$joined_core$blocking_reason,
      "Flow Statistics are missing or out of date.",
      fixed = TRUE
    )
    testthat::expect_null(join_request())
    testthat::expect_identical(join_calls, 0L)

    muffle_interrupted_workflow_promise(session$setInputs(
      win_width_selector = 6,
      win_step_selector = 6,
      calc_flow_stats = 1
    ))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_true(artifact_is_current(workflow_artifacts()$flow_statistics))

    registry <- set_he_artifact_status(
      workflow_artifacts(),
      "flow_statistics",
      "stale",
      data_source = "retained stale Flow Statistics",
      history_summary = "Must not be consumed by join.",
      blocking_reason = "Synthetic stale Flow Statistics.",
      next_action = "Regenerate Flow Statistics."
    )
    workflow_artifacts(registry)
    muffle_interrupted_workflow_promise(session$setInputs(
      join_he = 2
    ))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_identical(workflow_artifacts()$joined_core$status, "blocked")
    testthat::expect_identical(workflow_artifacts()$flow_statistics$status, "stale")
    testthat::expect_identical(join_calls, 0L)
    testthat::expect_true(artifact_is_current(workflow_artifacts()$oe_result))

    muffle_interrupted_workflow_promise(session$setInputs(calc_flow_stats = 2))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_true(artifact_is_current(workflow_artifacts()$flow_statistics))

    # RAW-16: missing and stale O:E block join while Flow Statistics are retained.
    registry <- set_he_artifact_status(
      workflow_artifacts(),
      "oe_result",
      "not_started",
      next_action = "Calculate O:E ratios."
    )
    workflow_artifacts(registry)
    muffle_interrupted_workflow_promise(session$setInputs(join_he = 3))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_identical(workflow_artifacts()$joined_core$status, "blocked")
    testthat::expect_match(
      workflow_artifacts()$joined_core$blocking_reason,
      "O:E ratios are required before building the Joined HE Dataset.",
      fixed = TRUE
    )
    testthat::expect_null(join_request())
    testthat::expect_identical(join_calls, 0L)
    testthat::expect_true(artifact_is_current(workflow_artifacts()$flow_statistics))

    registry <- set_he_artifact_status(
      workflow_artifacts(),
      "oe_result",
      "stale",
      data_source = "retained stale O:E",
      history_summary = "Must not be consumed by join.",
      blocking_reason = "Synthetic stale O:E state.",
      next_action = "Regenerate O:E ratios."
    )
    workflow_artifacts(registry)
    muffle_interrupted_workflow_promise(session$setInputs(join_he = 4))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_identical(workflow_artifacts()$joined_core$status, "blocked")
    testthat::expect_match(
      workflow_artifacts()$joined_core$blocking_reason,
      "O:E ratios are required before building the Joined HE Dataset.",
      fixed = TRUE
    )
    testthat::expect_null(join_request())
    testthat::expect_identical(join_calls, 0L)
    testthat::expect_true(artifact_is_current(workflow_artifacts()$flow_statistics))

    muffle_interrupted_workflow_promise(session$setInputs(calc_OE = 4))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_true(artifact_is_current(workflow_artifacts()$oe_result))

    # Raw daily Flow HEV does not require Flow Statistics or the Joined HE Dataset.
    muffle_interrupted_workflow_promise(session$setInputs(
      site_selector = "B1",
      hev_flow_data_mode = "daily_flow",
      biol_metric_selector = "LIFE_F_OE",
      flow_metric_selector = "Q95",
      HEV_date_range = c(2020, 2022),
      HEV_show_all_metrics = FALSE,
      HEV_show_high_low = FALSE,
      renderHEV = 1
    ))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_identical(hev_request(), 1)
    testthat::expect_silent(HEV_data())
    testthat::expect_true("flow" %in% names(HEV_data()))
    testthat::expect_s3_class(HEV_plot(), "ggplot")
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_true(artifact_is_current(workflow_artifacts()$hev_result))
    testthat::expect_identical(hev_current_result()$provenance$flow_mode, "daily_flow")

    # RAW-17: HEV blocks until a current Joined HE Dataset exists.
    muffle_interrupted_workflow_promise(session$setInputs(
      site_selector = "B1",
      hev_flow_data_mode = "flow_statistics",
      biol_metric_selector = "LIFE_F_OE",
      flow_metric_selector = "Q95",
      HEV_date_range = c(2020, 2022),
      HEV_show_all_metrics = FALSE,
      HEV_show_high_low = FALSE,
      renderHEV = 2
    ))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_identical(workflow_artifacts()$hev_result$status, "blocked")
    testthat::expect_match(
      workflow_artifacts()$hev_result$blocking_reason,
      "Joined HE Dataset is missing or out of date",
      fixed = TRUE
    )
    testthat::expect_null(hev_request())

    muffle_interrupted_workflow_promise(session$setInputs(join_he = 5))
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
      renderHEV = 3
    ))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_identical(hev_request(), 3)
    testthat::expect_true(artifact_is_current(workflow_artifacts()$joined_core))
    testthat::expect_identical(hev_plot_dependency_status()$status, "success")
    testthat::expect_silent(HEV_data())
    testthat::expect_silent(HEV_plot_data())
    testthat::expect_silent(HEV_go())
    testthat::expect_named(
      HEV_go(),
      c(
        "data", "analysis_context", "site_id",
        "flow_mode", "flow_source_revision", "date_range",
        "biol_metric_selector", "flow_metric_selector", "show_all_metrics",
        "show_high_low", "show_status", "river_type"
      )
    )
    testthat::expect_identical(HEV_go()$river_type, "non_chalk")
    testthat::expect_s3_class(HEV_plot(), "ggplot")
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_true(artifact_is_current(workflow_artifacts()$hev_result))
    previous_provenance <- hev_current_result()$provenance
    hev_download_history(append_hev_download_history(
      hev_download_history(),
      previous_provenance,
      "PNG",
      downloaded_at = as.POSIXct("2026-08-07 12:00:00", tz = "UTC")
    ))
    testthat::expect_equal(nrow(hev_download_history()), 1L)

    muffle_interrupted_workflow_promise(session$setInputs(choose_lags = 1))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_identical(workflow_artifacts()$joined_core$status, "stale")
    testthat::expect_identical(workflow_artifacts()$hev_result$status, "stale")
    testthat::expect_identical(hev_current_result()$status, "stale")
    testthat::expect_equal(nrow(hev_download_history()), 1L)
    testthat::expect_identical(
      hev_download_history()$source_fingerprint,
      previous_provenance$source_fingerprint
    )
    testthat::expect_error(HEV_plot(), class = "shiny.silent.error")

    muffle_interrupted_workflow_promise(session$setInputs(renderHEV = 4))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_identical(workflow_artifacts()$hev_result$status, "blocked")
    testthat::expect_null(hev_request())
    testthat::expect_false(identical(hev_current_result()$status, "success"))
    testthat::expect_equal(nrow(hev_download_history()), 1L)
    testthat::expect_error(HEV_plot(), class = "shiny.silent.error")
    testthat::expect_true(artifact_is_current(workflow_artifacts()$oe_result))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$flow_statistics))

    muffle_interrupted_workflow_promise(session$setInputs(join_he = 6))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_true(artifact_is_current(workflow_artifacts()$joined_core))
    testthat::expect_identical(workflow_artifacts()$hev_result$status, "blocked")
    testthat::expect_identical(hev_current_result()$status, "not_ready")
    testthat::expect_equal(nrow(hev_download_history()), 1L)

    muffle_interrupted_workflow_promise(session$setInputs(renderHEV = 5))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_s3_class(HEV_plot(), "ggplot")
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_true(artifact_is_current(workflow_artifacts()$hev_result))
    testthat::expect_identical(hev_current_result()$status, "success")
    testthat::expect_identical(hev_current_result()$provenance$source_dataset, "joined_core")
    testthat::expect_identical(hev_current_result()$provenance$flow_mode, "flow_statistics")
    testthat::expect_identical(hev_current_result()$provenance$filter_version, 0L)
    testthat::expect_equal(nrow(hev_download_history()), 1L)

    muffle_interrupted_workflow_promise(session$setInputs(HEV_show_high_low = TRUE))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_identical(workflow_artifacts()$hev_result$status, "stale")
    testthat::expect_identical(hev_current_result()$status, "stale")

    muffle_interrupted_workflow_promise(session$setInputs(renderHEV = 3))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_true(artifact_is_current(workflow_artifacts()$hev_result))
    testthat::expect_identical(hev_current_result()$status, "success")

    # RAW-18: a plotting exception or unusable result fails only the new HEV
    # request, retains prior HEV history/upstream data and can be retried.
    retained_plot <- hev_current_result()$plot
    retained_data <- hev_current_result()$data
    retained_provenance <- hev_current_result()$provenance
    retained_history <- hev_download_history()
    retained_upstream <- workflow_artifacts()[c(
      "biology_input", "environment_input", "flow_input", "flow_statistics",
      "oe_result", "joined_core", "analysis_dataset", "model_result"
    )]

    hev_plot_mode$value <- "error"
    muffle_interrupted_workflow_promise(session$setInputs(renderHEV = 6))
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_identical(workflow_artifacts()$hev_result$status, "failed")
    testthat::expect_identical(hev_current_result()$status, "failed")
    testthat::expect_identical(hev_current_result()$plot, retained_plot)
    testthat::expect_identical(hev_current_result()$data, retained_data)
    testthat::expect_identical(hev_current_result()$provenance, retained_provenance)
    testthat::expect_identical(hev_download_history(), retained_history)
    testthat::expect_false(workflow_artifacts()$hev_result$status %in% c("running", "complete", "warning"))
    testthat::expect_match(output$hev_status_message$html, "The plot could not be created", fixed = TRUE)
    testthat::expect_false(grepl("ggplot|C:/private|hev-source", output$hev_status_message$html))
    testthat::expect_error(HEV_plot(), class = "shiny.silent.error")
    testthat::expect_identical(
      vapply(workflow_artifacts()[names(retained_upstream)], `[[`, character(1), "status"),
      vapply(retained_upstream, `[[`, character(1), "status")
    )

    hev_plot_mode$value <- "null"
    muffle_interrupted_workflow_promise(session$setInputs(renderHEV = 7))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_identical(workflow_artifacts()$hev_result$status, "failed")
    testthat::expect_identical(hev_current_result()$plot, retained_plot)
    testthat::expect_identical(hev_download_history(), retained_history)

    hev_plot_mode$value <- "success"
    muffle_interrupted_workflow_promise(session$setInputs(renderHEV = 8))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_s3_class(HEV_plot(), "ggplot")
    testthat::expect_true(artifact_is_current(workflow_artifacts()$hev_result))
    testthat::expect_identical(hev_current_result()$status, "success")
    testthat::expect_identical(hev_download_history(), retained_history)

    joined_before_filter <- join_data()
    record_ids <- as.character(joined_before_filter$sample_id)
    record_id <- record_ids[[1L]]
    excluded_row_count <- sum(record_ids == record_id)
    selector_html <- output$analysis_record_selector$html

    testthat::expect_match(selector_html, 'data-id-column="record_id"', fixed = TRUE)
    testthat::expect_match(selector_html, "Record ID", fixed = TRUE)
    testthat::expect_match(selector_html, record_id, fixed = TRUE)
    testthat::expect_match(selector_html, 'width:100%', fixed = TRUE)
    testthat::expect_match(
      selector_html,
      "Choose the identifier shown in the current Joined HE dataset.",
      fixed = TRUE
    )

    muffle_interrupted_workflow_promise(session$setInputs(
      analysis_record_id = record_id,
      exclude_analysis_record = 1
    ))
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_equal(
      nrow(analysis_filter_result()$analysis_dataset),
      nrow(joined_before_filter) - excluded_row_count
    )
    testthat::expect_identical(current_analysis_data(), analysis_filter_result()$analysis_dataset)
    testthat::expect_false(record_id %in% as.character(HEV_data()$sample_id))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$filter_selection))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$exclusion_log))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$analysis_dataset))
    testthat::expect_identical(workflow_artifacts()$model_result$status, "stale")
    testthat::expect_identical(workflow_artifacts()$hev_result$status, "stale")
    testthat::expect_identical(basic_model_result()$status, "info")
    exclusion_log_after_exclude <- analysis_exclusion_log()
    testthat::expect_equal(nrow(exclusion_log_after_exclude), 1L)
    testthat::expect_identical(exclusion_log_after_exclude$record_id, record_id)
    testthat::expect_identical(exclusion_log_after_exclude$sample_id, record_id)
    testthat::expect_false(is.na(exclusion_log_after_exclude$site_id))
    testthat::expect_identical(exclusion_log_after_exclude$current_status, "excluded")

    muffle_interrupted_workflow_promise(session$setInputs(
      restore_analysis_record = 1
    ))
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_equal(
      nrow(analysis_filter_result()$analysis_dataset),
      nrow(joined_before_filter)
    )
    testthat::expect_true(record_id %in% as.character(HEV_data()$sample_id))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$filter_selection))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$exclusion_log))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$analysis_dataset))
    testthat::expect_identical(workflow_artifacts()$model_result$status, "stale")
    testthat::expect_identical(workflow_artifacts()$hev_result$status, "stale")
    exclusion_log_after_restore <- analysis_exclusion_log()
    testthat::expect_equal(nrow(exclusion_log_after_restore), 2L)
    testthat::expect_true(all(exclusion_log_after_restore$current_status == "restored"))
  })
})

testthat::test_that("an unavailable browser backend rejects forged save events", {
  workspace_root <- tempfile("disabled-server-workspace-storage-")
  old_options <- options(
    hetoolkit.workspace_root = workspace_root,
    hetoolkit.workspace_storage_factory = function(session) {
      new_browser_workspace_storage()
    }
  )
  on.exit(options(old_options), add = TRUE)

  shiny::testServer(workflow_dashboard_server, {
    testthat::expect_s3_class(workspace_storage, "browser_workspace_storage")
    testthat::expect_false(workspace_save_available)
    muffle_interrupted_workflow_promise(session$flushReact())
    muffle_interrupted_workflow_promise(session$setInputs(
      workspace_name = "Must not be written",
      save_workspace = 1
    ))
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_identical(workspace_save_status()$status, "error")
    testthat::expect_match(
      workspace_save_status()$message,
      "not configured",
      fixed = TRUE
    )
    testthat::expect_false(dir.exists(workspace_root))
  })
})

testthat::test_that("the default local backend writes a named, restorable workspace", {
  workspace_root <- tempfile("server-workspace-storage-")
  on.exit(unlink(workspace_root, recursive = TRUE, force = TRUE), add = TRUE)
  old_options <- options(hetoolkit.workspace_root = workspace_root)
  on.exit(options(old_options), add = TRUE)

  shiny::testServer(workflow_dashboard_server, {
    testthat::expect_s3_class(workspace_storage, "server_file_workspace_storage")
    testthat::expect_true(workspace_save_available)
    muffle_interrupted_workflow_promise(session$flushReact())
    workflow_session$task_id <- "generate_hev"
    workflow_session$stage_index <- 1L
    analysis_filter_selection(list(excluded_record_ids = "S1"))

    muffle_interrupted_workflow_promise(session$setInputs(
      workspace_name = "Customer review copy",
      choose_join_method = "A",
      save_workspace = 1
    ))
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_identical(workspace_save_status()$status, "success")
    testthat::expect_identical(
      workspace_save_status()$result$workspace_name,
      "Customer review copy"
    )
    testthat::expect_match(
      workspace_save_status()$message,
      "on this computer",
      fixed = TRUE
    )

    stored <- workspace_storage_load(
      workspace_storage,
      "Customer review copy",
      dataset_names = character()
    )
    testthat::expect_identical(stored$state$workflow_session$task_id, "generate_hev")
    testthat::expect_identical(stored$state$workflow_session$stage_index, 1L)
    testthat::expect_identical(stored$state$input_values$choose_join_method, "A")
    testthat::expect_false("local_flow_csv" %in% names(stored$state$input_values))
    testthat::expect_identical(
      stored$state$runtime_state$analysis_filter_selection$excluded_record_ids,
      "S1"
    )
  })
})

testthat::test_that("a processed dataset checkpoint restores downstream state in a new session", {
  checkpoint_path <- tempfile("joined-he-checkpoint-", fileext = ".rds")
  on.exit(unlink(checkpoint_path, force = TRUE), add = TRUE)
  checkpoint_data <- data.frame(
    biol_site_id = "B1",
    sample_id = paste0("S", 1:3),
    date = as.Date(c("2020-05-01", "2021-05-01", "2022-05-01")),
    Year = 2020:2022,
    Q95_lag0 = c(1.2, 1.1, 1.0),
    Q95z_lag0 = c(-1, 0, 1),
    LIFE_F_OE = c(0.8, 1.0, 1.2),
    stringsAsFactors = FALSE
  )
  write_processed_dataset_checkpoint(
    checkpoint_data,
    checkpoint_path,
    provenance = list(source = "first test session"),
    app_version = "test-commit"
  )
  upload <- shiny_upload_input(checkpoint_path, "application/octet-stream")

  shiny::testServer(workflow_dashboard_server, {
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_match(
      output$processed_dataset_checkpoint_download$html,
      "Download becomes available",
      fixed = TRUE
    )
    muffle_interrupted_workflow_promise(session$setInputs(
      processed_dataset_checkpoint_file = upload,
      load_processed_dataset_checkpoint = 1
    ))
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_identical(active_join_source(), "checkpoint")
    testthat::expect_identical(join_data(), checkpoint_data)
    testthat::expect_identical(current_analysis_data(), checkpoint_data)
    testthat::expect_true("Q95" %in% names(HEV_data()))
    testthat::expect_s3_class(HEV_data()$date, "Date")
    testthat::expect_identical(processed_checkpoint_load_status()$status, "success")
    testthat::expect_true(artifact_is_current(workflow_artifacts()$joined_core))
    testthat::expect_true(artifact_is_current(
      workflow_artifacts()$processed_dataset_checkpoint
    ))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$analysis_dataset))
    testthat::expect_match(
      output$processed_dataset_checkpoint_download$html,
      'id="download_processed_dataset_checkpoint"',
      fixed = TRUE
    )

    registry_before_flow_edit <- workflow_artifacts()
    muffle_interrupted_workflow_promise(session$setInputs(meta_paste = "changed mapping"))
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_true(artifact_is_current(workflow_artifacts()$joined_core))
    testthat::expect_identical(join_data(), checkpoint_data)
    testthat::expect_gte(
      workflow_artifacts()$joined_core$output_revision,
      registry_before_flow_edit$joined_core$output_revision
    )
  })
})

testthat::test_that("Stage 5 routes multi-site data through the formal mixed model", {
  checkpoint_path <- tempfile("formal-mixed-model-checkpoint-", fileext = ".rds")
  on.exit(unlink(checkpoint_path, force = TRUE), add = TRUE)

  sites <- paste0("B", 1:6)
  years <- 2018:2023
  checkpoint_data <- expand.grid(
    biol_site_id = sites,
    sampling_year = years,
    stringsAsFactors = FALSE
  )
  checkpoint_data$sample_id <- paste0("M", seq_len(nrow(checkpoint_data)))
  checkpoint_data$Year <- checkpoint_data$sampling_year
  checkpoint_data$date <- as.Date(paste0(checkpoint_data$sampling_year, "-05-01"))
  checkpoint_data$Q95z_lag0 <- rep(seq(-1.5, 1.5, length.out = length(years)), length(sites)) +
    rep(seq(-0.2, 0.2, length.out = length(sites)), each = length(years))
  site_effect <- stats::setNames(seq(-0.3, 0.3, length.out = length(sites)), sites)
  checkpoint_data$LIFE_F_OE <- 1 +
    0.2 * checkpoint_data$Q95z_lag0 +
    0.03 * (checkpoint_data$sampling_year - mean(years)) +
    site_effect[checkpoint_data$biol_site_id]

  write_processed_dataset_checkpoint(checkpoint_data, checkpoint_path)
  upload <- shiny_upload_input(checkpoint_path, "application/octet-stream")

  shiny::testServer(workflow_dashboard_server, {
    muffle_interrupted_workflow_promise(session$flushReact())
    muffle_interrupted_workflow_promise(session$setInputs(
      processed_dataset_checkpoint_file = upload,
      load_processed_dataset_checkpoint = 1
    ))
    muffle_interrupted_workflow_promise(session$flushReact())

    muffle_interrupted_workflow_promise(session$setInputs(
      basic_model_flow_var = "Q95z_lag0",
      basic_model_ecology_var = "LIFE_F_OE",
      basic_model_wq_var = "",
      basic_model_rhs_var = "",
      run_basic_model = 1
    ))
    muffle_interrupted_workflow_promise(session$flushReact())

    result <- basic_model_result()
    testthat::expect_true(result$status %in% c("success", "warning"))
    testthat::expect_identical(result$model_path, "multi_site_mixed")
    testthat::expect_match(result$formula, "biol_site_id", fixed = TRUE)
    testthat::expect_equal(result$site_count, length(sites))
    testthat::expect_s3_class(result$fixed_effects, "data.frame")
    testthat::expect_s3_class(result$random_effects, "data.frame")
    testthat::expect_s3_class(result$diagnostic_plot, "ggplot")
    testthat::expect_true(artifact_is_current(workflow_artifacts()$model_result))
    testthat::expect_match(
      output$basic_model_download_controls$html,
      'id="download_basic_model_random_effects"',
      fixed = TRUE
    )
  })
})

testthat::test_that("RAW-24 model UI hides diagnostics, retains upstream state and retries", {
  model_mode <- new.env(parent = emptyenv())
  model_mode$value <- "error"
  original_model_runner <- get(
    "run_analysis_model",
    envir = environment(workflow_dashboard_server)
  )
  rlang::local_bindings(
    run_analysis_model = function(...) {
      if (identical(model_mode$value, "error")) {
        stop(
          paste(
            "lm.fit stats package failure at",
            "C:/Users/developer/AppData/Local/Temp/model-input.csv"
          ),
          call. = FALSE
        )
      }
      original_model_runner(...)
    },
    .env = environment(workflow_dashboard_server)
  )

  checkpoint_path <- tempfile("raw24-model-checkpoint-", fileext = ".rds")
  on.exit(unlink(checkpoint_path, force = TRUE), add = TRUE)
  checkpoint_data <- data.frame(
    biol_site_id = "B1",
    sample_id = paste0("S", 1:4),
    date = as.Date(c("2020-05-01", "2021-05-01", "2022-05-01", "2023-05-01")),
    Year = 2020:2023,
    Q95z_lag0 = c(-1.5, -0.5, 0.5, 1.5),
    LIFE_F_OE = c(0.7, 0.92, 1.05, 1.31),
    stringsAsFactors = FALSE
  )
  write_processed_dataset_checkpoint(checkpoint_data, checkpoint_path)
  upload <- shiny_upload_input(checkpoint_path, "application/octet-stream")

  shiny::testServer(workflow_dashboard_server, {
    muffle_interrupted_workflow_promise(session$flushReact())

    checkpoint_fallback <- paste(
      "Processed dataset checkpoint could not be loaded.",
      "Use a checkpoint downloaded from this dashboard."
    )
    checkpoint_path_error <- simpleError(paste(
      "Processed dataset checkpoint readRDS failed at",
      "C:/Users/developer/AppData/Local/Temp/checkpoint.rds"
    ))
    workspace_path_error <- simpleError(
      "Workspace save failed in reactive storage at /tmp/private/workspace.rds"
    )
    testthat::expect_identical(
      processed_checkpoint_user_error_message(checkpoint_path_error),
      checkpoint_fallback
    )
    testthat::expect_identical(
      processed_checkpoint_user_error_message(simpleError(
        "Processed dataset checkpoint is missing required column 'Year'."
      )),
      "Processed dataset checkpoint is missing required column 'Year'."
    )
    testthat::expect_identical(
      workspace_user_error_message(workspace_path_error),
      "Workspace could not be saved. Check the name and local storage configuration."
    )
    testthat::expect_false(grepl(
      "readRDS|reactive|C:/Users|AppData|/tmp/private",
      paste(
        processed_checkpoint_user_error_message(checkpoint_path_error),
        workspace_user_error_message(workspace_path_error)
      )
    ))
    testthat::expect_message(
      record_raw24_condition_diagnostic("checkpoint test", checkpoint_path_error),
      "C:/Users/developer/AppData/Local/Temp/checkpoint.rds",
      fixed = TRUE
    )

    muffle_interrupted_workflow_promise(session$setInputs(
      processed_dataset_checkpoint_file = upload,
      load_processed_dataset_checkpoint = 1
    ))
    muffle_interrupted_workflow_promise(session$flushReact())
    retained_upstream <- workflow_artifacts()[c("joined_core", "analysis_dataset")]

    testthat::expect_message(
      muffle_interrupted_workflow_promise(session$setInputs(
        basic_model_flow_var = "Q95z_lag0",
        basic_model_ecology_var = "LIFE_F_OE",
        run_basic_model = 1
      )),
      "RAW-24 model diagnostic: lm.fit stats package failure",
      fixed = TRUE
    )
    muffle_interrupted_workflow_promise(session$flushReact())

    safe_message <- "The model could not be fitted with the selected variables."
    testthat::expect_identical(basic_model_result()$status, "failed")
    testthat::expect_identical(basic_model_result()$messages, safe_message)
    testthat::expect_match(basic_model_result()$diagnostic, "C:/Users/developer", fixed = TRUE)
    testthat::expect_match(output$basic_model_status$html, safe_message, fixed = TRUE)
    testthat::expect_false(grepl(
      "conditionMessage|lm.fit|stats package|C:/Users|AppData|model-input",
      output$basic_model_status$html
    ))
    testthat::expect_identical(workflow_artifacts()$model_result$status, "failed")
    testthat::expect_identical(
      workflow_artifacts()$model_result$blocking_reason,
      safe_message
    )
    testthat::expect_identical(
      workflow_artifacts()[c("joined_core", "analysis_dataset")],
      retained_upstream
    )
    testthat::expect_true(artifact_is_current(workflow_artifacts()$joined_core))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$analysis_dataset))

    model_mode$value <- "success"
    muffle_interrupted_workflow_promise(session$setInputs(run_basic_model = 2))
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_identical(basic_model_result()$status, "success")
    testthat::expect_null(basic_model_result()$diagnostic)
    testthat::expect_s3_class(basic_model_result()$diagnostic_plot, "ggplot")
    testthat::expect_identical(
      names(basic_model_result()$diagnostics),
      c("fitted", "residual")
    )
    testthat::expect_match(
      output$basic_model_download_controls$html,
      'id="download_basic_model_summary"',
      fixed = TRUE
    )
    testthat::expect_match(
      output$basic_model_download_controls$html,
      'id="download_basic_model_diagnostics"',
      fixed = TRUE
    )
    testthat::expect_match(
      output$basic_model_download_controls$html,
      'id="download_basic_model_coefficients"',
      fixed = TRUE
    )
    testthat::expect_true(artifact_is_current(workflow_artifacts()$model_result))
    testthat::expect_identical(current_analysis_data(), checkpoint_data)
  })
})

testthat::test_that("a failed checkpoint upload does not replace current data", {
  valid_path <- tempfile("joined-he-checkpoint-", fileext = ".rds")
  invalid_path <- tempfile("joined-he-checkpoint-invalid-", fileext = ".rds")
  on.exit(unlink(c(valid_path, invalid_path), force = TRUE), add = TRUE)
  checkpoint_data <- data.frame(
    biol_site_id = "B1",
    sample_id = "S1",
    Year = 2020L,
    Q95z_lag0 = 0,
    LIFE_F_OE = 1,
    stringsAsFactors = FALSE
  )
  write_processed_dataset_checkpoint(checkpoint_data, valid_path)
  writeLines("not an R checkpoint", invalid_path, useBytes = TRUE)
  upload <- function(path) shiny_upload_input(path, "application/octet-stream")

  shiny::testServer(workflow_dashboard_server, {
    muffle_interrupted_workflow_promise(session$flushReact())
    muffle_interrupted_workflow_promise(session$setInputs(
      processed_dataset_checkpoint_file = upload(valid_path),
      load_processed_dataset_checkpoint = 1
    ))
    muffle_interrupted_workflow_promise(session$flushReact())
    current_data <- join_data()

    muffle_interrupted_workflow_promise(session$setInputs(
      processed_dataset_checkpoint_file = upload(invalid_path),
      load_processed_dataset_checkpoint = 2
    ))
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_identical(processed_checkpoint_load_status()$status, "error")
    testthat::expect_identical(join_data(), current_data)
    testthat::expect_true(artifact_is_current(workflow_artifacts()$joined_core))
  })
})

testthat::test_that("RAW-19 HEV download records history only after a successful file write", {
  plot_value <- ggplot2::ggplot(
    data.frame(x = 1, y = 1),
    ggplot2::aes(x, y)
  ) + ggplot2::geom_point()
  history <- empty_hev_download_history()
  provenance <- list(
    site_id = "B1",
    biology_metrics = "LIFE_F_OE",
    flow_metrics = "Q95",
    date_range = "2020-01-01-2020-12-31",
    source_dataset = "joined_core",
    source_fingerprint = "fixture-fingerprint",
    filter_version = 0L
  )
  write_attempts <- 0L
  write_plot <- function(file, plot) {
    write_attempts <<- write_attempts + 1L
    testthat::expect_identical(plot, plot_value)
    if (write_attempts == 1L) {
      stop("ggsave Permission denied C:/Users/private/hev.png", call. = FALSE)
    }
    writeLines("test image", file)
  }
  on_download <- function(format, file) {
    history <<- append_hev_download_history(history, provenance, format)
  }

  shiny::testServer(
    downloadServer,
    args = list(
      id = "hev_download_test",
      plot = function() plot_value,
      can_download = function() TRUE,
      on_download = on_download,
      write_plot = write_plot
    ),
    {
      api <- session$getReturned()
      output_path <- tempfile("hev-download-", fileext = ".png")
      on.exit(unlink(output_path, force = TRUE), add = TRUE)

      failure <- tryCatch(api$write_download(output_path, "PNG"), error = identity)
      testthat::expect_s3_class(failure, "shiny.silent.error")
      testthat::expect_match(conditionMessage(failure), "The file could not be created or saved", fixed = TRUE)
      testthat::expect_false(grepl("ggsave|Permission denied|C:/Users", conditionMessage(failure)))
      testthat::expect_equal(nrow(history), 0L)
      testthat::expect_false(file.exists(output_path))

      testthat::expect_error(api$write_download(output_path, "PNG"), NA)
      testthat::expect_true(file.exists(output_path))
      testthat::expect_equal(nrow(history), 1L)
      testthat::expect_identical(history$format, "PNG")
      testthat::expect_identical(write_attempts, 2L)
      testthat::expect_identical(plot_value$data$x, 1)
    }
  )
})

testthat::test_that("RAW-01 missing HEV dependency blocks safely and ends the request", {
  rlang::local_bindings(
    hev_dependency_check = function(...) list(
      status = "error",
      message = paste(
        "The required package ggnewscale is missing.",
        "Please install project dependencies before using the HEV plot feature."
      )
    ),
    .env = environment(workflow_dashboard_server)
  )

  shiny::testServer(workflow_dashboard_server, {
    muffle_interrupted_workflow_promise(session$flushReact())
    muffle_interrupted_workflow_promise(session$setInputs(renderHEV = 1))
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_identical(hev_plot_dependency_status()$status, "error")
    testthat::expect_identical(workflow_artifacts()$hev_result$status, "blocked")
    testthat::expect_match(
      output$hev_status_message$html,
      "The required package ggnewscale is missing.",
      fixed = TRUE
    )
  })
})
