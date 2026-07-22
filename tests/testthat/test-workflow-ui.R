source(testthat::test_path("..", "..", "R", "workflow_config.R"))
source(testthat::test_path("..", "..", "R", "workflow_state.R"))
source(testthat::test_path("..", "..", "R", "workflow_ui.R"))

render_workflow_html <- function(tag) {
  htmltools::renderTags(tag)$html
}

testthat::test_that("Task selector renders all five client-confirmed Tasks", {
  html <- render_workflow_html(workflow_task_selector_ui())

  testthat::expect_length(gregexpr("Start or resume Task", html, fixed = TRUE)[[1]], 5L)
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
  registry <- set_he_artifact_status(registry, "oe_result", "complete")
  html <- render_workflow_html(workflow_task_selector_ui(registry = registry))

  testthat::expect_length(gregexpr("Review completed Task", html, fixed = TRUE)[[1]], 1L)
  testthat::expect_length(gregexpr("Start or resume Task", html, fixed = TRUE)[[1]], 4L)
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
