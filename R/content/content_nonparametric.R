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
  ),

  jonckheere_terpstra = list(
    title = "Jonckheere-Terpstra Test (Ordered Alternatives)",
    formula_latex = paste0(
      "$$n = \\frac{\\left(Z_{1-\\alpha/2}/3 + ",
      "Z_{1-\\beta}\\sqrt{2p_2 - 1 - (2p_1-1)^2}\\right)^2}{(2p_1-1)^2/4}$$",
      "$$\\tau = 2p_1 - 1$$"
    ),
    explanation = paste(
      "Use this to test for a monotonic trend in a continuous outcome",
      "across k *ordered* groups (e.g. increasing dose levels, disease",
      "severity stages) WITHOUT assuming normality -- the nonparametric",
      "alternative to the Cochran-Armitage trend test's continuous-",
      "outcome analog, and closely related to the Kruskal-Wallis design",
      "above but specifically for ordered (not just categorical) groups.",
      "",
      "- **p1 (concordance probability)** - the probability that a",
      "  randomly chosen pair of subjects has their outcome and their",
      "  ordinal group both moving the same direction; exactly 0.5 under",
      "  no trend. This directly determines Kendall's tau via",
      "  tau = 2\\*p1 - 1.",
      "- **p2** - a higher-order concordance probability (three",
      "  independent pairs sharing one member) needed for the variance",
      "  of the test statistic under the alternative.",
      "- **alpha, power** - as elsewhere.",
      "",
      "`clinfun::jonckheere.test()` -- the package this app already uses",
      "for Simon's two-stage design and Kendall's tau -- provides no",
      "sample-size function at all (it's an analysis-only function, like",
      "`stats::kruskal.test()`), but its own documentation notes that",
      "\"the asymptotic version is equivalent to",
      "`cor.test(x, g, method = \"k\")`\" -- i.e. exactly Kendall's tau",
      "computed between the outcome and an integer group score (Terpstra",
      "1952; Jonckheere 1954). This calculator is therefore a thin wrapper",
      "around the Kendall's Tau design above -- no new formula, since",
      "they're mathematically the same statistic under this framing.",
      sep = "\n"
    ),
    worked_example = paste(
      "Using the same inputs as the Kendall's Tau worked example (p1 =",
      "0.6, i.e. tau = 0.2, and p2 = 0.7), at alpha = 0.05 and 80% power,",
      "this calculator returns n = 135 -- identical to Kendall's tau's own",
      "verified answer (Chow, Shao & Wang (2003) Example 14.4), since the",
      "two tests are the same computation under the asymptotic",
      "equivalence noted above.",
      sep = "\n"
    ),
    citation = paste(
      "Jonckheere AR. A distribution-free k-sample test against ordered",
      "alternatives. Biometrika. 1954;41(1-2):133-145; Terpstra TJ. The",
      "asymptotic normality and consistency of Kendall's test against",
      "trend, when ties are present in one ranking. Indagationes",
      "Mathematicae. 1952;14:327-333; Hollander M, Wolfe DA.",
      "Nonparametric Statistical Methods. 2nd ed. Wiley; 1999 (the",
      "trend-test-as-Kendall's-tau equivalence)."
    ),
    backend = "TrialSize::Nonpara.Independ() (thin wrapper around this module's Kendall's tau design)"
  ),

  friedman = list(
    title = "Friedman Test (k Related/Repeated Measurements)",
    formula_latex = paste0(
      "$$n_{\\text{RM-ANOVA}} \\text{ solved from } k, f, \\alpha, \\text{power (Cohen 1988)}$$",
      "$$ARE = \\frac{3}{\\pi}\\cdot\\frac{k}{k+1} \\quad n_{\\text{Friedman}} = \\left\\lceil n_{\\text{RM-ANOVA}} / ARE \\right\\rceil$$"
    ),
    explanation = paste(
      "Use this to compare k >= 3 related/repeated measurements (e.g. the",
      "same subjects measured at k time points, or under k treatment",
      "conditions) WITHOUT assuming normality -- the nonparametric",
      "alternative to the one-group within-subjects design in the",
      "RM-ANOVA / Mixed ANOVA module, based on within-subject ranks",
      "rather than raw values.",
      "",
      "- **k** - the number of repeated measurements/conditions (use the",
      "  Wilcoxon signed-rank design above for k = 2).",
      "- **f (Cohen's f)** - the same standardized effect size the",
      "  RM-ANOVA within-subjects design uses.",
      "- **nscor** - nonsphericity correction (1 = sphericity assumption",
      "  met), same as the RM-ANOVA module.",
      "- **alpha, power** - as elsewhere.",
      "",
      "Like the Kruskal-Wallis design above, no installed package provides",
      "a genuine closed form for the Friedman test's sample size -- so",
      "this solves the equivalent one-group within-subjects RM-ANOVA",
      "sample size at the same Cohen's f, then inflates it by the",
      "asymptotic relative efficiency (ARE) of Friedman relative to",
      "RM-ANOVA under normality. Unlike Kruskal-Wallis's constant 3/pi",
      "(which applies for any number of groups), Friedman's ARE also",
      "depends on k itself: ARE = (3/pi) x k/(k+1), only approaching the",
      "familiar 3/pi limit as k grows large (Zimmerman & Zumbo 1993). This",
      "is an asymptotic approximation, not an exact finite-sample formula.",
      sep = "\n"
    ),
    worked_example = paste(
      "For k = 4 repeated measurements and a medium effect (f = 0.25) at",
      "alpha = 0.05 and 80% power, the equivalent one-group within-subjects",
      "RM-ANOVA needs n = 176; the ARE for k = 4 is (3/pi) x 4/5 = 0.764,",
      "so this calculator inflates n to 231 for the Friedman test.",
      "Independently confirmed by simulation: searching for the n at which",
      "the actual `stats::friedman.test()` and a from-scratch RM-ANOVA",
      "F-test each cross 80% empirical power, on identical simulated",
      "compound-symmetric data (k = 4), gives a ratio",
      "n_Friedman/n_RM-ANOVA of about 1.28 -- closely matching this",
      "formula's predicted 1/ARE = pi/3 x 5/4 = 1.31.",
      sep = "\n"
    ),
    citation = paste(
      "Zimmerman DW, Zumbo BD. Relative power of the Wilcoxon test, the",
      "Friedman test, and repeated-measures ANOVA on ranks. J Exp Educ.",
      "1993;62(1):75-86 (ARE = (3/pi) x k/(k+1)); Cohen J. Statistical",
      "Power Analysis for the Behavioral Sciences. 2nd ed. Lawrence",
      "Erlbaum Associates; 1988 (repeated-measures ANOVA power analysis)."
    ),
    backend = "calc_rm_anova() inflated by the (3/pi)*k/(k+1) asymptotic relative efficiency (Zimmerman & Zumbo 1993)"
  ),
  ks_two_sample = list(
    title = "Kolmogorov-Smirnov Test (Two Independent Samples), via Monte Carlo Simulation",
    formula_latex = paste0(
      "$$\\hat{\\text{power}}(n) = \\frac{1}{R}\\sum_{r=1}^{R} \\mathbb{1}\\left[",
      "\\text{ks.test}(X_r, Y_r)_{p\\text{-value}} < \\alpha\\right]$$",
      "$$X_r \\sim N(0,1)^{n_1}, \\quad Y_r \\sim N(\\delta,1)^{n_2}$$"
    ),
    explanation = paste(
      "Unlike every other design in this module, the two-sample",
      "Kolmogorov-Smirnov (KS) test has NO closed-form power/sample-size",
      "formula against a general alternative -- its power depends on the",
      "full shape of the difference between the two groups' distributions,",
      "not a single effect-size number, so the asymptotic-relative-",
      "efficiency shortcuts used elsewhere in this module don't apply.",
      "This design instead does exactly what this app's own checklist",
      "names for this situation: direct Monte Carlo simulation of the",
      "actual test.",
      "",
      "- **effect_size** - a standardized mean shift between two Normal",
      "  distributions with equal variance (comparable to Cohen's d for",
      "  the t-test) -- a representative benchmark scenario for framing",
      "  the KS test's sensitivity to a location shift, not a claim that",
      "  real data will be exactly Normal. KS power for a genuinely",
      "  different kind of distributional difference (a scale change, a",
      "  shape change, heavy tails) will differ from what's reported here.",
      "- **nsim** - the number of simulated datasets drawn per candidate",
      "  sample size while searching; more replicates reduce the Monte",
      "  Carlo sampling error in the reported n and achieved power, at the",
      "  cost of runtime.",
      "- **alpha, power, n_ratio** - as elsewhere.",
      "",
      "Because this searches by simulation, the result carries ordinary",
      "Monte Carlo error (bigger than the negligible rounding error of a",
      "closed-form calculation) -- re-running with a different seed or a",
      "larger nsim will give a slightly different but converging answer.",
      sep = "\n"
    ),
    worked_example = paste(
      "A medium shift (effect_size = 0.5, comparable to Cohen's d = 0.5),",
      "alpha = 0.05, 80% power, equal groups, nsim = 500: this calculator",
      "returns n = 91 per group (182 total), achieved simulated power",
      "0.797. For comparison, the equivalent two-sample t-test (which IS",
      "the optimal test against exactly this Normal location-shift",
      "alternative) needs only n = 64/group -- the KS test's well-known",
      "efficiency loss against a plain mean shift, since it is a",
      "general-purpose omnibus test for ANY distributional difference,",
      "not one tuned to detect a location shift specifically.",
      sep = "\n"
    ),
    citation = paste(
      "Massey FJ Jr. The Kolmogorov-Smirnov test for goodness of fit.",
      "J Am Stat Assoc. 1951;46(253):68-78 (defines the two-sample KS",
      "test statistic; no general power formula is given there or",
      "anywhere else in the literature for an arbitrary alternative, which",
      "is why direct simulation -- as this app's own checklist recommends",
      "for this test -- is used here instead)."
    ),
    backend = "direct Monte Carlo simulation of stats::ks.test()"
  )
)
