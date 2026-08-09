external_import_failure <- function(failure, diagnostic = NULL) {
  list(
    status = "error",
    data = NULL,
    failure = failure,
    diagnostic = diagnostic
  )
}

safe_external_import <- function(operation, required_columns = character()) {
  result <- tryCatch(
    operation(),
    error = function(error) {
      structure(
        list(message = conditionMessage(error)),
        class = "dashboard_external_import_error"
      )
    }
  )

  if (inherits(result, "dashboard_external_import_error")) {
    return(external_import_failure("request_failed", result$message))
  }
  if (is.null(result)) {
    return(external_import_failure("empty_result"))
  }
  if (!is.data.frame(result)) {
    return(external_import_failure(
      "invalid_result",
      "The external result was not tabular."
    ))
  }
  if (nrow(result) == 0L) {
    return(external_import_failure("empty_result"))
  }

  missing_columns <- setdiff(required_columns, names(result))
  if (length(missing_columns) > 0L) {
    return(external_import_failure(
      "invalid_result",
      paste("Missing required result columns:", paste(missing_columns, collapse = ", "))
    ))
  }
  unusable_columns <- required_columns[vapply(
    required_columns,
    function(column) {
      values <- result[[column]]
      all(is.na(values) | !nzchar(trimws(as.character(values))))
    },
    logical(1)
  )]
  if (length(unusable_columns) > 0L) {
    return(external_import_failure(
      "invalid_result",
      paste("Required result columns contain no usable values:", paste(unusable_columns, collapse = ", "))
    ))
  }

  list(
    status = "success",
    data = as.data.frame(result),
    failure = NULL,
    diagnostic = NULL
  )
}
