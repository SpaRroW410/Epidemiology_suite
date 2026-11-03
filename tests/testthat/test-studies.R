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

# --- phase S-3: readable names, design choices, notes ---------------------------------------------------------------------------

test_that("names that mean one thing everywhere get a label; names whose meaning depends on the calculator only where it is known", {
  expect_equal(.study_label("alpha"), "Significance level (alpha)")
  expect_equal(.study_label("conf_level"), "Confidence level (conf_level)")
  expect_equal(.study_label("n", kind = "result"), "Sample size (n)")
  # d, p1, r, sd1: different meanings in different calculators, so no label unless the calculator says
  for (nm in c("d", "p1", "r", "sd1", "k", "unknown_name")) expect_equal(.study_label(nm), nm)
  expect_equal(.study_label("d", "proportion"), "Margin of error (absolute) (d)")
  expect_equal(.study_label("p", "proportion"), "Expected proportion (p)")
  expect_equal(.study_label("p1", "cohort"), "Risk in the exposed group (p1)")
  expect_equal(.study_label("pE", "logrank"), "Event probability, experimental group (pE)")
  expect_equal(.study_label("pE", "case_control"), "Probability of exposure (pE)")
  expect_equal(names(.study_relabel(list(alpha = "0.05", zz = "1"))), c("Significance level (alpha)", "zz"))
  # every per-calculator entry names a real calculator
  ids <- vapply(module_registry(), `[[`, character(1), "id")
  expect_true(all(names(.study_labels_module) %in% ids))
})

test_that("a design choice from the guide is its own kind of entry: first in the tab and in the Word file, not in a table", {
  d <- study_design_entry("Two independent proportions", list(list(question = "What is the outcome?", answer = "Yes / no", confidence = "High"),
                                                            list(question = "How many groups?", answer = "Two")),
                          "Proportions: Two independent proportions")
  d$id <- "e9"
  expect_true(.study_is_design(d))
  expect_true(d$trail[[1]]$auto); expect_false(d$trail[[2]]$auto)
  expect_match(study_entry_summary(d), "^Design chosen with the guide: Two independent proportions")
  e1 <- prop_entry(0.05, "e1")
  expect_length(study_groups(list(d, e1)), 1)
  html <- as.character(study_view_ui(list(id = "s1", name = "S", note = "", entries = list(e1, d))))
  expect_match(html, "How the design was chosen", fixed = TRUE)
  expect_match(html, "1 result(s) from 1 calculator design(s).", fixed = TRUE)
  expect_match(html, "1 design choice(s) from the guide.", fixed = TRUE)
  expect_match(html, "suggested from the description", fixed = TRUE)
  skip_if_not_installed("officer")
  f <- tempfile(fileext = ".docx"); on.exit(unlink(f))
  writeBin(study_docx(list(id = "s1", name = "S", note = "Pilot in two districts.", entries = list(e1, d))), f)
  txt <- officer::docx_summary(officer::read_docx(f))$text
  expect_true("How the design was chosen" %in% txt)
  expect_true("Notes: Pilot in two districts." %in% txt)
  expect_true(any(grepl("^What is the outcome\\? Yes / no \\(suggested from the description\\)$", txt)))
  expect_true("Calculator: Proportions: Two independent proportions" %in% txt)
  expect_lt(which(txt == "How the design was chosen"), which(grepl("^1\\. Proportions", txt)))
})

test_that("notes on results reach the tab and the Word file, as a Comment line or a Comment column", {
  e1 <- prop_entry(0.05, "e1"); e1$note <- "Lower bound of the budget"
  e2 <- prop_entry(0.04, "e2"); e2$note <- ""
  html <- as.character(study_view_ui(list(id = "s1", name = "S", note = "", entries = list(e1, e2))))
  expect_match(html, "Lower bound of the budget", fixed = TRUE)
  expect_match(html, "esStudies.note(&quot;s1&quot;, &quot;e1&quot;", fixed = TRUE)
  expect_match(html, "esStudies.moveRow(&quot;s1&quot;, &quot;e2&quot;, -1)", fixed = TRUE)
  skip_if_not_installed("officer")
  f <- tempfile(fileext = ".docx"); on.exit(unlink(f))
  writeBin(study_docx(list(id = "s1", name = "S", entries = list(e1, e2))), f)
  s <- officer::docx_summary(officer::read_docx(f))
  cells <- s$text[s$content_type == "table cell"]
  expect_true(all(c("Comment", "Lower bound of the budget") %in% cells))
  m <- study_entry("means", "Means", calc_means_1s(mu0 = 120, mu1 = 125, sd = 15), means_content[["single"]]); m$id <- "e3"; m$note <- "From the 2019 survey"
  writeBin(study_docx(list(id = "s1", name = "S", entries = list(m))), f)
  expect_true("Comment: From the 2019 survey" %in% officer::docx_summary(officer::read_docx(f))$text)
})

test_that("section moves are offered between calculator sections, and the study note survives the record from the page", {
  m <- study_entry("means", "Means", calc_means_1s(mu0 = 120, mu1 = 125, sd = 15), means_content[["single"]]); m$id <- "e3"
  html <- as.character(study_view_ui(list(id = "s1", name = "S", note = "", entries = list(prop_entry(0.05, "e1"), m))))
  expect_match(html, "Move section down", fixed = TRUE)
  expect_match(html, "Move section up", fixed = TRUE)
  expect_match(html, "esStudies.moveSection(&quot;s1&quot;, &quot;proportion\\r", fixed = TRUE)
  st <- studies_normalize(list(studies = list(list(id = "s1", name = "S", note = "keep me", entries = list()))))
  expect_equal(st$studies[[1]]$note, "keep me")
})

test_that("the guide's last step offers Add this design choice", {
  node <- Filter(function(n) isTRUE(n$terminal), design_nodes)[[1]]
  html <- as.character(.render_design_terminal(node, list()))
  expect_match(html, 'id="design_wizard_study_target"', fixed = TRUE)
  expect_match(html, "esStudies.request(&#39;design_wizard_study_add&#39;", fixed = TRUE)
})

test_that("the randomization list and survey selection offer Add to study, with their own methods paragraph", {
  for (m in c("randomization", "survey_selection")) {
    html <- as.character(get(paste0("mod_", m, "_ui"))(m))
    expect_match(html, sprintf('id="%s-study_target"', m), fixed = TRUE)
  }
  v <- calc_randomization_list(20, c("A", "B"), c(1, 1), "block", 4, NULL, seed = 1)
  e <- study_entry("randomization", "Randomization List", v, randomization_content[["block"]])
  expect_equal(e$inputs$seed, "1")
  expect_true(nzchar(randomization_methods_text(v)))
})

test_that("the guide says when nothing in a description could be matched, and clears it on the next answer", {
  shiny::testServer(function(input, output, session) design_wizard_server(input, output, session), {
    session$setInputs(design_wizard_freetext = "Sexual and reproductive determinants in youth of a city")
    session$setInputs(design_wizard_parse = 1)
    expect_match(as.character(output$design_wizard_trace$html), "Nothing in this description could be matched")
    session$setInputs(design_wizard_freetext = "Prevalence of anaemia among adolescent girls in a district")
    session$setInputs(design_wizard_parse = 2)
    expect_false(grepl("Nothing in this description", as.character(output$design_wizard_trace$html)))
    expect_match(as.character(output$design_wizard_trace$html), "A proportion / prevalence")
  })
})
