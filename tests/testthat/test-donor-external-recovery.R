raw_recovery_server <- workflow_dashboard_server
raw_recovery_upload_input <- shiny_upload_input
raw_recovery_set_inputs <- set_inputs_ignoring_interrupted_promises

testthat::test_that("RAW-02 and RAW-03 donor parsers reject unsafe input before downstream use", {
  reader_calls <- 0L
  never_reader <- function(...) {
    reader_calls <<- reader_calls + 1L
    stop("fread raw parser detail C:/private/input.csv")
  }

  blank_mapping <- parse_donor_mapping(" \t\n ", reader = never_reader)
  blank_list <- parse_donor_site_list("\n\t", reader = never_reader)
  testthat::expect_identical(reader_calls, 0L)
  testthat::expect_match(blank_mapping$error, "If imputing flows please add donor mapping.", fixed = TRUE)
  testthat::expect_match(blank_list$error, "please add the donor site list", fixed = TRUE)

  malformed_mapping <- parse_donor_mapping("not blank", reader = never_reader)
  malformed_list <- parse_donor_site_list("not blank", reader = never_reader)
  testthat::expect_identical(reader_calls, 2L)
  testthat::expect_match(malformed_mapping$error, "donor mapping could not be read or validated", fixed = TRUE)
  testthat::expect_match(malformed_list$error, "donor site list is invalid or could not be read", fixed = TRUE)
  testthat::expect_false(grepl("fread|C:/private|conditionMessage", malformed_mapping$error, ignore.case = TRUE))
  testthat::expect_false(grepl("fread|C:/private|conditionMessage", malformed_list$error, ignore.case = TRUE))

  invalid_mapping <- parse_donor_mapping("donee,donor,extra\nF1,F2,x")
  invalid_list <- parse_donor_site_list("flow_input\nHDE")
  invalid_source <- parse_donor_site_list("flow_site_id,flow_input\nF2,LOCAL")
  testthat::expect_match(invalid_mapping$error, "two-column", fixed = TRUE)
  testthat::expect_match(invalid_list$error, "flow_site_id", fixed = TRUE)
  testthat::expect_match(invalid_source$error, "NRFA or HDE", fixed = TRUE)

  valid_mapping <- parse_donor_mapping("station,donor_station\nF1,F2")
  valid_list <- parse_donor_site_list("flow_site_id\nF2")
  testthat::expect_null(valid_mapping$error)
  testthat::expect_identical(valid_mapping$data[[1L]], "F1")
  testthat::expect_null(valid_list$error)
  testthat::expect_identical(valid_list$data$flow_input, "HDE")
})

testthat::test_that("RAW-03 donor list rejects column names duplicated by normalisation", {
  duplicate_case <- parse_donor_site_list(
    "flow_site_id,FLOW_SITE_ID\n27090,27091"
  )
  duplicate_whitespace_case <- parse_donor_site_list(
    " flow_site_id , FLOW_SITE_ID \n27090,27091"
  )
  valid_list <- parse_donor_site_list(
    "flow_site_id,flow_input\n27092,NRFA"
  )

  testthat::expect_null(duplicate_case$data)
  testthat::expect_identical(duplicate_case$error, donor_site_list_error_message())
  testthat::expect_null(duplicate_whitespace_case$data)
  testthat::expect_identical(
    duplicate_whitespace_case$error,
    donor_site_list_error_message()
  )
  testthat::expect_null(valid_list$error)
  testthat::expect_identical(valid_list$data$flow_site_id, "27092")
  testthat::expect_identical(valid_list$data$flow_input, "NRFA")
})

testthat::test_that("RAW-22 result boundary classifies service, empty, invalid and usable results", {
  service_error <- safe_external_import(
    function() stop("curl timeout at C:/private/token.txt"),
    required_columns = "id"
  )
  null_result <- safe_external_import(function() NULL, required_columns = "id")
  empty_result <- safe_external_import(function() data.frame(id = character()), required_columns = "id")
  non_tabular <- safe_external_import(function() list(id = "x"), required_columns = "id")
  invalid_result <- safe_external_import(function() data.frame(other = "x"), required_columns = "id")
  unusable_result <- safe_external_import(function() data.frame(id = NA_character_), required_columns = "id")
  success <- safe_external_import(function() data.frame(id = "x"), required_columns = "id")

  testthat::expect_identical(service_error$failure, "request_failed")
  testthat::expect_match(service_error$diagnostic, "curl timeout", fixed = TRUE)
  testthat::expect_identical(null_result$failure, "empty_result")
  testthat::expect_identical(empty_result$failure, "empty_result")
  testthat::expect_identical(non_tabular$failure, "invalid_result")
  testthat::expect_identical(invalid_result$failure, "invalid_result")
  testthat::expect_identical(unusable_result$failure, "invalid_result")
  testthat::expect_null(invalid_result$data)
  testthat::expect_identical(success$status, "success")
  testthat::expect_identical(success$data$id, "x")
})

