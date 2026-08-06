# Storage backends implement the generics in this file. The server-file backend
# uses immutable, checksum-addressed RDS objects so named copies can share data.

workspace_storage_save <- function(storage, snapshot, context = NULL) {
  UseMethod("workspace_storage_save")
}

workspace_storage_load <- function(
    storage, workspace_name, dataset_names = NULL, context = NULL) {
  UseMethod("workspace_storage_load")
}

workspace_storage_list <- function(storage, context = NULL) {
  UseMethod("workspace_storage_list")
}

workspace_storage_get_manifest <- function(storage, workspace_name, context = NULL) {
  UseMethod("workspace_storage_get_manifest")
}

workspace_storage_delete <- function(storage, workspace_name, context = NULL) {
  UseMethod("workspace_storage_delete")
}

workspace_storage_prune_objects <- function(storage) {
  UseMethod("workspace_storage_prune_objects")
}

workspace_storage_capabilities <- function(storage) {
  UseMethod("workspace_storage_capabilities")
}

new_workspace_storage_capabilities <- function(
    location,
    configured,
    requires_auth,
    operations = c("save", "load", "list", "get_manifest", "delete"),
    label = location) {
  allowed_locations <- c("browser", "server-file", "cloud")
  allowed_operations <- c(
    "save", "load", "list", "get_manifest", "delete", "prune_objects"
  )
  if (!is.character(location) || length(location) != 1L ||
      !location %in% allowed_locations) {
    stop("Workspace storage location is invalid.", call. = FALSE)
  }
  for (field in c("configured", "requires_auth")) {
    value <- get(field)
    if (!is.logical(value) || length(value) != 1L || is.na(value)) {
      stop(sprintf("Workspace storage %s must be one logical value.", field), call. = FALSE)
    }
  }
  if (!is.character(operations) || anyNA(operations) ||
      any(!operations %in% allowed_operations)) {
    stop("Workspace storage operations are invalid.", call. = FALSE)
  }
  if (!is.character(label) || length(label) != 1L || is.na(label) || !nzchar(label)) {
    stop("Workspace storage label must be one non-empty text value.", call. = FALSE)
  }

  structure(
    list(
      location = location,
      configured = configured,
      requires_auth = requires_auth,
      operations = unique(operations),
      label = label
    ),
    class = "workspace_storage_capabilities"
  )
}

normalize_workspace_access_context <- function(context) {
  if (is.null(context)) {
    context <- new_workspace_access_context()
  }
  validate_workspace_access_context(context)
  context
}

workspace_storage_operation_available <- function(storage, operation, context = NULL) {
  capabilities <- workspace_storage_capabilities(storage)
  if (!is.character(operation) || length(operation) != 1L ||
      is.na(operation) || !nzchar(operation)) {
    stop("Workspace storage operation must be one text value.", call. = FALSE)
  }
  if (!isTRUE(capabilities$configured) || !operation %in% capabilities$operations) {
    return(FALSE)
  }
  context <- normalize_workspace_access_context(context)
  !isTRUE(capabilities$requires_auth) || isTRUE(context$identity$authenticated)
}

workspace_storage_root <- function() {
  configured <- getOption("hetoolkit.workspace_root", "")
  if (is.character(configured) && length(configured) == 1L && nzchar(configured)) {
    return(configured)
  }

  configured <- Sys.getenv("HE_TOOLKIT_WORKSPACE_ROOT", unset = "")
  if (nzchar(configured)) {
    return(configured)
  }

  file.path(tools::R_user_dir("he-toolkit-dashboard", which = "data"), "workspaces")
}

new_server_file_workspace_storage <- function(root_dir = workspace_storage_root()) {
  if (!is.character(root_dir) || length(root_dir) != 1L ||
      is.na(root_dir) || !nzchar(trimws(root_dir))) {
    stop("Server-file workspace storage requires one root directory.", call. = FALSE)
  }

  structure(
    list(root_dir = normalizePath(root_dir, winslash = "/", mustWork = FALSE)),
    class = c(
      "server_file_workspace_storage",
      "local_workspace_storage",
      "workspace_storage"
    )
  )
}

new_local_workspace_storage <- function(root_dir = workspace_storage_root()) {
  new_server_file_workspace_storage(root_dir)
}

