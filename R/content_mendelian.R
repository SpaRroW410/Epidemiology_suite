# Metadata for the Mendelian Randomisation module: formula text, plain-language explanation, worked example and citation, rendered
# generically by mod_mendelian.R. Content is data, not hard-coded UI. Source read in full: Burgess 2014 (see R/calc_mendelian.R).

.mr_citation <- paste(
  "Burgess S. Sample size and power calculations in Mendelian randomization with a single instrumental variable and a binary outcome.",
  "Int J Epidemiol. 2014;43(3):922-929. doi:10.1093/ije/dyu005 (equations 4 to 6 for a continuous outcome, 9 to 12 for a binary",
  "outcome; validation simulation in its Table 1)."
)

.mr_common_help <- paste(
  "- **R-squared** - the proportion of the variance of the exposure that the genetic instrument explains (the squared correlation",
  "  between instrument and exposure; the R-squared of the regression of the exposure on the variant or allele score). Take it from",
  "  a published genome-wide association study of the exposure or from your own data. Genetic instruments usually explain little",
  "  (often 1 to 5%), which is why these studies need large samples.",
  "- **alpha** - two-sided significance level. The power is that of finding an effect in the direction of the true effect.",
  "",
  "**Be conservative.** The sample size is inversely proportional to R-squared, so a small error in it changes the answer a lot:",
  "the source advises a conservative R-squared, or trying a range of values (the curve below the result shows this). The formula",
  "assumes the instrument is valid and the estimate approximately normal, and it ignores the uncertainty in the instrument's",
  "association with the exposure; with a weak instrument it is optimistic. When the exposure and outcome share confounders the",
  "formula was slightly optimistic in the source's simulations (under 2 percentage points on average).",
  "",
  "**One instrument.** The formulas are for a single instrument: one variant, or several variants combined into one allele score.",
  "",
  "Not covered: several instruments analysed separately, two-sample designs where the two samples differ in size, and whether the",
  "instrument is valid (no pleiotropy, no population stratification): see the design card in the guide.",
  sep = "\n"
)

mendelian_content <- list(
  continuous = list(
    title = "Mendelian randomisation, continuous outcome (single instrument)",
    formula_latex = paste0(
      "$$n = \\frac{\\left(z_{1-\\alpha/2} + z_{power}\\right)^2}{\\beta_1^2\\,\\rho^2_{GX}}$$",
      "$$\\text{power} = \\Phi\\left(\\beta_1\\,\\rho_{GX}\\sqrt{N} - z_{1-\\alpha/2}\\right)$$"
    ),
    explanation = paste(
      "Use this to plan a **Mendelian randomisation** study with a **measured (continuous) outcome**, such as blood pressure: genetic",
      "variants stand in for the exposure, and the causal effect of the exposure on the outcome is estimated by the ratio (Wald)",
      "method, which for one instrument equals two-stage least squares.",
      "",
      "- **beta1** - the causal effect you want to detect: the change in the outcome, in standard deviations, per standard deviation",
      "  increase in the exposure. (0.2 means the outcome rises by a fifth of its SD for each SD of the exposure.)",
      .mr_common_help,
      "",
      "The sample size is that of an ordinary regression of the outcome on the exposure divided by R-squared: an instrument that",
      "explains 2% of the exposure needs 50 times the sample.",
      sep = "\n"
    ),
    worked_example = paste(
      "Detect an effect of beta1 = 0.2 SD of the outcome per SD of the exposure with an allele score that explains 2% of the",
      "exposure (R-squared = 0.02), at 5% significance and 80% power: n = (1.960 + 0.842)^2 / (0.2^2 x 0.02) = 7.849 / 0.0008 =",
      "9811.1, so **9812 participants**. With 5000 participants the power would be Phi(0.2 x sqrt(0.02) x sqrt(5000) - 1.960) =",
      "Phi(0.040) = 0.516.",
      sep = "\n"
    ),
    citation = .mr_citation,
    backend = "closed-form (Burgess 2014, equations 4-6, with var(R_Y) = var(X) = 1)"
  ),
  binary = list(
    title = "Mendelian randomisation, binary outcome (single instrument)",
    formula_latex = paste0(
      "$$N = \\frac{\\left(z_{1-\\alpha/2} + z_{power}\\right)^2}{\\beta_1^2\\,\\rho^2_{GX}\\,P(Y=1)\\,P(Y=0)} \\qquad \\beta_1 = \\ln(OR)$$",
      "$$\\text{power} = \\Phi\\left(\\beta_1\\,\\rho_{GX}\\sqrt{N\\,P(Y=1)\\,P(Y=0)} - z_{1-\\alpha/2}\\right)$$"
    ),
    explanation = paste(
      "Use this to plan a **Mendelian randomisation** study with a **yes/no outcome**, such as a disease, typically from a",
      "case-control sample: genetic variants stand in for the exposure, and the causal odds ratio is estimated by the ratio (Wald)",
      "method with a logistic regression of the outcome on the instrument.",
      "",
      "- **OR** - the causal odds ratio of the outcome per standard deviation increase in the exposure that you want to detect",
      "  (beta1 is its natural logarithm).",
      "- **Controls per case** - 1 for equal numbers. P(Y=1) in the formula is the share of cases in the sample, 1 / (1 + controls",
      "  per case). For a fixed total, equal numbers of cases and controls give the most power.",
      .mr_common_help,
      "",
      "A yes/no outcome carries less information than a measured one, so the numbers are much larger than for a continuous outcome.",
      "The source prints the formula for 5% significance and 80% power (the constant 7.848); other levels use the same variance with",
      "the corresponding normal quantiles.",
      sep = "\n"
    ),
    worked_example = paste(
      "Detect an odds ratio of exp(0.2) = 1.22 per SD of the exposure with an instrument that explains 2% of the exposure, equal",
      "numbers of cases and controls, 5% significance and 80% power: N = 7.849 / (0.2^2 x 0.02 x 0.5 x 0.5) = 39 244.4, so",
      "**19 623 cases and 19 623 controls**. This agrees with the source's validation table: 20 000 cases and 20 000 controls give",
      "80.7% power by the formula and 80.2% in its simulation. With two controls per case and an odds ratio of 1.5 at R-squared =",
      "0.03, 2388 cases and 4776 controls are needed.",
      sep = "\n"
    ),
    citation = .mr_citation,
    backend = "closed-form (Burgess 2014, equations 9-12)"
  )
)
