# Stage 1 upload checkpoints for the five Data Contract v2.0 CSV types.
# The registry keeps workflow naming, UI IDs and contract naming in one place.

local_csv_checkpoint_specs <- function() {
  list(
    biology = list(
      contract_type = "biology",
      workflow_type = "biology",
      title = "Biology CSV",
      description = "Biological sample identifiers, dates and supported index values.",
      input_id = "local_v2_biology_csv"
    ),
    environmental = list(
      contract_type = "environmental",
      workflow_type = "environment",
      title = "Site environmental CSV",
      description = "Site characteristics used by the biological prediction workflow.",
      input_id = "local_v2_environmental_csv"
    ),
    flow = list(
      contract_type = "flow",
      workflow_type = "flow",
      title = "Daily Flow CSV",
      description = "Daily Flow records. A valid file remains an operational Flow source.",
      input_id = "local_flow_csv"
    ),
    wq = list(
      contract_type = "wq",
      workflow_type = "wq",
      title = "Water Quality CSV",
      description = "Water Quality observations in the contracted long format.",
      input_id = "local_v2_wq_csv"
    ),
    rhs = list(
      contract_type = "rhs",
      workflow_type = "rhs",
      title = "RHS CSV",
      description = "River Habitat Survey identifiers and contracted summary values.",
      input_id = "local_v2_rhs_csv"
    )
  )
}

local_csv_checkpoint_output_id <- function(data_type, output) {
  paste("local_v2", data_type, output, sep = "_")
}

local_csv_checkpoint_card <- function(data_type) {
  spec <- local_csv_checkpoint_specs()[[data_type]]
  if (is.null(spec)) {
    stop(sprintf("Unknown local CSV checkpoint type: %s", data_type), call. = FALSE)
  }

  template_path <- paste0("templates/local_csv_v2/", spec$contract_type, ".csv")
  bslib::card(
    class = "dashboard-card",
    `data-task-imports` = spec$workflow_type,
    bslib::card_header(spec$title),
    shiny::div(class = "hint-text", spec$description),
    shiny::tags$a(
      class = "btn btn-outline-secondary client-action-button",
      href = template_path,
      download = basename(template_path),
      paste("Download", spec$title, "template")
    ),
    shiny::fileInput(
      spec$input_id,
      paste("Choose", spec$title),
      accept = c(".csv", "text/csv")
    ),
    shiny::uiOutput(local_csv_checkpoint_output_id(data_type, "status")),
    shiny::conditionalPanel(
      condition = sprintf("output['%s']", local_csv_checkpoint_output_id(data_type, "uploaded")),
      shiny::h5("Validation details"),
      DT::dataTableOutput(local_csv_checkpoint_output_id(data_type, "issues")),
      shiny::h5("Validated preview"),
      DT::dataTableOutput(local_csv_checkpoint_output_id(data_type, "preview"))
    )
  )
}

local_csv_checkpoint_panel <- function() {
  types <- names(local_csv_checkpoint_specs())
  cards <- lapply(types, local_csv_checkpoint_card)
  shiny::tagList(
    shiny::h3(class = "section-title", "Local CSV file import"),
    shiny::p(
      class = "page-lead",
      "Download and complete one CSV template for each data type required by the current Task. Files are checked independently before they enter later processing."
    ),
    do.call(
      bslib::layout_columns,
      c(list(col_widths = c(6, 6)), cards)
    ),
    shiny::uiOutput("source_conflict_resolution_panel")
  )
}

