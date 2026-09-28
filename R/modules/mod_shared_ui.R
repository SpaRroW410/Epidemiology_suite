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
