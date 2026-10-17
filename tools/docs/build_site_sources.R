# Generates the sources of the documentation site (ROADMAP item 17) from the package itself:
#   vignettes/<module>.Rmd   one page per calculator, built from its <module>_content object
#                                     (title, formula, explanation, worked example, citation, "implemented via")
#   vignettes/calculators.Rmd   the overview by workbench and group
#   vignettes/{roadmap,design,algorithm}.Rmd   the docs/*.md files with a header
#   _pkgdown.yml                      tools/docs/pkgdown_template.yml plus the generated article menu
# Nothing generated is committed (see .gitignore): the pages are rebuilt from the source of truth on every
# build, so the site cannot drift from the app. Run from the repository root:
#   Rscript tools/docs/build_site_sources.R
# It needs only pkgload (to read the content objects); building the site then needs pkgdown + pandoc.

suppressMessages(pkgload::load_all(".", quiet = TRUE))
ns <- asNamespace("epidemiologicasuite")
registry <- module_registry()
by_id <- setNames(registry, vapply(registry, `[[`, "", "id"))
out_dir <- "vignettes"
unlink(out_dir, recursive = TRUE)
dir.create(out_dir, recursive = TRUE)

`%||%` <- function(a, b) if (is.null(a)) b else a
yq <- function(x) paste0('"', gsub('"', '\\\\"', gsub("\\\\", "\\\\\\\\", x)), '"')
one_line <- function(x) trimws(gsub("\\s+", " ", x))
write_rmd <- function(name, title, description, body) {
  writeLines(c("---", paste0("title: ", yq(title)), paste0("description: ", yq(description)), "---", "", body),
             file.path(out_dir, paste0(name, ".Rmd")), useBytes = TRUE)
}
field <- function(d, nm) {
  v <- d[[nm]]
  if (is.null(v) || length(v) == 0 || (length(v) == 1 && is.na(v)) || !nzchar(trimws(paste(v, collapse = "")))) return(NULL)
  paste(v, collapse = "\n")
}

design_section <- function(d) {
  if (!is.list(d)) return(character())
  parts <- character()
  ttl <- field(d, "title")
  if (!is.null(ttl)) parts <- c(parts, paste0("## ", one_line(ttl)), "")
  f <- field(d, "formula_latex");     if (!is.null(f)) parts <- c(parts, f, "")
  e <- field(d, "explanation");       if (!is.null(e)) parts <- c(parts, e, "")
  w <- field(d, "worked_example");    if (!is.null(w)) parts <- c(parts, "**Worked example**", "", w, "")
  g <- field(d, "guidance");          if (!is.null(g)) parts <- c(parts, g, "")
  ci <- field(d, "citation");         if (!is.null(ci)) parts <- c(parts, "**Citations.** ", ci, "")
  b <- field(d, "backend");           if (!is.null(b)) parts <- c(parts, paste0("**Implemented via.** `", one_line(b), "`"), "")
  parts
}

is_design <- function(x) is.list(x) && any(c("title", "formula_latex", "explanation") %in% names(x))

overview <- c()
n_pages <- 0L
for (wb in module_workbenches) {
  overview <- c(overview, paste0("## ", wb$title), "")
  for (g in wb$groups) {
    overview <- c(overview, paste0("### ", g$title), "")
    for (mid in g$module_ids) {
      m <- by_id[[mid]]
      cont <- get0(paste0(mid, "_content"), envir = ns, inherits = FALSE)
      designs <- if (is_design(cont)) list(cont) else Filter(is_design, cont)
      body <- unlist(lapply(designs, design_section), use.names = FALSE)
      if (length(body) == 0) body <- "Guidance only: see the app."
      write_rmd(mid, m$title, paste0(wb$title, " > ", g$title), c(
        paste0("*", wb$title, " workbench, ", g$title, ".* Open it in the app from **", wb$title, " > ", m$title, "**."), "", body))
      n_pages <- n_pages + 1L
      ttls <- vapply(designs, function(d) one_line(field(d, "title") %||% ""), "")
      overview <- c(overview, paste0("- [", m$title, "](", mid, ".html)",
                                     if (length(ttls) > 1) paste0(" -- ", length(ttls), " designs") else ""))
    }
    overview <- c(overview, "")
  }
}
write_rmd("calculators", "Calculators", "Every calculator in the app, by workbench",
          c("Each page below shows what the calculator does, its formula, a worked example, the citation and how it is computed -- the same text as the **Formula / Help** and **Reference** tabs in the app.", "", overview))

doc_page <- function(src, name, title, description) {
  txt <- readLines(src, warn = FALSE)
  if (length(txt) && grepl("^# ", txt[1])) txt <- txt[-1]      # the page title replaces the first level-1 heading
  write_rmd(name, title, description, txt)
}
doc_page("docs/ROADMAP.md", "roadmap", "Roadmap and decisions", "What is built, what is next, and the findings log")
doc_page("docs/SDD.md", "design", "Software design", "Architecture, module contract and verification approach")
doc_page("docs/design_identification_algorithm.md", "algorithm", "Study-design identification algorithm", "How the guided wizard routes a question to a calculator")

tpl <- readLines("tools/docs/pkgdown_template.yml", warn = FALSE)
pages <- function(ids) paste0("      - ", ids)
art <- c("articles:",
         "  - title: Start here", "    contents:", "      - calculators",
         "  - title: Project", "    contents:", "      - roadmap", "      - design", "      - algorithm")
for (wb in module_workbenches) for (g in wb$groups) {
  art <- c(art, paste0("  - title: ", yq(paste0(wb$title, ": ", g$title))), "    contents:", pages(g$module_ids))
}
writeLines(c(tpl, "", art), "_pkgdown.yml")
cat(sprintf("Wrote %d calculator pages, the overview, 3 project pages and _pkgdown.yml\n", n_pages))
