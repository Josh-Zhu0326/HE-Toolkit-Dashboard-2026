# This file contains the server function, allowing user interactions with the dashboard to be executed

function(input, output, session){

  # FIVE-STAGE WORKFLOW SHELL ----
  # Preserve this registry when changing Tasks so reusable outputs remain available.
  workflow_artifacts <- reactiveVal(new_he_artifact_registry())
  workflow_session <- reactiveValues(
    task_id = NULL,
    stage_index = 1L
  )
  workspace_auth_provider <- workspace_auth_provider_for_session(session)
  workspace_context <- workspace_auth_context(workspace_auth_provider, session)
  workspace_storage <- workspace_storage_for_session(session)
  workspace_storage_info <- workspace_storage_capabilities(workspace_storage)
  workspace_save_available <- workspace_storage_operation_available(
    workspace_storage,
    "save",
    workspace_context
  )
  workspace_save_in_progress <- reactiveVal(FALSE)
  workspace_save_status <- reactiveVal(list(
    status = "idle",
    message = if (workspace_save_available) {
      "No workspace has been saved in this session."
    } else {
      "Workspace saving is not configured for this session."
    },
    result = NULL
  ))
  processed_checkpoint_data <- reactiveVal(NULL)
  processed_checkpoint_manifest <- reactiveVal(NULL)
  processed_checkpoint_load_status <- reactiveVal(list(
    status = "info",
    message = "No processed dataset checkpoint loaded."
  ))
  hev_plot_dependency_status <- reactiveVal(list(
    status = "info",
    message = "HEV plotting dependencies have not been checked in this session."
  ))
  hev_current_result <- reactiveVal(list(
    status = "not_ready",
    plot = NULL,
    data = NULL,
    provenance = NULL,
    messages = "Generate an HEV plot from the current analysis dataset."
  ))
  hev_download_history <- reactiveVal(empty_hev_download_history())
  active_join_source <- reactiveVal("generated")
  analysis_filter_selection <- reactiveVal(new_filter_selection())
  joined_enriched_result <- reactiveVal(list(
    status = "not_ready",
    joined_enriched = NULL,
    messages = "Optional enrichment has not been built.",
    provenance = empty_enrichment_provenance(character())
  ))
  selected_enrichments <- reactive({
    normalise_enrichment_selection(input$selected_enrichments)
  })

  mark_hev_result_stale <- function(reason) {
    current <- isolate(hev_current_result())
    if (!identical(current$status, "success")) {
      return(invisible(NULL))
    }
    hev_current_result(modifyList(current, list(
      status = "stale",
      messages = paste("The previous HEV plot is stale.", reason)
    )))
    if (workflow_artifact_is_current("hev_result")) {
      workflow_set_artifact(
        "hev_result",
        "stale",
        data_source = "HEV plot generation",
        history_summary = summarise_hev_provenance(current$provenance),
        blocking_reason = reason,
        next_action = "Regenerate the HEV plot before downloading it as the current result."
      )
    }
    invisible(NULL)
  }

  output$workflow_header <- renderUI({
    workflow_header_ui(
      task_id = workflow_session$task_id,
      current_stage = workflow_session$stage_index,
      registry = workflow_artifacts(),
      current_panel = input$main_nav,
      show_workspace_save = workspace_save_available
    )
  })

  output$workflow_stage_overview <- renderUI({
    if (is.null(workflow_session$task_id)) {
      return(NULL)
    }
    workflow_stage_overview_ui(
      task_id = workflow_session$task_id,
      current_stage = workflow_session$stage_index,
      registry = workflow_artifacts(),
      selected_enrichments = selected_enrichments()
    )
  })

  output$workflow_shell <- renderUI({
    workflow_task_selector_ui(registry = workflow_artifacts())
  })

  # Always derive Resume from artifact state; do not hard-code a starting Stage.
  lapply(he_workflow_task_ids(), function(task_id) {
    local({
      current_task_id <- task_id
      observeEvent(input[[paste0("select_task__", current_task_id)]], {
        task <- get_he_workflow_task(current_task_id)
        resume_stage <- workflow_resume_stage(task, workflow_artifacts())
        workflow_session$task_id <- current_task_id
        workflow_session$stage_index <- resume_stage
        updateNavbarPage(
          session,
          "main_nav",
          selected = workflow_nav_target(current_task_id, resume_stage)
        )
      }, ignoreInit = TRUE)
    })
  })

  # Keep unused "-" Stages inaccessible in both the UI and server.
  lapply(seq_along(he_workflow_stages), function(stage_index) {
    local({
      current_stage_index <- stage_index
      observeEvent(input[[paste0("workflow_stage_", current_stage_index)]], {
        req(workflow_session$task_id)
        task <- get_he_workflow_task(workflow_session$task_id)
        if (!identical(task$stage_path[[current_stage_index]], "-")) {
          workflow_session$stage_index <- current_stage_index
          updateNavbarPage(
            session,
            "main_nav",
            selected = workflow_nav_target(workflow_session$task_id, current_stage_index)
          )
        }
      }, ignoreInit = TRUE)
    })
  })

  observeEvent(input$change_task, {
    workflow_session$task_id <- NULL
    workflow_session$stage_index <- 1L
    updateNavbarPage(session, "main_nav", selected = "Home")
  }, ignoreInit = TRUE)

  observeEvent(input$open_task_selector, {
    workflow_session$task_id <- NULL
    workflow_session$stage_index <- 1L
    updateNavbarPage(session, "main_nav", selected = "Home")
  }, ignoreInit = TRUE)

  observeEvent(input$workflow_stage_view_biology, {
    req(workflow_session$task_id)
    req(identical(workflow_session$stage_index, 2L))
    updateNavbarPage(session, "main_nav", selected = "Process Biology")
  }, ignoreInit = TRUE)

  observeEvent(input$workflow_stage_view_flow, {
    req(workflow_session$task_id)
    req(identical(workflow_session$stage_index, 2L))
    updateNavbarPage(session, "main_nav", selected = "Process Flow")
  }, ignoreInit = TRUE)

  observeEvent(input$open_csv_validation, {
    updateNavbarPage(session, "main_nav", selected = "File Validation Sandbox")
  }, ignoreInit = TRUE)

  output$workflow_status_announcement <- renderText({
    req(workflow_session$task_id)
    task <- get_he_workflow_task(workflow_session$task_id)
    workflow_status_announcement_text(
      task,
      workflow_session$stage_index,
      workflow_artifacts()
    )
  })

  # WORKFLOW ARTIFACT ADAPTERS ----
  # Route real business outcomes through these adapters; never complete on click.
  workflow_set_artifact <- function(
      artifact_id,
      status,
      data_source = NULL,
      history_summary = NULL,
      blocking_reason = NULL,
      next_action = NULL,
      invalidate_downstream = FALSE) {
    registry <- isolate(workflow_artifacts())
    checkpoint_is_independent <- identical(
      isolate(active_join_source()),
      "checkpoint"
    ) && "joined_core" %in% workflow_descendants(artifact_id)
    if (invalidate_downstream && !checkpoint_is_independent) {
      registry <- invalidate_he_artifacts_from(registry, artifact_id)
    }
    registry <- set_he_artifact_status(
      registry,
      artifact_id,
      status,
      data_source = data_source,
      history_summary = history_summary,
      blocking_reason = blocking_reason,
      next_action = next_action
    )
    workflow_artifacts(registry)
    invisible(registry[[artifact_id]])
  }

  workflow_begin_artifact <- function(artifact_id, next_action) {
    workflow_set_artifact(
      artifact_id,
      "running",
      next_action = next_action,
      invalidate_downstream = TRUE
    )
  }

  workflow_complete_artifact <- function(artifact_id, data_source, history_summary) {
    workflow_set_artifact(
      artifact_id,
      "complete",
      data_source = data_source,
      history_summary = history_summary,
      invalidate_downstream = TRUE
    )
  }

  workflow_reset_artifact <- function(artifact_id, blocking_reason, next_action) {
    workflow_set_artifact(
      artifact_id,
      "not_started",
      blocking_reason = blocking_reason,
      next_action = next_action,
      invalidate_downstream = TRUE
    )
  }

  workflow_artifact_is_current <- function(artifact_id) {
    artifact_is_current(workflow_artifacts()[[artifact_id]])
  }

  workflow_block_artifact <- function(
      artifact_id,
      blocking_reason,
      next_action,
      notification = paste(blocking_reason, next_action)) {
    workflow_set_artifact(
      artifact_id,
      "blocked",
      blocking_reason = blocking_reason,
      next_action = next_action,
      invalidate_downstream = TRUE
    )
    showNotification(notification, type = "error", duration = 10)
    invisible(FALSE)
  }

  workflow_fail_external_import <- function(artifact_id, message, next_action) {
    workflow_set_artifact(
      artifact_id,
      "failed",
      blocking_reason = message,
      next_action = next_action,
      invalidate_downstream = TRUE
    )
    showNotification(message, type = "error", duration = 10)
    invisible(FALSE)
  }

  record_external_import_diagnostic <- function(context, result) {
    detail <- result$diagnostic
    if (is.null(detail) || !nzchar(detail)) {
      detail <- result$failure
    }
    current <- isolate(external_import_diagnostics())
    external_import_diagnostics(rbind(
      current,
      data.frame(
        recorded_at = Sys.time(),
        context = context,
        failure = result$failure,
        detail = detail,
        stringsAsFactors = FALSE
      )
    ))
    invisible(NULL)
  }

  record_file_operation_diagnostic <- function(context, result) {
    detail <- result$diagnostic
    if (is.null(detail) || !nzchar(detail)) {
      detail <- result$failure
    }
    message(sprintf(
      "RAW-19/21 file-operation diagnostic [%s/%s]: %s",
      context,
      result$failure,
      detail
    ))
    invisible(NULL)
  }

  raw24_contains_internal_detail <- function(message) {
    if (!is.character(message) || length(message) != 1L || is.na(message)) {
      return(TRUE)
    }
    grepl(
      paste(
        "[\\r\\n]",
        "[A-Za-z]:[/\\\\]",
        "(^|[[:space:]('\\\"])/(Users|home|tmp|private|var|etc|usr|opt)/",
        "\\\\\\\\[^\\\\]+\\\\",
        paste(
          "conditionMessage|traceback|call stack|fread|read[.]csv|readRDS",
          "ggplot|ggsave|file[.]copy|write_csv|curl|libcurl|reactive|shiny[.]",
          sep = "|"
        ),
        sep = "|"
      ),
      message,
      ignore.case = TRUE,
      perl = TRUE
    )
  }

  raw24_safe_condition_message <- function(error, safe_prefixes, fallback) {
    diagnostic <- conditionMessage(error)
    trusted_message <- any(startsWith(diagnostic, safe_prefixes)) &&
      !raw24_contains_internal_detail(diagnostic)
    if (isTRUE(trusted_message)) diagnostic else fallback
  }

  record_raw24_condition_diagnostic <- function(context, error) {
    message(sprintf(
      "RAW-24 user-facing error diagnostic [%s]: %s",
      context,
      conditionMessage(error)
    ))
    invisible(NULL)
  }

  safe_server_file_operation <- function(context, operation) {
    result <- safe_file_operation(operation)
    if (!identical(result$status, "success")) {
      record_file_operation_diagnostic(context, result)
      showNotification(result$message, type = "error", duration = 10)
      validate(need(FALSE, result$message))
    }
    result$value
  }

  safe_server_plot <- function(context, operation) {
    result <- safe_plot_result(operation)
    if (!identical(result$status, "success")) {
      message(sprintf(
        "RAW-18 plot diagnostic [%s/%s]: %s",
        context,
        result$failure,
        result$diagnostic
      ))
      validate(need(FALSE, result$message))
    }
    result$value
  }

  workflow_checkpoint_card <- function(artifact_id, complete_message, blocked_message) {
    artifact <- workflow_artifacts()[[artifact_id]]
    if (artifact_is_current(artifact)) {
      status <- if (identical(artifact$status, "warning")) "warn" else "pass"
      return(cp_card(status, complete_message))
    }
    cp_card("fail", blocked_message)
  }

  server_context <- environment()
  flow_source_revision <- reactiveVal(0L)
  external_flow_loaded <- reactiveVal(FALSE)
  external_flow_revision <- reactiveVal(NULL)
  external_import_requested_revision <- reactiveVal(NULL)
  flow_stats_revision <- reactiveVal(NULL)
  join_revision <- reactiveVal(NULL)
  hev_revision <- reactiveVal(NULL)
  rict_request <- reactiveVal(NULL)
  oe_request <- reactiveVal(NULL)
  biology_import_request <- reactiveVal(NULL)
  environment_import_request <- reactiveVal(NULL)
  external_import_diagnostics <- reactiveVal(data.frame(
    recorded_at = as.POSIXct(character()),
    context = character(),
    failure = character(),
    detail = character(),
    stringsAsFactors = FALSE
  ))
  hev_request <- reactiveVal(NULL)
  join_request <- reactiveVal(NULL)
  join_settings_used <- reactiveVal(NULL)

  normalise_join_settings <- function(lags, method) {
    list(
      lags = sort(unique(as.integer(lags))),
      method = as.character(method)[[1L]]
    )
  }

  local_flow_is_operational <- function(upload) {
    upload$validation$status %in% c("success", "warning")
  }

  invalidate_flow_derived_state <- function(reset_external = FALSE) {
    mark_hev_result_stale("The Flow source changed after the current HEV plot was generated.")
    flow_source_revision(isolate(flow_source_revision()) + 1L)
    flow_stats_revision(NULL)
    join_revision(NULL)
    hev_revision(NULL)
    hev_request(NULL)
    join_request(NULL)
    join_settings_used(NULL)
    workflow_reset_artifact(
      "flow_input",
      "The Flow source changed after downstream outputs were generated.",
      "Validate or import the current Flow source."
    )

    if (reset_external) {
      external_flow_loaded(FALSE)
      external_flow_revision(NULL)
      external_import_requested_revision(NULL)
    }

    for (flag_name in c("flow_data_exist", "flow_stats_exist", "HEV_data_exist")) {
      if (exists(flag_name, envir = server_context, inherits = FALSE)) {
        get(flag_name, envir = server_context)(FALSE)
      }
    }

    if (exists("basic_model_result", envir = server_context, inherits = FALSE)) {
      get("basic_model_result", envir = server_context)(list(
        status = "info",
        messages = "Pair biology and flow data, choose variables, then run the optional basic model.",
        plot = NULL,
        summary = NULL
      ))
    }
  }

  observeEvent(input$import_inv, {
    biology_import_request(NULL)
    if (!workflow_artifact_is_current("site_mapping")) {
      workflow_block_artifact(
        "biology_input",
        "Current site metadata with valid biol_site_id values are required before importing Biology data.",
        "Correct and validate the site metadata, then import Biology data again."
      )
      return()
    }
    biology_import_request(input$import_inv)
    workflow_begin_artifact("biology_input", "Complete the Biology import.")
  }, ignoreInit = FALSE, priority = 50)
  observeEvent(input$import_env, {
    environment_import_request(NULL)
    if (!workflow_artifact_is_current("site_mapping")) {
      workflow_block_artifact(
        "environment_input",
        "Current site metadata with valid biol_site_id values are required before importing Environmental data.",
        "Correct and validate the site metadata, then import Environmental data again."
      )
      return()
    }
    environment_import_request(input$import_env)
    workflow_begin_artifact("environment_input", "Complete the environmental-data import.")
  }, ignoreInit = FALSE, priority = 50)
  observeEvent(input$run_rict, {
    rict_request(NULL)
    if (!workflow_artifact_is_current("environment_input")) {
      workflow_block_artifact(
        "processed_environment",
        "Current Environmental data are required before running RICT predictions.",
        "Import or regenerate Environmental data, then run RICT predictions again."
      )
      return()
    }
    rict_request(input$run_rict)
    workflow_begin_artifact("processed_environment", "Complete RICT prediction processing.")
  }, ignoreInit = TRUE, priority = 100)
  observeEvent(input$calc_OE, {
    oe_request(NULL)
    if (!workflow_artifact_is_current("biology_input")) {
      workflow_block_artifact(
        "oe_result",
        "Biology data are required before calculating O:E ratios.",
        "Import or restore Biology data, then calculate O:E ratios again."
      )
      return()
    }
    if (!workflow_artifact_is_current("processed_environment")) {
      workflow_block_artifact(
        "oe_result",
        "Current RICT predictions are required before calculating O:E ratios.",
        "Run RICT predictions before calculating O:E ratios."
      )
      return()
    }
    oe_request(input$calc_OE)
    workflow_begin_artifact("oe_result", "Complete the O:E calculation.")
  }, ignoreInit = TRUE, priority = 100)
  observeEvent(input$calc_flow_stats, {
    if (!workflow_artifact_is_current("flow_input")) {
      workflow_set_artifact(
        "flow_statistics",
        "blocked",
        blocking_reason = "Flow statistics require current validated Flow data.",
        next_action = "Upload or import Flow data, then calculate Flow statistics again."
      )
      return()
    }
    workflow_begin_artifact("flow_statistics", "Complete the Flow-statistics calculation.")
  }, ignoreInit = TRUE, priority = 100)
  # Snapshot controls at click time so lazy output consumers cannot run a new
  # join later with settings the user did not explicitly submit.
  observeEvent(input$join_he, {
    req(!is.null(input$choose_lags), !is.null(input$choose_join_method))
    mark_hev_result_stale("The Joined HE Dataset is being rebuilt.")
    join_request(NULL)
    join_revision(NULL)
    hev_revision(NULL)
    hev_request(NULL)
    if (!workflow_artifact_is_current("oe_result")) {
      workflow_block_artifact(
        "joined_core",
        "Current O:E ratios are required before building the Joined HE Dataset.",
        "Calculate or regenerate O:E ratios, then build the Joined HE Dataset again."
      )
      return()
    }
    if (!workflow_artifact_is_current("flow_statistics")) {
      workflow_block_artifact(
        "joined_core",
        "Flow Statistics are missing or out of date.",
        "Calculate or regenerate Flow Statistics, then build the Joined HE Dataset again."
      )
      return()
    }
    active_join_source("generated")
    join_request(list(
      flow_revision = isolate(flow_source_revision()),
      settings = normalise_join_settings(
        input$choose_lags,
        input$choose_join_method
      ),
      request_id = input$join_he
    ))
    workflow_begin_artifact("joined_core", "Complete the biology–Flow join.")
  }, ignoreInit = TRUE, priority = 110)
  observeEvent(input$renderHEV, {
    dependency <- hev_dependency_check()
    hev_plot_dependency_status(dependency)
    if (identical(dependency$status, "error")) {
      hev_request(NULL)
      workflow_set_artifact(
        "hev_result",
        "blocked",
        blocking_reason = dependency$message,
        next_action = "Install the project dependencies, restart the dashboard, and create the HEV plot again."
      )
      showNotification(dependency$message, type = "error", duration = 10)
      return()
    }
    if (!workflow_artifact_is_current("joined_core")) {
      hev_request(NULL)
      workflow_block_artifact(
        "hev_result",
        "The Joined HE Dataset is missing or out of date.",
        "Rebuild or regenerate the Joined HE Dataset, then create the HEV plot again."
      )
      return()
    }
    hev_request(input$renderHEV)
    workflow_begin_artifact("hev_result", "Complete HEV plot generation.")
  }, ignoreInit = TRUE, priority = 100)

  observeEvent(
    list(input$choose_lags, input$choose_join_method),
    {
      req(!is.null(input$choose_lags), !is.null(input$choose_join_method))
      settings_used <- isolate(join_settings_used())
      if (is.null(settings_used)) {
        return()
      }

      current_settings <- normalise_join_settings(
        input$choose_lags,
        input$choose_join_method
      )
      if (identical(current_settings, settings_used)) {
        return()
      }

      registry <- isolate(workflow_artifacts())
      joined_core <- registry$joined_core
      if (artifact_is_current(joined_core)) {
        # Retain the cached output and its metadata, but stop treating it as
        # current until the user explicitly submits another Join request.
        mark_hev_result_stale("Join settings changed after the current HEV plot was generated.")
        join_revision(NULL)
        hev_revision(NULL)
        hev_request(NULL)
        workflow_set_artifact(
          "joined_core",
          "stale",
          data_source = joined_core$data_source,
          history_summary = joined_core$history_summary,
          blocking_reason = "Join settings changed after the current Joined HE dataset was generated.",
          next_action = "Run the join again with the current lag and method settings.",
          invalidate_downstream = TRUE
        )
      }
    },
    ignoreInit = TRUE,
    priority = 90
  )
  
  output$cp_biology <- renderUI({
    tagList(
      workflow_checkpoint_card(
        "biology_input",
        "Biology data loaded",
        "[Blocked] Biology data not imported"
      ),
      workflow_checkpoint_card(
        "environment_input",
        "Environmental data loaded",
        "[Blocked] Environmental data not imported"
      ),
      if (workflow_artifact_is_current("processed_environment")) {
        cp_card("pass", "RICT predictions complete")
      },
      if (workflow_artifact_is_current("oe_result")) {
        cp_card("pass", "O:E ratios calculated")
      }
    )
  })
  
  output$cp_flow <- renderUI({
    tagList(
      workflow_checkpoint_card(
        "flow_input",
        "Flow data loaded",
        "[Blocked] Flow data not imported"
      ),
      if (workflow_artifact_is_current("flow_statistics")) {
        cp_card("pass", "Flow statistics calculated")
      }
    )
  })
  
  output$cp_hev <- renderUI({
    tagList(
      workflow_checkpoint_card(
        "oe_result",
        "O:E ratios ready",
        "[Blocked] O:E not yet calculated"
      ),
      workflow_checkpoint_card(
        "flow_statistics",
        "Flow statistics ready",
        "[Blocked] Flow stats not yet calculated"
      ),
      workflow_checkpoint_card(
        "joined_core",
        "Biology and Flow paired",
        "[Blocked] Data not yet joined (Analysis page)"
      ),
      workflow_checkpoint_card(
        "analysis_dataset",
        "Current analysis dataset ready",
        "[Blocked] Current analysis dataset not yet available"
      ),
      if (workflow_artifact_is_current("oe_result") &&
          workflow_artifact_is_current("flow_statistics") &&
          workflow_artifact_is_current("joined_core") &&
          workflow_artifact_is_current("analysis_dataset")) {
        cp_card("pass", "All prerequisites met — ready to generate HEV plot")
      }
    )
  })

  wq_rhs_mapping_example <- data.frame(
    biol_site_id = "291",
    flow_site_id = "27090",
    flow_input = "NRFA",
    wq_site_id = "SW-A4070115",
    rhs_survey_id = "6145",
    stringsAsFactors = FALSE
  )

  output$wq_rhs_mapping_example <- DT::renderDataTable({
    DT::datatable(
      wq_rhs_mapping_example,
      extensions = "Buttons",
      rownames = FALSE,
      options = list(
        columnDefs = list(list(className = "dt-center", targets = 0:4)),
        searching = FALSE,
        pageLength = 5,
        dom = "Bfrtip",
        buttons = list("copy"),
        order = list(),
        autoWidth = FALSE,
        orderClasses = FALSE,
        lengthMenu = list(c(5, 10, 25, 50, 100), c(5, 10, 25, 50, 100))
      )
    )
  })

  # WQ/RHS UPLOAD DEMO ----
  read_uploaded_csv_safely <- function(upload, label) {
    if (is.null(upload)) {
      return(list(
        data = NULL,
        status = "info",
        messages = paste0("No ", label, " file uploaded yet.")
      ))
    }

    result <- read_dashboard_csv(upload$datapath, paste0("Your ", label, " file"))
    if (!identical(result$status, "success")) {
      return(result)
    }

    list(data = result$data, status = "ok", messages = character(0))
  }

  validate_wq_upload <- function(df) {
    if (is.null(df)) {
      return(list(status = "info", messages = "No WQ file uploaded yet."))
    }

    if (nrow(df) == 0 || ncol(df) == 0) {
      return(list(
        status = "error",
        messages = "Your WQ file appears to be empty. Please upload a CSV file with at least one data row."
      ))
    }

    names_lower <- tolower(names(df))
    messages <- "Your WQ file was uploaded successfully."
    status <- "success"

    site_cols <- c("biol_site_id", "wq_site_id", "site_id", "monitoring_site_id")
    if (!any(site_cols %in% names_lower)) {
      return(list(
        status = "error",
        messages = paste(
          "Your WQ file is missing a site identifier column.",
          "Add one of biol_site_id, wq_site_id, site_id, or monitoring_site_id, then upload the file again."
        )
      ))
    }

    date_like <- stringr::str_detect(names_lower, "date|time|sample")
    measurement_like <- stringr::str_detect(names_lower, "result|value|measure|determin|parameter|concentration|unit|qualifier|observation")
    numeric_like <- purrr::map_lgl(df, is.numeric)

    if (!any(date_like) && !any(measurement_like) && !any(numeric_like)) {
      status <- "warning"
      messages <- c(
        messages,
        "Your WQ file does not clearly contain a date-like or measurement-like column. Please add sample dates and measured results where possible."
      )
    }

    messages <- c(
      messages,
      "This preview shows the first rows of your uploaded file. No modelling has been run yet."
    )

    list(status = status, messages = messages)
  }

  validate_rhs_upload <- function(df) {
    if (is.null(df)) {
      return(list(status = "info", messages = "No RHS file uploaded yet."))
    }

    if (nrow(df) == 0 || ncol(df) == 0) {
      return(list(
        status = "error",
        messages = "Your RHS file appears to be empty. Please upload a CSV file with at least one data row."
      ))
    }

    names_lower <- tolower(names(df))
    messages <- "Your RHS file was uploaded successfully."
    status <- "success"

    id_cols <- "rhs_survey_id"
    if (!any(id_cols %in% names_lower)) {
      return(list(
        status = "error",
        messages = paste(
          "Your RHS file is missing the required rhs_survey_id column.",
          "Add rhs_survey_id, then upload the file again."
        )
      ))
    }

    rhs_metric_like <- stringr::str_detect(
      names_lower,
      "rhs|hms|hqa|score|class|metric|descriptor|habitat|channel|bank|substrate|vegetation|flow|poach|berm|bridge|ford"
    )
    non_identifier_cols <- setdiff(names_lower, id_cols)

    if (!any(rhs_metric_like) && length(non_identifier_cols) == 0) {
      status <- "warning"
      messages <- c(
        messages,
        "Your RHS file does not clearly contain an RHS metric or descriptor column. Please add habitat metrics or descriptors such as HMS, HQA, channel, bank, substrate, or vegetation fields."
      )
    }

    messages <- c(
      messages,
      "This preview shows the first rows of your uploaded file. No modelling has been run yet."
    )

    list(status = status, messages = messages)
  }

  dc11_csv_upload <- reactive({
    read_result <- read_uploaded_csv_safely(input$dc11_csv, "DC-11")
    validation <- if (identical(read_result$status, "ok")) {
      validate_dc11_dataset(read_result$data, input$dc11_csv_sheet)
    } else {
      list(status = read_result$status, messages = read_result$messages, issues = dc11_empty_issues())
    }

    list(data = read_result$data, validation = validation)
  })

  dc11_workbook_upload <- reactive({
    upload <- input$dc11_workbook
    if (is.null(upload)) {
      return(list(
        sheets = list(),
        validation = list(
          status = "info",
          messages = "No DC-11 workbook uploaded yet.",
          issues = dc11_empty_issues(),
          sheet_results = list()
        )
      ))
    }

    if (is.null(upload$datapath) || !file.exists(upload$datapath)) {
      return(list(
        sheets = list(),
        validation = list(
          status = "error",
          messages = "Your DC-11 workbook could not be found after upload. Please try uploading it again.",
          issues = dc11_checkpoint_issue("workbook", "error", "file_not_found", "Your DC-11 workbook could not be found after upload."),
          sheet_results = list()
        )
      ))
    }

    validation <- validate_dc11_workbook_file(upload$datapath)
    list(sheets = validation$sheets, validation = validation)
  })

  format_validation_message <- function(result) {
    status <- result$status
    if (isTRUE(status == "ok")) {
      status <- "success"
    }

    class_name <- paste("upload-status", paste0("upload-status-", status))
    tags$div(
      class = class_name,
      tags$ul(lapply(result$messages, tags$li))
    )
  }

  wq_upload <- reactive({
    read_result <- read_uploaded_csv_safely(input$wq_csv, "WQ")
    validation <- validate_wq_upload(read_result$data)

    if (read_result$status == "error") {
      validation <- list(status = "error", messages = read_result$messages)
    }

    list(data = read_result$data, validation = validation)
  })

  rhs_upload <- reactive({
    read_result <- read_uploaded_csv_safely(input$rhs_csv, "RHS")
    validation <- validate_rhs_upload(read_result$data)

    if (read_result$status == "error") {
      validation <- list(status = "error", messages = read_result$messages)
    }

    list(data = read_result$data, validation = validation)
  })

  observeEvent(input$wq_csv, {
    workflow_reset_artifact(
      "wq_input",
      "The WQ source changed.",
      "Validate the current WQ source if enrichment is required."
    )
  }, ignoreNULL = FALSE, priority = 200)

  observeEvent(input$rhs_csv, {
    workflow_reset_artifact(
      "rhs_input",
      "The RHS source changed.",
      "Validate the current RHS source if enrichment is required."
    )
  }, ignoreNULL = FALSE, priority = 200)

  observeEvent(wq_upload(), {
    upload <- wq_upload()
    req(!is.null(upload$data), nrow(upload$data) > 0L)
    req(upload$validation$status %in% c("success", "warning"))
    if (exists("wq_site_import_data", envir = server_context, inherits = FALSE)) {
      get("wq_site_import_data", envir = server_context)(NULL)
    }
    if (exists("reset_wq_contract_summary", envir = server_context, inherits = FALSE)) {
      get("reset_wq_contract_summary", envir = server_context)(
        "The local WQ upload changed. Rebuild the WQ contract summary from the current mapped records."
      )
    }
    workflow_set_artifact(
      "wq_input",
      if (identical(upload$validation$status, "warning")) "warning" else "complete",
      data_source = "Local WQ file",
      history_summary = "Validated local WQ upload.",
      invalidate_downstream = TRUE
    )
  })

  observeEvent(rhs_upload(), {
    upload <- rhs_upload()
    req(!is.null(upload$data), nrow(upload$data) > 0L)
    req(upload$validation$status %in% c("success", "warning"))
    workflow_set_artifact(
      "rhs_input",
      if (identical(upload$validation$status, "warning")) "warning" else "complete",
      data_source = "Local RHS file",
      history_summary = "Validated local RHS upload.",
      invalidate_downstream = TRUE
    )
  })

  output$wq_validation_status <- renderUI({
    format_validation_message(wq_upload()$validation)
  })

  output$rhs_validation_status <- renderUI({
    format_validation_message(rhs_upload()$validation)
  })

  output$dc11_validation_status <- renderUI({
    result <- dc11_csv_upload()$validation
    messages <- c(
      result$messages,
      "This checkpoint reports validation only. It has not changed the active import, join, model, or HEV data."
    )
    format_validation_message(list(status = result$status, messages = messages))
  })

  output$dc11_workbook_validation_status <- renderUI({
    result <- dc11_workbook_upload()$validation
    messages <- c(
      result$messages,
      "This workbook checkpoint reports validation only. It has not changed the active import, join, model, or HEV data."
    )
    format_validation_message(list(status = result$status, messages = messages))
  })

  output$dc11_workbook_validation_issues <- DT::renderDataTable({
    issues <- dc11_workbook_upload()$validation$issues
    if (is.null(issues) || nrow(issues) == 0) {
      return(data.frame(
        sheet = "workbook",
        severity = "success",
        code = "passed",
        message = "No DC-11 workbook issues found.",
        stringsAsFactors = FALSE
      ))
    }
    issues
  }, rownames = FALSE, options = list(scrollX = TRUE, pageLength = 10))

  observeEvent(dc11_workbook_upload(), {
    sheets <- names(dc11_workbook_upload()$sheets)
    if (is.null(sheets) || length(sheets) == 0L) {
      sheets <- names(dc11_sheet_schemas())
    }
    sheets <- sheets[!is.na(sheets) & nzchar(sheets)]
    if (length(sheets) == 0L) {
      return(invisible(NULL))
    }

    preview_sheet <- input$dc11_workbook_preview_sheet
    has_valid_preview_sheet <- !is.null(preview_sheet) &&
      length(preview_sheet) == 1L &&
      !is.na(preview_sheet) &&
      nzchar(preview_sheet) &&
      preview_sheet %in% sheets
    selected <- if (isTRUE(has_valid_preview_sheet)) {
      preview_sheet
    } else {
      sheets[[1L]]
    }
    updateSelectInput(
      session,
      "dc11_workbook_preview_sheet",
      choices = sheets,
      selected = selected
    )
  }, ignoreNULL = FALSE)

  output$dc11_workbook_preview <- DT::renderDataTable({
    sheets <- dc11_workbook_upload()$sheets
    req(length(sheets) > 0)
    sheet_name <- input$dc11_workbook_preview_sheet
    req(sheet_name %in% names(sheets))
    head(sheets[[sheet_name]], 10)
  }, options = list(scrollX = TRUE, pageLength = 10))

  output$dc11_validation_issues <- DT::renderDataTable({
    issues <- dc11_csv_upload()$validation$issues
    if (is.null(issues) || nrow(issues) == 0) {
      return(data.frame(
        sheet = input$dc11_csv_sheet,
        severity = "success",
        code = "passed",
        message = "No DC-11 issues found.",
        stringsAsFactors = FALSE
      ))
    }
    issues
  }, rownames = FALSE, options = list(scrollX = TRUE, pageLength = 10))

  output$dc11_preview <- DT::renderDataTable({
    req(dc11_csv_upload()$data)
    head(dc11_csv_upload()$data, 10)
  }, options = list(scrollX = TRUE, pageLength = 10))

  output$wq_preview <- DT::renderDataTable({
    req(wq_upload()$data)
    head(wq_upload()$data, 10)
  }, options = list(scrollX = TRUE, pageLength = 10))

  output$rhs_preview <- DT::renderDataTable({
    req(rhs_upload()$data)
    head(rhs_upload()$data, 10)
  }, options = list(scrollX = TRUE, pageLength = 10))
  
  # DATA IMPORTING ----
  ## Metadata ----
  ### loading ----
  site_metadata_upload_result <- reactiveVal(list(
    status = "info",
    messages = "Choose a site metadata CSV to parse and load it automatically."
  ))
  site_metadata_upload_text <- reactiveVal(NULL)
  site_metadata_upload_flow_provenance <- reactiveVal(NULL)
  current_site_metadata <- reactiveVal(NULL)
  metadata_result <- reactiveVal(list(
    data = NULL,
    flow_input_provenance = NULL,
    validation = list(
      status = "error",
      messages = "Please add site metadata, then validate the mapping again."
    )
  ))

  prepare_site_metadata_result <- function(parsed) {
    if (!is.null(parsed$error)) {
      return(list(
        data = NULL,
        flow_input_provenance = NULL,
        validation = list(status = "error", messages = parsed$error)
      ))
    }

    validation <- validate_supporting_mapping(parsed$data)
    if (identical(validation$status, "error")) {
      return(list(
        data = NULL,
        flow_input_provenance = NULL,
        validation = validation
      ))
    }

    normalised <- tryCatch(
      normalise_site_metadata_flow_input(parsed$data),
      error = function(error) NULL
    )
    if (is.null(normalised)) {
      return(list(
        data = NULL,
        flow_input_provenance = NULL,
        validation = list(
          status = "error",
          messages = "Site metadata could not be validated. Please correct the mapping columns and try again."
        )
      ))
    }

    dashboard_validation <- validate_dashboard_site_metadata(normalised)
    if (!is.null(dashboard_validation)) {
      return(list(
        data = NULL,
        flow_input_provenance = NULL,
        validation = list(status = "error", messages = dashboard_validation)
      ))
    }

    list(
      data = normalised,
      flow_input_provenance = site_metadata_flow_input_provenance(normalised),
      validation = list(
        status = validation$status,
        messages = c(validation$messages, parsed$warnings)
      )
    )
  }

  apply_site_metadata_result <- function(result, data_source) {
    metadata_result(result)
    if (identical(result$validation$status, "error")) {
      current_site_metadata(NULL)
      workflow_set_artifact(
        "site_mapping",
        "blocked",
        blocking_reason = paste(result$validation$messages, collapse = " "),
        next_action = "Correct the required site metadata and validate the mapping again.",
        invalidate_downstream = TRUE
      )
      return(invisible(FALSE))
    }

    current_site_metadata(result$data)
    workflow_set_artifact(
      "site_mapping",
      if (identical(result$validation$status, "warning")) "warning" else "complete",
      data_source = data_source,
      history_summary = sprintf("Validated %d site-mapping row(s).", nrow(result$data)),
      invalidate_downstream = TRUE
    )
    invisible(TRUE)
  }

  observeEvent(input$site_metadata_csv, {
    site_metadata_upload_text(NULL)
    site_metadata_upload_flow_provenance(NULL)
    parsed <- read_site_metadata_csv(input$site_metadata_csv$datapath)
    result <- prepare_site_metadata_result(parsed)
    if (!isTRUE(apply_site_metadata_result(result, "Uploaded site metadata CSV"))) {
      site_metadata_upload_result(result$validation)
      showNotification(paste(result$validation$messages, collapse = " "), type = "error")
      return()
    }

    normalised_text <- readr::format_csv(result$data)
    site_metadata_upload_text(normalised_text)
    site_metadata_upload_flow_provenance(result$flow_input_provenance)
    updateTextAreaInput(session, "meta_paste", value = normalised_text)
    messages <- c(
      paste0("Site metadata CSV imported successfully: ", nrow(result$data), " row(s) loaded."),
      paste0("Parsed ID columns: ", paste(intersect(c("biol_site_id", "flow_site_id", "wq_site_id", "rhs_survey_id"), names(result$data)), collapse = ", "), "."),
      "The compatible dataset import buttons below now use these site IDs.",
      result$validation$messages
    )
    site_metadata_upload_result(list(status = result$validation$status, messages = messages[nzchar(messages)]))
    showNotification("Site metadata CSV imported successfully.", type = "message")
  })

  output$site_metadata_upload_status <- renderUI({
    format_validation_message(site_metadata_upload_result())
  })

  output$flow_source_default_status <- renderUI({
    provenance <- tryCatch(
      metadata_flow_input_provenance(),
      error = function(error) NULL,
      shiny.silent.error = function(error) NULL
    )
    if (is.null(provenance)) {
      provenance <- site_metadata_upload_flow_provenance()
    }
    req(!is.null(provenance))
    default_count <- sum(provenance$flow_input_source == "defaulted")
    req(default_count > 0L)
    format_validation_message(list(
      status = "info",
      messages = paste(
        "Flow source was not specified for",
        default_count,
        if (default_count == 1L) "site." else "sites.",
        "HDE has been selected as the default source."
      )
    ))
  })

  output$download_demo_site_metadata <- downloadHandler(
    filename = function() "demo_site_metadata.csv",
    content = function(file) {
      safe_server_file_operation("demo site metadata", function() {
        copied <- file.copy("demo_site_metadata.csv", file, overwrite = TRUE)
        if (!isTRUE(copied)) {
          stop("The demo metadata copy did not complete.", call. = FALSE)
        }
        invisible(copied)
      })
    },
    contentType = "text/csv"
  )

  observeEvent(input$meta_paste, {
    parsed <- parse_site_metadata(input$meta_paste)
    result <- prepare_site_metadata_result(parsed)
    from_upload <- identical(input$meta_paste, site_metadata_upload_text()) &&
      !is.null(site_metadata_upload_flow_provenance())
    if (from_upload && !identical(result$validation$status, "error")) {
      result$flow_input_provenance <- site_metadata_upload_flow_provenance()
      attr(result$data, "flow_input_provenance") <- result$flow_input_provenance
    }

    apply_site_metadata_result(
      result,
      if (from_upload) "Uploaded site metadata CSV" else "Pasted site metadata"
    )
    if (!from_upload) {
      site_metadata_upload_result(result$validation)
      if (identical(result$validation$status, "error")) {
        showNotification(paste(result$validation$messages, collapse = " "), type = "error")
      }
    }
  }, ignoreInit = FALSE, priority = 100)

  metadata <- reactive({
    result <- metadata_result()
    validate(need(
      !identical(result$validation$status, "error") && !is.null(current_site_metadata()),
      paste(result$validation$messages, collapse = " ")
    ))
    current_site_metadata()
  })

  metadata_flow_input_provenance <- reactive({
    result <- metadata_result()
    validate(need(
      !identical(result$validation$status, "error") && !is.null(result$flow_input_provenance),
      paste(result$validation$messages, collapse = " ")
    ))
    result$flow_input_provenance
  })

  wq_site_import_result <- reactiveVal(list(
    status = "info",
    messages = "Paste extended site metadata, choose a WQ date range, then click 'Import WQ using site IDs'."
  ))
  rhs_site_import_result <- reactiveVal(list(
    status = "info",
    messages = "Paste extended site metadata, then click 'Import RHS using site IDs'."
  ))
  wq_site_import_data <- reactiveVal(NULL)
  rhs_site_import_data <- reactiveVal(NULL)
  wq_contract_summary_result <- reactiveVal(list(
    status = "info",
    messages = "Import mapped WQ records and calculate O:E biology data, then click 'Build WQ summary'.",
    data = data.frame()
  ))
  reset_wq_contract_summary <- function(message) {
    wq_contract_summary_result(list(
      status = "info",
      messages = message,
      data = data.frame()
    ))
  }

  observeEvent(list(input$meta_paste, input$date_range_wq), {
    wq_site_import_data(NULL)
    reset_wq_contract_summary(
      "The WQ mapping or date range changed. Import or validate WQ records again, then rebuild the WQ contract summary."
    )
  }, ignoreInit = TRUE)

  observeEvent(input$import_wq_site_ids, {
    reset_wq_contract_summary(
      "The WQ import source changed. Rebuild the WQ contract summary after the import completes."
    )
    parsed <- parse_site_metadata(input$meta_paste)
    if (!is.null(parsed$error)) {
      wq_site_import_data(NULL)
      wq_site_import_result(list(status = "error", messages = parsed$error))
      workflow_set_artifact(
        "wq_input",
        "blocked",
        blocking_reason = parsed$error,
        next_action = "Correct the WQ site mapping and try the import again.",
        invalidate_downstream = TRUE
      )
      showNotification(parsed$error, type = "error")
      return()
    }

    site_metadata <- parsed$data
    usable_wq_ids <- usable_mapping_ids(site_metadata, "wq_site_id")
    if (length(usable_wq_ids) == 0) {
      message <- "No confirmed WQ site IDs are available yet. Please provide WQ site IDs before importing WQ data."
      wq_site_import_data(NULL)
      wq_site_import_result(list(status = "warning", messages = message))
      workflow_set_artifact(
        "wq_input",
        "blocked",
        blocking_reason = message,
        next_action = "Add valid wq_site_id values and try the import again.",
        invalidate_downstream = TRUE
      )
      showNotification(message, type = "warning")
      return()
    }

    start_date <- max(as.Date(input$date_range_wq[[1]]), as.Date("2000-01-01"))
    end_date <- as.Date(input$date_range_wq[[2]])
    if (end_date <= start_date) {
      message <- "The WQ end date must be later than the start date. Water Quality Explorer data are available from 2000 onwards."
      wq_site_import_data(NULL)
      wq_site_import_result(list(status = "error", messages = message))
      workflow_set_artifact(
        "wq_input",
        "blocked",
        blocking_reason = message,
        next_action = "Correct the WQ date range and try the import again.",
        invalidate_downstream = TRUE
      )
      showNotification(message, type = "error")
      return()
    }

    workflow_begin_artifact("wq_input", "Complete the WQ import.")
    has_biology_mapping <- all(c("biol_site_id", "wq_site_id") %in% names(site_metadata))
    import_result <- safe_external_import(
      function() {
        imported <- import_dashboard_wq(
          sites = usable_wq_ids,
          start_date = format(start_date, "%Y-%m-%d"),
          end_date = format(end_date, "%Y-%m-%d")
        )
        if (has_biology_mapping) {
          map_wq_records_to_biology(imported, site_metadata)
        } else {
          imported
        }
      },
      required_columns = "wq_site_id"
    )

    if (!identical(import_result$status, "success")) {
      record_external_import_diagnostic("wq", import_result)
      message <- paste(
        "WQ data could not be retrieved or processed.",
        "Check the supplied site IDs and dates, then try again."
      )
      wq_site_import_data(NULL)
      wq_site_import_result(list(status = "error", messages = message))
      workflow_fail_external_import(
        "wq_input",
        message,
        "Check the WQ site IDs and date range, then try the import again."
      )
      return()
    }

    output_data <- import_result$data
    mapped_biology_count <- if ("biol_site_id" %in% names(output_data)) {
      length(unique(stats::na.omit(output_data$biol_site_id)))
    } else {
      0
    }
    wq_site_import_data(output_data)
    message <- if (mapped_biology_count > 0) {
      paste0("Imported ", nrow(output_data), " WQ records mapped to ", mapped_biology_count, " biology site(s).")
    } else {
      paste0("Imported ", nrow(output_data), " WQ records. No biology mapping was supplied.")
    }
    wq_site_import_result(list(status = "success", messages = c(
      message,
      "WQ records are mapped through wq_site_id; no ID equality with biology or flow sites is assumed."
    )))
    workflow_complete_artifact(
      "wq_input",
      "Water Quality Explorer",
      sprintf("Imported %d mapped WQ record(s).", nrow(output_data))
    )
    showNotification(message, type = "message")
  })

  observeEvent(input$import_rhs_site_ids, {
    parsed <- parse_site_metadata(input$meta_paste)
    if (!is.null(parsed$error)) {
      rhs_site_import_data(NULL)
      rhs_site_import_result(list(status = "error", messages = parsed$error))
      workflow_set_artifact(
        "rhs_input",
        "blocked",
        blocking_reason = parsed$error,
        next_action = "Correct the RHS site mapping and try the import again.",
        invalidate_downstream = TRUE
      )
      showNotification(parsed$error, type = "error")
      return()
    }

    site_metadata <- parsed$data
    usable_rhs_ids <- usable_mapping_ids(site_metadata, "rhs_survey_id")
    if (length(usable_rhs_ids) == 0) {
      message <- "No confirmed RHS survey IDs are available yet. Please provide rhs_survey_id values before importing RHS data."
      rhs_site_import_data(NULL)
      rhs_site_import_result(list(status = "warning", messages = message))
      workflow_set_artifact(
        "rhs_input",
        "blocked",
        blocking_reason = message,
        next_action = "Add valid rhs_survey_id values and try the import again.",
        invalidate_downstream = TRUE
      )
      showNotification(message, type = "warning")
      return()
    }

    retained_registry <- isolate(workflow_artifacts())
    workflow_begin_artifact("rhs_input", "Complete the RHS import.")
    has_biology_mapping <- all(c("biol_site_id", "rhs_survey_id") %in% names(site_metadata))
    rhs_file_failure <- NULL
    import_result <- safe_external_import(
      function() {
        imported <- tryCatch(
          import_rhs_in_temp_directory(usable_rhs_ids),
          dashboard_file_operation_error = function(error) {
            rhs_file_failure <<- error
            stop(error)
          }
        )
        if (has_biology_mapping) {
          map_rhs_records_to_biology(imported, site_metadata)
        } else {
          imported
        }
      },
      required_columns = "rhs_survey_id"
    )

    if (!is.null(rhs_file_failure)) {
      file_result <- file_operation_condition_result(rhs_file_failure)
      record_file_operation_diagnostic("RHS temporary import", file_result)
      workflow_artifacts(retained_registry)
      rhs_site_import_result(list(status = "error", messages = file_result$message))
      showNotification(file_result$message, type = "error", duration = 10)
      return()
    }

    if (!identical(import_result$status, "success")) {
      record_external_import_diagnostic("rhs", import_result)
      message <- paste(
        "RHS data could not be retrieved or processed.",
        "Check the supplied survey IDs, then try again."
      )
      rhs_site_import_data(NULL)
      rhs_site_import_result(list(status = "error", messages = message))
      workflow_fail_external_import(
        "rhs_input",
        message,
        "Check the RHS survey IDs, then try the import again."
      )
      return()
    }

    output_data <- import_result$data
    mapped_biology_count <- if ("biol_site_id" %in% names(output_data)) {
      length(unique(stats::na.omit(output_data$biol_site_id)))
    } else {
      0
    }
    rhs_site_import_data(output_data)
    message <- if (mapped_biology_count > 0) {
      paste0("Imported ", nrow(output_data), " RHS records mapped to ", mapped_biology_count, " biology site(s).")
    } else {
      paste0("Imported ", nrow(output_data), " RHS records. No biology mapping was supplied.")
    }
    rhs_site_import_result(list(status = "success", messages = c(
      message,
      "RHS records are mapped through rhs_survey_id; RHS site IDs are not used as survey IDs."
    )))
    workflow_complete_artifact(
      "rhs_input",
      "RHS import",
      sprintf("Imported %d mapped RHS record(s).", nrow(output_data))
    )
    showNotification(message, type = "message")
  })

  output$wq_site_import_status <- renderUI({
    format_validation_message(wq_site_import_result())
  })

  output$rhs_site_import_status <- renderUI({
    format_validation_message(rhs_site_import_result())
  })

  output$wq_site_import_preview <- DT::renderDataTable({
    req(wq_site_import_data())
    wq_site_import_data()
  }, rownames = FALSE, options = list(scrollX = TRUE, pageLength = 10))

  output$rhs_site_import_preview <- DT::renderDataTable({
    req(rhs_site_import_data())
    rhs_site_import_data()
  }, rownames = FALSE, options = list(scrollX = TRUE, pageLength = 10))

  output$download_mapped_wq_csv <- downloadHandler(
    filename = function() "mapped_wq_data.csv",
    content = function(file) {
      data <- mapped_wq_plot_data()
      validate(need(!is.null(data) && nrow(data) > 0, "No mapped WQ data are available to download."))
      safe_server_file_operation(
        "mapped WQ CSV",
        function() readr::write_csv(data, file)
      )
    },
    contentType = "text/csv"
  )

  output$download_mapped_rhs_csv <- downloadHandler(
    filename = function() "mapped_rhs_data.csv",
    content = function(file) {
      data <- mapped_rhs_plot_data()
      validate(need(!is.null(data) && nrow(data) > 0, "No mapped RHS data are available to download."))
      safe_server_file_operation(
        "mapped RHS CSV",
        function() readr::write_csv(data, file)
      )
    },
    contentType = "text/csv"
  )

  observeEvent(input$build_wq_contract_summary, {
    wq_data <- mapped_wq_plot_data()
    biology_data <- tryCatch(
      isolate(biol_all()),
      error = function(e) NULL
    )
    result <- build_wq_contract_summary(wq_data, biology_data)
    wq_contract_summary_result(result)
    if (result$status %in% c("success", "warning") && !is.null(result$data) && nrow(result$data) > 0) {
      workflow_status <- if (identical(result$status, "warning")) "warning" else "complete"
      workflow_set_artifact(
        "wq_input",
        workflow_status,
        data_source = "Contracted WQ summary",
        history_summary = sprintf(
          "Built WQ summary for %d biology record(s): 0180 orthophosphate mean, 0111 ammonia P90, DO pending OPEN-02.",
          nrow(result$data)
        ),
        invalidate_downstream = TRUE
      )
    }

    notification_type <- switch(
      result$status,
      success = "message",
      warning = "warning",
      error = "error",
      "message"
    )
    showNotification(paste(result$messages, collapse = " "), type = notification_type)
  })

  output$wq_contract_summary_status <- renderUI({
    result <- wq_contract_summary_result()
    format_validation_message(result)
  })

  output$wq_contract_summary_table <- DT::renderDataTable({
    result <- wq_contract_summary_result()
    req(!is.null(result$data), nrow(result$data) > 0)
    result$data
  }, rownames = FALSE, options = list(scrollX = TRUE, pageLength = 10))

  output$wq_contract_summary_plot <- renderPlot({
    plot_result <- build_wq_contract_summary_plot(wq_contract_summary_result()$data)
    validate(need(!is.null(plot_result$plot), plot_result$message))
    safe_server_plot("WQ summary", function() plot_result$plot)
  })

  output$wq_contract_summary_provenance <- renderUI({
    data <- wq_contract_summary_result()$data
    req(!is.null(data), nrow(data) > 0)
    provenance <- unique(stats::na.omit(data$wq_summary_provenance))
    req(length(provenance) > 0)
    tags$div(
      class = "upload-status upload-status-info",
      tags$strong("WQ summary provenance"),
      tags$ul(lapply(provenance, tags$li))
    )
  })

  output$download_wq_contract_summary_csv <- downloadHandler(
    filename = function() "wq_contract_summary.csv",
    content = function(file) {
      data <- wq_contract_summary_result()$data
      validate(need(!is.null(data) && nrow(data) > 0, "No WQ contract summary is available to download."))
      safe_server_file_operation(
        "WQ contract summary CSV",
        function() readr::write_csv(data, file)
      )
    },
    contentType = "text/csv"
  )

  mapped_wq_plot_data <- reactive({
    imported <- wq_site_import_data()
    if (!is.null(imported) && nrow(imported) > 0) {
      return(imported)
    }

    uploaded <- wq_upload()$data
    if (is.null(uploaded) || nrow(uploaded) == 0) {
      return(NULL)
    }

    parsed <- parse_site_metadata(input$meta_paste)
    if (is.null(parsed$error) && !is.null(parsed$data) && all(c("biol_site_id", "wq_site_id") %in% names(parsed$data)) && "wq_site_id" %in% names(uploaded)) {
      mapped <- map_wq_records_to_biology(uploaded, parsed$data)
      if (!is.null(mapped) && nrow(mapped) > 0) {
        return(mapped)
      }
    }

    if (all(c("biol_site_id", "wq_site_id") %in% names(uploaded))) {
      return(uploaded)
    }

    NULL
  })

  mapped_rhs_plot_data <- reactive({
    imported <- rhs_site_import_data()
    if (!is.null(imported) && nrow(imported) > 0) {
      return(imported)
    }

    uploaded <- rhs_upload()$data
    if (is.null(uploaded) || nrow(uploaded) == 0) {
      return(NULL)
    }

    uploaded <- tryCatch(
      normalise_rhs_records(uploaded),
      error = function(e) uploaded
    )

    parsed <- parse_site_metadata(input$meta_paste)
    if (is.null(parsed$error) && !is.null(parsed$data) && all(c("biol_site_id", "rhs_survey_id") %in% names(parsed$data)) && "rhs_survey_id" %in% names(uploaded)) {
      mapped <- map_rhs_records_to_biology(uploaded, parsed$data)
      if (!is.null(mapped) && nrow(mapped) > 0) {
        return(mapped)
      }
    }

    if (all(c("biol_site_id", "rhs_survey_id") %in% names(uploaded))) {
      return(uploaded)
    }

    NULL
  })

  output$wq_plot_controls <- renderUI({
    data <- mapped_wq_plot_data()
    numeric_cols <- wq_rhs_numeric_columns(data)
    date_cols <- wq_rhs_date_columns(data)
    group_cols <- if (is.null(data)) character(0) else names(data)
    default_group <- if ("biol_site_id" %in% group_cols) "biol_site_id" else wq_rhs_default_group(data)
    default_numeric <- if (length(numeric_cols) > 0) numeric_cols[[1]] else character(0)
    default_date <- if (length(date_cols) > 0) date_cols[[1]] else character(0)

    tagList(
      selectInput("wq_numeric_var", "WQ numeric variable", choices = numeric_cols, selected = default_numeric),
      selectInput("wq_date_col", "WQ date column", choices = date_cols, selected = default_date),
      selectInput("wq_group_col", "WQ grouping column", choices = group_cols, selected = default_group)
    )
  })

  output$rhs_plot_controls <- renderUI({
    data <- mapped_rhs_plot_data()
    numeric_cols <- wq_rhs_numeric_columns(data)
    categorical_cols <- wq_rhs_categorical_columns(data)
    variable_cols <- if (identical(input$rhs_plot_type, "Categorical count/bar plot")) categorical_cols else numeric_cols
    if (identical(input$rhs_plot_type, "Record count by biological site ID")) {
      variable_cols <- character(0)
    }
    group_cols <- if (is.null(data)) character(0) else names(data)
    default_group <- if ("biol_site_id" %in% group_cols) "biol_site_id" else wq_rhs_default_group(data)
    default_variable <- if (length(variable_cols) > 0) variable_cols[[1]] else character(0)

    tagList(
      if (!identical(input$rhs_plot_type, "Record count by biological site ID")) {
        selectInput("rhs_variable", "RHS variable", choices = variable_cols, selected = default_variable)
      },
      selectInput("rhs_group_col", "RHS grouping column", choices = group_cols, selected = default_group)
    )
  })

  current_wq_plot <- reactive({
    result <- build_wq_plot(
      data = mapped_wq_plot_data(),
      plot_type = input$wq_plot_type,
      numeric_var = input$wq_numeric_var,
      date_col = input$wq_date_col,
      group_col = input$wq_group_col
    )
    validate(need(!is.null(result$plot), result$message))
    safe_server_plot("WQ", function() result$plot)
  })

  current_rhs_plot <- reactive({
    result <- build_rhs_plot(
      data = mapped_rhs_plot_data(),
      plot_type = input$rhs_plot_type,
      variable = input$rhs_variable,
      group_col = input$rhs_group_col
    )
    validate(need(!is.null(result$plot), result$message))
    safe_server_plot("RHS", function() result$plot)
  })

  output$wq_mapped_plot <- renderPlot({
    current_wq_plot()
  })

  output$rhs_mapped_plot <- renderPlot({
    current_rhs_plot()
  })

  output$download_wq_plot <- downloadHandler(
    filename = function() "mapped_wq_plot.png",
    content = function(file) {
      plot <- current_wq_plot()
      safe_server_file_operation(
        "mapped WQ plot",
        function() ggplot2::ggsave(file, plot = plot, width = 10, height = 5, dpi = 150)
      )
    },
    contentType = "image/png"
  )

  output$download_rhs_plot <- downloadHandler(
    filename = function() "mapped_rhs_plot.png",
    content = function(file) {
      plot <- current_rhs_plot()
      safe_server_file_operation(
        "mapped RHS plot",
        function() ggplot2::ggsave(file, plot = plot, width = 10, height = 5, dpi = 150)
      )
    },
    contentType = "image/png"
  )

  local_inv_upload <- reactive({
    if (is.null(input$local_inv_csv)) {
      return(list(data = NULL, validation = list(status = "info", messages = "No local invertebrate CSV uploaded yet.")))
    }

    read_result <- read_dashboard_csv(input$local_inv_csv$datapath, "Local invertebrate")
    validation <- if (identical(read_result$status, "success")) {
      validate_local_invertebrate(read_result$data)
    } else {
      list(status = read_result$status, messages = read_result$messages)
    }

    list(data = read_result$data, validation = validation)
  })

  local_flow_upload <- reactive({
    if (is.null(input$local_flow_csv)) {
      return(list(data = NULL, validation = list(status = "info", messages = "No local flow CSV uploaded yet.")))
    }

    read_result <- read_dashboard_csv(input$local_flow_csv$datapath, "Local flow")
    validation <- if (identical(read_result$status, "success")) {
      validate_local_flow(read_result$data)
    } else {
      list(status = read_result$status, messages = read_result$messages)
    }

    data <- if (validation$status %in% c("success", "warning")) validation$data else read_result$data
    list(data = data, validation = validation)
  })

  observeEvent(local_inv_upload(), {
    upload <- local_inv_upload()
    req(!is.null(upload$data), nrow(upload$data) > 0L)
    req(upload$validation$status %in% c("success", "warning"))
    workflow_set_artifact(
      "biology_input",
      if (identical(upload$validation$status, "warning")) "warning" else "complete",
      data_source = "Local invertebrate file",
      history_summary = "Validated local invertebrate upload.",
      invalidate_downstream = TRUE
    )
  })

  observeEvent(local_flow_upload(), {
    upload <- local_flow_upload()
    req(local_flow_is_operational(upload), !is.null(upload$data), nrow(upload$data) > 0L)
    workflow_set_artifact(
      "flow_input",
      if (identical(upload$validation$status, "warning")) "warning" else "complete",
      data_source = "Local Flow file",
      history_summary = "Validated local Flow upload.",
      invalidate_downstream = TRUE
    )
  })

  observeEvent(input$local_flow_csv, {
    invalidate_flow_derived_state(reset_external = TRUE)
  }, ignoreNULL = FALSE, ignoreInit = FALSE, priority = 200)

  observeEvent(input$local_inv_csv, {
    workflow_reset_artifact(
      "biology_input",
      "The Local Biology source changed.",
      "Validate the current Local Biology file."
    )
  }, ignoreNULL = FALSE, ignoreInit = FALSE, priority = 200)

  observeEvent(input$site_metadata_csv, {
    current_site_metadata(NULL)
    metadata_result(list(
      data = NULL,
      flow_input_provenance = NULL,
      validation = list(
        status = "error",
        messages = "The site metadata replacement is being validated."
      )
    ))
    workflow_reset_artifact(
      "site_mapping",
      "The site metadata CSV changed.",
      "Complete validation of the replacement site metadata CSV."
    )
    invalidate_flow_derived_state(reset_external = TRUE)
  }, ignoreNULL = FALSE, ignoreInit = FALSE, priority = 200)

  observeEvent(input$meta_paste, {
    current_site_metadata(NULL)
    metadata_result(list(
      data = NULL,
      flow_input_provenance = NULL,
      validation = list(
        status = "error",
        messages = "The pasted site metadata replacement is being validated."
      )
    ))
    workflow_reset_artifact(
      "site_mapping",
      "The pasted site metadata changed.",
      "Complete validation of the pasted site metadata."
    )
    invalidate_flow_derived_state(reset_external = TRUE)
  }, ignoreNULL = FALSE, ignoreInit = TRUE, priority = 200)

  observeEvent(input$date_range_flow, {
    if (!local_flow_is_operational(local_flow_upload())) {
      invalidate_flow_derived_state(reset_external = TRUE)
    }
  }, ignoreNULL = FALSE, ignoreInit = FALSE, priority = 200)

  observeEvent(input$import_flow, {
    if (!local_flow_is_operational(local_flow_upload())) {
      invalidate_flow_derived_state(reset_external = TRUE)
      if (!workflow_artifact_is_current("site_mapping")) {
        external_import_requested_revision(NULL)
        workflow_block_artifact(
          "flow_input",
          "Current site metadata with valid flow_site_id values are required before importing Flow data.",
          "Correct and validate the site metadata, then import Flow data again."
        )
        return()
      }
      external_import_requested_revision(isolate(flow_source_revision()))
      workflow_begin_artifact("flow_input", "Complete the external Flow import.")
    } else {
      external_import_requested_revision(NULL)
    }
  }, ignoreInit = FALSE, priority = 100)

  output$local_inv_status <- renderUI({
    format_validation_message(local_inv_upload()$validation)
  })

  output$local_flow_status <- renderUI({
    format_validation_message(local_flow_upload()$validation)
  })

  output$local_inv_preview <- DT::renderDataTable({
    req(local_inv_upload()$data)
    head(local_inv_upload()$data, 20)
  }, rownames = FALSE, options = list(scrollX = TRUE, pageLength = 10))

  # --- Filtering + exclusion log for local invertebrate data ----------------
  filtered_inv <- reactive({
    req(local_inv_upload()$data)
    filter_records(local_inv_upload()$data)
  })

  exclusion_log_data <- reactive({
    build_exclusion_log(filtered_inv())
  })

  output$exclusion_log_status <- renderUI({
    format_validation_message(exclusion_log_summary(exclusion_log_data()))
  })

  output$exclusion_log_table <- DT::renderDataTable({
    exclusion_log_data()
  }, rownames = FALSE, options = list(scrollX = TRUE, pageLength = 10))

  output$download_exclusion_log <- downloadHandler(
    filename = function() paste0("exclusion_log_", format(Sys.Date(), "%Y%m%d"), ".csv"),
    content = function(file) {
      data <- exclusion_log_data()
      safe_server_file_operation(
        "exclusion log CSV",
        function() utils::write.csv(data, file, row.names = FALSE)
      )
    }
  )

  output$local_flow_preview <- DT::renderDataTable({
    req(local_flow_upload()$data)
    head(local_flow_upload()$data, 20)
  }, rownames = FALSE, options = list(scrollX = TRUE, pageLength = 10))
  
  ### displaying ----
  output$table1 <- function() {
    metadata_data <- metadata()
    validation_error <- validate_dashboard_site_metadata(metadata_data)
    validate(need(is.null(validation_error), validation_error))

    metadata_data %>% kable("html") %>% kable_styling("striped", full_width = F) %>%
      scroll_box(height = "250px")
  }
  
  ## Biology data ----
  ### importing ----
  biol_data <- eventReactive(biology_import_request(), {
    req(!is.null(biology_import_request()))
    biol_sites <- as.character(metadata()$biol_site_id)
    result <- safe_external_import(
      function() {
        import_inv(
          source = "parquet",
          sites = biol_sites,
          start_date = input$date_range_biol[1],
          end_date = input$date_range_biol[2]
        )
      },
      required_columns = "biol_site_id"
    )
    if (!identical(result$status, "success")) {
      record_external_import_diagnostic("biology", result)
      message <- paste(
        "Biology data could not be retrieved or processed.",
        "Check the selected sites and date range, then try again."
      )
      workflow_fail_external_import(
        "biology_input",
        message,
        "Check the Biology site IDs and date range, then try the import again."
      )
      validate(need(FALSE, message))
    }
    result$data
  })

  observeEvent(biol_data(), {
    imported <- biol_data()
    req(nrow(imported) > 0L)
    workflow_complete_artifact(
      "biology_input",
      "Biology import",
      sprintf("Imported %d Biology record(s).", nrow(imported))
    )
  })
  
  
  #### warning message for unID'd sites----
  observeEvent(input$import_inv, {
    
    missed_biol_sites <- metadata() %>% filter(!biol_site_id %in% biol_data()$biol_site_id) %>% select(biol_site_id)
    missed_biol_sites_text <- gsub("c\\(|\\)",'', missed_biol_sites)
    
    if(length(missed_biol_sites > 0)) {
      
      shinyalert(paste("Biology data could not be found for site(s)", paste(missed_biol_sites_text, collapse = ",")), 
                 type = "warning")
    } 
    
  })
  
  ### displaying ----
  output$biol_table <- function() {
    biol_data() %>% kable("html") %>% kable_styling("striped", full_width = F) %>% 
      scroll_box(height = "500px")
  }
  
  ## Environmental data ----
  ### importing ----
  env_data <- eventReactive(environment_import_request(), {
    req(!is.null(environment_import_request()))
    biol_sites <- as.character(metadata()$biol_site_id)
    result <- safe_external_import(
      function() {
        import_env(sites = biol_sites) %>%
          mutate(across(BOULDERS_COBBLES:SILT_CLAY, ~tidyr::replace_na(., 0)))
      },
      required_columns = "biol_site_id"
    )
    if (!identical(result$status, "success")) {
      record_external_import_diagnostic("environment", result)
      message <- paste(
        "Environmental data could not be retrieved or processed.",
        "Check the selected sites, then try again."
      )
      workflow_fail_external_import(
        "environment_input",
        message,
        "Check the Biology site IDs, then try the Environmental import again."
      )
      validate(need(FALSE, message))
    }
    result$data
  })

  observeEvent(env_data(), {
    imported <- env_data()
    req(nrow(imported) > 0L)
    workflow_complete_artifact(
      "environment_input",
      "Environmental import",
      sprintf("Imported %d environmental record(s).", nrow(imported))
    )
  })
  
  #### warning message for unID'd sites----
  observeEvent(input$import_env, {
    
    missed_env_sites <- metadata() %>% filter(!biol_site_id %in% env_data()$biol_site_id) %>% select(biol_site_id)
    missed_env_sites_text <- gsub("c\\(|\\)",'', missed_env_sites)
    
    if(length(missed_env_sites > 0)) {
      
      shinyalert(paste("Environmental base data could not be found for site(s)", paste(missed_env_sites_text, collapse = ",")), 
                 type = "warning")
    } 
    
  })
  
  ### displaying ----
  
  showEnvplot <- reactiveVal(TRUE)
  
  observeEvent(input$env_data_display, {
    showEnvplot(!showEnvplot())
  })
  
  output$env_tab_pca <- renderUI({
    if (showEnvplot()){
      plotOutput("env_fig")
    }
    else{
      tableOutput("env_table")
    }
  })
  
  #### render table ----
  output$env_table <- function() {
    env_data() %>% kable("html") %>% kable_styling("striped", full_width = F) %>% 
      scroll_box(height = "500px")
  }
  
  #### render PCA ----
  output$env_fig <- renderPlot({
    safe_server_plot("Environmental PCA", function() {
      plot_sitepca_dash(env_data(), vars = c("ALTITUDE", "SLOPE", "WIDTH", "DEPTH",
                                             "BOULDERS_COBBLES", "PEBBLES_GRAVEL", "SILT_CLAY"),
                        eigenvectors = TRUE, label_by = "biol_site_id")
    })
  })
  
  
  ## Flow data ----
  ### importing ----
  external_flow_data <- eventReactive(input$import_flow, {
    req(identical(external_import_requested_revision(), flow_source_revision()))
    flow_sites <- as.character(metadata()$flow_site_id)
    flow_inputs <- as.character(metadata()$flow_input)

    result <- safe_external_import(
      function() {
        import_dashboard_flow(
          sites = flow_sites,
          inputs = flow_inputs,
          start_date = input$date_range_flow[1],
          end_date = input$date_range_flow[2]
        )
      },
      required_columns = c("flow_site_id", "date", "flow")
    )
    if (!identical(result$status, "success")) {
      record_external_import_diagnostic("flow", result)
      external_flow_loaded(FALSE)
      external_flow_revision(NULL)
      message <- paste(
        "Flow data could not be retrieved or processed.",
        "Check the selected sites, source and date range, then try again."
      )
      workflow_fail_external_import(
        "flow_input",
        message,
        "Check the Flow site IDs, source and date range, then try the import again."
      )
      validate(need(FALSE, message))
    }
    external_flow_loaded(TRUE)
    external_flow_revision(isolate(flow_source_revision()))
    result$data
  })

  observeEvent(external_flow_data(), {
    imported <- external_flow_data()
    req(nrow(imported) > 0L)
    workflow_complete_artifact(
      "flow_input",
      "HDE/NRFA Flow import",
      sprintf("Imported %d Flow record(s).", nrow(imported))
    )
  })

  flow_data <- reactive({
    local_flow <- local_flow_upload()
    if (local_flow_is_operational(local_flow)) {
      return(local_flow$data)
    }

    imported <- external_flow_data()
    req(isTRUE(external_flow_loaded()))
    req(identical(external_flow_revision(), flow_source_revision()))
    imported
  })
  
  
  #### warning message for unID'd sites----
  observeEvent(input$import_flow, {
    
    missed_flow_sites <- metadata() %>% filter(!flow_site_id %in% flow_data()$flow_site_id) %>% select(flow_site_id)
    missed_flow_sites_text <- gsub("c\\(|\\)",'', missed_flow_sites)
    
    if(length(missed_flow_sites > 0)) {
      
      shinyalert(paste("Flow data could not be found for station(s)", paste(missed_flow_sites_text, collapse = ",")), 
                 type = "warning")
    } 
    
  })
  
  ### displaying ----
  
  showHeatmap <- reactiveVal(TRUE)
  
  observeEvent(input$flow_data_display, {
    showHeatmap(!showHeatmap())
  })
  
  output$flow_heatmap <- renderUI({
    if (showHeatmap()){
      plotOutput("flow_fig", width = "920px", height = "560px")
    }
    else{
      tableOutput("flow_table")
    }
  })
  
  #### render table ----
  output$flow_table <- function() {
    plot_heatmap(data = flow_data(), x = "date", y = "flow_site_id", fill = "flow", dual = FALSE) %>% 
      pluck(3) %>%
      kable("html") %>% kable_styling("striped", full_width = F) %>% 
      scroll_box(height = "300px")
  }
  
  #### render heatmap ----
  output$flow_fig <- renderPlot({
    safe_server_plot("Flow heatmap", function() {
      plot_heatmap_dash(data = flow_data(), x = "date", y = "flow_site_id", fill = "flow", dual = FALSE) %>%
        pluck(1) %>% grid.arrange() %>% print()
    })
  })
  
  
  ## Map of sites ----
  
  map_data <- reactive({
    req(input$import_env)
    
    temp.eastnorths <- osg_parse(env_data()$NGR_10_FIG, coord_system = "WGS84") %>% as.data.frame()
    
    cbind(env_data(), temp.eastnorths) %>%
      dplyr::select(AGENCY_AREA, WATER_BODY, CATCHMENT, biol_site_id, lat, lon)
    
  })
  
  output$map0 <- renderLeaflet({
    leaflet() %>% 
      addTiles() %>% 
      addCircleMarkers(data = map_data(), ~unique(lon), ~unique(lat), 
                       layerId = ~unique(biol_site_id), popup = ~paste(unique(biol_site_id), "<br>", 
                                                                       WATER_BODY))
  })
  
  
  # INVERT DATA PROCESSING ----
  
  ## RICT predictions ----
  ### calculating ----
  predict_data <- eventReactive(rict_request(), {
    req(!is.null(rict_request()))
    req(workflow_artifact_is_current("environment_input"))
    env_data <- env_data()
    
    keeps <- c("biol_site_id", "SEASON", "TL2_WHPT_ASPT_AbW_DistFam", "TL2_WHPT_NTAXA_AbW_DistFam",
               "TL3_LIFE_Fam_DistFam", "TL3_PSI_Fam")
    
    predict_indices(env_data = env_data, file_format = "EDE", all_indices = TRUE) %>%
      select(dplyr::all_of(keeps)) %>% dplyr::rename(Season = SEASON) %>%
      dplyr::mutate(Season = case_when(Season == 1 ~ "Spring", Season == 2 ~ "Summer",
                                       Season == 3 ~ "Autumn"))

  })

  observeEvent(predict_data(), {
    predictions <- predict_data()
    req(nrow(predictions) > 0L)
    workflow_complete_artifact(
      "processed_environment",
      "RICT processing",
      sprintf("Generated predictions for %d environmental record(s).", nrow(predictions))
    )
  })
  
  #### current Environmental prerequisite state ----
  env_data_exist <- reactiveVal(FALSE)
  
  observe({
    req(env_data())
    env_data_exist(TRUE)
  })
  
  #### warning message for incomplete env data ----
  observeEvent(predict_data(), {
    
    if(sum(is.na(env_data()$ALTITUDE),	
           is.na(env_data()$SLOPE),	
           is.na(env_data()$DISCHARGE),	
           is.na(env_data()$DIST_FROM_SOURCE),
           is.na(env_data()$WIDTH),	
           is.na(env_data()$DEPTH),	
           is.na(env_data()$ALKALINITY),	
           is.na(env_data()$BOULDERS_COBBLES),	
           is.na(env_data()$PEBBLES_GRAVEL),	
           is.na(env_data()$SAND),	
           is.na(env_data()$SILT_CLAY)) > 0) {
      
      shinyalert(title = "One or more sites are missing the complete set of environmental base data required for RICT predictions",
                 type = "warning")
    } 
    
  })
  
  ### displaying ----
  output$predictions_table <- DT::renderDataTable(
    server=FALSE,
    datatable(
      predict_data(),
      options = list(
        scrollY = "600px",
        scrollX = TRUE,
        scrollCollapse = TRUE,
        dom = 'Blrtip',
        buttons =
          list('copy', list(
            extend = 'collection',
            buttons = list(
              list(extend = 'csv', filename = "RICT_predictions"),
              list(extend = 'excel', filename = "RICT_predictions"),
              list(extend = 'pdf', filename = "RICT_predictions")),
            text = 'Download'))
      ),
      extensions = "Buttons"
    )
  )
  
  
  ## O:E ratios ----
  ### calculating ----
  biol_all <- eventReactive(oe_request(), {
    req(!is.null(oe_request()))
    req(workflow_artifact_is_current("biology_input"))
    req(workflow_artifact_is_current("processed_environment"))
    
    predict_data <- predict_data()
    env_data <- env_data()
    biol_data_2 <- biol_data() %>% distinct(biol_site_id, Year, Season, .keep_all = TRUE)
    biol_data_2 <- dplyr::left_join(biol_data_2, predict_data, by = c("biol_site_id", "Season"))
    biol_data_2 <- dplyr::left_join(biol_data_2, env_data, by = "biol_site_id")
    
    biol_data_2 %>%
      mutate(WHPT_ASPT_O = WHPT_ASPT, WHPT_ASPT_E = TL2_WHPT_ASPT_AbW_DistFam, WHPT_ASPT_OE = WHPT_ASPT_O/WHPT_ASPT_E,
             WHPT_NTAXA_O = WHPT_N_TAXA, WHPT_NTAXA_E = TL2_WHPT_NTAXA_AbW_DistFam, WHPT_NTAXA_OE = WHPT_NTAXA_O/WHPT_NTAXA_E,
             LIFE_F_O = LIFE_FAMILY_INDEX, LIFE_F_E = TL3_LIFE_Fam_DistFam, LIFE_F_OE = LIFE_F_O/LIFE_F_E,
             PSI_O = PSI_FAMILY_SCORE, PSI_E = TL3_PSI_Fam, PSI_OE = PSI_O/PSI_E, date = SAMPLE_DATE) %>% 
      select(biol_site_id, sample_id = SAMPLE_ID, date, Month, Year, Season, NGR_10_FIG,
             WFD_WATERBODY_ID:CALCIUM, WHPT_ASPT_O:PSI_OE)
    

  }, ignoreInit = TRUE)

  observeEvent(biol_all(), {
    result <- biol_all()
    req(nrow(result) > 0L)
    workflow_complete_artifact(
      "processed_biology",
      "Biology processing",
      sprintf("Processed %d Biology record(s).", nrow(result))
    )
    workflow_complete_artifact(
      "oe_result",
      "O:E calculation",
      sprintf("Calculated O:E outputs for %d Biology record(s).", nrow(result))
    )
  })
  
  #### current Biology prerequisite state ----
  
  biol_data_exist <- reactiveVal(FALSE)
  
  observe({
    req(biol_data())
    biol_data_exist(TRUE)
  })
  
  #### warning message for incomplete biol data ----
  observeEvent(biol_all(), {
    
    if(sum(is.na(biol_all()$WHPT_ASPT_O),	
           is.na(biol_all()$LIFE_F_O),	
           is.na(biol_all()$WHPT_NTAXA_O),	
           is.na(biol_all()$PSI_O)) > 0) {
      
      shinyalert(title = "One or more sites are missing observed WHPT, LIFE and/or PSI scores required for O:E calculations",
                 type = "warning")
    } 
    
  })
  
  #### current RICT prerequisite state ----
  
  predict_data_exist <- reactiveVal(FALSE)
  
  observe({
    req(predict_data())
    predict_data_exist(TRUE)
  })
  
  ### displaying ----
  output$OE_table <- DT::renderDataTable(
    server=FALSE,
    datatable(
      biol_all(),
      options = list(
        scrollY = "400px",
        scrollX = TRUE,
        scrollCollapse = TRUE,
        dom = 'Blrtip',
        buttons =
          list('copy', list(
            extend = 'collection',
            buttons = list(
              list(extend = 'csv', filename = "biol_data_O:E"),
              list(extend = 'excel', filename = "biol_data_O:E"),
              list(extend = 'pdf', filename = "biol_data_O:E")),
            text = 'Download'))
      ),
      extensions = "Buttons"
    )
  )
  
  # FLOW DATA PROCESSING ----
  ## Flow imputation----
  ### donor mapping ----
  #### upload ----
  donor_mapping_result <- reactive({
    donor_text <- paste(input$donor_mapping_paste, collapse = "\n")
    parse_donor_mapping(donor_text)
  })

  donor_mapping <- reactive({
    result <- donor_mapping_result()
    validate(need(is.null(result$error), result$error))
    result$data
  })
  
  #### display ----
  output$table2 <- function() {
    
  ##### error message for incorrect flow site IDs ----
    
    flow_sites_list <- metadata()$flow_site_id
    sites_req_donor <- donor_mapping()[,1]
    match <- sites_req_donor %in% flow_sites_list
    
    validate(
      need(!str_contains(match, "FALSE"), "Donee flow sites not detected in original metadata")
    )
    
    donor_mapping() %>% kable("html") %>% kable_styling("striped", full_width = F) %>% 
      scroll_box(height = "150px")
  }
  
  ### donor site list ----
  #### upload ----
  donor_list_result <- reactive({
    donor_text <- paste(input$donor_list_paste, collapse = "\n")
    parse_donor_site_list(donor_text)
  })

  donor_list <- reactive({
    result <- donor_list_result()
    validate(need(is.null(result$error), result$error))
    result$data
  })
  
  #### display ----
  output$table3 <- function() {
    
  ##### error messages for incorrect data formats ----
    donor_req_col_ID <- 'flow_site_id'
    donor_sites_col_names <- colnames(donor_list())
    
    donor_mapping_sites <- donor_mapping()[,2]
    metadata_sites <- metadata()$flow_site_id
    donor_list_sites <- donor_list()$flow_site_id
    all_flow_sites <- c(metadata_sites, donor_list_sites)
    
    validate(
      need(donor_req_col_ID %in% donor_sites_col_names, "You don't have a correctly named list of flow site IDs"),
      need(all(donor_mapping_sites %in% all_flow_sites), "One or more named donor sites are absent from both original metadata and additional donor list")
    )
    
    donor_list() %>% kable("html") %>% kable_styling("striped", full_width = F) %>% 
      scroll_box(height = "150px")
  }
  
  ### impute flow data ----
  #### get extra flow data if needed ----
  donor_flow_import_data <- reactiveVal(NULL)
  donor_flow_import_running <- reactiveVal(FALSE)
  donor_flow_import_result <- reactiveVal(list(
    status = "info",
    messages = "Add donor sites, then import the additional Flow data if required."
  ))
  import_donor_flow_success <- reactiveVal(FALSE)

  flow_data_extra <- reactive({
    req(donor_flow_import_data())
    donor_flow_import_data()
  })

  observeEvent(input$import_donor_flow, {
    import_donor_flow_success(FALSE)
    donor_flow_import_data(NULL)
    parsed <- donor_list_result()
    if (!is.null(parsed$error)) {
      donor_flow_import_result(list(status = "error", messages = parsed$error))
      showNotification(parsed$error, type = "error", duration = 10)
      return()
    }
    if (!workflow_artifact_is_current("flow_input")) {
      message <- paste(
        "Current Flow data are required before importing additional donor Flow data.",
        "Import or validate Flow data, then try again."
      )
      donor_flow_import_result(list(status = "error", messages = message))
      showNotification(message, type = "error", duration = 10)
      return()
    }

    donor_flow_import_running(TRUE)
    on.exit(donor_flow_import_running(FALSE), add = TRUE)
    donor_sites <- as.character(parsed$data$flow_site_id)
    donor_inputs <- as.character(parsed$data$flow_input)
    import_result <- safe_external_import(
      function() {
        import_dashboard_flow(
          sites = donor_sites,
          inputs = donor_inputs,
          start_date = input$date_range_flow[1],
          end_date = input$date_range_flow[2]
        )
      },
      required_columns = c("flow_site_id", "date", "flow")
    )
    if (!identical(import_result$status, "success")) {
      record_external_import_diagnostic("additional_donor_flow", import_result)
      message <- paste(
        "Additional donor Flow data could not be retrieved or processed.",
        "Check the donor site list, source and date range, then try again."
      )
      donor_flow_import_result(list(status = "error", messages = message))
      showNotification(message, type = "error", duration = 10)
      return()
    }

    combined <- bind_rows(flow_data(), import_result$data)
    donor_flow_import_data(combined)
    import_donor_flow_success(TRUE)
    donor_flow_import_result(list(
      status = "success",
      messages = sprintf("Imported additional Flow data for %d donor site(s).", length(unique(import_result$data$flow_site_id)))
    ))
    shinyalert(title = "Additional flow data successfully imported", type = "success")
  })
  
  #### warning message for unID'd donor sites ----
  observeEvent(flow_data_extra(), {
    missed_donor_sites <- donor_list() %>% filter(!flow_site_id %in% flow_data_extra()$flow_site_id) %>% select(flow_site_id)
    missed_donor_sites_text <- gsub("c\\(|\\)",'', missed_donor_sites)
    
    if(length(missed_donor_sites > 0)) {
      
      shinyalert(paste("Flow data could not be found for donor station(s)", paste(missed_donor_sites_text, collapse = ",")), 
                 type = "warning")
    } 
    
  })
  
  #### run imputation ----
  
  flow_data_forimp <- reactive({
    if (isTRUE(import_donor_flow_success())) {
      flow_data_extra()
    } else {
      flow_data()
    }
  })

  flow_imputation_running <- reactiveVal(FALSE)
  flow_imputation_result <- reactiveVal(list(
    status = "info",
    messages = "Add a donor mapping, then run Flow imputation.",
    data = NULL
  ))

  observeEvent(input$impute_flow, {
    parsed <- donor_mapping_result()
    if (!is.null(parsed$error)) {
      flow_imputation_result(list(status = "error", messages = parsed$error, data = NULL))
      showNotification(parsed$error, type = "error", duration = 10)
      return()
    }
    if (!workflow_artifact_is_current("flow_input")) {
      message <- "Current Flow data are required before imputation. Import or validate Flow data, then try again."
      flow_imputation_result(list(status = "error", messages = message, data = NULL))
      showNotification(message, type = "error", duration = 10)
      return()
    }

    mapping <- parsed$data
    available_sites <- unique(c(metadata()$flow_site_id, flow_data_forimp()$flow_site_id))
    if (!all(mapping[[1L]] %in% metadata()$flow_site_id) || !all(mapping[[2L]] %in% available_sites)) {
      message <- paste(
        "The donor mapping contains receiving or donor Flow sites that are not available.",
        "Correct the donor mapping or import the required donor sites, then try again."
      )
      flow_imputation_result(list(status = "error", messages = message, data = NULL))
      showNotification(message, type = "error", duration = 10)
      return()
    }

    flow_imputation_running(TRUE)
    on.exit(flow_imputation_running(FALSE), add = TRUE)
    imputation <- safe_external_import(
      function() {
        impute_flow(
          flow_data_forimp(),
          site_col = "flow_site_id",
          date_col = "date",
          flow_col = "flow",
          method = "equipercentile",
          donor = as.data.frame(mapping)
        )
      },
      required_columns = c("flow_site_id", "date", "flow")
    )
    if (!identical(imputation$status, "success")) {
      record_external_import_diagnostic("flow_imputation", imputation)
      message <- paste(
        "Flow imputation could not be completed from the donor mapping.",
        "Check the mapping and available donor Flow data, then try again."
      )
      flow_imputation_result(list(status = "error", messages = message, data = NULL))
      showNotification(message, type = "error", duration = 10)
      return()
    }
    flow_imputation_result(list(
      status = "success",
      messages = "Flow imputation completed successfully.",
      data = imputation$data
    ))
  })

  flow_data_imputed <- reactive({
    result <- flow_imputation_result()
    validate(need(identical(result$status, "success"), result$messages))
    result$data
  })
  
  #### displaying ----
  
  showHeatmapimp <- reactiveVal(TRUE)
  
  observeEvent(input$imp_flow_data_display, {
    showHeatmapimp(!showHeatmapimp())
  })
  
  output$flow_heatmap_imp <- renderUI({
    if (showHeatmapimp()){
      plotOutput("flow_fig_imp", width = "920px", height = "560px")
    }
    else{
      tableOutput("flow_table_imp")
    }
  })
  
  ##### render table ----
  output$flow_table_imp <- function() {
    plot_heatmap(data = flow_data_imputed(), x = "date", y = "flow_site_id", fill = "flow", dual = FALSE) %>% 
      pluck(3) %>%
      kable("html") %>% kable_styling("striped", full_width = F) %>% 
      scroll_box(height = "300px")
  }
  
  ##### render heatmap ----
  output$flow_fig_imp <- renderPlot({
    safe_server_plot("Imputed Flow heatmap", function() {
      plot_heatmap_dash(data = flow_data_imputed(), x = "date", y = "flow_site_id", fill = "flow", dual = FALSE) %>%
        pluck(1) %>% grid.arrange() %>% print()
    })
  })
  
  
  ## Calculating flow stats ----
  
  ### run calculation ----
  
  flow_data_final <- reactive({
    result <- flow_imputation_result()
    if (identical(result$status, "success")) {
      result$data
    } else {
      flow_data()
    }
  })
  
  flow_stats_result <- eventReactive(input$calc_flow_stats, {
    if (!workflow_artifact_is_current("flow_input")) {
      return(NULL)
    }

    flow_data_final <- flow_data_final()
    
    flow_data_final$flow[flow_data_final$flow <= 0] <- NA
    
    result <- tryCatch(
      calc_flowstats(
        data = flow_data_final,
        site_col = "flow_site_id",
        date_col = "date",
        flow_col = "flow",
        win_width = paste(input$win_width_selector, "months"),
        win_step = paste(input$win_step_selector, "months")
      ),
      error = function(error) {
        flow_stats_revision(NULL)
        workflow_set_artifact(
          "flow_statistics",
          "failed",
          blocking_reason = paste(
            "Flow statistics could not be calculated from the current",
            "Flow data and window settings."
          ),
          next_action = paste(
            "Review Flow coverage, dates and values or change the window settings,",
            "then calculate Flow statistics again."
          )
        )
        showNotification(
          paste(
            "Flow statistics could not be calculated.",
            "Review the Flow data and window settings, then try again."
          ),
          type = "error",
          duration = NULL
        )
        NULL
      }
    )
    if (is.null(result)) {
      return(NULL)
    }
    flow_stats_revision(isolate(flow_source_revision()))
    result
  })

  flow_stats <- reactive({
    result <- flow_stats_result()
    req(!is.null(result))
    req(identical(flow_stats_revision(), flow_source_revision()))
    result
  })

  observeEvent(flow_stats(), {
    result <- flow_stats()
    req(length(result) > 0L)
    row_count <- sum(vapply(result, nrow, integer(1)))
    workflow_complete_artifact(
      "processed_flow",
      "Flow processing",
      "Prepared the current Flow source for statistics."
    )
    workflow_complete_artifact(
      "flow_statistics",
      "Flow-statistics calculation",
      sprintf("Generated %d Flow-statistic row(s).", row_count)
    )
  })
  
  
  #### error message for absent flow data ----
  
  flow_data_exist <- reactiveVal(FALSE)
  
  observe({
    req(flow_data())
    flow_data_exist(TRUE)
  })
  
  observeEvent(input$calc_flow_stats, {
    
    if(!flow_data_exist()) {
      
      shinyalert(title = "Please import flow data",
                 type = "error")
    } 
    
  })
  
  ### display table ----
  
  flowStatsDisplay <- reactiveVal(TRUE)
  
  observeEvent(input$flow_stats_display, {
    flowStatsDisplay(!flowStatsDisplay())
  })
  
  flow_stats_data <- reactive({
    if (flowStatsDisplay()){
      flow_stats() %>% pluck(2)
    }
    else{
      flow_stats() %>% pluck(1)
    }
  })
  
  output$flow_stats_table <- DT::renderDataTable(
    server=FALSE,
    datatable(
      flow_stats_data(),
      options = list(
        scrollY = "400px",
        scrollX = TRUE,
        scrollCollapse = TRUE,
        dom = 'Blrtip',
        buttons =
          list('copy', list(
            extend = 'collection',
            buttons = list(
              list(extend = 'csv', filename = "flow_stats"),
              list(extend = 'excel', filename = "flow_stats"),
              list(extend = 'pdf', filename = "flow_stats")),
            text = 'Download'))
      ),
      extensions = "Buttons"
    )
  )
  
  
  # JOIN HE DATA ----
  ## Run join calculations ----
  ### default join type for modelling ----
  
  join_data_result <- eventReactive(join_request(), {
    request <- join_request()
    req(request)
    req(identical(request$request_id, input$join_he))
    req(workflow_artifact_is_current("oe_result"))
    req(workflow_artifact_is_current("flow_statistics"))
    mapping <- metadata()[, c("biol_site_id", "flow_site_id")]
    mapping$biol_site_id <- as.character(mapping$biol_site_id)
    mapping$flow_site_id <- as.character(mapping$flow_site_id)
    
    flowstats_1 <- flow_stats() %>% pluck(1)
    
    result <- join_he(biol_data = biol_all(), flow_stats = flowstats_1, mapping = mapping,
                      lags = request$settings$lags, method = request$settings$method, join_type = "add_flows")
    req(nrow(result) > 0L)
    join_revision(request)
    result
    
  })

  join_data <- reactive({
    if (identical(active_join_source(), "checkpoint")) {
      return(req(processed_checkpoint_data()))
    }
    result <- join_data_result()
    revision <- join_revision()
    req(
      identical(revision, join_request()),
      identical(revision$flow_revision, flow_source_revision()),
      identical(
        revision$settings,
        normalise_join_settings(input$choose_lags, input$choose_join_method)
      )
    )
    result
  })

  output$processed_dataset_checkpoint_status <- renderUI({
    status <- processed_checkpoint_load_status()
    tags$div(
      class = paste("upload-status", paste0("upload-status-", status$status)),
      status$message
    )
  })

  output$processed_dataset_checkpoint_download <- renderUI({
    if (!workflow_artifact_is_current("processed_dataset_checkpoint")) {
      return(tags$p(
        class = "hint-text",
        "Download becomes available when the Joined HE dataset is current."
      ))
    }
    downloadButton(
      "download_processed_dataset_checkpoint",
      "Download checkpoint",
      class = "client-action-button",
      icon = shiny::icon("file-arrow-down", verify_fa = FALSE)
    )
  })

  build_current_enrichment_inputs <- function(joined_core, selected) {
    enrichments <- list()
    if ("wq" %in% selected) {
      enrichments$wq <- prepare_wq_enrichment_summary(
        wq_contract_summary_result()$data,
        joined_core
      )
    }
    if ("rhs" %in% selected) {
      enrichments$rhs <- prepare_rhs_enrichment_summary(
        mapped_rhs_plot_data(),
        joined_core
      )
    }
    enrichments
  }

  observeEvent(input$build_joined_enriched, {
    core <- isolate(join_data())
    req(!is.null(core), nrow(core) > 0L)
    selected <- isolate(selected_enrichments())

    result <- build_joined_enriched(
      joined_core = core,
      enrichments = build_current_enrichment_inputs(core, selected),
      selected_enrichments = selected,
      keys = list(wq = "sample_id", rhs = "biol_site_id")
    )
    joined_enriched_result(result)

    has_enriched <- !is.null(result$joined_enriched) && nrow(result$joined_enriched) > 0L
    if (has_enriched) {
      workflow_set_artifact(
        "joined_enriched",
        if (identical(result$status, "warning")) "warning" else "complete",
        data_source = "Optional WQ/RHS enrichment",
        history_summary = sprintf(
          "Created enriched Joined HE dataset with %d row(s); successful: %s; failed: %s.",
          nrow(result$joined_enriched),
          paste(result$provenance$successful_enrichments, collapse = ", "),
          paste(result$provenance$failed_enrichments, collapse = ", ")
        ),
        invalidate_downstream = TRUE
      )
    } else {
      updateCheckboxInput(session, "use_joined_enriched", value = FALSE)
      workflow_set_artifact(
        "joined_enriched",
        "not_ready",
        blocking_reason = result$messages,
        next_action = "Select WQ/RHS enrichment with usable mapped summary data, or continue with the core Joined HE dataset.",
        invalidate_downstream = TRUE
      )
    }

    notification_type <- if (has_enriched && identical(result$status, "success")) {
      "message"
    } else {
      "warning"
    }
    showNotification(result$messages, type = notification_type, duration = 8)
  }, ignoreInit = TRUE)

  output$joined_enrichment_status <- renderUI({
    result <- joined_enriched_result()
    messages <- c(
      result$messages,
      if (is.null(result$joined_enriched)) {
        "Core Joined HE dataset remains available."
      } else {
        sprintf(
          "Successful enrichment: %s. Failed enrichment: %s.",
          paste(result$provenance$successful_enrichments, collapse = ", "),
          paste(result$provenance$failed_enrichments, collapse = ", ")
        )
      }
    )
    format_validation_message(list(status = result$status, messages = messages))
  })

  current_joined_source <- reactive({
    derive_analysis_dataset(
      joined_core = join_data(),
      joined_enriched = joined_enriched_result()$joined_enriched,
      use_enriched = isTRUE(input$use_joined_enriched),
      filter_selection = NULL
    )
  })

  output$analysis_source_status <- renderUI({
    source <- current_joined_source()
    format_validation_message(list(
      status = "info",
      messages = sprintf(
        "Current analysis source: %s; rows: %d; fingerprint: %s.",
        source$source_dataset,
        source$source_rows,
        substr(source$source_fingerprint, 1L, 18L)
      )
    ))
  })

  output$joined_enriched_table <- DT::renderDataTable({
    result <- joined_enriched_result()
    req(!is.null(result$joined_enriched), nrow(result$joined_enriched) > 0)
    result$joined_enriched
  }, rownames = FALSE, options = list(scrollX = TRUE, pageLength = 10))

  observeEvent(input$use_joined_enriched, {
    req(join_data())
    if (isTRUE(input$use_joined_enriched) &&
        (is.null(joined_enriched_result()$joined_enriched) ||
         nrow(joined_enriched_result()$joined_enriched) == 0L)) {
      updateCheckboxInput(session, "use_joined_enriched", value = FALSE)
      showNotification(
        "No current enriched dataset is available. Continue with joined_core or build optional enrichment first.",
        type = "warning"
      )
      return()
    }

    source <- current_joined_source()
    analysis_filter_selection(new_filter_selection())
    workflow_complete_artifact(
      "filter_selection",
      "Default analysis selection",
      sprintf("Reset analysis selection after switching to %s.", source$source_dataset)
    )
    workflow_complete_artifact(
      "exclusion_log",
      "Exclusion and restore log",
      "No analysis records are currently excluded."
    )
    workflow_complete_artifact(
      "analysis_dataset",
      source$source_dataset,
      sprintf(
        "Created analysis selection version 0 from %s with %d row(s).",
        source$source_dataset,
        source$source_rows
      )
    )
    mark_hev_result_stale("The analysis dataset source changed.")
  }, ignoreInit = TRUE)

  output$download_processed_dataset_checkpoint <- downloadHandler(
    filename = function() {
      sprintf("joined-he-checkpoint-%s.rds", format(Sys.Date(), "%Y%m%d"))
    },
    content = function(file) {
      validate(need(
        workflow_artifact_is_current("processed_dataset_checkpoint"),
        "The Joined HE dataset is stale. Regenerate or reload it before downloading."
      ))
      source_manifest <- isolate(processed_checkpoint_manifest())
      provenance <- list(
        source = if (identical(isolate(active_join_source()), "checkpoint")) {
          "validated processed dataset checkpoint"
        } else {
          "dashboard biology-flow join"
        },
        join_settings = isolate(join_settings_used()),
        source_checkpoint_checksum = if (is.null(source_manifest)) {
          NULL
        } else {
          source_manifest$dataset_checksum
        }
      )
      dataset <- isolate(join_data())
      safe_server_file_operation(
        "processed dataset checkpoint",
        function() write_processed_dataset_checkpoint(
          dataset = dataset,
          path = file,
          provenance = provenance
        )
      )
    }
  )

  processed_checkpoint_user_error_message <- function(error) {
    raw24_safe_condition_message(
      error,
      safe_prefixes = "Processed dataset checkpoint",
      fallback = paste(
        "Processed dataset checkpoint could not be loaded.",
        "Use a checkpoint downloaded from this dashboard."
      )
    )
  }

  observeEvent(input$load_processed_dataset_checkpoint, {
    uploaded <- isolate(input$processed_dataset_checkpoint_file)
    if (is.null(uploaded) || is.null(uploaded$datapath)) {
      message <- "Choose a processed dataset checkpoint before loading."
      processed_checkpoint_load_status(list(status = "error", message = message))
      showNotification(message, type = "error")
      return()
    }

    tryCatch({
      checkpoint <- read_processed_dataset_checkpoint(uploaded$datapath)
      processed_checkpoint_data(checkpoint$dataset)
      processed_checkpoint_manifest(checkpoint$manifest)
      active_join_source("checkpoint")
      join_revision(NULL)
      join_request(NULL)
      join_settings_used(NULL)
      analysis_filter_selection(new_filter_selection())

      message <- sprintf(
        "Loaded a verified Joined HE dataset with %d row(s); checksum %s.",
        nrow(checkpoint$dataset),
        substr(checkpoint$manifest$dataset_checksum, 1L, 12L)
      )
      processed_checkpoint_load_status(list(status = "success", message = message))
      showNotification(message, type = "message", duration = 6)
    }, error = function(error) {
      record_raw24_condition_diagnostic("processed dataset checkpoint load", error)
      message <- processed_checkpoint_user_error_message(error)
      processed_checkpoint_load_status(list(status = "error", message = message))
      showNotification(message, type = "error", duration = 8)
    })
  }, ignoreInit = TRUE)

  analysis_filter_result <- reactive({
    source <- current_joined_source()
    filtered <- apply_filter_selection(source$analysis_dataset, analysis_filter_selection())
    filtered$source_dataset <- source$source_dataset
    filtered$source_fingerprint <- source$source_fingerprint
    filtered
  })

  current_analysis_context <- reactive({
    filtered <- analysis_filter_result()
    list(
      source_dataset = filtered$source_dataset,
      source_fingerprint = filtered$source_fingerprint,
      filter_version = filtered$filter_version,
      analysis_rows = if (is.null(filtered$analysis_dataset)) 0L else nrow(filtered$analysis_dataset)
    )
  })

  # Single source of truth for every downstream analysis consumer. Filtering
  # derives this dataset without mutating the Joined HE dataset.
  current_analysis_data <- reactive({
    analysis_filter_result()$analysis_dataset
  })

  analysis_exclusion_log <- reactive({
    build_analysis_exclusion_log(analysis_filter_selection())
  })

  output$analysis_exclusion_log_table <- DT::renderDataTable({
    analysis_exclusion_log()
  }, rownames = FALSE, options = list(scrollX = TRUE, pageLength = 10))

  commit_analysis_selection <- function(next_selection, action_label) {
    joined <- isolate(current_joined_source()$analysis_dataset)
    current_selection <- isolate(analysis_filter_selection())
    record_id <- tail(next_selection$events$record_id, 1L)
    record_ids <- analysis_record_ids(joined)

    if (length(record_id) != 1L || !record_id %in% record_ids) {
      showNotification(
        "The selected record does not exist in the current Joined HE dataset.",
        type = "error"
      )
      return(invisible(NULL))
    }

    if (identical(
      sort(active_excluded_ids(current_selection)),
      sort(active_excluded_ids(next_selection))
    )) {
      showNotification(
        "The selected record already has that analysis status.",
        type = "warning"
      )
      return(invisible(NULL))
    }

    filtered <- apply_filter_selection(joined, next_selection)
    analysis_filter_selection(next_selection)

    workflow_complete_artifact(
      "filter_selection",
      "User analysis selection",
      sprintf(
        "%s Selection version %d excludes %d of %d records.",
        action_label,
        filtered$filter_version,
        filtered$n_excluded,
        filtered$n_source
      )
    )
    workflow_complete_artifact(
      "exclusion_log",
      "Exclusion and restore log",
      sprintf("Recorded %d analysis-selection action(s).", filtered$filter_version)
    )
    workflow_complete_artifact(
      "analysis_dataset",
      "Current analysis selection",
      sprintf(
        "Current analysis dataset contains %d of %d records.",
        filtered$n_kept,
        filtered$n_source
      )
    )

    basic_model_result(list(
      status = "info",
      messages = "The analysis selection changed. Run the model again.",
      plot = NULL,
      summary = NULL
    ))
    mark_hev_result_stale("The analysis selection changed.")

    invisible(filtered)
  }

  observeEvent(input$exclude_analysis_record, {
    record_id <- trimws(input$analysis_record_id)
    req(nzchar(record_id))
    next_selection <- exclude_record(
      isolate(analysis_filter_selection()),
      record_id = record_id
    )
    commit_analysis_selection(
      next_selection,
      sprintf("Excluded record %s.", record_id)
    )
  }, ignoreInit = TRUE)

  observeEvent(input$restore_analysis_record, {
    record_id <- trimws(input$analysis_record_id)
    req(nzchar(record_id))
    next_selection <- restore_record(
      isolate(analysis_filter_selection()),
      record_id = record_id
    )
    commit_analysis_selection(
      next_selection,
      sprintf("Restored record %s.", record_id)
    )
  }, ignoreInit = TRUE)

  observeEvent(join_data(), {
    analysis_filter_selection(new_filter_selection())
    joined_enriched_result(list(
      status = "not_ready",
      joined_enriched = NULL,
      messages = "Optional enrichment has not been built for the current core Joined HE dataset.",
      provenance = empty_enrichment_provenance(character())
    ))
    updateCheckboxInput(session, "use_joined_enriched", value = FALSE)
    result <- join_data()
    req(nrow(result) > 0L)
    is_checkpoint <- identical(active_join_source(), "checkpoint")
    if (!is_checkpoint) {
      join_settings_used(join_revision()$settings)
    }
    workflow_complete_artifact(
      "joined_core",
      if (is_checkpoint) "Verified processed dataset checkpoint" else "Biology–Flow join",
      sprintf(
        "%s a core Joined HE dataset with %d row(s).",
        if (is_checkpoint) "Loaded" else "Built",
        nrow(result)
      )
    )
    workflow_complete_artifact(
      "processed_dataset_checkpoint",
      "Joined HE dataset checkpoint",
      if (is_checkpoint) {
        "Validated checksum and schema; made the reloaded dataset available for downstream work."
      } else {
        "Made the current core Joined HE dataset available for download."
      }
    )
    workflow_complete_artifact(
      "filter_selection",
      "Default analysis selection",
      "Started with all joined records selected."
    )
    workflow_complete_artifact(
      "exclusion_log",
      "Exclusion and restore log",
      "No analysis records are currently excluded."
    )
    workflow_complete_artifact(
      "analysis_dataset",
      "Core Joined HE dataset",
      sprintf("Created analysis selection version 0 from joined_core with %d row(s).", nrow(result))
    )
    hev_current_result(list(
      status = "not_ready",
      plot = NULL,
      data = NULL,
      provenance = NULL,
      messages = "Generate an HEV plot from the current analysis dataset."
    ))
  })
  
  ### join type for plotting ----
  
  join_data_addbiol_result <- eventReactive(join_request(), {
    request <- join_request()
    req(request)
    req(identical(request$request_id, input$join_he))
    req(workflow_artifact_is_current("oe_result"))
    req(workflow_artifact_is_current("flow_statistics"))
    all.combinations <- expand.grid(biol_site_id = unique(biol_data()$biol_site_id), 
                                    Year = min(biol_data()$Year):max(biol_data()$Year), 
                                    Season = c("Spring", "Autumn"), stringsAsFactors = FALSE)
    
    biol_data1 <- all.combinations %>%
      left_join(biol_all())
    
    mapping <- metadata()[, c("biol_site_id", "flow_site_id")]
    mapping$biol_site_id <- as.character(mapping$biol_site_id)
    mapping$flow_site_id <- as.character(mapping$flow_site_id)
    
    flowstats_1 <- flow_stats() %>% pluck(1)
    
    result <- join_he(biol_data = biol_data1, flow_stats = flowstats_1, mapping = mapping,
                      lags = request$settings$lags, method = request$settings$method, join_type = "add_biol")
    result
    
  })

  join_data_addbiol <- reactive({
    result <- join_data_addbiol_result()
    revision <- join_revision()
    req(
      identical(revision, join_request()),
      identical(revision$flow_revision, flow_source_revision())
    )
    result
  })
  
  ### current join prerequisite states ----
  
  biol_all_data_exist <- reactiveVal(FALSE)
  
  observe({
    req(biol_all())
    biol_all_data_exist(TRUE)
  })
  
  flow_stats_exist <- reactiveVal(FALSE)
  
  observe({
    req(flow_stats())
    flow_stats_exist(TRUE)
  })
  
  ### error message for unselected lag(s) ----
  
  observeEvent(input$join_he, {
    
    if(is.null(input$choose_lags)) {
      
      shinyalert(title = "Please select one or more lag periods",
                 type = "error")
    } 
    
  })
  
  ### warning message for biol data predating flow records ----
  
  observeEvent(input$join_he, {
    req(!is.null(isolate(join_request())))
    req(identical(isolate(join_request())$request_id, input$join_he))
    
    biol_starts <- biol_data() %>% group_by(biol_site_id) %>% summarise(biol_start = min(SAMPLE_DATE))
    flow_starts <- flow_stats() %>% pluck(1) %>% group_by(flow_site_id) %>% summarise(flow_start = min(start_date))
    
    metadata <- metadata()
    metadata$biol_site_id <- as.character(metadata$biol_site_id)
    metadata$flow_site_id <- as.character(metadata$flow_site_id)
    
    biol_starts <- biol_starts %>% left_join(metadata %>% select(c(biol_site_id, flow_site_id)), by = "biol_site_id")
    biol_flow_starts <- biol_starts %>% left_join(flow_starts, by = "flow_site_id")
    
    biol_precede_sites <- biol_flow_starts %>% filter(biol_start < flow_start) %>% pull(biol_site_id)
    biol_precede_sites_text <- gsub("c\\(|\\)",'', biol_precede_sites)
    
    if(sum(biol_flow_starts$biol_start < biol_flow_starts$flow_start) > 0) {
      
      shinyalert(title = paste("One or more biology samples precede the start date of the earliest flow period at site(s) ", paste(biol_precede_sites_text, collapse = ",")),
                 type = "warning")
    } 
    
  })
  
  ## Display joined data ----
  ### table ----
  
  output$join_he_table <- DT::renderDataTable(
    server=FALSE,
    datatable(
      join_data(),
      options = list(
        scrollY = "400px",
        scrollX = TRUE,
        scrollCollapse = TRUE,
        dom = 'Blrtip',
        buttons =
          list('copy', list(
            extend = 'collection',
            buttons = list(
              list(extend = 'csv', filename = "he_data_joined"),
              list(extend = 'excel', filename = "he_data_joined"),
              list(extend = 'pdf', filename = "he_data_joined")),
            text = 'Download'))
      ),
      extensions = "Buttons"
    )
  )
  
  ### plots ----
  #### correlations ----
  output$corr_plots <- renderPlot({
    safe_server_plot("Analysis correlation", function() {
      GGally::ggpairs(current_analysis_data(), columns=c("LIFE_F_OE", "WHPT_ASPT_OE", "Q95z_lag0", "Q10z_lag0"),
                      upper = list(continuous = GGally::wrap("cor")),
                      diag = list(continuous = "densityDiag"),
                      lower = list(continuous = GGally::wrap("points")))+
        theme(text = element_text(size = 14))
    })
    
  })
  
  #### coverage hull ----
  
  output$flow_hull <- renderPlot({
    safe_server_plot("Analysis Flow coverage", function() {
      plot_rngflows(data = join_data_addbiol(), flow_stats = c("Q95z_lag0", "Q10z_lag0"),
                    biol_metric = "LIFE_F_OE", wrap_by = NULL, label = "Year") +
        theme(text = element_text(size = 16))
    })
  })

  output$basic_model_controls <- renderUI({
    data <- tryCatch(
      current_analysis_data(),
      error = function(e) NULL
    )
    numeric_cols <- wq_rhs_numeric_columns(data)
    flow_cols <- numeric_cols[stringr::str_detect(tolower(numeric_cols), "^q|flow")]
    ecology_cols <- numeric_cols[stringr::str_detect(tolower(numeric_cols), "oe$|life|whpt|psi|ntaxa|aspt")]
    if (length(flow_cols) == 0) {
      flow_cols <- numeric_cols
    }
    if (length(ecology_cols) == 0) {
      ecology_cols <- numeric_cols
    }

    tagList(
      selectInput("basic_model_flow_var", "Flow variable", choices = flow_cols, selected = if (length(flow_cols) > 0) flow_cols[[1]] else character(0)),
      selectInput("basic_model_ecology_var", "Ecology response variable", choices = ecology_cols, selected = if (length(ecology_cols) > 0) ecology_cols[[1]] else character(0))
    )
  })

  basic_model_result <- reactiveVal(list(
    status = "info",
    messages = "Pair biology and flow data, choose variables, then run the optional basic model.",
    plot = NULL,
    summary = NULL
  ))

  observeEvent(input$run_basic_model, {
    workflow_begin_artifact("model_spec", "Validate the selected model specification.")
    workflow_begin_artifact("model_result", "Complete model fitting and diagnostics.")
    data <- tryCatch(
      current_analysis_data(),
      error = function(e) NULL
    )
    # run_model() is the safe UI-facing interface: it validates inputs and
    # never lets a raw R error reach the user.
    result <- run_model(
      data = data,
      params = list(
        flow_var    = input$basic_model_flow_var,
        ecology_var = input$basic_model_ecology_var,
        model_type  = "linear"
      )
    )
    if (is.character(result$diagnostic) &&
        length(result$diagnostic) == 1L &&
        !is.na(result$diagnostic) &&
        nzchar(result$diagnostic)) {
      message(sprintf("RAW-24 model diagnostic: %s", result$diagnostic))
    }
    basic_model_result(result)
    if (identical(result$status, "success")) {
      workflow_complete_artifact(
        "model_spec",
        "Model controls",
        "Validated the selected Flow and ecology variables."
      )
      workflow_complete_artifact(
        "model_result",
        "Basic Flow–ecology model",
        "Fitted the current model and generated diagnostics."
      )
    } else {
      workflow_status <- if (identical(result$status, "not_ready")) "blocked" else "failed"
      next_action <- if (identical(result$status, "not_ready")) {
        "Select a single-site analysis dataset, then run the model again."
      } else {
        "Correct the model inputs and run the model again."
      }
      workflow_set_artifact(
        "model_result",
        workflow_status,
        blocking_reason = paste(result$messages, collapse = " "),
        next_action = next_action
      )
    }
  })

  observeEvent(
    list(input$basic_model_flow_var, input$basic_model_ecology_var),
    {
      if (workflow_artifact_is_current("model_result")) {
        workflow_set_artifact(
          "model_spec",
          "ready",
          next_action = "Run the model with the current variable selection.",
          invalidate_downstream = TRUE
        )
      }
    },
    ignoreInit = TRUE
  )

  output$basic_model_status <- renderUI({
    result <- basic_model_result()
    display_status <- if (identical(result$status, "not_ready")) "warning" else result$status
    format_validation_message(list(status = display_status, messages = result$messages))
  })

  output$basic_model_summary <- DT::renderDataTable({
    req(basic_model_result()$summary)
    basic_model_result()$summary
  }, rownames = FALSE, options = list(scrollX = TRUE, searching = FALSE, paging = FALSE))

  output$basic_model_plot <- renderPlot({
    req(basic_model_result()$plot)
    safe_server_plot("Basic model", function() basic_model_result()$plot)
  })
  
  # HEV ----
  ## Create HEV dataset ----
  
  HEV_data_result <- eventReactive(join_request(), {
    request <- join_request()
    req(request)
    flowstats_1 <- flow_stats() %>% pluck(1)
    
    mapping <- metadata()[, c("biol_site_id", "flow_site_id")]
    mapping$biol_site_id <- as.character(mapping$biol_site_id)
    mapping$flow_site_id <- as.character(mapping$flow_site_id)
    
    biol_data_hev <- dplyr::filter(biol_all(), biol_site_id %in% unique(mapping$biol_site_id))
    flow_data_hev <- dplyr::filter(flowstats_1, flow_site_id %in% unique(mapping$flow_site_id))
    
    hev_data <- expand.grid(
      biol_site_id = unique(biol_data_hev$biol_site_id), 
      date = seq.Date(as.Date("1990-01-01"), as.Date(Sys.Date()), by="day"), 
      stringsAsFactors = FALSE)
    
    hev_data$Month <- lubridate::month(hev_data$date)
    hev_data$Year <- lubridate::year(hev_data$date)
    
    hev_data <- hev_data %>%
      left_join(biol_data_hev, by = c("biol_site_id", "date", "Year"))
    
    hev_data$Season <- factor(hev_data$Season, levels = c("Spring", "Summer" ,"Autumn"))
    
    result <- join_he(biol_data = hev_data, flow_stats = flow_data_hev, mapping = mapping,
                      method = "A", join_type = "add_biol") %>%
      select(-"win_no_lag0") %>%
      rename_with(~str_replace_all(.x, "_lag0", ""))
    hev_revision(request)
    result
    
  })

  HEV_data <- reactive({
    if (identical(active_join_source(), "checkpoint")) {
      checkpoint_data <- current_analysis_data()
      req("date" %in% names(checkpoint_data))
      return(processed_dataset_checkpoint_hev_data(checkpoint_data))
    }
    result <- HEV_data_result()
    req(
      identical(hev_revision(), join_revision()),
      identical(hev_revision()$flow_revision, flow_source_revision())
    )

    analysis_data <- current_analysis_data()
    result_id_col <- analysis_record_id_column(result, allow_row_number = FALSE)
    analysis_id_col <- analysis_record_id_column(analysis_data, allow_row_number = FALSE)
    if (!is.na(result_id_col) && !is.na(analysis_id_col)) {
      included_ids <- unique(as.character(analysis_data[[analysis_id_col]]))
      result_ids <- as.character(result[[result_id_col]])
      keep <- is.na(result_ids) | !nzchar(result_ids) | result_ids %in% included_ids
      result <- result[keep, , drop = FALSE]
    }

    result
  })
  
  ## Plotting ----
  ### reactive expression to select site ----
  
  output$picker <- renderUI({
    pickerInput(inputId = 'site_selector', 
                label = 'Choose site', 
                choices = unique(HEV_data()$biol_site_id),
                options = list(`actions-box` = TRUE),multiple = F)
  })
  
  HEV_plot_data <- reactive({
    req(input$site_selector)
    HEV_data() %>%
      filter(biol_site_id == input$site_selector)
  })
  
  ### activate initial plot upon site selection
  HEV_go <- reactive({
    request_id <- hev_request()
    req(!is.null(request_id))
    req(isolate(workflow_artifact_is_current("joined_core")))
    plot_data <- isolate(HEV_plot_data())
    list(
      data = plot_data,
      analysis_context = isolate(current_analysis_context()),
      site_id = isolate(input$site_selector),
      date_range = isolate(input$HEV_date_range),
      biol_metric_selector = isolate(input$biol_metric_selector),
      flow_metric_selector = isolate(input$flow_metric_selector),
      show_all_metrics = isTRUE(isolate(input$HEV_show_all_metrics)),
      show_high_low = isTRUE(isolate(input$HEV_show_high_low)),
      show_status = isTRUE(isolate(input$HEV_show_status))
    )
  })
  
  ### current Joined HE Dataset prerequisite state ----
  
  HEV_data_exist <- reactiveVal(FALSE)
  
  observe({
    req(HEV_data())
    HEV_data_exist(TRUE)
  })
  
  ### render HEV plot with download option ----
  
  output$hev_status_message <- renderUI({
    dependency <- hev_plot_dependency_status()
    if (identical(dependency$status, "error")) {
      return(format_validation_message(list(
        status = "error",
        messages = dependency$message
      )))
    }
    result <- hev_current_result()
    messages <- result$messages
    if (isTRUE(input$HEV_show_status)) {
      messages <- c(
        messages,
        "Status class boundaries require confirmed boundary/class data. None are currently available in the dashboard data, so no boundary lines are drawn."
      )
    }
    display_status <- if (identical(result$status, "stale")) {
      "warning"
    } else if (identical(result$status, "not_ready")) {
      "info"
    } else if (identical(result$status, "failed")) {
      "error"
    } else {
      result$status
    }
    format_validation_message(list(status = display_status, messages = messages))
  })

  output$hev_provenance_summary <- renderUI({
    result <- hev_current_result()
    if (is.null(result$provenance)) {
      return(NULL)
    }
    format_validation_message(list(
      status = if (identical(result$status, "stale")) "warning" else "info",
      messages = summarise_hev_provenance(result$provenance)
    ))
  })

  HEV_result <- reactive({
    req(!is.null(hev_request()))
    safe_plot_result(
      operation = function() {
        req(!identical(hev_plot_dependency_status()$status, "error"))
        request <- HEV_go()
        hev_data <- request$data %>%
          filter(Year >= request$date_range[1] & Year <= request$date_range[2])
        biol_metrics <- resolve_hev_biology_metrics(
          hev_data,
          request$biol_metric_selector,
          request$show_all_metrics
        )
        flow_metrics <- resolve_hev_flow_metrics(
          hev_data,
          request$flow_metric_selector,
          request$show_high_low
        )
        if (nrow(hev_data) == 0L || length(biol_metrics) == 0L || length(flow_metrics) == 0L) {
          return(list(plot = NULL, data = NULL, provenance = NULL))
        }

        plot <- plot_hev_dash(data = hev_data,
                              date_col = "date",
                              flow_stat = flow_metrics,
                              biol_metric = biol_metrics,
                              multiplot = request$show_all_metrics,
                              clr_by = "Season")
        provenance <- build_hev_output_provenance(
          analysis_context = request$analysis_context,
          plot_data = hev_data,
          site_id = request$site_id,
          date_range = request$date_range,
          biology_metrics = biol_metrics,
          flow_metrics = flow_metrics,
          show_all_metrics = request$show_all_metrics,
          show_high_low = request$show_high_low,
          show_status = request$show_status
        )
        list(plot = plot, data = hev_data, provenance = provenance)
      },
      plot_value = function(value) value$plot
    )
  })

  HEV_plot <- reactive({
    req(identical(hev_current_result()$status, "success"))
    req(workflow_artifact_is_current("hev_result"))
    hev_current_result()$plot
  })

  observeEvent(HEV_result(), {
    result <- HEV_result()
    if (identical(result$status, "success")) {
      value <- result$value
      hev_current_result(list(
        status = "success",
        plot = value$plot,
        data = value$data,
        provenance = value$provenance,
        messages = "Generated the current HEV plot from the current analysis dataset."
      ))
      workflow_complete_artifact(
        "hev_result",
        "HEV plot generation",
        summarise_hev_provenance(value$provenance)
      )
      return()
    }

    previous <- isolate(hev_current_result())
    retained_message <- if (!is.null(previous$plot)) {
      "The previous valid HEV plot is retained as history but is not current."
    } else {
      NULL
    }
    hev_current_result(modifyList(previous, list(
      status = "failed",
      messages = c(result$message, retained_message)
    )))
    workflow_set_artifact(
      "hev_result",
      "failed",
      data_source = if (is.null(previous$provenance)) NULL else "Previous HEV plot generation",
      history_summary = if (is.null(previous$provenance)) NULL else summarise_hev_provenance(previous$provenance),
      blocking_reason = result$message,
      next_action = "Check the HEV site, date range and metric selections, then create the plot again."
    )
    message(sprintf(
      "RAW-18 plot diagnostic [HEV/%s]: %s",
      result$failure,
      result$diagnostic
    ))
    showNotification(result$message, type = "error", duration = 10)
  }, priority = -100)

  output$HEV_plot <- renderPlot({
    HEV_plot()
  }) 
  
  output$hev_download_history_table <- DT::renderDataTable({
    hev_download_history()
  }, rownames = FALSE, options = list(scrollX = TRUE, pageLength = 5))

  observeEvent(
    list(
      input$site_selector,
      input$biol_metric_selector,
      input$flow_metric_selector,
      input$HEV_date_range,
      input$HEV_show_all_metrics,
      input$HEV_show_high_low,
      input$HEV_show_status
    ),
    {
      mark_hev_result_stale("HEV settings changed after the current plot was generated.")
    },
    ignoreInit = TRUE
  )

  downloadServer(
    "HEVPlot",
    HEV_plot,
    can_download = function() {
      identical(hev_current_result()$status, "success") &&
        workflow_artifact_is_current("hev_result")
    },
    on_download = function(format, file) {
      hev_download_history(append_hev_download_history(
        hev_download_history(),
        hev_current_result()$provenance,
        format
      ))
    }
  )

  # LOCAL WORKSPACE SAVE ----

  workspace_try_collect <- function(collector) {
    tryCatch(
      isolate(collector()),
      error = function(error) NULL,
      shiny.silent.error = function(error) NULL
    )
  }

  collect_workspace_named_values <- function(collectors) {
    values <- lapply(collectors, workspace_try_collect)
    values[!vapply(values, is.null, logical(1))]
  }

  collect_current_workspace_inputs <- function() {
    input_values <- isolate(reactiveValuesToList(input))
    selected_ids <- intersect(workspace_saved_input_ids, names(input_values))
    selected <- input_values[selected_ids]
    selected[!vapply(selected, is.null, logical(1))]
  }

  collect_current_workspace_runtime <- function() {
    collect_workspace_named_values(list(
      analysis_filter_selection = function() analysis_filter_selection(),
      flow_source_revision = function() flow_source_revision(),
      external_flow_loaded = function() external_flow_loaded(),
      external_flow_revision = function() external_flow_revision(),
      external_import_requested_revision = function() external_import_requested_revision(),
      flow_stats_revision = function() flow_stats_revision(),
      join_revision = function() join_revision(),
      hev_revision = function() hev_revision(),
      join_request = function() join_request(),
      join_settings_used = function() join_settings_used(),
      site_metadata_upload_result = function() site_metadata_upload_result(),
      site_metadata_upload_flow_provenance = function() site_metadata_upload_flow_provenance(),
      wq_site_import_result = function() wq_site_import_result(),
      rhs_site_import_result = function() rhs_site_import_result(),
      wq_contract_summary_status = function() wq_contract_summary_result()$status,
      joined_enriched_status = function() joined_enriched_result()$status,
      analysis_source_dataset = function() current_joined_source()$source_dataset,
      hev_result_status = function() hev_current_result()$status,
      hev_result_provenance = function() hev_current_result()$provenance,
      hev_download_history_rows = function() nrow(hev_download_history()),
      show_environment_plot = function() showEnvplot(),
      show_flow_heatmap = function() showHeatmap(),
      show_imputed_flow_heatmap = function() showHeatmapimp(),
      flow_statistics_display = function() flowStatsDisplay(),
      environment_data_exists = function() env_data_exist(),
      biology_data_exists = function() biol_data_exist(),
      prediction_data_exists = function() predict_data_exist(),
      flow_data_exists = function() flow_data_exist(),
      joined_biology_exists = function() biol_all_data_exist(),
      flow_statistics_exist = function() flow_stats_exist(),
      hev_data_exists = function() HEV_data_exist()
    ))
  }

  collect_current_workspace_datasets <- function() {
    collect_workspace_named_values(list(
      uploaded_wq = function() wq_upload()$data,
      uploaded_rhs = function() rhs_upload()$data,
      site_metadata = function() metadata(),
      mapped_wq = function() wq_site_import_data(),
      mapped_rhs = function() rhs_site_import_data(),
      wq_contract_summary = function() wq_contract_summary_result(),
      local_biology_input = function() local_inv_upload()$data,
      local_flow_input = function() local_flow_upload()$data,
      biology_input = function() biol_data(),
      environment_input = function() env_data(),
      imported_flow = function() external_flow_data(),
      active_flow = function() flow_data(),
      environment_predictions = function() predict_data(),
      oe_results = function() biol_all(),
      additional_flow = function() flow_data_extra(),
      imputed_flow = function() flow_data_imputed(),
      final_flow = function() flow_data_final(),
      flow_statistics = function() flow_stats(),
      joined_core = function() join_data(),
      joined_enriched = function() joined_enriched_result()$joined_enriched,
      analysis_dataset = function() current_analysis_data(),
      analysis_exclusion_log = function() analysis_exclusion_log(),
      joined_analysis = function() join_data_addbiol(),
      model_result = function() basic_model_result(),
      hev_data = function() HEV_data(),
      hev_plot_data = function() hev_current_result()$data,
      hev_download_history = function() hev_download_history()
    ))
  }

  workspace_user_error_message <- function(error) {
    safe_prefixes <- c(
      "Workspace", "workspace", "A workspace", "Enter a workspace",
      "Dataset", "Saved dataset", "Local workspace"
    )
    raw24_safe_condition_message(
      error,
      safe_prefixes = safe_prefixes,
      fallback = "Workspace could not be saved. Check the name and local storage configuration."
    )
  }

  observeEvent(input$save_workspace, {
    if (!workspace_storage_operation_available(
      workspace_storage,
      "save",
      workspace_context
    )) {
      message <- "Workspace saving is not configured for this session."
      workspace_save_status(list(status = "error", message = message, result = NULL))
      showNotification(message, type = "error", duration = 8)
      return()
    }
    if (isTRUE(workspace_save_in_progress())) {
      showNotification("A workspace save is already in progress.", type = "warning")
      return()
    }

    workspace_save_in_progress(TRUE)
    on.exit(workspace_save_in_progress(FALSE), add = TRUE)

    tryCatch({
      snapshot <- new_workspace_snapshot(
        workspace_name = input$workspace_name,
        workflow_artifacts = isolate(workflow_artifacts()),
        workflow_session = list(
          task_id = isolate(workflow_session$task_id),
          stage_index = isolate(workflow_session$stage_index)
        ),
        input_values = collect_current_workspace_inputs(),
        runtime_state = collect_current_workspace_runtime(),
        datasets = collect_current_workspace_datasets(),
        current_panel = isolate(input$main_nav)
      )
      result <- workspace_storage_save(
        workspace_storage,
        snapshot,
        context = workspace_context
      )
      location_phrase <- switch(
        workspace_storage_info$location,
        browser = "in this browser",
        `server-file` = "on this computer",
        cloud = "in the configured cloud service",
        sprintf("in %s", workspace_storage_info$label)
      )
      message <- sprintf(
        "Saved workspace '%s' %s with %d data object(s).",
        result$workspace_name,
        location_phrase,
        result$dataset_count
      )
      workspace_save_status(list(status = "success", message = message, result = result))
      showNotification(message, type = "message", duration = 6)
    }, error = function(error) {
      record_raw24_condition_diagnostic("workspace save", error)
      message <- workspace_user_error_message(error)
      workspace_save_status(list(status = "error", message = message, result = NULL))
      showNotification(message, type = "error", duration = 8)
    })
  }, ignoreInit = TRUE)
  
  # CLEAR HISTORY OPTION ----
  
  observeEvent(input$clear_all, {
    shinyalert(title = "This will clear all existing data and outputs. Do you want to continue?", 
               callbackR = function(x) {
                 if(x == TRUE)
                   session$reload()
               },
               type = "warning",
               showCancelButton = TRUE,
               confirmButtonCol = '#DD6B55',
               confirmButtonText = 'Yes, go ahead')
    
  })
}
