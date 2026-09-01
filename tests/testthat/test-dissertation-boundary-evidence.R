boundary_complete_registry <- function(registry = new_he_artifact_registry()) {
  for (artifact_id in names(registry)) {
    registry <- set_he_artifact_status(
      registry,
      artifact_id,
      "complete",
      data_source = "boundary evidence fixture",
      history_summary = sprintf("Created current %s evidence.", artifact_id),
      completed_at = as.POSIXct("2026-09-02 00:00:00", tz = "UTC")
    )
  }
  registry
}

testthat::test_that("[B01] missing Flow Statistics block the downstream joined result", {
  shiny::testServer(workflow_dashboard_server, {
    muffle_interrupted_workflow_promise(session$flushReact())
    registry <- set_he_artifact_status(
      workflow_artifacts(),
      "oe_result",
      "complete",
      data_source = "boundary evidence fixture"
    )
    workflow_artifacts(registry)

    set_inputs_ignoring_interrupted_promises(
      session,
      choose_lags = 0,
      choose_join_method = "A",
      join_he = 1
    )
    muffle_interrupted_workflow_promise(session$flushReact())

    artifact <- workflow_artifacts()$joined_core
    testthat::expect_identical(artifact$status, "blocked")
    testthat::expect_false(artifact_is_current(artifact))
    testthat::expect_identical(artifact$output_revision, 0L)
    testthat::expect_match(
      artifact$blocking_reason,
      "Flow Statistics are missing or out of date.",
      fixed = TRUE
    )
    testthat::expect_match(
      artifact$next_action,
      "Calculate or regenerate Flow Statistics",
      fixed = TRUE
    )
    testthat::expect_null(join_request())
  })
})

testthat::test_that("[B02] upstream Flow change stales only dependent descendants", {
  shiny::testServer(workflow_dashboard_server, {
    muffle_interrupted_workflow_promise(session$flushReact())
    registry <- boundary_complete_registry(workflow_artifacts())
    workflow_artifacts(registry)
    revisions_before <- vapply(
      registry,
      `[[`,
      integer(1),
      "output_revision"
    )

    workflow_set_artifact(
      "flow_input",
      "complete",
      data_source = "changed Flow fixture",
      history_summary = "Committed a new current Flow revision.",
      invalidate_downstream = TRUE
    )

    changed <- workflow_artifacts()
    expected_stale <- workflow_descendants("flow_input")
    testthat::expect_true(all(vapply(
      changed[expected_stale],
      function(artifact) identical(artifact$status, "stale"),
      logical(1)
    )))
    testthat::expect_true(all(vapply(
      changed[c(
        "biology_input", "environment_input", "processed_biology",
        "processed_environment", "oe_result", "wq_input", "wq_summary"
      )],
      artifact_is_current,
      logical(1)
    )))
    testthat::expect_identical(
      vapply(changed[expected_stale], `[[`, integer(1), "output_revision"),
      revisions_before[expected_stale]
    )
    testthat::expect_true(all(vapply(
      changed[expected_stale],
      function(artifact) nzchar(artifact$blocking_reason) && nzchar(artifact$next_action),
      logical(1)
    )))
    testthat::expect_identical(changed$flow_input$output_revision, 2L)
  })
})

testthat::test_that("[B03] WQ enrichment change preserves joined_core", {
  shiny::testServer(workflow_dashboard_server, {
    muffle_interrupted_workflow_promise(session$flushReact())
    registry <- boundary_complete_registry(workflow_artifacts())
    workflow_artifacts(registry)
    core_before <- registry$joined_core

    workflow_set_artifact(
      "wq_input",
      "complete",
      data_source = "changed WQ fixture",
      history_summary = "Committed a new current WQ revision.",
      invalidate_downstream = TRUE
    )

    changed <- workflow_artifacts()
    testthat::expect_identical(changed$joined_core, core_before)
    testthat::expect_true(artifact_is_current(changed$joined_core))
    testthat::expect_identical(changed$wq_summary$status, "stale")
    testthat::expect_identical(changed$wq_enrichment$status, "stale")
    testthat::expect_identical(changed$joined_enriched$status, "stale")
    testthat::expect_identical(changed$analysis_dataset$status, "stale")
    testthat::expect_identical(changed$hev_result$status, "stale")
    testthat::expect_identical(changed$model_result$status, "stale")
    testthat::expect_true(artifact_is_current(changed$rhs_enrichment))
    testthat::expect_true(artifact_is_current(changed$processed_dataset_checkpoint))
  })
})

