local_oe_upload_input <- shiny_upload_input

local_oe_prediction_fixture <- function(env_data, ...) {
  data.frame(
    biol_site_id = rep(env_data$biol_site_id[[1L]], 3L),
    SEASON = 1:3,
    TL2_WHPT_ASPT_AbW_DistFam = c(5, 5.5, 6),
    TL2_WHPT_NTAXA_AbW_DistFam = c(16, 17, 18),
    TL3_LIFE_Fam_DistFam = c(7, 7.5, 8),
    TL3_PSI_Fam = c(50, 55, 60)
  )
}

testthat::test_that("v2 Local Biology and Environmental sources close the O:E path", {
  biology_imports <- 0L
  environment_imports <- 0L
  prediction_input <- NULL
  rlang::local_bindings(
    import_inv = function(...) {
      biology_imports <<- biology_imports + 1L
      stop("External Biology must not be called for valid local data.")
    },
    import_env = function(...) {
      environment_imports <<- environment_imports + 1L
      stop("External Environmental must not be called for valid local data.")
    },
    predict_indices = function(env_data, ...) {
      prediction_input <<- env_data
      local_oe_prediction_fixture(env_data, ...)
    },
    .env = environment(workflow_dashboard_server)
  )

  shiny::testServer(workflow_dashboard_server, {
    biology_path <- testthat::test_path(
      "..", "..", "www", "templates", "local_csv_v2", "biology.csv"
    )
    environment_path <- testthat::test_path(
      "..", "..", "www", "templates", "local_csv_v2", "environmental.csv"
    )
    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = "biol_site_id,flow_site_id\nB001,00123",
      local_v2_biology_csv = local_oe_upload_input(biology_path),
      local_v2_environmental_csv = local_oe_upload_input(environment_path)
    )
    session$flushReact()

    testthat::expect_true(artifact_is_current(workflow_artifacts()$biology_input))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$environment_input))

    session$setInputs(run_rict = 1)
    session$flushReact()
    testthat::expect_true(artifact_is_current(workflow_artifacts()$processed_environment))

    session$setInputs(calc_OE = 1)
    session$flushReact()
    result <- biol_all()

    testthat::expect_true(artifact_is_current(workflow_artifacts()$processed_biology))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$oe_result))
    testthat::expect_identical(result$sample_id, c("00017", "00018"))
    testthat::expect_identical(result$date, as.Date(c("2024-04-15", "2024-10-09")))
    testthat::expect_equal(result$WHPT_ASPT_OE[[1L]], 5.2 / 5)
    testthat::expect_equal(result$PSI_OE[[2L]], 62.5 / 60)
    testthat::expect_identical(prediction_input$NGR_PREFIX, "SO")
    testthat::expect_identical(prediction_input$EASTING, "12345")
    testthat::expect_identical(biology_imports, 0L)
    testthat::expect_identical(environment_imports, 0L)
  })
})

testthat::test_that("local source replacement clears O:E requests and stale results", {
  invalid_biology <- tempfile("invalid-local-biology-", fileext = ".csv")
  invalid_environment <- tempfile("invalid-local-environment-", fileext = ".csv")
  on.exit(unlink(c(invalid_biology, invalid_environment), force = TRUE), add = TRUE)
  writeLines(
    "biol_site_id,SAMPLE_ID,SAMPLE_DATE\nB001,00019,2024-05-01",
    invalid_biology,
    useBytes = TRUE
  )
  writeLines(
    "biol_site_id,NGR_10_FIG\nB001,SO1234512345",
    invalid_environment,
    useBytes = TRUE
  )
  rlang::local_bindings(
    predict_indices = local_oe_prediction_fixture,
    .env = environment(workflow_dashboard_server)
  )

  shiny::testServer(workflow_dashboard_server, {
    biology_path <- testthat::test_path(
      "..", "..", "www", "templates", "local_csv_v2", "biology.csv"
    )
    environment_path <- testthat::test_path(
      "..", "..", "www", "templates", "local_csv_v2", "environmental.csv"
    )
    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = "biol_site_id,flow_site_id\nB001,00123",
      local_v2_biology_csv = local_oe_upload_input(biology_path),
      local_v2_environmental_csv = local_oe_upload_input(environment_path)
    )
    session$flushReact()
    session$setInputs(run_rict = 1)
    session$flushReact()
    session$setInputs(calc_OE = 1)
    session$flushReact()
    testthat::expect_true(artifact_is_current(workflow_artifacts()$oe_result))

    set_inputs_ignoring_interrupted_promises(
      session,
      local_v2_biology_csv = local_oe_upload_input(invalid_biology)
    )
    session$flushReact()
    testthat::expect_false(artifact_is_current(workflow_artifacts()$biology_input))
    testthat::expect_false(artifact_is_current(workflow_artifacts()$oe_result))
    testthat::expect_null(oe_request())
    testthat::expect_error(biol_all(), class = "shiny.silent.error")

    set_inputs_ignoring_interrupted_promises(
      session,
      local_v2_biology_csv = local_oe_upload_input(biology_path)
    )
    session$flushReact()
    session$setInputs(calc_OE = 2)
    session$flushReact()
    testthat::expect_true(artifact_is_current(workflow_artifacts()$oe_result))

    set_inputs_ignoring_interrupted_promises(
      session,
      local_v2_environmental_csv = local_oe_upload_input(invalid_environment)
    )
    session$flushReact()
    testthat::expect_false(artifact_is_current(workflow_artifacts()$environment_input))
    testthat::expect_false(artifact_is_current(workflow_artifacts()$processed_environment))
    testthat::expect_false(artifact_is_current(workflow_artifacts()$oe_result))
    testthat::expect_null(rict_request())
    testthat::expect_null(oe_request())
    testthat::expect_error(predict_data(), class = "shiny.silent.error")
    testthat::expect_error(biol_all(), class = "shiny.silent.error")
  })
})

testthat::test_that("O:E blocks when RICT predictions do not cover Biology keys", {
  mismatched_environment <- tempfile(
    "mismatched-local-environment-",
    fileext = ".csv"
  )
  on.exit(unlink(mismatched_environment, force = TRUE), add = TRUE)
  environment_template <- testthat::test_path(
    "..", "..", "www", "templates", "local_csv_v2", "environmental.csv"
  )
  writeLines(
    sub("^B001,", "B002,", readLines(environment_template, warn = FALSE)),
    mismatched_environment,
    useBytes = TRUE
  )
  rlang::local_bindings(
    predict_indices = local_oe_prediction_fixture,
    .env = environment(workflow_dashboard_server)
  )

  shiny::testServer(workflow_dashboard_server, {
    biology_path <- testthat::test_path(
      "..", "..", "www", "templates", "local_csv_v2", "biology.csv"
    )
    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = "biol_site_id,flow_site_id\nB001,00123",
      local_v2_biology_csv = local_oe_upload_input(biology_path),
      local_v2_environmental_csv = local_oe_upload_input(mismatched_environment)
    )
    session$flushReact()
    session$setInputs(run_rict = 1)
    session$flushReact()
    testthat::expect_true(artifact_is_current(workflow_artifacts()$processed_environment))

    session$setInputs(calc_OE = 1)
    session$flushReact()

    testthat::expect_identical(workflow_artifacts()$oe_result$status, "blocked")
    testthat::expect_match(
      workflow_artifacts()$oe_result$blocking_reason,
      "do not cover Biology site/season records for: B001",
      fixed = TRUE
    )
    testthat::expect_null(oe_request())
    testthat::expect_error(biol_all(), class = "shiny.silent.error")
  })
})