new_browser_workspace_storage <- function(database_name = "he-toolkit-workspaces") {
  if (!is.character(database_name) || length(database_name) != 1L ||
      is.na(database_name) || !nzchar(trimws(database_name))) {
    stop("Browser workspace storage requires one database name.", call. = FALSE)
  }
  structure(
    list(database_name = trimws(database_name)),
    class = c("browser_workspace_storage", "workspace_storage")
  )
}

new_cloud_workspace_storage <- function(endpoint, auth_provider) {
  if (!is.character(endpoint) || length(endpoint) != 1L ||
      is.na(endpoint) || !nzchar(trimws(endpoint))) {
    stop("Cloud workspace storage requires one endpoint.", call. = FALSE)
  }
  validate_workspace_auth_provider(auth_provider)

  structure(
    list(endpoint = trimws(endpoint), auth_provider = auth_provider),
    class = c("cloud_workspace_storage", "workspace_storage")
  )
}

workspace_storage_for_session <- function(session = NULL) {
  factory <- getOption("hetoolkit.workspace_storage_factory", NULL)
  if (is.null(factory)) {
    return(new_server_file_workspace_storage())
  }
  if (!is.function(factory)) {
    stop("The configured workspace storage factory must be a function.", call. = FALSE)
  }
  storage <- factory(session)
  if (!inherits(storage, "workspace_storage")) {
    stop("The workspace storage factory returned an invalid backend.", call. = FALSE)
  }
  workspace_storage_capabilities(storage)
  storage
}

workspace_storage_capabilities.server_file_workspace_storage <- function(storage) {
  new_workspace_storage_capabilities(
    location = "server-file",
    configured = TRUE,
    requires_auth = FALSE,
    operations = c(
      "save", "load", "list", "get_manifest", "delete", "prune_objects"
    ),
    label = "this computer"
  )
}

workspace_storage_capabilities.local_workspace_storage <- function(storage) {
  workspace_storage_capabilities.server_file_workspace_storage(storage)
}

workspace_storage_capabilities.browser_workspace_storage <- function(storage) {
  new_workspace_storage_capabilities(
    location = "browser",
    configured = FALSE,
    requires_auth = FALSE,
    label = "this browser"
  )
}

workspace_storage_capabilities.cloud_workspace_storage <- function(storage) {
  new_workspace_storage_capabilities(
    location = "cloud",
    configured = FALSE,
    requires_auth = TRUE,
    label = "configured cloud service"
  )
}

workspace_browser_not_configured <- function() {
  stop(
    paste(
      "Browser workspace storage is not configured.",
      "Implement the IndexedDB bridge before enabling workspace actions."
    ),
    call. = FALSE
  )
}

workspace_storage_save.browser_workspace_storage <- function(
    storage, snapshot, context = NULL) {
  normalize_workspace_access_context(context)
  workspace_browser_not_configured()
}

workspace_storage_load.browser_workspace_storage <- function(
    storage, workspace_name, dataset_names = NULL, context = NULL) {
  normalize_workspace_access_context(context)
  workspace_browser_not_configured()
}

workspace_storage_list.browser_workspace_storage <- function(storage, context = NULL) {
  normalize_workspace_access_context(context)
  workspace_browser_not_configured()
}

workspace_storage_get_manifest.browser_workspace_storage <- function(
    storage, workspace_name, context = NULL) {
  normalize_workspace_access_context(context)
  workspace_browser_not_configured()
}

workspace_storage_delete.browser_workspace_storage <- function(
    storage, workspace_name, context = NULL) {
  normalize_workspace_access_context(context)
  workspace_browser_not_configured()
}

workspace_storage_prune_objects.browser_workspace_storage <- function(storage) {
  workspace_browser_not_configured()
}

workspace_cloud_not_configured <- function() {
  stop(
    paste(
      "Cloud workspace storage is not configured.",
      "Implement the workspace storage generics for the selected provider."
    ),
    call. = FALSE
  )
}

workspace_cloud_require_authenticated <- function(context) {
  context <- normalize_workspace_access_context(context)
  if (!isTRUE(context$identity$authenticated)) {
    stop("Cloud workspace storage requires an authenticated user.", call. = FALSE)
  }
  context
}

workspace_storage_save.cloud_workspace_storage <- function(
    storage, snapshot, context = NULL) {
  workspace_cloud_require_authenticated(context)
  workspace_cloud_not_configured()
}

