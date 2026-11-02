# Dark mode: a box drawn with a fixed light background keeps it in dark mode while the text turns light, so the text disappears
# (the wizard's "describe your study" box measured 1.29:1 contrast). Boxes use the theme's own colours (bg-body-tertiary) instead.

test_that("no app code draws a fixed light background (bg-light / bg-white) that dark mode cannot recolour", {
  files <- list.files(test_path("..", "..", "R"), pattern = "[.]R$", full.names = TRUE)
  skip_if(length(files) == 0, "R/ sources not available (installed package)")
  hits <- unlist(lapply(files, function(f) {
    l <- readLines(f, warn = FALSE)
    i <- grep("\\bbg-(light|white)\\b", l)
    if (length(i)) paste0(basename(f), ":", i, ": ", trimws(l[i])) else character()
  }))
  expect_equal(hits, character())
})

test_that("background loading of calculators is off in the browser build, and the progress bar with it", {
  local_mocked_bindings(Sys.info = function() c(sysname = "Emscripten"), .package = "base")
  expect_false(.background_load_enabled())
  page <- as.character(lazy_sidebar_assets(c("Means", "Cohort / RR"), show_progress = FALSE))
  expect_match(page, "var pending = \\[\\]", fixed = FALSE)
  page_on <- as.character(lazy_sidebar_assets(c("Means"), show_progress = TRUE))
  expect_match(page_on, "\"Means\"", fixed = TRUE)
})
