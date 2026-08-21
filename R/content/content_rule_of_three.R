# Metadata for the Rule of Three module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_rule_of_three.R (SDD 4.2: "content is data, not
# hardcoded UI").

rule_of_three_content <- list(
  bound = list(
    title = "Upper Bound on an Unseen Event Rate (Rule of Three)",
    formula_latex = paste0(
      "$$\\text{exact: } U = 1 - \\alpha^{1/n} \\qquad ",
      "\\text{approx (}\\alpha=0.05\\text{): } U \\approx 3/n$$"
    ),
    explanation = paste(
      "If you observe *zero* events (e.g. adverse events) in n subjects,",
      "this calculator gives the upper confidence bound on the true event",
      "rate consistent with that observation -- \"absence of evidence isn't",
      "evidence of absence\", quantified. The exact bound solves",
      "P(zero events | true rate = U, n subjects) = alpha; for a 95% bound",
      "(alpha = 0.05) this is closely approximated by the well-known",
      "\"rule of three\": U ~ 3/n.",
      "",
      "- **n** - the number of subjects observed, with zero events seen.",
      "- **conf_level** - the confidence level for the bound, typically 0.95.",
      "",
      "This is a one-sided bound only (\"the true rate is unlikely to be",
      "higher than this\"), appropriate for safety monitoring where a study",
      "of modest size found no adverse events but can't rule out a",
      "meaningful underlying risk.",
      sep = "\n"
    ),
    worked_example = paste(
      "The classic illustration (Hanley & Lippman-Hand 1983): a trial",
      "enrolls n = 30 subjects and observes zero adverse events. This",
      "calculator returns an approximate upper 95% bound of 3/30 = 0.0999",
      "and an exact bound of 0.0950 -- i.e. a true adverse-event rate of up",
      "to about 10% cannot be ruled out, even though none were observed.",
      sep = "\n"
    ),
    citation = paste(
      "Hanley JA, Lippman-Hand A. If nothing goes wrong, is everything all",
      "right? Interpreting zero numerators. JAMA. 1983;249(13):1743-1745;",
      "Louis TA. Confidence intervals for a binomial parameter after",
      "observing no successes. Am Stat. 1981;35(3):154."
    ),
    backend = "closed-form (exact zero-events binomial bound + rule-of-three approximation)"
  ),

  n_required = list(
    title = "Sample Size to Detect at Least One Event",
    formula_latex = paste0(
      "$$n = \\left\\lceil \\frac{\\ln(\\alpha)}{\\ln(1-p)} \\right\\rceil \\qquad ",
      "\\text{approx (}\\alpha=0.05\\text{): } n \\approx 3/p$$"
    ),
    explanation = paste(
      "The complement of the bound above: given an assumed true event",
      "rate, how many subjects are needed for a target probability of",
      "observing *at least one* event -- useful for planning a",
      "surveillance or safety-monitoring sample so that a rare-but-",
      "important event isn't missed purely by bad luck.",
      "",
      "- **p** - the assumed true event rate (e.g. from a known background",
      "  incidence).",
      "- **conf_level** - the desired probability of observing at least one",
      "  event, typically 0.95.",
      sep = "\n"
    ),
    worked_example = paste(
      "For an assumed true event rate of 1% (p = 0.01), this calculator",
      "returns an exact n = 299 (and an approximate n = 300, i.e. the",
      "\"3/p\" rule) to have a 95% chance of observing at least one event.",
      sep = "\n"
    ),
    citation = paste(
      "Hanley JA, Lippman-Hand A. If nothing goes wrong, is everything all",
      "right? Interpreting zero numerators. JAMA. 1983;249(13):1743-1745."
    ),
    backend = "closed-form (exact zero-events binomial bound + rule-of-three approximation)"
  )
)