source_conflict_resolution_panel <- function(results) {
  if (is.null(results) || length(results) == 0L) {
    return(NULL)
  }
  combined <- results[vapply(results, function(result) {
    provenance <- result$provenance
    !is.null(provenance) &&
      isTRUE(provenance$local_rows > 0L) &&
      isTRUE(provenance$explorer_rows > 0L)
  }, logical(1))]
  if (length(combined) == 0L) {
    return(shiny::div(
      class = "dashboard-card",
      shiny::h4("Local and Data Explorer conflicts"),
      shiny::p(
        class = "hint-text",
        "Conflict choices appear here when Local and Data Explorer records are loaded for the same data type."
      )
    ))
  }

  cards <- lapply(names(combined), function(data_type) {
    result <- combined[[data_type]]
    contract <- source_reconciliation_contract(data_type)
    status <- if (identical(result$status, "conflict")) "warning" else result$status
    conflict_table <- if (nrow(result$conflicts) > 0L) {
      shown <- utils::head(result$conflicts[, c(
        "record_key", "differing_fields", "local_values", "explorer_values"
      ), drop = FALSE], 20L)
      shiny::tagList(
        shiny::tags$div(
          class = "table-responsive",
          shiny::tags$table(
            class = "table table-sm table-striped",
            shiny::tags$thead(shiny::tags$tr(lapply(names(shown), shiny::tags$th))),
            shiny::tags$tbody(lapply(seq_len(nrow(shown)), function(row) {
              shiny::tags$tr(lapply(shown[row, , drop = TRUE], shiny::tags$td))
            }))
          )
        ),
        shiny::selectInput(
          source_reconciliation_input_id(data_type),
          paste("For conflicting", contract$label, "records"),
          choices = c(
            "Choose a resolution" = "",
            "Keep Local records" = "local",
            "Keep Data Explorer records" = "explorer",
            "Exclude conflicting records" = "exclude"
          ),
          selected = if (result$provenance$conflict_preference %in%
                         c("local", "explorer", "exclude")) {
            result$provenance$conflict_preference
          } else {
            ""
          }
        )
      )
    } else {
      shiny::p(
        class = "hint-text",
        "No conflicting values were found; exact duplicates were removed automatically with provenance."
      )
    }
    bslib::card(
      class = "dashboard-card",
      bslib::card_header(paste(contract$label, "source reconciliation")),
      local_csv_checkpoint_status_tag(list(status = status, messages = result$messages)),
      conflict_table
    )
  })

  shiny::tagList(
    shiny::h3(class = "section-title", "Resolve Local and Data Explorer conflicts"),
    shiny::p(
      class = "page-lead",
      "Exact duplicates are reported and collapsed. Conflicting values stay blocked until you choose which source to retain, or exclude those records."
    ),
    do.call(bslib::layout_columns, c(list(col_widths = c(12)), cards))
  )
}

local_csv_checkpoint_empty_result <- function(data_type) {
  list(
    status = "info",
    messages = sprintf("No %s CSV uploaded yet.", data_type),
    issues = local_csv_v2_empty_issues(),
    data = NULL
  )
}

local_csv_checkpoint_status_tag <- function(result) {
  status <- if (result$status %in% c("success", "warning", "error")) {
    result$status
  } else {
    "info"
  }
  shiny::div(
    class = paste("upload-status", paste0("upload-status-", status)),
    shiny::tags$ul(lapply(result$messages, shiny::tags$li))
  )
}

bind_local_csv_checkpoint <- function(input, output, data_type) {
  spec <- local_csv_checkpoint_specs()[[data_type]]
  if (is.null(spec)) {
    stop(sprintf("Unknown local CSV checkpoint type: %s", data_type), call. = FALSE)
  }

  result <- shiny::reactive({
    upload <- input[[spec$input_id]]
    if (is.null(upload)) {
      return(local_csv_checkpoint_empty_result(data_type))
    }
    read_local_csv_v2(upload$datapath, spec$contract_type)
  })

  output[[local_csv_checkpoint_output_id(data_type, "uploaded")]] <- shiny::reactive({
    !is.null(input[[spec$input_id]])
  })
  shiny::outputOptions(
    output,
    local_csv_checkpoint_output_id(data_type, "uploaded"),
    suspendWhenHidden = FALSE
  )

  output[[local_csv_checkpoint_output_id(data_type, "status")]] <- shiny::renderUI({
    local_csv_checkpoint_status_tag(result())
  })
  output[[local_csv_checkpoint_output_id(data_type, "issues")]] <- DT::renderDataTable({
    shiny::req(!is.null(input[[spec$input_id]]))
    issues <- result()$issues
    if (nrow(issues) == 0L) {
      issues <- local_csv_v2_issue(
        spec$contract_type,
        "success",
        "passed",
        "No validation issues found."
      )
    }
    issues
  }, rownames = FALSE, options = list(scrollX = TRUE, pageLength = 5))
  output[[local_csv_checkpoint_output_id(data_type, "preview")]] <- DT::renderDataTable({
    shiny::req(result()$data)
    utils::head(result()$data, 20L)
  }, rownames = FALSE, options = list(scrollX = TRUE, pageLength = 5))

  result
}
