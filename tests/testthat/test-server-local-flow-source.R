project_root <- normalizePath(testthat::test_path("..", ".."), winslash = "/", mustWork = TRUE)
dashboard_server <- local({
  previous_dir <- getwd()
  setwd(project_root)
  on.exit(setwd(previous_dir), add = TRUE)
  source("global.R")
  source("server.R")$value
})

flow_upload_input <- function(path) {
  list(
    name = basename(path),
    size = file.info(path)$size,
    type = "text/csv",
    datapath = normalizePath(path, winslash = "/", mustWork = TRUE)
  )
}

set_inputs_ignoring_interrupted_promises <- function(session, ...) {
  withCallingHandlers(
    session$setInputs(...),
    warning = function(warning) {
      if (grepl("restarting interrupted promise evaluation", conditionMessage(warning), fixed = TRUE)) {
        invokeRestart("muffleWarning")
      }
    }
  )
}

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

    error_message <- tryCatch(
      {
        flow_data()
        NULL
      },
      error = function(e) conditionMessage(e)
    )
    testthat::expect_match(error_message, "Invalid flow_input value(s): LOCAL.", fixed = TRUE)
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
