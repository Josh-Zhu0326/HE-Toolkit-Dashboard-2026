testthat::test_that("Local Environmental and RHS CSVs become operational only when selected", {
  environmental_path <- testthat::test_path(
    "..", "..", "www", "templates", "local_csv_v2", "environmental.csv"
  )
  rhs_path <- testthat::test_path(
    "..", "..", "www", "templates", "local_csv_v2", "rhs.csv"
  )

  shiny::testServer(workflow_dashboard_server, {
    set_inputs_ignoring_interrupted_promises(
      session,
      environment_source_mode = "local",
      rhs_source_mode = "local",
      local_v2_environmental_csv = shiny_upload_input(environmental_path),
      local_v2_rhs_csv = shiny_upload_input(rhs_path)
    )
    session$flushReact()

    testthat::expect_identical(env_data()$biol_site_id, "B001")
    testthat::expect_identical(mapped_rhs_plot_data()$rhs_survey_id, "RHS0001")
    testthat::expect_identical(
      workflow_artifacts()$environment_input$data_source,
      "Local Environmental CSV"
    )
    testthat::expect_identical(
      workflow_artifacts()$rhs_input$data_source,
      "Local RHS CSV"
    )
  })
})

testthat::test_that("a retained Local Flow upload does not replace the selected Explorer source", {
  rlang::local_bindings(
    import_dashboard_flow = function(...) {
      data.frame(
        flow_site_id = "27090",
        date = as.Date("2024-01-01"),
        flow = 99,
        stringsAsFactors = FALSE
      )
    },
    .env = environment(workflow_dashboard_server)
  )

  shiny::testServer(workflow_dashboard_server, {
    local_path <- testthat::test_path("..", "fixtures", "local_flow.csv")
    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = "biol_site_id,flow_site_id,flow_input\nB1,27090,HDE",
      flow_source_mode = "explorer",
      date_range_flow = as.Date(c("2024-01-01", "2024-12-31")),
      import_flow = 1
    )
    session$flushReact()
    testthat::expect_identical(flow_data()$flow, 99)

    set_inputs_ignoring_interrupted_promises(
      session,
      local_flow_csv = shiny_upload_input(local_path)
    )
    session$flushReact()

    testthat::expect_identical(local_flow_upload()$validation$status, "success")
    testthat::expect_identical(flow_data()$flow, 99)
    testthat::expect_identical(
      workflow_artifacts()$flow_input$data_source,
      "HDE/NRFA Flow import"
    )

    session$setInputs(flow_source_mode = "local")
    session$flushReact()
    testthat::expect_identical(flow_data()$flow, c(12.4, 15.2, 9.8))
    testthat::expect_identical(workflow_artifacts()$flow_input$data_source, "Local Flow file")

    session$setInputs(flow_source_mode = "explorer")
    session$flushReact()
    testthat::expect_identical(flow_data()$flow, 99)
    testthat::expect_identical(
      workflow_artifacts()$flow_input$data_source,
      "HDE/NRFA Flow import"
    )
  })
})
