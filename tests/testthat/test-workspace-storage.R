source(testthat::test_path("..", "..", "R", "workflow_config.R"))
source(testthat::test_path("..", "..", "R", "workflow_state.R"))
source(testthat::test_path("..", "..", "R", "workspace_state.R"))
source(testthat::test_path("..", "..", "R", "workspace_auth.R"))
source(testthat::test_path("..", "..", "R", "workspace_storage.R"))

new_workspace_storage_fixture <- function(root, workspace_name, values = 1:1000) {
  registry <- new_he_artifact_registry()
  registry <- set_he_artifact_status(registry, "joined_core", "complete")
  registry <- set_he_artifact_status(registry, "analysis_dataset", "complete")
  snapshot <- new_workspace_snapshot(
    workspace_name = workspace_name,
    workflow_artifacts = registry,
    workflow_session = list(task_id = "generate_hev", stage_index = 1L),
    input_values = list(choose_join_method = "A"),
    runtime_state = list(flow_source_revision = 4L),
    datasets = list(
      joined_core = data.frame(site_id = sprintf("S%04d", seq_along(values)), value = values),
      analysis_dataset = data.frame(site_id = sprintf("S%04d", seq_along(values)), value = values)
    ),
    app_version = "test-version"
  )
  list(storage = new_local_workspace_storage(root), snapshot = snapshot)
}

testthat::test_that("storage capabilities distinguish browser, server, and cloud", {
  testthat::expect_error(
    new_cloud_workspace_storage("https://storage.example.test", function() "token"),
    "must implement the workspace auth interface",
    fixed = TRUE
  )
  server_storage <- new_server_file_workspace_storage(tempfile("workspace-capabilities-"))
  legacy_storage <- new_local_workspace_storage(tempfile("workspace-capabilities-"))
  browser_storage <- new_browser_workspace_storage()
  cloud_storage <- new_cloud_workspace_storage(
    "https://storage.example.test",
    new_anonymous_workspace_auth_provider()
  )

  server_capabilities <- workspace_storage_capabilities(server_storage)
  testthat::expect_identical(server_capabilities$location, "server-file")
  testthat::expect_true(server_capabilities$configured)
  testthat::expect_false(server_capabilities$requires_auth)
  testthat::expect_true(workspace_storage_operation_available(
    server_storage,
    "save"
  ))
  testthat::expect_s3_class(legacy_storage, "local_workspace_storage")

  browser_capabilities <- workspace_storage_capabilities(browser_storage)
  testthat::expect_identical(browser_capabilities$location, "browser")
  testthat::expect_false(browser_capabilities$configured)
  testthat::expect_false(browser_capabilities$requires_auth)
  testthat::expect_false(workspace_storage_operation_available(
    browser_storage,
    "save"
  ))
  testthat::expect_error(
    workspace_storage_list(browser_storage),
    "IndexedDB bridge",
    fixed = TRUE
  )

  cloud_capabilities <- workspace_storage_capabilities(cloud_storage)
  testthat::expect_identical(cloud_capabilities$location, "cloud")
  testthat::expect_false(cloud_capabilities$configured)
  testthat::expect_true(cloud_capabilities$requires_auth)
  testthat::expect_false(workspace_storage_operation_available(
    cloud_storage,
    "save"
  ))
})

testthat::test_that("the default storage is local and alternative factories are injectable", {
  default_storage <- workspace_storage_for_session(NULL)
  testthat::expect_s3_class(default_storage, "server_file_workspace_storage")

  old_options <- options(
    hetoolkit.workspace_storage_factory = function(session) {
      new_browser_workspace_storage()
    }
  )
  on.exit(options(old_options), add = TRUE)

  injected <- workspace_storage_for_session(NULL)
  testthat::expect_s3_class(injected, "browser_workspace_storage")
})

testthat::test_that("local storage saves and restores a complete named workspace", {
  root <- tempfile("workspace-storage-")
  on.exit(unlink(root, recursive = TRUE, force = TRUE), add = TRUE)
  fixture <- new_workspace_storage_fixture(root, "River Avon baseline")

  result <- workspace_storage_save(fixture$storage, fixture$snapshot)
  testthat::expect_identical(result$workspace_name, "River Avon baseline")
  testthat::expect_identical(result$dataset_count, 2L)
  testthat::expect_true(file.exists(file.path(
    root, "named", "River-Avon-baseline", "manifest.json"
  )))

  manifest <- workspace_storage_get_manifest(fixture$storage, "River Avon baseline")
  testthat::expect_identical(manifest$storage$backend, "local-content-addressed-v1")
  testthat::expect_identical(manifest$datasets$joined_core$rows, 1000L)
  testthat::expect_identical(manifest$datasets$joined_core$columns, 2L)
  testthat::expect_setequal(
    manifest$datasets$joined_core$artifact_ids,
    c("joined_core", "processed_dataset_checkpoint")
  )
  testthat::expect_true(manifest$datasets$joined_core$bytes > 0)

  restored <- workspace_storage_load(fixture$storage, "River Avon baseline")
  testthat::expect_identical(
    restored$datasets$joined_core,
    fixture$snapshot$datasets$joined_core
  )
  testthat::expect_identical(restored$state$workflow_session$stage_index, 4L)

  index <- workspace_storage_list(fixture$storage)
  testthat::expect_identical(index$workspace_name, "River Avon baseline")
  testthat::expect_identical(index$stage_index, 4L)
  testthat::expect_identical(index$dataset_count, 2L)
})

