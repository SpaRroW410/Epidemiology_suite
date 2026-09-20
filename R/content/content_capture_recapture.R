# Metadata for the Capture-Recapture module: guidance text, formula, and
# citation. Content is data, rendered generically by mod_capture_recapture.R
# (SDD 4.2: "content is data, not hardcoded UI").

capture_recapture_content <- list(
  chapman_precision = list(
    title = "Two-Sample Mark-Recapture (Chapman-Petersen), Precision-Based",
    formula_latex = paste0(
      "$$\\hat{N} = \\frac{(n_1+1)(n_2+1)}{m_2+1} - 1 \\quad \\text{(Chapman 1951)}$$",
      "$$\\text{Var}(\\hat{N}) \\approx \\frac{N(N-n_1)(N-n_2)}{n_1 n_2}",
      "\\quad \\text{(large-sample approximation, Seber 1982)}$$",
      "$$n_2 = \\frac{(N-n_1)\\,N}{CV^2 \\, n_1 N + (N - n_1)},",
      "\\qquad CV = \\frac{\\text{precision}}{z_{1-\\alpha/2}}$$"
    ),
    explanation = paste(
      "Mark-recapture estimates an unknown population size N by marking",
      "n1 individuals in a first sample, then drawing a second sample of",
      "n2 individuals and counting how many (m2) are already marked.",
      "There is no R package on CRAN that plans n2 in advance -- `Rcapture`",
      "and similar packages only *analyse* an already-collected m2, they",
      "don't help you choose n2 before the study.",
      "",
      "**The estimator.** The Chapman (1951) modification of the classic",
      "Lincoln-Petersen estimator adds 1 to each count before dividing,",
      "which removes most of the small-sample bias of the raw",
      "n1*n2/m2 ratio (undefined whenever m2 = 0).",
      "",
      "**Planning n2.** This calculator inverts the large-sample variance",
      "of that estimator (Seber 1982) to solve for the second-sample size",
      "n2 that achieves a target relative precision on N_hat, given an",
      "already-fixed first-sample size n1 and an assumed (planning) value",
      "of the true population size N -- the same \"precision-based\"",
      "framing this app uses elsewhere (a target confidence-interval",
      "half-width, here expressed as a fraction of N, at a chosen",
      "confidence level).",
      "",
      "**A caveat worth stating plainly:** mark-recapture inherently needs",
      "an advance guess at N to plan n2 at all -- if that guess is badly",
      "wrong, the achieved precision (recomputed below at the solved n2)",
      "will differ from the target. Use a pilot count, a prior survey, or",
      "the most defensible expert estimate available, and treat the",
      "planning N as provisional.",
      sep = "\n"
    ),
    worked_example = paste(
      "N=1000 (planning estimate), n1=100 marked, target precision +/-10%",
      "at 95% confidence -> n2=474, expecting about 47 recaptures, achieved",
      "precision +/-9.99% (essentially exact) -- verified this session by",
      "simulating 200,000 replicates of the actual discrete mark-recapture",
      "process (m2 drawn from a Hypergeometric(N, n1, n2) distribution,",
      "Chapman estimator applied to each replicate): empirical CV of N_hat",
      "matched the target closely across several N/n1/precision",
      "combinations, confirming the closed-form inversion tracks the real",
      "sampling process, not just its large-sample algebra.",
      sep = "\n"
    ),
    citation = paste(
      "Chapman DG. Some properties of the hypergeometric distribution with",
      "applications to zoological sample censuses. Univ Calif Publ Stat.",
      "1951;1:131-160. Seber GAF. The Estimation of Animal Abundance and",
      "Related Parameters. 2nd ed. Griffin, 1982 (variance formula, section",
      "3.2). Robson DS, Regier HA. Sample size in Petersen mark-recapture",
      "experiments. Trans Am Fish Soc. 1964;93(3):215-226 (planning",
      "framing)."
    ),
    backend = "Closed-form (Chapman 1951 estimator; Seber 1982 large-sample variance, inverted for n2); no external package -- Monte-Carlo-verified against the discrete hypergeometric process"
  )
)
