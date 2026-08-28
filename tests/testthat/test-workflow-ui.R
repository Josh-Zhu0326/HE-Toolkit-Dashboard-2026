source(testthat::test_path("..", "..", "R", "workflow_config.R"))
source(testthat::test_path("..", "..", "R", "workflow_state.R"))
source(testthat::test_path("..", "..", "R", "workflow_ui.R"))

render_workflow_html <- function(tag) {
  htmltools::renderTags(tag)$html
}

testthat::test_that("Task selector renders all five client-confirmed Tasks", {
  html <- render_workflow_html(workflow_task_selector_ui())

  testthat::expect_length(gregexpr("Start Task", html, fixed = TRUE)[[1]], 5L)
  testthat::expect_length(gregexpr("Task 0", html, fixed = TRUE)[[1]], 5L)
  testthat::expect_length(gregexpr("Primary output", html, fixed = TRUE)[[1]], 5L)
  testthat::expect_false(grepl("Goal", html, fixed = TRUE))
  testthat::expect_false(grepl("Required stages", html, fixed = TRUE))
  testthat::expect_false(grepl("Reusable outputs", html, fixed = TRUE))
  testthat::expect_false(grepl("Next step", html, fixed = TRUE))
  testthat::expect_match(html, "Assess ecological condition", fixed = TRUE)
  testthat::expect_match(html, "Summarise the flow regime", fixed = TRUE)
  testthat::expect_match(
    html,
    "Combine biology, flow and environmental data",
    fixed = TRUE
  )
  testthat::expect_match(html, "Generate and interpret HEV plots", fixed = TRUE)
  testthat::expect_match(html, "Build and diagnose an HE model", fixed = TRUE)
})

testthat::test_that("Task selector keeps five columns on laptops and reflows on small screens", {
  style_html <- render_workflow_html(workflow_style_tags())

  testthat::expect_match(
    style_html,
    ".workflow-task-grid { margin-top:26px; display:grid; grid-template-columns:repeat(5,minmax(0,1fr))",
    fixed = TRUE
  )
  testthat::expect_match(style_html, "@media (max-width:959px)", fixed = TRUE)
  testthat::expect_match(
    style_html,
    ".workflow-task-grid { grid-template-columns:repeat(2,minmax(0,1fr)); }",
    fixed = TRUE
  )
  testthat::expect_match(style_html, "@media (max-width:599px)", fixed = TRUE)
  testthat::expect_match(
    style_html,
    ".workflow-task-grid { grid-template-columns:minmax(0,1fr); }",
    fixed = TRUE
  )
  testthat::expect_match(
    style_html,
    ".workflow-task-output { margin:0 0 17px;",
    fixed = TRUE
  )
  testthat::expect_match(
    style_html,
    ".workflow-task-card > .action-label { min-width:0; display:flex; flex:1 1 auto; flex-direction:column;",
    fixed = TRUE
  )
  testthat::expect_match(
    style_html,
    ".workflow-action-label { align-self:flex-start; margin-top:auto;",
    fixed = TRUE
  )
})

testthat::test_that("chart pages and tables expose one responsive content width", {
  project_root <- normalizePath(testthat::test_path("..", ".."), winslash = "/", mustWork = TRUE)
  ui_code <- paste(readLines(file.path(project_root, "ui.R"), warn = FALSE), collapse = "\n")
  server_code <- paste(readLines(file.path(project_root, "server.R"), warn = FALSE), collapse = "\n")

  testthat::expect_match(ui_code, ".dashboard-page-wide", fixed = TRUE)
  testthat::expect_match(ui_code, ".dataTables_scrollBody", fixed = TRUE)
  testthat::expect_match(ui_code, "overflow-x: auto !important", fixed = TRUE)
  testthat::expect_false(grepl('scrollY = "400px"', server_code, fixed = TRUE))
  testthat::expect_false(grepl('scrollY = "600px"', server_code, fixed = TRUE))
})

