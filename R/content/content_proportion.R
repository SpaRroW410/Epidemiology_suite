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
    title = "Single Proportion -- Precision-Based (No Reference Value)",
    formula_latex = paste0(
      "$$n_0 = \\frac{Z_{1-\\alpha/2}^2 \\, p(1-p)}{d^2}$$",
      "$$n = \\frac{n_0}{1 + \\dfrac{n_0 - 1}{N}} \\quad \\text{(finite population correction, if } N \\text{ known)}$$"
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
      "- **N (optional)** - the total size of the finite population you are",
      "  sampling from (e.g. total students in one college, total",
      "  households in one village). If provided, the finite population",
      "  correction (FPC) reduces the required sample size, since sampling",
      "  a larger fraction of a small population yields proportionally more",
      "  information. Leave blank for a community-level survey where the",
      "  population is effectively unlimited relative to the sample.",
      "",
      "Unlike the *vs. known value* calculator above, this formula does not",
      "test a hypothesis or require a power target -- there is no effect",
      "size and no comparison, only an estimation precision target.",
      sep = "\n"
    ),
    worked_example = paste(
      "The best-known example: with no prior estimate (p = 0.5), a desired",
      "precision of d = 0.05, and 95% confidence (Z = 1.96), this calculator",
      "returns n0 = 385 -- the widely-quoted default sample size for a",
      "prevalence survey with no other information available.",
      "",
      "Now suppose that survey is actually confined to a single college with",
      "N = 1000 eligible students. Applying the finite population correction",
      "to the same n0 = 385 gives an adjusted n = 278 -- fewer subjects",
      "needed, because 385 would already have been over a third of the",
      "entire population.",
      sep = "\n"
    ),
    citation = paste(
      "Cochran WG. Sampling Techniques. 3rd ed. New York: John Wiley & Sons;",
      "1977. (original formula and finite population correction);",
      "Naing L, Winn T, Rusli BN. Practical issues in calculating the",
      "sample size for prevalence studies. Arch Orofac Sci. 2006;1:9-14.",
      "(applied to health prevalence studies)."
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
  ),

  posthoc_pairwise = list(
    title = "Post-Hoc Pairwise Comparison (Bonferroni-Adjusted)",
    formula_latex = paste0(
      "$$n_{ij} = \\frac{\\left(Z_{1-\\alpha/(2\\tau)} + Z_{1-\\beta}\\right)^2 ",
      "\\left(p_i(1-p_i) + p_j(1-p_j)\\right)}{(p_i - p_j)^2}$$"
    ),
    explanation = paste(
      "The proportions counterpart of the Means module's \"Post-Hoc",
      "Pairwise Comparison\" design -- use this to size ONE specific",
      "pairwise comparison of two group proportions out of several",
      "planned comparisons across a multi-group study, correcting the",
      "significance level for running multiple tests at once",
      "(Bonferroni's method).",
      "",
      "- **tau** - the total number of pairwise comparisons planned",
      "  across the whole study (not just this one pair); e.g. for all",
      "  pairs among k groups, tau = k(k-1)/2.",
      "- **p1, p2** - the expected proportions for the two groups in this",
      "  specific pair.",
      "- **alpha** - the overall (family-wise) significance level; the",
      "  calculator internally uses alpha/tau for this pair's test.",
      "- **power** - the desired power for detecting this pair's",
      "  difference.",
      sep = "\n"
    ),
    worked_example = paste(
      "Chow, Shao & Wang (2003)'s own worked examples (Example 4.4.2):",
      "with tau = 2 planned pairwise comparisons, comparing p1 = 0.2",
      "against p2 = 0.4 at alpha = 0.05 and 80% power, this calculator",
      "returns n = 96 per group; comparing p1 = 0.2 against p2 = 0.5",
      "under the same tau, alpha and power returns n = 44 per group --",
      "both reproducing TrialSize::OneWayANOVA.PairwiseComparison()'s own",
      "output exactly (independently re-derived and cross-checked by",
      "hand, since that function's Rd file doesn't print a numeric",
      "answer for either example).",
      sep = "\n"
    ),
    citation = paste(
      "Chow SC, Shao J, Wang H. Sample Size Calculations in Clinical",
      "Research. New York: Marcel Dekker; 2003. Section 4.4.2."
    ),
    backend = "TrialSize::OneWayANOVA.PairwiseComparison()"
  )
)