testthat::test_that("[B04] filter exclude and restore rebuild analysis non-destructively", {
  joined <- data.frame(
    biol_site_id = c("B1", "B1", "B2"),
    sample_id = c("S1", "S2", "S3"),
    LIFE_F_OE = c(0.8, 0.9, 1.1),
    Q95z_lag0 = c(-1, 0, 1),
    stringsAsFactors = FALSE
  )
  joined_before <- joined
  registry <- boundary_complete_registry()
  model_revision <- registry$model_result$output_revision
  hev_revision <- registry$hev_result$output_revision

  selection <- exclude_record(
    new_filter_selection(),
    record_id = "S2",
    site_id = "B1",
    sample_id = "S2",
    timestamp = "2026-09-02 00:01:00"
  )
  excluded <- apply_filter_selection(joined, selection)
  registry <- invalidate_he_artifacts_from(registry, "filter_selection")
  registry <- set_he_artifact_status(registry, "filter_selection", "complete")
  registry <- set_he_artifact_status(registry, "exclusion_log", "complete")
  registry <- set_he_artifact_status(registry, "analysis_dataset", "complete")

  testthat::expect_identical(excluded$analysis_dataset$sample_id, c("S1", "S3"))
  testthat::expect_identical(joined, joined_before)
  testthat::expect_identical(registry$analysis_dataset$output_revision, 2L)
  testthat::expect_identical(registry$hev_result$status, "stale")
  testthat::expect_identical(registry$model_result$status, "stale")
  testthat::expect_identical(registry$hev_result$output_revision, hev_revision)
  testthat::expect_identical(registry$model_result$output_revision, model_revision)
  testthat::expect_true(artifact_is_current(registry$joined_core))

  selection <- restore_record(
    selection,
    record_id = "S2",
    timestamp = "2026-09-02 00:02:00"
  )
  restored <- apply_filter_selection(joined, selection)
  registry <- invalidate_he_artifacts_from(registry, "filter_selection")
  registry <- set_he_artifact_status(registry, "filter_selection", "complete")
  registry <- set_he_artifact_status(registry, "exclusion_log", "complete")
  registry <- set_he_artifact_status(registry, "analysis_dataset", "complete")
  log <- build_analysis_exclusion_log(selection)

  testthat::expect_identical(restored$analysis_dataset$sample_id, joined$sample_id)
  testthat::expect_identical(registry$analysis_dataset$output_revision, 3L)
  testthat::expect_equal(nrow(log), 2L)
  testthat::expect_identical(
    log$exclusion_reason,
    c("User excluded record", "User restored record")
  )
  testthat::expect_identical(
    log$timestamp,
    c("2026-09-02 00:01:00", "2026-09-02 00:02:00")
  )
  testthat::expect_true(all(log$current_status == "restored"))
  testthat::expect_identical(joined, joined_before)
})

testthat::test_that("[B05] model specification change stales only the model result", {
  shiny::testServer(workflow_dashboard_server, {
    muffle_interrupted_workflow_promise(session$flushReact())
    registry <- boundary_complete_registry(workflow_artifacts())
    workflow_artifacts(registry)
    model_before <- registry$model_result
    non_model_ids <- setdiff(names(registry), c("model_spec", "model_result"))
    non_model_before <- registry[non_model_ids]

    workflow_set_artifact(
      "model_spec",
      "ready",
      next_action = "Fit the model with the current variable selection.",
      invalidate_downstream = TRUE
    )

    changed <- workflow_artifacts()
    testthat::expect_identical(changed$model_spec$status, "ready")
    testthat::expect_identical(changed$model_result$status, "stale")
    testthat::expect_identical(
      changed$model_result$output_revision,
      model_before$output_revision
    )
    testthat::expect_identical(changed$model_result$data_source, model_before$data_source)
    testthat::expect_match(
      changed$model_result$next_action,
      "Regenerate model_result.",
      fixed = TRUE
    )
    testthat::expect_identical(changed[non_model_ids], non_model_before)
  })
})

