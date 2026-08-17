dashboard_server <- workflow_dashboard_server
flow_upload_input <- shiny_upload_input

testthat::test_that("valid Local Flow is operational and bypasses the external importer", {
  importer_calls <- 0L
  rlang::local_bindings(
    import_dashboard_flow = function(...) {
      importer_calls <<- importer_calls + 1L
      stop("External Flow importer must not be called for valid Local Flow data.")
    },
    .env = environment(dashboard_server)
  )

  shiny::testServer(dashboard_server, {
    local_path <- testthat::test_path("..", "fixtures", "local_flow.csv")
    set_inputs_ignoring_interrupted_promises(session,
      meta_paste = paste(
        "biol_site_id,flow_site_id,wq_site_id,rhs_survey_id",
        "291,27090,WQ001,RHS001",
        "292,27091,WQ002,RHS002",
        sep = "\n"
      ),
      local_flow_csv = flow_upload_input(local_path),
      date_range_flow = as.Date(c("2024-01-01", "2024-12-31"))
    )
    session$flushReact()

    testthat::expect_identical(local_flow_upload()$validation$status, "success")
    testthat::expect_identical(metadata()$flow_input, c("HDE", "HDE"))
    testthat::expect_identical(flow_data()$flow_site_id, c("27090", "27090", "27091"))
    testthat::expect_type(flow_data()$flow_site_id, "character")
    testthat::expect_true(all(flow_data()$flow_site_id %in% metadata()$flow_site_id))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$flow_input))
    testthat::expect_match(paste(as.character(output$cp_flow), collapse = ""), "Flow data loaded", fixed = TRUE)

    session$setInputs(import_flow = 1)
    session$flushReact()
    testthat::expect_identical(importer_calls, 0L)
  })
})

testthat::test_that("extra Local Flow columns never enter the operational source", {
  importer_calls <- 0L
  rlang::local_bindings(
    import_dashboard_flow = function(...) {
      importer_calls <<- importer_calls + 1L
      stop("External Flow importer must not be called for valid Local Flow data.")
    },
    .env = environment(dashboard_server)
  )

  shiny::testServer(dashboard_server, {
    local_path <- testthat::test_path("..", "fixtures", "local_flow_extra_columns.csv")
    set_inputs_ignoring_interrupted_promises(session,
      meta_paste = "biol_site_id,flow_site_id,wq_site_id,rhs_survey_id\n291,27090,WQ001,RHS001",
      local_flow_csv = flow_upload_input(local_path)
    )
    session$flushReact()

    testthat::expect_identical(local_flow_upload()$validation$status, "warning")
    testthat::expect_identical(names(flow_data()), c("flow_site_id", "date", "flow"))
    testthat::expect_identical(flow_data()$flow, 21.5)
    testthat::expect_identical(importer_calls, 0L)
  })
})

testthat::test_that("Flow-statistics calculation failures become recoverable workflow state", {
  rlang::local_bindings(
    calc_flowstats = function(...) {
      stop("synthetic internal calculation detail")
    },
    .env = environment(dashboard_server)
  )

  shiny::testServer(dashboard_server, {
    local_path <- testthat::test_path("..", "fixtures", "local_flow.csv")
    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = "biol_site_id,flow_site_id,wq_site_id,rhs_survey_id\n291,27090,WQ001,RHS001",
      local_flow_csv = flow_upload_input(local_path)
    )
    session$flushReact()
    testthat::expect_true(artifact_is_current(
      workflow_artifacts()$flow_input
    ))

    set_inputs_ignoring_interrupted_promises(
      session,
      win_width_selector = 6,
      win_step_selector = 6,
      calc_flow_stats = 1
    )
    session$flushReact()

    artifact <- workflow_artifacts()$flow_statistics
    testthat::expect_identical(artifact$status, "failed")
    testthat::expect_match(
      artifact$blocking_reason,
      "could not be calculated",
      fixed = TRUE
    )
    testthat::expect_match(
      artifact$next_action,
      "Review Flow coverage, dates and values",
      fixed = TRUE
    )
    testthat::expect_false(grepl(
      "synthetic internal calculation detail",
      paste(artifact$blocking_reason, artifact$next_action),
      fixed = TRUE
    ))
    testthat::expect_null(flow_stats_revision())
    testthat::expect_error(flow_stats(), class = "shiny.silent.error")
  })
})

