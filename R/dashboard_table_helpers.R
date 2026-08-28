# Shared DataTables defaults for wide dashboard data. Keep this helper focused
# on browsing behaviour so individual outputs still own their data semantics.
dashboard_datatable <- function(data,
                                frozen_columns = 1L,
                                page_length = 25L,
                                numeric_digits = 3L,
                                column_filter = TRUE) {
  data <- as.data.frame(data, stringsAsFactors = FALSE)
  frozen_columns <- max(0L, min(as.integer(frozen_columns), ncol(data)))

  extensions <- character()
  options <- list(
    scrollX = TRUE,
    autoWidth = FALSE,
    pageLength = as.integer(page_length),
    lengthMenu = c(10L, 25L, 50L),
    searching = TRUE,
    ordering = TRUE
  )

  if (frozen_columns > 0L) {
    extensions <- "FixedColumns"
    options$fixedColumns <- list(leftColumns = frozen_columns)
  }

  table <- DT::datatable(
    data,
    rownames = FALSE,
    filter = if (isTRUE(column_filter)) "top" else "none",
    extensions = extensions,
    options = options
  )

  numeric_columns <- names(data)[vapply(data, is.numeric, logical(1))]
  if (length(numeric_columns) > 0L) {
    table <- DT::formatRound(table, columns = numeric_columns, digits = numeric_digits)
  }

  table
}
