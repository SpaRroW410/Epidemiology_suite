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
  ),

  diggle = list(
    title = "Longitudinal Group-Slope-Difference Test (Diggle et al 2002 Method)",
    formula_latex = paste0(
      "$$n_{\\text{per group}} = \\frac{2\\left(Z_{1-\\alpha/2} + Z_{power}\\right)^2 \\xi}{\\delta^2}, ",
      "\\quad \\xi = \\left[\\begin{pmatrix}1 & t\\end{pmatrix} V^{-1} \\begin{pmatrix}1 \\\\ t\\end{pmatrix}\\right]^{-1}_{22}$$",
      "$$V = \\sigma^2 R, \\quad R_{jk} = \\rho \\text{ (exchangeable working correlation)}$$"
    ),
    explanation = paste(
      "A second method (alongside the Liu & Liang design above) for the",
      "same longitudinal group-slope-difference problem, from Diggle,",
      "Heagerty, Liang & Zeger's standard longitudinal-data-analysis",
      "textbook. Rather than separately specifying random-intercept and",
      "random-slope variances, this marginal/GEE-style method works",
      "directly from the marginal (residual) variance at a single visit",
      "and a working correlation between visits -- here, a single",
      "exchangeable correlation (the same correlation between any two",
      "visits, regardless of how far apart).",
      "",
      "- **visit_times** - the time of each planned repeated measurement.",
      "- **delta** - the between-group difference in slope to detect.",
      "- **sigma2** - the marginal (residual) variance at a single visit.",
      "- **rho** - the exchangeable working correlation between any two",
      "  visits (0 to 1).",
      "- **alpha, power** - as elsewhere.",
      sep = "\n"
    ),
    worked_example = paste(
      "`longpower::diggle.linear.power()` -- a single, self-contained",
      "function with no cross-file dependencies -- was read directly",
      "from its public GitHub CRAN mirror and reimplemented. Verified by",
      "literally reproducing the printed table on page 29 of Diggle et",
      "al (2002) -- the function's own documented example -- across a",
      "3x3 grid of correlation (rho = 0.2, 0.5, 0.8) and residual",
      "variance (sigma2 = 100, 200, 300), 3 visits at t = 0, 2, 5, delta",
      "= 0.5, one-sided alpha = 0.05, power = 0.80: this calculator",
      "exactly reproduces every cell of the table -- n = 313/625/938 at",
      "rho=0.2, n = 196/391/586 at rho=0.5, n = 79/157/235 at rho=0.8",
      "(per group).",
      sep = "\n"
    ),
    citation = paste(
      "Diggle PJ, Heagerty PJ, Liang KY, Zeger SL. Analysis of",
      "Longitudinal Data. 2nd ed. Oxford Statistical Science Series,",
      "2002. Page 29."
    ),
    backend = "closed-form reimplementation of longpower::diggle.linear.power()"
  ),

  edland = list(
    title = "Longitudinal Group-Slope-Difference Test (Ard & Edland 2011 Method)",
    formula_latex = paste0(
      "$$n_{\\text{per group}} = \\frac{2\\left(Z_{1-\\alpha/2} + Z_{power}\\right)^2}{\\delta^2}",
      "\\left[\\begin{pmatrix}1 & t\\end{pmatrix}^\\top V^{-1} \\begin{pmatrix}1 & t\\end{pmatrix}\\right]^{-1}_{22}$$",
      "$$V_{jk} = t_j t_k \\, \\sigma^2_{\\text{slope}} + \\sigma^2_{\\text{residual}}\\,\\mathbb{1}[j=k]$$"
    ),
    explanation = paste(
      "A third method (alongside Liu & Liang and Diggle above) for the",
      "same longitudinal group-slope-difference problem, designed",
      "specifically to translate pilot mixed-model estimates (e.g. from",
      "an `lmer`/`lme` REML fit) directly into a sample size -- as used",
      "e.g. for Alzheimer's disease trial planning from ADAS-cog pilot",
      "estimates. This calculator covers the method's default case:",
      "equal variances across groups, equal allocation, and no subject",
      "attrition (every subject completes all planned visits), with a",
      "random slope but no random-intercept variance.",
      "",
      "- **visit_times** - the time of each planned repeated measurement.",
      "- **delta** - the between-group difference in slope to detect.",
      "- **sigma2_slope** - the variance of the random slope (how much",
      "  subjects vary in their rate of change), from a REML fit to pilot",
      "  data.",
      "- **sigma2_residual** - the residual (within-subject) error",
      "  variance, from the same fit.",
      "- **alpha, power** - as elsewhere.",
      sep = "\n"
    ),
    worked_example = paste(
      "`longpower::edland.linear.power()` -- a single, self-contained",
      "function with no cross-file dependencies -- was read directly",
      "from its public GitHub CRAN mirror and reimplemented. Verified",
      "two ways: (1) reproducing the function's own documented",
      "Alzheimer's-disease example exactly -- 7 visits from 0 to 1.5",
      "years, slope difference to detect = 1.5, random-slope variance =",
      "24, residual variance = 10, alpha = 0.05, target power = 0.80 ->",
      "this calculator gives N = 416 total (208/arm), matching the raw,",
      "unrounded N = 414.62 the package itself computes; and (2)",
      "independently, this app's own already-verified Liu & Liang",
      "implementation gives the identical raw N = 414.62 for the",
      "equivalent scenario (near-zero random-intercept variance) -- two",
      "mathematically distinct derivations landing on the same raw",
      "number is strong cross-method confirmation (the two designs'",
      "*rounded* totals differ by 1 -- 415 vs 416 -- purely because Liu &",
      "Liang ceilings the total N directly while this design ceilings",
      "the per-group n first, then doubles it).",
      sep = "\n"
    ),
    citation = paste(
      "Ard MC, Edland SD. Power calculations for clinical trials in",
      "Alzheimer's disease. Journal of Alzheimer's Disease.",
      "2011;21(2):369-377."
    ),
    backend = "closed-form reimplementation of longpower::edland.linear.power()"
  )
)
