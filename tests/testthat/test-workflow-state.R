source(testthat::test_path("..", "..", "R", "workflow_config.R"))
source(testthat::test_path("..", "..", "R", "workflow_state.R"))

complete_all_artifacts <- function(registry) {
  for (artifact_id in names(registry)) {
    registry <- set_he_artifact_status(
      registry,
      artifact_id,
      "complete",
      data_source = "test fixture",
      history_summary = "Generated for dependency tests.",
      completed_at = as.POSIXct("2026-07-20 12:00:00", tz = "UTC")
    )
  }
  registry
}

testthat::test_that("artifact dependency contract is valid and acyclic", {
  testthat::expect_true(validate_he_artifact_dependencies())
  testthat::expect_identical(anyDuplicated(he_artifact_ids()), 0L)
})

testthat::test_that("dependency cycles fail explicitly", {
  cyclic <- list(a = "b", b = "c", c = "a")
  testthat::expect_error(
    validate_he_artifact_dependencies(cyclic),
    "Artifact dependency cycle detected",
    fixed = TRUE
  )
})

testthat::test_that("new artifacts expose the frozen state schema", {
  artifact <- new_he_artifact("joined_core")

  testthat::expect_named(
    artifact,
    c(
      "artifact_id", "status", "input_revisions", "output_revision",
      "validation_result", "completed_at", "data_source",
      "history_summary", "blocking_reason", "next_action"
    ),
    ignore.order = FALSE
  )
  testthat::expect_identical(artifact$status, "not_started")
  testthat::expect_identical(artifact$output_revision, 0L)
  testthat::expect_match(
    artifact$next_action,
    "Build the Core Joined HE dataset.",
    fixed = TRUE
  )
  testthat::expect_setequal(
    names(he_artifact_default_next_actions),
    he_artifact_ids()
  )
  testthat::expect_true(all(nzchar(he_artifact_default_next_actions)))
})

testthat::test_that("biology changes stale only dependent downstream outputs", {
  registry <- complete_all_artifacts(new_he_artifact_registry())
  changed <- invalidate_he_artifacts_from(registry, "biology_input")

  expected_stale <- c(
    "processed_biology", "oe_result", "joined_core", "joined_enriched",
    "analysis_dataset", "processed_dataset_checkpoint", "hev_result",
    "model_result"
  )
  testthat::expect_true(all(vapply(
    changed[expected_stale],
    function(artifact) identical(artifact$status, "stale"),
    logical(1)
  )))
  testthat::expect_true(artifact_is_current(changed$flow_statistics))
  testthat::expect_true(artifact_is_current(changed$wq_input))
})

testthat::test_that("WQ changes never stale joined_core", {
  registry <- complete_all_artifacts(new_he_artifact_registry())
  changed <- invalidate_he_artifacts_from(registry, "wq_input")

  testthat::expect_true(artifact_is_current(changed$joined_core))
  testthat::expect_identical(changed$joined_enriched$status, "stale")
  testthat::expect_identical(changed$analysis_dataset$status, "stale")
  testthat::expect_identical(changed$hev_result$status, "stale")
  testthat::expect_identical(changed$model_result$status, "stale")
})

testthat::test_that("filter changes preserve joined datasets", {
  registry <- complete_all_artifacts(new_he_artifact_registry())
  changed <- invalidate_he_artifacts_from(registry, "filter_selection")

  testthat::expect_true(artifact_is_current(changed$joined_core))
  testthat::expect_true(artifact_is_current(changed$joined_enriched))
  testthat::expect_true(artifact_is_current(changed$processed_dataset_checkpoint))
  testthat::expect_identical(changed$exclusion_log$status, "stale")
  testthat::expect_identical(changed$analysis_dataset$status, "stale")
  testthat::expect_identical(changed$hev_result$status, "stale")
  testthat::expect_identical(changed$model_result$status, "stale")
})

testthat::test_that("processed dataset checkpoint remains a Stage 3 core output", {
  testthat::expect_identical(
    he_artifact_stage_index[["processed_dataset_checkpoint"]],
    3L
  )
  testthat::expect_identical(
    he_artifact_dependencies$processed_dataset_checkpoint,
    "joined_core"
  )
})

testthat::test_that("invalid IDs and statuses fail explicitly", {
  registry <- new_he_artifact_registry()

  testthat::expect_error(
    new_he_artifact("unknown"),
    "Unknown workflow artifact ID: unknown",
    fixed = TRUE
  )
  testthat::expect_error(
    set_he_artifact_status(registry, "joined_core", "finished"),
    "Unknown workflow status: finished",
    fixed = TRUE
  )
})

testthat::test_that("Resume opens the earliest required Stage without current artifacts", {
  registry <- new_he_artifact_registry()

  testthat::expect_identical(
    workflow_resume_stage(get_he_workflow_task("generate_hev"), registry),
    1L
  )

  registry <- set_he_artifact_status(registry, "joined_core", "complete")
  registry <- set_he_artifact_status(registry, "analysis_dataset", "complete")

  testthat::expect_identical(
    workflow_resume_stage(get_he_workflow_task("generate_hev"), registry),
    4L
  )
})