testthat::test_that("RAW-02 and RAW-03 donor failures retain Flow state and retry in-session", {
  donor_import_calls <- 0L
  imputation_calls <- 0L
  rlang::local_bindings(
    import_dashboard_flow = function(sites, inputs, start_date, end_date) {
      donor_import_calls <<- donor_import_calls + 1L
      if (donor_import_calls == 1L) {
        stop("libcurl donor failure C:/private/donor.csv")
      }
      data.frame(
        flow_site_id = sites,
        date = as.Date("2024-01-01"),
        flow = 8.5,
        stringsAsFactors = FALSE
      )
    },
    impute_flow = function(data, ..., donor) {
      imputation_calls <<- imputation_calls + 1L
      testthat::expect_identical(as.character(donor[[1L]]), "27090")
      testthat::expect_identical(as.character(donor[[2L]]), "27090")
      data
    },
    .env = environment(raw_recovery_server)
  )

  shiny::testServer(raw_recovery_server, {
    local_flow_path <- testthat::test_path("..", "fixtures", "local_flow.csv")
    raw_recovery_set_inputs(
      session,
      meta_paste = "biol_site_id,flow_site_id\nB1,27090",
      local_flow_csv = raw_recovery_upload_input(local_flow_path),
      date_range_flow = as.Date(c("2024-01-01", "2024-12-31"))
    )
    session$flushReact()
    workflow_complete_artifact("flow_statistics", "test", "Retained before donor retry.")

    raw_recovery_set_inputs(session, donor_mapping_paste = "C:/private/missing-donor-map.csv", impute_flow = 1)
    session$flushReact()
    mapping_message <- flow_imputation_result()$messages
    testthat::expect_identical(flow_imputation_result()$status, "error")
    testthat::expect_match(mapping_message, "donor mapping could not be read or validated", fixed = TRUE)
    testthat::expect_false(grepl("fread|C:/private|conditionMessage", mapping_message, ignore.case = TRUE))
    testthat::expect_identical(imputation_calls, 0L)
    testthat::expect_true(artifact_is_current(workflow_artifacts()$flow_statistics))

    raw_recovery_set_inputs(
      session,
      donor_mapping_paste = "station,donor_station\n27090,27090",
      impute_flow = 2
    )
    session$flushReact()
    testthat::expect_identical(flow_imputation_result()$status, "success")
    testthat::expect_identical(imputation_calls, 1L)

    raw_recovery_set_inputs(session, donor_list_paste = "flow_input\nHDE", import_donor_flow = 1)
    session$flushReact()
    testthat::expect_identical(donor_flow_import_result()$status, "error")
    testthat::expect_identical(donor_import_calls, 0L)

    raw_recovery_set_inputs(
      session,
      donor_list_paste = "flow_site_id,flow_input\n27091,HDE",
      import_donor_flow = 2
    )
    session$flushReact()
    donor_error <- donor_flow_import_result()$messages
    testthat::expect_identical(donor_flow_import_result()$status, "error")
    testthat::expect_false(grepl("libcurl|C:/private|conditionMessage", donor_error, ignore.case = TRUE))
    testthat::expect_match(tail(external_import_diagnostics()$detail, 1L), "libcurl donor failure", fixed = TRUE)
    testthat::expect_false(import_donor_flow_success())
    testthat::expect_true(artifact_is_current(workflow_artifacts()$flow_statistics))

    raw_recovery_set_inputs(session, import_donor_flow = 3)
    session$flushReact()
    testthat::expect_identical(donor_flow_import_result()$status, "success")
    testthat::expect_true(import_donor_flow_success())
    testthat::expect_true("27091" %in% flow_data_extra()$flow_site_id)
    testthat::expect_true(artifact_is_current(workflow_artifacts()$flow_statistics))
  })
})

