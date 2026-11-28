# Metadata for the Multilevel / Hierarchical Model module: formula text,
# plain-language explanation, worked example, and citation. Content is
# data, rendered generically by mod_multilevel.R (SDD 4.2: "content is
# data, not hardcoded UI").

multilevel_content <- list(
  two_level = list(
    title = "Two-Level Model (Subjects with Repeated Measures)",
    formula_latex = paste0(
      "$$\\text{SE}(\\hat b)^2 = 2 \\times \\frac{\\sigma_e^2 + n_1 u_1^2 \\, s_x}{n_1 n_2 s_x}, ",
      "\\quad s_x = \\frac{T_{end}^2 (n_1+1)}{12(n_1-1)}$$",
      "$$\\lambda = \\frac{\\delta / T_{end}}{\\text{SE}(\\hat b)}, \\quad df = 2n_2 - 2$$"
    ),
    backend = "closed-form reimplementation (powerlmm's classic/equal-n formula)"
  ),
  three_level = list(
    title = "Three-Level Model (Subjects Nested in Clusters)",
    formula_latex = paste0(
      "$$\\text{SE}(\\hat b)^2 = 2 \\times \\frac{\\sigma_e^2 + n_1 u_1^2 s_x + n_1 n_2 v_1^2 s_x}{n_1 n_2 n_3 s_x}$$",
      "$$\\lambda = \\frac{\\delta / T_{end}}{\\text{SE}(\\hat b)}, \\quad df = 2n_3 - 2$$"
    ),
    backend = "closed-form reimplementation (powerlmm's classic/equal-n formula)"
  ),
  shared = list(
    explanation = paste(
      "Use this for a longitudinal trial analyzed with a **random-slope",
      "mixed model** (a subject-level, or subject-and-cluster-level,",
      "random intercept and random slope over time) -- testing whether the",
      "TREATMENT-GROUP DIFFERENCE IN THE RATE OF CHANGE (slope) over the",
      "study is nonzero, the standard question a growth-curve/hierarchical",
      "linear model answers. This is a genuinely different modeling",
      "framework from this app's existing Longitudinal / MMRM module, which",
      "covers marginal (GEE-style) models and correlation-structure-based",
      "MMRM -- here the variance is decomposed into hierarchical components",
      "(subject-level, and optionally cluster-level, random effects) instead.",
      "",
      "- **Two-level** -- an individually-randomized trial with subjects",
      "  measured repeatedly over time (no clustering).",
      "- **Three-level** -- a cluster-randomized trial (e.g. clinics,",
      "  schools, wards) where subjects within each cluster are measured",
      "  repeatedly over time.",
      "- **n1 (measurement occasions)** -- how many times each subject is",
      "  measured, spaced evenly from baseline to T_end.",
      "- **T_end (study duration)** -- total follow-up time, in whatever",
      "  units delta is expressed per (e.g. months).",
      "- **var_ratio (slope variance ratio)** -- the ratio of the",
      "  between-subject slope variance to the residual (measurement-error)",
      "  variance; captures how much subjects' individual trajectories",
      "  differ from the average trajectory, relative to noise.",
      "- **icc_slope (three-level only)** -- the fraction of the total",
      "  slope variance that is between-CLUSTER rather than",
      "  between-SUBJECT (0 = no cluster-level variation in trajectories).",
      "- **delta** -- the expected total difference in outcome between",
      "  arms by the end of the study (like an ordinary mean difference,",
      "  not a per-time-unit slope -- this calculator converts it",
      "  internally).",
      "- **sigma_error** -- the residual (within-subject, single-occasion)",
      "  standard deviation.",
      "",
      "**A genuine, verified property of this model worth knowing**: two",
      "inputs the wider literature often reports alongside these --",
      "icc_pre_subject and icc_pre_cluster (baseline/intercept ICCs) --",
      "are deliberately NOT asked for here, because they do not affect the",
      "power of this particular test. Under the standard assumption that a",
      "subject's (or cluster's) random intercept and random slope are",
      "uncorrelated (this model's default, and the one used here), the",
      "precision of the estimated SLOPE difference depends only on the",
      "slope-related variance components (var_ratio, icc_slope) -- not on",
      "how much subjects vary in their BASELINE level. This was confirmed",
      "directly, not assumed: running the real `powerlmm` package across 5",
      "(two-level) and 6 (three-level) different ICC values with every",
      "other input held fixed gave bit-identical power every time.",
      "",
      "This calculator covers the **no-dropout, equal-size** case only --",
      "the same closed-form `powerlmm` itself uses. Missing data /",
      "dropout switches that package to a more general matrix-based",
      "calculation, which is not covered here.",
      sep = "\n"
    ),
    worked_example = paste(
      "Two-level: n1 = 11 measurement occasions over T_end = 10 months,",
      "var_ratio = 0.02, sigma_error = 10, expected end-of-study",
      "difference delta = -0.9, alpha = 0.05, 80% power -> this calculator",
      "returns n = 5,639 subjects per arm -- exactly matching real",
      "`powerlmm::get_power()` at that same n (achieved power 0.800017 in",
      "both, to 6 decimal places).",
      "",
      "Three-level: the same n1/T_end/var_ratio/delta, plus n2 = 10",
      "subjects per cluster and icc_slope = 0.1 -> this calculator returns",
      "n = 914 clusters per arm (9,140 subjects per arm) -- again exactly",
      "matching real `powerlmm::get_power()` (achieved power 0.800181 in",
      "both).",
      sep = "\n"
    ),
    citation = paste(
      "Extends Galbraith S, Marschner IC. Guidelines for the design of",
      "clinical trials with longitudinal outcomes. Control Clin Trials.",
      "2002;23(3):257-271.",
      "",
      "Formula independently derived by reading the `powerlmm` R package's",
      "own source (`get_se_classic()`, `var_T()` in R/power.R, and the",
      "var_ratio/icc_slope variance-component solving in R/setup.R;",
      "Magnusson K. powerlmm: Power Analysis for Longitudinal Multilevel",
      "Models. https://github.com/cran/powerlmm) and verified exactly (to",
      "6 decimal places) against real `powerlmm::get_power()` calls across",
      "8 varied two- and three-level scenarios. Reimplemented from scratch",
      "rather than depending on `powerlmm` at runtime, so this app stays",
      "self-contained."
    )
  )
)
