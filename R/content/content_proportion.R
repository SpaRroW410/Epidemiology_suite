# Metadata for the Proportions module: formula text, plain-language explanation,
# worked example, and citation. Content is data, rendered generically by
# mod_proportion.R (SDD 4.2: "content is data, not hardcoded UI").

proportion_content <- list(
  single = list(
    title = "Single Proportion vs. a Known/Reference Value",
    formula_latex = paste0(
      "$$h = 2\\arcsin(\\sqrt{p_1}) - 2\\arcsin(\\sqrt{p_0})$$",
      "$$n = \\left(\\frac{Z_{1-\\alpha/2} + Z_{1-\\beta}}{h}\\right)^2$$"
    ),
    explanation = paste(
      "This calculator finds the sample size needed to detect a difference",
      "between an anticipated true proportion and a known or hypothesized",
      "reference proportion, using Cohen's arcsine-transformed effect size *h*.",
      "",
      "- **p0** - the known/reference proportion you are comparing against",
      "  (e.g. a published prevalence, or the null-hypothesis value).",
      "- **p1** - the proportion you expect to find in your study population.",
      "- **alpha** - the significance level (Type I error rate), typically 0.05.",
      "- **power** - the desired probability of detecting a true difference",
      "  (1 - Type II error rate), typically 0.8 or 0.9.",
      "",
      "The arcsine transformation stabilizes variance across the range of p,",
      "so *h* behaves like a standardized effect size (small ~0.2, medium ~0.5,",
      "large ~0.8, per Cohen's conventions).",
      sep = "\n"
    ),
    worked_example = paste(
      "Suppose national data suggest 20% prevalence of anemia (p0 = 0.20) in",
      "adolescent girls, and you expect your district to have a higher",
      "prevalence of 30% (p1 = 0.30). At alpha = 0.05 (two-sided) and 80% power,",
      "this calculator returns h ~ 0.2319 and a required sample size of n = 146.",
      sep = "\n"
    ),
    citation = paste(
      "Cohen J. Statistical Power Analysis for the Behavioral Sciences.",
      "2nd ed. Hillsdale, NJ: Lawrence Erlbaum Associates; 1988.",
      "(arcsine-transformed effect size h, and one-sample proportion power",
      "analysis, as implemented by pwr::pwr.p.test)."
    ),
    backend = "pwr::pwr.p.test (effect size via pwr::ES.h)"
  ),
  precision = list(
    title = "Single Proportion — Precision-Based (No Reference Value)",
    formula_latex = paste0(
      "$$n = \\frac{Z_{1-\\alpha/2}^2 \\, p(1-p)}{d^2}$$"
    ),
    explanation = paste(
      "This calculator finds the sample size needed to estimate a single",
      "proportion (e.g. a disease prevalence) to within a desired margin of",
      "error, when there is **no known reference value and no comparison",
      "group** -- you are simply estimating your own population's",
      "proportion as precisely as you choose. This is usually what is",
      "needed for a straightforward prevalence/frequency survey.",
      "",
      "- **p** - the expected proportion. If you have no prior estimate,",
      "  use 0.5 -- it maximizes p(1-p) and so gives the largest, safest",
      "  sample size.",
      "- **d** - the desired absolute precision (margin of error), e.g. 0.05",
      "  for a result reported as \"prevalence +/- 5 percentage points\".",
      "- **Confidence level** - typically 0.95 (95%), giving Z = 1.96.",
      "",
      "Unlike the *vs. known value* calculator above, this formula does not",
      "test a hypothesis or require a power target -- there is no effect",
      "size and no comparison, only an estimation precision target.",
      sep = "\n"
    ),
    worked_example = paste(
      "The best-known example: with no prior estimate (p = 0.5), a desired",
      "precision of d = 0.05, and 95% confidence (Z = 1.96), this calculator",
      "returns n = 385 -- the widely-quoted default sample size for a",
      "prevalence survey with no other information available.",
      sep = "\n"
    ),
    citation = paste(
      "Cochran WG. Sampling Techniques. 3rd ed. New York: John Wiley & Sons;",
      "1977. (original formula); Naing L, Winn T, Rusli BN. Practical issues",
      "in calculating the sample size for prevalence studies. Arch Orofac",
      "Sci. 2006;1:9-14. (applied to health prevalence studies)."
    ),
    backend = "Closed-form (Cochran's formula); no external package required"
  ),
  two_sample = list(
    title = "Two Independent Proportions",
    formula_latex = paste0(
      "$$h = 2\\arcsin(\\sqrt{p_1}) - 2\\arcsin(\\sqrt{p_2})$$",
      "$$n_{\\text{per group}} = \\left(\\frac{Z_{1-\\alpha/2} + Z_{1-\\beta}}{h}\\right)^2$$"
    ),
    explanation = paste(
      "This calculator finds the per-group sample size needed to detect a",
      "difference between two independent group proportions, assuming equal",
      "allocation (1:1) between groups, using Cohen's arcsine-transformed",
      "effect size *h*.",
      "",
      "- **p1** - the expected proportion in group 1.",
      "- **p2** - the expected proportion in group 2.",
      "- **alpha** - the significance level (Type I error rate), typically 0.05.",
      "- **power** - the desired probability of detecting a true difference",
      "  (1 - Type II error rate), typically 0.8 or 0.9.",
      "",
      "Total sample size is twice the per-group value (n1 = n2).",
      sep = "\n"
    ),
    worked_example = paste(
      "Suppose you expect 25% complication rates in a control group (p2 = 0.25)",
      "and want to detect a reduction to 10% in an intervention group",
      "(p1 = 0.10). At alpha = 0.05 (two-sided) and 80% power, this calculator",
      "returns |h| ~ 0.4037 and a required sample size of n = 97 per group",
      "(194 total).",
      sep = "\n"
    ),
    citation = paste(
      "Cohen J. Statistical Power Analysis for the Behavioral Sciences.",
      "2nd ed. Hillsdale, NJ: Lawrence Erlbaum Associates; 1988.",
      "(arcsine-transformed effect size h, and two-sample proportion power",
      "analysis, as implemented by pwr::pwr.2p.test)."
    ),
    backend = "pwr::pwr.2p.test (effect size via pwr::ES.h)"
  )
)
