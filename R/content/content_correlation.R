# Metadata for the Correlation module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_correlation.R (SDD 4.2: "content is data, not
# hardcoded UI").

correlation_content <- list(
  pearson = list(
    title = "Pearson Correlation Coefficient",
    formula_latex = paste0(
      "$$Z' = \\text{arctanh}(r) = \\frac{1}{2}\\ln\\!\\left(\\frac{1+r}{1-r}\\right)$$",
      "$$n = \\left(\\frac{Z_{1-\\alpha/2} + Z_{1-\\beta}}{Z'}\\right)^2 + 3$$"
    ),
    explanation = paste(
      "This calculator finds the sample size needed to detect a Pearson",
      "correlation coefficient of a given size between two continuous",
      "variables, using Fisher's z' (arctanh) transformation to",
      "approximate the sampling distribution of r.",
      "",
      "- **r** - the correlation coefficient you expect to find/detect",
      "  (conventionally, |r| ~0.1 small, ~0.3 medium, ~0.5 large, per",
      "  Cohen's conventions).",
      "- **alpha** - the significance level (Type I error rate), typically",
      "  0.05.",
      "- **power** - the desired probability of detecting a true",
      "  correlation (1 - Type II error rate), typically 0.8 or 0.9.",
      "- **Alternative hypothesis** - two-sided by default; use",
      "  one-sided only if you have a directional hypothesis (e.g. \"the",
      "  correlation is positive\").",
      "",
      "The Pearson correlation assumes the two variables are bivariate",
      "normal; if that assumption is doubtful, a rank-based coefficient",
      "may be more appropriate -- see the Nonparametric Tests module's",
      "Kendall's tau design.",
      sep = "\n"
    ),
    worked_example = paste(
      "Cohen (1988)'s conventional medium effect size: to detect a",
      "correlation of r = 0.3 at alpha = 0.05 (two-sided) with 80% power,",
      "this calculator returns n = 85 -- one of the most frequently",
      "quoted sample-size figures in the behavioral and health sciences",
      "literature.",
      sep = "\n"
    ),
    citation = paste(
      "Cohen J. Statistical Power Analysis for the Behavioral Sciences.",
      "2nd ed. Hillsdale, NJ: Lawrence Erlbaum Associates; 1988.",
      "(Fisher z' transformation and correlation power analysis, as",
      "implemented by pwr::pwr.r.test)."
    ),
    backend = "pwr::pwr.r.test()"
  ),

  two_independent = list(
    title = "Compare Two Independent Pearson Correlations",
    formula_latex = paste0(
      "$$q = \\left|\\,\\text{arctanh}(r_1) - \\text{arctanh}(r_2)\\,\\right|$$",
      "$$n_{\\text{per group}} = \\left(\\frac{Z_{1-\\alpha/2} + Z_{1-\\beta}}{q}\\right)^2 + 3$$"
    ),
    explanation = paste(
      "Use this to test whether the strength of a correlation between",
      "two variables differs between two independent groups (e.g. does",
      "a screening test correlate more strongly with the reference",
      "standard in one population than another?), rather than testing",
      "one correlation against zero.",
      "",
      "- **r1, r2** - the correlation coefficients you expect in each",
      "  group; they must differ, since the test detects a difference",
      "  between them.",
      "- **alpha, power, Alternative hypothesis** - as elsewhere.",
      "",
      "Cohen's q (the difference between the two Fisher z'-transformed",
      "correlations) plays the same effect-size role here that d plays",
      "for two means, or h for two proportions -- conventionally, q ~0.1",
      "small, ~0.3 medium, ~0.5 large. No dedicated `pwr` function covers",
      "this two-sample case (only the single-correlation-vs-zero test",
      "does), so this reimplements Cohen's own closed-form formula",
      "directly.",
      sep = "\n"
    ),
    worked_example = paste(
      "UCLA OARC's own G*Power worked example: comparing an established",
      "chemical-detection test (r1 = 0.89) against a cheaper new test",
      "(r2 = 0.76) using independent soil samples, two-sided alpha =",
      "0.05. At 90% power, this calculator returns n = 61 per group,",
      "matching the published table exactly; at 80% and 70% power the",
      "published table shows n = 46 and n = 37 (rounded to the nearest",
      "integer), while this calculator -- consistent with every other",
      "calculator in this app -- rounds UP to guarantee the target power",
      "is met, returning n = 47 and n = 38 respectively.",
      sep = "\n"
    ),
    citation = paste(
      "Cohen J. Statistical Power Analysis for the Behavioral Sciences.",
      "2nd ed. Hillsdale, NJ: Lawrence Erlbaum Associates; 1988. Worked",
      "example: UCLA Office of Advanced Research Computing, \"G*Power",
      "Data Analysis Examples: Power Analysis for Correlations\"",
      "(Correlations: Two independent Pearson r's)."
    ),
    backend = "closed-form (Cohen 1988)"
  )
)