testthat::test_that("Flow heatmaps expose PDF, CSV and PNG download controls", {
  project_root <- normalizePath(testthat::test_path("..", ".."), winslash = "/", mustWork = TRUE)
  ui_code <- paste(readLines(file.path(project_root, "ui.R"), warn = FALSE), collapse = "\n")
  server_code <- paste(readLines(file.path(project_root, "server.R"), warn = FALSE), collapse = "\n")

  testthat::expect_match(ui_code, 'downloadSelectUI("FlowHeatmap", choices = c("PDF", "CSV", "PNG"))', fixed = TRUE)
  testthat::expect_match(ui_code, 'downloadButtonUI("FlowHeatmap")', fixed = TRUE)
  testthat::expect_match(ui_code, 'downloadSelectUI("ImputedFlowHeatmap", choices = c("PDF", "CSV", "PNG"))', fixed = TRUE)
  testthat::expect_match(ui_code, 'downloadButtonUI("ImputedFlowHeatmap")', fixed = TRUE)

  selector_html <- render_workflow_html(downloadSelectUI("FlowHeatmap", choices = c("PDF", "CSV", "PNG")))
  testthat::expect_match(selector_html, "PDF", fixed = TRUE)
  testthat::expect_match(selector_html, "CSV", fixed = TRUE)
  testthat::expect_match(selector_html, "PNG", fixed = TRUE)
  testthat::expect_false(grepl("JPEG", selector_html, fixed = TRUE))
  testthat::expect_match(
    server_code,
    "function() build_flow_heatmap_plot(flow_data_with_donors())",
    fixed = TRUE
  )
  testthat::expect_match(server_code, "download_data = flow_data_with_donors", fixed = TRUE)
})

testthat::test_that("additional donor Flow inputs are located in Stage 1", {
  project_root <- normalizePath(testthat::test_path("..", ".."), winslash = "/", mustWork = TRUE)
  ui_code <- paste(readLines(file.path(project_root, "ui.R"), warn = FALSE), collapse = "\n")
  data_import_start <- regexpr('nav_panel(title = "Data Import"', ui_code, fixed = TRUE)[[1]]
  process_flow_start <- regexpr('nav_panel("Process Flow"', ui_code, fixed = TRUE)[[1]]
  stage_three_start <- regexpr("# STAGE 3 ----", ui_code, fixed = TRUE)[[1]]
  data_import_code <- substr(ui_code, data_import_start, process_flow_start - 1L)
  process_flow_code <- substr(ui_code, process_flow_start, stage_three_start - 1L)

  testthat::expect_gt(data_import_start, 0L)
  testthat::expect_gt(process_flow_start, data_import_start)
  testthat::expect_gt(stage_three_start, process_flow_start)
  testthat::expect_match(data_import_code, 'textAreaInput("donor_mapping_paste"', fixed = TRUE)
  testthat::expect_match(data_import_code, 'textAreaInput("donor_list_paste"', fixed = TRUE)
  testthat::expect_match(data_import_code, 'actionButton("import_donor_flow"', fixed = TRUE)
  testthat::expect_false(grepl('textAreaInput("donor_mapping_paste"', process_flow_code, fixed = TRUE))
  testthat::expect_false(grepl('actionButton("import_donor_flow"', process_flow_code, fixed = TRUE))
  testthat::expect_match(process_flow_code, 'actionButton("impute_flow"', fixed = TRUE)
})

testthat::test_that("Stage workspaces share the workflow visual system", {
  project_root <- normalizePath(testthat::test_path("..", ".."), winslash = "/", mustWork = TRUE)
  ui_code <- paste(readLines(file.path(project_root, "ui.R"), warn = FALSE), collapse = "\n")
  style_html <- render_workflow_html(workflow_style_tags())

  testthat::expect_length(
    gregexpr("workflow-stage-workspace", ui_code, fixed = TRUE)[[1]],
    8L
  )
  testthat::expect_match(
    style_html,
    ".workflow-stage-workspace { width:100%; max-width:1180px;",
    fixed = TRUE
  )
  testthat::expect_match(
    style_html,
    ".workflow-stage-workspace .nav-tabs .nav-link.active",
    fixed = TRUE
  )
  testthat::expect_match(
    style_html,
    ".workflow-stage-workspace .client-action-button.btn",
    fixed = TRUE
  )
  testthat::expect_match(
    style_html,
    "grid-template-areas:'sidebar' 'main'!important",
    fixed = TRUE
  )
  testthat::expect_match(
    ui_code,
    'class = "client-action-button workflow-secondary-action"',
    fixed = TRUE
  )
  testthat::expect_match(ui_code, 'uiOutput("analysis_record_selector")', fixed = TRUE)
  testthat::expect_false(grepl('textInput("analysis_record_id"', ui_code, fixed = TRUE))
  testthat::expect_match(
    style_html,
    ".analysis-record-selector .selectize-input { padding-right:34px!important; }",
    fixed = TRUE
  )
})

