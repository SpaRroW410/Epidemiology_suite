# A PubMed search builder at the guide's end points (CHECKLIST FIND-22; decision F4 in docs/SDD.md, section 17).
#
# The user's concepts (population or condition, exposure or intervention, outcome) become title/abstract terms, plus any MeSH
# headings the user chooses; they are joined with a study-design filter of one of three kinds, each labelled as such:
#   - validated: a published filter with a reported sensitivity and specificity, copied exactly as its source prints it
#     (the Cochrane Highly Sensitive Search Strategies for randomised trials; PubMed's Clinical Queries filters of Haynes et al.);
#   - pubmed: a filter built into PubMed and documented by NLM, not a published validation (the Systematic Review filter);
#   - simple: design terms written for this app, not validated (every design has one).
# The draft's search terms (docs/find_routing/03_study_design_registry_37.md, Part B) were the starting point; its four MeSH
# headings that do not exist ("Cluster Randomized Controlled Trials", "Ecological Studies", "Factorial Design", and "Equivalence
# Trials" for the publication type "Equivalence Trial") are not used, and "Network Meta-Analysis" is a publication type, not a
# subject heading. Every MeSH heading printed here is in inst/extdata/mesh_checked.csv, checked against NLM's MeSH by
# tools/find/check_mesh.R (FIND-23); a test fails when one is missing.
#
# Nothing is sent anywhere: the app writes the query; the user copies it or follows the link to PubMed.

# --- sources -------------------------------------------------------------------------------------------------------------------
.pubmed_sources <- list(
  cochrane_ts4 = list(
    short = "Cochrane Handbook 6.5, technical supplement to chapter 4, section 3.6.1",
    cite = paste("Lefebvre C, Glanville J, Briscoe S, et al. Technical Supplement to Chapter 4: Searching for and selecting studies",
                 "[last updated September 2024]. In: Higgins JPT et al. (eds). Cochrane Handbook for Systematic Reviews of Interventions",
                 "version 6.5. Cochrane, 2024. Boxes 3.a and 3.b (PubMed format, 2008 revision)"),
    url = "https://www.cochrane.org/authors/handbooks-and-manuals/handbook/current/chapter-04-technical-supplement-searching-and-selecting-studies",
    read = "full text (8 Nov 2026)"),
  clinical_queries = list(
    short = "PubMed Clinical Queries (Haynes et al.)",
    cite = paste("PubMed User Guide, Clinical Queries filters, Clinical Study Categories (revised December 2011), based on the work of",
                 "Haynes RB et al.; for example Haynes RB et al. BMJ 2005;330:1179 (PMID 15894554, treatment) and Wilczynski NL,",
                 "Haynes RB. AMIA Annu Symp Proc 2003:719-723 (PMID 14728267, causation)"),
    url = "https://pubmed.ncbi.nlm.nih.gov/help/#clinical-queries-filters",
    read = "PubMed help page (8 Nov 2026)"),
  pubmed_help = list(
    short = "PubMed User Guide",
    cite = "PubMed User Guide, \"Systematic reviews\": the Systematic Review filter, systematic[sb]",
    url = "https://pubmed.ncbi.nlm.nih.gov/help/#systematic-reviews",
    read = "PubMed help page (8 Nov 2026)")
)

