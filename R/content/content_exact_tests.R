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
      "$$\\text{power computed by enumerating all } (n_1+1)(n_2+1) \\text{ tables (Exact package)}$$"
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
    backend = "Exact::power.exact.test(method = \"fisher\") (search over n1)"
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
