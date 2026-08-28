testthat::test_that("site mapping creates a Biology-only map layer", {
  mapping <- data.frame(
    biol_site_id = "B01",
    biol_easting = 400000,
    biol_northing = 300000,
    flow_site_id = "F01",
    flow_easting = 401000,
    flow_northing = 301000,
    wq_site_id = "W01",
    wq_easting = 402000,
    wq_northing = 302000,
    stringsAsFactors = FALSE
  )

  points <- build_site_map_points(mapping = mapping)

  testthat::expect_identical(points$site_type, "Biology")
  testthat::expect_identical(points$site_id, "B01")
  testthat::expect_true(all(is.finite(points$lon)))
  testthat::expect_true(all(is.finite(points$lat)))
  testthat::expect_true(all(points$coordinate_source == "Biology site mapping"))
})

testthat::test_that("mapping coordinates take precedence over imported fallbacks", {
  mapping <- data.frame(
    biol_site_id = "B01",
    biol_easting = 400000,
    biol_northing = 300000,
    wq_site_id = "W01",
    wq_easting = 402000,
    wq_northing = 302000,
    stringsAsFactors = FALSE
  )
  environment <- data.frame(
    biol_site_id = "B01",
    FULL_EASTING = 410000,
    FULL_NORTHING = 310000,
    stringsAsFactors = FALSE
  )
  wq <- data.frame(
    wq_site_id = "W01",
    easting = 412000,
    northing = 312000,
    stringsAsFactors = FALSE
  )

  points <- build_site_map_points(mapping, environment, wq)

  testthat::expect_equal(nrow(points), 1L)
  testthat::expect_true(all(points$coordinate_source == "Biology site mapping"))
})

testthat::test_that("Biology NGR remains available and imported WQ coordinates are ignored", {
  environment <- data.frame(
    biol_site_id = "B01",
    NGR_10_FIG = "SK0000000000",
    stringsAsFactors = FALSE
  )
  wq <- data.frame(
    wq_site_id = "W01",
    easting = 402000,
    northing = 302000,
    stringsAsFactors = FALSE
  )

  points <- build_site_map_points(environment_data = environment, wq_data = wq)

  testthat::expect_identical(points$site_type, "Biology")
  testthat::expect_true(all(is.finite(points$lon)))
  testthat::expect_true(all(is.finite(points$lat)))
  testthat::expect_identical(points$coordinate_source, "Environmental NGR")
})

testthat::test_that("an invalid NGR does not remove other valid Biology sites", {
  environment <- data.frame(
    biol_site_id = c("B01", "B02", "B03"),
    NGR_10_FIG = c("SK0000000000", "INVALID", "ST00000000"),
    stringsAsFactors = FALSE
  )

  points <- build_site_map_points(environment_data = environment)

  testthat::expect_identical(points$site_id, c("B01", "B03"))
  testthat::expect_true(all(is.finite(points$lon)))
  testthat::expect_true(all(is.finite(points$lat)))
  testthat::expect_true(all(points$coordinate_source == "Environmental NGR"))
})

testthat::test_that("invalid or incomplete coordinates are omitted safely", {
  mapping <- data.frame(
    biol_site_id = c("B01", "B02"),
    biol_easting = c("", 400000),
    biol_northing = c(300000, NA),
    flow_site_id = c("F01", "TBC"),
    flow_easting = c(401000, 402000),
    flow_northing = c(301000, 302000),
    stringsAsFactors = FALSE
  )

  points <- build_site_map_points(mapping = mapping)

  testthat::expect_equal(nrow(points), 0L)
})

testthat::test_that("Stage 1 server map uses coordinates from validated site mapping", {
  shiny::testServer(workflow_dashboard_server, {
    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = paste(
        paste(
          "biol_site_id", "biol_easting", "biol_northing",
          "flow_site_id", "flow_easting", "flow_northing",
          "wq_site_id", "wq_easting", "wq_northing",
          sep = ","
        ),
        "B01,400000,300000,F01,401000,301000,W01,402000,302000",
        sep = "\n"
      )
    )
    session$flushReact()

    points <- map_data()
    testthat::expect_identical(points$site_type, "Biology")
    testthat::expect_true(all(points$coordinate_source == "Biology site mapping"))
  })
})

testthat::test_that("Biology map details include water body and sampling coverage", {
  mapping <- data.frame(
    biol_site_id = "B01",
    biol_easting = 400000,
    biol_northing = 300000,
    stringsAsFactors = FALSE
  )
  environment <- data.frame(
    biol_site_id = "B01",
    WATER_BODY = "River Test",
    stringsAsFactors = FALSE
  )
  biology <- data.frame(
    biol_site_id = c("B01", "B01", "B01"),
    SAMPLE_DATE = as.Date(c("2019-04-01", "2020-05-01", "2022-06-01")),
    stringsAsFactors = FALSE
  )

  points <- build_site_map_points(
    mapping = mapping,
    environment_data = environment,
    biology_data = biology
  )

  testthat::expect_identical(points$water_body, "River Test")
  testthat::expect_identical(points$sample_count, 3L)
  testthat::expect_identical(points$first_sampling_year, 2019L)
  testthat::expect_identical(points$last_sampling_year, 2022L)
})