# --- the published and built-in filters, exactly as their sources print them ------------------------------------------------
# Cochrane Boxes 3.a and 3.b are numbered lines ("#9 OR ... ; #9 NOT #10"); they are written here as one line with the same
# Boolean structure. The Clinical Queries strings are copied from the PubMed help page, including its spacing.
.pubmed_filters <- list(
  cochrane_sens = list(
    status = "validated", source = "cochrane_ts4",
    label = "Cochrane highly sensitive strategy for randomised trials, sensitivity-maximizing version",
    note = "Cochrane recommends starting with this version; use the next one if it retrieves too many records.",
    query = paste("(randomized controlled trial [pt] OR controlled clinical trial [pt] OR randomized [tiab] OR placebo [tiab]",
                  "OR drug therapy [sh] OR randomly [tiab] OR trial [tiab] OR groups [tiab]) NOT (animals [mh] NOT humans [mh])")),
  cochrane_prec = list(
    status = "validated", source = "cochrane_ts4",
    label = "Cochrane highly sensitive strategy for randomised trials, sensitivity- and precision-maximizing version",
    note = NULL,
    query = paste("(randomized controlled trial [pt] OR controlled clinical trial [pt] OR randomized [tiab] OR placebo [tiab]",
                  "OR clinical trials as topic [mesh:noexp] OR randomly [tiab] OR trial [ti]) NOT (animals [mh] NOT humans [mh])")),
  cq_therapy_broad = list(
    status = "validated", source = "clinical_queries",
    label = "Clinical Queries: Therapy, broad (sensitivity 99%, specificity 70%)", note = NULL,
    query = paste("((clinical[Title/Abstract] AND trial[Title/Abstract]) OR clinical trials as topic[MeSH Terms] OR",
                  "clinical trial[Publication Type] OR random*[Title/Abstract] OR random allocation[MeSH Terms] OR",
                  "therapeutic use[MeSH Subheading])")),
  cq_therapy_narrow = list(
    status = "validated", source = "clinical_queries",
    label = "Clinical Queries: Therapy, narrow (sensitivity 93%, specificity 97%)", note = NULL,
    query = paste("(randomized controlled trial[Publication Type] OR (randomized[Title/Abstract] AND controlled[Title/Abstract]",
                  "AND trial[Title/Abstract]))")),
  cq_etiology_broad = list(
    status = "validated", source = "clinical_queries",
    label = "Clinical Queries: Etiology, broad (sensitivity 93%, specificity 63%)",
    note = "Built to find studies of cause or harm of any design, not this design only.",
    query = paste("(risk*[Title/Abstract] OR risk*[MeSH:noexp] OR (risk adjustment[MeSH:noexp] OR risk assessment[MeSH:noexp]",
                  "OR risk factors[MeSH:noexp] OR risk management[MeSH:noexp] OR risk taking[MeSH:noexp]) OR cohort studies[MeSH Terms]",
                  "OR group[Text Word] OR groups[Text Word] OR grouped [Text Word])")),
  cq_etiology_narrow = list(
    status = "validated", source = "clinical_queries",
    label = "Clinical Queries: Etiology, narrow (sensitivity 51%, specificity 95%)",
    note = "Built to find studies of cause or harm of any design, not this design only.",
    query = paste("((relative[Title/Abstract] AND risk*[Title/Abstract]) OR (relative risk[Text Word]) OR risks[Text Word] OR",
                  "cohort studies[MeSH:noexp] OR (cohort[Title/Abstract] AND study[Title/Abstract]) OR (cohort[Title/Abstract]",
                  "AND studies[Title/Abstract]))")),
  pubmed_sr = list(
    status = "pubmed", source = "pubmed_help",
    label = "PubMed's Systematic Review filter",
    note = "Built into PubMed: the Systematic Review publication type plus a search strategy for records not yet indexed.",
    query = "systematic[sb]")
)

