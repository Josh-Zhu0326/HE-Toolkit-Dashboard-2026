# This file contains the server function, allowing user interactions with the dashboard to be executed

function(input, output, session){
  
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

  wq_rhs_mapping_example <- data.frame(
    biol_site_id = "291",
    flow_site_id = "27090",
    flow_input = "NRFA",
    wq_site_id = "SW-A4070115",
    rhs_site_id = "6145",
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

    id_cols <- c("biol_site_id", "rhs_survey_id", "rhs_site_id", "site_id", "survey_id")
    if (!any(id_cols %in% names_lower)) {
      status <- "warning"
      messages <- c(
        messages,
        "Your RHS file is missing a survey identifier column. Please include rhs_survey_id where possible, or one of: biol_site_id, rhs_site_id, site_id, survey_id."
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

  observeEvent(input$site_metadata_csv, {
    parsed <- read_site_metadata_csv(input$site_metadata_csv$datapath)
    if (!is.null(parsed$error)) {
      site_metadata_upload_result(list(status = "error", messages = parsed$error))
      showNotification(parsed$error, type = "error")
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

    updateTextAreaInput(session, "meta_paste", value = readr::format_csv(parsed$data))
    messages <- c(
      paste0("Site metadata CSV imported successfully: ", nrow(parsed$data), " row(s) loaded."),
      paste0("Parsed ID columns: ", paste(intersect(c("biol_site_id", "flow_site_id", "wq_site_id", "rhs_site_id", "rhs_survey_id"), names(parsed$data)), collapse = ", "), "."),
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

  metadata <- reactive({
    parsed <- parse_site_metadata(input$meta_paste)
    validate(need(is.null(parsed$error), parsed$error))
    parsed$data
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

    if (("biol_site_id" %in% names(uploaded)) && any(c("rhs_site_id", "rhs_survey_id") %in% names(uploaded))) {
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

    list(data = read_result$data, validation = validation)
  })

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
  flow_data <- eventReactive(input$import_flow, {
    flow_sites <- as.character(metadata()$flow_site_id)
    flow_inputs <- as.character(metadata()$flow_input)
    
    import_flow(sites = flow_sites, inputs = flow_inputs, start_date = input$date_range_flow[1],
                end_date = input$date_range_flow[2])
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
      select(keeps) %>% dplyr::rename(Season = SEASON) %>%
      dplyr::mutate(Season = case_when(Season == 1 ~ "Spring", Season == 2 ~ "Summer",
                                       Season == 3 ~ "Autumn"))
    
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
    }
  })
  
  #### display ----
  output$table3 <- function() {
    
  ##### error messages for incorrect data formats ----
    donor_req_col_ID <- 'flow_site_id'
    donor_req_col_input <- 'flow_input'
    donor_req_col_flow_input <- 'flow_input'
    donor_req_flow_input_types <- c('HDE', 'NRFA')
    
    donor_sites_col_names <- colnames(donor_list())
    
    donor_mapping_sites <- donor_mapping()[,2]
    metadata_sites <- metadata()$flow_site_id
    donor_list_sites <- donor_list()$flow_site_id
    all_flow_sites <- c(metadata_sites, donor_list_sites)
    
    flow_input <- donor_list()$flow_input
    match <- flow_input %in% donor_req_flow_input_types
    
    validate(
      need(donor_req_col_ID %in% donor_sites_col_names, "You don't have a correctly named list of flow site IDs"),
      need(donor_req_col_input %in% donor_sites_col_names, "You don't have a correctly named list of flow inputs"),
      need(all(donor_mapping_sites %in% all_flow_sites), "One or more named donor sites are absent from both original metadata and additional donor list"),
      need(!str_contains(match, "FALSE"), "Please ensure all your flow inputs are listed as either 'HDE' or 'NRFA'")
      
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
    
    donor_data <- import_flow(sites = donor_sites, inputs = donor_inputs, start_date = input$date_range_flow[1],
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
  
  flow_stats <- eventReactive(input$calc_flow_stats, {
    flow_data_final <- flow_data_final()
    
    flow_data_final$flow[flow_data_final$flow <= 0] <- NA
    
    calc_flowstats(data = flow_data_final, site_col = "flow_site_id", date_col = "date",
                   flow_col = "flow", win_width = paste(input$win_width_selector, "months"), 
                   win_step = paste(input$win_step_selector, "months"))
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
  
  join_data <- eventReactive(input$join_he, {
    mapping <- metadata()[, c("biol_site_id", "flow_site_id")]
    mapping$biol_site_id <- as.character(mapping$biol_site_id)
    mapping$flow_site_id <- as.character(mapping$flow_site_id)
    
    flowstats_1 <- flow_stats() %>% pluck(1)
    
    join_he(biol_data = biol_all(), flow_stats = flowstats_1, mapping = mapping,
            lags = as.integer(input$choose_lags), method = input$choose_join_method, join_type = "add_flows")
    
  })
  
  ### join type for plotting ----
  
  join_data_addbiol <- eventReactive(input$join_he, {
    all.combinations <- expand.grid(biol_site_id = unique(biol_data()$biol_site_id), 
                                    Year = min(biol_data()$Year):max(biol_data()$Year), 
                                    Season = c("Spring", "Autumn"), stringsAsFactors = FALSE)
    
    biol_data1 <- all.combinations %>%
      left_join(biol_all())
    
    mapping <- metadata()[, c("biol_site_id", "flow_site_id")]
    mapping$biol_site_id <- as.character(mapping$biol_site_id)
    mapping$flow_site_id <- as.character(mapping$flow_site_id)
    
    flowstats_1 <- flow_stats() %>% pluck(1)
    
    join_he(biol_data =  biol_data1, flow_stats = flowstats_1, mapping = mapping,
            lags = as.integer(input$choose_lags), method = input$choose_join_method, join_type = "add_biol")
    
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
    data <- tryCatch(join_data(), error = function(e) NULL)
    result <- build_basic_flow_ecology_model(
      data = data,
      flow_var = input$basic_model_flow_var,
      ecology_var = input$basic_model_ecology_var
    )
    basic_model_result(result)
  })

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
  
  HEV_data <- eventReactive(input$join_he, {
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
    
    join_he(biol_data =  hev_data, flow_stats = flow_data_hev, mapping = mapping,
            method = "A", join_type = "add_biol") %>% select(-"win_no_lag0") %>% 
      rename_all(funs(str_replace_all(., '_lag0', '')))
    
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
