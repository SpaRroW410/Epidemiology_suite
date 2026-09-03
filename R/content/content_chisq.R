# Metadata for the Chi-Square Tests module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_chisq.R (SDD 4.2: "content is data, not hardcoded UI").

chisq_content <- list(
  gof = list(
    title = "Goodness of Fit",
    formula_latex = paste0(
      "$$w = \\sqrt{\\sum_{i=1}^{k}\\frac{(P_{1i} - P_{0i})^2}{P_{0i}}}$$",
      "$$N = \\text{solved from } w, \\, df=k-1, \\, \\alpha, \\text{power (Cohen 1988)}$$"
    ),
    explanation = paste(
      "Use this to test whether the observed distribution of a single",
      "categorical variable (across k categories) matches a hypothesized",
      "or expected distribution -- e.g. \"do blood group proportions in",
      "our sample match the published national distribution?\"",
      "",
      "- **P0 (null proportions)** - the expected/hypothesized proportion",
      "  in each category, summing to 1.",
      "- **P1 (alternative proportions)** - the proportions you actually",
      "  expect to find, summing to 1 (same number of categories as P0).",
      "- **alpha, power** - as elsewhere.",
      "",
      "Cohen's w here plays the same role as h for proportions or d for",
      "means (small ~0.10, medium ~0.30, large ~0.50, per Cohen's",
      "conventions); degrees of freedom = k - 1.",
      sep = "\n"
    ),
    worked_example = paste(
      "Cohen (1988), Exercise 7.1, p. 249: with 4 equally-likely",
      "categories expected (P0 = 0.25 each), but actually anticipating",
      "37.5% in the first category and the remaining 62.5% split evenly",
      "across the other three (P1 = 0.375, 0.2083, 0.2083, 0.2083), this",
      "calculator returns w ~ 0.289 and a required total sample size of",
      "N = 131 at alpha = 0.05 and 80% power.",
      sep = "\n"
    ),
    citation = paste(
      "Cohen J. Statistical Power Analysis for the Behavioral Sciences.",
      "2nd ed. Hillsdale, NJ: Lawrence Erlbaum Associates; 1988.",
      "(effect size w, and chi-squared goodness-of-fit power analysis,",
      "as implemented by pwr::ES.w1 and pwr::pwr.chisq.test)."
    ),
    backend = "pwr::ES.w1() + pwr::pwr.chisq.test()"
  ),

  independence = list(
    title = "Test of Independence / Association (R x C Table)",
    formula_latex = paste0(
      "$$w = \\sqrt{\\sum_{i,j}\\frac{(P_{ij} - P_{i \\cdot}P_{\\cdot j})^2}{P_{i \\cdot}P_{\\cdot j}}}$$",
      "$$N = \\text{solved from } w, \\, df=(r-1)(c-1), \\, \\alpha, \\text{power (Cohen 1988)}$$"
    ),
    explanation = paste(
      "Use this to test whether two categorical variables are",
      "associated -- e.g. \"is treatment group associated with outcome",
      "category?\" -- from a contingency table with r rows and c columns.",
      "",
      "- **Joint proportions (P)** - the proportion of the *total* sample",
      "  you expect to fall into each row x column cell, summing to 1",
      "  across the whole table (not just within each row).",
      "- **alpha, power** - as elsewhere.",
      "",
      "Cohen's w is computed from how far the joint-proportion table",
      "departs from what independence would predict (each cell equal to",
      "its row-total times column-total); degrees of freedom =",
      "(rows-1) x (cols-1). For a 2x2 table this is closely related to,",
      "but not identical to, the two-independent-proportions calculator",
      "in the Proportions module -- use whichever framing matches how",
      "you'll actually analyze the data.",
      sep = "\n"
    ),
    worked_example = paste(
      "A 2x2 table where the joint proportions are expected to be 0.15",
      "(row 1, col 1), 0.35 (row 1, col 2), 0.10 (row 2, col 1), and 0.40",
      "(row 2, col 2) -- i.e. row totals of 0.50/0.50 and column totals",
      "of 0.25/0.75. This calculator returns w ~ 0.115 and a required",
      "total sample size of N = 589 at alpha = 0.05 and 80% power.",
      sep = "\n"
    ),
    citation = paste(
      "Cohen J. Statistical Power Analysis for the Behavioral Sciences.",
      "2nd ed. Hillsdale, NJ: Lawrence Erlbaum Associates; 1988.",
      "(effect size w, and chi-squared test-of-association power",
      "analysis, as implemented by pwr::ES.w2 and pwr::pwr.chisq.test)."
    ),
    backend = "pwr::ES.w2() + pwr::pwr.chisq.test()"
  ),

  mcnemar = list(
    title = "McNemar's Test (Paired/Matched Proportions)",
    formula_latex = paste0(
      "$$n = \\frac{\\left(Z_{1-\\alpha/2}(\\psi+1) + Z_{1-\\beta}\\sqrt{(\\psi+1)^2 - (\\psi-1)^2 p_d}\\right)^2}",
      "{(\\psi-1)^2 p_d}$$",
      "$$\\psi = \\frac{p_{01}}{p_{10}}, \\quad p_d = p_{10} + p_{01}$$"
    ),
    explanation = paste(
      "Use this when the SAME subjects are measured twice (before/after,",
      "or two raters/tests on the same subjects) for a binary outcome,",
      "and you want to test whether the proportion switching one",
      "direction differs from the proportion switching the other --",
      "e.g. \"does treatment change more patients from disease-positive",
      "to disease-negative than the reverse?\" This is the paired-data",
      "analog of the two-independent-proportions test in the Proportions",
      "module, and only the *discordant* (switching) pairs carry",
      "information -- concordant pairs (no change either way) don't",
      "affect the test.",
      "",
      "- **p10** - expected proportion of pairs that switch from",
      "  positive to negative (or from the first condition's \"yes\" to",
      "  the second condition's \"no\").",
      "- **p01** - expected proportion of pairs that switch the other",
      "  direction. p10 and p01 must differ -- if they're equal, there's",
      "  no asymmetry for McNemar's test to detect.",
      "- **alpha, power** - as elsewhere.",
      "",
      "p10 + p01 is the total discordant-pair proportion; concordant",
      "pairs (both positive or both negative at both time points) are",
      "not counted here since they don't inform the test.",
      sep = "\n"
    ),
    worked_example = paste(
      "Chow, Shao & Wang (2003), Example 6.4.3: a paired before/after",
      "study expects 50% of pairs to switch from positive to negative",
      "(p10 = 0.5) and 20% to switch from negative to positive",
      "(p01 = 0.2) -- a 2.5-fold asymmetry. At alpha = 0.05 and 80%",
      "power, this calculator returns n = 59 pairs, matching the",
      "textbook's own worked answer exactly.",
      sep = "\n"
    ),
    citation = paste(
      "Chow SC, Shao J, Wang H. Sample Size Calculations in Clinical",
      "Research. New York: Marcel Dekker; 2003. Section 6.4."
    ),
    backend = "TrialSize::McNemar.Test()"
  ),

  mantelhaenszel = list(
    title = "Mantel-Haenszel Test for Stratified Proportions",
    formula_latex = paste0(
      "$$n_{\\text{stratified}} = \\frac{\\left(\\sqrt{\\sigma_0}\\,Z_{1-\\alpha/2} + \\sqrt{\\sigma_1}\\,Z_{1-\\beta}\\right)^2}{\\Delta^2}, \\quad ",
      "\\Delta = \\sum_j a_j b_j (1-b_j)(p_{1j}-p_{2j})$$",
      "$$n_{\\text{pooled}} = \\frac{\\left(\\sqrt{\\sigma_0^*}\\,Z_{1-\\alpha/2} + \\sqrt{\\sigma_1^*}\\,Z_{1-\\beta}\\right)^2}{(p_1^* - p_2^*)^2}$$"
    ),
    explanation = paste(
      "Use this when comparing two groups' response proportions while",
      "adjusting for one or more confounding strata -- e.g. age bands,",
      "disease-severity categories, or propensity-score strata -- rather",
      "than pooling everyone together. This is the sample-size analog of",
      "the (weighted) Mantel-Haenszel / Cochran-Mantel-Haenszel test for a",
      "stratified 2x2xJ table, and it's what a matched or stratified",
      "case-control/cohort analysis, or a propensity-score-stratified",
      "comparison, actually analyzes.",
      "",
      "For each of the J strata, enter:",
      "- **a_j** - the proportion of the *total* sample that falls in",
      "  stratum j (all strata's a_j must sum to 1).",
      "- **b_j** - the proportion of stratum j's subjects allocated to",
      "  group 1 (the reference/control group); 1-b_j go to group 2.",
      "- **p1_j** - the expected response probability for group 1 in",
      "  stratum j.",
      "",
      "**phi** is the assumed common odds ratio of group 2 vs. group 1,",
      "applied identically in every stratum to derive that stratum's",
      "group-2 response probability from p1_j (so the effect is assumed",
      "constant across strata, the usual Mantel-Haenszel assumption of",
      "homogeneous/non-interacting strata).",
      "",
      "The calculator reports two sample sizes side by side: the correct",
      "**stratified (Mantel-Haenszel-weighted)** figure, and the **naive",
      "pooled** figure you'd get by ignoring the strata entirely and just",
      "comparing the two groups' overall proportions -- illustrating how",
      "much larger a sample an unadjusted analysis can need when a real",
      "confounding structure is ignored.",
      sep = "\n"
    ),
    worked_example = paste(
      "Chow, Shao & Wang (2003), Example 15.2.3 (a propensity-score",
      "stratified analysis with J=5 strata): stratum allocations",
      "a = (0.15, 0.15, 0.20, 0.25, 0.25), group-1 shares",
      "b = (0.4, 0.4, 0.5, 0.6, 0.6), group-1 response probabilities",
      "p1 = (0.5, 0.6, 0.7, 0.8, 0.9), assumed odds ratio phi = 2, at",
      "alpha = 0.05 and 80% power. This calculator returns a stratified",
      "(Mantel-Haenszel) sample size of n = 447, versus n = 1151 for the",
      "naive pooled comparison that ignores the strata -- both matching",
      "the textbook's own two worked answers exactly.",
      sep = "\n"
    ),
    citation = paste(
      "Chow SC, Shao J, Wang H. Sample Size Calculations in Clinical",
      "Research. New York: Marcel Dekker; 2003. Section 15.2.3."
    ),
    backend = "TrialSize::Propensity.Score.strata() + TrialSize::Propensity.Score.nostrata()"
  ),

  cochran_armitage = list(
    title = "Cochran-Armitage Trend Test (Dose-Response Proportions)",
    formula_latex = paste0(
      "$$H_0: p_1 = p_2 = \\cdots = p_k \\quad \\text{vs.} \\quad ",
      "H_a: p_1 \\le p_2 \\le \\cdots \\le p_k, \\; p_1 < p_k$$",
      "$$n \\text{ solved from the weighted-least-squares trend statistic ",
      "(Chow, Shao \\& Wang 2003, \\S11.5)}$$"
    ),
    explanation = paste(
      "Use this to test for a monotonic trend in response proportion",
      "across k ordered dose/exposure groups -- e.g. \"does the",
      "proportion of adverse events increase steadily as dose",
      "increases?\" -- rather than the omnibus \"do any groups differ\"",
      "question a plain chi-squared test of independence asks. This is",
      "the standard method for dose-response and exposure-response",
      "studies with a binary outcome.",
      "",
      "For each of the k ordered groups, enter:",
      "- **pi** - the response proportion you expect in that group.",
      "- **di** - the dose/exposure level for that group (e.g. 1, 2, 3,",
      "  4, or the actual doses).",
      "- **ni** - the planned *relative* allocation across groups (e.g.",
      "  all equal for equal allocation) -- only the ratios between",
      "  groups matter, not the absolute values.",
      "",
      "**delta** is a clinically meaningful minimal difference used in a",
      "small-sample correction term; 0 is a reasonable default when no",
      "such minimal difference is known. The calculator solves for the",
      "reference (first) group's sample size, then scales every other",
      "group by its allocation ratio to get the per-group and total",
      "sample sizes.",
      "",
      "Note: the closely related `TrialSize::Dose.Response.binary()` (also",
      "a dose-response/Cochran-Armitage-style formula) was investigated in",
      "an earlier batch and found to NOT reproduce its own package's",
      "documented example -- this calculator uses a different,",
      "independently verified function from the same package that DOES",
      "reproduce its own documented example exactly.",
      sep = "\n"
    ),
    worked_example = paste(
      "Chow, Shao & Wang (2003), Example 11.5: four equally-allocated",
      "dose groups with expected response proportions 0.1, 0.3, 0.5, 0.7",
      "at doses 1, 2, 3, 4, a minimal clinically meaningful difference of",
      "delta = 1, alpha = 0.05, and 80% power. This calculator returns",
      "n = 8 per group (32 total), matching the textbook's own worked",
      "answer (\"~7.5 for one group, total 28-32\") once rounded up to a",
      "whole number of subjects, consistent with every other calculator",
      "in this app.",
      sep = "\n"
    ),
    citation = paste(
      "Chow SC, Shao J, Wang H. Sample Size Calculations in Clinical",
      "Research. New York: Marcel Dekker; 2003. Section 11.5."
    ),
    backend = "TrialSize::Cochran.Armitage.Trend()"
  )
)
