testthat::test_that("Stage 3 rejects stale optional supporting data and supports rebuilding", {
  checkpoint_path <- tempfile("stage3-enrichment-", fileext = ".rds")
  on.exit(unlink(checkpoint_path, force = TRUE), add = TRUE)
  core <- data.frame(
    biol_site_id = c("B1", "B2"),
    sample_id = c("S1", "S2"),
    Year = c(2020L, 2021L),
    Q95z_lag0 = c(0.1, -0.1),
    LIFE_F_OE = c(0.9, 1.1),
    stringsAsFactors = FALSE
  )
  write_processed_dataset_checkpoint(core, checkpoint_path)
  upload <- shiny_upload_input(checkpoint_path, "application/octet-stream")

  shiny::testServer(workflow_dashboard_server, {
    set_inputs_ignoring_interrupted_promises(
      session,
      processed_dataset_checkpoint_file = upload
    )
    muffle_interrupted_workflow_promise(session$flushReact())
    set_inputs_ignoring_interrupted_promises(
      session,
      load_processed_dataset_checkpoint = 1
    )
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_true(workflow_artifact_is_current("joined_core"))
    testthat::expect_identical(current_joined_source()$source_dataset, "joined_core")

    wq_contract_summary_result(list(
      status = "success",
      messages = "WQ fixture ready.",
      data = data.frame(
        sample_id = c("S1", "S2"),
        orthophosphate_mean = c(0.04, 0.08),
        stringsAsFactors = FALSE
      )
    ))
    workflow_complete_artifact("wq_input", "test fixture", "Current WQ input.")
    workflow_complete_artifact("wq_summary", "test fixture", "Current WQ summary.")
    set_inputs_ignoring_interrupted_promises(session, selected_enrichments = "wq")
    set_inputs_ignoring_interrupted_promises(session, build_joined_enriched = 1)
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_identical(joined_enriched_result()$status, "success")
    testthat::expect_true(workflow_artifact_is_current("joined_enriched"))
    testthat::expect_identical(
      joined_enriched_result()$provenance$selected_enrichments,
      "wq"
    )
    set_inputs_ignoring_interrupted_promises(session, use_joined_enriched = TRUE)
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_identical(
      current_joined_source()$source_dataset,
      "joined_enriched"
    )
    testthat::expect_true(nzchar(current_joined_source()$source_fingerprint))
    testthat::expect_match(
      output$analysis_source_status$html,
      "Joined HE dataset with optional supporting data (2 rows)",
      fixed = TRUE
    )
    testthat::expect_false(grepl(
      "joined_core|joined_enriched|fingerprint|source_dataset",
      output$analysis_source_status$html
    ))

    workflow_set_artifact(
      "wq_input",
      "complete",
      data_source = "changed test fixture",
      history_summary = "Changed WQ input.",
      invalidate_downstream = TRUE
    )
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_identical(workflow_artifacts()$joined_enriched$status, "stale")
    testthat::expect_true(workflow_artifact_is_current("joined_core"))
    testthat::expect_identical(current_joined_source()$source_dataset, "joined_core")
    testthat::expect_match(
      output$joined_enrichment_status$html,
      "Optional supporting data have changed",
      fixed = TRUE
    )
    testthat::expect_match(
      output$analysis_source_status$html,
      "Core Joined HE dataset (2 rows)",
      fixed = TRUE
    )
    testthat::expect_false(grepl(
      "joined_core|joined_enriched|fingerprint|source_dataset",
      paste(
        output$joined_enrichment_status$html,
        output$analysis_source_status$html
      )
    ))

    workflow_complete_artifact("wq_summary", "test fixture", "Rebuilt WQ summary.")
    set_inputs_ignoring_interrupted_promises(session, build_joined_enriched = 2)
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_true(workflow_artifact_is_current("joined_enriched"))
    set_inputs_ignoring_interrupted_promises(session, use_joined_enriched = FALSE)
    set_inputs_ignoring_interrupted_promises(session, use_joined_enriched = TRUE)
    muffle_interrupted_workflow_promise(session$flushReact())
    testthat::expect_identical(
      current_joined_source()$source_dataset,
      "joined_enriched"
    )

    set_inputs_ignoring_interrupted_promises(
      session,
      selected_enrichments = c("wq", "rhs")
    )
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_identical(workflow_artifacts()$joined_enriched$status, "stale")
    testthat::expect_identical(
      joined_enriched_result()$provenance$selected_enrichments,
      "wq"
    )
    testthat::expect_false(enrichment_result_matches_selection(
      joined_enriched_result(),
      selected_enrichments()
    ))
    testthat::expect_identical(current_joined_source()$source_dataset, "joined_core")
    testthat::expect_match(
      output$joined_enrichment_status$html,
      "Rebuild the Joined HE dataset with optional supporting data",
      fixed = TRUE
    )
  })
})
