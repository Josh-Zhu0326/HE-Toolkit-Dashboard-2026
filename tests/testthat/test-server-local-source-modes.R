dashboard_server <- workflow_dashboard_server

testthat::test_that("local Biology and Environmental CSVs enter their active data flows", {
  biology_file <- tempfile("local-biology-", fileext = ".csv")
  environment_file <- tempfile("local-environment-", fileext = ".csv")
  on.exit(unlink(c(biology_file, environment_file), force = TRUE), add = TRUE)

  writeLines(c(
    "biol_site_id,SAMPLE_ID,SAMPLE_DATE,WHPT_ASPT,WHPT_N_TAXA,LIFE_FAMILY_INDEX,PSI_FAMILY_SCORE,Month,Year,Season",
    "B01,S01,2024-05-01,6.1,,,,5,2024,Spring"
  ), biology_file, useBytes = TRUE)
  readr::write_csv(local_dataset_template_data("environment"), environment_file)

  shiny::testServer(dashboard_server, {
    set_inputs_ignoring_interrupted_promises(
      session,
      biology_source_mode = "local",
      environment_source_mode = "local",
      local_biology_csv = shiny_upload_input(biology_file),
      local_environment_csv = shiny_upload_input(environment_file)
    )
    session$flushReact()

    testthat::expect_identical(biol_data()$SAMPLE_ID, "S01")
    testthat::expect_identical(env_data()$biol_site_id, "B01")
    testthat::expect_true(artifact_is_current(workflow_artifacts()$biology_input))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$environment_input))
  })
})

testthat::test_that("Flow combine mode retains external and local records", {
  importer_calls <- 0L
  rlang::local_bindings(
    import_dashboard_flow = function(...) {
      importer_calls <<- importer_calls + 1L
      data.frame(
        flow_site_id = "27090",
        date = as.Date("2024-01-01"),
        flow = 99,
        stringsAsFactors = FALSE
      )
    },
    .env = environment(dashboard_server)
  )

  shiny::testServer(dashboard_server, {
    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = "biol_site_id,flow_site_id\n291,27090",
      flow_source_mode = "combine",
      local_flow_csv = shiny_upload_input(
        testthat::test_path("..", "fixtures", "local_flow.csv")
      ),
      date_range_flow = as.Date(c("2024-01-01", "2024-12-31")),
      import_flow = 1
    )
    session$flushReact()

    combined <- flow_data()
    testthat::expect_equal(nrow(combined), 4L)
    testthat::expect_equal(sum(combined$flow_site_id == "27090"), 3L)
    testthat::expect_identical(importer_calls, 1L)
    testthat::expect_true(artifact_is_current(workflow_artifacts()$flow_input))
    testthat::expect_identical(source_resolution_provenance(combined)$mode, "combine")
    testthat::expect_match(
      workflow_artifacts()$flow_input$history_summary,
      "1 external, 3 local",
      fixed = TRUE
    )
  })
})

testthat::test_that("combine mode stays blocked until both Flow sources exist", {
  rlang::local_bindings(
    import_dashboard_flow = function(...) {
      data.frame(
        flow_site_id = "27090",
        date = as.Date("2024-01-01"),
        flow = 99,
        stringsAsFactors = FALSE
      )
    },
    .env = environment(dashboard_server)
  )

  shiny::testServer(dashboard_server, {
    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = "biol_site_id,flow_site_id\n291,27090",
      flow_source_mode = "combine",
      date_range_flow = as.Date(c("2024-01-01", "2024-12-31")),
      import_flow = 1
    )
    session$flushReact()

    testthat::expect_identical(workflow_artifacts()$flow_input$status, "blocked")
    testthat::expect_match(
      workflow_artifacts()$flow_input$blocking_reason,
      "requires a valid local Flow CSV",
      fixed = TRUE
    )
    testthat::expect_error(flow_data(), class = "shiny.silent.error")
  })
})

testthat::test_that("mapped WQ and RHS combine modes retain both sources", {
  replacement_wq <- tempfile("replacement-wq-", fileext = ".csv")
  file.copy(testthat::test_path("..", "fixtures", "wq.csv"), replacement_wq)
  on.exit(unlink(replacement_wq, force = TRUE), add = TRUE)

  shiny::testServer(dashboard_server, {
    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = paste(
        "biol_site_id,flow_site_id,wq_site_id,rhs_survey_id",
        "291,27090,SW-A4070115,RHS001",
        "292,27091,SW-A4070116,RHS002",
        sep = "\n"
      ),
      wq_source_mode = "combine",
      rhs_source_mode = "combine",
      wq_csv = shiny_upload_input(testthat::test_path("..", "fixtures", "wq.csv")),
      rhs_csv = shiny_upload_input(testthat::test_path("..", "fixtures", "rhs.csv"))
    )
    wq_site_import_data(data.frame(
      biol_site_id = "291",
      wq_site_id = "SW-A4070115",
      wq_site_name = "External WQ site",
      easting = 123456,
      northing = 654321,
      area = "Example area",
      date_time = "2023-12-01",
      det_id = "0180",
      determinand = "Orthophosphate reactive as P",
      result = 0.07,
      unit = "mg/L",
      qualifier = NA_character_,
      observation = NA_character_,
      stringsAsFactors = FALSE,
      check.names = FALSE
    ))
    rhs_site_import_data(data.frame(
      biol_site_id = "292",
      rhs_survey_id = "RHS002",
      Survey.Status = "Complete",
      HQA = 60,
      HMS.Score = 22,
      stringsAsFactors = FALSE,
      check.names = FALSE
    ))
    session$flushReact()

    testthat::expect_equal(nrow(mapped_wq_plot_data()), 4L)
    testthat::expect_equal(nrow(mapped_rhs_plot_data()), 3L)
    testthat::expect_true(artifact_is_current(workflow_artifacts()$wq_input))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$rhs_input))
    testthat::expect_identical(
      source_resolution_provenance(mapped_wq_plot_data())$mode,
      "combine"
    )

    wq_contract_summary_result(list(
      status = "success",
      messages = "Previous summary fixture.",
      data = data.frame(sample_id = "S1")
    ))
    set_inputs_ignoring_interrupted_promises(
      session,
      wq_csv = shiny_upload_input(replacement_wq)
    )
    session$flushReact()

    testthat::expect_identical(wq_contract_summary_result()$status, "info")
    testthat::expect_true(source_data_available(wq_site_import_data()))
    testthat::expect_equal(nrow(mapped_wq_plot_data()), 4L)
  })
})

