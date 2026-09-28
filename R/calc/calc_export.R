# Results export (ROADMAP P1 item 9 / finding F10): a sample-size
# justification paragraph, flat CSV/JSON dumps, and a citation in
# BibTeX/RIS form, all generated generically from an `ss_result` (see
# calc_result.R) plus the design's own citation/backend text -- already
# stored per-design in every module's content_*.R and already displayed
# on that module's Reference tab, so nothing new needs to be authored
# per design. Pure functions, no Shiny dependency, directly unit-testable
# (mirrors every calc_*.R file's own "no Shiny here" convention);
# R/modules/mod_shared_ui.R wires these into each module's UI/server.

#' Flatten an `ss_result` into a single-row, CSV/JSON-friendly named list
#'
#' Nested fields (currently only `inputs`) are flattened with a
#' dot-separated name (`inputs.p0`); a vector field longer than 1 is
#' collapsed to a single semicolon-separated string (e.g. a group-sequential
#' design's `alpha_spent`, or a genetics design's per-arm odds ratios) --
#' CSV has no native concept of a list cell, and this keeps the JSON export
#' symmetric with the CSV one rather than emitting nested arrays in one and
#' not the other.
#'
#' @param result An `ss_result`
#' @return A flat named list of length-1 character/numeric/logical values
ss_result_flatten <- function(result) {
  stopifnot(is.list(result))

  flatten_value <- function(v) {
    if (is.list(v)) return(NULL) # shouldn't occur beyond `inputs`; guard anyway
    if (length(v) == 0) return(NA)
    if (length(v) == 1) return(v)
    paste(v, collapse = "; ")
  }

  out <- list()
  for (nm in setdiff(names(result), "inputs")) {
    out[[nm]] <- flatten_value(result[[nm]])
  }
  if (!is.null(result$inputs) && is.list(result$inputs)) {
    for (nm in names(result$inputs)) {
      out[[paste0("inputs.", nm)]] <- flatten_value(result$inputs[[nm]])
    }
  }
  out
}

#' One-row CSV text for an `ss_result`
#'
#' @param result An `ss_result`
#' @return A single character string: a header line, a newline, a data
#'   line -- ready to write directly to a `.csv` file (already newline-
#'   terminated CSV text, not a data frame).
ss_result_to_csv <- function(result) {
  flat <- ss_result_flatten(result)
  df <- as.data.frame(lapply(flat, function(v) if (is.na(v)) NA else as.character(v)),
                       stringsAsFactors = FALSE, check.names = FALSE)
  con <- textConnection("csv_out", "w", local = TRUE)
  on.exit(close(con))
  utils::write.csv(df, con, row.names = FALSE)
  paste(csv_out, collapse = "\n")
}

#' One-object JSON text for an `ss_result`, hand-rolled (no new dependency)
#'
#' A small, deliberately narrow serializer for exactly the value shapes an
#' `ss_result` actually contains (single strings/numbers/logicals, or NA) --
#' not a general-purpose JSON encoder. If a future design's result ever
#' contains something this doesn't handle, `ss_result_flatten()`'s
#' `flatten_value()` has already reduced it to one of these shapes first.
#'
#' @param result An `ss_result`
#' @return A single-line JSON object as a character string
ss_result_to_json <- function(result) {
  flat <- ss_result_flatten(result)

  esc <- function(s) gsub('"', '\\\\"', gsub("\\\\", "\\\\\\\\", s))
  encode_scalar <- function(v) {
    if (identical(v, NA) || (length(v) == 1 && is.na(v))) return("null")
    if (is.logical(v)) return(if (isTRUE(v)) "true" else "false")
    if (is.numeric(v)) return(format(v, trim = TRUE, scientific = FALSE))
    paste0('"', esc(as.character(v)), '"')
  }

  pairs <- vapply(names(flat), function(nm) {
    sprintf('"%s":%s', esc(nm), encode_scalar(flat[[nm]]))
  }, character(1))

  paste0("{", paste(pairs, collapse = ","), "}")
}

