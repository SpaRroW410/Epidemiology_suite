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

# A folded "Advanced options" section for the inputs most people leave alone (the sidedness of the test, an optional finite-population
# size, an allocation ratio). Closed by default. `condition` is the JavaScript condition under which the section exists at all, so a
# design with nothing advanced to show does not get an empty section; inputs inside keep their own conditionalPanel()s. A collapsed
# section still holds live inputs: their values are bound and used whether or not it is open.
advanced_options_ui <- function(ns, ..., condition = NULL, title = "Advanced options") {
  panel <- bslib::accordion(
    id = ns("adv_acc"), open = FALSE, class = "mb-3",
    bslib::accordion_panel(title, value = "advanced", ...)
  )
  if (is.null(condition)) panel else conditionalPanel(condition = condition, panel)
}

# Results export (ROADMAP P1 item 9 / finding F10): a copy-able sample-size
# justification paragraph, CSV/JSON downloads, and a citation download
# (BibTeX/RIS), generic across every design -- calc_export.R's functions
# take a design title + ss_result (calc_result.R) + citation/backend, all
# already known to each module's own content_*.R. One UI block
# (`export_controls_ui()`) and one server call (`render_export_handlers()`)
# per module; add both once, not per design.
export_controls_ui <- function(ns) {
  # folded by default: most visits only want the number, and a closed panel is not rendered until it is opened
  bslib::accordion(
    id = ns("export_acc"), open = FALSE, class = "mt-3",
    bslib::accordion_panel(
      "Export this result: protocol paragraph, CSV, JSON, citation", value = "export",
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
#' @param value_fn Extracts the `ss_result` from what `result()` returns;
#'   defaults to `res$value`, the shape every module's dispatch already
#'   uses. Override only for the rare module whose `result` reactive
#'   returns more than one `ss_result` in one go (e.g. Meta-Analysis Power
#'   bundles a required-k result with a companion achieved-power one) --
#'   pick whichever one is this module's own headline answer.
#' @noRd
render_export_handlers <- function(output, result, content_fn, value_fn = function(res) res$value) {
  build <- function(fn) {
    res <- result()
    req(res$ok)
    entry <- content_fn()
    fn(value_fn(res), entry)
  }
  # Reuses calc_export.R's own BibTeX-key slugifier so a design's exported
  # files are named after it (e.g. "epidemiologysuite_two_independent_
  # proportions.csv") instead of a generic name every design would collide on.
  slug <- function() .citation_key(content_fn()$title)

  output$justification_text <- renderText({
    build(function(v, entry) format_justification(entry$title, v, entry$citation, entry$backend))
  })
  output$download_csv <- downloadHandler(
    filename = function() paste0("epidemiologysuite_", slug(), ".csv"),
    content = function(file) writeLines(build(function(v, entry) ss_result_to_csv(v)), file)
  )
  output$download_json <- downloadHandler(
    filename = function() paste0("epidemiologysuite_", slug(), ".json"),
    content = function(file) writeLines(build(function(v, entry) ss_result_to_json(v)), file)
  )
  output$download_bibtex <- downloadHandler(
    filename = function() paste0("epidemiologysuite_", slug(), ".bib"),
    content = function(file) {
      writeLines(build(function(v, entry) format_citation_bibtex(entry$title, entry$citation)), file)
    }
  )
  output$download_ris <- downloadHandler(
    filename = function() paste0("epidemiologysuite_", slug(), ".ris"),
    content = function(file) {
      writeLines(build(function(v, entry) format_citation_ris(entry$title, entry$citation)), file)
    }
  )
}

# Power / sensitivity curves (ROADMAP P1 item 10): "required n vs. effect
# size" and "required n vs. power", computed by calc_curve.R's
# ss_curve_points() from the design's own calc_*() function and current
# inputs -- base R graphics (plot()), no new dependency.
power_curves_ui <- function(ns) {
  # folded by default; the plots are not drawn (so not computed) until the panel is opened
  bslib::accordion(
    id = ns("curves_acc"), open = FALSE, class = "mt-2",
    bslib::accordion_panel(
      "Power / sensitivity curves", value = "curves",
      p(class = "text-muted small",
        "Every other input held at its current value. A point where the",
        "formula has no solution (e.g. an effect size outside its valid",
        "range) is simply omitted, not fabricated."),
      uiOutput(ns("curve_unavailable")),
      # Only shown for a design whose curve is too slow to recompute on every
      # input change (see render_power_curves()'s `gated`). The button is
      # static so its click count survives re-renders of the rest of the block.
      conditionalPanel(
        condition = sprintf("output['%s'] == 'yes'", ns("curve_gated")),
        uiOutput(ns("curve_gate_note")),
        actionButton(ns("curve_go"), "Compute / recompute curves", class = "btn-sm btn-outline-primary mb-2")
      ),
      plotOutput(ns("curve_effect"), height = "260px"),
      plotOutput(ns("curve_power"), height = "260px")
    )
  )
}

#' Wire power_curves_ui() outputs into a module's server
#'
#' @param output The module's own `output`.
#' @param curve_spec A plain function (not a reactive -- called from inside
#'   each output's own reactive context, like `content_fn` in
#'   `render_export_handlers()`, so a bare `input$design` read inside it
#'   already establishes the right dependency) returning either `NULL`
#'   (this design has no curve wiring) or
#'   `list(calc_fn, args, effect = list(param, values, label, title),
#'   power = list(param, values, label, title), gated)`.
#'   - Each axis's optional `title` replaces the default plot title; a
#'     precision-based design uses the second axis for its precision
#'     target (e.g. a CI width) instead of power.
#'   - `gated = list(note = "...")` marks a design whose calc_fn is too
#'     slow to recompute on every input change: its curves are computed only
#'     when the user clicks "Compute / recompute curves", and are never shown
#'     for inputs other than the ones they were computed from. Requires
#'     `input`.
#' @param input The module's own `input`; needed only for gated designs.
#' @noRd
render_power_curves <- function(output, curve_spec, input = NULL) {
  gated_store <- reactiveVal(NULL)

  is_gated <- function(spec) !is.null(spec) && !is.null(spec$gated)
  store_matches <- function(store, spec) {
    !is.null(store) && is_gated(spec) &&
      identical(store$args, spec$args) &&
      identical(store$effect_param, spec$effect$param)
  }

  output$curve_unavailable <- renderUI({
    spec <- curve_spec()
    if (is.null(spec)) {
      div(class = "text-muted small", "Power curves are not yet available for this design.")
    }
  })
  output$curve_gated <- renderText({
    if (is_gated(curve_spec())) "yes" else "no"
  })
  outputOptions(output, "curve_gated", suspendWhenHidden = FALSE)
  output$curve_gate_note <- renderUI({
    spec <- curve_spec()
    if (!is_gated(spec)) return(NULL)
    fresh <- store_matches(gated_store(), spec)
    div(class = if (fresh) "text-muted small" else "alert alert-warning small",
        strong("Slow calculation: "), spec$gated$note,
        if (!fresh) " The curves below are not shown until you click the button; they are never shown for inputs other than the ones they were computed from.")
  })

  if (!is.null(input)) {
    observeEvent(input$curve_go, {
      spec <- tryCatch(isolate(curve_spec()), error = function(e) NULL)
      if (!is_gated(spec)) return()
      shiny::withProgress(message = "Computing curves", value = 0, {
        pts <- list()
        for (which in c("effect", "power")) {
          axis <- spec[[which]]
          if (!is.null(axis)) {
            pts[[which]] <- ss_curve_points(spec$calc_fn, spec$args, axis$param, axis$values,
                                            time_limit = 4)
          }
          shiny::incProgress(0.5)
        }
      })
      gated_store(list(args = spec$args, effect_param = spec$effect$param, pts = pts))
    })
  }

  .draw_curve <- function(pts, spec, which) {
    axis <- spec[[which]]
    if (nrow(pts) == 0) {
      # Every grid point was rejected by the design's own validation (e.g.
      # a contrast of all zeros): say so rather than leave a blank box.
      plot.new()
      text(0.5, 0.5, "No valid points for the current inputs\n(the design's own validation rejected every value)",
           cex = 0.9, col = "grey40")
      return(invisible())
    }
    label <- if (!is.null(axis$label)) axis$label else axis$param
    main <- if (!is.null(axis$title)) axis$title else
      if (which == "power") "Required n vs. power" else "Required n vs. effect size"
    plot(pts$x, pts$y, type = "l", lwd = 2, xlab = label, ylab = "Required n", main = main)
    skipped <- attr(pts, "timeouts")
    if (!is.null(skipped) && skipped > 0) {
      mtext(sprintf("%d point(s) left out: too slow to compute (typically where the effect is close to zero)", skipped),
            side = 1, line = 4, cex = 0.7, col = "firebrick")
    }

    current <- tryCatch(do.call(spec$calc_fn, spec$args), error = function(e) NULL)
    if (!is.null(current)) {
      fname <- .ss_curve_n_field(current)
      if (!is.null(fname)) {
        points(spec$args[[axis$param]], current[[fname]], pch = 19, col = "firebrick")
      }
    }
  }

  # the points of one curve (shared by the plot and its text description, so they are computed once)
  .curve_pts <- function(spec, which) {
    axis <- spec[[which]]
    req(axis)
    if (is_gated(spec)) {
      store <- gated_store()
      req(store_matches(store, spec))
      store$pts[[which]]
    } else {
      ss_curve_points(spec$calc_fn, spec$args, axis$param, axis$values, time_limit = 2)
    }
  }
  pts_effect <- reactive({ spec <- curve_spec(); req(spec); .curve_pts(spec, "effect") })
  pts_power <- reactive({ spec <- curve_spec(); req(spec); .curve_pts(spec, "power") })

  # text description of a curve for people who cannot see it (the plot's alt text): axes, ranges, the trend, and the current setting
  .curve_alt <- function(pts, spec, which) {
    axis <- spec[[which]]
    label <- if (!is.null(axis$label)) axis$label else axis$param
    main <- if (!is.null(axis$title)) axis$title else
      if (which == "power") "Required n vs. power" else "Required n vs. effect size"
    if (is.null(pts) || nrow(pts) == 0) return(sprintf("%s. No valid points for the current inputs, so no curve is drawn.", main))
    fmt <- function(v) format(signif(v, 3), trim = TRUE)
    d <- diff(pts$y)
    trend <- if (all(d <= 1e-9)) "The required n falls as the horizontal value increases."
      else if (all(d >= -1e-9)) "The required n rises as the horizontal value increases."
      else sprintf("The required n is lowest at %s = %s and highest at %s = %s.", label, fmt(pts$x[which.min(pts$y)]), label, fmt(pts$x[which.max(pts$y)]))
    cur <- if (is_gated(spec)) NULL else tryCatch(do.call(spec$calc_fn, spec$args), error = function(e) NULL)
    fname <- if (is.null(cur)) NULL else .ss_curve_n_field(cur)
    now <- if (!is.null(fname)) sprintf(" At the current setting, %s = %s, the required n is %s (marked with a red dot).",
                                         label, fmt(spec$args[[axis$param]]), fmt(cur[[fname]])) else ""
    sprintf("Line chart: %s. Horizontal axis: %s, from %s to %s. Vertical axis: required n, from %s to %s. %s%s",
            main, label, fmt(min(pts$x)), fmt(max(pts$x)), fmt(min(pts$y)), fmt(max(pts$y)), trend, now)
  }

  output$curve_effect <- renderPlot({
    spec <- curve_spec()
    req(spec)
    .draw_curve(pts_effect(), spec, "effect")
  }, alt = function() { spec <- curve_spec(); req(spec); .curve_alt(pts_effect(), spec, "effect") })
  output$curve_power <- renderPlot({
    spec <- curve_spec()
    req(spec)
    .draw_curve(pts_power(), spec, "power")
  }, alt = function() { spec <- curve_spec(); req(spec); .curve_alt(pts_power(), spec, "power") })
}
