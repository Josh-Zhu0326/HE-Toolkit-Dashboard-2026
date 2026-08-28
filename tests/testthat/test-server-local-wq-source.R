testthat::test_that("validated v2 WQ populates determinands without Biology mapping", {
  wq_path <- testthat::test_path(
    "..", "..", "www", "templates", "local_csv_v2", "wq.csv"
  )

  shiny::testServer(workflow_dashboard_server, {
    muffle_interrupted_workflow_promise(session$flushReact())
    set_inputs_ignoring_interrupted_promises(
      session,
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

testthat::test_that("Stage 5 controls expose all present supported Flow lags", {
  checkpoint_path <- tempfile("stage5-flow-lags-", fileext = ".rds")
  on.exit(unlink(checkpoint_path, force = TRUE), add = TRUE)
  checkpoint_data <- data.frame(
    biol_site_id = "B1",
    sample_id = paste0("S", 1:5),
    date = as.Date(paste0(2020:2024, "-05-01")),
    Year = 2020:2024,
    LIFE_F_OE = seq(0.8, 1.2, length.out = 5),
    stringsAsFactors = FALSE
  )
  for (lag in SUPPORTED_FLOW_LAGS) {
    checkpoint_data[[paste0("Q95z_lag", lag)]] <- seq(-1, 1, length.out = 5)
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
    }
    testthat::expect_false(grepl("Q10z_lag3", controls, fixed = TRUE))
  })
})
