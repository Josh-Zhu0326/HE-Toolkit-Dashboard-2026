testthat::test_that("site mapping creates Biology, Flow and WQ map layers", {
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

  testthat::expect_identical(sort(points$site_type), c("Biology", "Flow", "WQ"))
  testthat::expect_identical(sort(points$site_id), c("B01", "F01", "W01"))
  testthat::expect_true(all(is.finite(points$lon)))
  testthat::expect_true(all(is.finite(points$lat)))
  testthat::expect_true(all(points$coordinate_source == "Site mapping"))
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

  testthat::expect_equal(nrow(points), 2L)
  testthat::expect_true(all(points$coordinate_source == "Site mapping"))
})

testthat::test_that("Biology NGR and imported WQ coordinates remain available as fallbacks", {
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

  testthat::expect_identical(sort(points$site_type), c("Biology", "WQ"))
  testthat::expect_true(all(is.finite(points$lon)))
  testthat::expect_true(all(is.finite(points$lat)))
  testthat::expect_setequal(
    points$coordinate_source,
    c("Environmental NGR", "Imported WQ data")
  )
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

  testthat::expect_equal(nrow(points), 1L)
  testthat::expect_identical(points$site_type, "Flow")
  testthat::expect_identical(points$site_id, "F01")
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
    testthat::expect_identical(sort(points$site_type), c("Biology", "Flow", "WQ"))
    testthat::expect_true(all(points$coordinate_source == "Site mapping"))
  })
})
