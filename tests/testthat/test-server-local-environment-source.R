dashboard_server <- workflow_dashboard_server
environment_upload_input <- shiny_upload_input

testthat::test_that("valid v2 Local Environmental data are operational", {
  importer_calls <- 0L
  prediction_input <- NULL
  rlang::local_bindings(
    import_env = function(...) {
      importer_calls <<- importer_calls + 1L
      stop("External Environmental importer must not be called for valid local data.")
    },
    predict_indices = function(env_data, ...) {
      prediction_input <<- env_data
      data.frame(
        biol_site_id = rep("B001", 3L),
        SEASON = 1:3,
        TL2_WHPT_ASPT_AbW_DistFam = c(5.1, 5.2, 5.3),
        TL2_WHPT_NTAXA_AbW_DistFam = c(20, 21, 22),
        TL3_LIFE_Fam_DistFam = c(6.1, 6.2, 6.3),
        TL3_PSI_Fam = c(50, 51, 52)
      )
    },
    .env = environment(dashboard_server)
  )

  shiny::testServer(dashboard_server, {
    local_path <- testthat::test_path(
      "..", "..", "www", "templates", "local_csv_v2", "environmental.csv"
    )
    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = "biol_site_id,flow_site_id\nB001,00123",
      environment_source_mode = "local",
      local_v2_environmental_csv = environment_upload_input(local_path)
    )
    session$flushReact()

    testthat::expect_identical(local_environment_upload()$validation$status, "success")
    testthat::expect_true(artifact_is_current(workflow_artifacts()$environment_input))
    testthat::expect_identical(
      workflow_artifacts()$environment_input$data_source,
      "Local Environmental CSV"
    )
    testthat::expect_identical(env_data()$NGR_PREFIX, "SO")
    testthat::expect_identical(env_data()$EASTING, "12345")
    testthat::expect_identical(env_data()$NGR_10_FIG, "SO1234512345")

    session$setInputs(import_env = 1)
    session$flushReact()
    testthat::expect_identical(importer_calls, 0L)

    session$setInputs(run_rict = 1)
    session$flushReact()
    testthat::expect_true(artifact_is_current(workflow_artifacts()$processed_environment))
    testthat::expect_identical(prediction_input$NGR_PREFIX, "SO")
    testthat::expect_identical(prediction_input$EASTING, "12345")
  })
})

testthat::test_that("invalid selected Local Environmental data do not fall back to retained Explorer data", {
  invalid_path <- tempfile("invalid-local-environment-", fileext = ".csv")
  on.exit(unlink(invalid_path, force = TRUE), add = TRUE)
  writeLines("biol_site_id,NGR_10_FIG\nB001,SO1234512345", invalid_path)
  external_fixture <- data.frame(
    biol_site_id = "B001",
    NGR_10_FIG = "SO1234512345",
    ALTITUDE = 10,
    BOULDERS_COBBLES = 25,
    PEBBLES_GRAVEL = 40,
    SAND = 20,
    SILT_CLAY = 15,
    stringsAsFactors = FALSE
  )
  rlang::local_bindings(
    import_env = function(...) external_fixture,
    .env = environment(dashboard_server)
  )

  shiny::testServer(dashboard_server, {
    valid_path <- testthat::test_path(
      "..", "..", "www", "templates", "local_csv_v2", "environmental.csv"
    )
    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = "biol_site_id,flow_site_id\nB001,00123",
      environment_source_mode = "explorer"
    )
    session$flushReact()

    session$setInputs(import_env = 1)
    session$flushReact()
    testthat::expect_true(isTRUE(external_environment_loaded()))
    testthat::expect_identical(env_data()$ALTITUDE, 10)

    set_inputs_ignoring_interrupted_promises(
      session,
      local_v2_environmental_csv = environment_upload_input(valid_path)
    )
    session$flushReact()
    testthat::expect_true(isTRUE(external_environment_loaded()))
    testthat::expect_identical(env_data()$ALTITUDE, 10)

    session$setInputs(environment_source_mode = "local")
    session$flushReact()
    testthat::expect_true(isTRUE(external_environment_loaded()))
    testthat::expect_identical(env_data()$ALTITUDE, 102.5)

    set_inputs_ignoring_interrupted_promises(
      session,
      local_v2_environmental_csv = environment_upload_input(invalid_path)
    )
    session$flushReact()

    testthat::expect_identical(local_environment_upload()$validation$status, "error")
    testthat::expect_false(artifact_is_current(workflow_artifacts()$environment_input))
    testthat::expect_true(isTRUE(external_environment_loaded()))
    testthat::expect_error(env_data(), class = "shiny.silent.error")

    session$setInputs(environment_source_mode = "explorer")
    session$flushReact()
    testthat::expect_identical(env_data()$ALTITUDE, 10)
  })
})
