# exclusion_log_helpers.R
# -----------------------------------------------------------------------------
# Turns the output of filter_records() into a single, tidy EXCLUSION LOG and
# provides the Shiny pieces to display + download it.
#
# The exclusion log answers, for every record that was dropped OR flagged:
#   WHO   (site_id, date)
#   WHAT  (the value that triggered the rule)
#   WHY   (the rule / message + severity)
#   WHEN  (timestamp)
#
# Log columns (fixed order):
#   site_id | date | excluded_value | rule | severity | timestamp
#
# Depends on: filtering_helpers.R (for filter_records output shape).
# -----------------------------------------------------------------------------

EXCLUSION_LOG_COLUMNS <- c("site_id", "date", "excluded_value",
                           "rule", "severity", "timestamp")

# Empty log with the correct columns (so the UI always has a table to show).
empty_exclusion_log <- function() {
  df <- data.frame(matrix(character(0), nrow = 0, ncol = length(EXCLUSION_LOG_COLUMNS)),
                   stringsAsFactors = FALSE)
  names(df) <- EXCLUSION_LOG_COLUMNS
  df
}

# Build the exclusion log from a filter_records() result.
#   filter_result : list returned by filter_records()
#   timestamp     : override for testing (defaults to current time)
build_exclusion_log <- function(filter_result, timestamp = NULL) {
  if (is.null(timestamp)) {
    timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  }

  parts <- list()

  # 1) Rows that were REMOVED (Errors, duplicates)
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

  # 2) Rows that were KEPT but FLAGGED (Warnings, e.g. small sites)
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

  if (length(parts) == 0) return(empty_exclusion_log())
  do.call(rbind, parts)
}

# Info-level summary message for the log (mirrors format_validation_message).
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

# ---------------------------------------------------------------------------
# Shiny wiring (plain, non-module style to match server.R).
# Copy the UI line into ui.R and the server block into server.R, then point
# `exclusion_log_data` at your filtered result. See docs comment below.
# ---------------------------------------------------------------------------

# UI: add inside the relevant tab in ui.R
#   uiOutput("exclusion_log_status"),
#   DT::dataTableOutput("exclusion_log_table"),
#   downloadButton("download_exclusion_log", "Download exclusion log as CSV")

# SERVER: add inside server function in server.R
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
