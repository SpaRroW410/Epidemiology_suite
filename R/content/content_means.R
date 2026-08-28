# Metadata for the Means module: formula text, plain-language explanation,
# worked example, and citation. Content is data, rendered generically by
# mod_means.R (SDD 4.2: "content is data, not hardcoded UI").

means_content <- list(
  single = list(
    title = "Single Mean vs. a Known/Reference Value",
    formula_latex = paste0(
      "$$d = \\frac{\\mu_1 - \\mu_0}{\\sigma}$$",
      "$$n = \\left(\\frac{Z_{1-\\alpha/2} + Z_{1-\\beta}}{d}\\right)^2 \\quad \\text{(one-sample t-test, approx.)}$$"
    ),
    explanation = paste(
      "This calculator finds the sample size needed to detect a difference",
      "between an anticipated true mean and a known or hypothesized",
      "reference mean, using a one-sample t-test and Cohen's standardized",
      "effect size *d*.",
      "",
      "- **mu0** - the known/reference mean you are comparing against (e.g.",
      "  a published normative value, or the null-hypothesis value).",
      "- **mu1** - the mean you expect to find in your study population.",
      "- **sd** - the expected standard deviation of the measurement.",
      "- **alpha** - the significance level (Type I error rate), typically 0.05.",
      "- **power** - the desired probability of detecting a true difference",
      "  (1 - Type II error rate), typically 0.8 or 0.9.",
      "",
      "d = (mu1 - mu0) / sd standardizes the expected difference in units of",
      "the standard deviation (small ~0.2, medium ~0.5, large ~0.8, per",
      "Cohen's conventions).",
      sep = "\n"
    ),
    worked_example = paste(
      "Suppose the national reference mean systolic BP for a population is",
      "120 mmHg (mu0 = 120), and you expect your study population to average",
      "125 mmHg (mu1 = 125) with SD = 15 mmHg. At alpha = 0.05 (two-sided)",
      "and 80% power, this calculator returns d ~ 0.3333 and a required",
      "sample size of n = 73.",
      sep = "\n"
    ),
    citation = paste(
      "Cohen J. Statistical Power Analysis for the Behavioral Sciences.",
      "2nd ed. Hillsdale, NJ: Lawrence Erlbaum Associates; 1988.",
      "(standardized effect size d, and one-sample t-test power analysis,",
      "as implemented by pwr::pwr.t.test)."
    ),
    backend = "pwr::pwr.t.test(type = \"one.sample\")"
  ),
  two_sample = list(
    title = "Two Independent Means",
    formula_latex = paste0(
      "$$d = \\frac{\\mu_1 - \\mu_2}{\\sigma}$$",
      "$$n_{\\text{per group}} = \\left(\\frac{Z_{1-\\alpha/2} + Z_{1-\\beta}}{d}\\right)^2 \\times 2 \\quad \\text{(two-sample t-test, approx.)}$$"
    ),
    explanation = paste(
      "This calculator finds the per-group sample size needed to detect a",
      "difference between two independent groups' means, assuming equal",
      "allocation (1:1) and a common/pooled standard deviation, using a",
      "two-sample (independent) t-test and Cohen's standardized effect",
      "size *d*.",
      "",
      "- **mu1** - the expected mean in group 1.",
      "- **mu2** - the expected mean in group 2.",
      "- **sd** - the common/pooled standard deviation shared by both groups.",
      "- **alpha** - the significance level (Type I error rate), typically 0.05.",
      "- **power** - the desired probability of detecting a true difference",
      "  (1 - Type II error rate), typically 0.8 or 0.9.",
      "",
      "Total sample size is twice the per-group value (n1 = n2).",
      sep = "\n"
    ),
    worked_example = paste(
      "Suppose you expect a mean hemoglobin of 11.5 g/dL in a control group",
      "(mu2 = 11.5) and 12.5 g/dL in an intervention group (mu1 = 12.5),",
      "with a common SD = 2.0 g/dL. At alpha = 0.05 (two-sided) and 80%",
      "power, this calculator returns d = 0.5 and a required sample size of",
      "n = 64 per group (128 total).",
      sep = "\n"
    ),
    citation = paste(
      "Cohen J. Statistical Power Analysis for the Behavioral Sciences.",
      "2nd ed. Hillsdale, NJ: Lawrence Erlbaum Associates; 1988.",
      "(standardized effect size d, and two-sample t-test power analysis,",
      "as implemented by pwr::pwr.t.test)."
    ),
    backend = "pwr::pwr.t.test(type = \"two.sample\")"
  ),
  paired = list(
    title = "Two Paired Means (e.g. Before-After, Matched Pairs)",
    formula_latex = paste0(
      "$$d = \\frac{\\bar{\\Delta}}{\\sigma_\\Delta}$$",
      "$$n = \\left(\\frac{Z_{1-\\alpha/2} + Z_{1-\\beta}}{d}\\right)^2 \\quad \\text{(paired t-test, approx.)}$$"
    ),
    explanation = paste(
      "This calculator finds the number of pairs (e.g. subjects measured",
      "before and after, or matched pairs) needed to detect a change in",
      "mean within the same subjects, using a paired t-test on the",
      "within-pair differences and Cohen's standardized effect size *d*.",
      "",
      "- **mean_diff** - the expected mean of the paired differences (e.g.",
      "  mean weight change from before to after).",
      "- **sd_diff** - the standard deviation *of the paired differences*",
      "  themselves, not of either measurement occasion alone -- this is",
      "  usually smaller than the SD of a single measurement, since paired",
      "  designs remove between-subject variability.",
      "- **alpha** - the significance level (Type I error rate), typically 0.05.",
      "- **power** - the desired probability of detecting a true difference",
      "  (1 - Type II error rate), typically 0.8 or 0.9.",
      sep = "\n"
    ),
    worked_example = paste(
      "Suppose a weight-loss intervention is expected to produce a mean",
      "change of 2 kg (mean_diff = 2), with a standard deviation of the",
      "individual changes of 5 kg (sd_diff = 5). At alpha = 0.05 (two-sided)",
      "and 80% power, this calculator returns d = 0.4 and a required sample",
      "size of n = 52 pairs.",
      sep = "\n"
    ),
    citation = paste(
      "Cohen J. Statistical Power Analysis for the Behavioral Sciences.",
      "2nd ed. Hillsdale, NJ: Lawrence Erlbaum Associates; 1988.",
      "(standardized effect size d, and paired t-test power analysis, as",
      "implemented by pwr::pwr.t.test)."
    ),
    backend = "pwr::pwr.t.test(type = \"paired\")"
  ),

  anova = list(
    title = "Three or More Independent Groups (One-Way ANOVA)",
    formula_latex = paste0(
      "$$f = \\frac{\\sigma_m}{\\sigma}, \\quad ",
      "\\sigma_m = \\sqrt{\\frac{1}{k}\\sum_{i=1}^{k}(\\mu_i - \\bar\\mu)^2}$$",
      "$$n_{\\text{per group}} = \\text{solved from } f, k, \\alpha, \\text{power (Cohen 1988)}$$"
    ),
    explanation = paste(
      "This calculator finds the per-group sample size needed to detect",
      "*any* difference among three or more independent group means",
      "(a one-way, between-subjects ANOVA design), using Cohen's",
      "standardized effect size *f*.",
      "",
      "- **Group means** - the mean you expect in each of the k groups",
      "  (k >= 3).",
      "- **sd** - the common/pooled standard deviation shared by all",
      "  groups.",
      "- **alpha, power** - as elsewhere.",
      "",
      "f is the population standard deviation of the k group means,",
      "divided by the common SD (small ~0.10, medium ~0.25, large ~0.40,",
      "per Cohen's conventions). This omnibus test only tells you *some*",
      "pair of groups differs, not *which* pair -- see the \"Planned",
      "linear contrast\" design below for testing one specific",
      "pre-specified comparison instead, or \"Post-hoc pairwise",
      "comparison\" for a multiplicity-adjusted comparison of two",
      "specific groups after the fact.",
      sep = "\n"
    ),
    worked_example = paste(
      "Cohen (1988)'s own example (Exercise 8.10, p. 391): with a medium",
      "conventional effect size (f = 0.28) and k = 4 groups, at alpha =",
      "0.05 and 80% power, this calculator returns n = 36 per group (144",
      "total).",
      "",
      "Worked from raw values: suppose you expect three group means of 9,",
      "10, and 11 with a common SD of 4. That implies f ~ 0.204, and at",
      "alpha = 0.05 and 80% power, a required sample size of n = 79 per",
      "group (237 total).",
      sep = "\n"
    ),
    citation = paste(
      "Cohen J. Statistical Power Analysis for the Behavioral Sciences.",
      "2nd ed. Hillsdale, NJ: Lawrence Erlbaum Associates; 1988.",
      "(standardized effect size f, and one-way ANOVA power analysis, as",
      "implemented by pwr::pwr.anova.test)."
    ),
    backend = "pwr::pwr.anova.test()"
  ),

  planned_contrast = list(
    title = "Planned Linear Contrast Among k Group Means",
    formula_latex = paste0(
      "$$H_0: L(\\mu) = \\sum_{i=1}^{k} c_i \\mu_i = 0 \\quad \\text{vs.} \\quad ",
      "H_1: L(\\mu) = \\epsilon \\ne 0, \\quad \\sum_{i=1}^{k} c_i = 0$$",
      "$$n = \\frac{(Z_{1-\\alpha}+Z_{1-\\beta})^2 \\sigma^2 \\sum_i c_i^2/f_i}{\\epsilon^2}$$"
    ),
    explanation = paste(
      "Use this when you have a *specific, pre-specified* (\"planned\")",
      "comparison in mind across three or more groups -- e.g. a linear",
      "dose-response trend across ordered dose levels, or any other a",
      "priori weighted combination of group means -- rather than the",
      "one-way ANOVA design's *omnibus* question of whether any groups",
      "differ at all. Because the comparison is specified in advance,",
      "this needs no post-hoc multiplicity correction (unlike testing",
      "many pairwise comparisons after the fact, which this calculator",
      "does not cover).",
      "",
      "- **Group means (mu_i)** - the mean you expect in each of the k",
      "  groups.",
      "- **Common SD (sigma)** - the standard deviation shared by all",
      "  groups.",
      "- **Contrast coefficients (c_i)** - the weights defining your",
      "  planned comparison, which must sum to 0. For an equally-spaced",
      "  linear trend across k ordered groups these are the standard",
      "  orthogonal polynomial coefficients (e.g. -3,-1,1,3 for k=4); for",
      "  an unequally-spaced trend (e.g. doses 0, 1, 2, 3 mg but tested",
      "  against a specific non-uniform weighting) any coefficients",
      "  summing to 0 can be used.",
      "- **Allocation fractions (f_i)** - each group's share of the total",
      "  sample size (n_i/n), summing to 1; equal allocation across k",
      "  groups uses f_i = 1/k for every group.",
      "- **alpha, power** - as elsewhere.",
      sep = "\n"
    ),
    worked_example = paste(
      "Chow, Shao & Wang (2003), Example 11.1: a 4-arm dose-response",
      "trial with expected group means 0.05, 0.12, 0.14, 0.16, a common",
      "SD of 0.22, and contrast coefficients -6, 1, 2, 3 (an a priori",
      "weighting emphasizing the placebo-vs-active contrast), with equal",
      "allocation (f_i = 0.25 for all 4 groups). At alpha = 0.05 and 80%",
      "power, this calculator returns a total sample size of n = 178,",
      "matching the textbook's own worked answer exactly.",
      sep = "\n"
    ),
    citation = paste(
      "Chow SC, Shao J, Wang H. Sample Size Calculations in Clinical",
      "Research. New York: Marcel Dekker; 2003. Section 11.2."
    ),
    backend = "TrialSize::Dose.Response.Linear()"
  ),

  single_precision = list(
    title = "Single Mean, Precision-Based (No Reference Value)",
    formula_latex = paste0(
      "$$V^2 = \\sigma^2/\\bar{x}^2, \\quad ",
      "n = \\frac{Z_{1-\\alpha/2}^2 \\, V^2}{Z_{1-\\alpha/2}^2 \\, V^2 / N_\\infty + \\epsilon_r^2}$$"
    ),
    explanation = paste(
      "This calculator finds the sample size needed to estimate a mean to a",
      "desired precision, with no hypothesis test and no reference value --",
      "just a target margin of error and a confidence level (the estimation",
      "counterpart of the Proportions module's precision-based design).",
      "",
      "- **mean** - the anticipated mean of the variable (must be non-zero:",
      "  the underlying formula works in relative-variance terms, so it",
      "  suits inherently-positive measurements like BP, Hb, BMI, or",
      "  bodyweight, not values that can legitimately be zero or negative).",
      "- **sd** - the expected standard deviation.",
      "- **epsilon** - the desired precision: how close the estimate should",
      "  land to the true value, either as an absolute amount or as a",
      "  fraction of the mean (`error = \"relative\"` vs `\"absolute\"`).",
      "- **conf_level** - the confidence level, typically 0.95.",
      "- **N** - optional finite population size; leave blank for an",
      "  effectively infinite population (a finite population correction is",
      "  applied automatically when supplied).",
      sep = "\n"
    ),
    worked_example = paste(
      "epiR's own documented example (Levy & Lemeshow 1999): a city has 20",
      "neighbourhood clinics, each seeing an average of 1500 patients/year",
      "(SD 300), of whom ~5% get a particular new prescription. Wanting an",
      "estimate within 20% of the true value (relative error), this",
      "calculator returns n = 4 clinics -- exactly epiR's own printed",
      "answer.",
      sep = "\n"
    ),
    citation = paste(
      "Levy PS, Lemeshow S. Sampling of Populations: Methods and",
      "Applications. Wiley Series in Probability and Statistics; 1999,",
      "pp. 70-75. (as implemented by epiR::epi.sssimpleestc)."
    ),
    backend = "epiR::epi.sssimpleestc()"
  ),

  two_sample_unequal_n = list(
    title = "Two Independent Means, Unequal Group Sizes",
    formula_latex = paste0(
      "$$d = \\frac{\\mu_1 - \\mu_2}{\\sigma}$$",
      "$$\\text{solve } n_2 \\text{ from } d, n_1, \\alpha, \\text{power (Cohen 1988)}$$"
    ),
    explanation = paste(
      "This calculator finds the size of a *second* group needed to reach a",
      "target power, when the *first* group's size is already fixed (e.g. a",
      "comparison group constrained by how many archived samples/records",
      "are available) -- a two-sample t-test with unequal allocation.",
      "",
      "- **mu1, mu2** - the expected means in group 1 and group 2.",
      "- **sd** - the common/pooled standard deviation shared by both groups.",
      "- **n1** - the already-fixed size of group 1.",
      "- **alpha, power** - as elsewhere.",
      "",
      "If both groups can be freely sized, use \"Two independent means\"",
      "(equal allocation) instead -- it needs a smaller total n for the",
      "same power.",
      sep = "\n"
    ),
    worked_example = paste(
      "Suppose group 1 is fixed at n1 = 90 (mu1 = 10, mu2 = 9.4, sd = 1, so",
      "d = 0.6 -- Cohen's own example effect size, Exercise 2.3 p. 437). At",
      "alpha = 0.05 (two-sided) and 80% power, this calculator returns n2 =",
      "30 (n_total = 120). As a check on the underlying method: Cohen's own",
      "textbook example with n1 = 90, n2 = 60 and this same d = 0.6 (one-",
      "sided) gives an achieved power of 0.9737 -- reproduced exactly by",
      "pwr::pwr.t2n.test().",
      sep = "\n"
    ),
    citation = paste(
      "Cohen J. Statistical Power Analysis for the Behavioral Sciences.",
      "2nd ed. Hillsdale, NJ: Lawrence Erlbaum Associates; 1988, Exercise",
      "2.3 p. 437. (as implemented by pwr::pwr.t2n.test)."
    ),
    backend = "pwr::pwr.t2n.test()"
  ),

  posthoc_pairwise = list(
    title = "Post-Hoc Pairwise Comparison (Bonferroni-Adjusted)",
    formula_latex = paste0(
      "$$n_{ij} = \\frac{2\\left(Z_{1-\\alpha/(2\\tau)} + Z_{1-\\beta}\\right)^2 \\sigma^2}",
      "{(\\mu_i - \\mu_j)^2}$$"
    ),
    explanation = paste(
      "Use this to size ONE specific pairwise comparison (group i vs.",
      "group j) out of several planned comparisons across a multi-group",
      "study, correcting the significance level for running multiple",
      "tests at once (Bonferroni's method) -- the multiplicity-adjusted",
      "complement to the \"Planned linear contrast\" design above, which",
      "instead tests a single pre-specified combination of *all* k means.",
      "",
      "- **tau** - the total number of pairwise comparisons planned",
      "  across the whole study (not just this one pair); e.g. for all",
      "  pairs among k groups, tau = k(k-1)/2 -- 3 groups gives tau=3, 4",
      "  groups gives tau=6 -- or a smaller number if you only plan to",
      "  test some of the pairs.",
      "- **Common SD (sigma)** - the standard deviation shared by all",
      "  groups.",
      "- **Assumed difference (margin)** - the true difference between",
      "  this specific pair's two group means.",
      "- **alpha** - the overall (family-wise) significance level; the",
      "  calculator internally uses alpha/tau for this pair's test, so",
      "  the whole family of tau tests keeps a combined false-positive",
      "  rate no higher than alpha.",
      "- **power** - the desired power for detecting this pair's",
      "  difference.",
      "",
      "Because the correction divides alpha by tau, more planned",
      "comparisons require a larger sample size per pair for the same",
      "power -- the cost of testing multiple hypotheses without inflating",
      "the overall false-positive rate.",
      sep = "\n"
    ),
    worked_example = paste(
      "Suppose a 3-arm trial (tau = 3 planned pairwise comparisons among",
      "the 3 arms) expects a common SD of 4 and wants to detect a",
      "difference of 3 units between one specific pair of arms, at an",
      "overall alpha = 0.05 and 80% power. This calculator returns n = 38",
      "per group for that pair -- independently re-derived from the",
      "standard two-sample z-test formula with alpha/tau in place of",
      "alpha, and confirmed to reproduce",
      "TrialSize::OneWayANOVA.pairwise()'s own output exactly (that",
      "package's Rd file cites the method but doesn't print a worked",
      "numeric answer).",
      sep = "\n"
    ),
    citation = paste(
      "Chow SC, Shao J, Wang H. Sample Size Calculations in Clinical",
      "Research. New York: Marcel Dekker; 2003. Bonferroni multiple-",
      "comparison adjustment applied to the standard two-sample sample",
      "size formula."
    ),
    backend = "TrialSize::OneWayANOVA.pairwise()"
  )
)
