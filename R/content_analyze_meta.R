# Metadata for the Analyze: Meta-Analysis module: formula text, plain-language explanation, worked example and citation, rendered
# generically by mod_analyze_meta.R. Content is data, not hard-coded UI. Methods and checks: see R/calc_analyze_meta.R.

.meta_citation <- paste(
  "Inverse-variance pooling with the DerSimonian-Laird between-study variance, as implemented in the metafor package (Viechtbauer W.",
  "Conducting meta-analyses in R with the metafor package. J Stat Softw. 2010;36(3):1-48), against which this calculator is checked.",
  "On the choice of estimator: Veroniki AA, Jackson D, Viechtbauer W, et al. Methods to estimate the between-study variance and its",
  "uncertainty in meta-analysis. Res Synth Methods. 2016;7(1):55-79. doi:10.1002/jrsm.1164."
)

.meta_formula <- paste0(
  "$$\\hat\\theta_F = \\frac{\\sum w_i y_i}{\\sum w_i}, \\quad w_i = \\frac{1}{v_i} \\qquad ",
  "Q = \\sum w_i (y_i - \\hat\\theta_F)^2 \\qquad I^2 = \\max\\left(0, \\frac{Q - (k-1)}{Q}\\right)$$",
  "$$\\hat\\tau^2 = \\max\\left(0, \\frac{Q - (k-1)}{\\sum w_i - \\sum w_i^2 / \\sum w_i}\\right) \\qquad ",
  "\\hat\\theta_R = \\frac{\\sum w_i^* y_i}{\\sum w_i^*}, \\quad w_i^* = \\frac{1}{v_i + \\hat\\tau^2} \\qquad ",
  "SE = \\frac{1}{\\sqrt{\\sum w}}$$"
)

.meta_common_help <- paste(
  "**How to enter the studies.** One study per line: *label, estimate, lower limit, upper limit* (the confidence interval as",
  "published), or *label, estimate, standard error*. Separate the figures with commas. The label can be left out.",
  "",
  "**What you get.**",
  "",
  "- **Fixed-effect estimate** - assumes every study estimates the same true effect; studies are weighted by their precision.",
  "- **Random-effects estimate** - allows the true effect to differ between studies (variance tau-squared, estimated by the",
  "  DerSimonian-Laird method); small studies get relatively more weight and the interval is wider. With no heterogeneity the two",
  "  estimates are the same.",
  "- **Q and its p-value** - a test of whether the studies differ more than chance allows. It has little power with few studies,",
  "  so a non-significant Q does not show the studies agree.",
  "- **I-squared** - the percentage of the variation between the study estimates that is beyond chance.",
  "- **Forest plot** - each study with its interval, and the two pooled estimates.",
  "",
  "**Cautions.** The DerSimonian-Laird method is the most widely used, but it can underestimate the between-study variance and",
  "so give too narrow an interval, especially with few studies or large heterogeneity (Veroniki et al. 2016). With fewer than about",
  "five studies treat the random-effects interval as optimistic. Pooling does not correct bias in the studies or publication",
  "bias, and studies that differ in design or population may not be worth pooling at all.",
  "",
  "Not covered: pooling from raw 2x2 counts (Mantel-Haenszel or Peto), other variance estimators (REML, Paule-Mandel), the",
  "Hartung-Knapp interval, prediction intervals, subgroup analysis and meta-regression, and funnel plots. Use a full",
  "meta-analysis package for a review you will publish; this tool is for a quick, transparent pooled estimate.",
  sep = "\n"
)

analyze_meta_content <- list(
  ratio = list(
    title = "Meta-analysis of ratios (odds ratio, risk ratio, hazard ratio)",
    formula_latex = .meta_formula,
    explanation = paste(
      "Use this to **pool the results of several studies** when each reports a ratio (odds ratio, risk ratio, rate ratio or hazard",
      "ratio) with its confidence interval. Ratios are pooled on the log scale: y is the log of each ratio and its variance v is",
      "recovered from the interval, SE = (ln upper - ln lower) / (2 x 1.96) for a 95% interval. The pooled result is turned back",
      "into a ratio. Pool only ratios of the same kind.",
      "",
      .meta_common_help,
      sep = "\n"
    ),
    worked_example = paste(
      "Four studies report risk ratios (95% CI): 0.75 (0.55-1.02), 0.90 (0.70-1.16), 0.62 (0.40-0.96) and 1.05 (0.80-1.38).",
      "Fixed-effect: **0.865 (0.745-1.004)**, p = 0.057. Q = 5.08 on 3 degrees of freedom (p = 0.17), I-squared = 40.9%,",
      "tau-squared = 0.0168. Random-effects: **0.848 (0.695-1.036)**, p = 0.11. The fixed-effect weights are 23.4%, 35.0%, 11.6% and",
      "30.0%; the random-effects weights 24.9%, 31.0%, 15.5% and 28.6% (the smallest study gains weight).",
      sep = "\n"
    ),
    citation = .meta_citation,
    backend = "closed-form (inverse variance; DerSimonian-Laird), checked against metafor::rma()"
  ),
  difference = list(
    title = "Meta-analysis of differences (mean difference, risk difference)",
    formula_latex = .meta_formula,
    explanation = paste(
      "Use this to **pool the results of several studies** when each reports a difference (a mean difference, a standardised mean",
      "difference, a risk difference, or any estimate with a roughly normal sampling distribution) with its confidence interval or",
      "standard error. The estimates are pooled as they are; from an interval, SE = (upper - lower) / (2 x 1.96) for a 95% interval.",
      "",
      .meta_common_help,
      sep = "\n"
    ),
    worked_example = paste(
      "Three trials report mean differences in systolic blood pressure (SE): -2.1 (0.9), -0.8 (0.7) and -3.0 (1.2) mmHg.",
      "Fixed-effect: **-1.59 (-2.57 to -0.61)**. I-squared = 32.8%. Random-effects: **-1.71 (-2.95 to -0.47)**.",
      sep = "\n"
    ),
    citation = .meta_citation,
    backend = "closed-form (inverse variance; DerSimonian-Laird), checked against metafor::rma()"
  )
)