testthat::test_that("uploaded and pasted metadata preserve flow_input provenance", {
  shiny::testServer(dashboard_server, {
    upload_path <- testthat::test_path("..", "fixtures", "flow_mapping", "flow_input_missing.csv")
    parsed <- read_site_metadata_csv(upload_path)
    normalised <- normalise_site_metadata_flow_input(parsed$data)
    normalised_text <- readr::format_csv(normalised)

    set_inputs_ignoring_interrupted_promises(session, site_metadata_csv = flow_upload_input(upload_path))
    session$flushReact()

    upload_provenance <- site_metadata_upload_flow_provenance()
    testthat::expect_identical(site_metadata_upload_result()$status, "success")
    testthat::expect_identical(upload_provenance$flow_input_value, "HDE")
    testthat::expect_identical(upload_provenance$flow_input_source, "defaulted")
    testthat::expect_match(
      output$flow_source_default_status$html,
      "HDE has been selected as the default source.",
      fixed = TRUE
    )
    testthat::expect_match(
      output$flow_source_default_status$html,
      "upload-status-info",
      fixed = TRUE
    )

    set_inputs_ignoring_interrupted_promises(session, meta_paste = normalised_text)
    session$flushReact()

    preserved <- metadata_flow_input_provenance()
    testthat::expect_identical(metadata()$flow_input, "HDE")
    testthat::expect_identical(preserved$flow_input_value, "HDE")
    testthat::expect_identical(preserved$flow_input_source, "defaulted")

    session$setInputs(
      meta_paste = paste(
        "biol_site_id,flow_site_id,flow_input,wq_site_id,rhs_survey_id",
        "291,27090,HDE,WQ001,RHS001",
        "292,27091,,WQ002,RHS002",
        sep = "\n"
      )
    )
    session$flushReact()

    pasted <- metadata_flow_input_provenance()
    testthat::expect_identical(metadata()$flow_input, c("HDE", "HDE"))
    testthat::expect_identical(pasted$flow_input_source, c("explicit", "defaulted"))
    testthat::expect_match(
      output$flow_source_default_status$html,
      "Flow source was not specified for 1 site.",
      fixed = TRUE
    )
  })
})

testthat::test_that("invalid pasted flow_input is blocked before the external importer", {
  importer_calls <- 0L
  rlang::local_bindings(
    import_dashboard_flow = function(...) {
      importer_calls <<- importer_calls + 1L
      stop("External Flow importer received invalid metadata.")
    },
    .env = environment(dashboard_server)
  )

  shiny::testServer(dashboard_server, {
    set_inputs_ignoring_interrupted_promises(session,
      meta_paste = "biol_site_id,flow_site_id,flow_input,wq_site_id,rhs_survey_id\n291,27090,LOCAL,WQ001,RHS001",
      date_range_flow = as.Date(c("2024-01-01", "2024-12-31")),
      import_flow = 1
    )
    session$flushReact()

    error_message <- paste(metadata_result()$validation$messages, collapse = " ")
    testthat::expect_match(error_message, "invalid flow_input value", fixed = TRUE)
    testthat::expect_false(grepl("conditionMessage", error_message, fixed = TRUE))
    testthat::expect_identical(workflow_artifacts()$site_mapping$status, "blocked")
    testthat::expect_false(artifact_is_current(workflow_artifacts()$flow_input))
    testthat::expect_error(flow_data(), class = "shiny.silent.error")
    testthat::expect_identical(importer_calls, 0L)
  })
})

