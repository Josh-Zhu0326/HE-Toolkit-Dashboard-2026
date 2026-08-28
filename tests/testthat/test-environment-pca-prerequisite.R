pca_environment_fixture <- function(site_ids) {
  row_count <- length(site_ids)
  data.frame(
    biol_site_id = site_ids,
    ALTITUDE = seq_len(row_count) + 9,
    SLOPE = seq_len(row_count),
    WIDTH = seq_len(row_count) + 3,
    DEPTH = seq_len(row_count),
    BOULDERS_COBBLES = seq_len(row_count) + 19,
    PEBBLES_GRAVEL = seq_len(row_count) + 29,
    SILT_CLAY = seq_len(row_count) + 24,
    stringsAsFactors = FALSE
  )
}

pca_metadata_text <- function(site_ids) {
  paste(
    c(
      "biol_site_id,flow_site_id",
      sprintf("%s,F%s", site_ids, seq_along(site_ids))
    ),
    collapse = "\n"
  )
}

testthat::test_that("Environmental PCA explains a single usable site before plotting", {
  # Repeated records for one site must not be mistaken for multiple sites.
  environment_fixture <- pca_environment_fixture(c("B1", "B1"))
  plot_calls <- 0L
  rlang::local_bindings(
    import_env = function(...) environment_fixture,
    plot_sitepca_dash = function(...) {
      plot_calls <<- plot_calls + 1L
      ggplot2::ggplot(data.frame(x = 1, y = 1), ggplot2::aes(x, y))
    },
    .env = environment(workflow_dashboard_server)
  )

  shiny::testServer(workflow_dashboard_server, {
    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = pca_metadata_text("B1"),
      import_env = 1
    )
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_error(
      output$env_fig,
      paste(
        "PCA cannot be run with data from only one site.",
        "Currently 1 usable site was detected; add data for at least one more site."
      ),
      fixed = TRUE
    )
  })

  testthat::expect_identical(plot_calls, 0L)
})

testthat::test_that("Environmental PCA counts only sites with complete PCA inputs", {
  environment_fixture <- pca_environment_fixture(c("B1", "B2"))
  environment_fixture$SLOPE[[2]] <- NA_real_
  plot_calls <- 0L
  rlang::local_bindings(
    import_env = function(...) environment_fixture,
    plot_sitepca_dash = function(...) {
      plot_calls <<- plot_calls + 1L
      ggplot2::ggplot(data.frame(x = 1, y = 1), ggplot2::aes(x, y))
    },
    .env = environment(workflow_dashboard_server)
  )

  shiny::testServer(workflow_dashboard_server, {
    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = pca_metadata_text(c("B1", "B2")),
      import_env = 1
    )
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_error(
      output$env_fig,
      "PCA cannot be run with data from only one site.",
      fixed = TRUE
    )
  })

  testthat::expect_identical(plot_calls, 0L)
})

testthat::test_that("Environmental PCA still plots with two usable sites", {
  environment_fixture <- pca_environment_fixture(c("B1", "B2"))
  plot_calls <- 0L
  rlang::local_bindings(
    import_env = function(...) environment_fixture,
    plot_sitepca_dash = function(...) {
      plot_calls <<- plot_calls + 1L
      ggplot2::ggplot(data.frame(x = 1, y = 1), ggplot2::aes(x, y))
    },
    .env = environment(workflow_dashboard_server)
  )

  shiny::testServer(workflow_dashboard_server, {
    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = pca_metadata_text(c("B1", "B2")),
      import_env = 1
    )
    muffle_interrupted_workflow_promise(session$flushReact())

    testthat::expect_error(output$env_fig, NA)
  })

  testthat::expect_identical(plot_calls, 1L)
})
