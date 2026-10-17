# Metadata for the Bayesian Design Analysis module: formula text,
# plain-language explanation, worked example, and citation. Content is
# data, rendered generically by mod_bayesian.R (SDD 4.2: "content is
# data, not hardcoded UI").

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
    backend = "closed-form integral (Spiegelhalter, Abrams & Myles 2004); identical to Hmisc::gbayes2(), which it is tested against"
  ),
  bfda = list(
    title = "Bayes Factor Design Analysis, Two-Sample Means",
    formula_latex = paste0(
      "$$\\widehat{\\Pr}(\\text{BF}_{10} > \\tau) = \\frac{1}{R}\\sum_{r=1}^{R} \\mathbb{1}",
      "\\left[\\text{BF}_{10}(X_r, Y_r) > \\tau\\right]$$",
      "$$\\text{BF}_{10} = \\text{JZS default Bayesian } t\\text{-test ",
      "(Rouder et al. 2009), Cauchy prior on effect size}$$"
    ),
    explanation = paste(
      "Ordinary power analysis asks: what sample size gives X% probability",
      "of a significant p-value? Bayes Factor Design Analysis (BFDA) asks",
      "a genuinely different question: what sample size gives X%",
      "probability that the actual Bayes factor (BF10, comparing the",
      "alternative to the null) will exceed a chosen EVIDENCE threshold",
      "-- e.g. BF10 > 10, conventionally \"strong evidence\" (Jeffreys",
      "1961; Lee & Wagenmakers 2013). Unlike a p-value threshold, BF10",
      "measures the relative support the data give the alternative",
      "over the null, and larger values represent stronger evidence",
      "rather than a fixed pass/fail cutoff.",
      "",
      "BFDA has NO closed form by design -- the method invented by",
      "Schoenbrodt & Wagenmakers (2018) IS direct simulation, exactly the",
      "same situation this app's own checklist names \"simulation",
      "(`simr`/custom Monte Carlo)\" for elsewhere. This computes",
      "the JZS (Jeffreys-Zellner-Siow) default Bayes factor of the",
      "Bayesian t-test of Rouder et al. (2009) -- a closed-form integral, equal to",
      "`BayesFactor::ttestBF()` and checked against it -- using a Cauchy prior on",
      "the standardized effect size -- and repeatedly simulates two-group",
      "data at the assumed Cohen's d, counting the fraction of replicates",
      "whose Bayes factor exceeds the chosen threshold.",
      "",
      "- **effect_size** - Cohen's d between the two groups.",
      "- **bf_threshold** - the Bayes factor value counted as \"compelling",
      "  evidence\" (3 = \"moderate,\" 10 = \"strong,\" the two conventional",
      "  benchmarks).",
      "- **alpha** - used ONLY to compute a classical two-sample t-test n",
      "  as a search warm-start (`pwr::pwr.t.test()`); it has no direct",
      "  role in the Bayesian calculation itself.",
      "- **power** - the target probability that BF10 exceeds the",
      "  threshold.",
      "- **nsim** - simulated datasets per candidate n while searching;",
      "  this design's default nsim is lower than for the other simulated",
      "  designs (it was chosen when the Bayes factor came from a slower",
      "  package) and the search is warm-started from the classical n to",
      "  keep the overall search time reasonable.",
      sep = "\n"
    ),
    worked_example = paste(
      "A medium effect (Cohen's d = 0.5), targeting 80% probability of",
      "reaching \"strong\" evidence (BF10 > 10), nsim = 100: this",
      "calculator returns n = 129/group (258 total), versus only n = 64/",
      "group for the classical two-sample t-test at the same d/alpha/",
      "power -- BFDA needing roughly double the classical n to reach a",
      "stringent evidence threshold is the expected, well-documented",
      "direction (Schoenbrodt & Wagenmakers 2018's own simulations show",
      "the same pattern). Independently confirmed by a separate,",
      "larger-nsim simulation: at n=129, a 400-replicate check gives",
      "P(BF10 > 10) = 0.835 (matching the 0.80 target, on the",
      "conservative/higher side as expected from Monte Carlo search",
      "noise); at n=110, the same check gives only 0.75, confirming n=129",
      "is a genuine, non-arbitrary crossing point rather than noise.",
      sep = "\n"
    ),
    citation = paste(
      "Schoenbrodt FD, Wagenmakers EJ. Bayes factor design analysis:",
      "planning for compelling evidence. Psychon Bull Rev.",
      "2018;25(1):128-142 (defines BFDA and its simulation-based",
      "methodology, the checklist's own named approach for this item).",
      "Rouder JN, Speckman PL, Sun D, Morey RD, Iverson G. Bayesian t",
      "tests for accepting and rejecting the null hypothesis. Psychon",
      "Bull Rev. 2009;16(2):225-237 (the JZS default Bayesian t-test",
      "as implemented by BayesFactor::ttestBF(); here recomputed in closed form)."
    ),
    backend = "direct Monte Carlo simulation of the JZS two-sample Bayes factor (closed-form integral, Rouder et al. 2009; identical to BayesFactor::ttestBF(), which it is tested against)"
  )
)
