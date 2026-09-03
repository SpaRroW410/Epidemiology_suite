# Metadata for the Nonparametric Tests module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_nonparametric.R (SDD 4.2: "content is data, not
# hardcoded UI").

nonparametric_content <- list(
  wilcoxon_rank_sum = list(
    title = "Wilcoxon Rank-Sum Test (Mann-Whitney U)",
    formula_latex = paste0(
      "$$n_2 = \\frac{\\left(Z_{1-\\alpha/2}\\sqrt{k(k+1)/12} + ",
      "Z_{1-\\beta}\\sqrt{k^2(p_2-p_1^2) + k(p_3-p_1^2)}\\right)^2}{k^2(1/2-p_1)^2}, ",
      "\\quad n_1 = k\\,n_2$$"
    ),
    explanation = paste(
      "Use this to compare two independent groups on a continuous or",
      "ordinal outcome WITHOUT assuming normality -- the nonparametric",
      "alternative to the two-independent-means t-test in the Means",
      "module, based on ranks rather than raw values.",
      "",
      "- **k** - the allocation ratio n1/n2 (1 for equal group sizes).",
      "- **p1** - P(Y >= X) for one observation from each group: the",
      "  probability a random group-2 value exceeds a random group-1",
      "  value. Exactly 0.5 under the null of no shift; further from 0.5",
      "  means a bigger effect (this plays the same role that Cohen's d",
      "  plays for the parametric t-test, and can be estimated from pilot",
      "  data or from an assumed effect size and distribution shape).",
      "- **p2, p3** - higher-order concordance probabilities involving",
      "  three observations (needed for the variance of the rank-sum",
      "  statistic under the alternative); like p1, these are typically",
      "  estimated from pilot data or a assumed parametric alternative",
      "  distribution.",
      "- **alpha, power** - as elsewhere.",
      sep = "\n"
    ),
    worked_example = paste(
      "Chow, Shao & Wang (2003), Example 14.3: with equal group sizes",
      "(k = 1), p1 = 0.7, p2 = 0.8, and p3 = 0.8, at alpha = 0.05 and 80%",
      "power, this calculator returns n = 54 total (27 per group),",
      "matching the textbook's own worked answer exactly.",
      sep = "\n"
    ),
    citation = paste(
      "Chow SC, Shao J, Wang H. Sample Size Calculations in Clinical",
      "Research. New York: Marcel Dekker; 2003. Section 14.3."
    ),
    backend = "TrialSize::Nonpara.Two.Sample()"
  ),

  wilcoxon_signed_rank = list(
    title = "Wilcoxon Signed-Rank Test (One Sample / Paired Differences)",
    formula_latex = paste0(
      "$$n = \\frac{\\left(Z_{1-\\alpha/2}/\\sqrt{12} + ",
      "Z_{1-\\beta}\\sqrt{p_3 + 4p_4 - 4p_2^2}\\right)^2}{(1/4-p_2)^2}$$"
    ),
    explanation = paste(
      "Use this to test whether the median of a single distribution (or",
      "the median of paired differences, e.g. before-after) differs from",
      "zero, WITHOUT assuming normality -- the nonparametric alternative",
      "to the one-sample or paired t-test in the Means module.",
      "",
      "- **p2** - P(|Z_i| >= |Z_j|, Z_i > 0) for two independent",
      "  observations: exactly 0.25 under the null of a symmetric",
      "  distribution centered at zero.",
      "- **p3, p4** - higher-order probabilities (three observations)",
      "  needed for the variance of the signed-rank statistic under the",
      "  alternative.",
      "- **alpha, power** - as elsewhere.",
      "",
      "As with the rank-sum test above, p2/p3/p4 are typically estimated",
      "from pilot data or an assumed alternative distribution rather than",
      "specified directly from intuition.",
      sep = "\n"
    ),
    worked_example = paste(
      "Chow, Shao & Wang (2003), Example 14.2: with p2 = 0.3, p3 = 0.4,",
      "and p4 = 0.05, at alpha = 0.05 and 80% power, this calculator",
      "returns n = 383, matching the textbook's own worked answer",
      "exactly.",
      sep = "\n"
    ),
    citation = paste(
      "Chow SC, Shao J, Wang H. Sample Size Calculations in Clinical",
      "Research. New York: Marcel Dekker; 2003. Section 14.2."
    ),
    backend = "TrialSize::Nonpara.One.Sample()"
  ),

  kendall_tau = list(
    title = "Kendall's Tau (Nonparametric Test of Association)",
    formula_latex = paste0(
      "$$n = \\frac{\\left(Z_{1-\\alpha/2}/3 + ",
      "Z_{1-\\beta}\\sqrt{2p_2 - 1 - (2p_1-1)^2}\\right)^2}{(2p_1-1)^2/4}$$",
      "$$\\tau = 2p_1 - 1$$"
    ),
    explanation = paste(
      "Use this to test whether two continuous variables are associated",
      "WITHOUT assuming bivariate normality -- the nonparametric",
      "alternative to the Pearson-correlation test in the Correlation",
      "module, based on the probability that pairs of observations are",
      "\"concordant\" (both variables move the same direction) rather",
      "than on the raw values.",
      "",
      "- **p1 (concordance probability)** - P((X1-X2)(Y1-Y2) > 0) for two",
      "  independent pairs: the probability that a randomly chosen pair",
      "  of subjects is concordant. Exactly 0.5 under independence; this",
      "  directly determines Kendall's tau via tau = 2\\*p1 - 1, so an",
      "  expected tau of 0.4 corresponds to p1 = 0.7.",
      "- **p2** - a higher-order concordance probability (three",
      "  independent pairs sharing one member) needed for the variance",
      "  of the test statistic under the alternative.",
      "- **alpha, power** - as elsewhere.",
      sep = "\n"
    ),
    worked_example = paste(
      "Chow, Shao & Wang (2003), Example 14.4: with p1 = 0.6",
      "(tau = 0.2) and p2 = 0.7, at alpha = 0.05 and 80% power, this",
      "calculator returns n = 135, matching the textbook's own worked",
      "answer exactly.",
      sep = "\n"
    ),
    citation = paste(
      "Chow SC, Shao J, Wang H. Sample Size Calculations in Clinical",
      "Research. New York: Marcel Dekker; 2003. Section 14.4."
    ),
    backend = "TrialSize::Nonpara.Independ()"
  ),

  kruskal_wallis = list(
    title = "Kruskal-Wallis Test (k Independent Groups)",
    formula_latex = paste0(
      "$$n_{\\text{ANOVA}} \\text{ solved from } k, f, \\alpha, \\text{power (Cohen 1988)}$$",
      "$$n_{\\text{per group}} = \\left\\lceil n_{\\text{ANOVA}} \\times \\frac{\\pi}{3} \\right\\rceil$$"
    ),
    explanation = paste(
      "Use this to compare k >= 3 independent groups on a continuous or",
      "ordinal outcome WITHOUT assuming normality -- the nonparametric",
      "alternative to one-way ANOVA in the Means module, based on ranks",
      "across all groups rather than raw values.",
      "",
      "- **k** - the number of groups (use the Wilcoxon rank-sum design",
      "  above for k = 2).",
      "- **f (Cohen's f)** - the same standardized effect size the ANOVA",
      "  design uses (small ~0.10, medium ~0.25, large ~0.40).",
      "- **alpha, power** - as elsewhere.",
      "",
      "No installed package provides a genuine k-sample rank-test closed",
      "form (unlike this module's other three designs, each a direct",
      "TrialSize:: formula) -- so this uses the approach this project's",
      "own feasibility review named for this item: solve the equivalent",
      "one-way ANOVA sample size at the same Cohen's f, then inflate it by",
      "the classical asymptotic relative efficiency (ARE) of the",
      "Kruskal-Wallis test relative to ANOVA under normality, 3/pi ~ 0.955",
      "(Hodges & Lehmann 1956) -- the same constant that relates the",
      "Wilcoxon rank-sum test to the two-sample t-test. This is an",
      "asymptotic approximation, not an exact finite-sample formula, and",
      "is conservative (adequately large, if anything) for many",
      "non-normal distributions, since the Kruskal-Wallis test's",
      "efficiency relative to ANOVA is often *higher* than 3/pi when the",
      "data are non-normal.",
      sep = "\n"
    ),
    worked_example = paste(
      "For k = 3 groups and a medium effect (f = 0.25) at alpha = 0.05",
      "and 80% power, one-way ANOVA needs n = 53 per group; this",
      "calculator inflates that by pi/3 to n = 56 per group (168 total)",
      "for the Kruskal-Wallis test -- independently confirmed by",
      "simulation: running the actual `kruskal.test()` on 5,000",
      "replicates of 3-group data at this exact effect size gives an",
      "empirical power of 0.812 at n = 56 (closely matching the 0.80",
      "target), versus only 0.787 at the unadjusted ANOVA n = 53.",
      sep = "\n"
    ),
    citation = paste(
      "Hodges JL, Lehmann EL. The Efficiency of Some Nonparametric",
      "Competitors of the t-Test. Ann Math Stat. 1956;27(2):324-335",
      "(asymptotic relative efficiency 3/pi); Lehmann EL. Nonparametrics:",
      "Statistical Methods Based on Ranks. Holden-Day; 1975; Cohen J.",
      "Statistical Power Analysis for the Behavioral Sciences. 2nd ed.",
      "Lawrence Erlbaum Associates; 1988 (one-way ANOVA power analysis,",
      "as implemented by pwr::pwr.anova.test)."
    ),
    backend = "pwr::pwr.anova.test() inflated by the 3/pi asymptotic relative efficiency (Hodges & Lehmann 1956)"
  )
)