testthat::test_that("local WQ and RHS stay blocked until site mapping succeeds", {
  shiny::testServer(dashboard_server, {
    set_inputs_ignoring_interrupted_promises(
      session,
      wq_source_mode = "local",
      rhs_source_mode = "local",
      wq_csv = shiny_upload_input(testthat::test_path("..", "fixtures", "wq.csv")),
      rhs_csv = shiny_upload_input(testthat::test_path("..", "fixtures", "rhs.csv"))
    )
    session$flushReact()

    testthat::expect_identical(workflow_artifacts()$wq_input$status, "blocked")
    testthat::expect_identical(workflow_artifacts()$rhs_input$status, "blocked")
    testthat::expect_match(
      workflow_artifacts()$wq_input$blocking_reason,
      "site mapping",
      fixed = TRUE
    )
    testthat::expect_match(
      workflow_artifacts()$rhs_input$blocking_reason,
      "site mapping",
      fixed = TRUE
    )
    testthat::expect_error(mapped_wq_plot_data(), class = "shiny.silent.error")
    testthat::expect_error(mapped_rhs_plot_data(), class = "shiny.silent.error")
  })
})

testthat::test_that("partial local WQ and RHS mappings report counts and stay blocked", {
  wq_file <- tempfile("partial-wq-", fileext = ".csv")
  rhs_file <- tempfile("partial-rhs-", fileext = ".csv")
  on.exit(unlink(c(wq_file, rhs_file), force = TRUE), add = TRUE)

  wq <- rbind(local_dataset_template_data("wq"), local_dataset_template_data("wq"))
  wq$wq_site_id <- c("WQ-MATCHED", "WQ-UNMATCHED")
  rhs <- rbind(local_dataset_template_data("rhs"), local_dataset_template_data("rhs"))
  rhs$rhs_survey_id <- c("RHS-MATCHED", "RHS-UNMATCHED")
  readr::write_csv(wq, wq_file)
  readr::write_csv(rhs, rhs_file)

  shiny::testServer(dashboard_server, {
    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = paste(
        "biol_site_id,flow_site_id,wq_site_id,rhs_survey_id",
        "B01,F01,WQ-MATCHED,RHS-MATCHED",
        sep = "\n"
      ),
      wq_source_mode = "local",
      rhs_source_mode = "local",
      wq_csv = shiny_upload_input(wq_file),
      rhs_csv = shiny_upload_input(rhs_file)
    )
    session$flushReact()

    testthat::expect_identical(workflow_artifacts()$wq_input$status, "blocked")
    testthat::expect_identical(workflow_artifacts()$rhs_input$status, "blocked")
    testthat::expect_match(workflow_artifacts()$wq_input$blocking_reason, "matched 1 of 2", fixed = TRUE)
    testthat::expect_match(workflow_artifacts()$rhs_input$blocking_reason, "matched 1 of 2", fixed = TRUE)
    testthat::expect_identical(wq_source_resolution()$provenance$local_unmatched_rows, 1L)
    testthat::expect_identical(rhs_source_resolution()$provenance$local_unmatched_rows, 1L)
  })
})

testthat::test_that("invalid replacement WQ and RHS uploads invalidate completed source artifacts", {
  invalid_wq <- tempfile("invalid-wq-", fileext = ".csv")
  invalid_rhs <- tempfile("invalid-rhs-", fileext = ".csv")
  writeLines("wq_site_id,date_time\nWQ1,2024-01-01", invalid_wq)
  writeLines("rhs_survey_id,HQA\nRHS1,60", invalid_rhs)
  on.exit(unlink(c(invalid_wq, invalid_rhs), force = TRUE), add = TRUE)

  shiny::testServer(dashboard_server, {
    workflow_complete_artifact("wq_input", "Fixture", "Previous WQ source.")
    workflow_complete_artifact("rhs_input", "Fixture", "Previous RHS source.")
    wq_contract_summary_result(list(
      status = "success",
      messages = "Previous summary fixture.",
      data = data.frame(sample_id = "S1")
    ))

    set_inputs_ignoring_interrupted_promises(
      session,
      wq_source_mode = "local",
      rhs_source_mode = "local",
      wq_csv = shiny_upload_input(invalid_wq),
      rhs_csv = shiny_upload_input(invalid_rhs)
    )
    session$flushReact()

    testthat::expect_identical(workflow_artifacts()$wq_input$status, "blocked")
    testthat::expect_identical(workflow_artifacts()$rhs_input$status, "blocked")
    testthat::expect_identical(wq_contract_summary_result()$status, "info")
  })
})
