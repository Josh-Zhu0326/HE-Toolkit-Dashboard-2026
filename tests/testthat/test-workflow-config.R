source(testthat::test_path("..", "..", "R", "workflow_config.R"))
source(testthat::test_path("..", "..", "R", "workflow_state.R"))

testthat::test_that("public workflow state vocabulary is frozen at eight states", {
  testthat::expect_identical(
    he_workflow_state_labels,
    c(
      "not_started", "blocked", "ready", "running",
      "complete", "warning", "stale", "failed"
    )
  )
})

testthat::test_that("workflow config has five valid stages and Tasks", {
  testthat::expect_true(validate_he_workflow_config())
  testthat::expect_length(he_workflow_stages, 5L)
  testthat::expect_length(he_workflow_tasks, 5L)
  testthat::expect_identical(anyDuplicated(he_workflow_stage_ids()), 0L)
  testthat::expect_identical(anyDuplicated(he_workflow_task_ids()), 0L)
})

testthat::test_that("Task configuration uses task_id as its only Task identifier field", {
  testthat::expect_true(all(vapply(
    he_workflow_tasks,
    function(task) "task_id" %in% names(task),
    logical(1)
  )))
  testthat::expect_false(any(vapply(
    he_workflow_tasks,
    function(task) "goal_id" %in% names(task),
    logical(1)
  )))
})

testthat::test_that("canonical Task IDs are frozen in configured order", {
  testthat::expect_identical(
    he_workflow_task_ids(),
    c(
      "ecological_condition",
      "flow_regime",
      "build_he_dataset",
      "generate_hev",
      "he_modelling"
    )
  )
})

testthat::test_that("Task policy derives stage permissions from stage_path", {
  configured_policy <- stats::setNames(
    lapply(he_workflow_tasks, function(task) {
      task["import_types"]
    }),
    he_workflow_task_ids()
  )

  testthat::expect_identical(
    configured_policy$ecological_condition$import_types,
    c("biology", "environment")
  )
  testthat::expect_identical(configured_policy$flow_regime$import_types, "flow")
  testthat::expect_true(task_stage_is_enabled("generate_hev", 4L))
  testthat::expect_false(task_stage_is_enabled("generate_hev", 5L))
  testthat::expect_identical(task_last_enabled_stage("generate_hev"), 4L)
  testthat::expect_true(task_import_is_enabled("flow_regime", "flow"))
  testthat::expect_false(task_import_is_enabled("flow_regime", "biology"))
})

testthat::test_that("canonical Stage IDs and all five Task paths are frozen exactly", {
  testthat::expect_identical(
    he_workflow_stage_ids(),
    c(
      "prepare_data",
      "process_data",
      "build_dataset",
      "explore_refine",
      "model_export"
    )
  )

  configured_paths <- stats::setNames(
    lapply(he_workflow_tasks, `[[`, "stage_path"),
    he_workflow_task_ids()
  )
  expected_paths <- list(
    ecological_condition = c("R", "R", "-", "-", "-"),
    flow_regime = c("R", "R", "-", "-", "-"),
    build_he_dataset = c("R", "R", "R", "-", "-"),
    generate_hev = c("R", "R", "R", "R", "-"),
    he_modelling = c("R", "R", "R", "R", "R")
  )

  testthat::expect_identical(configured_paths, expected_paths)
})

