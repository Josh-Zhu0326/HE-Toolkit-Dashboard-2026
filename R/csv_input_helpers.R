read_character_csv <- function(path = NULL, text = NULL) {
  parser_warnings <- character(0)
  data <- tryCatch(
    withCallingHandlers(
      if (is.null(text)) {
        data.table::fread(
          path,
          colClasses = "character",
          data.table = FALSE,
          encoding = "UTF-8"
        )
      } else {
        data.table::fread(
          text = text,
          colClasses = "character",
          data.table = FALSE
        )
      },
      warning = function(warning) {
        parser_warnings <<- c(parser_warnings, conditionMessage(warning))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(error) NULL
  )

  if (is.null(data) || length(parser_warnings) > 0L) {
    return(NULL)
  }
  data
}
