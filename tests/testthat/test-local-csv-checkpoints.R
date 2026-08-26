testthat::test_that("Stage 1 exposes one maintainable checkpoint specification per v2 CSV", {
  specs <- local_csv_checkpoint_specs()

  testthat::expect_identical(
    names(specs),
    c("biology", "environmental", "flow", "wq", "rhs")
  )
  testthat::expect_identical(
    unname(vapply(specs, `[[`, character(1), "contract_type")),
    local_csv_v2_types()
  )
  testthat::expect_identical(specs$environmental$workflow_type, "environment")
  testthat::expect_identical(specs$flow$input_id, "local_flow_csv")
  testthat::expect_identical(
    anyDuplicated(vapply(specs, `[[`, character(1), "input_id")),
    0L
  )
})

testthat::test_that("Stage 1 checkpoint panel contains five task-gated uploads and templates", {
  html <- as.character(local_csv_checkpoint_panel())
  specs <- local_csv_checkpoint_specs()

  for (data_type in names(specs)) {
    spec <- specs[[data_type]]
    testthat::expect_match(html, spec$input_id, fixed = TRUE)
    testthat::expect_match(
      html,
      paste0("templates/local_csv_v2/", spec$contract_type, ".csv"),
      fixed = TRUE
    )
    testthat::expect_match(
      html,
      paste0('data-task-imports="', spec$workflow_type, '"'),
      fixed = TRUE
    )
  }
  testthat::expect_match(html, "Files are checked independently", fixed = TRUE)
})

testthat::test_that("checkpoint status markup preserves warning and blocking severity", {
  warning_html <- as.character(local_csv_checkpoint_status_tag(list(
    status = "warning",
    messages = "Review this value."
  )))
  error_html <- as.character(local_csv_checkpoint_status_tag(list(
    status = "error",
    messages = "Correct this file."
  )))

  testthat::expect_match(warning_html, "upload-status-warning", fixed = TRUE)
  testthat::expect_match(error_html, "upload-status-error", fixed = TRUE)
})

testthat::test_that("the primary v2 Biology checkpoint stays separate from the legacy exclusion log", {
  ui_text <- paste(readLines(testthat::test_path("..", "..", "ui.R")), collapse = "\n")

  testthat::expect_identical(
    local_csv_checkpoint_specs()$biology$input_id,
    "local_v2_biology_csv"
  )
  testthat::expect_match(ui_text, '"local_inv_csv"', fixed = TRUE)
  testthat::expect_match(ui_text, '"exclusion_log_table"', fixed = TRUE)
  testthat::expect_match(
    ui_text,
    "It is separate from the Data Contract v2.0 Biology CSV above.",
    fixed = TRUE
  )
})

testthat::test_that("each checkpoint validates independently and does not mutate another result", {
  test_server <- function(input, output, session) {
    biology <- bind_local_csv_checkpoint(input, output, "biology")
    flow <- bind_local_csv_checkpoint(input, output, "flow")
  }

  shiny::testServer(test_server, {
    flow_path <- testthat::test_path(
      "..", "..", "www", "templates", "local_csv_v2", "flow.csv"
    )
    session$setInputs(local_flow_csv = shiny_upload_input(flow_path))
    session$flushReact()

    testthat::expect_identical(flow()$status, "success")
    testthat::expect_identical(biology()$status, "info")
    testthat::expect_null(biology()$data)
  })
})

testthat::test_that("all five template files pass through their Shiny checkpoints", {
  checkpoint_server <- function(input, output, session) {
    results <- lapply(
      names(local_csv_checkpoint_specs()),
      function(data_type) bind_local_csv_checkpoint(input, output, data_type)
    )
    names(results) <- names(local_csv_checkpoint_specs())
  }

  shiny::testServer(checkpoint_server, {
    specs <- local_csv_checkpoint_specs()
    uploads <- lapply(specs, function(spec) {
      path <- testthat::test_path(
        "..", "..", "www", "templates", "local_csv_v2",
        paste0(spec$contract_type, ".csv")
      )
      shiny_upload_input(path)
    })
    names(uploads) <- vapply(specs, `[[`, character(1), "input_id")
    do.call(session$setInputs, uploads)
    session$flushReact()

    for (data_type in names(results)) {
      testthat::expect_identical(results[[data_type]]()$status, "success")
      testthat::expect_gt(nrow(results[[data_type]]()$data), 0L)
    }
  })
})
