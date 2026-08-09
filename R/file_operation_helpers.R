# RAW-19 / RAW-21 file-operation recovery boundary. Keep this focused on
# writing, copying and runtime filesystem access; scientific operations,
# external imports and plot construction retain their own contracts.

file_operation_user_message <- function() {
  paste(
    "The file could not be created or saved.",
    "Check that the destination is available and writable, then try again."
  )
}

safe_file_operation <- function(operation,
                                user_message = file_operation_user_message()) {
  if (!is.function(operation)) {
    stop("File recovery requires an operation function.", call. = FALSE)
  }

  tryCatch(
    list(
      status = "success",
      failure = NULL,
      value = operation(),
      message = NULL,
      diagnostic = NULL
    ),
    error = function(error) {
      list(
        status = "failed",
        failure = "file_operation_error",
        value = NULL,
        message = user_message,
        diagnostic = conditionMessage(error)
      )
    }
  )
}

new_file_operation_error <- function(result) {
  if (!is.list(result) || !identical(result$status, "failed")) {
    stop("A failed file-operation result is required.", call. = FALSE)
  }

  structure(
    list(
      message = result$message,
      call = NULL,
      failure = result$failure,
      diagnostic = result$diagnostic
    ),
    class = c("dashboard_file_operation_error", "error", "condition")
  )
}

abort_file_operation <- function(result) {
  stop(new_file_operation_error(result))
}

file_operation_condition_result <- function(error) {
  if (!inherits(error, "dashboard_file_operation_error")) {
    stop("A dashboard file-operation error is required.", call. = FALSE)
  }

  list(
    status = "failed",
    failure = error$failure,
    value = NULL,
    message = conditionMessage(error),
    diagnostic = error$diagnostic
  )
}