workspace_storage_load.cloud_workspace_storage <- function(
    storage, workspace_name, dataset_names = NULL, context = NULL) {
  workspace_cloud_require_authenticated(context)
  workspace_cloud_not_configured()
}

workspace_storage_list.cloud_workspace_storage <- function(storage, context = NULL) {
  workspace_cloud_require_authenticated(context)
  workspace_cloud_not_configured()
}

workspace_storage_get_manifest.cloud_workspace_storage <- function(
    storage, workspace_name, context = NULL) {
  workspace_cloud_require_authenticated(context)
  workspace_cloud_not_configured()
}

workspace_storage_delete.cloud_workspace_storage <- function(
    storage, workspace_name, context = NULL) {
  workspace_cloud_require_authenticated(context)
  workspace_cloud_not_configured()
}

workspace_storage_prune_objects.cloud_workspace_storage <- function(storage) {
  workspace_cloud_not_configured()
}

local_workspace_paths <- function(storage) {
  list(
    root = storage$root_dir,
    workspaces = file.path(storage$root_dir, "named"),
    objects = file.path(storage$root_dir, "objects"),
    staging = file.path(storage$root_dir, ".staging")
  )
}

ensure_local_workspace_directories <- function(storage) {
  paths <- local_workspace_paths(storage)
  for (path in unname(paths[c("root", "workspaces", "objects", "staging")])) {
    if (!dir.exists(path) && !dir.create(path, recursive = TRUE, showWarnings = FALSE)) {
      stop("Local workspace storage could not be prepared.", call. = FALSE)
    }
  }
  invisible(paths)
}

workspace_checksum <- function(path) {
  checksum <- unname(tools::md5sum(path))
  if (length(checksum) != 1L || is.na(checksum) || !nzchar(checksum)) {
    stop("A saved workspace file could not be checksummed.", call. = FALSE)
  }
  checksum
}

workspace_file_bytes <- function(path) {
  bytes <- unname(file.info(path)$size)
  if (length(bytes) != 1L || is.na(bytes)) 0 else as.numeric(bytes)
}

workspace_dataset_metadata <- function(dataset_name, value, checksum, bytes) {
  dimensions <- dim(value)
  list(
    dataset_name = dataset_name,
    object_key = checksum,
    format = "rds",
    compression = "gzip",
    checksum_algorithm = "md5",
    checksum = checksum,
    bytes = bytes,
    artifact_ids = workspace_dataset_artifact_ids(dataset_name),
    class = class(value),
    rows = if (length(dimensions) >= 1L) as.integer(dimensions[[1L]]) else NULL,
    columns = if (length(dimensions) >= 2L) as.integer(dimensions[[2L]]) else NULL,
    column_names = if (!is.null(names(value))) names(value) else character()
  )
}

validate_workspace_manifest <- function(manifest) {
  if (!is.list(manifest) ||
      !all(c("schema_version", "workspace", "state", "datasets", "storage") %in%
           names(manifest))) {
    stop("Saved workspace manifest is incomplete.", call. = FALSE)
  }
  if (!identical(manifest$schema_version, workspace_schema_version)) {
    stop(
      sprintf(
        "Workspace schema '%s' is not supported by this application.",
        as.character(manifest$schema_version)
      ),
      call. = FALSE
    )
  }
  if (!is.list(manifest$workspace) ||
      !all(c("workspace_id", "workspace_name", "directory_name", "saved_at") %in%
           names(manifest$workspace))) {
    stop("Saved workspace identity metadata is incomplete.", call. = FALSE)
  }
  if (!identical(
    manifest$workspace$directory_name,
    workspace_directory_name(manifest$workspace$workspace_name)
  )) {
    stop("Saved workspace directory metadata is invalid.", call. = FALSE)
  }
  if (!is.list(manifest$state) ||
      !all(c("file", "checksum_algorithm", "checksum", "bytes") %in%
           names(manifest$state)) ||
      !identical(manifest$state$file, "state.rds") ||
      !grepl("^[0-9a-f]{32}$", manifest$state$checksum)) {
    stop("Saved workspace state metadata is invalid.", call. = FALSE)
  }
  if (!is.list(manifest$datasets) ||
      (length(manifest$datasets) > 0L &&
       (is.null(names(manifest$datasets)) || anyDuplicated(names(manifest$datasets)) ||
        any(!grepl("^[A-Za-z0-9_.-]+$", names(manifest$datasets)))))) {
    stop("Saved workspace dataset manifest is invalid.", call. = FALSE)
  }
  for (dataset_name in names(manifest$datasets)) {
    entry <- manifest$datasets[[dataset_name]]
    if (!is.list(entry) ||
        !all(c("dataset_name", "object_key", "checksum", "bytes") %in% names(entry)) ||
        !identical(entry$dataset_name, dataset_name) ||
        !identical(entry$object_key, entry$checksum) ||
        !grepl("^[0-9a-f]{32}$", entry$checksum)) {
      stop(sprintf("Saved dataset '%s' has invalid manifest metadata.", dataset_name), call. = FALSE)
    }
  }

  invisible(TRUE)
}

