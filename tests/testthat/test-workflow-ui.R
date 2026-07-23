source(testthat::test_path("..", "..", "R", "workflow_config.R"))
source(testthat::test_path("..", "..", "R", "workflow_state.R"))
source(testthat::test_path("..", "..", "R", "workflow_ui.R"))

render_workflow_html <- function(tag) {
  htmltools::renderTags(tag)$html
}

testthat::test_that("Task selector renders all five client-confirmed Tasks", {
  html <- render_workflow_html(workflow_task_selector_ui())

  testthat::expect_length(gregexpr("Start or resume Task", html, fixed = TRUE)[[1]], 5L)
  testthat::expect_length(gregexpr("Required stages", html, fixed = TRUE)[[1]], 5L)
  testthat::expect_length(gregexpr("Reusable outputs", html, fixed = TRUE)[[1]], 5L)
  testthat::expect_length(gregexpr("Next step", html, fixed = TRUE)[[1]], 5L)
  testthat::expect_match(html, "Assess ecological condition", fixed = TRUE)
  testthat::expect_match(html, "Summarise the flow regime", fixed = TRUE)
  testthat::expect_match(
    html,
    "Join biomonitoring indices with flow statistics and other environmental data",
    fixed = TRUE
  )
  testthat::expect_match(html, "Generate HEV plots", fixed = TRUE)
  testthat::expect_match(html, "Undertake HE modelling", fixed = TRUE)
})

testthat::test_that("Task selector consumes completion artifact state", {
  registry <- new_he_artifact_registry()
  registry <- set_he_artifact_status(registry, "biology_input", "complete")
  registry <- set_he_artifact_status(registry, "environment_input", "complete")
  registry <- set_he_artifact_status(registry, "oe_result", "complete")
  registry <- set_he_artifact_status(registry, "processed_biology", "complete")
  html <- render_workflow_html(workflow_task_selector_ui(registry = registry))

  testthat::expect_length(gregexpr("Review completed Task", html, fixed = TRUE)[[1]], 1L)
  testthat::expect_length(gregexpr("Start or resume Task", html, fixed = TRUE)[[1]], 4L)
  testthat::expect_match(html, "Processed biology", fixed = TRUE)
  testthat::expect_match(html, "Review Stage 2", fixed = TRUE)
})

testthat::test_that("legacy hard-coded progress navigation is removed", {
  project_root <- normalizePath(testthat::test_path("..", ".."), winslash = "/", mustWork = TRUE)
  active_ui_code <- paste(
    readLines(file.path(project_root, "global.R"), warn = FALSE),
    readLines(file.path(project_root, "ui.R"), warn = FALSE),
    collapse = "\n"
  )

  testthat::expect_false(grepl("wf_progress_bar", active_ui_code, fixed = TRUE))
  testthat::expect_false(grepl("Join & Analyse", active_ui_code, fixed = TRUE))
})

testthat::test_that("selected Task renders one shared five-stage navigation", {
  html <- render_workflow_html(workflow_shell_ui("generate_hev", 4L))

  testthat::expect_length(gregexpr("workflow_stage_", html, fixed = TRUE)[[1]], 5L)
  testthat::expect_match(html, "Current stage · 4 of 5", fixed = TRUE)
  testthat::expect_match(html, "Produce HEV plots with daily flows or flow statistics", fixed = TRUE)
  testthat::expect_match(html, "Open HEV Plots", fixed = TRUE)
})

testthat::test_that("navigation targets existing Shiny panels", {
  testthat::expect_identical(workflow_nav_target("generate_hev", 1L), "Data Import")
  testthat::expect_identical(workflow_nav_target("flow_regime", 2L), "Process Flow")
  testthat::expect_identical(workflow_nav_target("ecological_condition", 2L), "Process Biology")
  testthat::expect_identical(workflow_nav_target("build_he_dataset", 3L), "Analysis")
  testthat::expect_identical(workflow_nav_target("generate_hev", 4L), "HEV Plots")
  testthat::expect_identical(workflow_nav_target("he_modelling", 5L), "Analysis")
})

testthat::test_that("not-used stages are disabled", {
  html <- render_workflow_html(workflow_shell_ui("ecological_condition", 1L))
  stage_three <- regmatches(
    html,
    regexpr('<button[^>]*id="workflow_stage_3"[^>]*>', html)
  )

  testthat::expect_match(stage_three, "disabled", fixed = TRUE)
})

