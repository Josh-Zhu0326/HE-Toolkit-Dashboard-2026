# Processed dataset checkpoints are portable, versioned R objects used to move
# a Joined HE dataset between dashboard sessions without rerunning imports.

processed_dataset_checkpoint_schema_version <- "1.0.0"

processed_dataset_checksum <- function(dataset) {
  checksum_file <- tempfile("processed-dataset-checksum-", fileext = ".bin")
  on.exit(unlink(checksum_file, force = TRUE), add = TRUE)
  writeBin(serialize(dataset, NULL, xdr = TRUE, version = 3L), checksum_file)
  checksum <- unname(tools::md5sum(checksum_file))
  if (length(checksum) != 1L || is.na(checksum) || !nzchar(checksum)) {
    stop("Processed dataset checksum could not be calculated.", call. = FALSE)
  }
  checksum
}

processed_dataset_column_classes <- function(dataset) {
  vapply(dataset, function(column) paste(class(column), collapse = "/"), character(1))
}

validate_processed_dataset <- function(dataset) {
  if (!is.data.frame(dataset) || nrow(dataset) < 1L || ncol(dataset) < 1L) {
    stop("Processed dataset checkpoint must contain a non-empty data frame.", call. = FALSE)
  }
  if (is.null(names(dataset)) || any(!nzchar(names(dataset))) || anyDuplicated(names(dataset))) {
    stop("Processed dataset checkpoint has invalid or duplicate column names.", call. = FALSE)
  }
  if (!"biol_site_id" %in% names(dataset)) {
    stop("Processed dataset checkpoint is missing required column 'biol_site_id'.", call. = FALSE)
  }
  if (!any(c("record_id", "sample_id") %in% names(dataset))) {
    stop("Processed dataset checkpoint requires a record_id or sample_id column.", call. = FALSE)
  }
  if (!"Year" %in% names(dataset)) {
    stop("Processed dataset checkpoint is missing required column 'Year'.", call. = FALSE)
  }
  supported_column <- vapply(
    dataset,
    function(column) is.atomic(column) || inherits(column, c("Date", "POSIXct", "POSIXlt")),
    logical(1)
  )
  if (any(!supported_column)) {
    stop("Processed dataset checkpoint contains an unsupported non-atomic column.", call. = FALSE)
  }
  if (anyNA(dataset$biol_site_id) || any(!nzchar(trimws(as.character(dataset$biol_site_id))))) {
    stop("Processed dataset checkpoint contains a missing biology site identifier.", call. = FALSE)
  }

  invisible(TRUE)
}

