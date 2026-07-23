# This file contains the server function, allowing user interactions with the dashboard to be executed

function(input, output, session){

  # FIVE-STAGE WORKFLOW SHELL ----
  # Preserve this registry when changing Tasks so reusable outputs remain available.
  workflow_artifacts <- reactiveVal(new_he_artifact_registry())
  workflow_session <- reactiveValues(
    task_id = NULL,
    stage_index = 1L
  )

  output$workflow_shell <- renderUI({
    workflow_shell_ui(
      task_id = workflow_session$task_id,
      current_stage = workflow_session$stage_index,
      registry = workflow_artifacts()
    )
  })

  # Always derive Resume from artifact state; do not hard-code a starting Stage.
  lapply(he_workflow_task_ids(), function(task_id) {
    observeEvent(input[[paste0("select_task__", task_id)]], {
      task <- get_he_workflow_task(task_id)
      workflow_session$task_id <- task_id
      workflow_session$stage_index <- workflow_resume_stage(
        task,
        workflow_artifacts()
      )
    }, ignoreInit = TRUE)
  })

  # Keep unused "-" Stages inaccessible in both the UI and server.
  lapply(seq_along(he_workflow_stages), function(stage_index) {
    observeEvent(input[[paste0("workflow_stage_", stage_index)]], {
      req(workflow_session$task_id)
      task <- get_he_workflow_task(workflow_session$task_id)
      if (!identical(task$stage_path[[stage_index]], "-")) {
        workflow_session$stage_index <- stage_index
      }
    }, ignoreInit = TRUE)
  })

  observeEvent(input$change_task, {
    workflow_session$task_id <- NULL
    workflow_session$stage_index <- 1L
  }, ignoreInit = TRUE)

  # Route primary actions through the shared mapping; do not duplicate panel rules here.
  observeEvent(input$workflow_primary_action, {
    req(workflow_session$task_id)
    target <- workflow_nav_target(
      workflow_session$task_id,
      workflow_session$stage_index
    )
    updateNavbarPage(session, "main_nav", selected = target)
  }, ignoreInit = TRUE)

  output$workflow_status_announcement <- renderText({
    req(workflow_session$task_id)
    task <- get_he_workflow_task(workflow_session$task_id)
    stage <- he_workflow_stages[[workflow_session$stage_index]]
    sprintf("Current Task: %s. Current stage: %s.", task$task_label, stage$stage_label)
  })

  # INTRO PAGE ----

  output$intro_page <- renderUI({
    tags$iframe(
      id = "intro-page-frame",
      seamless = "seamless",
      scrolling = "no",
      src = "prefix/intro_page.html",
      style = "border:0; display:block; width:100%; height:1000px; overflow:hidden;",
      onload = paste(
        "var frame = this;",
        "var resizeFrame = function() {",
        "frame.style.height = frame.contentWindow.document.documentElement.scrollHeight + 'px';",
        "};",
        "resizeFrame();",
        "setTimeout(resizeFrame, 250);",
        "setTimeout(resizeFrame, 1000);"
      )
    )
  })
  
  # jump to cards
  observeEvent(input$goto_hev,     {
    updateNavbarPage(session, "main_nav", selected = "HEV Plots") 
  })
  
  observeEvent(input$goto_oe,      {
    updateNavbarPage(session, "main_nav", selected = "Process Biology")
  })
  
  observeEvent(input$goto_flow,    {
    updateNavbarPage(session, "main_nav", selected = "Process Flow")
  })
  
  observeEvent(input$goto_import,  {
    updateNavbarPage(session, "main_nav", selected = "Data Import")
  })
  
  observeEvent(input$goto_wqrhs,   {
    updateNavbarPage(session, "main_nav", selected = "Data Import")
  })
  
  observeEvent(input$goto_analysis,{
    updateNavbarPage(session, "main_nav", selected = "Analysis")
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
    if (invalidate_downstream) {
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

  local_flow_is_operational <- function(upload) {
    upload$validation$status %in% c("success", "warning")
  }

  invalidate_flow_derived_state <- function(reset_external = FALSE) {
    flow_source_revision(isolate(flow_source_revision()) + 1L)
    flow_stats_revision(NULL)
    join_revision(NULL)
    hev_revision(NULL)
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
    workflow_begin_artifact("biology_input", "Complete the Biology import.")
  }, ignoreInit = TRUE, priority = 100)
  observeEvent(input$import_env, {
    workflow_begin_artifact("environment_input", "Complete the environmental-data import.")
  }, ignoreInit = TRUE, priority = 100)
  observeEvent(input$run_rict, {
    workflow_begin_artifact("processed_environment", "Complete RICT prediction processing.")
  }, ignoreInit = TRUE, priority = 100)
  observeEvent(input$calc_OE, {
    workflow_begin_artifact("oe_result", "Complete the O:E calculation.")
  }, ignoreInit = TRUE, priority = 100)
  observeEvent(input$calc_flow_stats, {
    workflow_begin_artifact("flow_statistics", "Complete the Flow-statistics calculation.")
  }, ignoreInit = TRUE, priority = 100)
  observeEvent(input$join_he, {
    workflow_begin_artifact("joined_core", "Complete the biology–Flow join.")
  }, ignoreInit = TRUE, priority = 100)
  observeEvent(input$renderHEV, {
    workflow_begin_artifact("hev_result", "Complete HEV plot generation.")
  }, ignoreInit = TRUE, priority = 100)
  
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
      if (workflow_artifact_is_current("oe_result") &&
          workflow_artifact_is_current("flow_statistics") &&
          workflow_artifact_is_current("joined_core")) {
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

    if (is.null(upload$datapath) || !file.exists(upload$datapath)) {
      return(list(
        data = NULL,
        status = "error",
        messages = paste0("Your ", label, " file could not be found after upload. Please try uploading it again.")
      ))
    }

    data <- tryCatch(
      data.table::fread(upload$datapath, data.table = FALSE, encoding = "UTF-8"),
      error = function(e) e
    )

    if (inherits(data, "error")) {
      return(list(
        data = NULL,
        status = "error",
        messages = paste0("Your ", label, " file could not be read as CSV. Please check that it is a valid comma-separated file.")
      ))
    }

    list(data = data, status = "ok", messages = character(0))
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
      status <- "warning"
      messages <- c(
        messages,
        "Your WQ file is missing a site identifier column. Please include one of: biol_site_id, wq_site_id, site_id, monitoring_site_id."
      )
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
      status <- "warning"
      messages <- c(
        messages,
        "Your RHS file is missing the required rhs_survey_id column."
      )
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

  observeEvent(input$site_metadata_csv, {
    site_metadata_upload_text(NULL)
    site_metadata_upload_flow_provenance(NULL)
    parsed <- read_site_metadata_csv(input$site_metadata_csv$datapath)
    if (!is.null(parsed$error)) {
      site_metadata_upload_result(list(status = "error", messages = parsed$error))
      showNotification(parsed$error, type = "error")
      return()
    }

    parsed$data <- tryCatch(
      normalise_site_metadata_flow_input(parsed$data),
      error = function(e) e
    )
    if (inherits(parsed$data, "error")) {
      message <- conditionMessage(parsed$data)
      site_metadata_upload_result(list(status = "error", messages = message))
      showNotification(message, type = "error")
      return()
    }
    
 
    supporting_validation <- validate_supporting_mapping(parsed$data)
    if (identical(supporting_validation$status, "error")) {
      site_metadata_upload_result(supporting_validation)
      showNotification(paste(supporting_validation$messages, collapse = " "), type = "error")
      return()
    }

    validation_error <- validate_dashboard_site_metadata(parsed$data)
    if (!is.null(validation_error)) {
      site_metadata_upload_result(list(status = "error", messages = validation_error))
      showNotification(validation_error, type = "error")
      return()
    }

    normalised_text <- readr::format_csv(parsed$data)
    site_metadata_upload_text(normalised_text)
    site_metadata_upload_flow_provenance(site_metadata_flow_input_provenance(parsed$data))
    updateTextAreaInput(session, "meta_paste", value = normalised_text)
    messages <- c(
      paste0("Site metadata CSV imported successfully: ", nrow(parsed$data), " row(s) loaded."),
      paste0("Parsed ID columns: ", paste(intersect(c("biol_site_id", "flow_site_id", "wq_site_id", "rhs_survey_id"), names(parsed$data)), collapse = ", "), "."),
      "The compatible dataset import buttons below now use these site IDs.",
      supporting_validation$messages,
      parsed$warnings
    )
    site_metadata_upload_result(list(status = supporting_validation$status, messages = messages[nzchar(messages)]))
    showNotification("Site metadata CSV imported successfully.", type = "message")
  })

  output$site_metadata_upload_status <- renderUI({
    format_validation_message(site_metadata_upload_result())
  })

  output$download_demo_site_metadata <- downloadHandler(
    filename = function() "demo_site_metadata.csv",
    content = function(file) {
      file.copy("demo_site_metadata.csv", file, overwrite = TRUE)
    },
    contentType = "text/csv"
  )

  metadata_result <- reactive({
    parsed <- parse_site_metadata(input$meta_paste)
    validate(need(is.null(parsed$error), parsed$error))
    normalised <- tryCatch(
      normalise_site_metadata_flow_input(parsed$data),
      error = function(e) e
    )
    validate(need(!inherits(normalised, "error"), if (inherits(normalised, "error")) conditionMessage(normalised) else ""))
    validation_error <- validate_dashboard_site_metadata(normalised)
    validate(need(is.null(validation_error), validation_error))
    provenance <- site_metadata_flow_input_provenance(normalised)
    if (identical(input$meta_paste, site_metadata_upload_text()) &&
        !is.null(site_metadata_upload_flow_provenance())) {
      provenance <- site_metadata_upload_flow_provenance()
      attr(normalised, "flow_input_provenance") <- provenance
    }
    list(data = normalised, flow_input_provenance = provenance)
  })

  metadata <- reactive({
    metadata_result()$data
  })

  observeEvent(metadata(), {
    site_metadata <- metadata()
    req(nrow(site_metadata) > 0L)
    workflow_complete_artifact(
      "site_mapping",
      "Validated site metadata",
      sprintf("Validated %d site-mapping row(s).", nrow(site_metadata))
    )
  })

  metadata_flow_input_provenance <- reactive({
    metadata_result()$flow_input_provenance
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

  observeEvent(input$import_wq_site_ids, {
    parsed <- parse_site_metadata(input$meta_paste)
    if (!is.null(parsed$error)) {
      wq_site_import_data(NULL)
      wq_site_import_result(list(status = "error", messages = parsed$error))
      showNotification(parsed$error, type = "error")
      return()
    }

    site_metadata <- parsed$data
    usable_wq_ids <- usable_mapping_ids(site_metadata, "wq_site_id")
    if (length(usable_wq_ids) == 0) {
      message <- "No confirmed WQ site IDs are available yet. Please provide WQ site IDs before importing WQ data."
      wq_site_import_data(NULL)
      wq_site_import_result(list(status = "warning", messages = message))
      showNotification(message, type = "warning")
      return()
    }

    start_date <- max(as.Date(input$date_range_wq[[1]]), as.Date("2000-01-01"))
    end_date <- as.Date(input$date_range_wq[[2]])
    if (end_date <= start_date) {
      message <- "The WQ end date must be later than the start date. Water Quality Explorer data are available from 2000 onwards."
      wq_site_import_result(list(status = "error", messages = message))
      showNotification(message, type = "error")
      return()
    }

    imported <- tryCatch(
      hetoolkit::import_wq(
        sites = usable_wq_ids,
        dets = "default",
        start_date = format(start_date, "%Y-%m-%d"),
        end_date = format(end_date, "%Y-%m-%d"),
        save = FALSE
      ),
      error = function(e) NULL
    )

    if (is.null(imported) || nrow(imported) == 0) {
      message <- "WQ data could not be imported for the supplied site IDs and date range. Check the IDs, dates, and network connection."
      wq_site_import_data(NULL)
      wq_site_import_result(list(status = "error", messages = message))
      showNotification(message, type = "error")
      return()
    }

    has_biology_mapping <- all(c("biol_site_id", "wq_site_id") %in% names(site_metadata))
    output_data <- if (has_biology_mapping) map_wq_records_to_biology(imported, site_metadata) else imported
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
      showNotification(parsed$error, type = "error")
      return()
    }

    site_metadata <- parsed$data
    usable_rhs_ids <- usable_mapping_ids(site_metadata, "rhs_survey_id")
    if (length(usable_rhs_ids) == 0) {
      message <- "No confirmed RHS survey IDs are available yet. Please provide rhs_survey_id values before importing RHS data."
      rhs_site_import_data(NULL)
      rhs_site_import_result(list(status = "warning", messages = message))
      showNotification(message, type = "warning")
      return()
    }

    imported <- tryCatch(
      import_rhs_in_temp_directory(usable_rhs_ids),
      error = function(e) NULL
    )

    if (is.null(imported) || nrow(imported) == 0) {
      message <- "RHS data could not be imported for the supplied survey IDs. Check the IDs and network connection."
      rhs_site_import_data(NULL)
      rhs_site_import_result(list(status = "error", messages = message))
      showNotification(message, type = "error")
      return()
    }

    has_biology_mapping <- all(c("biol_site_id", "rhs_survey_id") %in% names(site_metadata))
    output_data <- if (has_biology_mapping) map_rhs_records_to_biology(imported, site_metadata) else imported
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
      readr::write_csv(data, file)
    },
    contentType = "text/csv"
  )

  output$download_mapped_rhs_csv <- downloadHandler(
    filename = function() "mapped_rhs_data.csv",
    content = function(file) {
      data <- mapped_rhs_plot_data()
      validate(need(!is.null(data) && nrow(data) > 0, "No mapped RHS data are available to download."))
      readr::write_csv(data, file)
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
      workflow_set_artifact(
        "wq_input",
        result$status,
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
    plot_result$plot
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
      readr::write_csv(data, file)
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
    result$plot
  })

  current_rhs_plot <- reactive({
    result <- build_rhs_plot(
      data = mapped_rhs_plot_data(),
      plot_type = input$rhs_plot_type,
      variable = input$rhs_variable,
      group_col = input$rhs_group_col
    )
    validate(need(!is.null(result$plot), result$message))
    result$plot
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
      ggplot2::ggsave(file, plot = current_wq_plot(), width = 10, height = 5, dpi = 150)
    },
    contentType = "image/png"
  )

  output$download_rhs_plot <- downloadHandler(
    filename = function() "mapped_rhs_plot.png",
    content = function(file) {
      ggplot2::ggsave(file, plot = current_rhs_plot(), width = 10, height = 5, dpi = 150)
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

  observeEvent(input$meta_paste, {
    workflow_reset_artifact(
      "site_mapping",
      "Site metadata changed.",
      "Validate the current site mapping."
    )
    invalidate_flow_derived_state(reset_external = TRUE)
  }, ignoreNULL = FALSE, ignoreInit = FALSE, priority = 200)

  observeEvent(input$date_range_flow, {
    if (!local_flow_is_operational(local_flow_upload())) {
      invalidate_flow_derived_state(reset_external = TRUE)
    }
  }, ignoreNULL = FALSE, ignoreInit = FALSE, priority = 200)

  observeEvent(input$import_flow, {
    if (!local_flow_is_operational(local_flow_upload())) {
      invalidate_flow_derived_state(reset_external = TRUE)
      external_import_requested_revision(isolate(flow_source_revision()))
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
    content  = function(file) utils::write.csv(exclusion_log_data(), file, row.names = FALSE)
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
  biol_data <- eventReactive(input$import_inv, {
    biol_sites <- as.character(metadata()$biol_site_id)
    
    import_inv(source = "parquet", sites = biol_sites, start_date = input$date_range_biol[1],
               end_date = input$date_range_biol[2])
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
  env_data <- eventReactive(input$import_env, {
    biol_sites <- as.character(metadata()$biol_site_id)
    
    import_env(sites = biol_sites) %>% mutate(across(BOULDERS_COBBLES: SILT_CLAY, ~tidyr::replace_na(.,0)))
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
    plot_sitepca_dash(env_data(), vars = c("ALTITUDE", "SLOPE", "WIDTH", "DEPTH", 
                                           "BOULDERS_COBBLES", "PEBBLES_GRAVEL", "SILT_CLAY"), 
                      eigenvectors = TRUE, label_by = "biol_site_id")
  })
  
  
  ## Flow data ----
  ### importing ----
  external_flow_data <- eventReactive(input$import_flow, {
    req(identical(external_import_requested_revision(), flow_source_revision()))
    flow_sites <- as.character(metadata()$flow_site_id)
    flow_inputs <- as.character(metadata()$flow_input)

    imported <- import_dashboard_flow(sites = flow_sites, inputs = flow_inputs, start_date = input$date_range_flow[1],
                                      end_date = input$date_range_flow[2])
    external_flow_loaded(TRUE)
    external_flow_revision(isolate(flow_source_revision()))
    imported
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
    plot_heatmap_dash(data = flow_data(), x = "date", y = "flow_site_id", fill = "flow", dual = FALSE) %>% 
      pluck(1) %>% grid.arrange() %>% print()
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
  predict_data <- eventReactive(input$run_rict, {
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
  
  #### error message for absent env data ----
  env_data_exist <- reactiveVal(FALSE)
  
  observe({
    req(env_data())
    env_data_exist(TRUE)
  })
  
  observeEvent(input$run_rict, {
    
    if(!env_data_exist()) {
      
      shinyalert(title = "Please import environmental base data",
                 type = "error")
    } 
    
  })
  
  #### warning message for incomplete env data ----
  observeEvent(input$run_rict, {
    
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
  biol_all <- reactive({
    req(input$calc_OE)
    
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
      select(c(biol_site_id, SAMPLE_ID, date, Month, Year, Season, NGR_10_FIG, WFD_WATERBODY_ID:CALCIUM,
               WHPT_ASPT_O:PSI_OE))
    

  })

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
  
  #### error message for absent biol data ----
  
  biol_data_exist <- reactiveVal(FALSE)
  
  observe({
    req(biol_data())
    biol_data_exist(TRUE)
  })
  
  observeEvent(input$calc_OE, {
    
    if(!biol_data_exist()) {
      
      shinyalert(title = "Please import biology data",
                 type = "error")
    } 
    
  })
  
  #### warning message for incomplete biol data ----
  observeEvent(input$calc_OE, {
    
    if(sum(is.na(biol_all()$WHPT_ASPT_O),	
           is.na(biol_all()$LIFE_F_O),	
           is.na(biol_all()$WHPT_NTAXA_O),	
           is.na(biol_all()$PSI_O)) > 0) {
      
      shinyalert(title = "One or more sites are missing observed WHPT, LIFE and/or PSI scores required for O:E calculations",
                 type = "warning")
    } 
    
  })
  
  #### error message for absent predict data ----
  
  predict_data_exist <- reactiveVal(FALSE)
  
  observe({
    req(predict_data())
    predict_data_exist(TRUE)
  })
  
  observeEvent(input$calc_OE, {
    
    if(!predict_data_exist()) {
      
      shinyalert(title = "Please run RICT predictions",
                 type = "error")
    } 
    
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
  donor_mapping <- reactive({ 
    
  ##### error message for absent donor mapping ----
    validate(
      need(input$donor_mapping_paste != "", "If imputing flows please add donor mapping")
    )
    
    if (input$donor_mapping_paste != '') {
      donor_mapping <- fread(paste(input$donor_mapping_paste, collapse = "\n"), colClasses = "character")
      donor_mapping <-as.data.frame(donor_mapping)
    }
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
  donor_list <- reactive({ 
    
  ##### error message for absent extra flow site list ----
    validate(
      need(input$donor_list_paste != "", "If imputing flows please add additional donor sites as required")
    )
    
    if (input$donor_list_paste != '') {
      donor_list <- fread(paste(input$donor_list_paste, collapse = "\n"), colClasses = "character")
      donor_list <-as.data.frame(donor_list)
      donor_list <- tryCatch(
        normalise_site_metadata_flow_input(donor_list),
        error = function(e) e
      )
      validate(need(!inherits(donor_list, "error"), if (inherits(donor_list, "error")) conditionMessage(donor_list) else ""))
      donor_list
    }
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
  flow_data_extra <- reactive({
    req(input$import_donor_flow)
    
    donor_sites <- as.character(donor_list()$flow_site_id)
    donor_inputs <- as.character(donor_list()$flow_input)
    
    donor_data <- import_dashboard_flow(sites = donor_sites, inputs = donor_inputs, start_date = input$date_range_flow[1],
                                        end_date = input$date_range_flow[2])
    
    bind_rows(flow_data(), donor_data)
    
  })
  
  #### alert message for successful import ----
  
  import_donor_flow_success <- reactiveVal(FALSE)
  
  observe({
    req(flow_data_extra())
    import_donor_flow_success(TRUE)
  })
  
  observeEvent(input$import_donor_flow, {
    
    if(import_donor_flow_success()) {
      
      shinyalert(title = "Additional flow data successfully imported",
                 type = "success")
    } 
    
  })
  
  #### warning message for unID'd donor sites ----
  observeEvent(input$import_donor_flow, {
    
    missed_donor_sites <- donor_list() %>% filter(!flow_site_id %in% flow_data_extra()$flow_site_id) %>% select(flow_site_id)
    missed_donor_sites_text <- gsub("c\\(|\\)",'', missed_donor_sites)
    
    if(length(missed_donor_sites > 0)) {
      
      shinyalert(paste("Flow data could not be found for donor station(s)", paste(missed_donor_sites_text, collapse = ",")), 
                 type = "warning")
    } 
    
  })
  
  #### run imputation ----
  
  extra_check <- reactiveVal(TRUE)
  
  observeEvent(flow_data_extra(), {
    extra_check(!extra_check())
  })
  
  flow_data_forimp <- reactive({
    
    if (extra_check()){
      flow_data_forimp <- flow_data()
      
    }
    else{
      flow_data_forimp <- flow_data_extra()
      
    }
    
  })
  
  flow_data_imputed <- reactive({
    req(input$impute_flow)
    
    donor_mapping <- as.data.frame(donor_mapping())
    
    impute_flow(flow_data_forimp(), site_col = "flow_site_id", date_col = "date", flow_col = "flow", 
                method = "equipercentile", donor = donor_mapping)
    
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
    plot_heatmap_dash(data = flow_data_imputed(), x = "date", y = "flow_site_id", fill = "flow", dual = FALSE) %>% 
      pluck(1) %>% grid.arrange() %>% print()
  })
  
  
  ## Calculating flow stats ----
  
  ### run calculation ----
  
  imp_check <- reactiveVal(TRUE)
  
  observeEvent(flow_data_imputed(), {
    imp_check(!imp_check())
  })
  
  flow_data_final <- reactive({
    
    if (imp_check()){
      flow_data_final <- flow_data()
      
    }
    else{
      flow_data_final <- flow_data_imputed()
      
    }
    
  })
  
  flow_stats_result <- eventReactive(input$calc_flow_stats, {
    flow_data_final <- flow_data_final()
    
    flow_data_final$flow[flow_data_final$flow <= 0] <- NA
    
    result <- calc_flowstats(data = flow_data_final, site_col = "flow_site_id", date_col = "date",
                             flow_col = "flow", win_width = paste(input$win_width_selector, "months"),
                             win_step = paste(input$win_step_selector, "months"))
    flow_stats_revision(isolate(flow_source_revision()))
    result
  })

  flow_stats <- reactive({
    result <- flow_stats_result()
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
  
  join_data_result <- eventReactive(input$join_he, {
    mapping <- metadata()[, c("biol_site_id", "flow_site_id")]
    mapping$biol_site_id <- as.character(mapping$biol_site_id)
    mapping$flow_site_id <- as.character(mapping$flow_site_id)
    
    flowstats_1 <- flow_stats() %>% pluck(1)
    
    result <- join_he(biol_data = biol_all(), flow_stats = flowstats_1, mapping = mapping,
                      lags = as.integer(input$choose_lags), method = input$choose_join_method, join_type = "add_flows")
    join_revision(isolate(flow_source_revision()))
    result
    
  })

  join_data <- reactive({
    result <- join_data_result()
    req(identical(join_revision(), flow_source_revision()))
    result
  })

  observeEvent(join_data(), {
    result <- join_data()
    req(nrow(result) > 0L)
    workflow_complete_artifact(
      "joined_core",
      "Biology–Flow join",
      sprintf("Built a core Joined HE dataset with %d row(s).", nrow(result))
    )
    workflow_complete_artifact(
      "processed_dataset_checkpoint",
      "Joined HE dataset checkpoint",
      "Made the current core Joined HE dataset available for download."
    )
    workflow_complete_artifact(
      "filter_selection",
      "Default analysis selection",
      "Started with all joined records selected."
    )
    workflow_complete_artifact(
      "analysis_dataset",
      "Core Joined HE dataset",
      sprintf("Created analysis selection version 0 with %d row(s).", nrow(result))
    )
  })
  
  ### join type for plotting ----
  
  join_data_addbiol_result <- eventReactive(input$join_he, {
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
                      lags = as.integer(input$choose_lags), method = input$choose_join_method, join_type = "add_biol")
    join_revision(isolate(flow_source_revision()))
    result
    
  })

  join_data_addbiol <- reactive({
    result <- join_data_addbiol_result()
    req(identical(join_revision(), flow_source_revision()))
    result
  })
  
  ### error message for absent biology data ----
  
  biol_all_data_exist <- reactiveVal(FALSE)
  
  observe({
    req(biol_all())
    biol_all_data_exist(TRUE)
  })
  
  observeEvent(input$join_he, {
    
    if(!biol_all_data_exist()) {
      
      shinyalert(title = "Processed biology data are missing",
                 type = "error")
    } 
    
  })
  
  ### error message for absent flow stats ----
  
  flow_stats_exist <- reactiveVal(FALSE)
  
  observe({
    req(flow_stats())
    flow_stats_exist(TRUE)
  })
  
  observeEvent(input$join_he, {
    
    if(!flow_stats_exist()) {
      
      shinyalert(title = "Flow statistics are missing",
                 type = "error")
    } 
    
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
    GGally::ggpairs(join_data(), columns=c("LIFE_F_OE", "WHPT_ASPT_OE", "Q95z_lag0", "Q10z_lag0"), 
                    upper = list(continuous = GGally::wrap("cor")),
                    diag = list(continuous = "densityDiag"),
                    lower = list(continuous = GGally::wrap("points")))+
      theme(text = element_text(size = 14))
    
  })
  
  #### coverage hull ----
  
  output$flow_hull <- renderPlot({
    
    plot_rngflows(data = join_data_addbiol(), flow_stats = c("Q95z_lag0", "Q10z_lag0"), 
                  biol_metric = "LIFE_F_OE", wrap_by = NULL, label = "Year") +
      theme(text = element_text(size = 16))
    
  })

  output$basic_model_controls <- renderUI({
    data <- tryCatch(join_data(), error = function(e) NULL)
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
    data <- tryCatch(join_data(), error = function(e) NULL)
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
      workflow_set_artifact(
        "model_result",
        "failed",
        blocking_reason = paste(result$messages, collapse = " "),
        next_action = "Correct the model inputs and run the model again."
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
    format_validation_message(list(status = result$status, messages = result$messages))
  })

  output$basic_model_summary <- DT::renderDataTable({
    req(basic_model_result()$summary)
    basic_model_result()$summary
  }, rownames = FALSE, options = list(scrollX = TRUE, searching = FALSE, paging = FALSE))

  output$basic_model_plot <- renderPlot({
    req(basic_model_result()$plot)
    basic_model_result()$plot
  })
  
  # HEV ----
  ## Create HEV dataset ----
  
  HEV_data_result <- eventReactive(input$join_he, {
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
    hev_revision(isolate(flow_source_revision()))
    result
    
  })

  HEV_data <- reactive({
    result <- HEV_data_result()
    req(identical(hev_revision(), flow_source_revision()))
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
    
    HEV_plot_data <- HEV_data() %>% 
      filter(biol_site_id == input$site_selector)
    
    return(HEV_plot_data)
    
  })
  
  ### activate initial plot upon site selection
  HEV_go <- reactive({
    req(input$renderHEV)
    
    HEV_plot_data()
    
  }) 
  
  ### error message for absent joined data ----
  
  HEV_data_exist <- reactiveVal(FALSE)
  
  observe({
    req(HEV_data())
    HEV_data_exist(TRUE)
  })
  
  observeEvent(input$renderHEV, {
    
    if(!HEV_data_exist()) {
      
      shinyalert(title = "Paired biology-flow data are missing",
                 type = "error")
    } 
    
  })
  
  ### render HEV plot with download option ----
  
  output$hev_status_message <- renderUI({
    if (isTRUE(input$HEV_show_status)) {
      format_validation_message(list(
        status = "warning",
        messages = "Status class boundaries require confirmed boundary/class data. None are currently available in the dashboard data, so no boundary lines are drawn."
      ))
    }
  })

  HEV_plot <- reactive({
    hev_data <- HEV_go() %>% filter(Year >= input$HEV_date_range[1] & Year <= input$HEV_date_range[2])
    biol_metrics <- if (isTRUE(input$HEV_show_all_metrics)) {
      c("WHPT_ASPT_OE", "WHPT_NTAXA_OE", "LIFE_F_OE", "PSI_OE")
    } else {
      input$biol_metric_selector
    }
    flow_metrics <- if (isTRUE(input$HEV_show_high_low)) {
      selected <- input$flow_metric_selector
      high_low <- if (stringr::str_detect(selected, "z$")) c("Q95z", "Q10z") else c("Q95", "Q10")
      if (all(high_low %in% names(hev_data))) high_low else selected
    } else {
      input$flow_metric_selector
    }

    plot_hev_dash(data = hev_data,
                  date_col = "date",
                  flow_stat = flow_metrics,
                  biol_metric = biol_metrics,
                  multiplot = isTRUE(input$HEV_show_all_metrics),
                  clr_by = "Season")
  })

  observeEvent(HEV_plot(), {
    plot_result <- HEV_plot()
    req(!is.null(plot_result))
    workflow_complete_artifact(
      "hev_result",
      "HEV plot generation",
      "Generated the current HEV plot from the current analysis selection."
    )
  })

  output$HEV_plot <- renderPlot({
    HEV_plot()
  }) 
  
  downloadServer("HEVPlot", HEV_plot)
  
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
