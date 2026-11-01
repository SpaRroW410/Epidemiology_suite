# Shared interface pieces for the five precision-based calculators (single proportion, single mean, cluster survey of a proportion,
# incidence rate, diagnostic accuracy): the absolute/relative choice, the non-response / loss-to-follow-up input, the "When should I
# use which?" panel, the line stating the precision both ways, and the warnings and enrolment figures under the result. The
# calculation and the checks are in calc_precision_checks.R.

precision_type_input <- function(id, label = "Precision expressed as", selected = "absolute",
                                 absolute = "Absolute (+/- d on the scale of the estimate)",
                                 relative = "Relative (+/- a fraction of the estimate)") {
  choices <- c("absolute", "relative")
  names(choices) <- c(absolute, relative)
  radioButtons(id, label, choices = choices, selected = selected)
}

nonresponse_input <- function(id, label = "Expected non-response / loss to follow-up (fraction; 0 = none, 0.1 = 10%)") {
  numericInput(id, label, value = 0, min = 0, max = 0.95, step = 0.05)
}

# `kind`: "proportion", "mean", "cluster", "rate" or "diagnostic"
precision_guidance_ui <- function(kind) {
  tags$details(
    class = "mb-3",
    tags$summary("When should I use absolute or relative precision?"),
    div(class = "mt-2", shiny::markdown(precision_guidance_md(kind)))
  )
}

# The precision line under the inputs; `text` from precision_equivalents_text() (NULL shows nothing).
precision_equivalents_ui <- function(text) {
  if (is.null(text)) return(NULL)
  div(class = "text-muted small mb-2", text)
}

precision_notes_ui <- function(notes) {
  if (length(notes) == 0) return(NULL)
  tagList(lapply(notes, function(n) div(class = "text-warning", n)))
}

# "Enrol ..." line under a result; NULL when there is no inflation.
nonresponse_result_ui <- function(enrolled, required, nonresponse, what = "participants") {
  if (is.null(enrolled) || is.null(nonresponse) || nonresponse <= 0) return(NULL)
  p(strong(sprintf("To enrol, allowing for %s non-response / loss to follow-up: ", .prec_pct(nonresponse))), enrolled,
    span(class = "text-muted", sprintf(" (%s / (1 - %s), rounded up; %s %s expected to remain)", required,
                                       format(nonresponse, trim = TRUE), required, what)))
}

# An optional numeric input: NULL when empty (numericInput(value = NA) reports NULL or NA).
.input_or_null <- function(x) if (is.null(x) || length(x) != 1 || is.na(x)) NULL else x

# Non-response input as a number (empty = 0).
.nonresponse_value <- function(x) {
  x <- .input_or_null(x)
  if (is.null(x)) 0 else x
}
