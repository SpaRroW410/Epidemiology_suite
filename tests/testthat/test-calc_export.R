source(file.path("..", "..", "R", "calc", "calc_result.R"))
source(file.path("..", "..", "R", "calc", "calc_export.R"))
source(file.path("..", "..", "R", "calc", "calc_utils.R"))
source(file.path("..", "..", "R", "calc", "calc_proportion.R"))

test_that("ss_result_flatten flattens inputs with a dot-separated name and collapses vectors", {
  r <- new_ss_result(list(
    n_total = 100, alpha_spent = c(0.01, 0.05),
    inputs = list(p1 = 0.3, note = "two.sided")
  ))
  flat <- ss_result_flatten(r)
  expect_equal(flat$n_total, 100)
  expect_equal(flat$alpha_spent, "0.01; 0.05")
  expect_equal(flat$inputs.p1, 0.3)
  expect_equal(flat$inputs.note, "two.sided")
  expect_false("inputs" %in% names(flat))
})

test_that("ss_result_flatten represents a NULL field as NA, not dropped", {
  r <- new_ss_result(list(n = 10, N = NULL, inputs = list(N = NULL)))
  flat <- ss_result_flatten(r)
  expect_true("N" %in% names(flat))
  expect_true(is.na(flat$N))
  expect_true(is.na(flat$inputs.N))
})

test_that("ss_result_to_csv produces a one-line header + one-line data CSV round-trippable by read.csv", {
  r <- calc_proportion_2s(p1 = 0.3, p2 = 0.5)
  csv <- ss_result_to_csv(r)
  expect_match(csv, "^\"n_per_group\"")
  parsed <- utils::read.csv(text = csv, stringsAsFactors = FALSE)
  expect_equal(nrow(parsed), 1)
  expect_equal(parsed$n_per_group, r$n_per_group)
  expect_equal(parsed$inputs.p1, r$inputs$p1)
})

test_that("ss_result_to_json produces valid, parseable JSON matching the result's own fields", {
  r <- calc_proportion_2s(p1 = 0.3, p2 = 0.5)
  j <- ss_result_to_json(r)
  expect_match(j, "^\\{.*\\}$")
  # Hand-parse without adding a JSON-parsing dependency to the test suite:
  # every field name we put in must appear as a quoted key.
  for (nm in names(ss_result_flatten(r))) {
    expect_match(j, paste0('"', nm, '":'), fixed = TRUE)
  }
})

test_that("ss_result_to_json escapes embedded quotes and backslashes", {
  r <- new_ss_result(list(n = 5, inputs = list(note = 'a "quoted" \\ value')))
  j <- ss_result_to_json(r)
  expect_match(j, '\\\\"quoted\\\\"')
  expect_match(j, "\\\\\\\\")
})

test_that("format_justification names the design, the headline field(s), the inputs, and the citation", {
  r <- calc_proportion_2s(p1 = 0.3, p2 = 0.5)
  para <- format_justification("Two independent proportions", r,
                                citation = "Cohen (1988)", backend = "pwr::pwr.2p.test")
  expect_match(para, "Two independent proportions", fixed = TRUE)
  expect_match(para, "n_per_group = 93", fixed = TRUE)
  expect_match(para, "p1 = 0.3", fixed = TRUE)
  expect_match(para, "pwr::pwr.2p.test", fixed = TRUE)
  expect_match(para, "Cohen (1988)", fixed = TRUE)
  expect_false(grepl("\n", para))
})

test_that("format_justification omits the backend clause when none is given", {
  r <- calc_proportion_2s(p1 = 0.3, p2 = 0.5)
  para <- format_justification("Two independent proportions", r, citation = "Cohen (1988)")
  expect_false(grepl("computed via", para))
})

test_that("format_justification refuses a missing citation rather than silently omitting the source", {
  r <- calc_proportion_2s(p1 = 0.3, p2 = 0.5)
  expect_error(format_justification("Two independent proportions", r, citation = ""), "citation")
  expect_error(format_justification("Two independent proportions", r, citation = NULL), "citation")
})

test_that("format_justification errors rather than silently producing an empty report when no headline field is recognized", {
  r <- new_ss_result(list(inputs = list(x = 1)))
  expect_error(format_justification("X", r, citation = "Y"), "headline")
})

test_that("format_citation_bibtex produces one well-formed @misc entry with the citation preserved verbatim", {
  bib <- format_citation_bibtex("Two independent proportions", "Cohen (1988), pp. 1-10")
  expect_match(bib, "^@misc\\{two_independent_proportions,")
  expect_match(bib, "note = \\{Cohen \\(1988\\), pp. 1-10\\}")
  expect_match(bib, "\\}\\s*$")
})

test_that("format_citation_bibtex escapes literal braces in the citation text", {
  bib <- format_citation_bibtex("X", "A {special} note")
  expect_match(bib, "\\\\\\{special\\\\\\}")
})

test_that("format_citation_ris produces a generic (GEN) record with title and note tags", {
  ris <- format_citation_ris("Two independent proportions", "Cohen (1988)")
  expect_match(ris, "^TY  - GEN")
  expect_match(ris, "TI  - Two independent proportions", fixed = TRUE)
  expect_match(ris, "N1  - Cohen \\(1988\\)")
  expect_match(ris, "ER  - ")
})

test_that("citation key is a stable, ASCII, underscore-joined slug of the design title", {
  bib <- format_citation_bibtex("Non-inferiority trial, hazard ratio (Cox PH)", "Ref")
  expect_match(bib, "^@misc\\{non_inferiority_trial_hazard_ratio_cox_ph,")
})

# grepl()/regexpr() on non-ASCII bytes are themselves unreliable on a host
# with no working multibyte locale (the exact problem .ascii_safe() exists
# to work around -- see its own comment), so these tests check ASCII-ness
# via raw byte values instead of a regex, which has no such dependency.
.is_ascii_only <- function(s) all(as.integer(charToRaw(s)) <= 127L)

test_that("format_justification transliterates non-ASCII characters this app's citations use (em dash, section sign, diaeresis)", {
  r <- new_ss_result(list(n = 5, inputs = list()))
  para <- format_justification("A — B", r, citation = "See §3.1 (Schönbrodt)")
  expect_true(.is_ascii_only(para))
  expect_match(para, "A -- B", fixed = TRUE)
  expect_match(para, "sec. 3.1", fixed = TRUE)
  expect_match(para, "Schoenbrodt", fixed = TRUE)
})

test_that("format_citation_bibtex and format_citation_ris are pure ASCII even given non-ASCII input", {
  bib <- format_citation_bibtex("Café design", "Ref — 1988")
  ris <- format_citation_ris("Café design", "Ref — 1988")
  expect_true(.is_ascii_only(bib))
  expect_true(.is_ascii_only(ris))
})
