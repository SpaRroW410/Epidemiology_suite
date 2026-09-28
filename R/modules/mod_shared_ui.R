# Shared rendering helper for formula display, used by every mod_*.R's
# "Formula / Help" tab in place of a bare withMathJax(HTML(...)) call.
# Centralizes the MathJax rendering plus a collapsible raw-LaTeX view with a
# copy-to-clipboard button, so all modules render formulas identically (SDD
# 4.2: content is data, rendered generically) and every formula's LaTeX
# source becomes visible/copyable without editing 24 files' content.

.formula_block_counter <- local({
  n <- 0L
  function() {
    n <<- n + 1L
    n
  }
})

render_formula_block <- function(latex) {
  raw_id <- paste0("formula_raw_", .formula_block_counter())
  tagList(
    div(class = "formula-block", withMathJax(HTML(latex))),
    tags$details(
      tags$summary("Show LaTeX source"),
      tags$pre(
        tags$code(id = raw_id, latex),
        style = "white-space: pre-wrap;"
      ),
      tags$button(
        "Copy", type = "button",
        class = "btn btn-sm btn-outline-secondary mt-1",
        onclick = sprintf(
          paste0(
            "navigator.clipboard.writeText(document.getElementById('%s').innerText)",
            ".then(function(btn){ return function(){",
            "  var old = btn.innerText; btn.innerText = 'Copied!';",
            "  setTimeout(function(){ btn.innerText = old; }, 1500);",
            "}; }(this));"
          ),
          raw_id
        )
      )
    )
  )
}

# Explicit "Calculate" button for Monte Carlo designs (ROADMAP F9/P1#7):
# these simulate (and refit models, or search over thousands of replicates)
# rather than solve a closed form, so recomputing on every keystroke would
# make one user's slow design freeze the single R process for everyone else
# on the same app instance. Paired with the server-side pattern in each
# affected module: the reactive depends on the design radio (so switching
# TO a Monte Carlo design still computes once with its current defaults)
# and the Calculate button, but isolates every other input so typing in a
# numeric field no longer re-triggers the simulation.
monte_carlo_calculate_ui <- function(ns, note = "can take a few seconds. Set the inputs above, then click Calculate.") {
  tagList(
    div(class = "alert alert-warning small", strong("Monte Carlo simulation: "), note),
    actionButton(ns("calculate"), "Calculate", class = "btn-primary")
  )
}

# Results export (ROADMAP P1 item 9 / finding F10): a copy-able sample-size
# justification paragraph, CSV/JSON downloads, and a citation download
# (BibTeX/RIS), generic across every design -- calc_export.R's functions
# take a design title + ss_result (calc_result.R) + citation/backend, all
# already known to each module's own content_*.R. One UI block
# (`export_controls_ui()`) and one server call (`render_export_handlers()`)
# per module; add both once, not per design.
export_controls_ui <- function(ns) {
  tagList(
    hr(),
    h5("Export this result"),
    p(class = "text-muted small",
      "A ready-to-paste justification paragraph for a protocol or ethics submission."),
    verbatimTextOutput(ns("justification_text")),
    tags$button(
      "Copy paragraph", type = "button",
      class = "btn btn-sm btn-outline-secondary mb-2",
      onclick = sprintf(
        paste0(
          "navigator.clipboard.writeText(document.getElementById('%s').innerText)",
          ".then(function(btn){ return function(){",
          "  var old = btn.innerText; btn.innerText = 'Copied!';",
          "  setTimeout(function(){ btn.innerText = old; }, 1500);",
          "}; }(this));"
        ),
        ns("justification_text")
      )
    ),
    div(
      downloadButton(ns("download_csv"), "CSV", class = "btn-sm btn-outline-secondary"),
      downloadButton(ns("download_json"), "JSON", class = "btn-sm btn-outline-secondary"),
      downloadButton(ns("download_bibtex"), "Citation (BibTeX)", class = "btn-sm btn-outline-secondary"),
      downloadButton(ns("download_ris"), "Citation (RIS)", class = "btn-sm btn-outline-secondary")
    )
  )
}

#' Wire the export_controls_ui() outputs into a module's server
#'
#' @param output The module's own `output`
#' @param result The module's own `result` reactive -- must return
#'   `list(ok, value, message)` exactly as every module's existing
#'   `tryCatch()`-wrapped design dispatch already does; `value` is the
#'   `ss_result` returned by whichever `calc_*()` function was called.
#' @param content_fn A plain function (not a reactive -- called from
#'   inside each output's own reactive context, so a plain `input$design`
#'   read inside it already establishes the right dependency) returning
#'   that design's `content_*.R` entry: `list(title, citation, backend)`
#'   (`backend` optional).
render_export_handlers <- function(output, result, content_fn) {
  build <- function(fn) {
    res <- result()
    req(res$ok)
    entry <- content_fn()
    fn(res$value, entry)
  }
  # Reuses calc_export.R's own BibTeX-key slugifier so a design's exported
  # files are named after it (e.g. "sample2result_two_independent_
  # proportions.csv") instead of a generic name every design would collide on.
  slug <- function() .citation_key(content_fn()$title)

  output$justification_text <- renderText({
    build(function(v, entry) format_justification(entry$title, v, entry$citation, entry$backend))
  })
  output$download_csv <- downloadHandler(
    filename = function() paste0("sample2result_", slug(), ".csv"),
    content = function(file) writeLines(build(function(v, entry) ss_result_to_csv(v)), file)
  )
  output$download_json <- downloadHandler(
    filename = function() paste0("sample2result_", slug(), ".json"),
    content = function(file) writeLines(build(function(v, entry) ss_result_to_json(v)), file)
  )
  output$download_bibtex <- downloadHandler(
    filename = function() paste0("sample2result_", slug(), ".bib"),
    content = function(file) {
      writeLines(build(function(v, entry) format_citation_bibtex(entry$title, entry$citation)), file)
    }
  )
  output$download_ris <- downloadHandler(
    filename = function() paste0("sample2result_", slug(), ".ris"),
    content = function(file) {
      writeLines(build(function(v, entry) format_citation_ris(entry$title, entry$citation)), file)
    }
  )
}