testthat::test_that("route-only required Stages use downstream artifact progress", {
  cases <- list(
    build_he_dataset = list(stages = 1L, evidence = "oe_result"),
    generate_hev = list(stages = c(1L, 2L), evidence = "joined_core"),
    he_modelling = list(stages = c(1L, 2L), evidence = "joined_core")
  )

  for (task_id in names(cases)) {
    task <- get_he_workflow_task(task_id)
    registry <- new_he_artifact_registry()

    for (stage_index in cases[[task_id]]$stages) {
      testthat::expect_false(
        workflow_required_stage_has_downstream_progress(
          task,
          stage_index,
          registry
        ),
        info = sprintf("%s Stage %d before progress", task_id, stage_index)
      )
    }

    registry <- set_he_artifact_status(
      registry,
      cases[[task_id]]$evidence,
      "complete"
    )

    for (stage_index in cases[[task_id]]$stages) {
      testthat::expect_true(
        workflow_required_stage_has_downstream_progress(
          task,
          stage_index,
          registry
        ),
        info = sprintf("%s Stage %d after progress", task_id, stage_index)
      )
    }
  }
})

testthat::test_that("route-only completion rejects non-current downstream progress", {
  task <- get_he_workflow_task("generate_hev")

  for (status in c("ready", "running", "blocked", "failed", "stale")) {
    registry <- new_he_artifact_registry()
    registry <- set_he_artifact_status(registry, "joined_core", "complete")
    registry <- set_he_artifact_status(registry, "joined_core", status)

    evidence <- workflow_required_stage_completion_evidence(
      task,
      1L,
      registry
    )
    testthat::expect_false(evidence$satisfied, info = status)
    testthat::expect_identical(evidence$evidence_type, "none", info = status)
  }
})

testthat::test_that("route-only completion requires current causal branch evidence", {
  task <- get_he_workflow_task("build_he_dataset")
  registry <- new_he_artifact_registry()
  registry <- set_he_artifact_status(registry, "oe_result", "complete")

  testthat::expect_false(workflow_required_stage_is_satisfied(
    task,
    1L,
    registry
  ))

  registry <- set_he_artifact_status(registry, "flow_statistics", "warning")
  evidence <- workflow_required_stage_completion_evidence(task, 1L, registry)

  testthat::expect_true(evidence$satisfied)
  testthat::expect_identical(evidence$evidence_type, "causal-required")
  testthat::expect_setequal(
    evidence$artifact_ids,
    c("oe_result", "flow_statistics")
  )
  testthat::expect_true(workflow_artifact_has_stage_ancestor(
    "oe_result",
    1L
  ))
  testthat::expect_true(workflow_artifact_has_stage_ancestor(
    "flow_statistics",
    1L
  ))
})

testthat::test_that("route-only completion accepts only contract-allowed reusable output", {
  task <- get_he_workflow_task("generate_hev")
  registry <- new_he_artifact_registry()
  registry <- set_he_artifact_status(
    registry,
    "processed_dataset_checkpoint",
    "complete"
  )

  evidence <- workflow_required_stage_completion_evidence(task, 2L, registry)
  testthat::expect_true(evidence$satisfied)
  testthat::expect_identical(evidence$evidence_type, "validated-reusable")
  testthat::expect_identical(
    evidence$artifact_ids,
    "processed_dataset_checkpoint"
  )

  unrelated <- new_he_artifact_registry()
  unrelated <- set_he_artifact_status(
    unrelated,
    "flow_statistics",
    "complete"
  )
  testthat::expect_false(workflow_required_stage_is_satisfied(
    task,
    1L,
    unrelated
  ))
})

testthat::test_that("Resume returns to a blocked, failed, or stale required Stage", {
  for (status in c("blocked", "failed", "stale")) {
    registry <- new_he_artifact_registry()
    registry <- set_he_artifact_status(registry, "joined_core", status)
    registry <- set_he_artifact_status(registry, "analysis_dataset", "complete")

    testthat::expect_identical(
      workflow_resume_stage(get_he_workflow_task("generate_hev"), registry),
      3L,
      info = status
    )
  }
})

testthat::test_that("a completed Task resumes at its final required Stage", {
  registry <- new_he_artifact_registry()
  for (artifact_id in c("biology_input", "environment_input", "oe_result")) {
    registry <- set_he_artifact_status(registry, artifact_id, "complete")
  }

  testthat::expect_identical(
    workflow_resume_stage(get_he_workflow_task("ecological_condition"), registry),
    2L
  )
})

testthat::test_that("Task completion follows its configured completion artifact", {
  task <- get_he_workflow_task("build_he_dataset")
  registry <- new_he_artifact_registry()

  testthat::expect_false(workflow_task_is_complete(task, registry))
  registry <- set_he_artifact_status(
    registry,
    "processed_dataset_checkpoint",
    "complete"
  )
  testthat::expect_true(workflow_task_is_complete(task, registry))
})

testthat::test_that("completed Task 3 resumes at Stage 3 without Stage 4 analysis", {
  task <- get_he_workflow_task("build_he_dataset")
  registry <- new_he_artifact_registry()
  for (artifact_id in task$required_artifacts) {
    registry <- set_he_artifact_status(registry, artifact_id, "complete")
  }

  testthat::expect_identical(registry$analysis_dataset$status, "not_started")
  testthat::expect_true(workflow_task_is_complete(task, registry))
  testthat::expect_identical(workflow_resume_stage(task, registry), 3L)
})