# --- design terms (simple filters, not validated) and which published filters suit each design ------------------------------
# `terms`: the design's own words, written for this app. `filters`: the published or built-in filters offered for the design.
# `combine`: offer "published filter AND design terms" (when the published filter is broader than the design).
.pubmed_designs <- list(
  sr_meta          = list(filters = "pubmed_sr", combine = TRUE,
                          terms = "(\"Meta-Analysis\"[pt] OR \"meta-analy*\"[tiab] OR metaanaly*[tiab])"),
  sr_narrative     = list(filters = "pubmed_sr", combine = FALSE,
                          terms = "(\"Systematic Review\"[pt] OR \"systematic review*\"[tiab] OR \"narrative synthesis\"[tiab])"),
  scoping          = list(filters = NULL, combine = FALSE,
                          terms = "(\"Scoping Review\"[pt] OR \"scoping review*\"[tiab] OR \"scoping stud*\"[tiab] OR \"evidence map*\"[tiab])"),
  nma              = list(filters = "pubmed_sr", combine = TRUE,
                          terms = paste("(\"Network Meta-Analysis\"[pt] OR \"network meta-analy*\"[tiab] OR \"mixed treatment comparison*\"[tiab]",
                                        "OR \"multiple treatment comparison*\"[tiab])")),
  umbrella         = list(filters = "pubmed_sr", combine = TRUE,
                          terms = paste("(\"umbrella review*\"[tiab] OR \"overview of reviews\"[tiab] OR \"overview of systematic reviews\"[tiab]",
                                        "OR \"review of reviews\"[tiab] OR \"meta-review*\"[tiab])")),
  qes              = list(filters = "pubmed_sr", combine = TRUE,
                          terms = paste("(\"meta-ethnograph*\"[tiab] OR \"meta-synthes*\"[tiab] OR metasynthes*[tiab] OR",
                                        "\"qualitative evidence synthes*\"[tiab] OR \"thematic synthesis\"[tiab] OR \"qualitative systematic review*\"[tiab])")),
  phenomenology    = list(filters = NULL, combine = FALSE,
                          terms = "(phenomenolog*[tiab] OR \"lived experience*\"[tiab])"),
  grounded         = list(filters = NULL, combine = FALSE,
                          terms = "(\"Grounded Theory\"[Mesh] OR \"grounded theory\"[tiab] OR \"constant comparative\"[tiab])"),
  ethnography      = list(filters = NULL, combine = FALSE,
                          terms = "(\"Anthropology, Cultural\"[Mesh] OR ethnograph*[tiab] OR \"participant observation\"[tiab])"),
  case_study       = list(filters = NULL, combine = FALSE,
                          terms = "(\"qualitative case stud*\"[tiab] OR (\"case stud*\"[tiab] AND qualitative[tiab]))"),
  qual_descriptive = list(filters = NULL, combine = FALSE,
                          terms = paste("(\"Qualitative Research\"[Mesh] OR qualitative[tiab] OR \"Focus Groups\"[Mesh] OR \"focus group*\"[tiab]",
                                        "OR \"thematic analysis\"[tiab] OR interview*[tiab])")),
  mm_explanatory   = list(filters = NULL, combine = FALSE,
                          terms = "(\"mixed method*\"[tiab] OR \"mixed-method*\"[tiab] OR multimethod*[tiab] OR \"explanatory sequential\"[tiab])"),
  mm_exploratory   = list(filters = NULL, combine = FALSE,
                          terms = "(\"mixed method*\"[tiab] OR \"mixed-method*\"[tiab] OR multimethod*[tiab] OR \"exploratory sequential\"[tiab])"),
  mm_convergent    = list(filters = NULL, combine = FALSE,
                          terms = paste("(\"mixed method*\"[tiab] OR \"mixed-method*\"[tiab] OR multimethod*[tiab] OR \"convergent parallel\"[tiab]",
                                        "OR \"convergent design\"[tiab])")),
  mm_embedded      = list(filters = c("cochrane_sens", "cochrane_prec"), combine = TRUE,
                          terms = "(\"process evaluation*\"[tiab] OR \"Qualitative Research\"[Mesh] OR qualitative[tiab] OR interview*[tiab])"),
  parallel_rct     = list(filters = c("cochrane_sens", "cochrane_prec", "cq_therapy_broad", "cq_therapy_narrow"), combine = FALSE,
                          terms = "(\"Randomized Controlled Trial\"[pt] OR randomized[tiab] OR randomised[tiab] OR randomly[tiab])"),
  crossover        = list(filters = c("cochrane_sens", "cochrane_prec"), combine = TRUE,
                          terms = "(\"Cross-Over Studies\"[Mesh] OR crossover[tiab] OR \"cross-over\"[tiab])"),
  cluster_rct      = list(filters = c("cochrane_sens", "cochrane_prec"), combine = TRUE,
                          terms = paste("(\"cluster random*\"[tiab] OR \"cluster-random*\"[tiab] OR \"group random*\"[tiab] OR",
                                        "\"community random*\"[tiab])")),
  stepped_wedge    = list(filters = c("cochrane_sens", "cochrane_prec"), combine = TRUE,
                          terms = "(\"stepped wedge\"[tiab] OR \"stepped-wedge\"[tiab])"),
  noninferiority   = list(filters = c("cochrane_sens", "cochrane_prec"), combine = TRUE,
                          terms = "(\"Equivalence Trial\"[pt] OR \"non-inferior*\"[tiab] OR noninferior*[tiab] OR \"equivalence trial*\"[tiab])"),
  did              = list(filters = NULL, combine = FALSE,
                          terms = paste("(\"Controlled Before-After Studies\"[Mesh] OR \"difference-in-difference*\"[tiab] OR",
                                        "\"difference in difference*\"[tiab] OR \"controlled before-after\"[tiab] OR \"controlled before and after\"[tiab])")),
  its              = list(filters = NULL, combine = FALSE,
                          terms = paste("(\"Interrupted Time Series Analysis\"[Mesh] OR \"interrupted time series\"[tiab] OR",
                                        "\"interrupted time-series\"[tiab] OR \"segmented regression\"[tiab])")),
  rdd              = list(filters = NULL, combine = FALSE,
                          terms = "(\"regression discontinuity\"[tiab])"),
  prepost          = list(filters = NULL, combine = FALSE,
                          terms = paste("(\"before-after\"[tiab] OR \"before and after\"[tiab] OR \"pre-post\"[tiab] OR \"pretest-posttest\"[tiab]",
                                        "OR \"single-arm\"[tiab] OR \"single arm\"[tiab])")),
  ecological       = list(filters = NULL, combine = FALSE,
                          terms = "(\"ecological stud*\"[tiab] OR \"ecologic stud*\"[tiab] OR \"ecological analys*\"[tiab] OR \"aggregate data\"[tiab])"),
  ecological_trend = list(filters = NULL, combine = FALSE,
                          terms = "((ecological[tiab] OR ecologic[tiab]) AND (\"time trend*\"[tiab] OR \"time-trend*\"[tiab] OR \"time series\"[tiab]))"),
  case_report      = list(filters = NULL, combine = FALSE,
                          terms = "(\"Case Reports\"[pt] OR \"case report\"[ti])"),
  case_series      = list(filters = NULL, combine = FALSE,
                          terms = "(\"case series\"[tiab] OR \"consecutive patients\"[tiab] OR \"consecutive cases\"[tiab])"),
  descriptive_cs   = list(filters = NULL, combine = FALSE,
                          terms = paste("(\"Cross-Sectional Studies\"[Mesh] OR \"Prevalence\"[Mesh] OR \"Health Surveys\"[Mesh] OR",
                                        "\"cross-sectional\"[tiab] OR prevalence[tiab])")),
  analytic_cs      = list(filters = c("cq_etiology_broad", "cq_etiology_narrow"), combine = FALSE,
                          terms = "(\"Cross-Sectional Studies\"[Mesh] OR \"cross-sectional\"[tiab])"),
  cohort           = list(filters = c("cq_etiology_broad", "cq_etiology_narrow"), combine = FALSE,
                          terms = "(\"Cohort Studies\"[Mesh] OR cohort*[tiab] OR \"follow-up stud*\"[tiab])"),
  case_control     = list(filters = c("cq_etiology_broad", "cq_etiology_narrow"), combine = FALSE,
                          terms = paste("(\"Case-Control Studies\"[Mesh] OR \"case-control\"[tiab] OR \"case control\"[tiab] OR",
                                        "\"case-referent\"[tiab])")),
  nested_cc        = list(filters = c("cq_etiology_broad", "cq_etiology_narrow"), combine = FALSE,
                          terms = "(\"nested case-control\"[tiab] OR \"nested case control\"[tiab] OR \"incidence density sampling\"[tiab])"),
  case_crossover   = list(filters = c("cq_etiology_broad", "cq_etiology_narrow"), combine = FALSE,
                          terms = "(\"case-crossover\"[tiab] OR \"case crossover\"[tiab])"),
  mr               = list(filters = NULL, combine = FALSE,
                          terms = "(\"Mendelian Randomization Analysis\"[Mesh] OR \"mendelian randomi*\"[tiab])")
)