testthat::test_that("replacing valid Local Flow with an invalid file removes the previous local source", {
  importer_calls <- 0L
  rlang::local_bindings(
    import_dashboard_flow = function(sites, inputs, start_date, end_date) {
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
    valid_path <- testthat::test_path("..", "fixtures", "local_flow.csv")
    invalid_path <- testthat::test_path("..", "fixtures", "local_invertebrate.csv")
    set_inputs_ignoring_interrupted_promises(session,
      meta_paste = "biol_site_id,flow_site_id,wq_site_id,rhs_survey_id\n291,27090,WQ001,RHS001",
      local_flow_csv = flow_upload_input(valid_path),
      date_range_flow = as.Date(c("2024-01-01", "2024-12-31"))
    )
    session$flushReact()

    testthat::expect_identical(flow_data()$flow, c(12.4, 15.2, 9.8))
    testthat::expect_match(paste(as.character(output$cp_flow), collapse = ""), "Flow data loaded", fixed = TRUE)
    testthat::expect_identical(importer_calls, 0L)

    session$setInputs(import_flow = 1)
    session$flushReact()
    testthat::expect_match(paste(as.character(output$cp_flow), collapse = ""), "Flow data loaded", fixed = TRUE)
    testthat::expect_identical(importer_calls, 0L)

    set_inputs_ignoring_interrupted_promises(session,
      local_flow_csv = flow_upload_input(invalid_path)
    )
    session$flushReact()

    testthat::expect_identical(local_flow_upload()$validation$status, "error")
    testthat::expect_match(paste(as.character(output$cp_flow), collapse = ""), "Flow data not imported", fixed = TRUE)
    testthat::expect_error(flow_data(), class = "shiny.silent.error")
    testthat::expect_identical(importer_calls, 0L)

    session$setInputs(import_flow = 2)
    session$flushReact()
    testthat::expect_identical(flow_data()$flow, 99)
    testthat::expect_identical(importer_calls, 1L)
  })
})

testthat::test_that("replacing Local Flow invalidates Flow statistics and join state", {
  rlang::local_bindings(
    calc_flowstats = function(data, ...) {
      marker <- data$flow[[1]]
      list(
        data.frame(flow_site_id = data$flow_site_id[[1]], start_date = data$date[[1]], source_flow = marker),
        data.frame(flow_site_id = data$flow_site_id[[1]], source_flow = marker)
      )
    },
    .env = environment(dashboard_server)
  )

  shiny::testServer(dashboard_server, {
    source_a <- testthat::test_path("..", "fixtures", "local_flow.csv")
    source_b <- testthat::test_path("..", "fixtures", "local_flow_extra_columns.csv")
    set_inputs_ignoring_interrupted_promises(session,
      meta_paste = "biol_site_id,flow_site_id,wq_site_id,rhs_survey_id\n291,27090,WQ001,RHS001",
      local_flow_csv = flow_upload_input(source_a),
      calc_flow_stats = 1
    )
    session$flushReact()

    testthat::expect_identical(flow_stats()[[1]]$source_flow, 12.4)
    testthat::expect_true(artifact_is_current(workflow_artifacts()$flow_statistics))
    workflow_complete_artifact(
      "joined_core",
      "test fixture",
      "Generated for Flow invalidation test."
    )
    session$flushReact()
    testthat::expect_true(artifact_is_current(workflow_artifacts()$joined_core))

    set_inputs_ignoring_interrupted_promises(session,
      local_flow_csv = flow_upload_input(source_b)
    )
    session$flushReact()

    testthat::expect_false(artifact_is_current(workflow_artifacts()$flow_statistics))
    testthat::expect_false(artifact_is_current(workflow_artifacts()$joined_core))
    testthat::expect_identical(workflow_artifacts()$flow_statistics$status, "stale")
    testthat::expect_identical(workflow_artifacts()$joined_core$status, "stale")
    testthat::expect_identical(flow_data()$flow, 21.5)
    testthat::expect_error(flow_stats(), class = "shiny.silent.error")
    testthat::expect_false(grepl("Flow statistics calculated", paste(as.character(output$cp_flow), collapse = ""), fixed = TRUE))
    testthat::expect_match(paste(as.character(output$cp_hev), collapse = ""), "Flow stats not yet calculated", fixed = TRUE)
    testthat::expect_match(paste(as.character(output$cp_hev), collapse = ""), "Data not yet joined", fixed = TRUE)
  })
})

