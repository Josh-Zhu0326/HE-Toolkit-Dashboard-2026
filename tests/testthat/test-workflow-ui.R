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

testthat::test_that("workflow shell preserves the v2.2 prototype structure", {
  selector_html <- render_workflow_html(workflow_shell_ui())
  workspace_html <- render_workflow_html(workflow_shell_ui("build_he_dataset", 3L))

  testthat::expect_length(
    gregexpr("workflow-task-card", selector_html, fixed = TRUE)[[1]],
    5L
  )
  testthat::expect_match(selector_html, "workflow-contextbar", fixed = TRUE)
  testthat::expect_match(selector_html, "workflow-stagebar-shell", fixed = TRUE)
  testthat::expect_match(workspace_html, "workflow-stage-overview", fixed = TRUE)
  testthat::expect_match(workspace_html, "workflow-grid", fixed = TRUE)
  testthat::expect_match(workspace_html, 'aria-current="step"', fixed = TRUE)
})

testthat::test_that("workflow header owns branding, utilities, and Stage 2 work areas", {
  header_html <- render_workflow_html(
    workflow_header_ui(
      "build_he_dataset",
      2L,
      current_panel = "Process Flow"
    )
  )

  testthat::expect_match(header_html, "HE Toolkit Dashboard", fixed = TRUE)
  testthat::expect_match(header_html, "EA_logo_white.png", fixed = TRUE)
  testthat::expect_match(header_html, "Task selector", fixed = TRUE)
  testthat::expect_match(header_html, "CSV validation", fixed = TRUE)
  testthat::expect_match(header_html, "Biology processing", fixed = TRUE)
  testthat::expect_match(header_html, "Flow processing", fixed = TRUE)
  testthat::expect_match(
    header_html,
    'id="workflow_stage_view_flow"',
    fixed = TRUE
  )
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

testthat::test_that("Workflow Header replaces the legacy primary navbar", {
  project_root <- normalizePath(testthat::test_path("..", ".."), winslash = "/", mustWork = TRUE)
  ui_code <- paste(
    readLines(file.path(project_root, "ui.R"), warn = FALSE),
    collapse = "\n"
  )
  style_html <- render_workflow_html(workflow_style_tags())

  testthat::expect_match(ui_code, 'uiOutput("workflow_header")', fixed = TRUE)
  testthat::expect_match(
    style_html,
    "body.bslib-page-navbar > nav.navbar",
    fixed = TRUE
  )
  testthat::expect_match(ui_code, '"Build HE Dataset"', fixed = TRUE)
  testthat::expect_match(ui_code, '"Explore Relationships"', fixed = TRUE)
  testthat::expect_match(ui_code, '"Model and Export"', fixed = TRUE)
  testthat::expect_false(grepl('nav_panel("Analysis"', ui_code, fixed = TRUE))
})

testthat::test_that("selected Task renders one shared five-stage navigation", {
  html <- render_workflow_html(workflow_shell_ui("generate_hev", 4L))

  testthat::expect_length(gregexpr("workflow_stage_", html, fixed = TRUE)[[1]], 5L)
  testthat::expect_match(
    html,
    "Stage 4 · Explore and Refine Relationships",
    fixed = TRUE
  )
  testthat::expect_match(
    html,
    "Explore the Joined HE dataset and record non-destructive filtering decisions",
    fixed = TRUE
  )
  testthat::expect_match(html, "Current HEV plots", fixed = TRUE)
})

testthat::test_that("navigation targets existing Shiny panels", {
  testthat::expect_identical(workflow_nav_target("generate_hev", 1L), "Data Import")
  testthat::expect_identical(workflow_nav_target("flow_regime", 2L), "Process Flow")
  testthat::expect_identical(workflow_nav_target("ecological_condition", 2L), "Process Biology")
  testthat::expect_identical(workflow_nav_target("build_he_dataset", 3L), "Build HE Dataset")
  testthat::expect_identical(workflow_nav_target("generate_hev", 4L), "HEV Plots")
  testthat::expect_identical(workflow_nav_target("he_modelling", 5L), "Model and Export")
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

testthat::test_that("route-only required Stages never present themselves as optional", {
  cases <- list(
    build_he_dataset = list(
      stages = 1L,
      evidence = c("oe_result", "flow_statistics")
    ),
    generate_hev = list(
      stages = c(1L, 2L),
      evidence = "joined_core"
    ),
    he_modelling = list(
      stages = c(1L, 2L),
      evidence = "joined_core"
    )
  )

  for (task_id in names(cases)) {
    task <- get_he_workflow_task(task_id)
    registry <- new_he_artifact_registry()

    for (stage_index in cases[[task_id]]$stages) {
      steps_html <- render_workflow_html(
        workflow_required_steps_ui(task, stage_index, registry)
      )
      checkpoint_html <- render_workflow_html(
        workflow_checkpoint_ui(task, stage_index, registry)
      )

      testthat::expect_match(
        steps_html,
        'data-required-route="indirect"',
        fixed = TRUE,
        info = sprintf("%s Stage %d", task_id, stage_index)
      )
      testthat::expect_match(steps_html, "Required route stage", fixed = TRUE)
      testthat::expect_match(
        checkpoint_html,
        'data-checkpoint-evidence="downstream-artifact"',
        fixed = TRUE
      )
      testthat::expect_match(
        checkpoint_html,
        "No current completion evidence is recorded yet.",
        fixed = TRUE
      )
      testthat::expect_false(grepl("optional capability", steps_html, fixed = TRUE))
      testthat::expect_identical(
        workflow_stage_status(task, stage_index, registry),
        "not_started"
      )
    }

    for (artifact_id in cases[[task_id]]$evidence) {
      registry <- set_he_artifact_status(
        registry,
        artifact_id,
        "complete"
      )
    }

    for (stage_index in cases[[task_id]]$stages) {
      checkpoint_html <- render_workflow_html(
        workflow_checkpoint_ui(task, stage_index, registry)
      )

      testthat::expect_identical(
        workflow_stage_status(task, stage_index, registry),
        "complete"
      )
      testthat::expect_match(
        checkpoint_html,
        "Current causally linked downstream evidence is recorded.",
        fixed = TRUE
      )
      testthat::expect_match(
        checkpoint_html,
        "does not claim that unrelated or stale calculations ran in this session.",
        fixed = TRUE
      )
    }
  }
})

testthat::test_that("route-only Stage UI rejects progress states as completion", {
  task <- get_he_workflow_task("generate_hev")

  for (status in c("ready", "running", "blocked", "failed", "stale")) {
    registry <- new_he_artifact_registry()
    registry <- set_he_artifact_status(registry, "joined_core", "complete")
    registry <- set_he_artifact_status(registry, "joined_core", status)

    testthat::expect_identical(
      workflow_stage_status(task, 1L, registry),
      "not_started",
      info = status
    )
    checkpoint_html <- render_workflow_html(
      workflow_checkpoint_ui(task, 1L, registry)
    )
    testthat::expect_match(
      checkpoint_html,
      'data-completion-evidence="none"',
      fixed = TRUE,
      info = status
    )
  }
})

testthat::test_that("route-only Stage UI identifies contract-allowed reusable evidence", {
  task <- get_he_workflow_task("generate_hev")
  registry <- new_he_artifact_registry()
  registry <- set_he_artifact_status(
    registry,
    "processed_dataset_checkpoint",
    "complete"
  )

  checkpoint_html <- render_workflow_html(
    workflow_checkpoint_ui(task, 2L, registry)
  )

  testthat::expect_identical(
    workflow_stage_status(task, 2L, registry),
    "complete"
  )
  testthat::expect_match(
    checkpoint_html,
    'data-completion-evidence="validated-reusable"',
    fixed = TRUE
  )
  testthat::expect_match(
    checkpoint_html,
    "A current validated reusable output allowed by this Task is recorded.",
    fixed = TRUE
  )
})

testthat::test_that("route-only status announcements provide an honest next action", {
  task <- get_he_workflow_task("generate_hev")
  registry <- new_he_artifact_registry()

  announcement <- workflow_status_announcement_text(task, 1L, registry)
  testthat::expect_match(
    announcement,
    "Stage status: not started.",
    fixed = TRUE
  )
  testthat::expect_match(
    announcement,
    "Complete the required route work in this Stage or provide a validated reusable output.",
    fixed = TRUE
  )

  registry <- set_he_artifact_status(registry, "joined_core", "complete")
  progressed <- workflow_status_announcement_text(task, 1L, registry)
  testthat::expect_match(progressed, "Stage status: complete.", fixed = TRUE)
  testthat::expect_false(grepl("Next action:", progressed, fixed = TRUE))
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

testthat::test_that("Not started checkpoints always provide a concrete next action", {
  task <- get_he_workflow_task("ecological_condition")
  html <- render_workflow_html(
    workflow_checkpoint_ui(task, 1L, new_he_artifact_registry())
  )

  testthat::expect_match(html, "Not started", fixed = TRUE)
  testthat::expect_match(html, "Upload or import Biology data.", fixed = TRUE)
  testthat::expect_match(
    html,
    "Import Environmental data for the mapped Biology sites.",
    fixed = TRUE
  )
  testthat::expect_false(grepl("No action recorded yet", html, fixed = TRUE))
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
