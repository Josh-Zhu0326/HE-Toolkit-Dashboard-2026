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

dashboard_package_available <- function(package) {
  requireNamespace(package, quietly = TRUE)
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

  if (!dashboard_package_available("hetoolkit")) {
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
    cat("Installing hetoolkit from APEM-LTD/hetoolkit.\n")
    remotes::install_github(
      "APEM-LTD/hetoolkit",
      lib = customer_library,
      dependencies = NA,
      upgrade = "never"
    )
  }

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
