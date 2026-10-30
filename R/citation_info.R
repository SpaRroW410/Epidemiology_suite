# How to cite the software: one place for the facts (author, version, year, address, DOI) and the functions that turn them into the
# citation formats shown on the app's Cite tab. Keep the version equal to DESCRIPTION's (a test checks it) and the year, version
# and address in step with CITATION.cff and inst/CITATION.

# The DOI that Zenodo issues for a release, e.g. "10.5281/zenodo.1234567". NA until it exists: the Cite tab then says so and cites the
# web address instead. This is the only line to change when the DOI arrives (plus CITATION.cff and inst/CITATION).
.citation_doi <- NA_character_

# The release the citations name, and the tag of the GitHub / Zenodo release ("v" + this). R only accepts numbers in the DESCRIPTION
# version, so a pre-release cannot be written there: DESCRIPTION carries 0.99.x, which sorts before 1.0.0, until the final 1.0 release.
.release_label <- "1.0-alpha"

suite_citation_info <- function() {
  list(
    title = "Epidemiological suite",
    subtitle = "sample size, power and analysis tools for epidemiology and clinical research",
    family = "Maheshwari", given = "Mukul",
    version = .release_label, year = "2026",
    url = "https://github.com/SpaRroW410/Sample_size_all",
    site = "https://sparrow410.github.io/Sample_size_all/",
    doi = if (is.na(.citation_doi) || !nzchar(.citation_doi)) NA_character_ else sub("^https?://(dx[.])?doi[.]org/", "", .citation_doi),
    publisher = "Zenodo"
  )
}

citation_formats <- c(
  "APA 7th edition" = "apa", "Vancouver (NLM)" = "vancouver", "Harvard" = "harvard", "IEEE" = "ieee",
  "MLA 9th edition" = "mla", "Chicago (author-date)" = "chicago", "BibTeX" = "bibtex", "RIS (EndNote, Zotero, Mendeley)" = "ris",
  "Sentence for a Methods section" = "methods"
)

# the persistent link: the DOI address when there is a DOI, else the repository address
.citation_link <- function(info) if (is.na(info$doi)) info$url else paste0("https://doi.org/", info$doi)

#' The citation of the software in one format
#'
#' @param format One of `citation_formats`: "apa", "vancouver", "harvard", "ieee", "mla", "chicago", "bibtex", "ris", "methods".
#' @param info The facts, from [suite_citation_info()].
#' @param accessed Date shown in the formats that give a date of access (Harvard, MLA).
#' @return A single string (several lines for BibTeX and RIS).
#' @noRd
citation_text <- function(format = "apa", info = suite_citation_info(), accessed = Sys.Date()) {
  format <- match.arg(format, unname(citation_formats))
  link <- .citation_link(info)
  has_doi <- !is.na(info$doi)
  ini <- paste0(substr(info$given, 1, 1), ".")
  acc <- format(accessed, "%d %B %Y")
  switch(format,
    apa = sprintf("%s, %s (%s). %s (Version %s) [Computer software]. %s%s", info$family, ini, info$year, info$title, info$version,
                  if (has_doi) paste0(info$publisher, ". ") else "", link),
    vancouver = sprintf("%s %s. %s [computer program]. Version %s. %s. %sAvailable from: %s", info$family, substr(info$given, 1, 1), info$title,
                        info$version, info$year, if (has_doi) sprintf("doi:%s. ", info$doi) else "", link),
    harvard = sprintf("%s, %s (%s) %s. Version %s. %sAvailable at: %s (Accessed: %s).", info$family, ini, info$year, info$title, info$version,
                      if (has_doi) paste0(info$publisher, ". ") else "", link, acc),
    ieee = sprintf("%s %s, \"%s,\" version %s, %s. [Online]. Available: %s", ini, info$family, info$title, info$version, info$year, link),
    mla = sprintf("%s, %s. %s. Version %s, %s%s, %s. Accessed %s.", info$family, info$given, info$title, info$version,
                  if (has_doi) paste0(info$publisher, ", ") else "", info$year, link, acc),
    chicago = sprintf("%s, %s. %s. %s. Version %s. %s%s.", info$family, info$given, info$year, info$title, info$version,
                      if (has_doi) paste0(info$publisher, ". ") else "", link),
    bibtex = paste0(
      sprintf("@misc{%s%s%s,\n", tolower(info$family), info$year, "suite"),
      sprintf("  author = {%s, %s},\n", info$family, info$given),
      sprintf("  title = {%s},\n", info$title),
      sprintf("  year = {%s},\n", info$year),
      sprintf("  version = {%s},\n", info$version),
      sprintf("  note = {Computer software},\n"),
      if (has_doi) sprintf("  publisher = {%s},\n  doi = {%s},\n", info$publisher, info$doi),
      sprintf("  url = {%s}\n}", link)),
    ris = paste(c("TY  - COMP", sprintf("AU  - %s, %s", info$family, info$given), sprintf("TI  - %s", info$title), sprintf("PY  - %s", info$year),
                  sprintf("ET  - %s", info$version), if (has_doi) c(sprintf("PB  - %s", info$publisher), sprintf("DO  - %s", info$doi)),
                  sprintf("UR  - %s", link), "ER  - "), collapse = "\n"),
    methods = sprintf("Sample sizes were calculated with %s (version %s; %s).", info$title, info$version,
                      if (has_doi) paste0("doi:", info$doi) else paste("available at", link))
  )
}

# file name and media type of the download for each format
.citation_file <- function(format) {
  switch(format, bibtex = "epidemiological-suite.bib", ris = "epidemiological-suite.ris", "epidemiological-suite-citation.txt")
}