new_processed_dataset_checkpoint <- function(
    dataset,
    provenance = list(),
    app_version = workspace_app_version(),
    created_at = Sys.time()) {
  validate_processed_dataset(dataset)
  if (!is.list(provenance)) {
    stop("Processed dataset provenance must be a named list.", call. = FALSE)
  }

  checkpoint <- list(
    manifest = list(
      schema_version = processed_dataset_checkpoint_schema_version,
      created_at = format(as.POSIXct(created_at, tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      app_version = as.character(app_version)[[1L]],
      checksum_algorithm = "md5",
      dataset_checksum = processed_dataset_checksum(dataset),
      rows = as.integer(nrow(dataset)),
      columns = as.integer(ncol(dataset)),
      column_names = names(dataset),
      column_classes = processed_dataset_column_classes(dataset),
      provenance = provenance
    ),
    dataset = dataset
  )
  validate_processed_dataset_checkpoint(checkpoint)
  checkpoint
}

validate_processed_dataset_checkpoint <- function(checkpoint) {
  if (!is.list(checkpoint) || !identical(names(checkpoint), c("manifest", "dataset"))) {
    stop("Processed dataset checkpoint structure is invalid.", call. = FALSE)
  }
  manifest <- checkpoint$manifest
  required_manifest_fields <- c(
    "schema_version", "created_at", "app_version", "checksum_algorithm",
    "dataset_checksum", "rows", "columns", "column_names", "column_classes",
    "provenance"
  )
  if (!is.list(manifest) || !all(required_manifest_fields %in% names(manifest))) {
    stop("Processed dataset checkpoint manifest is incomplete.", call. = FALSE)
  }
  if (!identical(manifest$schema_version, processed_dataset_checkpoint_schema_version)) {
    stop(
      "Processed dataset checkpoint schema is not supported.",
      call. = FALSE
    )
  }
  if (!identical(manifest$checksum_algorithm, "md5") ||
      length(manifest$dataset_checksum) != 1L ||
      !grepl("^[0-9a-f]{32}$", manifest$dataset_checksum)) {
    stop("Processed dataset checkpoint checksum metadata is invalid.", call. = FALSE)
  }

  dataset <- checkpoint$dataset
  validate_processed_dataset(dataset)
  if (!identical(as.integer(manifest$rows), as.integer(nrow(dataset))) ||
      !identical(as.integer(manifest$columns), as.integer(ncol(dataset))) ||
      !identical(as.character(manifest$column_names), names(dataset)) ||
      !identical(
        unname(as.character(manifest$column_classes)),
        unname(processed_dataset_column_classes(dataset))
      )) {
    stop("Processed dataset checkpoint schema does not match its dataset.", call. = FALSE)
  }
  if (!identical(processed_dataset_checksum(dataset), manifest$dataset_checksum)) {
    stop("Processed dataset checkpoint failed its integrity check.", call. = FALSE)
  }
  if (!is.list(manifest$provenance)) {
    stop("Processed dataset checkpoint provenance is invalid.", call. = FALSE)
  }

  invisible(TRUE)
}

write_processed_dataset_checkpoint <- function(
    dataset,
    path,
    provenance = list(),
    app_version = workspace_app_version(),
    created_at = Sys.time()) {
  checkpoint <- new_processed_dataset_checkpoint(
    dataset = dataset,
    provenance = provenance,
    app_version = app_version,
    created_at = created_at
  )
  tryCatch(
    saveRDS(checkpoint, path, compress = "gzip", version = 3L),
    error = function(error) {
      stop("Processed dataset checkpoint could not be written.", call. = FALSE)
    }
  )
  invisible(checkpoint$manifest)
}

read_processed_dataset_checkpoint <- function(path) {
  if (!is.character(path) || length(path) != 1L || is.na(path) || !file.exists(path)) {
    stop("Processed dataset checkpoint file was not found.", call. = FALSE)
  }
  checkpoint <- tryCatch(
    readRDS(path),
    error = function(error) {
      stop("Processed dataset checkpoint could not be read.", call. = FALSE)
    }
  )
  validate_processed_dataset_checkpoint(checkpoint)
  checkpoint
}

processed_dataset_checkpoint_hev_data <- function(dataset) {
  validate_processed_dataset(dataset)
  if (!"date" %in% names(dataset)) {
    stop(
      "Processed dataset checkpoint does not contain the sample date required for HEV.",
      call. = FALSE
    )
  }

  hev_data <- dataset
  if (!inherits(hev_data$date, "Date")) {
    converted <- suppressWarnings(as.Date(hev_data$date))
    if (anyNA(converted) && any(!is.na(hev_data$date))) {
      stop(
        "Processed dataset checkpoint contains an invalid sample date for HEV.",
        call. = FALSE
      )
    }
    hev_data$date <- converted
  }

  lag_zero_columns <- grep("_lag0$", names(hev_data), value = TRUE)
  for (column_name in lag_zero_columns) {
    hev_name <- sub("_lag0$", "", column_name)
    if (!hev_name %in% names(hev_data)) {
      names(hev_data)[names(hev_data) == column_name] <- hev_name
    }
  }
  if ("win_no_lag0" %in% names(hev_data)) {
    hev_data$win_no_lag0 <- NULL
  }
  hev_data
}
