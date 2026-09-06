# Metadata for the Bayesian Assurance module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_bayesian.R (SDD 4.2: "content is data, not hardcoded
# UI").

bayesian_content <- list(
  assurance_or = list(
    title = "Bayesian Assurance for a Two-Arm Proportions Trial (Log Odds Ratio)",
    formula_latex = paste0(
      "$$\\text{assurance} = \\int \\Pr\\!\\big(\\text{CI}_{1-\\alpha}(\\delta) \\text{ excludes } \\delta_w \\mid \\delta\\big)\\, ",
      "\\pi(\\delta)\\, d\\delta$$",
      "$$\\text{Var}(\\hat\\delta) \\approx \\frac{1}{n_1 p_1(1-p_1)} + \\frac{1}{n_2 p_2(1-p_2)}$$"
    ),
    explanation = paste(
      "Ordinary power analysis fixes the true treatment effect at one",
      "assumed value and asks for the probability of a significant",
      "result given THAT value. **Assurance** (also called Bayesian",
      "prior-averaged power) instead places a probability distribution",
      "-- a prior -- on the unknown true effect (here, the log odds",
      "ratio, delta) and reports the probability that the trial will",
      "produce a 1-alpha confidence/credible interval for delta lying",
      "entirely above a minimally-worthwhile value delta_w, AVERAGED over",
      "that prior. This is more honest than ordinary power when the true",
      "effect is itself uncertain (e.g. based on a small pilot study or",
      "expert opinion) rather than known with confidence.",
      "",
      "- **p1, p2** - anticipated response probabilities in the two arms,",
      "  used only to compute the sampling variance of the log odds",
      "  ratio (not the effect size itself, which comes from the prior).",
      "- **Prior type** - either a single Normal distribution on the log",
      "  odds ratio (mean + SD), or a Uniform distribution (lower/upper",
      "  bounds) -- both accepted directly by the underlying function,",
      "  which in general allows ANY prior density.",
      "- **delta_w** - the minimally worthwhile log odds ratio (0 by",
      "  default: any true improvement at all counts as success).",
      "- **n_ratio** - allocation ratio n2/n1 (1 = equal arms).",
      "- **alpha, power** - alpha is the two-sided significance level for",
      "  the interval; power here is the TARGET assurance to solve for n.",
      sep = "\n"
    ),
    worked_example = paste(
      "Reproducing `Hmisc::gbayes2()`'s own documentation example exactly:",
      "p1 = p2 = 0.3, a Uniform(log(1.2), log(1.3)) prior on the log odds",
      "ratio, delta_w = 0 (the default null), equal allocation, alpha =",
      "0.05, target assurance = 0.90. The package's own example code runs",
      "`uniroot()` on this exact setup and finds n = 2,119.7 per arm; this",
      "calculator returns n1 = n2 = 2,120 per arm (4,240 total), matching",
      "to within rounding. A second documented example -- a 50:50 mixture",
      "of a vague N(0, 100^2) prior and an informative N(1, 1) prior,",
      "evaluated (not solved for n) at n1=500/n2=300 with a fixed",
      "variance -- reproduces the package's own printed assurance value",
      "of 0.6133338 exactly when called directly with the same inputs",
      "(the mixture-prior case isn't exposed in this app's simplified",
      "two-shape UI, but validates the same underlying `gbayes2()` call).",
      sep = "\n"
    ),
    citation = paste(
      "Spiegelhalter DJ, Freedman LS. A predictive approach to selecting",
      "the size of a clinical trial, based on subjective clinical",
      "opinion. Stat Med. 1986;5(1):1-13."
    ),
    backend = "Hmisc::gbayes2()"
  )
)