workspace_storage_save.local_workspace_storage <- function(
    storage, snapshot, context = NULL) {
  normalize_workspace_access_context(context)
  validate_workspace_snapshot(snapshot)
  paths <- ensure_local_workspace_directories(storage)
  directory_name <- snapshot$workspace$directory_name
  destination <- file.path(paths$workspaces, directory_name)

  existing_directories <- basename(list.dirs(
    paths$workspaces,
    full.names = TRUE,
    recursive = FALSE
  ))
  name_already_exists <- tolower(directory_name) %in% tolower(existing_directories)
  if (name_already_exists || dir.exists(destination) || file.exists(destination)) {
    stop(
      sprintf("A workspace named '%s' already exists. Choose a new name.", snapshot$workspace$workspace_name),
      call. = FALSE
    )
  }

  staging_dir <- file.path(
    paths$staging,
    paste0(directory_name, "-", snapshot$workspace$workspace_id)
  )
  if (dir.exists(staging_dir)) {
    unlink(staging_dir, recursive = TRUE, force = TRUE)
  }
  if (!dir.create(staging_dir, recursive = TRUE, showWarnings = FALSE)) {
    stop("Workspace staging directory could not be created.", call. = FALSE)
  }
  published <- FALSE
  on.exit({
    if (!published && dir.exists(staging_dir)) {
      unlink(staging_dir, recursive = TRUE, force = TRUE)
    }
  }, add = TRUE)

  dataset_manifest <- list()
  for (dataset_name in names(snapshot$datasets)) {
    staged_object <- file.path(staging_dir, paste0("dataset-", dataset_name, ".rds"))
    tryCatch(
      saveRDS(snapshot$datasets[[dataset_name]], staged_object, compress = "gzip", version = 3L),
      error = function(error) {
        stop(sprintf("Dataset '%s' could not be saved.", dataset_name), call. = FALSE)
      }
    )

    checksum <- workspace_checksum(staged_object)
    object_path <- file.path(paths$objects, paste0(checksum, ".rds"))
    if (!file.exists(object_path)) {
      moved <- file.rename(staged_object, object_path)
      if (!moved && !file.exists(object_path)) {
        stop(sprintf("Dataset '%s' could not be published.", dataset_name), call. = FALSE)
      }
    }
    if (!identical(workspace_checksum(object_path), checksum)) {
      stop(
        sprintf("Dataset '%s' conflicts with an existing invalid data object.", dataset_name),
        call. = FALSE
      )
    }
    if (file.exists(staged_object)) {
      unlink(staged_object, force = TRUE)
    }

    dataset_manifest[[dataset_name]] <- workspace_dataset_metadata(
      dataset_name,
      snapshot$datasets[[dataset_name]],
      checksum,
      workspace_file_bytes(object_path)
    )
  }

  stored_snapshot <- snapshot
  stored_snapshot$datasets <- list()
  state_path <- file.path(staging_dir, "state.rds")
  saveRDS(stored_snapshot, state_path, compress = "gzip", version = 3L)

  manifest <- list(
    schema_version = workspace_schema_version,
    workspace = snapshot$workspace,
    state = list(
      file = "state.rds",
      format = "rds",
      compression = "gzip",
      checksum_algorithm = "md5",
      checksum = workspace_checksum(state_path),
      bytes = workspace_file_bytes(state_path)
    ),
    datasets = dataset_manifest,
    storage = list(
      backend = "local-content-addressed-v1",
      object_directory = "objects"
    )
  )
  validate_workspace_manifest(manifest)
  saveRDS(manifest, file.path(staging_dir, "manifest.rds"), compress = "gzip", version = 3L)
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("The jsonlite package is required to write workspace manifests.", call. = FALSE)
  }
  jsonlite::write_json(
    manifest,
    file.path(staging_dir, "manifest.json"),
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null",
    na = "null"
  )

  if (!file.rename(staging_dir, destination)) {
    stop("Workspace could not be published to local storage.", call. = FALSE)
  }
  published <- TRUE

  list(
    workspace_id = snapshot$workspace$workspace_id,
    workspace_name = snapshot$workspace$workspace_name,
    directory_name = directory_name,
    saved_at = snapshot$workspace$saved_at,
    dataset_count = length(dataset_manifest),
    bytes = sum(vapply(dataset_manifest, `[[`, numeric(1), "bytes")) +
      manifest$state$bytes,
    backend = manifest$storage$backend
  )
}