testthat::test_that("completion and reuse contracts are frozen exactly", {
  contract_fields <- c(
    "required_artifacts",
    "completion_artifact",
    "reusable_artifacts",
    "valid_next_tasks"
  )
  configured_contracts <- stats::setNames(
    lapply(he_workflow_tasks, function(task) task[contract_fields]),
    he_workflow_task_ids()
  )
  expected_contracts <- list(
    ecological_condition = list(
      required_artifacts = c("biology_input", "environment_input", "oe_result"),
      completion_artifact = "oe_result",
      reusable_artifacts = c("processed_biology", "processed_environment", "oe_result"),
      valid_next_tasks = c("build_he_dataset", "generate_hev", "he_modelling")
    ),
    flow_regime = list(
      required_artifacts = c("flow_input", "flow_statistics"),
      completion_artifact = "flow_statistics",
      reusable_artifacts = c("processed_flow", "flow_statistics"),
      valid_next_tasks = c("build_he_dataset", "generate_hev", "he_modelling")
    ),
    build_he_dataset = list(
      required_artifacts = c(
        "oe_result",
        "flow_statistics",
        "joined_core",
        "processed_dataset_checkpoint"
      ),
      completion_artifact = "processed_dataset_checkpoint",
      reusable_artifacts = c(
        "joined_core",
        "joined_enriched",
        "processed_dataset_checkpoint"
      ),
      valid_next_tasks = c("generate_hev", "he_modelling")
    ),
    generate_hev = list(
      required_artifacts = c("joined_core", "analysis_dataset", "hev_result"),
      completion_artifact = "hev_result",
      reusable_artifacts = c(
        "processed_dataset_checkpoint",
        "analysis_dataset",
        "hev_result"
      ),
      valid_next_tasks = "he_modelling"
    ),
    he_modelling = list(
      required_artifacts = c("joined_core", "analysis_dataset", "model_result"),
      completion_artifact = "model_result",
      reusable_artifacts = c(
        "processed_dataset_checkpoint",
        "analysis_dataset",
        "model_result"
      ),
      valid_next_tasks = "generate_hev"
    )
  )

  testthat::expect_identical(configured_contracts, expected_contracts)
})

testthat::test_that("every Task path uses the shared five-stage contract", {
  for (task in he_workflow_tasks) {
    testthat::expect_length(task$stage_path, 5L)
    testthat::expect_true(all(task$stage_path %in% c("R", "-")))
    testthat::expect_setequal(
      required_stage_ids(task),
      he_workflow_stage_ids()[task$stage_path == "R"]
    )
    derived_stage_numbers <- which(vapply(
      seq_along(task$stage_path),
      function(stage_index) task_stage_is_enabled(task, stage_index),
      logical(1)
    ))
    testthat::expect_identical(derived_stage_numbers, which(task$stage_path == "R"))
  }
})

testthat::test_that("client-confirmed Task wording is represented exactly", {
  condition_task <- get_he_workflow_task("ecological_condition")
  dataset_task <- get_he_workflow_task("build_he_dataset")
  hev_task <- get_he_workflow_task("generate_hev")
  model_task <- get_he_workflow_task("he_modelling")

  testthat::expect_identical(condition_task$primary_output, "Expected values and O:E ratios")
  testthat::expect_identical(
    dataset_task$task_label,
    "Combine biology, flow and environmental data"
  )
  testthat::expect_identical(dataset_task$primary_output, "Joined HE dataset")
  testthat::expect_identical(hev_task$task_label, "Generate and interpret HEV plots")
  testthat::expect_identical(
    hev_task$description,
    "Select sites and biological and flow metrics, generate HEV plots, review patterns and export the current plot."
  )
  testthat::expect_identical(
    hev_task$primary_output,
    "HEV plots, plot data and provenance"
  )
  testthat::expect_identical(model_task$task_label, "Build and diagnose an HE model")
  testthat::expect_identical(
    model_task$description,
    "Select flow and ecology variables, fit an eligible model, review diagnostics and export the current results."
  )
  testthat::expect_identical(
    model_task$primary_output,
    "Model results, diagnostics and export files"
  )
})

testthat::test_that("Task 4 and Task 5 use the strict v2 Stage paths", {
  hev_task <- get_he_workflow_task("generate_hev")
  model_task <- get_he_workflow_task("he_modelling")

  testthat::expect_identical(hev_task$stage_path, c("R", "R", "R", "R", "-"))
  testthat::expect_identical(model_task$stage_path, c("R", "R", "R", "R", "R"))
  testthat::expect_identical(hev_task$completion_artifact, "hev_result")
  testthat::expect_identical(model_task$completion_artifact, "model_result")
})

testthat::test_that("user-facing workflow strings exclude superseded terminology", {
  user_facing <- unlist(lapply(
    he_workflow_tasks,
    function(task) unlist(task[c("task_label", "description", "primary_output")], use.names = FALSE)
  ), use.names = FALSE)

  testthat::expect_false(any(grepl("Goal", user_facing, fixed = TRUE)))
  testthat::expect_false(any(grepl("analysis_dataset", user_facing, fixed = TRUE)))
  testthat::expect_false(any(grepl("NRFA fallback", user_facing, fixed = TRUE)))
})

