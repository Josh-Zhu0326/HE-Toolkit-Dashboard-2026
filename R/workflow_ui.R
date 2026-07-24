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

workflow_status_label <- function(status) {
  labels <- c(
    not_started = "Not started",
    blocked = "Blocked",
    ready = "Ready",
    running = "Running",
    complete = "Complete",
    warning = "Warning",
    stale = "Stale",
    failed = "Failed"
  )
  label <- unname(labels[status])
  if (length(label) != 1L || is.na(label)) {
    stop(sprintf("Missing user-facing workflow status: %s", status), call. = FALSE)
  }
  label
}

workflow_style_tags <- function() {
  shiny::tags$style(shiny::HTML("
    body.bslib-page-navbar {
      --wf-ink:#1f2a24;
      --wf-muted:#637069;
      --wf-line:#d9e0dc;
      --wf-surface:#ffffff;
      --wf-canvas:#f4f6f4;
      --wf-green:#245f3b;
      --wf-green-dark:#19462b;
      --wf-green-soft:#e8f2eb;
      --wf-blue:#255f8f;
      --wf-blue-soft:#eaf2f8;
      --wf-amber:#8a5700;
      --wf-amber-soft:#fff4d9;
      --wf-red:#9d2f2f;
      --wf-red-soft:#faeaea;
      --wf-purple:#6a4aa1;
      --wf-purple-soft:#f0ebf8;
      --wf-grey-soft:#edf0ee;
      color:var(--wf-ink);
      background:var(--wf-canvas);
    }
    body.bslib-page-navbar > nav.navbar { display:none!important; }
    body.bslib-page-navbar > .container-fluid { padding-right:0; padding-left:0; }
    body.bslib-page-navbar > .container-fluid > .tab-content { background:var(--wf-canvas); }
    .workflow-home-page {
      min-height:calc(100vh - 58px);
      color:var(--wf-ink);
      background:var(--wf-canvas);
      font-size:14px;
      line-height:1.5;
    }
    .workflow-surface { color:var(--wf-ink); background:var(--wf-canvas); }
    .workflow-shell { max-width:1180px; margin:0 auto; padding:28px clamp(16px,4vw,44px) 48px; }
    .workflow-shell h1,.workflow-shell h2,.workflow-shell h3,.workflow-shell p { margin-top:0; }
    .workflow-shell h1 { margin-bottom:8px; font-size:2.125rem; line-height:1.2; letter-spacing:-.02em; text-wrap:balance; }
    .workflow-shell h2 { font-size:1.25rem; line-height:1.3; text-wrap:balance; }
    .workflow-shell h3 { font-size:.94rem; }
    .workflow-eyebrow { margin:0 0 5px; color:var(--wf-green); font-size:.75rem; font-weight:700; letter-spacing:.08em; text-transform:uppercase; }
    .workflow-lead { max-width:760px; color:var(--wf-muted); font-size:1rem; line-height:1.55; text-wrap:pretty; }

    .workflow-contextbar { color:#fff; background:var(--wf-green); }
    .workflow-contextbar-inner { max-width:1180px; min-height:58px; margin:0 auto; padding:8px clamp(16px,4vw,44px); display:grid; grid-template-columns:auto minmax(280px,1fr) auto; align-items:center; gap:24px; }
    .workflow-brand { display:flex; align-items:center; gap:10px; color:#fff; white-space:nowrap; }
    .workflow-brand strong { font-size:1rem; }
    .workflow-context-copy,.workflow-context-meta { display:flex; flex-direction:column; }
    .workflow-context-copy span,.workflow-context-meta span { color:rgba(255,255,255,.75); font-size:.75rem; }
    .workflow-context-copy strong { max-width:720px; color:#fff; font-size:.84rem; }
    .workflow-context-actions { display:flex; align-items:center; gap:12px; }
    .workflow-context-meta { text-align:right; }
    .workflow-context-meta strong { max-width:320px; color:#fff; font-size:.8rem; }
    .workflow-agency-logo { width:auto; height:34px; margin-left:2px; }
    .workflow-top-button.btn { min-height:40px; padding:7px 11px; border:1px solid rgba(255,255,255,.55); border-radius:6px; color:#fff; background:transparent; box-shadow:none; }
    .workflow-top-button.btn:hover,.workflow-top-button.btn:focus { color:#fff; border-color:#fff; background:rgba(255,255,255,.12); }
    .workflow-utilities { position:relative; }
    .workflow-utilities summary { min-height:40px; padding:7px 11px; display:flex; align-items:center; border:1px solid rgba(255,255,255,.55); border-radius:6px; color:#fff; cursor:pointer; list-style:none; }
    .workflow-utilities summary::-webkit-details-marker { display:none; }
    .workflow-utilities[open] summary,.workflow-utilities summary:hover { border-color:#fff; background:rgba(255,255,255,.12); }
    .workflow-utility-menu { position:absolute; z-index:20; top:calc(100% + 7px); right:0; min-width:210px; padding:6px; border:1px solid var(--wf-line); border-radius:8px; color:var(--wf-ink); background:#fff; box-shadow:0 3px 8px rgba(25,42,32,.12); }
    .workflow-utility-menu a { padding:8px 10px; display:block; border-radius:5px; color:var(--wf-ink); text-decoration:none; }
    .workflow-utility-menu a:hover,.workflow-utility-menu a:focus { color:var(--wf-green-dark); background:var(--wf-green-soft); }

    .workflow-stagebar-shell { overflow-x:auto; border-bottom:1px solid var(--wf-line); background:var(--wf-surface); }
    .workflow-stagebar { max-width:1180px; min-width:750px; margin:0 auto; padding:0 clamp(16px,4vw,44px); display:grid; grid-template-columns:repeat(5,minmax(142px,1fr)); }
    .workflow-stagebar .btn { min-height:70px; margin:0; padding:10px 12px; border:0; border-right:1px solid var(--wf-line); border-bottom:4px solid transparent; border-radius:0; color:var(--wf-muted); background:transparent; box-shadow:none; text-align:left; white-space:normal; }
    .workflow-stagebar .btn:first-child { border-left:1px solid var(--wf-line); }
    .workflow-stagebar .btn:hover:not(:disabled) { color:var(--wf-green-dark); background:#f8faf8; }
    .workflow-stagebar .btn.is-current { color:var(--wf-green-dark); border-bottom-color:var(--wf-green); background:var(--wf-green-soft); }
    .workflow-stagebar .btn.is-required .workflow-stage-name { color:var(--wf-ink); }
    .workflow-stagebar .btn:disabled { cursor:not-allowed; opacity:.55; }
    .workflow-stage-number { display:block; font-size:.69rem; font-weight:700; letter-spacing:.06em; text-transform:uppercase; }
    .workflow-stage-name { display:block; margin-top:3px; font-size:.81rem; font-weight:650; line-height:1.25; }
    .workflow-stage-mark { display:block; margin-top:5px; color:#8a948e; font-size:.69rem; font-weight:700; }
    .workflow-stagebar .is-required .workflow-stage-mark { color:var(--wf-green); }
    .workflow-stagebar .is-optional .workflow-stage-mark { color:var(--wf-blue); }
    .workflow-stage-subnav { padding:8px clamp(16px,4vw,44px); display:flex; justify-content:center; gap:8px; border-bottom:1px solid var(--wf-line); background:#f8faf8; }
    .workflow-stage-subnav .btn { min-height:34px; padding:5px 12px; border:1px solid var(--wf-line); border-radius:6px; color:var(--wf-green-dark); background:#fff; box-shadow:none; }
    .workflow-stage-subnav .btn.is-current { border-color:var(--wf-green); background:var(--wf-green-soft); font-weight:700; }

    .workflow-task-grid { margin-top:24px; display:grid; grid-template-columns:repeat(5,minmax(0,1fr)); gap:14px; align-items:stretch; }
    .workflow-task-card { min-height:338px; padding:20px; display:flex!important; flex-direction:column; align-items:stretch; border:1px solid var(--wf-line); border-radius:10px; color:var(--wf-ink)!important; background:var(--wf-surface); box-shadow:0 1px 3px rgba(25,42,32,.08); text-align:left; text-decoration:none!important; transition:border-color .18s ease-out,transform .18s ease-out,background-color .18s ease-out; }
    .workflow-task-card:hover { border-color:var(--wf-green); color:var(--wf-ink)!important; background:#fff; transform:translateY(-1px); }
    .workflow-task-card:focus-visible { outline:3px solid var(--wf-surface); outline-offset:2px; box-shadow:0 0 0 5px var(--wf-blue); }
    .workflow-task-card h2 { min-height:6.4rem; margin:10px 0 7px; font-size:1rem; line-height:1.25; }
    .workflow-task-card p { margin:0 0 14px; color:var(--wf-muted); font-size:.84rem; line-height:1.45; }
    .workflow-task-meta { margin-top:auto; padding:11px 0; border-top:1px solid var(--wf-line); color:var(--wf-muted); font-size:.71rem; line-height:1.4; }
    .workflow-task-meta-row { margin-bottom:8px; }
    .workflow-task-meta-row:last-child { margin-bottom:0; }
    .workflow-task-meta strong { display:block; color:var(--wf-green-dark); font-size:.7rem; }
    .workflow-task-output { padding-top:11px; border-top:1px solid var(--wf-line); font-size:.72rem; }
    .workflow-task-output strong { color:var(--wf-green-dark); }
    .workflow-action-label { position:absolute; width:1px; height:1px; padding:0; margin:-1px; overflow:hidden; clip:rect(0,0,0,0); white-space:nowrap; border:0; }

    .workflow-grid { display:grid; grid-template-columns:minmax(0,1.55fr) minmax(300px,.85fr); gap:18px; align-items:start; }
    .workflow-panel { overflow:hidden; border:1px solid var(--wf-line); border-radius:10px; background:var(--wf-surface); box-shadow:0 1px 3px rgba(25,42,32,.08); }
    .workflow-panel-head { padding:17px 18px 13px; border-bottom:1px solid var(--wf-line); }
    .workflow-panel-head h2 { margin-bottom:3px; }
    .workflow-panel-head p { margin:0; color:var(--wf-muted); font-size:.81rem; }
    .workflow-panel-empty { margin:0; padding:17px 18px; color:var(--wf-muted); }
    .workflow-step-list { margin:0; padding:0; list-style:none; }
    .workflow-step { padding:17px 18px; display:grid; grid-template-columns:minmax(0,1fr) auto; gap:14px; align-items:start; border-bottom:1px solid var(--wf-line); }
    .workflow-step:last-child { border-bottom:0; }
    .workflow-step .hint-text { margin:5px 0 0; color:var(--wf-muted); font-size:.75rem; line-height:1.4; }
    .workflow-state { flex-shrink:0; display:inline-flex; align-items:center; gap:6px; padding:4px 9px; border-radius:999px; color:#626b66; background:var(--wf-grey-soft); font-size:.69rem; font-weight:750; white-space:nowrap; }
    .workflow-state::before { width:7px; height:7px; border-radius:50%; background:currentColor; content:''; }
    .workflow-state.complete { color:var(--wf-green); background:var(--wf-green-soft); }
    .workflow-state.warning { color:var(--wf-amber); background:var(--wf-amber-soft); }
    .workflow-state.blocked,.workflow-state.failed { color:var(--wf-red); background:var(--wf-red-soft); }
    .workflow-state.stale { color:var(--wf-purple); background:var(--wf-purple-soft); }
    .workflow-state.running { color:var(--wf-blue); background:var(--wf-blue-soft); }
    .workflow-state.ready { color:var(--wf-green-dark); background:#edf5ef; }

    .workflow-checkpoint-body { padding:18px; }
    .workflow-checkpoint-body dl { margin:0; }
    .workflow-checkpoint-artifact { padding:16px 0 0; border-top:1px solid var(--wf-line); }
    .workflow-checkpoint-artifact + .workflow-checkpoint-artifact { margin-top:16px; }
    .workflow-checkpoint-artifact > h3 { margin:0 0 10px; color:var(--wf-ink); }
    .workflow-checkpoint-row { padding:10px 0; border-top:1px solid var(--wf-line); }
    .workflow-checkpoint-row:first-child { padding-top:0; border-top:0; }
    .workflow-checkpoint-row dt { margin-bottom:4px; color:var(--wf-muted); font:700 .69rem/1.4 ui-monospace,SFMono-Regular,Menlo,monospace; }
    .workflow-checkpoint-row dd { margin:0; color:var(--wf-ink); }
    .workflow-checkpoint-empty { margin:0; color:var(--wf-muted); }

    .workflow-scope-note { margin-top:16px; padding:13px 15px; display:flex; gap:10px; border:1px solid #bdd2e2; border-radius:8px; background:var(--wf-blue-soft); }
    .workflow-scope-note strong { display:block; color:var(--wf-blue); }
    .workflow-scope-note p { margin:2px 0 0; color:#36576e; }
    .workflow-guide { max-width:1180px; margin:0 auto; padding:0 clamp(16px,4vw,44px) 48px; }
    .workflow-guide details { margin:0; border:1px solid var(--wf-line); border-radius:8px; background:var(--wf-surface); }
    .workflow-guide summary { padding:14px 16px; cursor:pointer; font-weight:700; }
    .workflow-guide details > :not(summary) { margin-right:16px; margin-left:16px; }
    .workflow-stage-overview { border-bottom:1px solid var(--wf-line); background:var(--wf-canvas); }
    .workflow-stage-overview-inner { max-width:1180px; margin:0 auto; padding:10px clamp(16px,4vw,44px); }
    .workflow-stage-overview details { border:1px solid var(--wf-line); border-radius:8px; background:#fff; }
    .workflow-stage-overview summary { padding:10px 13px; display:flex; align-items:center; justify-content:space-between; gap:16px; cursor:pointer; }
    .workflow-stage-overview-title { display:flex; align-items:baseline; gap:10px; }
    .workflow-stage-overview-title strong { color:var(--wf-ink); }
    .workflow-stage-overview-title span { color:var(--wf-muted); font-size:.78rem; }
    .workflow-stage-overview-body { padding:0 13px 13px; }
    .workflow-stage-overview .workflow-grid { margin-top:2px; }
    .workflow-stage-overview .workflow-panel { box-shadow:none; }

    @media (pointer:coarse) {
      .workflow-top-button.btn { min-height:44px; }
    }
    @media (prefers-reduced-motion:reduce) {
      .workflow-task-card { transition-duration:.01ms!important; transform:none!important; }
    }
  "))
}

workflow_context_bar_ui <- function(task = NULL, task_is_complete = FALSE) {
  shiny::div(
    class = "workflow-contextbar",
    shiny::div(
      class = "workflow-contextbar-inner",
      shiny::div(
        class = "workflow-brand",
        shiny::strong("HE Toolkit Dashboard")
      ),
      shiny::div(
        class = "workflow-context-copy",
        shiny::span("Current Task"),
        shiny::strong(if (is.null(task)) "Not selected" else task$task_label)
      ),
      shiny::div(
        class = "workflow-context-actions",
        if (!is.null(task)) {
          shiny::div(
            class = "workflow-context-meta",
            shiny::span(if (task_is_complete) "Task complete" else "Primary output"),
            shiny::strong(task$primary_output)
          )
        },
        if (!is.null(task)) {
          shiny::actionButton(
            "change_task",
            "Change Task",
            class = "workflow-top-button"
          )
        },
        shiny::tags$details(
          class = "workflow-utilities",
          shiny::tags$summary("Utilities"),
          shiny::div(
            class = "workflow-utility-menu",
            shiny::actionLink("open_task_selector", "Task selector"),
            shiny::actionLink("open_csv_validation", "CSV validation"),
            shiny::tags$a(
              "HE Toolkit GitHub",
              href = "https://github.com/APEM-LTD/hetoolkit",
              target = "_blank",
              rel = "noopener noreferrer"
            ),
            shiny::tags$a(
              "HE Toolkit website",
              href = "https://apem-ltd.github.io/hetoolkit/index.html",
              target = "_blank",
              rel = "noopener noreferrer"
            )
          )
        ),
        shiny::tags$img(
          class = "workflow-agency-logo",
          src = "EA_logo_white.png",
          alt = "Environment Agency"
        )
      )
    )
  )
}

workflow_stage_subnav_ui <- function(task = NULL, current_stage = NULL, current_panel = NULL) {
  if (is.null(task) ||
      !identical(current_stage, 2L) ||
      !task$task_id %in% c("build_he_dataset", "generate_hev", "he_modelling")) {
    return(NULL)
  }

  shiny::div(
    class = "workflow-stage-subnav",
    `aria-label` = "Stage 2 work areas",
    shiny::actionButton(
      "workflow_stage_view_biology",
      "Biology processing",
      class = if (identical(current_panel, "Process Biology")) "is-current" else ""
    ),
    shiny::actionButton(
      "workflow_stage_view_flow",
      "Flow processing",
      class = if (identical(current_panel, "Process Flow")) "is-current" else ""
    )
  )
}

workflow_header_ui <- function(
    task_id = NULL,
    current_stage = 1L,
    registry = new_he_artifact_registry(),
    current_panel = NULL) {
  task <- if (is.null(task_id)) NULL else get_he_workflow_task(task_id)
  shiny::div(
    class = "workflow-app-header",
    workflow_context_bar_ui(
      task,
      if (is.null(task)) FALSE else workflow_task_is_complete(task, registry)
    ),
    workflow_stage_nav_ui(task, if (is.null(task)) NULL else current_stage),
    workflow_stage_subnav_ui(task, current_stage, current_panel)
  )
}

workflow_task_selector_ui <- function(
    tasks = he_workflow_tasks,
    registry = new_he_artifact_registry()) {
  shiny::div(
    class = "workflow-surface",
    shiny::div(
      class = "workflow-shell",
      shiny::p(class = "workflow-eyebrow", "Choose an outcome"),
      shiny::h1("What do you want to achieve?"),
      shiny::p(
        class = "workflow-lead",
        "Choose one Task to see its route through the shared five-stage workflow. Completed outputs can be downloaded and used again in a later session."
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
          shiny::actionLink(
            paste0("select_task__", task$task_id),
            shiny::tagList(
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
              shiny::span(
                class = "workflow-action-label",
                if (task_is_complete) "Review completed Task" else "Start or resume Task"
              )
            ),
            class = "workflow-task-card",
            `data-task-id` = task$task_id,
            `data-completion-status` = registry[[task$completion_artifact]]$status,
            `data-resume-stage` = resume_stage
          )
        })
      )
    )
  )
}

workflow_stage_nav_ui <- function(task = NULL, current_stage = NULL) {
  shiny::div(
    class = "workflow-stagebar-shell",
    shiny::div(
      class = "workflow-stagebar",
      role = "navigation",
      `aria-label` = "Five-stage workflow",
      lapply(seq_along(he_workflow_stages), function(index) {
        stage <- he_workflow_stages[[index]]
        mark <- if (is.null(task)) "-" else task$stage_path[[index]]
        mark_text <- if (is.null(task)) {
          "Select a Task"
        } else {
          switch(mark, R = "Required", O = "Optional", `-` = "Not used")
        }
        class_name <- paste(
          if (identical(index, current_stage)) "is-current" else "",
          if (identical(mark, "R")) "is-required" else "",
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
        if (is.null(task) || identical(mark, "-")) {
          button <- htmltools::tagAppendAttributes(button, disabled = "disabled")
        }
        if (identical(index, current_stage)) {
          button <- htmltools::tagAppendAttributes(button, `aria-current` = "step")
        }
        button
      })
    )
  )
}

workflow_required_steps_ui <- function(task, stage_index, registry) {
  artifact_ids <- workflow_required_stage_artifact_ids(task, stage_index)

  if (length(artifact_ids) == 0L) {
    return(shiny::p(
      class = "workflow-panel-empty",
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
        shiny::span(
          class = paste("workflow-state", artifact$status),
          workflow_status_label(artifact$status)
        )
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
    shiny::tags$dt(label),
    shiny::tags$dd(value)
  )
}

workflow_checkpoint_ui <- function(task, stage_index, registry) {
  artifact_ids <- workflow_required_stage_artifact_ids(task, stage_index)
  stage_status <- workflow_stage_status(task, stage_index, registry)

  shiny::tagList(
    shiny::tags$dl(
      workflow_checkpoint_row(
        "Stage status",
        shiny::span(
          class = paste("workflow-state", stage_status),
          workflow_status_label(stage_status)
        )
      )
    ),
    if (length(artifact_ids) == 0L) {
      shiny::p(
        class = "workflow-checkpoint-empty",
        "No separate required artifact is recorded for this Stage."
      )
    } else {
      lapply(artifact_ids, function(artifact_id) {
        artifact <- registry[[artifact_id]]
        shiny::tags$section(
          class = "workflow-checkpoint-artifact",
          `data-checkpoint-node` = artifact_id,
          `data-checkpoint-status` = artifact$status,
          shiny::h3(workflow_artifact_label(artifact_id)),
          shiny::tags$dl(
            workflow_checkpoint_row(
              "Status",
              shiny::span(
                class = paste("workflow-state", artifact$status),
                workflow_status_label(artifact$status)
              )
            ),
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
  if (stage_index == 3L) return("Build HE Dataset")
  if (stage_index == 4L && identical(task_id, "generate_hev")) return("HEV Plots")
  if (stage_index == 4L) return("Explore Relationships")
  if (stage_index == 5L && identical(task_id, "generate_hev")) return("HEV Plots")
  "Model and Export"
}

workflow_stage_overview_ui <- function(
    task_id,
    current_stage,
    registry,
    selected_enrichments = character()) {
  task <- get_he_workflow_task(task_id)
  stage <- he_workflow_stages[[current_stage]]
  stage_status <- workflow_stage_status(task, current_stage, registry)

  shiny::div(
    class = "workflow-stage-overview",
    shiny::div(
      class = "workflow-stage-overview-inner",
      shiny::tags$details(
        shiny::tags$summary(
          shiny::div(
            class = "workflow-stage-overview-title",
            shiny::strong(sprintf("Stage %d · %s", current_stage, stage$stage_label)),
            shiny::span(stage$description)
          ),
          shiny::span(
            class = paste("workflow-state", stage_status),
            workflow_status_label(stage_status)
          )
        ),
        shiny::div(
          class = "workflow-stage-overview-body",
          shiny::div(
            class = "workflow-grid",
            shiny::tags$section(
              class = "workflow-panel",
              shiny::div(
                class = "workflow-panel-head",
                shiny::h2("Required steps for this Task"),
                shiny::p("Calculations start only after an explicit action.")
              ),
              workflow_required_steps_ui(task, current_stage, registry)
            ),
            shiny::tags$aside(
              class = "workflow-panel workflow-checkpoint",
              shiny::div(
                class = "workflow-panel-head",
                shiny::h2("Checkpoint"),
                shiny::p("Current artifact evidence and recovery guidance.")
              ),
              shiny::div(
                class = "workflow-checkpoint-body",
                workflow_checkpoint_ui(task, current_stage, registry)
              )
            )
          ),
          workflow_core_scope_ui(task, selected_enrichments)
        )
      )
    ),
    shiny::span(
      class = "visually-hidden",
      `aria-live` = "polite",
      `aria-atomic` = "true",
      shiny::textOutput("workflow_status_announcement", container = shiny::span)
    )
  )
}

workflow_workspace_ui <- function(
    task_id,
    current_stage,
    registry,
    selected_enrichments = character()) {
  shiny::tagList(
    workflow_header_ui(task_id, current_stage, registry),
    workflow_stage_overview_ui(
      task_id,
      current_stage,
      registry,
      selected_enrichments
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
    return(shiny::tagList(
      workflow_header_ui(registry = registry),
      workflow_task_selector_ui(registry = registry)
    ))
  }
  workflow_workspace_ui(
    task_id,
    current_stage,
    registry,
    selected_enrichments
  )
}