testthat::test_that("workflow shell separates Task goals from Stage steps", {
  selector_html <- render_workflow_html(workflow_shell_ui())
  workspace_html <- render_workflow_html(workflow_shell_ui("build_he_dataset", 3L))

  testthat::expect_length(
    gregexpr("workflow-task-card", selector_html, fixed = TRUE)[[1]],
    5L
  )
  testthat::expect_match(selector_html, "workflow-contextbar", fixed = TRUE)
  testthat::expect_false(grepl("workflow-stagebar-shell", selector_html, fixed = TRUE))
  testthat::expect_match(selector_html, "Choose a Task", fixed = TRUE)
  testthat::expect_match(
    selector_html,
    "Explore, combine and analyse hydrological and ecological data in one guided workflow.",
    fixed = TRUE
  )
  testthat::expect_match(workspace_html, "Steps to complete this Task", fixed = TRUE)
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
  testthat::expect_false(grepl("CSV validation", header_html, fixed = TRUE))
  testthat::expect_match(header_html, "Biology processing", fixed = TRUE)
  testthat::expect_match(header_html, "Flow processing", fixed = TRUE)
  testthat::expect_match(header_html, "WQ processing", fixed = TRUE)
  testthat::expect_match(
    header_html,
    'id="workflow_stage_view_flow"',
    fixed = TRUE
  )
  testthat::expect_match(
    header_html,
    'id="workflow_stage_view_wq"',
    fixed = TRUE
  )
  testthat::expect_false(grepl('id="workspace_name"', header_html, fixed = TRUE))
  testthat::expect_false(grepl('id="save_workspace"', header_html, fixed = TRUE))

  enabled_header_html <- render_workflow_html(
    workflow_header_ui(
      "build_he_dataset",
      2L,
      current_panel = "Process Flow",
      show_workspace_save = TRUE
    )
  )
  testthat::expect_match(enabled_header_html, 'id="workspace_name"', fixed = TRUE)
  testthat::expect_match(enabled_header_html, 'id="save_workspace"', fixed = TRUE)
  testthat::expect_match(enabled_header_html, "Save workspace copy", fixed = TRUE)
})

testthat::test_that("Stage 3 exposes the processed dataset checkpoint round trip", {
  ui_code <- paste(
    readLines(testthat::test_path("..", "..", "ui.R"), warn = FALSE),
    collapse = "\n"
  )

  testthat::expect_match(ui_code, '"processed_dataset_checkpoint_file"', fixed = TRUE)
  testthat::expect_match(ui_code, '"load_processed_dataset_checkpoint"', fixed = TRUE)
  testthat::expect_match(ui_code, '"processed_dataset_checkpoint_download"', fixed = TRUE)
})

testthat::test_that("Stage 2 WQ presentation uses only contracted controls and RHS stays table-only", {
  ui_code <- paste(
    readLines(testthat::test_path("..", "..", "ui.R"), warn = FALSE),
    collapse = "\n"
  )
  server_code <- paste(
    readLines(testthat::test_path("..", "..", "server.R"), warn = FALSE),
    collapse = "\n"
  )

  testthat::expect_match(ui_code, 'nav_panel(\n    "Process WQ"', fixed = TRUE)
  testthat::expect_match(ui_code, '"wq_stage2_display"', fixed = TRUE)
  testthat::expect_match(ui_code, 'choices = c("Time series", "Boxplot")', fixed = TRUE)
  testthat::expect_match(ui_code, 'min = "2000-01-01"', fixed = TRUE)
  testthat::expect_false(grepl("Mean bar chart", ui_code, fixed = TRUE))
  testthat::expect_false(grepl('output$wq_contract_summary_plot', server_code, fixed = TRUE))
  testthat::expect_false(grepl('output$rhs_mapped_plot', server_code, fixed = TRUE))
  testthat::expect_false(grepl('"rhs_plot_type"', ui_code, fixed = TRUE))
  testthat::expect_match(ui_code, 'full_screen = TRUE', fixed = TRUE)
})

testthat::test_that("Task 4 and Task 5 pages expose distinct user paths", {
  ui_code <- paste(
    readLines(testthat::test_path("..", "..", "ui.R"), warn = FALSE),
    collapse = "\n"
  )

  testthat::expect_match(ui_code, "Generate and interpret HEV plots", fixed = TRUE)
  testthat::expect_match(ui_code, "Interpretation checklist", fixed = TRUE)
  testthat::expect_match(ui_code, "1. Select variables and fit the model", fixed = TRUE)
  testthat::expect_match(
    ui_code,
    "eligible single-site or multi-site model",
    fixed = TRUE
  )
  testthat::expect_match(ui_code, "3. Review residual diagnostics", fixed = TRUE)
  testthat::expect_match(ui_code, "4. Export the current model", fixed = TRUE)
  testthat::expect_match(ui_code, 'uiOutput("basic_model_result_review")', fixed = TRUE)
  testthat::expect_match(ui_code, 'uiOutput("basic_model_diagnostic_review")', fixed = TRUE)
  testthat::expect_match(ui_code, 'uiOutput("basic_model_download_controls")', fixed = TRUE)
})

