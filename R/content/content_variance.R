# Metadata for the Variance Tests module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_variance.R (SDD 4.2: "content is data, not
# hardcoded UI").

variance_content <- list(
  single = list(
    title = "Single-Variance Test (Chi-Squared)",
    formula_latex = paste0(
      "$$H_0: \\sigma^2 = \\sigma_0^2 \\quad \\text{vs.} \\quad H_1: \\sigma^2 = \\sigma_1^2, ",
      "\\quad \\sigma_1^2 \\ne \\sigma_0^2$$",
      "$$\\frac{(n-1)S^2}{\\sigma_0^2} \\sim \\chi^2_{n-1} \\text{ under } H_0$$"
    ),
    explanation = paste(
      "Use this to test whether a population's variance (or SD) equals a",
      "specific reference value -- e.g. \"is this new manufacturing",
      "process's variability the same as the established process's",
      "known SD of 10 units?\" -- rather than estimating a mean.",
      "",
      "- **sigma0 (reference SD)** - the null-hypothesis standard",
      "  deviation you're testing against.",
      "- **sigma1 (assumed true SD)** - the standard deviation you",
      "  actually expect, which must differ from sigma0.",
      "- **alpha, power** - as elsewhere.",
      "- **Alternative** - two-sided (sigma differs from sigma0 in either",
      "  direction), or one-sided if you only care about the variance",
      "  being larger or smaller.",
      "",
      "This uses the standard result that, under the null hypothesis,",
      "(n-1) times the sample variance divided by the reference variance",
      "follows a chi-squared distribution with n-1 degrees of freedom --",
      "solved numerically for the n that achieves the desired power",
      "against the assumed true variance (no closed algebraic formula",
      "exists for n, but the power-as-a-function-of-n relationship is",
      "exact and deterministic).",
      sep = "\n"
    ),
    worked_example = paste(
      "For a reference SD of 10 units and an assumed true SD of 14",
      "units (one-sided, testing whether the true SD is larger), at",
      "alpha = 0.05 and 80% power, this calculator returns n = 28 --",
      "independently confirmed by Monte Carlo simulation (20,000",
      "replicates at n = 28 gave an empirical power of 0.814, closely",
      "matching the 0.80 target).",
      sep = "\n"
    ),
    citation = paste(
      "Standard chi-squared test for a single variance; see e.g. Rosner",
      "B. Fundamentals of Biostatistics. 8th ed. Cengage Learning; 2015,",
      "or Desu MM, Raghavarao D. Sample Size Methodology. Academic",
      "Press; 1990."
    ),
    backend = "closed-form (chi-squared distribution, uniroot solve)"
  ),

  two = list(
    title = "Two-Variance Test (F Test)",
    formula_latex = paste0(
      "$$H_0: \\sigma_1^2 = \\sigma_2^2 \\quad \\text{vs.} \\quad H_1: \\sigma_1^2 \\ne \\sigma_2^2$$",
      "$$\\frac{S_1^2/S_2^2}{\\sigma_1^2/\\sigma_2^2} \\sim F_{n-1,n-1} ",
      "\\text{ for equal group sizes } n$$"
    ),
    explanation = paste(
      "The two-sample counterpart of the single-variance test above --",
      "use this to test whether two groups have equal variability",
      "(e.g. comparing measurement consistency between two instruments,",
      "or variability between two manufacturing processes) rather than",
      "comparing their means.",
      "",
      "- **sigma1, sigma2** - the assumed true standard deviations for",
      "  the two groups, which must differ.",
      "- **alpha, power** - as elsewhere.",
      "- **Alternative** - two-sided or one-sided, as above.",
      "",
      "Assumes equal group sizes (a common simplification for planning",
      "purposes); uses the standard result that the ratio of two sample",
      "variances, scaled by the true variance ratio, follows an F",
      "distribution with (n-1, n-1) degrees of freedom.",
      sep = "\n"
    ),
    worked_example = paste(
      "For assumed SDs of 10 and 14 units in the two groups (two-sided",
      "test), at alpha = 0.05 and 80% power, this calculator returns",
      "n = 72 per group (144 total) -- independently confirmed by Monte",
      "Carlo simulation (20,000 replicates at n = 72 gave an empirical",
      "power of 0.804, closely matching the 0.80 target).",
      sep = "\n"
    ),
    citation = paste(
      "Standard F test for equality of two variances; see e.g. Rosner B.",
      "Fundamentals of Biostatistics. 8th ed. Cengage Learning; 2015, or",
      "Desu MM, Raghavarao D. Sample Size Methodology. Academic Press;",
      "1990.",
      "",
      "Note: TrialSize::ISV.Equality() and ISCV.Equality() (Chow, Shao &",
      "Wang 2003) were investigated as possible backends for this design",
      "and found to be broken in the installed package -- ISV.Equality()",
      "computes nothing useful (its loop never compares its ratio to",
      "anything and returns NULL), and ISCV.Equality() has a missing",
      "multiplication operator and throws a runtime error on any input.",
      "This calculator reimplements the standard F-test formula directly",
      "instead, verified by simulation rather than against those broken",
      "functions."
    ),
    backend = "closed-form (F distribution, uniroot solve)"
  )
)
