# Refresh inst/extdata/mesh_checked.csv: every MeSH heading, publication type and subheading the PubMed search builder prints
# (R/pubmed_search.R), looked up in NLM's MeSH (id.nlm.nih.gov/mesh). CHECKLIST FIND-23.
#
#   Rscript tools/find/check_mesh.R [year]      # year: the MeSH year to check against (default: this calendar year)
#
# A heading is accepted only when NLM has a record of that kind whose name is the printed text, ignoring case and with a hyphen
# allowed for a space (Clinical Queries prints "risk taking" for "Risk-Taking"); an entry term is not enough ("Network
# Meta-Analysis" is an entry term of the subject heading "Network Meta-Analysis as Topic" and, since 2025, a publication type). A heading that
# does not exist stops the script with an error, and the file is left as it was. Needs network access; run it when the
# builder's terms change and once a year, after NLM publishes the new MeSH (the test reads the year from the file).

args <- commandArgs(trailingOnly = TRUE)
year <- if (length(args)) args[[1]] else format(Sys.Date(), "%Y")
suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = TRUE))

sparql <- function(q) {
  u <- paste0("https://id.nlm.nih.gov/mesh/sparql?format=JSON&year=", year, "&query=", utils::URLencode(q, reserved = TRUE))
  jsonlite::fromJSON(paste(readLines(u, warn = FALSE), collapse = "\n"))$results$bindings
}

lookup <- function(printed, kind) {
  cls <- switch(kind, "descriptor" = "TopicalDescriptor", "publication type" = "PublicationType", "qualifier" = "Qualifier")
  # only the chosen year's graph: older years keep names that have since changed
  find <- function(label) sparql(paste0(
    "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#> PREFIX meshv: <http://id.nlm.nih.gov/mesh/vocab#> ",
    "SELECT DISTINCT ?r ?l FROM <http://id.nlm.nih.gov/mesh/", year, "> ",
    "WHERE { ?r a meshv:", cls, " ; rdfs:label ?l . FILTER(lcase(str(?l)) = \"", tolower(label), "\") }"))
  b <- find(printed)
  if (!length(b) || !nrow(b)) b <- find(gsub(" ", "-", printed))   # a hyphen printed as a space (risk taking / Risk-Taking)
  if (!length(b) || !nrow(b)) return(NULL)
  data.frame(printed = printed, kind = kind, ui = sub(".*/", "", b$r$value[1]), nlm_label = b$l$value[1])
}

atoms <- .pubmed_all_mesh_atoms()
rows <- lapply(seq_len(nrow(atoms)), function(i) {
  r <- lookup(atoms$printed[i], atoms$kind[i])
  if (is.null(r)) stop("Not in MeSH ", year, " as a ", atoms$kind[i], ": ", atoms$printed[i], call. = FALSE)
  r
})
out <- do.call(rbind, rows)
out$mesh_year <- year
out$checked_on <- format(Sys.Date())
out <- out[order(out$kind, tolower(out$printed)), ]
utils::write.csv(out, "inst/extdata/mesh_checked.csv", row.names = FALSE)
cat(nrow(out), "headings checked against MeSH", year, "\n")
