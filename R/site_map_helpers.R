empty_site_map_points <- function() {
  data.frame(
    site_type = character(),
    site_id = character(),
    lon = numeric(),
    lat = numeric(),
    coordinate_source = character(),
    water_body = character(),
    sample_count = integer(),
    first_sampling_year = integer(),
    last_sampling_year = integer(),
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
  site_map_points_from_bng(
    mapping,
    site_type = "Biology",
    id_col = "biol_site_id",
    easting_col = "biol_easting",
    northing_col = "biol_northing",
    coordinate_source = "Biology site mapping"
  )
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

site_map_first_column <- function(data, candidates) {
  field <- intersect(candidates, names(data))
  if (length(field) == 0L) NA_character_ else field[[1L]]
}

add_biology_site_map_details <- function(
    points,
    biology_data = NULL,
    environment_data = NULL,
    mapping = NULL) {
  if (!is.data.frame(points) || nrow(points) == 0L) {
    return(empty_site_map_points())
  }
  points$water_body <- NA_character_
  points$sample_count <- 0L
  points$first_sampling_year <- NA_integer_
  points$last_sampling_year <- NA_integer_

  location_sources <- list(environment_data, mapping)
  for (source in location_sources) {
    if (!is.data.frame(source) || nrow(source) == 0L ||
        !"biol_site_id" %in% names(source)) {
      next
    }
    water_body_field <- site_map_first_column(source, c(
      "WATER_BODY", "water_body", "WFD_WATERBODY_ID", "waterbody", "site_name"
    ))
    if (is.na(water_body_field)) {
      next
    }
    ids <- trimws(as.character(source$biol_site_id))
    values <- trimws(as.character(source[[water_body_field]]))
    for (index in seq_len(nrow(points))) {
      matches <- which(ids == points$site_id & site_map_nonblank(values))
      if (length(matches) > 0L && !site_map_nonblank(points$water_body[[index]])) {
        points$water_body[[index]] <- values[[matches[[1L]]]]
      }
    }
  }

  if (is.data.frame(biology_data) && nrow(biology_data) > 0L &&
      "biol_site_id" %in% names(biology_data)) {
    biology_ids <- trimws(as.character(biology_data$biol_site_id))
    date_field <- site_map_first_column(biology_data, c("SAMPLE_DATE", "date"))
    year_field <- site_map_first_column(biology_data, c("Year", "sampling_year"))
    years <- if (!is.na(year_field)) {
      suppressWarnings(as.integer(biology_data[[year_field]]))
    } else if (!is.na(date_field)) {
      suppressWarnings(as.integer(format(as.Date(biology_data[[date_field]]), "%Y")))
    } else {
      rep(NA_integer_, nrow(biology_data))
    }

    for (index in seq_len(nrow(points))) {
      rows <- which(biology_ids == points$site_id)
      points$sample_count[[index]] <- length(rows)
      site_years <- years[rows]
      site_years <- site_years[is.finite(site_years)]
      if (length(site_years) > 0L) {
        points$first_sampling_year[[index]] <- min(site_years)
        points$last_sampling_year[[index]] <- max(site_years)
      }
    }
  }
  points
}

build_site_map_points <- function(
    mapping = NULL,
    environment_data = NULL,
    wq_data = NULL,
    biology_data = NULL) {
  # wq_data is retained as a compatibility argument, but non-Biology records
  # and coordinates are intentionally never promoted to map layers.
  points <- dplyr::bind_rows(
    site_map_points_from_mapping(mapping),
    site_map_points_from_environment(environment_data)
  )
  if (nrow(points) == 0L) {
    return(empty_site_map_points())
  }

  points <- points |>
    dplyr::filter(site_type == "Biology") |>
    dplyr::distinct(site_type, site_id, .keep_all = TRUE)
  add_biology_site_map_details(
    points,
    biology_data = biology_data,
    environment_data = environment_data,
    mapping = mapping
  )
}
