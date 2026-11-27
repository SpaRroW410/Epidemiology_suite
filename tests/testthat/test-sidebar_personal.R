# Favourites and recent calculators (docs/ui_remap_plan.md, step 5)

test_that("the lists are saved to a file and read back, keeping only real calculator titles", {
  f <- tempfile(fileext = ".txt"); on.exit(unlink(f))
  expect_equal(.personal_read(f), list(fav = character(), recent = character()))          # no file yet
  out <- .personal_write(list(fav = list("Stepped-Wedge CRT", "No such calculator", "Case-Control", "Case-Control"),
                              recent = as.list(c("Means", "Correlation", "Proportions", "Cohort / RR", "Rule of Three", "LQAS"))), f)
  expect_equal(out$fav, c("Stepped-Wedge CRT", "Case-Control"))
  expect_length(out$recent, 5)                                                             # at most five recent
  expect_equal(.personal_read(f), out)
  writeLines(c("fav\tMeans", "junk line", "recent\tNot a title"), f)
  expect_equal(.personal_read(f), list(fav = "Means", recent = character()))
})

test_that("saving to a file is off on a server, in tests and in the browser build, and on when asked", {
  withr::with_options(list(epidemiologysuite.save_personal = FALSE), expect_false(.personal_save_enabled()))
  withr::with_options(list(epidemiologysuite.save_personal = TRUE), expect_true(.personal_save_enabled() ||
                                                                               identical(Sys.info()[["sysname"]], "Emscripten")))
  withr::with_options(list(epidemiologysuite.save_personal = NULL), expect_equal(.personal_save_enabled(), interactive()))
  expect_match(.personal_file(), "epidemiologysuite", fixed = TRUE)
})

test_that("the server sends the saved lists and writes changes only when saving is on", {
  f <- tempfile(fileext = ".txt"); on.exit(unlink(f))
  .personal_write(list(fav = "Means", recent = "Correlation"), f)
  shiny::testServer(function(input, output, session) sidebar_personal_server(input, session, save = TRUE, path = f), {
    session$setInputs(es_personal = list(fav = list("Means", "Case-Control"), recent = list("Correlation")))
    session$setInputs(es_personal = list(fav = list("Case-Control"), recent = list("Means", "Correlation")))
  })
  expect_equal(.personal_read(f), list(fav = "Case-Control", recent = c("Means", "Correlation")))
  g <- tempfile(fileext = ".txt")
  shiny::testServer(function(input, output, session) sidebar_personal_server(input, session, save = FALSE, path = g), {
    session$setInputs(es_personal = list(fav = list("Means"), recent = list()))
  })
  expect_false(file.exists(g))
})

test_that("the page has the star buttons, the short lists and the favourite words of the filter", {
  html <- htmltools::renderTags(attr(epidemiologysuite_app(lazy = TRUE), "ui_tags"))
  page <- paste(html$head, html$html)
  expect_match(page, "es_personal_v1", fixed = TRUE)
  expect_match(page, "Add to favourites: ", fixed = TRUE)
  expect_match(page, "'Recent'", fixed = TRUE)
  expect_match(page, "'favourite', 'favourites', 'favorite'", fixed = TRUE)
  expect_match(page, "\\u2b50", fixed = TRUE)
})
