dashboard_server <- workflow_dashboard_server

testthat::test_that("local Biology and Environmental CSVs enter their active data flows", {
  biology_file <- tempfile("local-biology-", fileext = ".csv")
  environment_file <- tempfile("local-environment-", fileext = ".csv")
  on.exit(unlink(c(biology_file, environment_file), force = TRUE), add = TRUE)

  writeLines(c(
    "biol_site_id,SAMPLE_ID,SAMPLE_DATE,WHPT_ASPT,WHPT_N_TAXA,LIFE_FAMILY_INDEX,PSI_FAMILY_SCORE,Month,Year,Season",
    "B01,S01,2024-05-01,6.1,,,,5,2024,Spring"
  ), biology_file, useBytes = TRUE)
  writeLines(c(
    paste(local_dataset_contracts()$environment$required, collapse = ","),
    "B01,AA00100010,100,1.2,10,2.5,4,0.5,20,30,25,25,75,100,2024-01-01,2024-12-31,3"
  ), environment_file, useBytes = TRUE)

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
      date_time = "2023-12-01",
      det_id = "0180",
      qualifier = "",
      result = 0.07,
      stringsAsFactors = FALSE
    ))
    rhs_site_import_data(data.frame(
      biol_site_id = "292",
      rhs_survey_id = "RHS002",
      HQA = 60,
      HMSRBB = 22,
      stringsAsFactors = FALSE
    ))
    session$flushReact()

    testthat::expect_equal(nrow(mapped_wq_plot_data()), 4L)
    testthat::expect_equal(nrow(mapped_rhs_plot_data()), 3L)
    testthat::expect_true(artifact_is_current(workflow_artifacts()$wq_input))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$rhs_input))
  })
})