testthat::test_that("unknown Task IDs fail explicitly", {
  testthat::expect_error(
    get_he_workflow_task("unknown-task"),
    "Unknown workflow task ID: unknown-task",
    fixed = TRUE
  )
})

testthat::test_that("config validation rejects missing required Task fields", {
  invalid_tasks <- he_workflow_tasks
  invalid_tasks[[1]]$task_label <- NULL

  testthat::expect_error(
    validate_he_workflow_config(tasks = invalid_tasks),
    "Workflow Task 1 is missing required field(s): task_label",
    fixed = TRUE
  )
})

testthat::test_that("config validation rejects unknown artifact IDs in every contract field", {
  for (field_name in c("required_artifacts", "reusable_artifacts", "completion_artifact")) {
    invalid_tasks <- he_workflow_tasks
    invalid_tasks[[1]][[field_name]] <- "misspelled_artifact"

    testthat::expect_error(
      validate_he_workflow_config(tasks = invalid_tasks),
      "refers to unknown artifact ID(s): misspelled_artifact",
      fixed = TRUE,
      info = field_name
    )
  }
})

testthat::test_that("config validation rejects artifacts without a Stage mapping", {
  invalid_mapping <- he_artifact_stage_index[names(he_artifact_stage_index) != "oe_result"]

  testthat::expect_error(
    validate_he_workflow_config(artifact_stage_index = invalid_mapping),
    "refers to artifact(s) without a stage mapping: oe_result",
    fixed = TRUE
  )
})

testthat::test_that("config validation rejects required artifacts outside required Stages", {
  invalid_cases <- list(
    unused_stage = "joined_core",
    disabled_stage = "analysis_dataset"
  )

  for (artifact_id in invalid_cases) {
    invalid_tasks <- he_workflow_tasks
    invalid_tasks[[1]]$required_artifacts <- c(
      invalid_tasks[[1]]$required_artifacts,
      artifact_id
    )

    testthat::expect_error(
      validate_he_workflow_config(tasks = invalid_tasks),
      sprintf(
        "Task ecological_condition has required artifact(s) mapped to a non-required Stage: %s",
        artifact_id
      ),
      fixed = TRUE,
      info = artifact_id
    )
  }
})

testthat::test_that("config validation rejects superseded optional Stage symbols", {
  invalid_tasks <- he_workflow_tasks
  invalid_tasks[[1]]$stage_path[[4L]] <- "O"

  testthat::expect_error(
    validate_he_workflow_config(tasks = invalid_tasks),
    "Task ecological_condition has an invalid five-stage path.",
    fixed = TRUE
  )
})

testthat::test_that("config validation rejects non-contiguous Stage paths", {
  invalid_stages <- he_workflow_tasks
  invalid_stages[[1]]$stage_path <- c("R", "-", "R", "-", "-")
  testthat::expect_error(
    validate_he_workflow_config(tasks = invalid_stages),
    "must require a contiguous Stage path starting at Stage 1",
    fixed = TRUE
  )
})

testthat::test_that("config validation rejects reusable artifacts from disabled Stages", {
  invalid_reuse <- he_workflow_tasks
  invalid_reuse[[3]]$reusable_artifacts <- c(
    invalid_reuse[[3]]$reusable_artifacts,
    "analysis_dataset"
  )
  testthat::expect_error(
    validate_he_workflow_config(tasks = invalid_reuse),
    "reusable artifact(s) mapped to a disabled Stage: analysis_dataset",
    fixed = TRUE
  )
})

testthat::test_that("config validation rejects dependencies on later Stages", {
  invalid_dependencies <- he_artifact_dependencies
  invalid_dependencies$processed_dataset_checkpoint <- "analysis_dataset"

  testthat::expect_error(
    validate_he_workflow_config(artifact_dependencies = invalid_dependencies),
    paste(
      "Artifact processed_dataset_checkpoint depends on later-Stage artifact(s):",
      "analysis_dataset"
    ),
    fixed = TRUE
  )
})
