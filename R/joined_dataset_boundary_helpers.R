# joined_dataset_boundary_helpers.R
# WK8-05: keep joined_core, optional enrichment, and analysis data as separate
# layers. These helpers do not run HE Toolkit science functions; they protect
# the data boundary after the core join has been built.

normalise_enrichment_selection <- function(selected_enrichments) {
  selected <- tolower(trimws(as.character(selected_enrichments)))
  selected <- selected[nzchar(selected)]
  unique(selected)
}

normalise_named_enrichment_list <- function(values) {
  if (is.null(values)) {
    return(list())
  }
  names(values) <- normalise_enrichment_selection(names(values))
  values
}

enrichment_result_matches_selection <- function(result, selected_enrichments) {
  if (is.null(result$provenance$selected_enrichments)) {
    return(FALSE)
  }
  identical(
    sort(normalise_enrichment_selection(result$provenance$selected_enrichments)),
    sort(normalise_enrichment_selection(selected_enrichments))
  )
}

joined_dataset_fingerprint <- function(data) {
  if (is.null(data) || !is.data.frame(data)) {
    return(NA_character_)
  }
  paste(
    nrow(data),
    ncol(data),
    paste(names(data), collapse = "|"),
    paste(vapply(data, function(column) {
      paste(as.character(column), collapse = "|")
    }, character(1)), collapse = "||"),
    sep = "::"
  )
}

empty_enrichment_provenance <- function(selected_enrichments) {
  list(
    source_dataset = "joined_core",
    selected_enrichments = normalise_enrichment_selection(selected_enrichments),
    successful_enrichments = character(),
    failed_enrichments = character(),
    failure_reasons = list(),
    coverage = data.frame(
      enrichment = character(),
      matched_rows = integer(),
      source_rows = integer(),
      stringsAsFactors = FALSE
    )
  )
}

enrichment_failure <- function(name, reason) {
  list(status = "failed", name = name, reason = reason)
}

validate_single_enrichment <- function(joined_core, enrichment, name, key) {
  if (is.null(enrichment) || !is.data.frame(enrichment) || nrow(enrichment) == 0) {
    return(enrichment_failure(name, "No enrichment data were supplied."))
  }
  if (!key %in% names(joined_core)) {
    return(enrichment_failure(name, sprintf("Core joined data are missing key '%s'.", key)))
  }
  if (!key %in% names(enrichment)) {
    return(enrichment_failure(name, sprintf("Enrichment data are missing key '%s'.", key)))
  }
  if (anyDuplicated(as.character(enrichment[[key]])) > 0) {
    return(enrichment_failure(name, sprintf("Enrichment key '%s' is not unique.", key)))
  }

  value_columns <- setdiff(names(enrichment), key)
  if (length(value_columns) == 0) {
    return(enrichment_failure(name, "Enrichment data contain no value columns."))
  }

  overlapping <- intersect(value_columns, names(joined_core))
  if (length(overlapping) > 0) {
    return(enrichment_failure(
      name,
      sprintf("Enrichment columns would overwrite core fields: %s.", paste(overlapping, collapse = ", "))
    ))
  }

  list(status = "success", name = name, key = key, value_columns = value_columns)
}

append_single_enrichment <- function(joined, enrichment, key, value_columns) {
  core_key <- as.character(joined[[key]])
  enrichment_key <- as.character(enrichment[[key]])
  match_index <- match(core_key, enrichment_key)
  for (column in value_columns) {
    values <- enrichment[[column]][match_index]
    joined[[column]] <- values
  }
  joined
}

enrichment_coverage <- function(joined_core, enrichment, name, key) {
  core_key <- as.character(joined_core[[key]])
  enrichment_key <- as.character(enrichment[[key]])
  data.frame(
    enrichment = name,
    matched_rows = sum(core_key %in% enrichment_key),
    source_rows = nrow(joined_core),
    stringsAsFactors = FALSE
  )
}

