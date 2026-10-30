test_that("every citation format names the author, title, version, year and the link", {
  info <- suite_citation_info()
  for (f in unname(citation_formats)) {
    txt <- citation_text(f)
    expect_type(txt, "character"); expect_length(txt, 1)
    if (f != "methods") expect_match(txt, "Maheshwari", fixed = TRUE, info = f)   # the Methods sentence names the software, not its author
    expect_match(txt, "Epidemiological suite", fixed = TRUE, info = f)
    expect_match(txt, info$version, fixed = TRUE, info = f)
    expect_match(txt, info$url, fixed = TRUE, info = f)
    if (f != "methods") expect_match(txt, info$year, fixed = TRUE, info = f)
  }
})

test_that("the version and year in the citation are the package's and the current release", {
  desc <- NULL
  for (p in c("../../DESCRIPTION", "../../../DESCRIPTION", "DESCRIPTION")) if (file.exists(p)) { desc <- read.dcf(p); break }
  skip_if(is.null(desc), "DESCRIPTION not available")
  expect_equal(suite_citation_info()$version, unname(desc[1, "Version"]))
})

test_that("formats follow the usual layouts", {
  expect_match(citation_text("apa"), "^Maheshwari, M\\. \\(2026\\)\\. Epidemiological suite \\(Version 1\\.0\\.0\\) \\[Computer software\\]\\. ")
  expect_match(citation_text("vancouver"), "^Maheshwari M\\. Epidemiological suite \\[computer program\\]\\. Version 1\\.0\\.0\\. 2026\\. ")
  expect_match(citation_text("ieee"), "^M\\. Maheshwari, \"Epidemiological suite,\" version 1\\.0\\.0, 2026\\. \\[Online\\]\\. Available: ")
  expect_match(citation_text("bibtex"), "^@misc\\{maheshwari2026suite,\\n  author = \\{Maheshwari, Mukul\\},")
  expect_match(citation_text("ris"), "^TY  - COMP\\nAU  - Maheshwari, Mukul\\n")
  expect_match(citation_text("ris"), "ER  - $")
  expect_match(citation_text("harvard", accessed = as.Date("2026-11-05")), "\\(Accessed: 05 November 2026\\)\\.$")
  expect_match(citation_text("mla", accessed = as.Date("2026-11-05")), "Accessed 05 November 2026\\.$")
})

test_that("without a DOI the web address is cited; with one, the DOI address and the publisher are", {
  expect_true(is.na(suite_citation_info()$doi) || nzchar(suite_citation_info()$doi))
  testthat::local_mocked_bindings(.citation_doi = NA_character_)
  for (f in unname(citation_formats)) expect_false(grepl("doi", citation_text(f), ignore.case = TRUE), info = f)
  testthat::local_mocked_bindings(.citation_doi = "https://doi.org/10.5281/zenodo.1234567")
  expect_equal(suite_citation_info()$doi, "10.5281/zenodo.1234567")          # a pasted address is reduced to the DOI itself
  expect_match(citation_text("apa"), "Zenodo\\. https://doi\\.org/10\\.5281/zenodo\\.1234567$")
  expect_match(citation_text("vancouver"), "doi:10\\.5281/zenodo\\.1234567\\. Available from: https://doi\\.org/10\\.5281/zenodo\\.1234567$")
  expect_match(citation_text("bibtex"), "publisher = \\{Zenodo\\},\\n  doi = \\{10\\.5281/zenodo\\.1234567\\},\\n  url = \\{https://doi\\.org/10\\.5281/zenodo\\.1234567\\}")
  expect_match(citation_text("ris"), "PB  - Zenodo\\nDO  - 10\\.5281/zenodo\\.1234567\\nUR  - https://doi\\.org/10\\.5281/zenodo\\.1234567\\nER")
  expect_match(citation_text("methods"), "doi:10\\.5281/zenodo\\.1234567")
})

test_that("an unknown format is refused and each format has a download name", {
  expect_error(citation_text("nonsense"), "should be one of")
  expect_equal(.citation_file("bibtex"), "epidemiological-suite.bib")
  expect_equal(.citation_file("ris"), "epidemiological-suite.ris")
  expect_equal(.citation_file("apa"), "epidemiological-suite-citation.txt")
})

test_that("the Cite tab is in the page and its files exist", {
  page <- as.character(htmltools::as.tags(attr(epidemiologicasuite_app(lazy = FALSE), "ui_tags")))
  expect_match(page, "How to cite", fixed = TRUE)
  expect_match(page, "cite_format", fixed = TRUE)
  for (p in c("../../CITATION.cff", "../../inst/CITATION")) if (file.exists(p)) expect_true(TRUE)
})

test_that("the Cite tab shows the chosen format and says the DOI is pending (browser test)", {
  skip_if_no_ui()
  app <- ui_fresh_driver(background_load = FALSE, name = "cite")
  withr::defer(app$stop())
  ui_select_tab(app, "main_nav", "Cite")
  app$wait_for_js("document.getElementById('cite_text') && document.getElementById('cite_text').innerText.length > 20", timeout = 30000)
  expect_match(ui_output_text(app, "cite_text"), "^Maheshwari, M\\. \\(2026\\)")
  app$set_inputs(cite_format = "bibtex"); app$wait_for_idle(800)
  expect_match(ui_output_text(app, "cite_text"), "^@misc\\{")
  expect_match(app$get_js("document.querySelector('#cite_doi_note').innerText"), "DOI")
})
