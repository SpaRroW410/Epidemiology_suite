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
  )
)
