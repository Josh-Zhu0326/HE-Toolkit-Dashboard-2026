args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 1L) {
  stop("Usage: preflight_dashboard_diagnostics.R <project-directory>", call. = FALSE)
}

project_dir <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
dependency_script <- file.path(project_dir, "scripts", "setup_dashboard_dependencies.R")

if (!file.exists(dependency_script)) {
  stop("The Dashboard dependency definition was not found.", call. = FALSE)
}

dependency_definitions <- new.env(parent = baseenv())
sys.source(dependency_script, envir = dependency_definitions)
required <- dependency_definitions$dashboard_required_packages

if (!length(required)) {
  stop("The Dashboard dependency list is empty.", call. = FALSE)
}

available <- vapply(required, requireNamespace, logical(1), quietly = TRUE)
missing <- required[!available]

cat("R:", R.version.string, "\n")
cat("R architecture:", R.version$arch, "\n")
cat("Pointer size bytes:", .Machine$sizeof.pointer, "\n")
cat("Locale:", paste(Sys.getlocale(), collapse = "; "), "\n")
cat("Library paths:", paste(.libPaths(), collapse = "; "), "\n")
cat("Package versions:\n")
for (package in required[available]) {
  cat("-", package, as.character(utils::packageVersion(package)), "\n")
}

if (length(missing)) {
  cat("MISSING:", paste(missing, collapse = ", "), "\n", file = stderr())
  quit(save = "no", status = 21L, runLast = FALSE)
}

quit(save = "no", status = 0L, runLast = FALSE)