# Dynamic Shiny outputs (renderText -> the websocket JSON message) and
# downloaded files both need to render correctly regardless of the host's
# locale -- and unlike this app's static, once-rendered UI text (which the
# browser gets as part of the page's own HTML and displays correctly
# regardless), a non-ASCII byte sent through R's JSON serialization on a
# host with no UTF-8 locale configured (checked: some minimal server/
# container images have none) can come out corrupted. Citations/titles are
# free text (not typeset for display), so transliterating the handful of
# non-ASCII characters this app's own content actually uses (checked
# across every content_*.R file) to their plain-ASCII equivalent sidesteps
# the whole problem, portably, and is also simply more compatible for a
# BibTeX/RIS file a reference manager will read.
# Dynamic Shiny outputs (renderText -> the websocket JSON message) and
# downloaded files both need to render correctly regardless of the host's
# locale -- and unlike this app's static, once-rendered UI text (which the
# browser gets as part of the page's own HTML and displays correctly
# regardless), a non-ASCII byte sent through R's JSON serialization on a
# host with no working multibyte locale (checked: this project's own CI/dev
# sandbox has none installed) can come out corrupted -- confirmed this goes
# deeper than JSON escaping: even character-level R operations that are
# normally locale-independent (gsub(), intToUtf8()) can fail or silently
# mis-render under a session with no multibyte locale at all. Citations/
# titles are free text (not typeset for display), so transliterating the
# handful of non-ASCII characters this app's own content actually uses
# (checked across every content_*.R file, plus common accented Latin
# letters for future citations) to their plain-ASCII equivalent sidesteps
# the whole problem -- portably, and it is also simply more compatible for
# a BibTeX/RIS file a reference manager will read.
#
# Implemented at the RAW BYTE level (charToRaw()/rawToChar(), never gsub()
# or intToUtf8()) specifically because those higher-level, locale-aware
# functions are the ones observed to fail here; raw vectors are just
# bytes, so matching a UTF-8 character's known, fixed byte sequence has no
# locale dependency at all.
.ascii_safe <- function(s) {
  table <- list(
  list(pat = as.raw(c(0xe2, 0x80, 0x94)), rep = charToRaw("--")),
  list(pat = as.raw(c(0xe2, 0x80, 0x93)), rep = charToRaw("-")),
  list(pat = as.raw(c(0xe2, 0x80, 0x98)), rep = charToRaw("'")),
  list(pat = as.raw(c(0xe2, 0x80, 0x99)), rep = charToRaw("'")),
  list(pat = as.raw(c(0xe2, 0x80, 0x9c)), rep = charToRaw("\"")),
  list(pat = as.raw(c(0xe2, 0x80, 0x9d)), rep = charToRaw("\"")),
  list(pat = as.raw(c(0xc2, 0xa7)), rep = charToRaw("sec. ")),
  list(pat = as.raw(c(0xc2, 0xb1)), rep = charToRaw("+/-")),
  list(pat = as.raw(c(0xc2, 0xb0)), rep = charToRaw(" deg")),
  list(pat = as.raw(c(0xc3, 0x84)), rep = charToRaw("Ae")),
  list(pat = as.raw(c(0xc3, 0x96)), rep = charToRaw("Oe")),
  list(pat = as.raw(c(0xc3, 0x9c)), rep = charToRaw("Ue")),
  list(pat = as.raw(c(0xc3, 0xa4)), rep = charToRaw("ae")),
  list(pat = as.raw(c(0xc3, 0xb6)), rep = charToRaw("oe")),
  list(pat = as.raw(c(0xc3, 0xbc)), rep = charToRaw("ue")),
  list(pat = as.raw(c(0xc3, 0x80)), rep = charToRaw("A")),
  list(pat = as.raw(c(0xc3, 0x81)), rep = charToRaw("A")),
  list(pat = as.raw(c(0xc3, 0x82)), rep = charToRaw("A")),
  list(pat = as.raw(c(0xc3, 0x83)), rep = charToRaw("A")),
  list(pat = as.raw(c(0xc3, 0x85)), rep = charToRaw("A")),
  list(pat = as.raw(c(0xc3, 0x87)), rep = charToRaw("C")),
  list(pat = as.raw(c(0xc3, 0x88)), rep = charToRaw("E")),
  list(pat = as.raw(c(0xc3, 0x89)), rep = charToRaw("E")),
  list(pat = as.raw(c(0xc3, 0x8a)), rep = charToRaw("E")),
  list(pat = as.raw(c(0xc3, 0x8b)), rep = charToRaw("E")),
  list(pat = as.raw(c(0xc3, 0x8c)), rep = charToRaw("I")),
  list(pat = as.raw(c(0xc3, 0x8d)), rep = charToRaw("I")),
  list(pat = as.raw(c(0xc3, 0x8e)), rep = charToRaw("I")),
  list(pat = as.raw(c(0xc3, 0x8f)), rep = charToRaw("I")),
  list(pat = as.raw(c(0xc3, 0x91)), rep = charToRaw("N")),
  list(pat = as.raw(c(0xc3, 0x92)), rep = charToRaw("O")),
  list(pat = as.raw(c(0xc3, 0x93)), rep = charToRaw("O")),
  list(pat = as.raw(c(0xc3, 0x94)), rep = charToRaw("O")),
  list(pat = as.raw(c(0xc3, 0x95)), rep = charToRaw("O")),
  list(pat = as.raw(c(0xc3, 0x99)), rep = charToRaw("U")),
  list(pat = as.raw(c(0xc3, 0x9a)), rep = charToRaw("U")),
  list(pat = as.raw(c(0xc3, 0x9b)), rep = charToRaw("U")),
  list(pat = as.raw(c(0xc3, 0x9d)), rep = charToRaw("Y")),
  list(pat = as.raw(c(0xc3, 0xa0)), rep = charToRaw("a")),
  list(pat = as.raw(c(0xc3, 0xa1)), rep = charToRaw("a")),
  list(pat = as.raw(c(0xc3, 0xa2)), rep = charToRaw("a")),
  list(pat = as.raw(c(0xc3, 0xa3)), rep = charToRaw("a")),
  list(pat = as.raw(c(0xc3, 0xa5)), rep = charToRaw("a")),
  list(pat = as.raw(c(0xc3, 0xa7)), rep = charToRaw("c")),
  list(pat = as.raw(c(0xc3, 0xa8)), rep = charToRaw("e")),
  list(pat = as.raw(c(0xc3, 0xa9)), rep = charToRaw("e")),
  list(pat = as.raw(c(0xc3, 0xaa)), rep = charToRaw("e")),
  list(pat = as.raw(c(0xc3, 0xab)), rep = charToRaw("e")),
  list(pat = as.raw(c(0xc3, 0xac)), rep = charToRaw("i")),
  list(pat = as.raw(c(0xc3, 0xad)), rep = charToRaw("i")),
  list(pat = as.raw(c(0xc3, 0xae)), rep = charToRaw("i")),
  list(pat = as.raw(c(0xc3, 0xaf)), rep = charToRaw("i")),
  list(pat = as.raw(c(0xc3, 0xb1)), rep = charToRaw("n")),
  list(pat = as.raw(c(0xc3, 0xb2)), rep = charToRaw("o")),
  list(pat = as.raw(c(0xc3, 0xb3)), rep = charToRaw("o")),
  list(pat = as.raw(c(0xc3, 0xb4)), rep = charToRaw("o")),
  list(pat = as.raw(c(0xc3, 0xb5)), rep = charToRaw("o")),
  list(pat = as.raw(c(0xc3, 0xb9)), rep = charToRaw("u")),
  list(pat = as.raw(c(0xc3, 0xba)), rep = charToRaw("u")),
  list(pat = as.raw(c(0xc3, 0xbb)), rep = charToRaw("u")),
  list(pat = as.raw(c(0xc3, 0xbd)), rep = charToRaw("y"))

  )
  raw <- charToRaw(s)
  for (t in table) raw <- .raw_replace(raw, t$pat, t$rep)
  rawToChar(raw)
}

