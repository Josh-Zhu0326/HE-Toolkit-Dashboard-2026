args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L || !nzchar(trimws(args[[1L]]))) {
  stop(
    "Usage: Rscript --vanilla scripts/generate_gate_d_candidate_manifest.R <output-directory>",
    call. = FALSE
  )
}
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("The jsonlite package is required to generate the Gate D manifest.", call. = FALSE)
}

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
output_dir <- normalizePath(args[[1L]], winslash = "/", mustWork = FALSE)
if (!dir.exists(output_dir) &&
    !dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)) {
  stop("Gate D manifest output directory could not be created.", call. = FALSE)
}

run_git <- function(arguments) {
  output <- suppressWarnings(system2("git", arguments, stdout = TRUE, stderr = TRUE))
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) {
    stop("Git metadata could not be collected for the Gate D manifest.", call. = FALSE)
  }
  trimws(paste(output, collapse = "\n"))
}

relative_path <- function(path) {
  normalised <- normalizePath(path, winslash = "/", mustWork = TRUE)
  repo_prefix <- paste0(repo_root, "/")
  if (startsWith(normalised, repo_prefix)) {
    return(substring(normalised, nchar(repo_prefix) + 1L))
  }
  basename(normalised)
}

file_manifest <- function(paths) {
  paths <- sort(unique(paths[file.exists(paths)]))
  if (length(paths) == 0L) {
    return(data.frame(
      path = character(),
      checksum_algorithm = character(),
      checksum = character(),
      bytes = numeric(),
      stringsAsFactors = FALSE
    ))
  }
  data.frame(
    path = vapply(paths, relative_path, character(1)),
    checksum_algorithm = "md5",
    checksum = unname(tools::md5sum(paths)),
    bytes = as.numeric(file.info(paths)$size),
    stringsAsFactors = FALSE
  )
}

material_paths <- file.path(repo_root, c(
  "docs/client-decision-log-v1.md",
  "docs/week08/pilot-execution.md",
  "docs/week09/formal-session-manifest-and-qa-draft.md",
  "docs/week09/formal-study-protocol-v1-draft.md",
  "docs/week09/RAW-01-25-recovery-matrix.md"
))
fixture_paths <- list.files(
  file.path(repo_root, "tests", "fixtures"),
  recursive = TRUE,
  full.names = TRUE
)
fixture_paths <- fixture_paths[file.info(fixture_paths)$isdir %in% FALSE]
lock_paths <- c(
  file.path(repo_root, c(
    "manifest.json", "global.R", "server.R", "ui.R",
    "scripts/generate_gate_d_candidate_manifest.R"
  )),
  list.files(
    file.path(repo_root, "R"),
    pattern = "[.]R$",
    full.names = TRUE
  )
)

runtime_packages <- c(
  "shiny", "bslib", "rsconnect", "shinybusy", "shinyWidgets",
  "shinyalert", "fontawesome", "dplyr", "tidyr", "purrr", "stringr",
  "sjmisc", "naniar", "DT", "data.table", "kableExtra", "ggplot2",
  "ggnewscale", "gridExtra", "GGally", "leaflet", "hetoolkit", "rnrfa",
  "testthat", "jsonlite"
)
installed <- utils::installed.packages()
package_versions <- vapply(runtime_packages, function(package) {
  if (package %in% rownames(installed)) installed[package, "Version"] else "NOT_INSTALLED"
}, character(1))

status_porcelain <- run_git(c("status", "--porcelain=v1", "--untracked-files=all"))
manifest <- list(
  manifest_kind = "gate-d-rc-candidate",
  generated_at_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  decision_scope = paste(
    "Technical candidate evidence only.",
    "This manifest does not replace Pilot 1/2, ethics confirmation, Gate D team sign-off, or an authorised RC tag."
  ),
  repository = list(
    root = repo_root,
    branch = run_git(c("branch", "--show-current")),
    commit = run_git(c("rev-parse", "HEAD")),
    origin_main = run_git(c("rev-parse", "origin/main")),
    merge_base_with_origin_main = run_git(c("merge-base", "HEAD", "origin/main")),
    clean_worktree = !nzchar(status_porcelain),
    status_porcelain = if (nzchar(status_porcelain)) strsplit(status_porcelain, "\n", fixed = TRUE)[[1L]] else character()
  ),
  environment = list(
    r_version = R.version.string,
    platform = R.version$platform,
    os = Sys.info()[["sysname"]],
    os_release = Sys.info()[["release"]],
    package_versions = as.list(package_versions)
  ),
  dependency_and_entrypoint_files = file_manifest(lock_paths),
  research_materials = file_manifest(material_paths),
  synthetic_test_fixtures = file_manifest(fixture_paths),
  gate_d_human_evidence = list(
    pilot_1_packet = "REQUIRES_AUTHORISED_TEAM_EVIDENCE",
    pilot_2_packet = "REQUIRES_AUTHORISED_TEAM_EVIDENCE",
    ethics_and_material_boundary = "REQUIRES_AUTHORISED_TEAM_CONFIRMATION",
    facilitator_manifest_acceptance = "REQUIRES_TEAM_SIGN_OFF",
    gate_d_decision = "REQUIRES_TEAM_SIGN_OFF"
  )
)

json_path <- file.path(output_dir, "gate-d-candidate-manifest.json")
jsonlite::write_json(
  manifest,
  json_path,
  auto_unbox = TRUE,
  pretty = TRUE,
  null = "null",
  na = "null"
)

session_path <- file.path(output_dir, "session-info.txt")
capture.output(utils::sessionInfo(), file = session_path)

checksums <- rbind(
  transform(manifest$dependency_and_entrypoint_files, category = "runtime"),
  transform(manifest$research_materials, category = "material"),
  transform(manifest$synthetic_test_fixtures, category = "fixture")
)
checksums <- checksums[, c("category", "path", "checksum_algorithm", "checksum", "bytes")]
utils::write.csv(checksums, file.path(output_dir, "checksums.csv"), row.names = FALSE)

message(sprintf("Wrote Gate D candidate evidence to %s", output_dir))
