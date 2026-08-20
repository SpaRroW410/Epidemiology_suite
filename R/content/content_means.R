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
  )
)