# Byte-sequence search-and-replace (see `.ascii_safe()`'s comment for why
# this doesn't use `gsub()`). `pat` and `rep` are raw vectors; `pat` need
# not be the same length as `rep`.
.raw_replace <- function(raw, pat, rep) {
  n <- length(raw); m <- length(pat)
  if (m == 0L || n < m) return(raw)
  out <- vector("list", 0L)
  push <- function(x) if (length(x) > 0L) out[[length(out) + 1L]] <<- x
  i <- 1L
  seg_start <- 1L
  while (i <= n - m + 1L) {
    if (identical(raw[i:(i + m - 1L)], pat)) {
      push(if (i > seg_start) raw[seg_start:(i - 1L)] else raw(0))
      push(rep)
      i <- i + m
      seg_start <- i
    } else {
      i <- i + 1L
    }
  }
  push(if (seg_start <= n) raw[seg_start:n] else raw(0))
  if (length(out) == 0L) return(raw(0))
  do.call(c, out)
}

#' Sample-size justification paragraph, ready to paste into a protocol
#'
#' Fully generic across every design: enumerates the result's own headline
#' field(s) (same detection `format.ss_result()` uses) and its `inputs`,
#' names the design, and appends the citation (and, if given, the backend
#' package/method) -- no per-design template needed, since every calc_*()
#' function already names its own fields meaningfully and every module's
#' content_*.R already carries a citation.
#'
#' @param design_title Human-readable design name, e.g. "Two independent
#'   proportions" (a module's `<name>_content[[design]]$title`, or the
#'   catalog's own label)
#' @param result An `ss_result`
#' @param citation Citation text for this design (`content_*.R`'s own
#'   `citation` field)
#' @param backend Optional "implemented via" string (`content_*.R`'s own
#'   `backend` field); omitted from the paragraph if NULL
#' @return A single character string (one paragraph, no line breaks)
format_justification <- function(design_title, result, citation, backend = NULL) {
  stopifnot(is.list(result))
  if (is.null(citation) || !nzchar(citation)) {
    stop("citation must be a non-empty string -- never omit the source a reviewer would ask for.")
  }
  design_title <- .ascii_safe(design_title)
  citation <- .ascii_safe(citation)
  if (!is.null(backend)) backend <- .ascii_safe(backend)

  nms <- setdiff(names(result), "inputs")
  headline <- Filter(.ss_result_is_headline, nms)
  headline_txt <- vapply(headline, function(nm) {
    sprintf("%s = %s", nm, .ss_result_fmt_value(result[[nm]]))
  }, character(1))
  if (length(headline_txt) == 0) {
    stop("result has no field format.ss_result()'s own headline detector recognizes (n*/k*/*power*) -- nothing to report.")
  }

  input_txt <- character(0)
  if (!is.null(result$inputs) && is.list(result$inputs) && length(result$inputs) > 0) {
    input_txt <- vapply(names(result$inputs), function(nm) {
      sprintf("%s = %s", nm, .ss_result_fmt_value(result$inputs[[nm]]))
    }, character(1))
  }

  paste0(
    "For the \"", design_title, "\" design, this app's calculation gives ",
    paste(headline_txt, collapse = ", "),
    if (length(input_txt) > 0) paste0(" (assuming ", paste(input_txt, collapse = ", "), ")") else "",
    if (!is.null(backend) && nzchar(backend)) paste0(", computed via ", backend) else "",
    ". Reference: ", citation
  )
}