local_workspace_directory <- function(storage, workspace_name) {
  paths <- local_workspace_paths(storage)
  file.path(paths$workspaces, workspace_directory_name(workspace_name))
}

workspace_storage_get_manifest.local_workspace_storage <- function(
    storage, workspace_name, context = NULL) {
  normalize_workspace_access_context(context)
  workspace_dir <- local_workspace_directory(storage, workspace_name)
  manifest_path <- file.path(workspace_dir, "manifest.rds")
  if (!file.exists(manifest_path)) {
    stop(sprintf("Workspace '%s' was not found.", validate_workspace_name(workspace_name)), call. = FALSE)
  }

  manifest <- tryCatch(
    readRDS(manifest_path),
    error = function(error) stop("Saved workspace manifest could not be read.", call. = FALSE)
  )
  validate_workspace_manifest(manifest)
  manifest
}

workspace_storage_load.local_workspace_storage <- function(
    storage, workspace_name, dataset_names = NULL, context = NULL) {
  context <- normalize_workspace_access_context(context)
  manifest <- workspace_storage_get_manifest(storage, workspace_name, context)
  workspace_dir <- local_workspace_directory(storage, workspace_name)
  state_path <- file.path(workspace_dir, manifest$state$file)
  if (!file.exists(state_path) ||
      !identical(workspace_checksum(state_path), manifest$state$checksum)) {
    stop("Saved workspace state failed its integrity check.", call. = FALSE)
  }

  snapshot <- tryCatch(
    readRDS(state_path),
    error = function(error) stop("Saved workspace state could not be read.", call. = FALSE)
  )

  available_names <- names(manifest$datasets)
  if (is.null(dataset_names)) {
    dataset_names <- available_names
  }
  if (!is.character(dataset_names) || anyNA(dataset_names)) {
    stop("Requested workspace dataset names must be text values.", call. = FALSE)
  }
  dataset_names <- unique(dataset_names)
  unknown_names <- setdiff(dataset_names, available_names)
  if (length(unknown_names) > 0L) {
    stop(
      sprintf("Workspace does not contain dataset(s): %s", paste(unknown_names, collapse = ", ")),
      call. = FALSE
    )
  }

  paths <- local_workspace_paths(storage)
  datasets <- list()
  for (dataset_name in dataset_names) {
    entry <- manifest$datasets[[dataset_name]]
    object_path <- file.path(paths$objects, paste0(entry$object_key, ".rds"))
    if (!file.exists(object_path) ||
        !identical(workspace_checksum(object_path), entry$checksum)) {
      stop(sprintf("Saved dataset '%s' failed its integrity check.", dataset_name), call. = FALSE)
    }
    datasets[[dataset_name]] <- tryCatch(
      readRDS(object_path),
      error = function(error) {
        stop(sprintf("Saved dataset '%s' could not be read.", dataset_name), call. = FALSE)
      }
    )
  }

  snapshot$datasets <- datasets
  prepare_workspace_for_restore(
    snapshot,
    require_dataset_coverage = setequal(dataset_names, available_names)
  )
}

empty_workspace_index <- function() {
  data.frame(
    workspace_name = character(),
    directory_name = character(),
    workspace_id = character(),
    saved_at = character(),
    task_id = character(),
    stage_index = integer(),
    dataset_count = integer(),
    bytes = numeric(),
    stringsAsFactors = FALSE
  )
}

