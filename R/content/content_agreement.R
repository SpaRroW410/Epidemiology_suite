# Metadata for the Agreement/Reliability module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_agreement.R (SDD 4.2: "content is data, not hardcoded
# UI").

agreement_content <- list(
  kappa = list(
    title = "Cohen's Kappa - Categorical Agreement (No Gold Standard)",
    formula_latex = paste0(
      "$$\\kappa = \\frac{P_o - P_e}{1 - P_e}$$",
      "$$n \\text{ solved numerically so the } (1-\\alpha)\\text{ CI for } \\kappa ",
      "\\text{ has the desired width}$$"
    ),
    explanation = paste(
      "Use this when there is **no reference/gold-standard test** -- you",
      "just want to know how well two (or more) raters or methods agree",
      "when classifying subjects into categories (e.g. two radiologists",
      "independently reading a scan as normal/abnormal). Cohen's kappa",
      "measures agreement beyond what would be expected by chance alone;",
      "this calculator finds the sample size needed to estimate kappa to a",
      "desired confidence-interval width, given how you expect the",
      "categories to split.",
      "",
      "- **kappa** - the value of kappa you expect to find (0 = chance",
      "  agreement, 1 = perfect agreement; conventionally, <0.20 slight,",
      "  0.21-0.40 fair, 0.41-0.60 moderate, 0.61-0.80 substantial, >0.80",
      "  almost perfect).",
      "- **Categories** - the number of possible rating outcomes (2 for a",
      "  binary/present-absent rating, up to 5).",
      "- **Raters** - how many raters or methods are being compared (2-6).",
      "- **Category proportions** - the expected proportion of subjects",
      "  falling into each category (must sum to 1); this is analogous to",
      "  the *prevalence* input in the diagnostic-accuracy calculators.",
      "- **Desired CI width** - the full width of the confidence interval",
      "  you want for the estimated kappa, e.g. 0.2 for a result reported",
      "  as \"kappa = 0.6, 95% CI 0.5-0.7\".",
      "",
      "This is a precision-based design (like the *Single proportion -",
      "precision-based* calculator in the Proportions module) -- there is",
      "no hypothesis test and no power target, only an estimation-precision",
      "target.",
      sep = "\n"
    ),
    worked_example = paste(
      "Two clinicians independently classify patients as having (or not",
      "having) a condition, with no reference standard available. You",
      "expect moderate-to-substantial agreement (kappa = 0.6), and expect",
      "about 40% of patients to be classified as having the condition",
      "(props = 0.4, 0.6). For a 95% CI of width 0.2 (e.g. reported as",
      "\"kappa = 0.6, 95% CI 0.5-0.7\"), this calculator returns n = 211",
      "subjects.",
      sep = "\n"
    ),
    citation = paste(
      "Donner A, Eliasziw M. Sample size requirements for reliability",
      "studies. Stat Med. 1987;6(4):441-448. (original 2-rater, binary-",
      "outcome method); Rotondi MA, Donner A. A confidence interval",
      "approach to sample size estimation for interobserver agreement",
      "studies with multiple raters and outcomes. J Clin Epidemiol.",
      "2012;65(7):778-784. (extension to 3-6 raters and up to 5",
      "categories, as implemented in the kappaSize package)."
    ),
    backend = "presize::prec_kappa() (wraps kappaSize::CIBinary/CI3Cats/CI4Cats/CI5Cats)"
  ),

  icc = list(
    title = "Intraclass Correlation Coefficient (ICC) - Continuous Agreement (No Gold Standard)",
    formula_latex = paste0(
      "$$n = \\frac{8 Z_{1-\\alpha/2}^2 (1-\\rho)^2 (1+(k-1)\\rho)^2}{k(k-1)\\,w^2} + 1$$"
    ),
    explanation = paste(
      "Use this when there is **no reference/gold-standard measurement**",
      "and your outcome is continuous (not categorical) -- e.g. two",
      "instruments, or two raters, each measuring the same continuous",
      "quantity (blood pressure, a symptom score) on the same subjects.",
      "The intraclass correlation coefficient (ICC) measures how much of",
      "the total variance is due to real between-subject differences",
      "versus measurement/rater inconsistency.",
      "",
      "- **rho** - the ICC value you expect to find (0-1; conventionally,",
      "  <0.5 poor, 0.5-0.75 moderate, 0.75-0.9 good, >0.9 excellent",
      "  reliability).",
      "- **k** - the number of raters or repeated measurements taken on",
      "  each subject (>= 2).",
      "- **Desired CI width (w)** - the full width of the confidence",
      "  interval you want for the estimated ICC.",
      "",
      "Like the kappa calculator above, this is a precision-based design:",
      "no hypothesis test, no power target, just an estimation-precision",
      "target. The formula is an approximation that applies to both",
      "one-way and two-way ANOVA-based ICC estimators.",
      sep = "\n"
    ),
    worked_example = paste(
      "Two raters each measure the same continuous score on every",
      "subject. You expect good reliability (rho = 0.75), and want a 95%",
      "CI of width 0.2 for the estimated ICC. This calculator returns",
      "n = 79 subjects.",
      "",
      "(Bonett (2002)'s own published example: 4 raters, an expected ICC",
      "of 0.85, and a desired CI width of 0.2, needs n = 19.2 -- rounded",
      "up here to 20.)",
      sep = "\n"
    ),
    citation = paste(
      "Bonett DG. Sample size requirements for estimating intraclass",
      "correlations with desired precision. Stat Med. 2002;21(9):1331-",
      "1335."
    ),
    backend = "presize::prec_icc()"
  ),

  cronbach = list(
    title = "Cronbach's Alpha - Scale Internal Consistency",
    formula_latex = paste0(
      "$$n \\text{ solved so the } (1-\\alpha)\\text{ CI for Cronbach's alpha has the desired width (Bonett \\& Wright 2015)}$$"
    ),
    explanation = paste(
      "Use this when developing or validating a multi-item scale or",
      "questionnaire, and you want to estimate its internal consistency",
      "(how well the items \"hang together\") to a target precision.",
      "Cronbach's alpha is the most commonly reported reliability",
      "coefficient for this purpose.",
      "",
      "- **k** - the number of items/questions in the scale.",
      "- **calpha** - the Cronbach's alpha value you expect to find (0-1;",
      "  conventionally, >=0.7 acceptable, >=0.8 good, >=0.9 excellent",
      "  for a research scale).",
      "- **Desired CI width** - the full width of the confidence interval",
      "  you want for the estimated alpha.",
      "",
      "This is a precision-based design, same logic as the kappa/ICC",
      "calculators above: no hypothesis test, no power target, just an",
      "estimation-precision target.",
      sep = "\n"
    ),
    worked_example = paste(
      "presize's own documented example: a 5-item scale (k = 5) expected",
      "to have Cronbach's alpha = 0.7. For a 95% CI of width 0.1, this",
      "calculator returns n = 349 -- matching presize's own printed",
      "answer exactly.",
      sep = "\n"
    ),
    citation = paste(
      "Bonett DG, Wright TA. Cronbach's alpha reliability: Interval",
      "estimation, hypothesis testing, and sample size planning. J",
      "Organiz Behav. 2015;36(1):3-15."
    ),
    backend = "presize::prec_cronb()"
  ),

  bland_altman = list(
    title = "Bland-Altman Limits of Agreement",
    formula_latex = paste0(
      "$$n \\text{ solved so the CI for the limit of agreement has the desired width (SD-units)}$$"
    ),
    explanation = paste(
      "Use this when comparing two measurement methods on a continuous",
      "scale (e.g. a new device vs. a reference device) via a",
      "Bland-Altman plot, and you want to know how many subjects are",
      "needed to estimate the *limits of agreement* (the range within",
      "which most differences between the two methods are expected to",
      "fall) to a target precision.",
      "",
      "- **Desired CI width** - the full width of the confidence interval",
      "  for the limit of agreement, expressed in SD-units of the paired",
      "  differences (not the original measurement units) -- e.g. 1 means",
      "  the CI around the limit of agreement spans +/-0.5 SD.",
      "- **Confidence level** - typically 0.95.",
      "",
      "Unlike the mean-difference precision calculators elsewhere in this",
      "app, this targets the precision of the *limit of agreement itself*",
      "-- the number that actually gets reported and interpreted on a",
      "Bland-Altman plot.",
      sep = "\n"
    ),
    worked_example = paste(
      "Worked from presize's own formula: wanting a 95% CI of width 1",
      "SD-unit around the limit of agreement, this calculator returns",
      "n = 47 subjects. (For a much tighter width of 0.1 SD-units,",
      "presize's own documented example returns n = 4610 -- illustrating",
      "how sharply required n grows as the desired precision tightens.)",
      sep = "\n"
    ),
    citation = paste(
      "Bland JM, Altman DG. Statistical methods for assessing agreement",
      "between two methods of clinical measurement. Lancet.",
      "1986;327(8476):307-310."
    ),
    backend = "presize::prec_lim_agree()"
  )
)
