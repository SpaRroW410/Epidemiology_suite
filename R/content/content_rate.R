# Metadata for the Incidence Rate module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_rate.R (SDD 4.2: "content is data, not hardcoded UI").

rate_content <- list(
  precision = list(
    title = "Incidence Rate Estimation, Precision-Based",
    formula_latex = paste0(
      "$$\\text{time} = x / r \\quad \\text{(person-time needed to accumulate } x \\text{ events)}$$"
    ),
    explanation = paste(
      "This calculator finds the number of events (and the corresponding",
      "amount of person-time follow-up) needed to estimate an incidence",
      "rate to a target confidence-interval width -- no hypothesis test, no",
      "comparison group, just a precision target.",
      "",
      "- **rate** - the expected rate (events per unit person-time, e.g.",
      "  per person-year).",
      "- **conf_width** - the desired full width of the confidence interval,",
      "  in the same units as rate; should not exceed 5x the rate.",
      "- **conf_level** - the confidence level, typically 0.95.",
      "- **method** - \"exact\" is recommended when you expect fewer than 5",
      "  events; \"score\" is a good general-purpose default otherwise.",
      "",
      "The calculator returns the number of *events* needed, then the",
      "person-time required to expect that many (= events / rate) -- e.g.",
      "if you need 20 events and expect a rate of 2.5 per person-year, you",
      "need about 8 person-years of follow-up (which could be 8 people",
      "followed for 1 year, or 1 person followed for 8 years, etc.).",
      sep = "\n"
    ),
    worked_example = paste(
      "presize's own documented example: for a rate of 2.5 events per unit",
      "person-time and a target 95% CI width of 2.243 (score method), this",
      "calculator returns 21 events needed (rounding presize's own 20.005",
      "up), requiring about 8.4 units of person-time -- matching presize's",
      "own reported figures for this rate/width combination.",
      sep = "\n"
    ),
    citation = paste(
      "Barker L. A Comparison of Nine Confidence Intervals for a Poisson",
      "Parameter When the Expected Number of Events is <= 5. Am Stat.",
      "2002;56(2):85-89. (as implemented by presize::prec_rate)."
    ),
    backend = "presize::prec_rate()"
  )
)
