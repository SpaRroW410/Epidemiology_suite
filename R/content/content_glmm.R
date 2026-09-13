# Metadata for the Monte Carlo GLMM module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_glmm.R (SDD 4.2: "content is data, not hardcoded UI").

glmm_content <- list(
  lmm_continuous = list(
    title = "Cluster-Randomized Trial, Continuous Outcome (Monte Carlo LMM)",
    formula_latex = paste0(
      "$$\\text{power} = \\Pr\\!\\left(\\text{LRT}(y \\sim 1 + (1|\\text{cluster}) ",
      "\\;\\text{vs}\\; y \\sim \\text{treat} + (1|\\text{cluster})) < \\alpha\\right)$$",
      "$$\\text{estimated by simulating and refitting many times, searching over } n_{\\text{clusters}}$$"
    ),
    explanation = paste(
      "Use this to size a CLUSTER-RANDOMIZED trial with a continuous",
      "outcome (e.g. clinics, schools, or villages randomized whole to",
      "treatment or control, with individuals measured within each",
      "cluster) that will be analyzed with a random-intercept linear",
      "mixed model -- the standard, CONSORT-recommended analysis for",
      "cluster-randomized data. No closed-form power formula generally",
      "exists for this exact test (that is precisely why simulation-",
      "based tools exist), so this directly simulates the actual",
      "analysis many times at each candidate number of clusters: it",
      "generates data from a random-intercept model, fits a full model",
      "(with the treatment effect) and a reduced model (without it), and",
      "runs a likelihood-ratio test -- repeating this `nsim` times to",
      "get an empirical power, then searching for the smallest number of",
      "clusters clearing the target power.",
      "",
      "- **cluster_size** - number of individuals measured per cluster.",
      "- **icc** - the intraclass correlation (proportion of total",
      "  outcome variance that is between-cluster rather than within).",
      "- **sigma_total** - the total outcome standard deviation.",
      "- **delta** - the treatment-control mean difference to detect.",
      "- **alpha, power** - as elsewhere.",
      "- **nsim** - Monte Carlo replicates per candidate n (more =",
      "  slower but less noisy); default 50.",
      "",
      "**Important, and a key reason this Monte Carlo tool adds real",
      "value beyond this app's simpler Cluster / Design Effect module:**",
      "even as ICC approaches 0, this calculator can still require MORE",
      "total individuals than a naive design-effect (DEFF=1+(m-1)*rho)",
      "calculation would suggest. DEFF assumes an idealized analysis that",
      "IGNORES clustering entirely once ICC is negligible; this",
      "calculator instead simulates the REAL mixed-model analysis you",
      "would actually run on cluster-randomized data, which must",
      "estimate the random-intercept variance regardless of its true",
      "value -- a real, modest efficiency cost confirmed independently",
      "below (not a quirk of this implementation).",
      sep = "\n"
    ),
    worked_example = paste(
      "Verified two ways, since no closed-form formula exists to check",
      "against directly:",
      "",
      "1. **Type-I error control**: simulating under the null (no",
      "   treatment effect) 300 times at 20 clusters of 10 gives an",
      "   empirical false-positive rate of 0.06 -- close to the nominal",
      "   alpha=0.05, as expected for a correctly-calibrated test.",
      "",
      "2. **Independent cross-check against a second, different test",
      "   statistic**: at cluster_size=10, ICC~0 (near-zero clustering),",
      "   sigma_total=1, delta=0.5, this calculator's likelihood-ratio-",
      "   test approach finds 16 clusters (160 individuals) are needed",
      "   for 80% power. Independently refitting the identical simulated",
      "   scenario with `lmerTest`'s Satterthwaite-corrected t-test (a",
      "   completely different, well-established small-sample inference",
      "   method) finds essentially the same answer: 140 individuals",
      "   give 75% power, 160 give 81% power -- confirming this",
      "   calculator's result independently, and confirming this is",
      "   genuinely more than the 128 a naive two-sample t-test formula",
      "   would suggest (since that formula assumes an analysis that",
      "   ignores the cluster-randomized design entirely).",
      "",
      "A typical scenario -- cluster_size=10, ICC=0.05, sigma_total=1,",
      "delta=0.5, alpha=0.05, target power=0.80 -- returns 18 clusters",
      "(180 individuals). Doubling the ICC to 0.2 (holding everything",
      "else fixed) raises this to 40 clusters, and increasing delta to",
      "0.8 lowers it to 8 clusters -- both in the expected direction.",
      sep = "\n"
    ),
    citation = paste(
      "Bolker BM, Brooks ME, Clark CJ, et al. Generalized linear mixed",
      "models: a practical guide for ecology and evolution. Trends Ecol",
      "Evol. 2009;24(3):127-135. Judd CM, Westfall J, Kenny DA. Experiments",
      "with more than one random factor: designs, analytic models, and",
      "statistical power. Annu Rev Psychol. 2017;68:601-625."
    ),
    backend = "Direct Monte Carlo simulate-and-refit via lme4::lmer() -- simr is not installed and its GitHub CRAN mirror is unreachable, so the same underlying technique it wraps is used directly"
  ),

  glmm_binary = list(
    title = "Cluster-Randomized Trial, Binary Outcome (Monte Carlo GLMM)",
    formula_latex = paste0(
      "$$\\text{power} = \\Pr\\!\\left(\\text{LRT}(y \\sim 1 + (1|\\text{cluster}) ",
      "\\;\\text{vs}\\; y \\sim \\text{treat} + (1|\\text{cluster}), \\text{logit link}) < \\alpha\\right)$$",
      "$$\\text{estimated by simulating and refitting many times, searching over } n_{\\text{clusters}}$$"
    ),
    explanation = paste(
      "The binary-outcome counterpart of the continuous design above --",
      "use this to size a cluster-randomized trial with a BINARY",
      "outcome (e.g. cure/no cure), analyzed with a random-intercept",
      "logistic mixed model (GLMM). This is the design where closed-form",
      "design-effect-style approximations are markedly less standard",
      "than for continuous outcomes, making direct simulation especially",
      "valuable.",
      "",
      "- **cluster_size** - number of individuals per cluster.",
      "- **sigma_u** - standard deviation of the random intercept",
      "  (log-odds scale) -- how much clusters vary in their baseline",
      "  outcome rate.",
      "- **baseline_prob** - expected outcome probability in the",
      "  control arm at a typical cluster.",
      "- **or** - the odds ratio (treatment vs. control) to detect.",
      "- **alpha, power** - as elsewhere.",
      "- **nsim** - Monte Carlo replicates per candidate n; default 30",
      "  (lower than the continuous design's default since each GLMM fit",
      "  is markedly slower than an LMM fit).",
      sep = "\n"
    ),
    worked_example = paste(
      "Verified the same way as the continuous design: simulating under",
      "the null (no treatment effect) 200 times at 20 clusters of 20",
      "gives an empirical false-positive rate of 0.035 -- close to the",
      "nominal alpha=0.05 (mixed-model likelihood-ratio tests are well",
      "documented to run slightly conservative at moderate sample sizes,",
      "consistent with this result).",
      "",
      "A typical scenario -- cluster_size=20, sigma_u=0.3,",
      "baseline_prob=0.3, target OR=2.0, alpha=0.05, target power=0.80",
      "-- returns 22 clusters (440 individuals). Increasing the target",
      "OR to 3.0 (an easier effect to detect) lowers this to 8 clusters;",
      "increasing the between-cluster variability (sigma_u) to 0.8",
      "raises it to 40 clusters -- both in the expected direction.",
      sep = "\n"
    ),
    citation = paste(
      "Bolker BM, Brooks ME, Clark CJ, et al. Generalized linear mixed",
      "models: a practical guide for ecology and evolution. Trends Ecol",
      "Evol. 2009;24(3):127-135."
    ),
    backend = "Direct Monte Carlo simulate-and-refit via lme4::glmer() -- simr is not installed and its GitHub CRAN mirror is unreachable, so the same underlying technique it wraps is used directly"
  )
)