# The filter choices for a design, in order: each published filter (and, where useful, the same AND the design terms), then the
# design terms alone. Values are "<filter>", "<filter>+terms", "terms" or "none".
.pubmed_filter_choices <- function(design) {
  d <- .pubmed_designs[[design]]
  if (is.null(d)) return(NULL)
  out <- character(0)
  for (f in d$filters) {
    lab <- .pubmed_filters[[f]]$label
    kind <- if (identical(.pubmed_filters[[f]]$status, "validated")) "validated filter" else "built into PubMed"
    if (isTRUE(d$combine)) out[paste0(lab, " (", kind, ") AND the design terms (not validated)")] <- paste0(f, "+terms")
    out[paste0(lab, " (", kind, ")")] <- f
  }
  out["Design terms only (simple filter, not validated)"] <- "terms"
  out["No design filter"] <- "none"
  out
}

.pubmed_filter_query <- function(design, choice) {
  d <- .pubmed_designs[[design]]
  if (is.null(d) || is.null(choice) || identical(choice, "none")) return(NULL)
  if (identical(choice, "terms")) return(d$terms)
  combine <- endsWith(choice, "+terms")
  key <- sub("\\+terms$", "", choice)
  if (!key %in% d$filters) return(NULL)
  f <- paste0("(", .pubmed_filters[[key]]$query, ")")
  if (identical(key, "pubmed_sr")) f <- .pubmed_filters[[key]]$query
  if (combine) paste(f, "AND", d$terms) else f
}

