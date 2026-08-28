# Reconcile the five local CSV sources with their Data Explorer equivalents.
# Exact cross-source duplicates are collapsed with provenance. Conflicting
# records never receive an implicit winner: a Local/Explorer/exclude decision
# is required before the reconciled data can enter downstream processing.

source_reconciliation_contracts <- function() {
  list(
    biology = list(
      label = "Biology",
      identity_candidates = list(
        c("biol_site_id", "SAMPLE_ID"),
        c("biol_site_id", "sample_id"),
        c("biol_site_id", "SAMPLE_DATE"),
        c("biol_site_id", "date")
      )
    ),
    environmental = list(
      label = "Site environmental",
      identity_candidates = list("biol_site_id")
    ),
    flow = list(
      label = "Daily Flow",
      identity_candidates = list(c("flow_site_id", "date"))
    ),
    wq = list(
      label = "Water Quality",
      identity_candidates = list(c("wq_site_id", "date_time", "det_id"))
    ),
    rhs = list(
      label = "RHS",
      identity_candidates = list("rhs_survey_id")
    )
  )
}

source_reconciliation_types <- function() {
  names(source_reconciliation_contracts())
}

source_reconciliation_contract <- function(data_type) {
  contracts <- source_reconciliation_contracts()
  if (!is.character(data_type) || length(data_type) != 1L ||
      is.na(data_type) || !data_type %in% names(contracts)) {
    stop(
      paste0(
        "Unknown source-reconciliation data type. Use one of: ",
        paste(names(contracts), collapse = ", "),
        "."
      ),
      call. = FALSE
    )
  }
  contracts[[data_type]]
}

source_reconciliation_input_id <- function(data_type) {
  paste0("source_conflict_preference_", data_type)
}

source_reconciliation_nonblank <- function(values) {
  values <- trimws(as.character(values))
  !is.na(values) & nzchar(values)
}

