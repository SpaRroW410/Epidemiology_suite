# Metadata for the Longitudinal Slope Difference module: formula text,
# plain-language explanation, worked example, and citation. Content is
# data, rendered generically by mod_longitudinal.R (SDD 4.2: "content is
# data, not hardcoded UI").

longitudinal_content <- list(
  slope_diff = list(
    title = "Longitudinal Group-Slope-Difference Test (Liu & Liang GEE/GLS Method)",
    formula_latex = paste0(
      "$$N = \\frac{\\left(Z_{1-\\alpha/2} + Z_{power}\\right)^2}{\\delta^2 \\Sigma_1}, ",
      "\\quad \\Sigma_1 \\text{ from the GLS/GEE information matrix}$$",
      "$$R_{jk} = \\sigma^2_{\\text{intercept}} + t_j t_k \\sigma^2_{\\text{slope}} + ",
      "(t_j+t_k)\\,\\text{Cov}(\\text{intercept},\\text{slope}) + \\sigma^2_{\\text{residual}}\\mathbb{1}[j=k]$$"
    ),
    explanation = paste(
      "Many longitudinal trials (e.g. tracking cognitive decline,",
      "biomarker trajectories, or lung function over repeated visits)",
      "test whether two groups' RATE OF CHANGE over time (slope) differs",
      "-- not just their level at one time point. Liu & Liang (1997)",
      "give a general GLS/GEE-style sample-size method for testing a",
      "linear contrast in a correlated-observations model; this",
      "calculator applies it to its single most common use: comparing",
      "two groups' linear slopes under a random-intercept + random-",
      "slope + residual-error covariance structure (the standard linear",
      "mixed model for longitudinal data).",
      "",
      "- **visit_times** - the time (e.g. in years or months) of each",
      "  planned repeated measurement.",
      "- **delta** - the between-group difference in slope (rate of",
      "  change per unit time) you want to detect.",
      "- **sigma2_intercept, sigma2_slope** - the variance of each",
      "  subject's random intercept and random slope (how much subjects",
      "  vary in their baseline level and their rate of change).",
      "- **cov_intercept_slope** - the covariance between a subject's",
      "  random intercept and random slope.",
      "- **sigma2_residual** - the residual (within-subject,",
      "  measurement-to-measurement) error variance.",
      "- **allocation1** - the proportion of subjects in group 1.",
      "- **alpha, power** - as elsewhere.",
      sep = "\n"
    ),
    worked_example = paste(
      "`longpower` (the checklist's named package for GEE-based",
      "longitudinal tests) is not installable from CRAN in this sandbox",
      "(no network access); `liu.liang.linear.power()` -- a single,",
      "self-contained function with no cross-file dependencies -- was",
      "read directly from its public GitHub CRAN mirror and",
      "reimplemented. Verified by reproducing the function's own",
      "documented Alzheimer's-disease example exactly: 7 visits from",
      "0 to 1.5 years (0, 0.25, ..., 1.5), slope difference to detect =",
      "1.5, random-intercept variance = 55, random-slope variance = 24,",
      "intercept-slope correlation = 0.8 (covariance = 0.8*sqrt(55*24)",
      "= 30.79), residual variance = 10, alpha = 0.05, target power =",
      "0.80: this calculator gives N = 415 total (208/arm), matching",
      "the package's own vignette statement -- \"the study would",
      "require about 207 subjects per arm\" -- to within rounding",
      "(raw N = 414.62, 207.31/arm, identical to this calculator's",
      "unrounded computation).",
      sep = "\n"
    ),
    citation = paste(
      "Liu G, Liang KY. Sample size calculations for studies with",
      "correlated observations. Biometrics. 1997;53(3):937-947."
    ),
    backend = "closed-form reimplementation of longpower::liu.liang.linear.power()"
  ),

  mmrm_ar1 = list(
    title = "Mixed Model of Repeated Measures (MMRM) with Dropout, AR(1) Correlation",
    formula_latex = paste0(
      "$$\\phi_g = \\frac{1}{r_{g,J}} - \\sum_{j=1}^{J-1} \\rho^{2(t_J - t_j)} ",
      "\\left(\\frac{1}{r_{g,j+1}} - \\frac{1}{r_{g,j}}\\right)$$",
      "$$N_1 = \\big(\\phi_1 + \\lambda\\phi_2\\big)\\frac{\\big(Z_{1-\\alpha/2}+Z_{power}\\big)^2\\sigma^2}",
      "{\\delta^2}, \\quad N_2 = N_1/\\lambda$$"
    ),
    explanation = paste(
      "Comparing two arms' mean outcome at a trial's endpoint (or",
      "another single contrast) using all the REPEATED, possibly",
      "incomplete, measurements collected along the way -- the standard",
      "MMRM (mixed model of repeated measures) analysis used to handle",
      "dropout in longitudinal trials without discarding partially-",
      "observed subjects. This design assumes an AR(1) correlation",
      "structure between visits (correlation between visits j and k is",
      "rho^(2*|t_j - t_k|)) and lets each arm have its own dropout",
      "(retention) pattern over time.",
      "",
      "- **rho** - the AR(1) correlation between adjacent visits.",
      "- **ra, rb** - each arm's CUMULATIVE retention proportion at",
      "  each visit (e.g. 1, 0.9, 0.8 means 100%/90%/80% of subjects",
      "  still have data by visits 1/2/3); non-increasing.",
      "- **sigma** - the residual standard deviation of a single",
      "  observation.",
      "- **lambda** - the allocation ratio (arm 2's size / arm 1's",
      "  size).",
      "- **delta** - the between-arm difference to detect.",
      "- **alpha, power** - as elsewhere.",
      sep = "\n"
    ),
    worked_example = paste(
      "`longpower` (the checklist's named package for MMRM) is not",
      "installable from CRAN in this sandbox (no network access);",
      "`power.mmrm.ar1()` -- from the same package already used for the",
      "group-slope-difference design above, again a single, self-",
      "contained function with no cross-file dependencies -- was read",
      "directly from its public GitHub CRAN mirror and reimplemented.",
      "Verified against the package's own documented \"approximate",
      "simulation results from Table 5\" of Lu, Luo & Chen (2008):",
      "rho=0.6, arm-1 retention=(1, 0.76, 0.63, 0.52), arm-2",
      "retention=(1, 0.87, 0.81, 0.78), sigma=1, delta=0.9,",
      "lambda=sqrt(1.25/1.75), target power=0.904 -- this calculator",
      "gives N=81 total (37/44 per arm), matching the package's own",
      "companion example exactly (which fixes N=81 and solves back for",
      "rho, recovering rho=0.585, close to the input 0.6 -- the small",
      "gap is explained by N=81 being a rounded integer, not the exact",
      "unrounded root 80.61). A second round-trip (N=87, rho=0.6,",
      "lambda=1.25/1.75, power=0.910, solve for delta) recovers",
      "delta=0.891, close to the documented delta=0.9, the same",
      "rounding-explained gap.",
      sep = "\n"
    ),
    citation = paste(
      "Lu K, Luo X, Chen P-Y. Sample size estimation for repeated",
      "measures analysis in randomized clinical trials with missing",
      "data. International Journal of Biostatistics. 2008;4(1)."
    ),
    backend = "closed-form reimplementation of longpower::power.mmrm.ar1()"
  )
)