# --- the user's concepts --------------------------------------------------------------------------------------------------------
# Synonyms are separated by commas, semicolons, new lines or the word OR; MeSH headings by semicolons or new lines only (a
# heading's name can contain a comma: "Diabetes Mellitus, Type 2"). A term the user already tagged (word[tiab], "a b"[Mesh])
# is kept as typed; any other term is searched in titles and abstracts, quoted when it has more than one word. Brackets and
# quotes inside a plain term are dropped, so a stray character cannot break the query.
.pubmed_split <- function(x, sep = "[,;\n]|\\s+OR\\s+") {
  if (is.null(x) || !nzchar(trimws(x))) return(character(0))
  parts <- trimws(unlist(strsplit(x, sep)))
  parts[nzchar(parts)]
}

.pubmed_stray <- "[][(){}\"]"   # brackets of any kind and double quotes (POSIX class: ] first)
.pubmed_tagged <- "^\"?[^][\"()]+\"?[[:space:]]*\\[[A-Za-z: /]+\\]$"

.pubmed_term <- function(t) {
  if (grepl(.pubmed_tagged, t)) return(t)
  t <- trimws(gsub(.pubmed_stray, "", t))
  if (!nzchar(t)) return(NULL)
  if (grepl("[[:space:]-]", t)) paste0("\"", t, "\"[tiab]") else paste0(t, "[tiab]")
}

.pubmed_mesh <- function(h) {
  h <- trimws(gsub(.pubmed_stray, "", h))
  if (!nzchar(h)) NULL else paste0("\"", h, "\"[Mesh]")
}

.pubmed_concept_block <- function(text, mesh = NULL) {
  terms <- c(unlist(lapply(.pubmed_split(text), .pubmed_term)), unlist(lapply(.pubmed_split(mesh, "[;\n]"), .pubmed_mesh)))
  if (!length(terms)) return(NULL)
  paste0("(", paste(terms, collapse = " OR "), ")")
}

#' The full PubMed query: each concept block (synonyms joined by OR), joined by AND, then AND the design filter.
#' @param concepts,mesh character vectors (one element per concept); `mesh` may be shorter or NULL.
#' @return the query string, or NULL when no concept was entered.
#' @noRd
pubmed_build_query <- function(concepts, mesh = NULL, design = NULL, choice = "none") {
  blocks <- unlist(lapply(seq_along(concepts), function(i)
    .pubmed_concept_block(concepts[[i]], if (i <= length(mesh)) mesh[[i]] else NULL)))
  if (!length(blocks)) return(NULL)
  f <- if (!is.null(design)) .pubmed_filter_query(design, choice) else NULL
  paste(c(blocks, f), collapse = " AND ")
}

pubmed_url <- function(query) paste0("https://pubmed.ncbi.nlm.nih.gov/?term=", utils::URLencode(query, reserved = TRUE))

# --- the MeSH headings a query prints (for the FIND-23 test and tools/find/check_mesh.R) --------------------------------------
# Returns a data frame of the controlled-vocabulary atoms: printed text and kind (descriptor, publication type, qualifier).
# Truncated MeSH searches (risk*[MeSH:noexp], as Clinical Queries prints it) are not headings and are left out.
.pubmed_mesh_atoms <- function(query) {
  atoms <- trimws(unlist(strsplit(gsub("[()]", " ", query), "\\s+(AND|OR|NOT)\\s+")))
  m <- regmatches(atoms, regexec("^\"?([^\"[]+?)\"?\\s*\\[([A-Za-z: ]+)\\]$", atoms))
  out <- lapply(m, function(x) {
    if (length(x) != 3) return(NULL)
    tag <- tolower(trimws(x[3]))
    kind <- if (tag %in% c("mh", "mesh", "mesh:noexp", "mesh terms", "majr")) "descriptor"
            else if (tag %in% c("pt", "publication type")) "publication type"
            else if (tag %in% c("sh", "mesh subheading", "subheading:noexp", "subheading")) "qualifier"
            else NULL
    if (is.null(kind) || grepl("\\*$", x[2])) return(NULL)
    data.frame(printed = trimws(x[2]), kind = kind)
  })
  out <- do.call(rbind, out)
  if (is.null(out)) data.frame(printed = character(0), kind = character(0)) else unique(out)
}

