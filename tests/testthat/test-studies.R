# Studies (R/mod_studies.R): entries, grouping into tables, the record sent back by the page, and the Studies tab's drawing.

prop_entry <- function(d, id) {
  e <- study_entry("proportion", "Proportions", calc_proportion_precision(p = 0.3, d = d), proportion_content[["precision"]])
  e$id <- id
  e
}

test_that("an entry carries the result as shown: inputs, headline, formula, citation, paragraph, and a key for the same calculation", {
  e <- prop_entry(0.05, "e1")
  expect_equal(e$module, "proportion")
  expect_equal(e$results$n, "323")
  expect_true("n" %in% unlist(e$headline))
  expect_equal(e$inputs$d, "0.05")
  expect_true(nzchar(e$formula_latex))
  expect_equal(e$citation, proportion_content[["precision"]]$citation)
  expect_match(e$justification, "this app's calculation gives")
  expect_equal(e$version, .release_label)
  expect_identical(e$key, prop_entry(0.05, "e9")$key)
  expect_false(identical(e$key, prop_entry(0.04, "e2")$key))
  expect_match(study_entry_summary(e), "^Proportions -- .*: n = 323")
})

test_that("warnings travel with the entry and empty or list fields are left out", {
  x <- calc_proportion_precision(p = 0.05, d = 0.03)
  e <- study_entry("proportion", "Proportions", x, proportion_content[["precision"]])
  expect_gt(length(x$precision_notes), 0)
  expect_equal(length(e$notes), length(x$precision_notes))
  expect_false("N" %in% names(e$results))      # NULL in the result
  expect_false("precision_notes" %in% names(e$results))
})

test_that("repeated use of one design is one table: the inputs that changed as columns, the others listed once", {
  g <- list(prop_entry(0.05, "e1"), prop_entry(0.04, "e2"), prop_entry(0.03, "e3"))
  tb <- study_table(g)
  expect_equal(names(tb$table)[1:2], c("#", "d"))
  expect_equal(tb$table$d, c("0.05", "0.04", "0.03"))
  expect_true("n" %in% names(tb$table))
  expect_equal(tb$table$n[1], "323")
  expect_true(all(c("p", "conf_level") %in% names(tb$constant)))
  expect_false("d" %in% names(tb$constant))
})

test_that("entries are grouped by calculator and design in the order first added", {
  m <- study_entry("means", "Means", calc_means_1s(mu0 = 120, mu1 = 125, sd = 15), means_content[["single"]]); m$id <- "e3"
  gs <- study_groups(list(prop_entry(0.05, "e1"), m, prop_entry(0.04, "e2")))
  expect_length(gs, 2)
  expect_length(gs[[1]], 2)
  expect_equal(gs[[2]][[1]]$module, "means")
  expect_length(study_groups(list()), 0)
})

test_that("the record sent back by the page is checked: malformed studies and entries are dropped, nothing gives three empty studies", {
  blank <- studies_normalize(NULL)
  expect_equal(vapply(blank$studies, `[[`, "", "id"), c("s1", "s2", "s3"))
  e <- prop_entry(0.05, "e1")
  bad <- e; bad$id <- "e1\"><script>"
  st <- studies_normalize(list(studies = list(list(id = "s1", name = "Survey", entries = list(e, bad, "x")),
                                               list(id = "bad id!", name = "x", entries = list())),
                               recent = list(e, list(id = "r1"))))
  expect_length(st$studies, 1)
  expect_equal(st$studies[[1]]$name, "Survey")
  expect_length(st$studies[[1]]$entries, 1)
  expect_length(st$recent, 1)
})

test_that("the Studies tab draws a table, a single result, references, and escapes what came from the page", {
  e1 <- prop_entry(0.05, "e1"); e2 <- prop_entry(0.04, "e2")
  e3 <- study_entry("means", "Means", calc_means_1s(mu0 = 120, mu1 = 125, sd = 15), means_content[["single"]]); e3$id <- "e3"
  html <- as.character(study_view_ui(list(id = "s1", name = "Study <b>1</b>", entries = list(e1, e2, e3))))
  expect_match(html, "3 result(s) from 2 calculator design(s)", fixed = TRUE)
  expect_match(html, "<table", fixed = TRUE)
  expect_match(html, "Same in every row", fixed = TRUE)
  expect_match(html, "References", fixed = TRUE)
  expect_false(grepl("<b>1</b>", html, fixed = TRUE))
  expect_match(html, "esStudies.remove(&quot;s1&quot;, &quot;e3&quot;)", fixed = TRUE)
  expect_match(as.character(study_view_ui(list(id = "s2", name = "Study 2", entries = list()))), "Nothing added yet")
  expect_match(as.character(recent_view_ui(list(e1))), "esStudies.addFromRecent(&quot;e1&quot;", fixed = TRUE)
  expect_match(as.character(recent_view_ui(list())), "No calculations yet")
})

test_that("every calculator that exports a result also offers Add to study, and the app has the Studies tab and script", {
  html <- as.character(export_controls_ui(NS("proportion")))
  expect_match(html, 'id="proportion-study_target"', fixed = TRUE)
  expect_match(html, "esStudies.request(&quot;proportion-study_add&quot;", fixed = TRUE)
  ui <- as.character(attr(epidemiologysuite_app(lazy = FALSE), "ui_tags"))
  expect_match(ui, 'data-value="Studies"', fixed = TRUE)
  expect_match(ui, "es_studies_v1", fixed = TRUE)
  expect_match(ui, "sessionStorage", fixed = TRUE)
})

test_that("JavaScript string literals are quoted safely", {
  expect_equal(.study_js_str("a\"b"), "\"a\\\"b\"")
  expect_equal(.study_js_str("</script>"), "\"\\u003c/script>\"")
})
