dashboard_startup_packages <- c(
  "shiny", "bslib", "rsconnect", "shinybusy", "shinyWidgets",
  "shinyalert", "fontawesome", "htmltools", "dplyr", "tidyr", "purrr", "stringr",
  "sjmisc", "naniar", "DT", "data.table", "kableExtra", "ggplot2",
  "gridExtra", "GGally", "leaflet", "hetoolkit", "rnrfa", "lme4",
  "performance"
)

dashboard_runtime_packages <- c(
  "ggrepel", "ggnewscale", "ggpubr", "jsonlite", "lubridate", "plotly",
  "readr", "readxl", "tibble", "viridis"
)

dashboard_required_packages <- unique(c(
  dashboard_startup_packages,
  dashboard_runtime_packages
))

HETOOLKIT_REPO <- "APEM-LTD/hetoolkit"
HETOOLKIT_REF <- "b9d3f34b4dcad62dbe951069aaf3c39ee3b5883d"

dashboard_package_available <- function(package) {
  requireNamespace(package, quietly = TRUE)
}

hetoolkit_description <- function() {
  package_path <- find.package("hetoolkit", quiet = TRUE)
  if (!length(package_path)) {
    return(NULL)
  }
  packageDescription("hetoolkit", lib.loc = dirname(package_path))
}

hetoolkit_revision <- function(description = hetoolkit_description()) {
  if (is.null(description)) {
    return(NA_character_)
  }
  revision_fields <- c("RemoteSha", "GithubSHA", "GithubSHA1")
  revisions <- unlist(description[revision_fields], use.names = FALSE)
  revisions <- revisions[!is.na(revisions) & nzchar(revisions)]
  if (!length(revisions)) NA_character_ else as.character(revisions[[1L]])
}

hetoolkit_matches_verified_revision <- function(
  description = hetoolkit_description()
) {
  revision <- hetoolkit_revision(description)
  !is.na(revision) && identical(tolower(revision), tolower(HETOOLKIT_REF))
}

report_hetoolkit_metadata <- function(description = hetoolkit_description()) {
  if (is.null(description)) {
    cat("hetoolkit is not installed.\n")
    return(invisible(NULL))
  }
  metadata_value <- function(field) {
    value <- description[[field]]
    if (is.null(value) || !length(value) || is.na(value[[1L]]) ||
        !nzchar(value[[1L]])) {
      "not recorded"
    } else {
      as.character(value[[1L]])
    }
  }
  cat("Installed hetoolkit version:", metadata_value("Version"), "\n")
  cat("Installed hetoolkit source:",
      paste0(metadata_value("RemoteUsername"), "/",
             metadata_value("RemoteRepo")), "\n")
  cat("Installed hetoolkit reference:", metadata_value("RemoteRef"), "\n")
  cat("Installed hetoolkit revision:", hetoolkit_revision(description), "\n")
  invisible(description)
}

setup_dashboard_dependencies <- function() {
  options(
    repos = c(CRAN = "https://cloud.r-project.org"),
    timeout = 1200,
    pkgType = "binary"
  )

  customer_library <- Sys.getenv("R_LIBS_USER", unset = NA_character_)
  if (is.na(customer_library) || !nzchar(customer_library)) {
    stop("R_LIBS_USER is not set to the customer package library.", call. = FALSE)
  }

  if (!dir.exists(customer_library) &&
      !dir.create(customer_library, recursive = TRUE, showWarnings = FALSE)) {
    stop("The customer package library could not be created: ", customer_library,
         call. = FALSE)
  }
  .libPaths(unique(c(customer_library, .libPaths())))
  cat("Customer runtime library:", normalizePath(
    customer_library, winslash = "/", mustWork = TRUE
  ), "\n")
  cat("Active R library paths:", paste(.libPaths(), collapse = "; "), "\n")

  cran_packages <- setdiff(dashboard_required_packages, "hetoolkit")
  missing_cran <- cran_packages[
    !vapply(cran_packages, dashboard_package_available, logical(1))
  ]

  if (length(missing_cran)) {
    cat("Installing missing CRAN packages:",
        paste(missing_cran, collapse = ", "), "\n")
    install.packages(
      missing_cran,
      lib = customer_library,
      dependencies = NA,
      type = "binary"
    )
  } else {
    cat("All required CRAN packages are already available.\n")
  }

  installed_hetoolkit <- hetoolkit_description()
  if (hetoolkit_matches_verified_revision(installed_hetoolkit)) {
    cat("hetoolkit already matches the verified revision", HETOOLKIT_REF, "\n")
  } else {
    if (is.null(installed_hetoolkit)) {
      cat("hetoolkit is missing; installing the verified revision.\n")
    } else {
      cat("The installed hetoolkit revision is incorrect or unverified;",
          "installing the verified revision.\n")
      report_hetoolkit_metadata(installed_hetoolkit)
    }
    if (!dashboard_package_available("remotes")) {
      cat("Installing remotes so hetoolkit can be installed.\n")
      install.packages(
        "remotes",
        lib = customer_library,
        dependencies = NA,
        type = "binary"
      )
    }
    if (!dashboard_package_available("remotes")) {
      stop("The remotes package is unavailable; hetoolkit cannot be installed.",
           call. = FALSE)
    }
    cat("Installing hetoolkit from", HETOOLKIT_REPO,
        "at verified revision", HETOOLKIT_REF, "\n")
    remotes::install_github(
      paste0(HETOOLKIT_REPO, "@", HETOOLKIT_REF),
      lib = customer_library,
      dependencies = NA,
      upgrade = "never",
      force = TRUE
    )
  }

  final_hetoolkit <- hetoolkit_description()
  if (!hetoolkit_matches_verified_revision(final_hetoolkit)) {
    stop("hetoolkit does not match the verified revision after installation: ",
         HETOOLKIT_REF, call. = FALSE)
  }
  if (!dashboard_package_available("hetoolkit")) {
    stop("The verified hetoolkit revision could not be loaded.", call. = FALSE)
  }
  report_hetoolkit_metadata(final_hetoolkit)
  cat("hetoolkit loaded successfully at the verified revision.\n")

  still_missing <- dashboard_required_packages[
    !vapply(dashboard_required_packages, dashboard_package_available, logical(1))
  ]
  if (length(still_missing)) {
    stop(
      "Required packages remain unavailable after installation: ",
      paste(still_missing, collapse = ", "),
      call. = FALSE
    )
  }

  cat("All required dashboard packages are available.\n")
  invisible(TRUE)
}

if (sys.nframe() == 0L) {
  status <- tryCatch(
    {
      setup_dashboard_dependencies()
      0L
    },
    error = function(error) {
      message("Dependency preparation failed: ", conditionMessage(error))
      1L
    }
  )
  quit(save = "no", status = status, runLast = FALSE)
}
