source(testthat::test_path("..", "..", "R", "workflow_config.R"))
source(testthat::test_path("..", "..", "R", "workflow_state.R"))

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
    ecological_condition = c("R", "R", "-", "O", "O"),
    flow_regime = c("R", "R", "-", "O", "O"),
    build_he_dataset = c("R", "R", "R", "O", "O"),
    generate_hev = c("R", "R", "R", "R", "O"),
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
        "analysis_dataset",
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
    testthat::expect_true(all(task$stage_path %in% c("R", "O", "-")))
    testthat::expect_setequal(
      required_stage_ids(task),
      he_workflow_stage_ids()[task$stage_path == "R"]
    )
    testthat::expect_setequal(
      optional_stage_ids(task),
      he_workflow_stage_ids()[task$stage_path == "O"]
    )
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
    "Join biomonitoring indices with flow statistics and other environmental data"
  )
  testthat::expect_identical(dataset_task$primary_output, "Joined HE dataset")
  testthat::expect_identical(hev_task$task_label, "Generate HEV plots")
  testthat::expect_identical(
    hev_task$description,
    "Produce HEV plots with daily flows or flow statistics."
  )
  testthat::expect_identical(
    hev_task$primary_output,
    "HEV plots, data and data history"
  )
  testthat::expect_identical(model_task$task_label, "Undertake HE modelling")
  testthat::expect_identical(
    model_task$description,
    "Fit, compare and visualise regression-based HE models."
  )
  testthat::expect_identical(
    model_task$primary_output,
    "Current model, diagnostics and data history"
  )
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
    optional_stage = "analysis_dataset"
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