testthat::test_that("external Flow remains available when no valid Local Flow exists", {
  importer_calls <- 0L
  rlang::local_bindings(
    import_dashboard_flow = function(sites, inputs, start_date, end_date) {
      importer_calls <<- importer_calls + 1L
      testthat::expect_identical(sites, c("27090", "27091"))
      testthat::expect_identical(inputs, c("HDE", "NRFA"))
      data.frame(
        flow_site_id = sites,
        date = as.Date("2024-01-01"),
        flow = c(8.5, 9.5),
        stringsAsFactors = FALSE
      )
    },
    .env = environment(dashboard_server)
  )

  shiny::testServer(dashboard_server, {
    set_inputs_ignoring_interrupted_promises(session,
      meta_paste = paste(
        "biol_site_id,flow_site_id,flow_input,wq_site_id,rhs_survey_id",
        "291,27090,,WQ001,RHS001",
        "292,27091,nrfa,WQ002,RHS002",
        sep = "\n"
      ),
      date_range_flow = as.Date(c("2024-01-01", "2024-12-31")),
      import_flow = 1
    )
    session$flushReact()

    testthat::expect_identical(flow_data()$flow, c(8.5, 9.5))
    testthat::expect_identical(importer_calls, 1L)
    testthat::expect_true(artifact_is_current(workflow_artifacts()$flow_input))
    provenance <- metadata_flow_input_provenance()
    testthat::expect_identical(provenance$flow_input_value, c("HDE", "NRFA"))
    testthat::expect_identical(provenance$flow_input_source, c("defaulted", "explicit"))
    testthat::expect_match(paste(as.character(output$cp_flow), collapse = ""), "Flow data loaded", fixed = TRUE)
  })
})

testthat::test_that("RAW-05 to RAW-09 metadata upload and paste replacements invalidate and recover", {
  valid_upload <- tempfile("valid-mapping-", fileext = ".csv")
  invalid_upload <- tempfile("invalid-mapping-", fileext = ".csv")
  corrected_upload <- tempfile("corrected-mapping-", fileext = ".csv")
  on.exit(unlink(c(valid_upload, invalid_upload, corrected_upload), force = TRUE), add = TRUE)
  writeLines(
    c(
      "biol_site_id,flow_site_id,wq_site_id,rhs_survey_id",
      "B1,F1,W1,R1"
    ),
    valid_upload,
    useBytes = TRUE
  )
  writeLines(
    c(
      "biol_site_id,wq_site_id,rhs_survey_id",
      "B2,W2,R2"
    ),
    invalid_upload,
    useBytes = TRUE
  )
  writeLines(
    c(
      "biol_site_id,flow_site_id",
      "B2,F2"
    ),
    corrected_upload,
    useBytes = TRUE
  )

  shiny::testServer(dashboard_server, {
    set_inputs_ignoring_interrupted_promises(
      session,
      site_metadata_csv = flow_upload_input(valid_upload)
    )
    session$flushReact()

    testthat::expect_true(artifact_is_current(workflow_artifacts()$site_mapping))
    testthat::expect_identical(metadata()$biol_site_id, "B1")
    workflow_complete_artifact("biology_input", "test", "Unrelated Biology fixture.")
    workflow_complete_artifact("environment_input", "test", "Unrelated Environment fixture.")
    workflow_complete_artifact("wq_input", "test", "Unrelated optional WQ fixture.")
    workflow_complete_artifact("flow_input", "test", "Flow fixture.")
    workflow_complete_artifact("processed_flow", "test", "Processed Flow fixture.")
    workflow_complete_artifact("flow_statistics", "test", "Flow statistics fixture.")

    set_inputs_ignoring_interrupted_promises(
      session,
      site_metadata_csv = flow_upload_input(invalid_upload)
    )
    session$flushReact()

    upload_message <- paste(site_metadata_upload_result()$messages, collapse = " ")
    testthat::expect_identical(workflow_artifacts()$site_mapping$status, "blocked")
    testthat::expect_false(artifact_is_current(workflow_artifacts()$flow_input))
    testthat::expect_false(artifact_is_current(workflow_artifacts()$flow_statistics))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$biology_input))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$environment_input))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$wq_input))
    testthat::expect_error(metadata(), class = "shiny.silent.error")
    testthat::expect_match(upload_message, "flow_site_id", fixed = TRUE)
    testthat::expect_match(upload_message, "validate again", fixed = TRUE)

    set_inputs_ignoring_interrupted_promises(
      session,
      site_metadata_csv = flow_upload_input(corrected_upload)
    )
    session$flushReact()

    testthat::expect_true(artifact_is_current(workflow_artifacts()$site_mapping))
    testthat::expect_identical(metadata()$biol_site_id, "B2")
    testthat::expect_identical(metadata()$flow_site_id, "F2")
    testthat::expect_identical(metadata()$flow_input, "HDE")
    testthat::expect_identical(site_metadata_upload_result()$status, "info")

    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = paste(
        "biol_site_id,flow_site_id,wq_site_id,rhs_survey_id",
        "B3,F3,W3,R3",
        sep = "\n"
      )
    )
    session$flushReact()
    testthat::expect_true(artifact_is_current(workflow_artifacts()$site_mapping))
    testthat::expect_identical(metadata()$biol_site_id, "B3")

    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = paste(
        "biol_site_id,wq_site_id,rhs_survey_id",
        "B4,W4,R4",
        sep = "\n"
      )
    )
    session$flushReact()

    paste_message <- paste(metadata_result()$validation$messages, collapse = " ")
    testthat::expect_identical(workflow_artifacts()$site_mapping$status, "blocked")
    testthat::expect_error(metadata(), class = "shiny.silent.error")
    testthat::expect_identical(paste_message, upload_message)

    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = paste(
        "biol_site_id,flow_site_id,wq_site_id,rhs_survey_id",
        "B4,F4,W4,R4",
        sep = "\n"
      )
    )
    session$flushReact()

    testthat::expect_true(artifact_is_current(workflow_artifacts()$site_mapping))
    testthat::expect_identical(metadata()$flow_site_id, "F4")
  })
})