testthat::test_that("RAW-22 required Biology, Environment and Flow imports fail safely and retry", {
  biology_calls <- 0L
  environment_calls <- 0L
  flow_calls <- 0L
  environment_fixture <- data.frame(
    biol_site_id = "B1",
    BOULDERS_COBBLES = 20,
    PEBBLES_GRAVEL = 30,
    SILT_CLAY = 25,
    stringsAsFactors = FALSE
  )
  rlang::local_bindings(
    import_inv = function(...) {
      biology_calls <<- biology_calls + 1L
      if (biology_calls == 1L) stop("HTTP 503 Biology C:/private/api.json")
      data.frame(biol_site_id = "B1", date = as.Date("2024-01-01"))
    },
    import_env = function(...) {
      environment_calls <<- environment_calls + 1L
      if (environment_calls == 1L) stop("timeout Environmental curl detail")
      environment_fixture
    },
    import_dashboard_flow = function(...) {
      flow_calls <<- flow_calls + 1L
      if (flow_calls == 1L) stop("URL Flow request failed C:/private/flow.json")
      data.frame(flow_site_id = "F1", date = as.Date("2024-01-01"), flow = 7.5)
    },
    .env = environment(raw_recovery_server)
  )

  shiny::testServer(raw_recovery_server, {
    raw_recovery_set_inputs(
      session,
      meta_paste = "biol_site_id,flow_site_id,flow_input\nB1,F1,HDE",
      date_range_biol = as.Date(c("2024-01-01", "2024-12-31")),
      date_range_flow = as.Date(c("2024-01-01", "2024-12-31"))
    )
    session$flushReact()
    workflow_complete_artifact("rhs_input", "test", "Unrelated RHS fixture.")

    for (path in c("biology", "environment", "flow")) {
      input_name <- switch(path, biology = "import_inv", environment = "import_env", flow = "import_flow")
      artifact_name <- switch(path, biology = "biology_input", environment = "environment_input", flow = "flow_input")
      do.call(
        raw_recovery_set_inputs,
        c(list(session = session), stats::setNames(list(1), input_name))
      )
      session$flushReact()
      artifact <- workflow_artifacts()[[artifact_name]]
      testthat::expect_identical(artifact$status, "failed", info = path)
      testthat::expect_false(artifact_is_current(artifact), info = path)
      testthat::expect_false(grepl("HTTP|curl|C:/private|conditionMessage", paste(artifact$blocking_reason, artifact$next_action), ignore.case = TRUE), info = path)
      testthat::expect_true(artifact_is_current(workflow_artifacts()$rhs_input), info = path)
      testthat::expect_false(any(vapply(workflow_artifacts(), function(item) identical(item$status, "running"), logical(1))), info = path)

      do.call(
        raw_recovery_set_inputs,
        c(list(session = session), stats::setNames(list(2), input_name))
      )
      session$flushReact()
      testthat::expect_true(artifact_is_current(workflow_artifacts()[[artifact_name]]), info = path)
    }

    testthat::expect_identical(biology_calls, 2L)
    testthat::expect_identical(environment_calls, 2L)
    testthat::expect_identical(flow_calls, 2L)
    testthat::expect_setequal(external_import_diagnostics()$context, c("biology", "environment", "flow"))
    testthat::expect_true(any(grepl("C:/private", external_import_diagnostics()$detail, fixed = TRUE)))
    testthat::expect_identical(biol_data()$biol_site_id, "B1")
    testthat::expect_identical(env_data()$biol_site_id, "B1")
    testthat::expect_identical(flow_data()$flow_site_id, "F1")
  })
})

