# Metadata for the Exact Tests module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_exact_tests.R (SDD 4.2: "content is data, not
# hardcoded UI").

exact_tests_content <- list(
  binomial = list(
    title = "Binomial Test, Single Proportion (Exact)",
    formula_latex = paste0(
      "$$\\text{power} = \\sum_{x \\, : \\, p\\text{-value}(x) \\le \\alpha} \\binom{n}{x} p_1^x (1-p_1)^{n-x}$$"
    ),
    explanation = paste(
      "The proportion-testing counterpart of the Proportions module's",
      "\"single proportion vs. known/reference value\" design, but using",
      "the *exact* binomial distribution instead of the normal",
      "approximation -- more accurate for small samples or proportions",
      "near 0 or 1, where the approximation used elsewhere in this app can",
      "be unreliable.",
      "",
      "- **p0** - the reference/hypothesized proportion.",
      "- **p1** - the proportion you actually expect to find.",
      "- **alpha, power** - as elsewhere.",
      "",
      "This searches upward over n calling R's own `stats::binom.test()`",
      "at every candidate rather than a closed-form formula, because exact",
      "test power is a genuinely non-monotonic (\"sawtoothed\") function",
      "of n -- one more subject can occasionally *lower* achieved power",
      "before it recovers (Chernick & Liu 2002). To avoid recommending a",
      "fragile single-n spike, this requires power to stay at or above",
      "target for a couple of subsequent n values before accepting it.",
      sep = "\n"
    ),
    worked_example = paste(
      "Worked example: p0 = 0.10, p1 = 0.30 (a proportion three times the",
      "reference value). At alpha = 0.05 (two-sided) and 80% power, this",
      "calculator returns n = 25, with an achieved exact power of 0.8065 --",
      "and confirms n = 26 and n = 27 also clear 80% power, so n = 25",
      "isn't a fragile one-off peak (n = 21-24 and n = 28 alone would each",
      "have looked adequate or inadequate in isolation, illustrating the",
      "sawtooth).",
      sep = "\n"
    ),
    citation = paste(
      "Chernick MR, Liu CY. The Saw-Toothed Behavior of Power versus",
      "Sample Size and Software Solutions. Am Stat. 2002;56(2):149-155.",
      "(the non-monotonicity this calculator's stability check guards",
      "against; formula is R's own stats::binom.test)."
    ),
    backend = "stats::binom.test() (search over n; no additional package required)"
  ),

  fisher = list(
    title = "Fisher's Exact Test, Two Independent Proportions",
    formula_latex = paste0(
      "$$\\text{power computed by enumerating all } (n_1+1)(n_2+1) \\text{ tables}$$"
    ),
    explanation = paste(
      "The exact-test counterpart of the Proportions module's \"two",
      "independent proportions\" design -- appropriate for small samples,",
      "where Fisher's exact test is preferred over the chi-square/normal",
      "approximation.",
      "",
      "- **p1, p2** - the proportions expected in group 1 and group 2.",
      "- **alpha, power** - as elsewhere.",
      "- **ratio** - group 2 size divided by group 1 size (1 = equal",
      "  allocation).",
      "",
      "Like the binomial-test design above, this searches upward over n1",
      "(with n2 = ceiling(n1 x ratio)) rather than solving a closed-form",
      "equation, requiring power to stay at or above target for a couple",
      "of subsequent n1 values before accepting it, for the same",
      "sawtooth reason.",
      sep = "\n"
    ),
    worked_example = paste(
      "The Exact package's own documented example (p1 = 0.15, p2 = 0.60):",
      "at a 2:1 allocation ratio, alpha = 0.05 (two-sided) and 80% power,",
      "this calculator returns n1 = 14, n2 = 28 (n_total = 42), achieved",
      "power 0.8195. As a check on the underlying method: the package's",
      "own printed example at n1 = 15, n2 = 30 reports power = 0.8049 --",
      "reproduced exactly by Exact::power.exact.test(). (n1 = 14 clears",
      "80% power a step earlier than the package's illustrative n1 = 15 --",
      "a real instance of the sawtooth behavior described above, not a",
      "discrepancy.)",
      sep = "\n"
    ),
    citation = paste(
      "Calhoun P. Exact: Unconditional Exact Test. R package.; Chernick",
      "MR, Liu CY. The Saw-Toothed Behavior of Power versus Sample Size",
      "and Software Solutions. Am Stat. 2002;56(2):149-155."
    ),
    backend = "exact power over every 2x2 table, written from the definition of Fisher's test (equal to Exact::power.exact.test(method = \"fisher\"), checked over grids); search over n1; no package needed"
  ),

  boschloo = list(
    title = "Boschloo's Exact Test, Two Independent Proportions (Unconditional)",
    formula_latex = paste0(
      "$$\\text{power computed by maximizing the p-value over the unknown ",
      "nuisance parameter}$$"
    ),
    explanation = paste(
      "Boschloo's test is the classic \"unconditional\" exact test for two",
      "independent proportions -- unlike Fisher's exact test above (which",
      "conditions on the observed row/column margins), Boschloo's test",
      "maximizes the p-value over the unknown common success probability",
      "instead of conditioning it away. This makes it *uniformly at least",
      "as powerful* as Fisher's exact test (Boschloo 1970), at the cost of",
      "being somewhat more computationally intensive -- the standard",
      "recommendation when small-sample power matters more than",
      "familiarity.",
      "",
      "- **p1, p2** - the proportions expected in group 1 and group 2.",
      "- **alpha, power, ratio** - as in Fisher's exact test above.",
      "",
      "Same search strategy as Fisher's exact test above (searching",
      "upward over n1 with a stability check for the sawtooth effect),",
      "computed here in the same way as Fisher's (every 2x2 table,",
      "checked against the `Exact` package). Boschloo's own p-value",
      "calculation searches over a grid of nuisance-parameter values",
      "internally, so this design can take a few seconds to compute --",
      "noticeably slower than Fisher's exact test above, but still exact.",
      sep = "\n"
    ),
    worked_example = paste(
      "For p1 = 0.30, p2 = 0.60 at alpha = 0.05 (two-sided) and 80% power,",
      "this calculator returns n1 = 44 (88 total), versus n1 = 48 (96",
      "total) for Fisher's exact test on the identical inputs -- exactly",
      "the theoretical relationship the method is known for (Boschloo",
      "1970 proved Boschloo's test is never less powerful than Fisher's",
      "exact test for the same inputs), used here as the verification",
      "since no external printed worked example was available in this",
      "sandboxed session.",
      sep = "\n"
    ),
    citation = paste(
      "Boschloo RD. Raised Conditional Level of Significance for the",
      "2x2-table when Testing the Equality of Two Probabilities. Statist",
      "Neerlandica. 1970;24(1):1-35."
    ),
    backend = "exact power over every 2x2 table, written from the definition of Boschloo's test (equal to Exact::power.exact.test(method = \"boschloo\"), checked over grids); search over n1; no package needed"
  ),

  poisson = list(
    title = "Exact Poisson Test, Single Rate vs. a Reference/Standard Rate",
    formula_latex = paste0(
      "$$\\text{power} = \\sum_{x \\, : \\, p\\text{-value}(x) \\le \\alpha} ",
      "\\frac{e^{-\\lambda_1}\\lambda_1^x}{x!}, \\quad \\lambda_1 = \\text{rate}_1 \\times T$$"
    ),
    explanation = paste(
      "The one-sample, count-data counterpart of the Binomial Test design",
      "above -- use this to test whether an observed incidence rate",
      "differs from a known background/standard rate, using the exact",
      "Poisson distribution rather than a normal approximation. Typical",
      "use: \"is this population's disease rate different from the",
      "published national/standard rate?\"",
      "",
      "- **rate0 (reference/standard rate)** - the null-hypothesis rate,",
      "  in events per unit of person-time (e.g. per person-year).",
      "- **rate1 (expected/anticipated true rate)** - the rate you",
      "  actually expect to observe, same units as rate0.",
      "- **alpha, power** - as elsewhere.",
      "",
      "This searches upward over person-time T calling R's own",
      "`stats::poisson.test()` at every candidate rather than a",
      "closed-form formula, for exactly the same reason as the Binomial",
      "Test design: exact-test power is a non-monotonic (\"sawtoothed\")",
      "function of T (Chernick & Liu 2002), so this requires power to",
      "stay at or above target for a couple of subsequent T values before",
      "accepting it.",
      sep = "\n"
    ),
    worked_example = paste(
      "Worked example: a reference rate of 5 events per unit person-time,",
      "expecting a true rate of 10 (double the reference). At alpha =",
      "0.05 (two-sided) and 80% power, this calculator returns a required",
      "person-time of T = 3 (expecting 30 events), with an achieved exact",
      "power of 0.8854 -- independently confirmed by a 20,000-replicate",
      "Monte Carlo simulation (empirical power 0.8835, closely matching",
      "the exact value).",
      sep = "\n"
    ),
    citation = paste(
      "Exact Poisson test: R's own stats::poisson.test(); Chernick MR,",
      "Liu CY. The Saw-Toothed Behavior of Power versus Sample Size and",
      "Software Solutions. Am Stat. 2002;56(2):149-155 (the",
      "non-monotonicity this calculator's stability check guards",
      "against)."
    ),
    backend = "stats::poisson.test() (search over person-time; no additional package required)"
  ),

  sign_test = list(
    title = "Sign Test (Paired Data / One-Sample Median)",
    formula_latex = paste0(
      "$$\\text{power} = \\sum_{x \\, : \\, p\\text{-value}(x) \\le \\alpha} \\binom{n}{x} p_{\\text{pos}}^x (1-p_{\\text{pos}})^{n-x}, ",
      "\\quad p_0 = 0.5$$"
    ),
    explanation = paste(
      "Use this to test whether paired differences (e.g. before-after",
      "measurements) tend to be positive more often than negative -- or,",
      "for a single sample, whether values tend to fall above a",
      "hypothesized median -- without assuming a symmetric distribution",
      "of differences (unlike the Wilcoxon signed-rank test in the",
      "Nonparametric Tests module, which does assume symmetry).",
      "",
      "- **p_pos** - the proportion of pairs you expect to show a",
      "  positive difference (or values above the hypothesized median);",
      "  must differ from 0.5, the null value.",
      "- **alpha, power** - as elsewhere.",
      "",
      "The sign test only looks at the *direction* of each pair's",
      "difference, discarding its magnitude -- which is exactly a binomial",
      "test of whether the proportion of positive differences equals 0.5.",
      "This calculator is the Binomial Test design above with the",
      "reference proportion fixed at 0.5, so it inherits the same",
      "exact-enumeration search over n (and the same sawtooth caveat --",
      "see the Binomial Test explanation).",
      sep = "\n"
    ),
    worked_example = paste(
      "Worked example: expecting 70% of pairs to show a positive",
      "difference (p_pos = 0.7). At alpha = 0.05 (two-sided) and 80%",
      "power, this calculator returns n = 54, with an achieved exact",
      "power of 0.8368 -- computed by the same verified",
      "stats::binom.test()-based search as the Binomial Test design",
      "above, just with p0 fixed at 0.5.",
      sep = "\n"
    ),
    citation = paste(
      "Conover WJ. Practical Nonparametric Statistics. 3rd ed. Wiley;",
      "1999. Chapter 3.4 (the sign test as a binomial test)."
    ),
    backend = "stats::binom.test() (search over n; same engine as the Binomial Test design, p0 fixed at 0.5)"
  )
)
