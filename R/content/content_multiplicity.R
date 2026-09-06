# Metadata for the Multiplicity Adjustment module: formula text, plain-
# language explanation, worked example, and citation. Content is data,
# rendered generically by mod_multiplicity.R (SDD 4.2: "content is data,
# not hardcoded UI").

multiplicity_content <- list(
  overview = list(
    title = "Multiplicity-Adjusted Sample Size",
    formula_latex = paste0(
      "$$\\alpha_{Bonferroni} = \\frac{\\alpha}{m} \\qquad ",
      "\\alpha_{Sidak} = 1 - (1-\\alpha)^{1/m}$$"
    ),
    explanation = paste(
      "When a study plans several simultaneous hypothesis tests -- several",
      "outcome variables, several pairwise group comparisons, several",
      "subgroups -- testing each one at the usual alpha = 0.05 inflates the",
      "chance that at least one comes back \"significant\" purely by chance",
      "(the family-wise error rate, FWER). This calculator tightens the",
      "per-comparison alpha to control the FWER across all m planned",
      "comparisons, then re-runs one of this app's own already-verified",
      "one-sample/two-sample formulas with that tighter alpha -- \"wrap any",
      "calculator with alpha/m\".",
      "",
      "- **Bonferroni** (alpha/m) is the classic correction: always valid,",
      "  regardless of whether the m tests are independent or correlated.",
      "  It is somewhat conservative (larger required n) when the tests are",
      "  positively correlated.",
      "- **Sidak** (1 - (1-alpha)^(1/m)) is the exact FWER-controlling",
      "  correction when the m tests are independent -- slightly less",
      "  conservative than Bonferroni (a larger adjusted alpha, hence a",
      "  smaller n) for the same m.",
      "- **m** is the number of planned simultaneous comparisons.",
      "- **Base test** is which of this app's own formulas to re-run with",
      "  the adjusted alpha: a single proportion or mean against a",
      "  reference value, or two independent proportions or means.",
      "",
      "Holm's step-down procedure is not offered here as a separate option:",
      "its per-comparison threshold is data-dependent (it adapts to the",
      "observed p-values' rank order after the study is run), so there is",
      "no single a priori alpha to plan a sample size against. The",
      "worst-case (first, most conservative) step of Holm's procedure uses",
      "exactly the Bonferroni value alpha/m -- which is what a priori",
      "sample-size planning conservatively assumes.",
      "",
      "Note: if you are planning pairwise comparisons among all pairs of k",
      "group means or proportions specifically, the Means and Proportions",
      "modules each already have a dedicated \"Post-hoc pairwise comparison",
      "(Bonferroni-adjusted)\" design that additionally accounts for using a",
      "common pooled variance/proportion across all groups -- prefer that",
      "design for that specific case. This module is for the more general",
      "case of m arbitrary simultaneous comparisons (e.g. several distinct",
      "outcome variables), each analyzed as its own one- or two-sample test.",
      sep = "\n"
    ),
    worked_example = paste(
      "A trial plans to test m = 4 distinct outcome variables, each via a",
      "two-sample proportion comparison (p1 = 0.50 vs. p2 = 0.65), and",
      "wants to control the overall (family-wise) alpha at 0.05 using the",
      "Bonferroni correction. The per-comparison adjusted alpha is",
      "0.05 / 4 = 0.0125. Re-running the two-proportion formula",
      "(pwr::pwr.2p.test) at this tighter alpha (power = 0.80) gives",
      "n = 241/group (482 total) -- versus n = 170/group (340 total) at",
      "the unadjusted alpha = 0.05, confirming the expected inflation from",
      "correcting for 4 simultaneous tests.",
      sep = "\n"
    ),
    citation = paste(
      "Bonferroni CE. Teoria statistica delle classi e calcolo delle",
      "probabilita. Pubblicazioni del R Istituto Superiore di Scienze",
      "Economiche e Commerciali di Firenze. 1936;8:3-62. Sidak Z. Rectangular",
      "confidence regions for the means of multivariate normal",
      "distributions. J Am Stat Assoc. 1967;62(318):626-633. Holm S. A",
      "simple sequentially rejective multiple test procedure. Scand J Stat.",
      "1979;6(2):65-70. (as re-run through pwr::pwr.p.test /",
      "pwr::pwr.2p.test / pwr::pwr.t.test)."
    ),
    backend = "pwr::pwr.p.test() / pwr.2p.test() / pwr.t.test()"
  )
)