testthat::test_that("[B06] failed model evidence is explicit and recoverable", {
  model_mode <- new.env(parent = emptyenv())
  model_mode$value <- "error"
  original_model_runner <- get(
    "run_analysis_model",
    envir = environment(workflow_dashboard_server)
  )
  rlang::local_bindings(
    run_analysis_model = function(...) {
      if (identical(model_mode$value, "error")) {
        stop("Injected deterministic model-fit failure.", call. = FALSE)
      }
      original_model_runner(...)
    },
    .env = environment(workflow_dashboard_server)
  )

  checkpoint_path <- tempfile("b06-model-checkpoint-", fileext = ".rds")
  on.exit(unlink(checkpoint_path, force = TRUE), add = TRUE)
  checkpoint_data <- data.frame(
    biol_site_id = "B1",
    sample_id = paste0("S", 1:4),
    date = as.Date(c("2020-05-01", "2021-05-01", "2022-05-01", "2023-05-01")),
    Year = 2020:2023,
    Q95z_lag0 = c(-1.5, -0.5, 0.5, 1.5),
    LIFE_F_OE = c(0.70, 0.92, 1.05, 1.31),
    stringsAsFactors = FALSE
  )
  write_processed_dataset_checkpoint(checkpoint_data, checkpoint_path)
  upload <- shiny_upload_input(checkpoint_path, "application/octet-stream")

  shiny::testServer(workflow_dashboard_server, {
    muffle_interrupted_workflow_promise(session$flushReact())
    set_inputs_ignoring_interrupted_promises(
      session,
      processed_dataset_checkpoint_file = upload,
      load_processed_dataset_checkpoint = 1
    )
    muffle_interrupted_workflow_promise(session$flushReact())
    retained_upstream <- workflow_artifacts()[c("joined_core", "analysis_dataset")]

    testthat::expect_message(
      set_inputs_ignoring_interrupted_promises(
        session,
        basic_model_flow_var = "Q95z_lag0",
        basic_model_ecology_var = "LIFE_F_OE",
        run_basic_model = 1
      ),
      "Injected deterministic model-fit failure.",
      fixed = TRUE
    )
    muffle_interrupted_workflow_promise(session$flushReact())

    failed_result <- basic_model_result()
    failed_artifact <- workflow_artifacts()$model_result
    testthat::expect_identical(failed_result$status, "failed")
    testthat::expect_false(analysis_model_result_is_exportable(failed_result))
    testthat::expect_null(failed_result$export)
    testthat::expect_identical(failed_artifact$status, "failed")
    testthat::expect_false(artifact_is_current(failed_artifact))
    testthat::expect_identical(failed_artifact$output_revision, 0L)
    testthat::expect_true(nzchar(failed_artifact$blocking_reason))
    testthat::expect_true(nzchar(failed_artifact$next_action))
    testthat::expect_identical(
      workflow_artifacts()[c("joined_core", "analysis_dataset")],
      retained_upstream
    )

    model_mode$value <- "success"
    set_inputs_ignoring_interrupted_promises(session, run_basic_model = 2)
    muffle_interrupted_workflow_promise(session$flushReact())

    recovered_result <- basic_model_result()
    recovered_artifact <- workflow_artifacts()$model_result
    testthat::expect_identical(recovered_result$status, "success")
    testthat::expect_true(analysis_model_result_is_exportable(recovered_result))
    testthat::expect_true(artifact_is_current(recovered_artifact))
    testthat::expect_identical(recovered_artifact$output_revision, 1L)
    testthat::expect_identical(
      workflow_artifacts()[c("joined_core", "analysis_dataset")],
      retained_upstream
    )
  })
})

testthat::test_that("[B07] Resume returns the earliest unmet required stage", {
  registry <- new_he_artifact_registry()
  registry <- set_he_artifact_status(
    registry,
    "joined_core",
    "stale",
    data_source = "retained stale boundary fixture",
    blocking_reason = "A required Stage 3 dependency changed.",
    next_action = "Rebuild the Joined HE dataset."
  )
  registry <- set_he_artifact_status(
    registry,
    "analysis_dataset",
    "complete",
    data_source = "later retained analysis fixture"
  )
  task <- get_he_workflow_task("generate_hev")
  testthat::expect_identical(workflow_resume_stage(task, registry), 3L)

  shiny::testServer(workflow_dashboard_server, {
    muffle_interrupted_workflow_promise(session$flushReact())
    workflow_artifacts(registry)
    set_inputs_ignoring_interrupted_promises(
      session,
      `select_task__generate_hev` = 1
    )
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_identical(workflow_session$task_id, "generate_hev")
    testthat::expect_identical(workflow_session$stage_index, 3L)
    testthat::expect_identical(
      workflow_resume_stage(
        get_he_workflow_task(workflow_session$task_id),
        workflow_artifacts()
      ),
      workflow_session$stage_index
    )
  })
})
