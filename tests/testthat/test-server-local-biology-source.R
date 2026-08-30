dashboard_server <- workflow_dashboard_server
biology_upload_input <- shiny_upload_input

testthat::test_that("valid v2 Local Biology is operational and bypasses the external importer", {
  importer_calls <- 0L
  rlang::local_bindings(
    import_inv = function(...) {
      importer_calls <<- importer_calls + 1L
      stop("External Biology importer must not be called for valid Local Biology data.")
    },
    .env = environment(dashboard_server)
  )

  shiny::testServer(dashboard_server, {
    local_path <- testthat::test_path(
      "..", "..", "www", "templates", "local_csv_v2", "biology.csv"
    )
    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = "biol_site_id,flow_site_id\nB001,00123",
      biology_source_mode = "local",
      local_v2_biology_csv = biology_upload_input(local_path)
    )
    session$flushReact()

    testthat::expect_identical(local_biology_upload()$validation$status, "success")
    testthat::expect_true(artifact_is_current(workflow_artifacts()$biology_input))
    testthat::expect_identical(workflow_artifacts()$biology_input$data_source, "Local Biology CSV")
    testthat::expect_identical(biol_data()$SAMPLE_ID, c("00017", "00018"))
    testthat::expect_s3_class(biol_data()$SAMPLE_DATE, "Date")
    testthat::expect_false("sample_id" %in% names(biol_data()))

    session$setInputs(import_inv = 1)
    session$flushReact()
    testthat::expect_identical(importer_calls, 0L)
  })
})

testthat::test_that("invalid Local Biology replacement cannot reuse a previous source", {
  invalid_path <- tempfile("invalid-local-biology-", fileext = ".csv")
  on.exit(unlink(invalid_path, force = TRUE), add = TRUE)
  writeLines("biol_site_id,SAMPLE_ID,SAMPLE_DATE\nB001,00019,2024-05-01", invalid_path)
  external_fixture <- data.frame(
    biol_site_id = "B001",
    SAMPLE_ID = "EXTERNAL",
    SAMPLE_DATE = as.Date("2023-04-15"),
    stringsAsFactors = FALSE
  )
  rlang::local_bindings(
    import_inv = function(...) external_fixture,
    .env = environment(dashboard_server)
  )

  shiny::testServer(dashboard_server, {
    valid_path <- testthat::test_path(
      "..", "..", "www", "templates", "local_csv_v2", "biology.csv"
    )
    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = "biol_site_id,flow_site_id\nB001,00123",
      date_range_biol = as.Date(c("2023-01-01", "2023-12-31")),
      import_inv = 1
    )
    session$flushReact()
    testthat::expect_true(isTRUE(external_biology_loaded()))
    testthat::expect_identical(biol_data()$SAMPLE_ID, "EXTERNAL")

    set_inputs_ignoring_interrupted_promises(
      session,
      biology_source_mode = "local",
      local_v2_biology_csv = biology_upload_input(valid_path)
    )
    session$flushReact()
    testthat::expect_true(artifact_is_current(workflow_artifacts()$biology_input))
    testthat::expect_identical(biol_data()$SAMPLE_ID[[1L]], "00017")

    set_inputs_ignoring_interrupted_promises(
      session,
      biology_source_mode = "local",
      local_v2_biology_csv = biology_upload_input(invalid_path)
    )
    session$flushReact()

    testthat::expect_identical(local_biology_upload()$validation$status, "error")
    testthat::expect_false(artifact_is_current(workflow_artifacts()$biology_input))
    testthat::expect_true(isTRUE(external_biology_loaded()))
    testthat::expect_error(biol_data(), class = "shiny.silent.error")

    session$setInputs(biology_source_mode = "explorer")
    session$flushReact()
    testthat::expect_identical(biol_data()$SAMPLE_ID, "EXTERNAL")
    testthat::expect_true(artifact_is_current(workflow_artifacts()$biology_input))
  })
})

testthat::test_that("RAW-05 legacy Local Biology remains preview-only", {
  empty_biology <- tempfile("empty-local-biology-", fileext = ".csv")
  on.exit(unlink(empty_biology, force = TRUE), add = TRUE)
  writeLines("biol_site_id,date,taxon,abundance", empty_biology, useBytes = TRUE)

  shiny::testServer(dashboard_server, {
    valid_biology <- testthat::test_path("..", "fixtures", "local_invertebrate.csv")
    valid_flow <- testthat::test_path("..", "fixtures", "local_flow.csv")
    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = "biol_site_id,flow_site_id\n291,27090",
      local_inv_csv = biology_upload_input(valid_biology),
      flow_source_mode = "local",
      local_flow_csv = biology_upload_input(valid_flow)
    )
    session$flushReact()

    testthat::expect_false(artifact_is_current(workflow_artifacts()$biology_input))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$flow_input))

    set_inputs_ignoring_interrupted_promises(
      session,
      local_inv_csv = biology_upload_input(empty_biology)
    )
    session$flushReact()

    message <- paste(local_inv_upload()$validation$messages, collapse = " ")
    testthat::expect_identical(local_inv_upload()$validation$status, "error")
    testthat::expect_false(artifact_is_current(workflow_artifacts()$biology_input))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$flow_input))
    testthat::expect_match(message, "appears to be empty", fixed = TRUE)
    testthat::expect_match(message, "upload a CSV containing at least one data row", fixed = TRUE)

    set_inputs_ignoring_interrupted_promises(
      session,
      local_inv_csv = biology_upload_input(valid_biology)
    )
    session$flushReact()

    testthat::expect_false(artifact_is_current(workflow_artifacts()$biology_input))
    testthat::expect_identical(local_inv_upload()$validation$status, "success")
  })
})
