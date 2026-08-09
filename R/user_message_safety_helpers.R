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