workspace_storage_list.local_workspace_storage <- function(storage, context = NULL) {
  normalize_workspace_access_context(context)
  paths <- local_workspace_paths(storage)
  if (!dir.exists(paths$workspaces)) {
    return(empty_workspace_index())
  }

  directories <- list.dirs(paths$workspaces, full.names = TRUE, recursive = FALSE)
  rows <- lapply(directories, function(directory) {
    manifest_path <- file.path(directory, "manifest.rds")
    if (!file.exists(manifest_path)) {
      return(NULL)
    }
    manifest <- tryCatch(readRDS(manifest_path), error = function(error) NULL)
    if (is.null(manifest)) {
      return(NULL)
    }
    valid <- tryCatch({
      validate_workspace_manifest(manifest)
      TRUE
    }, error = function(error) FALSE)
    if (!valid) {
      return(NULL)
    }

    state_path <- file.path(directory, manifest$state$file)
    state_is_valid <- file.exists(state_path) && tryCatch(
      identical(workspace_checksum(state_path), manifest$state$checksum),
      error = function(error) FALSE
    )
    if (!state_is_valid) {
      return(NULL)
    }
    stored_snapshot <- tryCatch(readRDS(state_path), error = function(error) NULL)
    if (is.null(stored_snapshot)) {
      return(NULL)
    }
    task_id <- if (is.null(stored_snapshot)) NULL else stored_snapshot$state$workflow_session$task_id
    stage_index <- tryCatch(
      prepare_workspace_for_restore(
        stored_snapshot,
        require_dataset_coverage = FALSE
      )$state$workflow_session$stage_index,
      error = function(error) NA_integer_
    )
    if (is.na(stage_index)) {
      return(NULL)
    }
    data.frame(
      workspace_name = manifest$workspace$workspace_name,
      directory_name = manifest$workspace$directory_name,
      workspace_id = manifest$workspace$workspace_id,
      saved_at = manifest$workspace$saved_at,
      task_id = if (is.null(task_id)) NA_character_ else task_id,
      stage_index = as.integer(stage_index),
      dataset_count = length(manifest$datasets),
      bytes = manifest$state$bytes + sum(vapply(
        manifest$datasets,
        `[[`,
        numeric(1),
        "bytes"
      )),
      stringsAsFactors = FALSE
    )
  })
  rows <- Filter(Negate(is.null), rows)
  if (length(rows) == 0L) {
    return(empty_workspace_index())
  }

  result <- do.call(rbind, rows)
  result[order(result$saved_at, decreasing = TRUE), , drop = FALSE]
}

workspace_storage_delete.local_workspace_storage <- function(
    storage, workspace_name, context = NULL) {
  normalize_workspace_access_context(context)
  workspace_dir <- local_workspace_directory(storage, workspace_name)
  if (!dir.exists(workspace_dir)) {
    stop(sprintf("Workspace '%s' was not found.", validate_workspace_name(workspace_name)), call. = FALSE)
  }
  unlink(workspace_dir, recursive = TRUE, force = TRUE)
  if (dir.exists(workspace_dir)) {
    stop("Workspace could not be deleted from local storage.", call. = FALSE)
  }
  workspace_storage_prune_objects(storage)
  invisible(TRUE)
}

workspace_storage_prune_objects.local_workspace_storage <- function(storage) {
  paths <- local_workspace_paths(storage)
  if (!dir.exists(paths$objects)) {
    return(invisible(character()))
  }

  referenced <- character()
  if (dir.exists(paths$workspaces)) {
    manifest_paths <- file.path(
      list.dirs(paths$workspaces, full.names = TRUE, recursive = FALSE),
      "manifest.rds"
    )
    for (manifest_path in manifest_paths[file.exists(manifest_paths)]) {
      manifest <- tryCatch(readRDS(manifest_path), error = function(error) NULL)
      if (!is.null(manifest) && is.list(manifest$datasets)) {
        referenced <- c(
          referenced,
          vapply(manifest$datasets, `[[`, character(1), "object_key")
        )
      }
    }
  }
  referenced <- unique(referenced)

  object_paths <- list.files(paths$objects, pattern = "^[0-9a-f]{32}\\.rds$", full.names = TRUE)
  object_keys <- sub("\\.rds$", "", basename(object_paths))
  orphan_paths <- object_paths[!object_keys %in% referenced]
  if (length(orphan_paths) > 0L) {
    unlink(orphan_paths, force = TRUE)
  }
  invisible(basename(orphan_paths))
}