testthat::test_that("named copies reuse unchanged large data objects", {
  root <- tempfile("workspace-storage-")
  on.exit(unlink(root, recursive = TRUE, force = TRUE), add = TRUE)
  first <- new_workspace_storage_fixture(root, "Baseline copy")
  second <- new_workspace_storage_fixture(root, "Review copy")

  workspace_storage_save(first$storage, first$snapshot)
  workspace_storage_save(second$storage, second$snapshot)

  object_files <- list.files(file.path(root, "objects"), pattern = "\\.rds$")
  testthat::expect_length(object_files, 1L)
  testthat::expect_equal(nrow(workspace_storage_list(first$storage)), 2L)
})

testthat::test_that("an existing name is never overwritten", {
  root <- tempfile("workspace-storage-")
  on.exit(unlink(root, recursive = TRUE, force = TRUE), add = TRUE)
  fixture <- new_workspace_storage_fixture(root, "Protected copy", values = 1:3)
  workspace_storage_save(fixture$storage, fixture$snapshot)
  original <- workspace_storage_load(fixture$storage, "Protected copy")

  changed <- new_workspace_storage_fixture(root, "Protected copy", values = 10:12)
  testthat::expect_error(
    workspace_storage_save(changed$storage, changed$snapshot),
    "already exists",
    fixed = TRUE
  )
  after_failed_save <- workspace_storage_load(fixture$storage, "Protected copy")
  testthat::expect_identical(after_failed_save$datasets, original$datasets)
})

testthat::test_that("load verifies state and large-object checksums before use", {
  root <- tempfile("workspace-storage-")
  on.exit(unlink(root, recursive = TRUE, force = TRUE), add = TRUE)
  fixture <- new_workspace_storage_fixture(root, "Integrity copy")
  workspace_storage_save(fixture$storage, fixture$snapshot)
  manifest <- workspace_storage_get_manifest(fixture$storage, "Integrity copy")
  object_path <- file.path(root, "objects", paste0(
    manifest$datasets$joined_core$object_key,
    ".rds"
  ))
  writeLines("corrupted", object_path, useBytes = TRUE)

  testthat::expect_error(
    workspace_storage_load(fixture$storage, "Integrity copy"),
    "failed its integrity check",
    fixed = TRUE
  )
})

testthat::test_that("callers can restore state without eagerly loading large data", {
  root <- tempfile("workspace-storage-")
  on.exit(unlink(root, recursive = TRUE, force = TRUE), add = TRUE)
  fixture <- new_workspace_storage_fixture(root, "Lazy state copy")
  workspace_storage_save(fixture$storage, fixture$snapshot)

  restored <- workspace_storage_load(
    fixture$storage,
    "Lazy state copy",
    dataset_names = character()
  )
  testthat::expect_length(restored$datasets, 0L)
  testthat::expect_identical(restored$state$workflow_session$stage_index, 4L)
})

testthat::test_that("deleting a named copy prunes only unreferenced objects", {
  root <- tempfile("workspace-storage-")
  on.exit(unlink(root, recursive = TRUE, force = TRUE), add = TRUE)
  first <- new_workspace_storage_fixture(root, "First copy")
  second <- new_workspace_storage_fixture(root, "Second copy")
  workspace_storage_save(first$storage, first$snapshot)
  workspace_storage_save(second$storage, second$snapshot)

  workspace_storage_delete(first$storage, "First copy")
  testthat::expect_equal(nrow(workspace_storage_list(first$storage)), 1L)
  testthat::expect_length(list.files(file.path(root, "objects"), pattern = "\\.rds$"), 1L)

  workspace_storage_delete(second$storage, "Second copy")
  testthat::expect_equal(nrow(workspace_storage_list(first$storage)), 0L)
  testthat::expect_length(list.files(file.path(root, "objects"), pattern = "\\.rds$"), 0L)
})
