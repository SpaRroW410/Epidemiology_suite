# Information tips and the Glossary page (owner's request of 2 Nov 2026). The text is in content_glossary.R.
#
# info_tip("phi") is a small (i) button that shows a popover with the term's short definition: on hover, on keyboard focus and on a
# tap (a phone has no hover; tapping elsewhere closes it). It is a real <button> with an accessible name, so a screen reader announces
# "What is phi ...?". Bootstrap popover trigger "hover focus" was chosen after trying "click" and "hover focus click" in Chromium with a
# mouse and with touch emulation: "click" does not open on hover, and the combination adds nothing. Tapping the (i) inside a label
# does not select a radio button or focus an input.

info_tip <- function(term) {
  g <- glossary_entry(term)
  bslib::popover(
    tags$button(type = "button", class = "btn btn-link p-0 ms-1 info-tip", `aria-label` = paste0("What is ", g$label, "?"), "\u24d8"),
    tags$p(class = "mb-1", g$short),
    if (!is.null(g$formula)) tags$p(class = "mb-0 small text-muted", tags$code(g$formula)),
    title = g$label, placement = "auto", options = list(trigger = "hover focus")
  )
}

# A label followed by its information tip, for the label of an input: numericInput(id, with_tip("phi", "phi"), ...)
with_tip <- function(text, term) tagList(text, info_tip(term))

info_tip_css <- "
.info-tip { font-size: 1rem; line-height: 1; vertical-align: baseline; text-decoration: none; }
.info-tip:focus-visible { outline: 2px solid var(--bs-primary); outline-offset: 2px; }
.popover { max-width: 22rem; }
"

# The Glossary page: every term with its explanation, filtered by what is typed in the box (done in the browser).
glossary_ui <- function() {
  ids <- names(glossary)
  ord <- order(tolower(vapply(glossary, `[[`, "", "label")))
  items <- lapply(ids[ord], function(id) {
    g <- glossary[[id]]
    div(class = "glossary-item mb-3", `data-text` = tolower(paste(g$label, g$short, if (!is.null(g$long)) g$long)),
        h5(class = "mb-1", id = paste0("glossary_", id), g$label),
        p(class = "mb-1", g$short),
        if (!is.null(g$long)) p(class = "mb-1 text-muted", g$long),
        if (!is.null(g$formula)) p(class = "mb-1 small", strong("Formula: "), tags$code(g$formula)),
        if (!is.null(g$source)) p(class = "mb-0 small text-muted", "Source: ", g$source))
  })
  tagList(
    p("Plain-language meanings of the terms the calculators use. A small (i) beside a term in a calculator shows its short definition."),
    textInput("glossary_filter", NULL, placeholder = "Filter the terms, e.g. phi, odds, power", width = "100%"),
    tags$script(HTML("
$(document).on('input', '#glossary_filter', function () {
  var q = this.value.toLowerCase().trim();
  document.querySelectorAll('.glossary-item').forEach(function (e) {
    e.style.display = (!q || e.getAttribute('data-text').indexOf(q) >= 0) ? '' : 'none';
  });
});")),
    items
  )
}
