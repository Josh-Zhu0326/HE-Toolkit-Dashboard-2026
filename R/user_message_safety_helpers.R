raw24_contains_internal_detail <- function(message) {
  if (!is.character(message) || length(message) != 1L || is.na(message)) {
    return(TRUE)
  }

  url_token <- "\\bhttps?://[^[:space:]'\\\"<>|]+"
  path_scan_message <- gsub(
    url_token,
    "",
    message,
    ignore.case = TRUE,
    perl = TRUE
  )
  absolute_posix_path <- paste0(
    "(^|[^[:alnum:]_./-])",
    "/(?!/)[^[:space:]'\\\"<>|]*"
  )
  absolute_windows_path <- paste0(
    "(?<![[:alnum:]_.-])[A-Za-z]:[/\\\\]",
    "|\\\\\\\\[^\\\\/[:space:]]+[\\\\/][^[:space:]'\\\"<>|]+"
  )

  contains_absolute_path <- grepl(
    paste(absolute_windows_path, absolute_posix_path, sep = "|"),
    path_scan_message,
    ignore.case = TRUE,
    perl = TRUE
  )
  contains_technical_detail <- grepl(
    paste(
      "[\\r\\n]",
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

  contains_absolute_path || contains_technical_detail
}

raw24_safe_condition_message <- function(error, safe_prefixes, fallback) {
  diagnostic <- conditionMessage(error)
  trusted_message <- any(startsWith(diagnostic, safe_prefixes)) &&
    !raw24_contains_internal_detail(diagnostic)
  if (isTRUE(trusted_message)) diagnostic else fallback
}