testthat::test_that("RAW-05 and RAW-06 malformed Local Flow replacement is controlled and retryable", {
  malformed_path <- tempfile("malformed-local-flow-", fileext = ".csv")
  on.exit(unlink(malformed_path, force = TRUE), add = TRUE)
  writeLines(
    c("flow_site_id,date,flow", '"F1,2024-01-01,12.4'),
    malformed_path,
    useBytes = TRUE
  )

  shiny::testServer(dashboard_server, {
    valid_path <- testthat::test_path("..", "fixtures", "local_flow.csv")
    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = "biol_site_id,flow_site_id\n291,27090",
      local_flow_csv = flow_upload_input(valid_path)
    )
    session$flushReact()
    workflow_complete_artifact("biology_input", "test", "Unrelated Biology fixture.")
    testthat::expect_true(artifact_is_current(workflow_artifacts()$flow_input))

    set_inputs_ignoring_interrupted_promises(
      session,
      local_flow_csv = flow_upload_input(malformed_path)
    )
    session$flushReact()

    message <- paste(local_flow_upload()$validation$messages, collapse = " ")
    testthat::expect_identical(local_flow_upload()$validation$status, "error")
    testthat::expect_false(artifact_is_current(workflow_artifacts()$flow_input))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$biology_input))
    testthat::expect_match(message, "could not be read or validated", fixed = TRUE)
    testthat::expect_match(message, "upload it again", fixed = TRUE)
    testthat::expect_false(grepl(
      "fread|read.csv|conditionMessage|malformed-local-flow",
      message,
      ignore.case = TRUE
    ))
    testthat::expect_error(flow_data(), class = "shiny.silent.error")

    set_inputs_ignoring_interrupted_promises(
      session,
      local_flow_csv = flow_upload_input(valid_path)
    )
    session$flushReact()

    testthat::expect_true(artifact_is_current(workflow_artifacts()$flow_input))
    testthat::expect_identical(local_flow_upload()$validation$status, "success")
    testthat::expect_identical(flow_data()$flow, c(12.4, 15.2, 9.8))
  })
})

