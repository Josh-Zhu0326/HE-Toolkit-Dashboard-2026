source(testthat::test_path("..", "..", "R", "workflow_config.R"))
source(testthat::test_path("..", "..", "R", "workflow_state.R"))
source(testthat::test_path("..", "..", "R", "workspace_state.R"))
source(testthat::test_path("..", "..", "R", "workspace_auth.R"))
source(testthat::test_path("..", "..", "R", "workspace_storage.R"))

workspace_test_snapshot <- function(
    workspace_name = "River Avon review",
    task_id = "generate_hev",
    stage_index = 1L,
    registry = new_he_artifact_registry(),
    datasets = list(joined_core = data.frame(site = "A", value = 1))) {
  new_workspace_snapshot(
    workspace_name = workspace_name,
    workflow_artifacts = registry,
    workflow_session = list(task_id = task_id, stage_index = stage_index),
    input_values = list(choose_lags = c(0L, 1L)),
    runtime_state = list(flow_source_revision = 3L),
    datasets = datasets,
    current_panel = "Build HE Dataset",
    app_version = "test-version",
    saved_at = as.POSIXct("2026-08-04 10:30:00", tz = "UTC"),
    workspace_id = "workspace-test-id"
  )
}

testthat::test_that("workspace names become safe cross-platform directory names", {
  testthat::expect_identical(
    workspace_directory_name("  River Avon / July review  "),
    "River-Avon-July-review"
  )
  testthat::expect_identical(workspace_directory_name("CON"), "workspace-CON")
  testthat::expect_identical(
    workspace_directory_name("\u6cb3\u6d41 \u9879\u76ee"),
    "\u6cb3\u6d41-\u9879\u76ee"
  )
  testthat::expect_error(validate_workspace_name("  "), "Enter a workspace name", fixed = TRUE)
  testthat::expect_error(
    validate_workspace_name(paste(rep("x", 81L), collapse = "")),
    "80 characters or fewer",
    fixed = TRUE
  )
})

testthat::test_that("workspace snapshots preserve state without upload paths", {
  snapshot <- workspace_test_snapshot()

  testthat::expect_identical(snapshot$schema_version, workspace_schema_version)
  testthat::expect_identical(snapshot$workspace$directory_name, "River-Avon-review")
  testthat::expect_identical(snapshot$state$input_values$choose_lags, c(0L, 1L))
  testthat::expect_false(any(grepl("file|csv|datapath", names(snapshot$state$input_values))))
  testthat::expect_silent(validate_workspace_snapshot(snapshot))

  summary <- workspace_state_summary(snapshot)
  testthat::expect_identical(summary$workspace_id, "workspace-test-id")
  testthat::expect_identical(summary$dataset_count, 1L)
  testthat::expect_identical(summary$resume_stage, 1L)
})

testthat::test_that("restore derives the Stage from artifact state", {
  registry <- new_he_artifact_registry()
  registry <- set_he_artifact_status(registry, "joined_core", "complete")
  registry <- set_he_artifact_status(registry, "analysis_dataset", "complete")
  snapshot <- workspace_test_snapshot(
    registry = registry,
    stage_index = 1L,
    datasets = list(
      joined_core = data.frame(site = "A", value = 1),
      analysis_dataset = data.frame(site = "A", value = 1)
    )
  )

  restored <- prepare_workspace_for_restore(snapshot)
  testthat::expect_identical(restored$state$workflow_session$stage_index, 4L)
})

testthat::test_that("current scientific artifacts require their saved data objects", {
  registry <- new_he_artifact_registry()
  registry <- set_he_artifact_status(registry, "joined_core", "complete")

  testthat::expect_error(
    workspace_test_snapshot(registry = registry, datasets = list()),
    "artifact 'joined_core' is missing its saved data object",
    fixed = TRUE
  )
})

testthat::test_that("incompatible or malformed workspace state fails safely", {
  snapshot <- workspace_test_snapshot()
  snapshot$schema_version <- "99.0.0"
  testthat::expect_error(
    validate_workspace_snapshot(snapshot),
    "is not supported",
    fixed = TRUE
  )

  snapshot <- workspace_test_snapshot()
  snapshot$state$workflow_artifacts$unknown <- snapshot$state$workflow_artifacts$joined_core
  testthat::expect_error(
    validate_workspace_snapshot(snapshot),
    "does not match the current application schema",
    fixed = TRUE
  )

  snapshot <- workspace_test_snapshot()
  snapshot$state$workflow_session$task_id <- "unknown_task"
  testthat::expect_error(
    validate_workspace_snapshot(snapshot),
    "contains an unknown Task",
    fixed = TRUE
  )
})

testthat::test_that("cloud storage constructor reserves the backend contract", {
  storage <- new_cloud_workspace_storage(
    "https://storage.example.test",
    auth_provider = new_anonymous_workspace_auth_provider()
  )

  testthat::expect_s3_class(storage, "cloud_workspace_storage")
  testthat::expect_error(
    workspace_storage_list(storage),
    "requires an authenticated user",
    fixed = TRUE
  )
  authenticated_context <- new_workspace_access_context(
    new_workspace_identity(authenticated = TRUE, subject = "provider|user-123"),
    access_token = "test-token"
  )
  testthat::expect_error(
    workspace_storage_list(storage, authenticated_context),
    "Cloud workspace storage is not configured",
    fixed = TRUE
  )
})
