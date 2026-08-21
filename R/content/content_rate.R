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
  ),

  comparison = list(
    title = "Comparison of Two Incidence Rates",
    formula_latex = paste0(
      "$$\\log(\\lambda) = \\beta_0 + \\beta_1 x, \\quad x \\sim \\text{Bernoulli}(B)$$",
      "$$n \\text{ solved from a Wald-test power equation (Demidenko 2007)}$$"
    ),
    explanation = paste(
      "Comparing two groups' incidence rates via person-time is",
      "algebraically a Poisson regression with one Bernoulli-distributed",
      "predictor (the group indicator) -- this calculator uses Demidenko",
      "(2007)'s Wald-test power formula for that one-predictor case.",
      "",
      "- **rate_ref** - the expected rate in the reference (unexposed)",
      "  group, in events per unit person-time.",
      "- **rate_ratio** - the rate ratio you expect (exposed group's rate",
      "  divided by the reference group's rate); must differ from 1.",
      "- **prop_exposed** - the proportion of the total sample in the",
      "  exposed group (0.5 = equal allocation).",
      "- **alpha, power** - as elsewhere.",
      "",
      "This is implemented as a direct closed-form calculation (matching",
      "the WebPower package's own `wp.poisson(family = \"Bernoulli\")`",
      "formula exactly) rather than depending on WebPower itself, whose",
      "package-level dependencies (lme4, lavaan, dplyr, PearsonDS) are far",
      "heavier than this one formula needs.",
      sep = "\n"
    ),
    worked_example = paste(
      "WebPower's own documented example: a reference rate of 2.798 events",
      "per unit person-time, an expected rate ratio of 0.8938, with 53% of",
      "the sample in the exposed group. At alpha = 0.05 (two-sided) and 80%",
      "power, this calculator returns n_total = 944 (501 exposed, 443",
      "reference) -- matching WebPower's own printed n = 943.26 (ceiling",
      "944) exactly.",
      sep = "\n"
    ),
    citation = paste(
      "Demidenko E. Sample size determination for logistic regression",
      "revisited. Stat Med. 2007;26(18):3385-97. (Wald-test power formula",
      "this calculator implements); Zhang Z, Yuan KH. Practical",
      "Statistical Power Analysis Using WebPower and R. ISDSA Press;",
      "2018. (parameterization/worked example this was verified against)."
    ),
    backend = "Closed-form (Demidenko 2007's Poisson-regression Wald-test formula, as documented by WebPower::wp.poisson); no external package required"
  )
)
