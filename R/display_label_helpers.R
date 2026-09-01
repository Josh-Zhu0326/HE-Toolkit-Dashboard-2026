# Keep internal dataset and enrichment identifiers stable. These helpers are
# the shared presentation boundary for normal user-facing text.

he_joined_dataset_display_labels <- c(
  joined_core = "Core Joined HE dataset",
  joined_enriched = "Joined HE dataset with optional supporting data"
)

he_optional_supporting_data_display_labels <- c(
  wq = "Water Quality",
  rhs = "River Habitat Survey"
)

display_label_for_value <- function(value, labels) {
  values <- as.character(value)
  mapped <- unname(labels[values])
  use_original <- is.na(mapped)
  mapped[use_original] <- values[use_original]
  mapped
}

joined_dataset_display_label <- function(source_dataset) {
  display_label_for_value(source_dataset, he_joined_dataset_display_labels)
}

optional_supporting_data_display_labels <- function(enrichments) {
  display_label_for_value(
    enrichments,
    he_optional_supporting_data_display_labels
  )
}

optional_supporting_data_rebuild_message <- function() {
  paste(
    "Optional supporting data have changed.",
    "Rebuild the Joined HE dataset with optional supporting data before using it for analysis."
  )
}

enrichment_result_messages <- function(status, provenance) {
  successful <- optional_supporting_data_display_labels(
    provenance$successful_enrichments
  )
  failed <- optional_supporting_data_display_labels(
    provenance$failed_enrichments
  )

  if (length(provenance$selected_enrichments) == 0L) {
    return(paste(
      "No optional supporting data were selected.",
      "The Core Joined HE dataset will continue to be used."
    ))
  }

  if (length(successful) > 0L && length(failed) == 0L) {
    return(c(
      "Optional supporting data were successfully added to the current Joined HE dataset.",
      sprintf("Added supporting data: %s.", paste(successful, collapse = ", "))
    ))
  }

  if (length(successful) > 0L) {
    messages <- c(
      "Some optional supporting data were added successfully.",
      sprintf("Added: %s.", paste(successful, collapse = ", "))
    )
    if (length(failed) > 0L) {
      messages <- c(
        messages,
        sprintf("Could not add: %s.", paste(failed, collapse = ", "))
      )
    }
    return(messages)
  }

  messages <- paste(
    "Optional supporting data could not be added.",
    "The Core Joined HE dataset will continue to be used."
  )
  if (length(failed) > 0L) {
    messages <- c(
      messages,
      sprintf("Could not add: %s.", paste(failed, collapse = ", "))
    )
  }
  messages
}
