# Metadata for the Crossover Trial (2x2) module: formula text,
# plain-language explanation, worked example, and citation. Content is
# data, rendered generically by mod_crossover.R (SDD 4.2: "content is
# data, not hardcoded UI").

crossover_content <- list(
  crossover_2x2 = list(
    title = "2x2 Crossover Trial (Continuous Outcome) -- Test for a Difference",
    formula_latex = paste0(
      "$$n_{sequence} = \\frac{\\left(Z_{1-\\alpha/2}+Z_{1-\\beta}\\right)^2\\sigma^2}",
      "{2\\delta^2}, \\qquad n_{total} = 2\\,n_{sequence}$$"
    ),
    explanation = paste(
      "Use this for a **2x2 crossover trial** with a continuous outcome,",
      "testing whether two treatments differ in their mean effect (not an",
      "equivalence/non-inferiority test -- for that, see the Equivalence",
      "(TOST) module). Subjects are randomized to one of two sequences",
      "(treatment A then B, or B then A, each separated by a washout",
      "period long enough to eliminate carryover), so each subject acts",
      "as their own control.",
      "",
      "- **delta** - the true mean difference you want to be able to",
      "  detect (test minus control).",
      "- **sigma** - the *within-subject* standard deviation in the",
      "  crossover design (how much an individual subject's response",
      "  varies between periods, absent any treatment effect) -- not the",
      "  between-subject SD you'd use for a parallel-group trial. Because",
      "  each subject is compared to themselves, this is usually much",
      "  smaller, which is exactly why crossover designs need far fewer",
      "  subjects than a parallel-group trial of the same size effect.",
      "- **alpha, power** - as elsewhere (two-sided test).",
      "",
      "n_sequence is the number of subjects needed in EACH of the two",
      "sequences; the total trial enrollment is twice that (equal",
      "allocation across the two sequences).",
      sep = "\n"
    ),
    worked_example = paste(
      "Using this calculator's own formula/backend directly: a",
      "within-subject SD of sigma = 0.4, targeting a detectable",
      "difference of delta = 0.2, with alpha = 0.05 (two-sided) and 80%",
      "power, gives n = 15.7 per sequence -> 16 per sequence (32 total).",
      "This reproduces `TrialSize::TwoSampleCrossOver.Equality()`'s output",
      "exactly for these inputs.",
      sep = "\n"
    ),
    citation = "Chow SC, Shao J, Wang H. Sample Size Calculations in Clinical Research. New York: Marcel Dekker; 2003. Chapter 3.",
    backend = "closed form written out in the app, equal to TrialSize::TwoSampleCrossOver.Equality() (compared with the package in the tests; the package is not a dependency)"
  )
)
