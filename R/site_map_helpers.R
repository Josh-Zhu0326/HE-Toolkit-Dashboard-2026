empty_site_map_points <- function() {
  data.frame(
    site_type = character(),
    site_id = character(),
    lon = numeric(),
    lat = numeric(),
    coordinate_source = character(),
    stringsAsFactors = FALSE
  )
}

site_map_nonblank <- function(values) {
  values <- trimws(as.character(values))
  !is.na(values) & nzchar(values) & toupper(values) != "TBC"
}

site_map_bng_to_wgs84 <- function(easting, northing) {
  easting <- suppressWarnings(as.numeric(easting))
  northing <- suppressWarnings(as.numeric(northing))
  valid <- is.finite(easting) & is.finite(northing)
  result <- data.frame(lon = rep(NA_real_, length(easting)), lat = rep(NA_real_, length(easting)))
  if (!any(valid)) {
    return(result)
  }

  points <- sf::st_as_sf(
    data.frame(easting = easting[valid], northing = northing[valid]),
    coords = c("easting", "northing"),
    crs = 27700
  )
  coordinates <- sf::st_coordinates(sf::st_transform(points, 4326))
  result$lon[valid] <- coordinates[, "X"]
  result$lat[valid] <- coordinates[, "Y"]
  result
}

site_map_points_from_bng <- function(data, site_type, id_col, easting_col,
                                     northing_col, coordinate_source) {
  required <- c(id_col, easting_col, northing_col)
  if (!is.data.frame(data) || nrow(data) == 0L || !all(required %in% names(data))) {
    return(empty_site_map_points())
  }

  coordinates <- site_map_bng_to_wgs84(data[[easting_col]], data[[northing_col]])
  result <- data.frame(
    site_type = site_type,
    site_id = trimws(as.character(data[[id_col]])),
    lon = coordinates$lon,
    lat = coordinates$lat,
    coordinate_source = coordinate_source,
    stringsAsFactors = FALSE
  )
  valid <- site_map_nonblank(result$site_id) & is.finite(result$lon) & is.finite(result$lat)
  unique(result[valid, , drop = FALSE])
}

site_map_points_from_mapping <- function(mapping) {
  specifications <- list(
    c("Biology", "biol_site_id", "biol_easting", "biol_northing"),
    c("Flow", "flow_site_id", "flow_easting", "flow_northing"),
    c("WQ", "wq_site_id", "wq_easting", "wq_northing")
  )
  points <- lapply(specifications, function(specification) {
    site_map_points_from_bng(
      mapping,
      site_type = specification[[1L]],
      id_col = specification[[2L]],
      easting_col = specification[[3L]],
      northing_col = specification[[4L]],
      coordinate_source = "Site mapping"
    )
  })
  dplyr::bind_rows(points)
}

site_map_points_from_environment <- function(environment_data) {
  if (!is.data.frame(environment_data) || nrow(environment_data) == 0L ||
      !"biol_site_id" %in% names(environment_data)) {
    return(empty_site_map_points())
  }

  if (all(c("FULL_EASTING", "FULL_NORTHING") %in% names(environment_data))) {
    points <- site_map_points_from_bng(
      environment_data,
      "Biology",
      "biol_site_id",
      "FULL_EASTING",
      "FULL_NORTHING",
      "Environmental data"
    )
    if (nrow(points) > 0L) {
      return(points)
    }
  }

  if (!"NGR_10_FIG" %in% names(environment_data)) {
    return(empty_site_map_points())
  }
  converter <- tryCatch(
    getFromNamespace("osg_parse", "hetoolkit"),
    error = function(error) NULL
  )
  if (is.null(converter)) {
    return(empty_site_map_points())
  }

  ngr_values <- trimws(as.character(environment_data$NGR_10_FIG))
  coordinates <- data.frame(
    lon = rep(NA_real_, length(ngr_values)),
    lat = rep(NA_real_, length(ngr_values))
  )
  for (index in which(site_map_nonblank(ngr_values))) {
    converted <- tryCatch(
      suppressWarnings(as.data.frame(
        converter(ngr_values[[index]], coord_system = "WGS84")
      )),
      error = function(error) NULL
    )
    if (!is.null(converted) && nrow(converted) > 0L &&
        all(c("lon", "lat") %in% names(converted))) {
      coordinates$lon[[index]] <- suppressWarnings(as.numeric(converted$lon[[1L]]))
      coordinates$lat[[index]] <- suppressWarnings(as.numeric(converted$lat[[1L]]))
    }
  }

  result <- data.frame(
    site_type = "Biology",
    site_id = trimws(as.character(environment_data$biol_site_id)),
    lon = suppressWarnings(as.numeric(coordinates$lon)),
    lat = suppressWarnings(as.numeric(coordinates$lat)),
    coordinate_source = "Environmental NGR",
    stringsAsFactors = FALSE
  )
  valid <- site_map_nonblank(result$site_id) & is.finite(result$lon) & is.finite(result$lat)
  unique(result[valid, , drop = FALSE])
}

site_map_points_from_wq <- function(wq_data) {
  site_map_points_from_bng(
    wq_data,
    "WQ",
    "wq_site_id",
    "easting",
    "northing",
    "Imported WQ data"
  )
}

build_site_map_points <- function(mapping = NULL, environment_data = NULL, wq_data = NULL) {
  points <- dplyr::bind_rows(
    site_map_points_from_mapping(mapping),
    site_map_points_from_environment(environment_data),
    site_map_points_from_wq(wq_data)
  )
  if (nrow(points) == 0L) {
    return(empty_site_map_points())
  }

  points |>
    dplyr::filter(site_type %in% c("Biology", "Flow", "WQ")) |>
    dplyr::distinct(site_type, site_id, .keep_all = TRUE)
}
