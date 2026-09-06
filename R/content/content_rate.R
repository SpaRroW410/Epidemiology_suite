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
  ),

  poisson_regression = list(
    title = "Poisson Regression, Continuous Predictor",
    formula_latex = paste0(
      "$$\\log(\\mu_i) = \\beta_0 + \\beta_1 x_{1i}, \\quad x_1 \\sim N(\\mu_{x_1}, \\sigma^2_{x_1})$$",
      "$$n = \\phi\\frac{\\left(Z_{1-\\alpha/2}\\sqrt{V(b_1|\\beta_1=0)} + Z_{power}\\sqrt{V(b_1|\\beta_1=\\theta_1)}\\right)^2}",
      "{\\mu_T e^{\\beta_0}\\theta_1^2}$$"
    ),
    explanation = paste(
      "The \"Comparison of Two Incidence Rates\" design above covers",
      "Poisson regression with a single BINARY predictor (an exposed vs.",
      "unexposed group indicator); this covers the continuous-predictor",
      "case instead -- e.g. testing whether a continuous exposure or",
      "biomarker level (assumed normally distributed) is associated with",
      "an event rate.",
      "",
      "- **beta0** - the intercept (log scale) of the Poisson regression.",
      "- **beta1** - the slope (log rate ratio per unit increase in the",
      "  predictor) you want to detect; must differ from 0.",
      "- **Predictor mean / variance (mu.x1, sigma2.x1)** - the assumed",
      "  mean and variance of the (normally distributed) predictor.",
      "- **Mean exposure time (mu.T)** - the average follow-up/exposure",
      "  time per subject.",
      "- **Over-dispersion (phi)** - the ratio var(y)/mean(y); 1 means a",
      "  genuine Poisson distribution (no over-dispersion), values above 1",
      "  inflate the required sample size to compensate for extra-Poisson",
      "  variability often seen in real count data.",
      "- **alpha, power** - as elsewhere (two-sided test).",
      "",
      "Wraps `powerMediation::sizePoisson()` -- already a project",
      "dependency (used by the Logistic Regression module) -- which",
      "directly implements Signorini (1991)'s closed-form Wald-test",
      "sample-size formula for Poisson regression.",
      sep = "\n"
    ),
    worked_example = paste(
      "powerMediation's own documented example: beta0 = 0.1, beta1 = 0.5,",
      "predictor mean = 0 and variance = 1 (a standard normal predictor),",
      "mean exposure time = 1, no over-dispersion (phi = 1), alpha = 0.05",
      "(two-sided), 80% power. This calculator returns n = 28, matching",
      "the package's own worked answer exactly.",
      sep = "\n"
    ),
    citation = paste(
      "Signorini DF. Sample size for Poisson regression. Biometrika.",
      "1991;78(2):446-450."
    ),
    backend = "powerMediation::sizePoisson()"
  )
)
