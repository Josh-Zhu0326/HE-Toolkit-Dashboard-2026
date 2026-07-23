# Keep these renderers presentation-only; put Task and state rules in config/state.
# Update UI tests whenever control IDs, Stage routes, or panel names change.

he_workflow_artifact_labels <- c(
  biology_input = "Biology data",
  environment_input = "Environmental data",
  flow_input = "Flow data",
  site_mapping = "Site mapping",
  wq_input = "Water-quality data",
  rhs_input = "River Habitat Survey data",
  processed_biology = "Processed biology",
  processed_environment = "Processed environmental data",
  processed_flow = "Processed flow",
  oe_result = "Expected values and O:E ratios",
  flow_statistics = "Flow statistics",
  joined_core = "Core Joined HE dataset",
  joined_enriched = "Enriched Joined HE dataset",
  processed_dataset_checkpoint = "Downloadable Joined HE dataset checkpoint",
  filter_selection = "Current record selection",
  exclusion_log = "Exclusion and restore log",
  analysis_dataset = "Current analysis selection",
  hev_result = "Current HEV plots",
  model_spec = "Current model specification",
  model_result = "Current model and diagnostics"
)

workflow_artifact_label <- function(artifact_id) {
  label <- unname(he_workflow_artifact_labels[artifact_id])
  if (length(label) != 1L || is.na(label)) {
    stop(sprintf("Missing user-facing label for workflow artifact: %s", artifact_id), call. = FALSE)
  }
  label
}

workflow_present_value <- function(value, fallback) {
  if (is.null(value) || length(value) == 0L || all(is.na(value))) {
    return(fallback)
  }
  text <- paste(as.character(value), collapse = ", ")
  if (!nzchar(trimws(text))) fallback else text
}

