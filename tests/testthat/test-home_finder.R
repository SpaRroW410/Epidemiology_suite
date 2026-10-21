# Found by the first shinytest2 smoke run (ROADMAP item 12): the Home hub's
# "Browse calculators" jump buttons had non-unique HTML ids whenever one
# calculator is listed under several families of the same lens.

test_that("every Browse jump button has a unique id", {
  ids <- home_browse_button_ids()
  expect_gt(length(ids), 100)
  expect_false(anyDuplicated(names(ids)) > 0)
})

test_that("every Browse jump button opens a real catalog entry, and every family key has a button", {
  ids <- home_browse_button_ids()
  for (key in unname(ids)) {
    expect_false(is.null(catalog_entry(key)), info = key)
  }
  listed <- unique(unlist(lapply(c(study_design_families, test_families), `[[`, "catalog_keys")))
  expect_setequal(unique(unname(ids)), listed)
})

test_that("the rendered Browse accordion has no duplicate button ids in either lens", {
  html_ids <- function(families, axis) {
    unlist(lapply(seq_along(families), function(i) {
      vapply(families[[i]]$catalog_keys, function(k) .browse_button_id(axis, i, k), character(1))
    }))
  }
  expect_false(anyDuplicated(html_ids(study_design_families, "design")) > 0)
  expect_false(anyDuplicated(html_ids(test_families, "test")) > 0)
})