source_reconciliation_value <- function(value) {
  if (length(value) == 0L || is.na(value[[1L]])) {
    return("")
  }
  value <- value[[1L]]
  if (inherits(value, "POSIXt")) {
    return(format(value, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
  }
  if (inherits(value, "Date")) {
    return(format(value, "%Y-%m-%d"))
  }
  if (is.numeric(value) && is.finite(value)) {
    return(format(value, digits = 15L, scientific = FALSE, trim = TRUE))
  }
  trimws(as.character(value))
}

source_reconciliation_values_equal <- function(left, right) {
  left_text <- source_reconciliation_value(left)
  right_text <- source_reconciliation_value(right)
  if (!nzchar(left_text) && !nzchar(right_text)) {
    return(TRUE)
  }
  left_number <- suppressWarnings(as.numeric(left_text))
  right_number <- suppressWarnings(as.numeric(right_text))
  if (is.finite(left_number) && is.finite(right_number)) {
    return(isTRUE(all.equal(left_number, right_number, tolerance = 1e-10)))
  }
  identical(left_text, right_text)
}

source_reconciliation_key_fields <- function(local, explorer, data_type) {
  contract <- source_reconciliation_contract(data_type)
  for (candidate in contract$identity_candidates) {
    if (all(candidate %in% names(local)) && all(candidate %in% names(explorer))) {
      return(candidate)
    }
  }
  character()
}

source_reconciliation_record_keys <- function(data, key_fields) {
  if (nrow(data) == 0L) {
    return(character())
  }
  apply(data[, key_fields, drop = FALSE], 1L, function(row) {
    paste(vapply(as.list(row), source_reconciliation_value, character(1)), collapse = " | ")
  })
}

source_reconciliation_align_rows <- function(rows) {
  rows <- rows[vapply(rows, function(row) is.data.frame(row) && nrow(row) > 0L, logical(1))]
  if (length(rows) == 0L) {
    return(data.frame())
  }
  fields <- unique(unlist(lapply(rows, names), use.names = FALSE))
  aligned <- lapply(rows, function(row) {
    missing <- setdiff(fields, names(row))
    for (field in missing) {
      row[[field]] <- NA
    }
    row[, fields, drop = FALSE]
  })
  result <- do.call(rbind, aligned)
  rownames(result) <- NULL
  result
}

source_reconciliation_merge_row <- function(local_row, explorer_row, prefer = "local") {
  fields <- union(names(local_row), names(explorer_row))
  preferred <- if (identical(prefer, "explorer")) explorer_row else local_row
  fallback <- if (identical(prefer, "explorer")) local_row else explorer_row
  result <- preferred
  for (field in setdiff(fields, names(result))) {
    result[[field]] <- NA
  }
  for (field in intersect(fields, names(fallback))) {
    if (!field %in% names(preferred) ||
        !source_reconciliation_nonblank(result[[field]])[[1L]]) {
      result[[field]] <- fallback[[field]][[1L]]
    }
  }
  result[, fields, drop = FALSE]
}

source_reconciliation_collapse_exact_rows <- function(data) {
  if (!is.data.frame(data) || nrow(data) < 2L) {
    return(data)
  }
  normalised <- as.data.frame(lapply(data, function(column) {
    vapply(seq_along(column), function(index) {
      source_reconciliation_value(column[index])
    }, character(1))
  }), stringsAsFactors = FALSE, check.names = FALSE)
  data[!duplicated(normalised), , drop = FALSE]
}

source_reconciliation_empty_conflicts <- function() {
  data.frame(
    conflict_id = character(),
    data_type = character(),
    record_key = character(),
    differing_fields = character(),
    local_values = character(),
    explorer_values = character(),
    stringsAsFactors = FALSE
  )
}

source_reconciliation_problem <- function(data_type, message) {
  list(
    status = "error",
    ready = FALSE,
    messages = message,
    data = NULL,
    conflicts = source_reconciliation_empty_conflicts(),
    provenance = list(data_type = data_type)
  )
}

reconcile_source_records <- function(
    local = NULL,
    explorer = NULL,
    data_type,
    conflict_preference = NULL) {
  contract <- source_reconciliation_contract(data_type)
  has_local <- is.data.frame(local) && nrow(local) > 0L
  has_explorer <- is.data.frame(explorer) && nrow(explorer) > 0L

  if (!has_local && !has_explorer) {
    return(list(
      status = "info",
      ready = FALSE,
      messages = sprintf("No Local or Data Explorer %s records are available yet.", contract$label),
      data = NULL,
      conflicts = source_reconciliation_empty_conflicts(),
      provenance = list(data_type = data_type, local_rows = 0L, explorer_rows = 0L)
    ))
  }
  if (!has_local || !has_explorer) {
    source_name <- if (has_local) "Local" else "Data Explorer"
    data <- if (has_local) local else explorer
    return(list(
      status = "success",
      ready = TRUE,
      messages = sprintf("Using %d %s %s record(s).", nrow(data), source_name, contract$label),
      data = data,
      conflicts = source_reconciliation_empty_conflicts(),
      provenance = list(
        data_type = data_type,
        local_rows = if (has_local) nrow(local) else 0L,
        explorer_rows = if (has_explorer) nrow(explorer) else 0L,
        exact_duplicates_removed = 0L,
        conflicts = 0L,
        conflict_preference = "not applicable"
      )
    ))
  }

  local <- source_reconciliation_collapse_exact_rows(local)
  explorer <- source_reconciliation_collapse_exact_rows(explorer)
  key_fields <- source_reconciliation_key_fields(local, explorer, data_type)
  if (length(key_fields) == 0L) {
    return(source_reconciliation_problem(
      data_type,
      sprintf(
        "Local and Data Explorer %s records cannot be compared because no supported identity key is shared.",
        contract$label
      )
    ))
  }

  local_keys <- source_reconciliation_record_keys(local, key_fields)
  explorer_keys <- source_reconciliation_record_keys(explorer, key_fields)
  if (any(!nzchar(local_keys)) || any(!nzchar(explorer_keys))) {
    return(source_reconciliation_problem(
      data_type,
      sprintf("%s source reconciliation found a blank record identity.", contract$label)
    ))
  }
  duplicated_local <- unique(local_keys[duplicated(local_keys)])
  duplicated_explorer <- unique(explorer_keys[duplicated(explorer_keys)])
  if (length(duplicated_local) > 0L || length(duplicated_explorer) > 0L) {
    return(source_reconciliation_problem(
      data_type,
      paste0(
        contract$label,
        " source reconciliation found multiple non-identical rows with the same identity in one source: ",
        paste(unique(c(duplicated_local, duplicated_explorer)), collapse = "; "),
        ". Correct that source before combining it."
      )
    ))
  }

  common_keys <- intersect(local_keys, explorer_keys)
  local_only <- local[!local_keys %in% common_keys, , drop = FALSE]
  explorer_only <- explorer[!explorer_keys %in% common_keys, , drop = FALSE]
  compare_fields <- setdiff(intersect(names(local), names(explorer)), key_fields)
  ignored_fields <- c(".record_source", ".source_resolution")
  compare_fields <- setdiff(compare_fields, ignored_fields)
  exact_rows <- list()
  conflicting_rows <- list()
  conflicts <- source_reconciliation_empty_conflicts()

  for (record_key in common_keys) {
    local_row <- local[match(record_key, local_keys), , drop = FALSE]
    explorer_row <- explorer[match(record_key, explorer_keys), , drop = FALSE]
    differing <- compare_fields[!vapply(compare_fields, function(field) {
      source_reconciliation_values_equal(local_row[[field]], explorer_row[[field]])
    }, logical(1))]

    if (length(differing) == 0L) {
      exact_rows[[length(exact_rows) + 1L]] <- source_reconciliation_merge_row(
        local_row,
        explorer_row,
        prefer = "local"
      )
      next
    }

    conflict_id <- paste(data_type, record_key, sep = "::")
    conflicts <- rbind(conflicts, data.frame(
      conflict_id = conflict_id,
      data_type = data_type,
      record_key = record_key,
      differing_fields = paste(differing, collapse = ", "),
      local_values = paste(vapply(differing, function(field) {
        paste0(field, "=", source_reconciliation_value(local_row[[field]]))
      }, character(1)), collapse = "; "),
      explorer_values = paste(vapply(differing, function(field) {
        paste0(field, "=", source_reconciliation_value(explorer_row[[field]]))
      }, character(1)), collapse = "; "),
      stringsAsFactors = FALSE
    ))
    conflicting_rows[[conflict_id]] <- list(local = local_row, explorer = explorer_row)
  }

  preference <- if (is.null(conflict_preference) || length(conflict_preference) == 0L) {
    ""
  } else {
    as.character(conflict_preference)[[1L]]
  }
  if (nrow(conflicts) > 0L && !preference %in% c("local", "explorer", "exclude")) {
    return(list(
      status = "conflict",
      ready = FALSE,
      messages = sprintf(
        "%d conflicting %s record(s) need a source choice before the combined data can be used.",
        nrow(conflicts),
        contract$label
      ),
      data = NULL,
      conflicts = conflicts,
      provenance = list(
        data_type = data_type,
        key_fields = key_fields,
        local_rows = nrow(local),
        explorer_rows = nrow(explorer),
        exact_duplicates_removed = length(exact_rows),
        conflicts = nrow(conflicts),
        conflict_preference = "unresolved"
      )
    ))
  }

  resolved_rows <- list()
  if (nrow(conflicts) > 0L && !identical(preference, "exclude")) {
    resolved_rows <- lapply(conflicting_rows, function(rows) {
      source_reconciliation_merge_row(rows$local, rows$explorer, prefer = preference)
    })
  }
  combined <- source_reconciliation_align_rows(c(
    list(local_only, explorer_only),
    exact_rows,
    resolved_rows
  ))
  messages <- c(
    sprintf(
      "Combined %d Local and %d Data Explorer %s record(s).",
      nrow(local), nrow(explorer), contract$label
    )
  )
  if (length(exact_rows) > 0L) {
    messages <- c(messages, sprintf(
      "Removed %d exact cross-source duplicate(s) and retained reconciliation provenance.",
      length(exact_rows)
    ))
  }
  if (nrow(conflicts) > 0L) {
    action <- switch(
      preference,
      local = "retained the Local records",
      explorer = "retained the Data Explorer records",
      exclude = "excluded the conflicting records"
    )
    messages <- c(messages, sprintf(
      "Resolved %d conflict(s): %s.", nrow(conflicts), action
    ))
  }

  list(
    status = if (nrow(conflicts) > 0L) "warning" else "success",
    ready = TRUE,
    messages = messages,
    data = combined,
    conflicts = conflicts,
    provenance = list(
      data_type = data_type,
      key_fields = key_fields,
      local_rows = nrow(local),
      explorer_rows = nrow(explorer),
      exact_duplicates_removed = length(exact_rows),
      conflicts = nrow(conflicts),
      conflict_preference = if (nrow(conflicts) > 0L) preference else "not applicable"
    )
  )
}

source_reconciliation_ready_data <- function(result) {
  if (is.null(result) || !isTRUE(result$ready) || !is.data.frame(result$data)) {
    message <- if (is.null(result$messages)) {
      "The selected Local and Data Explorer records have not been reconciled."
    } else {
      paste(result$messages, collapse = " ")
    }
    stop(message, call. = FALSE)
  }
  result$data
}
