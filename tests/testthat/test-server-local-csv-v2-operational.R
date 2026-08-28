testthat::test_that("all five primary CSV types feed their operational Stage 1 data paths", {
  shiny::testServer(workflow_dashboard_server, {
    template <- function(data_type) {
      shiny_upload_input(testthat::test_path(
        "..", "..", "www", "templates", "local_csv_v2", paste0(data_type, ".csv")
      ))
    }
    set_inputs_ignoring_interrupted_promises(
      session,
      meta_paste = paste(
        "biol_site_id,flow_site_id,wq_site_id,rhs_survey_id",
        "B001,00123,WQ001,RHS0001",
        sep = "\n"
      ),
      local_v2_biology_csv = template("biology"),
      local_v2_environmental_csv = template("environmental"),
      local_flow_csv = template("flow"),
      local_v2_wq_csv = template("wq"),
      local_v2_rhs_csv = template("rhs")
    )
    session$flushReact()

    testthat::expect_equal(nrow(biol_data()), 2L)
    testthat::expect_identical(env_data()$biol_site_id, "B001")
    testthat::expect_equal(nrow(flow_data()), 2L)
    testthat::expect_equal(nrow(mapped_wq_plot_data()), 2L)
    testthat::expect_identical(unique(mapped_wq_plot_data()$biol_site_id), "B001")
    testthat::expect_equal(nrow(mapped_rhs_plot_data()), 1L)
    testthat::expect_identical(unique(mapped_rhs_plot_data()$biol_site_id), "B001")

    artifacts <- workflow_artifacts()
    testthat::expect_true(all(vapply(
      artifacts[c("biology_input", "environment_input", "flow_input", "wq_input", "rhs_input")],
      artifact_is_current,
      logical(1)
    )))
  })
})
