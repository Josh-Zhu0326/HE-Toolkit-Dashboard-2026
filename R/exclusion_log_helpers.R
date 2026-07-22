# exclusion_log_helpers.R
# This takes what filter_records() gives back and turns it into one tidy log
# table, plus a short summary message.
# For every row that was removed or flagged, the log shows who (site_id, date),
# what value caused it, why (the rule and severity), and when (timestamp).
# The columns are always in this order:
#   site_id, date, excluded_value, rule, severity, timestamp
# Needs filtering_helpers.R because it reads the filter_records() output.

EXCLUSION_LOG_COLUMNS <- c("site_id", "date", "excluded_value",
                           "rule", "severity", "timestamp")

# an empty log with the right columns, so the table always has something to show
empty_exclusion_log <- function() {
  df <- data.frame(matrix(character(0), nrow = 0, ncol = length(EXCLUSION_LOG_COLUMNS)),
                   stringsAsFactors = FALSE)
  names(df) <- EXCLUSION_LOG_COLUMNS
  df
}

# build the log from a filter_records() result.
# timestamp can be passed in for testing, otherwise it uses the current time.
build_exclusion_log <- function(filter_result, timestamp = NULL) {
  if (is.null(timestamp)) {
    timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  }

  parts <- list()

  # rows that were removed (errors and duplicates)
  ex <- filter_result$excluded
  if (!is.null(ex) && nrow(ex) > 0) {
    parts[[length(parts) + 1]] <- data.frame(
      site_id        = as.character(ex$biol_site_id),
      date           = as.character(ex$date),
      excluded_value = if ("excluded_value" %in% names(ex)) as.character(ex$excluded_value) else NA_character_,
      rule           = as.character(ex$exclusion_reason),
      severity       = as.character(ex$severity),
      timestamp      = timestamp,
      stringsAsFactors = FALSE
    )
  }

  # rows we kept but still flagged (warnings, like small sites)
  lg <- filter_result$log
  if (!is.null(lg) && nrow(lg) > 0) {
    parts[[length(parts) + 1]] <- data.frame(
      site_id        = as.character(lg$biol_site_id),
      date           = as.character(lg$date),
      excluded_value = if ("excluded_value" %in% names(lg)) as.character(lg$excluded_value) else NA_character_,
      rule           = as.character(lg$reason),
      severity       = as.character(lg$severity),
      timestamp      = timestamp,
      stringsAsFactors = FALSE
    )
  }

  # nothing to log, return the empty table
  if (length(parts) == 0) return(empty_exclusion_log())
  do.call(rbind, parts)
}

# a short info message about the log, to show above the table
exclusion_log_summary <- function(log) {
  n <- if (is.null(log)) 0 else nrow(log)
  if (n == 0) {
    return(list(status = "info",
                messages = "No records were excluded or flagged."))
  }
  n_err  <- sum(log$severity == "Error")
  n_warn <- sum(log$severity == "Warning")
  list(
    status = "info",
    messages = paste0(
      n, " record(s) were excluded or flagged ",
      "(", n_err, " error(s), ", n_warn, " warning(s)). ",
      "See the exclusion log below for details."
    )
  )
}

# How to wire this into the app (plain style, like the rest of server.R).
# Copy the UI lines into ui.R and the server block into server.R.
#
# UI (inside a tab in ui.R):
#   uiOutput("exclusion_log_status"),
#   DT::dataTableOutput("exclusion_log_table"),
#   downloadButton("download_exclusion_log", "Download exclusion log as CSV")
#
# SERVER (inside the server function in server.R):
#   filtered_inv <- reactive({
#     req(local_inv_upload()$data)
#     filter_records(local_inv_upload()$data)
#   })
#   exclusion_log_data <- reactive({ build_exclusion_log(filtered_inv()) })
#
#   output$exclusion_log_status <- renderUI({
#     format_validation_message(exclusion_log_summary(exclusion_log_data()))
#   })
#   output$exclusion_log_table <- DT::renderDataTable({
#     exclusion_log_data()
#   }, rownames = FALSE, options = list(scrollX = TRUE, pageLength = 10))
#   output$download_exclusion_log <- downloadHandler(
#     filename = function() paste0("exclusion_log_", format(Sys.Date(), "%Y%m%d"), ".csv"),
#     content  = function(file) utils::write.csv(exclusion_log_data(), file, row.names = FALSE)
#   )