# Shared by the BibTeX/RIS generators: a short, stable, ASCII citation key
# from a design title -- e.g. "Two independent proportions" ->
# "two_independent_proportions".
.citation_key <- function(design_title) {
  key <- tolower(design_title)
  key <- gsub("[^a-z0-9]+", "_", key)
  gsub("^_|_$", "", key)
}

#' Citation in BibTeX form
#'
#' The citations stored in this app's content_*.R files are free-text
#' (author/journal/year run together as written in the original source),
#' not structured author/year/journal/volume fields -- parsing those back
#' out reliably across ~150 differently-formatted citations risks
#' fabricating wrong structured metadata, which this project's own rules
#' treat as worse than not having it. So this deliberately emits a generic
#' `@misc` entry with the full citation text preserved verbatim in `note`,
#' rather than a `@article` entry with guessed fields.
#'
#' @param design_title Human-readable design name
#' @param citation Citation text for this design
#' @return A single character string, valid BibTeX for one `@misc` entry
format_citation_bibtex <- function(design_title, citation) {
  design_title <- .ascii_safe(design_title)
  citation <- .ascii_safe(citation)
  esc <- function(s) gsub("([{}])", "\\\\\\1", s)
  sprintf(
    "@misc{%s,\n  title = {%s},\n  note = {%s},\n  howpublished = {sample2result sample size calculator}\n}\n",
    .citation_key(design_title), esc(design_title), esc(citation)
  )
}

#' Citation in RIS form
#'
#' Same free-text-preserving approach as `format_citation_bibtex()`: a
#' generic record type (GEN) with the citation text in the note (N1) field,
#' not parsed into structured author/year/journal RIS tags.
#'
#' @param design_title Human-readable design name
#' @param citation Citation text for this design
#' @return A single character string, valid RIS for one record
format_citation_ris <- function(design_title, citation) {
  design_title <- .ascii_safe(design_title)
  citation <- .ascii_safe(citation)
  paste0(
    "TY  - GEN\n",
    "TI  - ", design_title, "\n",
    "N1  - ", citation, "\n",
    "ER  - \n"
  )
}
