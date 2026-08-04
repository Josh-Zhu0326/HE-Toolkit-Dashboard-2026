hev_dependency_check <- function(
    package_available = requireNamespace("ggnewscale", quietly = TRUE)) {
  if (isTRUE(package_available)) {
    return(list(
      status = "success",
      message = "HEV plotting dependencies are available."
    ))
  }

  list(
    status = "error",
    message = paste(
      "The required package ggnewscale is missing.",
      "Please install project dependencies before using the HEV plot feature."
    )
  )
}