testthat::test_that("Task selector consumes completion artifact state", {
  registry <- new_he_artifact_registry()
  registry <- set_he_artifact_status(registry, "biology_input", "complete")
  registry <- set_he_artifact_status(registry, "environment_input", "complete")
  registry <- set_he_artifact_status(registry, "oe_result", "complete")
  registry <- set_he_artifact_status(registry, "processed_biology", "complete")
  html <- render_workflow_html(workflow_task_selector_ui(registry = registry))

  testthat::expect_length(gregexpr("Review Task", html, fixed = TRUE)[[1]], 1L)
  testthat::expect_length(gregexpr("Start Task", html, fixed = TRUE)[[1]], 4L)
  testthat::expect_match(html, 'data-completion-status="complete"', fixed = TRUE)
  testthat::expect_false(grepl("Processed biology", html, fixed = TRUE))
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

testthat::test_that("standalone validation Sandbox is retired without orphaning workflow uploads", {
  project_root <- normalizePath(testthat::test_path("..", ".."), winslash = "/", mustWork = TRUE)
  ui_code <- paste(readLines(file.path(project_root, "ui.R"), warn = FALSE), collapse = "\n")
  workflow_ui_code <- paste(
    readLines(file.path(project_root, "R", "workflow_ui.R"), warn = FALSE),
    collapse = "\n"
  )
  server_code <- paste(readLines(file.path(project_root, "server.R"), warn = FALSE), collapse = "\n")

  testthat::expect_false(grepl("File Validation Sandbox", ui_code, fixed = TRUE))
  testthat::expect_false(grepl("open_csv_validation", workflow_ui_code, fixed = TRUE))
  testthat::expect_false(grepl("dc11_workbook", paste(ui_code, server_code), fixed = TRUE))
  testthat::expect_false(grepl("dc11_csv", paste(ui_code, server_code), fixed = TRUE))

  testthat::expect_match(ui_code, "Legacy WQ workflow upload", fixed = TRUE)
  testthat::expect_match(ui_code, "Legacy RHS workflow upload", fixed = TRUE)
  testthat::expect_match(ui_code, 'fileInput("wq_csv"', fixed = TRUE)
  testthat::expect_match(ui_code, 'fileInput("rhs_csv"', fixed = TRUE)
  testthat::expect_match(ui_code, '`data-task-imports` = "wq"', fixed = TRUE)
  testthat::expect_match(ui_code, '`data-task-imports` = "rhs"', fixed = TRUE)
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

testthat::test_that("Task-disabled stages stay visible with accessible explanation", {
  html <- render_workflow_html(workflow_shell_ui("generate_hev", 4L))
  stage_five <- regmatches(
    html,
    regexpr('<button[^>]*id="workflow_stage_5"[^>]*>', html)
  )

  testthat::expect_match(stage_five, "disabled", fixed = TRUE)
  testthat::expect_match(stage_five, 'aria-disabled="true"', fixed = TRUE)
  testthat::expect_match(html, "Not required for this Task", fixed = TRUE)
})

testthat::test_that("Stage 1 import controls declare policy-derived import types", {
  project_root <- normalizePath(testthat::test_path("..", ".."), winslash = "/", mustWork = TRUE)
  ui_code <- paste(readLines(file.path(project_root, "ui.R"), warn = FALSE), collapse = "\n")
  script_html <- render_workflow_html(workflow_task_policy_script())

  for (import_type in he_workflow_import_types) {
    testthat::expect_match(
      ui_code,
      sprintf('`data-task-imports` = "%s"', import_type),
      fixed = TRUE
    )
  }
  testthat::expect_match(script_html, "workflow-task-policy", fixed = TRUE)
  testthat::expect_match(script_html, "data-task-import-panel", fixed = TRUE)
  testthat::expect_match(
    script_html,
    "typeof configured === 'string' ? [configured] : []",
    fixed = TRUE
  )
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

testthat::test_that("Task cards expose stable state without route detail", {
  html <- render_workflow_html(workflow_task_selector_ui())

  testthat::expect_match(html, 'data-task-id="build_he_dataset"', fixed = TRUE)
  testthat::expect_match(html, 'data-completion-status="not_started"', fixed = TRUE)
  testthat::expect_match(html, 'data-resume-stage="1"', fixed = TRUE)
  testthat::expect_false(grepl("workflow-stagebar-shell", html, fixed = TRUE))
  testthat::expect_false(grepl("Required stages", html, fixed = TRUE))
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
  testthat::expect_match(
    html,
    "Explore, combine and analyse hydrological and ecological data in one guided workflow.",
    fixed = TRUE
  )
  testthat::expect_false(grepl("analysis_dataset", html, fixed = TRUE))
  testthat::expect_false(grepl("NRFA fallback", html, fixed = TRUE))
})