build_joined_enriched <- function(joined_core,
                                  enrichments = list(),
                                  selected_enrichments = names(enrichments),
                                  keys = list(wq = "sample_id", rhs = "biol_site_id")) {
  if (is.null(joined_core) || !is.data.frame(joined_core) || nrow(joined_core) == 0) {
    stop("joined_core must be a non-empty data frame before optional enrichment.", call. = FALSE)
  }

  enrichments <- normalise_named_enrichment_list(enrichments)
  keys <- normalise_named_enrichment_list(keys)
  selected <- normalise_enrichment_selection(selected_enrichments)
  provenance <- empty_enrichment_provenance(selected)
  if (length(selected) == 0) {
    return(list(
      status = "not_ready",
      joined_enriched = NULL,
      messages = enrichment_result_messages("not_ready", provenance),
      provenance = provenance
    ))
  }

  joined_enriched <- joined_core
  for (name in selected) {
    key <- keys[[name]]
    if (is.null(key) || !nzchar(key)) {
      validation <- enrichment_failure(name, "No enrichment join key is configured.")
    } else {
      validation <- validate_single_enrichment(joined_core, enrichments[[name]], name, key)
    }

    if (identical(validation$status, "success")) {
      joined_enriched <- append_single_enrichment(
        joined_enriched,
        enrichments[[name]],
        validation$key,
        validation$value_columns
      )
      provenance$successful_enrichments <- c(provenance$successful_enrichments, name)
      provenance$coverage <- rbind(
        provenance$coverage,
        enrichment_coverage(joined_core, enrichments[[name]], name, validation$key)
      )
    } else {
      provenance$failed_enrichments <- c(provenance$failed_enrichments, name)
      provenance$failure_reasons[[name]] <- validation$reason
    }
  }

  if (length(provenance$successful_enrichments) == 0) {
    return(list(
      status = "warning",
      joined_enriched = NULL,
      messages = enrichment_result_messages("warning", provenance),
      provenance = provenance
    ))
  }

  status <- if (length(provenance$failed_enrichments) > 0) "warning" else "success"

  list(
    status = status,
    joined_enriched = joined_enriched,
    messages = enrichment_result_messages(status, provenance),
    provenance = provenance
  )
}

derive_analysis_dataset <- function(joined_core,
                                    joined_enriched = NULL,
                                    use_enriched = FALSE,
                                    filter_selection = NULL) {
  if (isTRUE(use_enriched) && is.data.frame(joined_enriched) && nrow(joined_enriched) > 0) {
    source_dataset <- "joined_enriched"
    source_data <- joined_enriched
  } else {
    source_dataset <- "joined_core"
    source_data <- joined_core
  }
  source_fingerprint <- joined_dataset_fingerprint(source_data)

  if (!is.null(filter_selection)) {
    if (!exists("apply_filter_selection", mode = "function")) {
      stop("apply_filter_selection() is required to derive a filtered analysis dataset.", call. = FALSE)
    }
    filtered <- apply_filter_selection(source_data, filter_selection)
    analysis <- filtered$analysis_dataset
    filter_version <- filtered$filter_version
  } else {
    analysis <- source_data
    filter_version <- 0L
  }

  list(
    analysis_dataset = analysis,
    source_dataset = source_dataset,
    source_fingerprint = source_fingerprint,
    source_rows = if (is.null(source_data)) 0L else nrow(source_data),
    analysis_rows = if (is.null(analysis)) 0L else nrow(analysis),
    filter_version = filter_version,
    generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  )
}

prepare_wq_enrichment_summary <- function(summary_data, joined_core) {
  if (is.null(summary_data) || !is.data.frame(summary_data) || nrow(summary_data) == 0) {
    return(NULL)
  }
  if (!"sample_id" %in% names(summary_data) || !"sample_id" %in% names(joined_core)) {
    return(NULL)
  }

  protected <- names(joined_core)
  keep <- c(
    "sample_id",
    setdiff(names(summary_data), protected)
  )
  keep <- keep[keep %in% names(summary_data)]
  summary_data[, keep, drop = FALSE]
}

prepare_rhs_enrichment_summary <- function(rhs_data, joined_core) {
  if (is.null(rhs_data) || !is.data.frame(rhs_data) || nrow(rhs_data) == 0) {
    return(NULL)
  }
  if (!"biol_site_id" %in% names(rhs_data) || !"biol_site_id" %in% names(joined_core)) {
    return(NULL)
  }

  candidate_columns <- c(
    "survey_date", "rhs_survey_date",
    "HMSRBB", "HMS.Class", "HQA", "HQA.Adjusted",
    "Hms.Poaching.Sub.Score", "Bed.Material.Description",
    "Predominant.Flow.Type", "habitat_notes"
  )
  keep <- c("biol_site_id", intersect(candidate_columns, names(rhs_data)))
  if (length(keep) <= 1L) {
    keep <- c("biol_site_id", setdiff(names(rhs_data), c(names(joined_core), "rhs_survey_id")))
  }
  keep <- keep[keep %in% names(rhs_data)]
  rhs_summary <- rhs_data[, keep, drop = FALSE]
  unique(rhs_summary)
}