testthat::test_that("RAW-22 optional WQ and RHS imports reject failed results and recover", {
  wq_calls <- 0L
  rhs_calls <- 0L
  rlang::local_bindings(
    import_dashboard_wq = function(...) {
      wq_calls <<- wq_calls + 1L
      if (wq_calls == 1L) stop("WQ HTTP library internals C:/private/wq.json")
      if (wq_calls == 2L) return(data.frame(wq_site_id = character()))
      if (wq_calls == 3L) return(data.frame(unusable = "W1"))
      data.frame(wq_site_id = "W1", date = as.Date("2024-01-01"), value = 1.5)
    },
    import_rhs_in_temp_directory = function(...) {
      rhs_calls <<- rhs_calls + 1L
      if (rhs_calls == 1L) stop("RHS timeout stack trace C:/private/rhs.zip")
      if (rhs_calls == 2L) return(data.frame(rhs_survey_id = character()))
      if (rhs_calls == 3L) return(data.frame(unusable = "R1"))
      data.frame(rhs_survey_id = "R1", HQA = 42)
    },
    .env = environment(raw_recovery_server)
  )

  shiny::testServer(raw_recovery_server, {
    raw_recovery_set_inputs(
      session,
      meta_paste = "biol_site_id,flow_site_id,wq_site_id,rhs_survey_id\nB1,F1,W1,R1",
      date_range_wq = as.Date(c("2024-01-01", "2024-12-31"))
    )
    session$flushReact()
    workflow_complete_artifact("flow_input", "test", "Unrelated Flow fixture.")

    for (click in 1:4) {
      raw_recovery_set_inputs(session, import_wq_site_ids = click)
      session$flushReact()
      if (click < 4L) {
        message <- paste(wq_site_import_result()$messages, collapse = " ")
        testthat::expect_identical(workflow_artifacts()$wq_input$status, "failed")
        testthat::expect_null(wq_site_import_data())
        testthat::expect_false(grepl("HTTP|library|C:/private|conditionMessage", message, ignore.case = TRUE))
      } else {
        testthat::expect_identical(wq_site_import_result()$status, "success")
        testthat::expect_true(artifact_is_current(workflow_artifacts()$wq_input))
        testthat::expect_identical(wq_site_import_data()$wq_site_id, "W1")
      }
      testthat::expect_true(artifact_is_current(workflow_artifacts()$flow_input))
    }

    for (click in 1:4) {
      raw_recovery_set_inputs(session, import_rhs_site_ids = click)
      session$flushReact()
      if (click < 4L) {
        message <- paste(rhs_site_import_result()$messages, collapse = " ")
        testthat::expect_identical(workflow_artifacts()$rhs_input$status, "failed")
        testthat::expect_null(rhs_site_import_data())
        testthat::expect_false(grepl("timeout|stack trace|C:/private|conditionMessage", message, ignore.case = TRUE))
      } else {
        testthat::expect_identical(rhs_site_import_result()$status, "success")
        testthat::expect_true(artifact_is_current(workflow_artifacts()$rhs_input))
        testthat::expect_identical(rhs_site_import_data()$rhs_survey_id, "R1")
      }
      testthat::expect_true(artifact_is_current(workflow_artifacts()$flow_input))
    }

    testthat::expect_identical(wq_calls, 4L)
    testthat::expect_identical(rhs_calls, 4L)
    testthat::expect_true(all(c("wq", "rhs") %in% external_import_diagnostics()$context))
    testthat::expect_false(any(vapply(workflow_artifacts(), function(item) identical(item$status, "running"), logical(1))))
  })
})

testthat::test_that("RAW-21 RHS temporary-file failure retains current results and retries", {
  rhs_calls <- 0L
  rlang::local_bindings(
    import_rhs_in_temp_directory = function(...) {
      rhs_calls <<- rhs_calls + 1L
      if (rhs_calls == 2L) {
        abort_file_operation(safe_file_operation(function() {
          stop("Permission denied at C:/Users/private/hetoolkit-rhs", call. = FALSE)
        }))
      }
      data.frame(rhs_survey_id = "R1", HQA = 40 + rhs_calls)
    },
    .env = environment(raw_recovery_server)
  )

  shiny::testServer(raw_recovery_server, {
    raw_recovery_set_inputs(
      session,
      meta_paste = "biol_site_id,rhs_survey_id\nB1,R1"
    )
    session$flushReact()

    raw_recovery_set_inputs(session, import_rhs_site_ids = 1)
    session$flushReact()
    testthat::expect_true(artifact_is_current(workflow_artifacts()$rhs_input))
    retained_data <- rhs_site_import_data()
    retained_registry <- workflow_artifacts()

    raw_recovery_set_inputs(session, import_rhs_site_ids = 2)
    session$flushReact()
    failure_message <- paste(rhs_site_import_result()$messages, collapse = " ")
    testthat::expect_identical(rhs_site_import_result()$status, "error")
    testthat::expect_match(failure_message, "The file could not be created or saved", fixed = TRUE)
    testthat::expect_false(grepl("Permission denied|C:/Users|hetoolkit-rhs", failure_message))
    testthat::expect_identical(rhs_site_import_data(), retained_data)
    testthat::expect_identical(workflow_artifacts(), retained_registry)
    testthat::expect_true(artifact_is_current(workflow_artifacts()$rhs_input))
    testthat::expect_false(any(vapply(
      workflow_artifacts(),
      function(item) identical(item$status, "running"),
      logical(1)
    )))

    raw_recovery_set_inputs(session, import_rhs_site_ids = 3)
    session$flushReact()
    testthat::expect_identical(rhs_calls, 3L)
    testthat::expect_identical(rhs_site_import_result()$status, "success")
    testthat::expect_identical(rhs_site_import_data()$HQA, 43)
    testthat::expect_true(artifact_is_current(workflow_artifacts()$rhs_input))
  })
})