testthat::test_that("optional reusable artifacts do not affect required Stage status", {
  task <- get_he_workflow_task("build_he_dataset")
  registry <- new_he_artifact_registry()
  registry <- set_he_artifact_status(registry, "joined_core", "complete")
  registry <- set_he_artifact_status(
    registry,
    "processed_dataset_checkpoint",
    "complete"
  )

  html <- render_workflow_html(workflow_required_steps_ui(task, 3L, registry))

  testthat::expect_match(html, "Core Joined HE dataset", fixed = TRUE)
  testthat::expect_match(
    html,
    "Downloadable Joined HE dataset checkpoint",
    fixed = TRUE
  )
  testthat::expect_false(grepl("Enriched Joined HE dataset", html, fixed = TRUE))
  testthat::expect_identical(registry$joined_enriched$status, "not_started")
  testthat::expect_identical(workflow_stage_status(task, 3L, registry), "complete")
})

testthat::test_that("Checkpoint renders real artifact metadata and recovery guidance", {
  task <- get_he_workflow_task("ecological_condition")
  registry <- new_he_artifact_registry()
  registry <- set_he_artifact_status(
    registry,
    "biology_input",
    "blocked",
    data_source = "Local biology workbook",
    history_summary = "Validated 12 records before a mapping error.",
    blocking_reason = "One biology site is not mapped.",
    next_action = "Add the missing site mapping and validate again."
  )

  html <- render_workflow_html(workflow_checkpoint_ui(task, 1L, registry))

  testthat::expect_match(html, "Local biology workbook", fixed = TRUE)
  testthat::expect_match(html, "Validated 12 records before a mapping error.", fixed = TRUE)
  testthat::expect_match(html, "One biology site is not mapped.", fixed = TRUE)
  testthat::expect_match(html, "Add the missing site mapping and validate again.", fixed = TRUE)
  testthat::expect_false(grepl("Shown after", html, fixed = TRUE))
})

testthat::test_that("Core-only scope is informational and disappears when enrichment is selected", {
  task <- get_he_workflow_task("build_he_dataset")

  core_only_html <- render_workflow_html(workflow_core_scope_ui(task))
  testthat::expect_match(core_only_html, "Core-only scope", fixed = TRUE)
  testthat::expect_match(core_only_html, "does not block the Core Joined HE dataset", fixed = TRUE)

  selected_html <- render_workflow_html(workflow_core_scope_ui(task, "wq"))
  testthat::expect_identical(as.character(selected_html), "")
  testthat::expect_error(
    workflow_core_scope_ui(task, "unknown"),
    "Selected enrichments must contain only 'wq' or 'rhs'.",
    fixed = TRUE
  )
})

testthat::test_that("Task cards expose configured Stage labels and stable state attributes", {
  html <- render_workflow_html(workflow_task_selector_ui())

  testthat::expect_match(html, 'data-task-id="build_he_dataset"', fixed = TRUE)
  testthat::expect_match(html, 'data-completion-status="not_started"', fixed = TRUE)
  testthat::expect_match(html, 'data-resume-stage="1"', fixed = TRUE)
  for (stage in he_workflow_stages) {
    testthat::expect_match(html, stage$stage_label, fixed = TRUE)
  }
})

testthat::test_that("Checkpoint and announcement expose accessibility state", {
  html <- render_workflow_html(workflow_shell_ui("build_he_dataset", 3L))

  testthat::expect_match(html, 'data-checkpoint-node="joined_core"', fixed = TRUE)
  testthat::expect_match(html, 'data-checkpoint-status="not_started"', fixed = TRUE)
  testthat::expect_match(html, 'aria-live="polite"', fixed = TRUE)
  testthat::expect_match(html, 'aria-atomic="true"', fixed = TRUE)
  testthat::expect_match(html, 'role="note"', fixed = TRUE)
  testthat::expect_match(html, 'data-workflow-scope="core-only"', fixed = TRUE)
})

testthat::test_that("Rendered workflow excludes superseded user-facing terminology", {
  html <- paste(
    render_workflow_html(workflow_task_selector_ui()),
    render_workflow_html(workflow_shell_ui("build_he_dataset", 3L))
  )

  testthat::expect_false(grepl("Goal", html, fixed = TRUE))
  testthat::expect_false(grepl("analysis_dataset", html, fixed = TRUE))
  testthat::expect_false(grepl("NRFA fallback", html, fixed = TRUE))
})