testthat::test_that("RAW-05 empty Local Biology replacement invalidates only its current source and retries", {
  empty_biology <- tempfile("empty-local-biology-", fileext = ".csv")
  on.exit(unlink(empty_biology, force = TRUE), add = TRUE)
  writeLines(
    "biol_site_id,SAMPLE_ID,SAMPLE_DATE,WHPT_ASPT,WHPT_N_TAXA,LIFE_FAMILY_INDEX,PSI_FAMILY_SCORE,Month,Year,Season",
    empty_biology,
    useBytes = TRUE
  )

  shiny::testServer(dashboard_server, {
    valid_biology <- testthat::test_path("..", "fixtures", "local_invertebrate.csv")
    valid_flow <- testthat::test_path("..", "fixtures", "local_flow.csv")
    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = "biol_site_id,flow_site_id\n291,27090",
      local_biology_csv = flow_upload_input(valid_biology),
      local_flow_csv = flow_upload_input(valid_flow)
    )
    session$flushReact()

    testthat::expect_true(artifact_is_current(workflow_artifacts()$biology_input))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$flow_input))

    set_inputs_ignoring_interrupted_promises(
      session,
      local_biology_csv = flow_upload_input(empty_biology)
    )
    session$flushReact()

    message <- paste(local_biology_upload()$validation$messages, collapse = " ")
    testthat::expect_identical(local_biology_upload()$validation$status, "error")
    testthat::expect_false(artifact_is_current(workflow_artifacts()$biology_input))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$flow_input))
    testthat::expect_match(message, "appears to be empty", fixed = TRUE)
    testthat::expect_match(message, "at least one data row", fixed = TRUE)

    set_inputs_ignoring_interrupted_promises(
      session,
      local_biology_csv = flow_upload_input(valid_biology)
    )
    session$flushReact()

    testthat::expect_true(artifact_is_current(workflow_artifacts()$biology_input))
    testthat::expect_identical(local_biology_upload()$validation$status, "success")
  })
})

testthat::test_that("RAW-07 optional WQ and RHS uploads stay non-blocking but supplied invalid files do not remain current", {
  malformed_wq <- tempfile("malformed-wq-", fileext = ".csv")
  invalid_rhs <- tempfile("invalid-rhs-", fileext = ".csv")
  on.exit(unlink(c(malformed_wq, invalid_rhs), force = TRUE), add = TRUE)
  writeLines(c("wq_site_id,date,value", "W1,2024-01-01,1,extra"), malformed_wq, useBytes = TRUE)
  writeLines(c("habitat_score,channel_type", "55,natural"), invalid_rhs, useBytes = TRUE)

  shiny::testServer(dashboard_server, {
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_identical(wq_upload()$validation$status, "info")
    testthat::expect_identical(rhs_upload()$validation$status, "info")
    workflow_complete_artifact("joined_core", "test", "Unrelated core join fixture.")

    valid_wq <- testthat::test_path("..", "fixtures", "wq.csv")
    valid_rhs <- testthat::test_path("..", "fixtures", "rhs.csv")
    set_inputs_ignoring_interrupted_promises(
      session,
      wq_csv = flow_upload_input(valid_wq),
      rhs_csv = flow_upload_input(valid_rhs)
    )
    session$flushReact()
    testthat::expect_true(artifact_is_current(workflow_artifacts()$wq_input))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$rhs_input))
    workflow_complete_artifact("joined_enriched", "test", "Optional enrichment fixture.")

    set_inputs_ignoring_interrupted_promises(
      session,
      wq_csv = flow_upload_input(malformed_wq),
      rhs_csv = flow_upload_input(invalid_rhs)
    )
    session$flushReact()

    wq_message <- paste(wq_upload()$validation$messages, collapse = " ")
    rhs_message <- paste(rhs_upload()$validation$messages, collapse = " ")
    testthat::expect_identical(wq_upload()$validation$status, "error")
    testthat::expect_identical(rhs_upload()$validation$status, "error")
    testthat::expect_false(artifact_is_current(workflow_artifacts()$wq_input))
    testthat::expect_false(artifact_is_current(workflow_artifacts()$rhs_input))
    testthat::expect_identical(workflow_artifacts()$joined_enriched$status, "stale")
    testthat::expect_true(artifact_is_current(workflow_artifacts()$joined_core))
    testthat::expect_match(wq_message, "could not be read or validated", fixed = TRUE)
    testthat::expect_match(rhs_message, "rhs_survey_id", fixed = TRUE)

    set_inputs_ignoring_interrupted_promises(
      session,
      wq_csv = flow_upload_input(valid_wq),
      rhs_csv = flow_upload_input(valid_rhs)
    )
    session$flushReact()

    testthat::expect_true(artifact_is_current(workflow_artifacts()$wq_input))
    testthat::expect_true(artifact_is_current(workflow_artifacts()$rhs_input))
    testthat::expect_identical(wq_upload()$validation$status, "success")
    testthat::expect_identical(rhs_upload()$validation$status, "success")
  })
})