workflow_style_tags <- function() {
  shiny::tags$style(shiny::HTML("
    .workflow-shell { max-width:1180px; margin:1.25rem auto 2rem; padding:0 1rem; color:#17231d; }
    .workflow-shell-header { display:flex; justify-content:space-between; align-items:flex-start; gap:1rem; margin-bottom:1rem; }
    .workflow-eyebrow { color:#47705a; font-size:.76rem; font-weight:700; letter-spacing:.08em; text-transform:uppercase; margin:0 0 .25rem; }
    .workflow-shell h1 { font-size:clamp(1.75rem,3vw,2.55rem); line-height:1.1; margin:0 0 .6rem; }
    .workflow-lead { color:#40504a; max-width:760px; line-height:1.55; }
    .workflow-task-grid { display:grid; grid-template-columns:repeat(2,minmax(0,1fr)); gap:1rem; margin-top:1.25rem; }
    .workflow-task-card { display:flex; flex-direction:column; min-height:245px; padding:1.25rem; border:1px solid #d8e3dc; border-radius:12px; background:#fff; box-shadow:0 8px 24px rgba(20,45,32,.06); }
    .workflow-task-card h2 { font-size:1.18rem; margin:.2rem 0 .55rem; }
    .workflow-task-card p { color:#4a5a53; line-height:1.48; }
    .workflow-task-meta { margin:.45rem 0 .85rem; padding:.75rem; background:#f5f8f6; border-radius:8px; font-size:.8rem; }
    .workflow-task-meta-row { margin-bottom:.45rem; }
    .workflow-task-meta-row:last-child { margin-bottom:0; }
    .workflow-task-meta strong { display:block; color:#2f4d3d; }
    .workflow-task-output { margin-top:auto; padding:.75rem 0; border-top:1px solid #e7ede9; font-size:.88rem; }
    .workflow-task-card .btn { width:100%; background:#008938; border-color:#008938; color:#fff; }
    .workflow-context { background:#173f2a; color:#fff; border-radius:12px; padding:1rem 1.15rem; }
    .workflow-context strong { display:block; font-size:1.05rem; }
    .workflow-context .btn { margin-top:.65rem; color:#173f2a; background:#fff; border-color:#fff; }
    .workflow-stagebar { display:grid; grid-template-columns:repeat(5,minmax(0,1fr)); gap:.45rem; margin:1rem 0; }
    .workflow-stagebar .btn { min-height:82px; text-align:left; white-space:normal; border:1px solid #d8e3dc; background:#fff; color:#314139; }
    .workflow-stagebar .btn.is-current { border:2px solid #008938; background:#eef8f2; }
    .workflow-stagebar .btn.is-optional { border-style:dashed; }
    .workflow-stagebar .btn:disabled { opacity:.48; }
    .workflow-stage-number { display:block; font-size:.7rem; font-weight:700; text-transform:uppercase; color:#5e7468; }
    .workflow-stage-name { display:block; margin:.18rem 0; font-size:.82rem; font-weight:650; }
    .workflow-stage-mark { display:block; font-size:.7rem; color:#47705a; }
    .workflow-workspace-head { display:flex; justify-content:space-between; gap:1.25rem; align-items:flex-start; margin:1.25rem 0 1rem; }
    .workflow-path-summary { min-width:220px; padding:.85rem 1rem; background:#f1f6f3; border-radius:10px; font-size:.84rem; }
    .workflow-recommendation { display:flex; align-items:center; justify-content:space-between; gap:1rem; padding:1rem 1.1rem; background:#eaf6ef; border-left:4px solid #008938; border-radius:8px; }
    .workflow-recommendation .btn { background:#008938; border-color:#008938; color:#fff; }
    .workflow-grid { display:grid; grid-template-columns:minmax(0,1.45fr) minmax(280px,.75fr); gap:1rem; margin-top:1rem; }
    .workflow-panel { border:1px solid #d8e3dc; border-radius:10px; background:#fff; padding:1rem; }
    .workflow-step-list { list-style:none; padding:0; margin:0; }
    .workflow-step { display:flex; justify-content:space-between; gap:1rem; padding:.72rem 0; border-bottom:1px solid #edf1ee; }
    .workflow-step:last-child { border-bottom:0; }
    .workflow-state { flex-shrink:0; padding:.18rem .5rem; border-radius:999px; background:#eef1ef; font-size:.72rem; font-weight:700; }
    .workflow-state.complete { background:#ddf2e6; color:#116333; }
    .workflow-state.warning { background:#fff0d6; color:#855600; }
    .workflow-state.stale,.workflow-state.failed { background:#fde4e4; color:#9b2929; }
    .workflow-state.ready { background:#e3edf8; color:#245b88; }
    .workflow-checkpoint-artifact { margin-top:.8rem; padding:.75rem; border:1px solid #e1e9e4; border-radius:8px; }
    .workflow-checkpoint-artifact > strong { display:block; margin-bottom:.25rem; }
    .workflow-checkpoint-row { padding:.45rem 0; border-bottom:1px solid #edf1ee; }
    .workflow-checkpoint-row:last-child { border-bottom:0; }
    .workflow-scope-note { display:flex; gap:.7rem; margin-top:1rem; padding:1rem; border-left:4px solid #4f7d63; border-radius:8px; background:#f1f6f3; }
    .workflow-scope-note strong { display:block; margin-bottom:.2rem; }
    .workflow-scope-note p { margin:0; color:#40504a; }
    .workflow-guide { max-width:1180px; margin:0 auto 2rem; padding:0 1rem; }
    .workflow-guide details { border:1px solid #d8e3dc; border-radius:10px; background:#fff; padding:1rem; }
    .workflow-guide summary { cursor:pointer; font-weight:700; }
    @media (max-width:850px) {
      .workflow-task-grid,.workflow-grid { grid-template-columns:1fr; }
      .workflow-stagebar { grid-template-columns:1fr; }
      .workflow-workspace-head,.workflow-shell-header,.workflow-recommendation { flex-direction:column; }
      .workflow-path-summary { min-width:0; width:100%; }
    }
  "))
}

workflow_task_selector_ui <- function(
    tasks = he_workflow_tasks,
    registry = new_he_artifact_registry()) {
  shiny::div(
    class = "workflow-shell",
    shiny::div(
      class = "workflow-shell-header",
      shiny::div(
        shiny::p(class = "workflow-eyebrow", "Choose a Task"),
        shiny::h1("What do you want to achieve?"),
        shiny::p(
          class = "workflow-lead",
          "Choose one Task to see its route through the shared five-stage workflow. Completed outputs can be downloaded and used again in a later session."
        )
      )
    ),
    shiny::div(
      class = "workflow-task-grid",
      lapply(seq_along(tasks), function(index) {
        task <- tasks[[index]]
        task_is_complete <- workflow_task_is_complete(task, registry)
        resume_stage <- workflow_resume_stage(task, registry)
        required_stage_numbers <- which(task$stage_path == "R")
        required_stage_labels <- vapply(
          he_workflow_stages[required_stage_numbers],
          `[[`,
          character(1),
          "stage_label"
        )
        reusable_ids <- task$reusable_artifacts[vapply(
          registry[task$reusable_artifacts],
          artifact_is_current,
          logical(1)
        )]
        reusable_labels <- if (length(reusable_ids) == 0L) {
          "None available yet"
        } else {
          paste(vapply(reusable_ids, workflow_artifact_label, character(1)), collapse = ", ")
        }
        next_step <- if (task_is_complete) {
          sprintf(
            "Review Stage %d — %s",
            resume_stage,
            he_workflow_stages[[resume_stage]]$stage_label
          )
        } else {
          sprintf(
            "Stage %d — %s",
            resume_stage,
            he_workflow_stages[[resume_stage]]$stage_label
          )
        }
        shiny::div(
          class = "workflow-task-card",
          `data-task-id` = task$task_id,
          `data-completion-status` = registry[[task$completion_artifact]]$status,
          `data-resume-stage` = resume_stage,
          shiny::span(class = "workflow-eyebrow", sprintf("Task %02d", index)),
          shiny::h2(task$task_label),
          shiny::p(task$description),
          shiny::div(
            class = "workflow-task-meta",
            shiny::div(
              class = "workflow-task-meta-row",
              shiny::strong("Required stages"),
              paste(required_stage_labels, collapse = " → ")
            ),
            shiny::div(
              class = "workflow-task-meta-row",
              shiny::strong("Reusable outputs"),
              reusable_labels
            ),
            shiny::div(
              class = "workflow-task-meta-row",
              shiny::strong("Next step"),
              next_step
            )
          ),
          shiny::div(
            class = "workflow-task-output",
            shiny::strong("Primary output: "),
            task$primary_output
          ),
          shiny::actionButton(
            paste0("select_task__", task$task_id),
            if (task_is_complete) "Review completed Task" else "Start or resume Task",
            class = "workflow-select-task"
          )
        )
      })
    )
  )
}

workflow_stage_nav_ui <- function(task, current_stage) {
  shiny::div(
    class = "workflow-stagebar",
    role = "navigation",
    `aria-label` = "Five-stage workflow",
    lapply(seq_along(he_workflow_stages), function(index) {
      stage <- he_workflow_stages[[index]]
      mark <- task$stage_path[[index]]
      mark_text <- switch(mark, R = "Required", O = "Optional", `-` = "Not used")
      class_name <- paste(
        if (identical(index, current_stage)) "is-current" else "",
        if (identical(mark, "O")) "is-optional" else ""
      )
      button <- shiny::actionButton(
        paste0("workflow_stage_", index),
        shiny::tagList(
          shiny::span(class = "workflow-stage-number", sprintf("Stage %d", index)),
          shiny::span(class = "workflow-stage-name", stage$stage_label),
          shiny::span(class = "workflow-stage-mark", mark_text)
        ),
        class = class_name
      )
      if (identical(mark, "-")) {
        button <- htmltools::tagAppendAttributes(button, disabled = "disabled")
      }
      button
    })
  )
}

workflow_required_steps_ui <- function(task, stage_index, registry) {
  artifact_ids <- workflow_required_stage_artifact_ids(task, stage_index)

  if (length(artifact_ids) == 0L) {
    return(shiny::p(
      class = "workflow-lead",
      "This stage has no separate required output for the selected Task. Review it only if you need the optional capability."
    ))
  }

  shiny::tags$ul(
    class = "workflow-step-list",
    lapply(artifact_ids, function(artifact_id) {
      artifact <- registry[[artifact_id]]
      shiny::tags$li(
        class = "workflow-step",
        shiny::div(
          shiny::strong(workflow_artifact_label(artifact_id)),
          if (!is.null(artifact$next_action)) shiny::div(class = "hint-text", artifact$next_action)
        ),
        shiny::span(class = paste("workflow-state", artifact$status), artifact$status)
      )
    })
  )
}

workflow_stage_status <- function(task, stage_index, registry) {
  artifact_ids <- workflow_required_stage_artifact_ids(task, stage_index)
  if (length(artifact_ids) == 0L) {
    return("not_started")
  }
  statuses <- vapply(registry[artifact_ids], `[[`, character(1), "status")
  # Keep worst-first priority aligned with state labels and workflow-state CSS.
  priority <- c("failed", "stale", "blocked", "running", "not_started", "ready", "warning", "complete")
  priority[priority %in% statuses][[1]]
}

workflow_checkpoint_row <- function(label, value, class = NULL) {
  shiny::div(
    class = paste("workflow-checkpoint-row", class),
    shiny::strong(label),
    shiny::div(value)
  )
}

workflow_checkpoint_ui <- function(task, stage_index, registry) {
  artifact_ids <- workflow_required_stage_artifact_ids(task, stage_index)
  stage_status <- workflow_stage_status(task, stage_index, registry)

  shiny::tagList(
    workflow_checkpoint_row("Stage status", stage_status),
    if (length(artifact_ids) == 0L) {
      shiny::p(
        class = "workflow-lead",
        "No separate required artifact is recorded for this Stage."
      )
    } else {
      lapply(artifact_ids, function(artifact_id) {
        artifact <- registry[[artifact_id]]
        shiny::div(
          class = "workflow-checkpoint-artifact",
          `data-checkpoint-node` = artifact_id,
          `data-checkpoint-status` = artifact$status,
          shiny::strong(workflow_artifact_label(artifact_id)),
          workflow_checkpoint_row("Status", artifact$status),
          workflow_checkpoint_row(
            "Data source",
            workflow_present_value(artifact$data_source, "Not available yet")
          ),
          workflow_checkpoint_row(
            "Data history",
            workflow_present_value(artifact$history_summary, "Not available yet")
          ),
          workflow_checkpoint_row(
            "Blocking reason",
            workflow_present_value(artifact$blocking_reason, "None")
          ),
          workflow_checkpoint_row(
            "Next action",
            workflow_present_value(artifact$next_action, "No action recorded yet")
          )
        )
      })
    }
  )
}

workflow_core_scope_ui <- function(task, selected_enrichments = character()) {
  core_task_ids <- c("build_he_dataset", "generate_hev", "he_modelling")
  if (!task$task_id %in% core_task_ids) {
    return(NULL)
  }

  allowed_enrichments <- c("wq", "rhs")
  selected_enrichments <- unique(as.character(selected_enrichments))
  if (anyNA(selected_enrichments) ||
      length(setdiff(selected_enrichments, allowed_enrichments)) > 0L) {
    stop("Selected enrichments must contain only 'wq' or 'rhs'.", call. = FALSE)
  }
  if (length(selected_enrichments) > 0L) {
    return(NULL)
  }

  shiny::div(
    class = "workflow-scope-note",
    role = "note",
    `data-workflow-scope` = "core-only",
    shiny::span(`aria-hidden` = "true", "ⓘ"),
    shiny::div(
      shiny::strong("Core-only scope"),
      shiny::p(
        "Water-quality and River Habitat Survey enrichment have not been selected. ",
        "This is information, not a warning, and it does not block the Core Joined HE dataset."
      )
    )
  )
}

workflow_status_announcement_text <- function(task, stage_index, registry) {
  stage <- he_workflow_stages[[stage_index]]
  stage_status <- gsub("_", " ", workflow_stage_status(task, stage_index, registry), fixed = TRUE)
  artifact_ids <- workflow_required_stage_artifact_ids(task, stage_index)
  next_actions <- unique(Filter(
    nzchar,
    vapply(
      registry[artifact_ids],
      function(artifact) workflow_present_value(artifact$next_action, ""),
      character(1)
    )
  ))
  next_text <- if (length(next_actions) == 0L) {
    ""
  } else {
    sprintf(" Next action: %s", paste(next_actions, collapse = " "))
  }

  sprintf(
    "Current Task: %s. Current stage: %s. Stage status: %s.%s",
    task$task_label,
    stage$stage_label,
    stage_status,
    next_text
  )
}

workflow_nav_target <- function(task_id, stage_index) {
  # Update exact navigation tests when a dashboard panel title or route changes.
  if (stage_index == 1L) return("Data Import")
  if (stage_index == 2L) {
    if (identical(task_id, "flow_regime")) return("Process Flow")
    return("Process Biology")
  }
  if (stage_index == 3L) return("Analysis")
  if (stage_index == 4L && identical(task_id, "generate_hev")) return("HEV Plots")
  if (stage_index == 4L) return("Analysis")
  if (stage_index == 5L && identical(task_id, "generate_hev")) return("HEV Plots")
  "Analysis"
}

workflow_primary_action_label <- function(task_id, stage_index) {
  paste("Open", workflow_nav_target(task_id, stage_index))
}

workflow_workspace_ui <- function(
    task_id,
    current_stage,
    registry,
    selected_enrichments = character()) {
  task <- get_he_workflow_task(task_id)
  task_is_complete <- workflow_task_is_complete(task, registry)
  stage <- he_workflow_stages[[current_stage]]
  required_stage_numbers <- which(task$stage_path == "R")
  optional_stage_numbers <- which(task$stage_path == "O")

  shiny::div(
    class = "workflow-shell",
    shiny::div(
      class = "workflow-shell-header",
      shiny::div(
        shiny::p(class = "workflow-eyebrow", "Current Task"),
        shiny::h1(task$task_label),
        shiny::p(class = "workflow-lead", task$description)
      ),
      shiny::div(
        class = "workflow-context",
        shiny::span("Primary output"),
        shiny::strong(task$primary_output),
        shiny::span(if (task_is_complete) "Task complete" else "Task in progress"),
        shiny::actionButton("change_task", "Change Task")
      )
    ),
    workflow_stage_nav_ui(task, current_stage),
    shiny::div(
      class = "workflow-workspace-head",
      shiny::div(
        shiny::p(class = "workflow-eyebrow", sprintf("Current stage · %d of 5", current_stage)),
        shiny::h2(stage$stage_label),
        shiny::p(class = "workflow-lead", stage$description)
      ),
      shiny::div(
        class = "workflow-path-summary",
        shiny::strong("Task path"),
        shiny::div(sprintf("Required: %s", paste(required_stage_numbers, collapse = " → "))),
        if (length(optional_stage_numbers) > 0L) {
          shiny::div(sprintf("Optional: %s", paste(optional_stage_numbers, collapse = ", ")))
        }
      )
    ),
    shiny::div(
      class = "workflow-recommendation",
      shiny::div(
        shiny::strong("Next recommended action"),
        shiny::div(sprintf("Continue in %s when the required inputs are ready.", stage$stage_label))
      ),
      shiny::actionButton(
        "workflow_primary_action",
        workflow_primary_action_label(task_id, current_stage)
      )
    ),
    shiny::div(
      class = "workflow-grid",
      shiny::tags$section(
        class = "workflow-panel",
        shiny::h3("Required steps for this Task"),
        workflow_required_steps_ui(task, current_stage, registry)
      ),
      shiny::tags$aside(
        class = "workflow-panel",
        shiny::h3("Checkpoint"),
        workflow_checkpoint_ui(task, current_stage, registry)
      )
    ),
    workflow_core_scope_ui(task, selected_enrichments),
    shiny::span(
      class = "visually-hidden",
      `aria-live` = "polite",
      `aria-atomic` = "true",
      shiny::textOutput("workflow_status_announcement", container = shiny::span)
    )
  )
}

workflow_shell_ui <- function(
    task_id = NULL,
    current_stage = 1L,
    registry = new_he_artifact_registry(),
    selected_enrichments = character()) {
  # Keep this selector as the only entry point when no Task is active.
  if (is.null(task_id)) {
    return(workflow_task_selector_ui(registry = registry))
  }
  workflow_workspace_ui(
    task_id,
    current_stage,
    registry,
    selected_enrichments
  )
}
