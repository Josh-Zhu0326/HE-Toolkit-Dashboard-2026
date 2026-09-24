testthat::test_that("validated v2 WQ populates determinands without Biology mapping", {
  wq_path <- testthat::test_path(
    "..", "..", "www", "templates", "local_csv_v2", "wq.csv"
  )

  shiny::testServer(workflow_dashboard_server, {
    muffle_interrupted_workflow_promise(session$flushReact())
    set_inputs_ignoring_interrupted_promises(
      session,
      wq_source_mode = "local",
      local_v2_wq_csv = shiny_upload_input(wq_path)
    )
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_identical(local_wq_upload()$validation$status, "success")
    muffle_interrupted_workflow_promise(session$flushReact())
    preview <- mapped_wq_plot_data()
    spec <- wq_preview_filter_spec(preview)
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_equal(nrow(preview), 2L)
    testthat::expect_false("biol_site_id" %in% names(preview))
    testthat::expect_identical(spec$determinant_choices, c("0111", "0180"))
    testthat::expect_identical(spec$site_choices, "WQ001")
    testthat::expect_match(output$wq_plot_controls$html, "wq_determinand_filter", fixed = TRUE)
    testthat::expect_match(output$wq_plot_controls$html, "0180", fixed = TRUE)
    testthat::expect_match(output$wq_plot_controls$html, "0111", fixed = TRUE)
  })
})

testthat::test_that("validated v2 WQ uses Biology mapping when it is available", {
  wq_path <- testthat::test_path(
    "..", "..", "www", "templates", "local_csv_v2", "wq.csv"
  )
  mapping <- paste(
    "biol_site_id,wq_site_id",
    "B001,WQ001",
    sep = "\n"
  )

  shiny::testServer(workflow_dashboard_server, {
    muffle_interrupted_workflow_promise(session$flushReact())
    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = mapping,
      wq_source_mode = "local",
      local_v2_wq_csv = shiny_upload_input(wq_path)
    )
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_identical(local_wq_upload()$validation$status, "success")
    muffle_interrupted_workflow_promise(session$flushReact())
    preview <- mapped_wq_plot_data()
    testthat::expect_true("biol_site_id" %in% names(preview))
    testthat::expect_identical(unique(preview$biol_site_id), "B001")
    testthat::expect_identical(
      wq_preview_filter_spec(preview)$determinant_choices,
      c("0111", "0180")
    )
  })
})

testthat::test_that("WQ controls explain when no valid determinands exist", {
  shiny::testServer(workflow_dashboard_server, {
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_match(
      output$wq_plot_controls$html,
      "No valid WQ determinands are available in the current validated WQ source.",
      fixed = TRUE
    )
    testthat::expect_false(grepl(
      "wq_determinand_filter",
      output$wq_plot_controls$html,
      fixed = TRUE
    ))
  })
})

testthat::test_that("Stage 5 offers Q95z lags and rejects Raw Q95 submissions", {
  checkpoint_path <- tempfile("stage5-flow-lags-", fileext = ".rds")
  on.exit(unlink(checkpoint_path, force = TRUE), add = TRUE)
  checkpoint_data <- data.frame(
    biol_site_id = "B1",
    sample_id = paste0("S", 1:5),
    date = as.Date(paste0(2020:2024, "-05-01")),
    Year = 2020:2024,
    LIFE_F_OE = c(0.8, 1.1, 1.0, 0.9, 1.2),
    stringsAsFactors = FALSE
  )
  for (lag in SUPPORTED_FLOW_LAGS) {
    checkpoint_data[[paste0("Q95z_lag", lag)]] <- c(-0.3, -0.5, -0.1, -0.6, -0.4)
    checkpoint_data[[paste0("Q95_lag", lag)]] <- c(10, 9, 11, 8, 12)
  }
  write_processed_dataset_checkpoint(checkpoint_data, checkpoint_path)

  shiny::testServer(workflow_dashboard_server, {
    muffle_interrupted_workflow_promise(session$flushReact())
    set_inputs_ignoring_interrupted_promises(
      session,
      processed_dataset_checkpoint_file = shiny_upload_input(
        checkpoint_path,
        "application/octet-stream"
      )
    )
    muffle_interrupted_workflow_promise(session$flushReact())
    set_inputs_ignoring_interrupted_promises(
      session,
      load_processed_dataset_checkpoint = 1
    )
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_identical(active_join_source(), "checkpoint")
    testthat::expect_identical(current_analysis_data(), checkpoint_data)
    muffle_interrupted_workflow_promise(session$flushReact())

    controls <- output$basic_model_controls$html
    for (lag in c(0, 1, 3, 6, 12)) {
      testthat::expect_match(controls, paste0("Q95z_lag", lag), fixed = TRUE)
      testthat::expect_false(grepl(paste0("Q95_lag", lag), controls, fixed = TRUE))
    }
    testthat::expect_false(grepl("Q10z_lag3", controls, fixed = TRUE))

    set_inputs_ignoring_interrupted_promises(
      session,
      basic_model_ecology_var = "LIFE_F_OE",
      basic_model_flow_var = "Q95z_lag0",
      basic_model_wq_var = "",
      basic_model_rhs_var = "",
      run_basic_model = 1
    )
    testthat::expect_identical(basic_model_result()$status, "success")
    testthat::expect_true(workflow_artifact_is_current("model_result"))

    # Submit a value absent from the selector, as an old or modified client could.
    set_inputs_ignoring_interrupted_promises(session, basic_model_flow_var = "Q95_lag12")
    set_inputs_ignoring_interrupted_promises(session, run_basic_model = 2)
    testthat::expect_identical(basic_model_result()$status, "blocked")
    testthat::expect_identical(workflow_artifacts()$model_spec$status, "blocked")
    testthat::expect_identical(workflow_artifacts()$model_result$status, "blocked")
    testthat::expect_match(output$basic_model_status$html, "Select Q95z", fixed = TRUE)
    testthat::expect_null(basic_model_result()$export)
    testthat::expect_null(basic_model_result()$diagnostic_plot)
    testthat::expect_false(grepl(
      'id="download_basic_model_', output$basic_model_download_controls$html, fixed = TRUE
    ))
    testthat::expect_identical(current_analysis_data(), checkpoint_data)

    set_inputs_ignoring_interrupted_promises(session, basic_model_flow_var = "Q95z_lag12")
    set_inputs_ignoring_interrupted_promises(session, run_basic_model = 3)
    testthat::expect_identical(basic_model_result()$status, "success")
    testthat::expect_true(workflow_artifact_is_current("model_result"))
    testthat::expect_identical(basic_model_result()$provenance$predictors, "Q95z_lag12")
    testthat::expect_s3_class(basic_model_result()$export$coefficients, "data.frame")
    testthat::expect_identical(current_analysis_data(), checkpoint_data)
  })
})
