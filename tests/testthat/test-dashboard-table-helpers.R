source(testthat::test_path("..", "..", "R", "dashboard_table_helpers.R"))

testthat::test_that("dashboard tables share wide-data browsing defaults", {
  table <- dashboard_datatable(
    data.frame(
      wq_site_id = c("WQ01", "WQ02"),
      date_time = as.Date(c("2024-01-01", "2024-01-02")),
      result = c(1.23456, 2.34567)
    ),
    frozen_columns = 2L
  )

  testthat::expect_s3_class(table, "datatables")
  testthat::expect_true(isTRUE(table$x$options$scrollX))
  testthat::expect_identical(table$x$options$pageLength, 25L)
  testthat::expect_identical(table$x$options$fixedColumns$leftColumns, 2L)
  testthat::expect_true("FixedColumns" %in% unlist(table$x$extensions, use.names = FALSE))
})