.pubmed_all_mesh_atoms <- function() {
  qs <- c(vapply(.pubmed_filters, `[[`, "", "query"), vapply(.pubmed_designs, `[[`, "", "terms"))
  out <- unique(rbind(do.call(rbind, lapply(qs, .pubmed_mesh_atoms)),
                      data.frame(printed = .pubmed_mesh_examples, kind = "descriptor")))
  rownames(out) <- NULL
  out
}

.mesh_norm <- function(x) gsub("[^a-z0-9]", "", tolower(x))

# --- rendering ------------------------------------------------------------------------------------------------------------------
# Example headings shown in the MeSH boxes (checked with the rest, FIND-23).
.pubmed_mesh_examples <- c("Diabetes Mellitus, Type 2", "Yoga", "Glycated Hemoglobin")

.render_pubmed_builder <- function(design) {
  if (is.null(design) || is.null(.pubmed_designs[[design]])) return(NULL)
  concept <- function(i, label, placeholder) div(class = "col-12 col-md-4",
    textInput(paste0("design_pubmed_c", i), label, placeholder = placeholder, width = "100%"),
    textInput(paste0("design_pubmed_m", i), span(class = "small", "MeSH headings (optional; separate with semicolons)"),
              width = "100%", placeholder = paste("e.g.", .pubmed_mesh_examples[[i]])))
  tags$details(class = "pubmed-builder card card-body mt-2 mb-2",
    tags$summary(class = "fw-semibold", "Search PubMed for studies like this"),
    p(class = "small text-muted mt-2 mb-2",
      "Enter the words for each part of your question; separate synonyms with commas. Words are searched in titles and abstracts. ",
      "Add MeSH headings only after checking them in the ",
      tags$a(href = "https://meshb.nlm.nih.gov/search", target = "_blank", rel = "noopener", .noWS = "after", "MeSH Browser"),
      ". Nothing is sent anywhere until you open the link."),
    div(class = "row g-2",
      concept(1, "Population or condition", "e.g. type 2 diabetes, T2DM"),
      concept(2, "Exposure or intervention", "e.g. yoga, physical activity"),
      concept(3, "Outcome", "e.g. HbA1c, glycaemic control")),
    selectInput("design_pubmed_filter", "Study-design filter", choices = .pubmed_filter_choices(design), width = "100%"),
    uiOutput("design_pubmed_result"))
}

.render_pubmed_result <- function(design, choice, query) {
  key <- if (!is.null(choice)) sub("\\+terms$", "", choice) else "none"
  f <- .pubmed_filters[[key]]
  about <- if (!is.null(f)) {
    s <- .pubmed_sources[[f$source]]
    p(class = "small text-muted mb-2",
      if (identical(f$status, "validated")) strong("A published, validated filter, copied as printed. ") else strong("Built into PubMed. "),
      f$note, if (!is.null(f$note)) " ", "Source: ", tags$a(href = s$url, target = "_blank", rel = "noopener", .noWS = "after", s$short), ".",
      if (endsWith(choice, "+terms")) " The design terms added to it are not part of the validated filter.")
  } else if (identical(choice, "terms")) {
    p(class = "small text-muted mb-2", strong("A simple filter, not validated: "),
      "design words and headings written for this app. It may miss studies that do not use these words.")
  }
  if (is.null(query)) return(tagList(about, p(class = "small text-muted mb-0", "Enter at least one word above to build the search.")))
  tagList(about,
    tags$textarea(id = "design_pubmed_query", class = "form-control font-monospace small", rows = 5, readonly = NA,
                  `aria-label` = "PubMed search", query),
    div(class = "d-flex flex-wrap gap-2 mt-2",
      tags$a(class = "btn btn-sm btn-primary", href = pubmed_url(query), target = "_blank", rel = "noopener", "Open in PubMed"),
      tags$button(type = "button", class = "btn btn-sm btn-outline-secondary",
                  onclick = "navigator.clipboard && navigator.clipboard.writeText(document.getElementById('design_pubmed_query').value);",
                  "Copy")))
}

pubmed_builder_server <- function(input, output, session, design) {
  output$design_pubmed_result <- renderUI({
    d <- design()
    req(d)
    val <- function(id) { x <- input[[id]]; if (is.null(x)) "" else x }
    q <- pubmed_build_query(vapply(paste0("design_pubmed_c", 1:3), val, ""), vapply(paste0("design_pubmed_m", 1:3), val, ""),
                            design = d, choice = input$design_pubmed_filter)
    .render_pubmed_result(d, input$design_pubmed_filter, q)
  })
}
