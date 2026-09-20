# Metadata for the EFA/CFA Subjects-Per-Item Guidance module. Content is
# data, rendered generically by mod_efa_cfa.R (SDD 4.2: "content is data,
# not hardcoded UI").
#
# Like the Pilot/Feasibility module, this is a rule-of-thumb calculator,
# not a solved hypothesis-test formula -- there is no single accepted
# power formula for factor-analysis sample size.

efa_cfa_content <- list(
  rule_of_thumb = list(
    title = "EFA/CFA Subjects-Per-Item Sample Size",
    formula_latex = paste0(
      "$$N_{5:1} = 5 \\times k, \\quad N_{10:1} = 10 \\times k, ",
      "\\quad N_{20:1} = 20 \\times k$$",
      "$$k = \\text{number of items (EFA) or free parameters (CFA/SEM)}$$"
    ),
    explanation = paste(
      "There is no accepted power formula for exploratory or confirmatory",
      "factor analysis sample size the way there is for a hypothesis",
      "test -- the field instead relies on published participant-to-item",
      "(or participant-to-parameter) ratios, refined over decades of",
      "methodological work. Treat any number below as a starting point,",
      "not a target to defend statistically.",
      "",
      "**Costello & Osborne (2005) ratios.** Reviewing common practice",
      "and simulation evidence, they summarize: 5:1 as an absolute",
      "minimum, 10:1 commonly recommended, and up to 20:1 for a more",
      "robust and stable factor solution.",
      "",
      "**Comrey & Lee (1992) absolute-N scale.** Independently of item",
      "count, they propose adjective labels for the resulting total N:",
      "50 = very poor, 100 = poor, 200 = fair, 300 = good, 500 = very",
      "good, 1000+ = excellent. The calculator below reports which label",
      "each of the three ratio-based N's falls into.",
      "",
      "**The important caveat (MacCallum, Widaman, Zhang & Hong 1999).**",
      "A fixed ratio-only rule can be badly wrong in either direction: the",
      "authors show required N depends heavily on the COMMUNALITY level",
      "(how strongly items load on their factors) and on how",
      "OVERDETERMINED the factors are (how many items mark each factor).",
      "Low communality can need a much larger N than any of these ratios",
      "suggest, regardless of item count; high communality with several",
      "items per factor can need less. Use these ratios as a starting",
      "point when nothing else is known, not a substitute for planning",
      "around your study's actual expected communalities when that",
      "information is available.",
      sep = "\n"
    ),
    worked_example = paste(
      "A 20-item scale: 5:1 -> N=100 (\"poor\" on the Comrey & Lee scale);",
      "10:1 -> N=200 (\"fair\"); 20:1 -> N=400 (\"good\"). A shorter 6-item",
      "scale needs far fewer participants by these ratios (N=30/60/120),",
      "but MacCallum et al.'s caveat matters most exactly in these smaller",
      "cases: a 6-item scale with low communalities can still need a much",
      "larger N than 120 to recover a stable factor structure.",
      sep = "\n"
    ),
    citation = paste(
      "Costello AB, Osborne JW. Best practices in exploratory factor",
      "analysis: four recommendations for getting the most from your",
      "analysis. Pract Assess Res Eval. 2005;10(7). Comrey AL, Lee HB. A",
      "First Course in Factor Analysis. 2nd ed. Erlbaum, 1992. MacCallum",
      "RC, Widaman KF, Zhang S, Hong S. Sample size in factor analysis.",
      "Psychol Methods. 1999;4(1):84-99."
    ),
    backend = "Closed-form rule-of-thumb ratios (Costello & Osborne 2005; Comrey & Lee 1992 adjective lookup); no external package required"
  ),

  rmsea = list(
    title = "CFA/SEM Test of Close Fit via RMSEA",
    formula_latex = paste0(
      "$$ncp_0 = (n-1)\\,df\\,RMSEA_0^2 / G, \\qquad ncp_A = (n-1)\\,df\\,RMSEA_A^2 / G$$",
      "$$c = \\chi^2_{df,\\,ncp_0}(1-\\alpha), \\qquad ",
      "power = \\Pr\\!\\left(\\chi^2_{df,\\,ncp_A} > c\\right)$$"
    ),
    explanation = paste(
      "Unlike the rule-of-thumb calculator above, this is a genuine",
      "closed-form hypothesis-test power calculation for a structural",
      "equation model (SEM) or confirmatory factor analysis (CFA), based",
      "on the model's RMSEA (root mean square error of approximation) fit",
      "statistic -- the standard approach for planning a target sample",
      "size given a model's degrees of freedom and an assumed level of",
      "misfit.",
      "",
      "- **df** - the model's degrees of freedom (from the model itself:",
      "  number of unique sample moments minus number of free",
      "  parameters).",
      "- **RMSEA0 (null)** - the RMSEA value under the null hypothesis --",
      "  typically the \"close fit\" threshold, 0.05.",
      "- **RMSEA_A (alternative)** - the RMSEA value you want to be able",
      "  to detect/reject against -- e.g. 0.08 (\"mediocre fit\") to test",
      "  whether the model achieves close fit rather than merely",
      "  mediocre fit.",
      "- **Groups** - the number of groups in a multi-group model (1 for",
      "  an ordinary single-group model).",
      "",
      "This is MacCallum, Browne & Sugawara (1996)'s test of close fit",
      "(and its complement, testing NOT-close-fit when RMSEA0 > RMSEA_A),",
      "built on the fact that df times the sample RMSEA-squared follows a",
      "noncentral chi-square distribution with a noncentrality parameter",
      "determined by the true RMSEA, sample size, and df.",
      sep = "\n"
    ),
    worked_example = paste(
      "df=20, RMSEA0=0.05 (close fit) vs RMSEA_A=0.08 (mediocre fit),",
      "alpha=0.05, target power=0.80 -> this calculator finds n=434,",
      "achieving power=0.8004 -- exactly matching a real",
      "`semTools::findRMSEAsamplesize()`/`findRMSEApower()` call on the",
      "same inputs. A second scenario testing the reverse direction",
      "(RMSEA0=0.08 vs RMSEA_A=0.03, i.e. testing whether the model is",
      "NOT close-fitting, df=50, n=300, alpha=0.05, a 2-group model) gives",
      "power=0.8972, also matching exactly. A third scenario (df=100,",
      "RMSEA0=0.06 vs RMSEA_A=0.10, power=0.90, alpha=0.01) needs n=131,",
      "again matching exactly.",
      sep = "\n"
    ),
    citation = paste(
      "MacCallum RC, Browne MW, Sugawara HM. Power analysis and",
      "determination of sample size for covariance structure modeling.",
      "Psychol Methods. 1996;1(2):130-149.",
      "",
      "Formula reimplemented from, and verified bit-for-bit against, real",
      "`semTools::findRMSEApower()`/`findRMSEAsamplesize()` calls (Jorgensen",
      "TD, Pornprasertmanit S, Schoemann AM, Rosseel Y. semTools: Useful",
      "Tools for Structural Equation Modeling. R package,",
      "https://github.com/cran/semTools) -- installed in this sandbox via",
      "the github.com/cran mirror (`cran.r-project.org` itself is",
      "network-blocked here), used only as a verification oracle. Per this",
      "project's vendoring policy, the shipped calculator has no new",
      "runtime dependency."
    ),
    backend = "closed-form reimplementation (MacCallum, Browne & Sugawara 1996)"
  ),

  irt_calibration = list(
    title = "IRT Item Calibration — Minimum Sample Size by Model Type",
    formula_latex = paste0(
      "$$N_{minimum} = \\text{lookup}(\\text{model type}), \\quad ",
      "\\text{from published Monte Carlo parameter-recovery studies}$$"
    ),
    explanation = paste(
      "Like the EFA/CFA ratios above, there is no closed-form power",
      "formula for IRT (Item Response Theory) item calibration -- how",
      "many examinees are needed depends on the specific model's",
      "complexity (how many parameters each item has), not a single",
      "hypothesis test. The field instead relies on published Monte",
      "Carlo parameter-recovery studies -- simulating known \"true\" item",
      "parameters, generating response data at various sample sizes, and",
      "checking how well the fitted model recovers the true values --",
      "which established the following widely-cited minimum-N",
      "guidelines by model type:",
      "",
      "- **Rasch / 1PL** (one parameter per item: difficulty only) --",
      "  the simplest and most data-efficient IRT model. Linacre (1994)",
      "  recommends roughly 50 well-targeted examinees as a conservative",
      "  minimum for useful (if imprecise, about +/-1 logit) item",
      "  calibration, rising to 100-150 for +/-0.5 logit precision, and",
      "  250+ for the tightest, most stable calibrations.",
      "- **2PL** (difficulty + discrimination per item) -- Hulin, Lissak",
      "  & Drasgow (1982)'s classic Monte Carlo recovery study",
      "  (N = 200/500/1000/2000 examinees, tests of 15/30/60 items)",
      "  found N >= 500 needed for adequate item-parameter recovery.",
      "- **3PL** (difficulty + discrimination + guessing per item) --",
      "  the same study found the added guessing parameter needs",
      "  substantially more data, N >= 1000.",
      "- **Polytomous** (graded response/partial credit, multiple",
      "  ordered response categories per item) -- Reise & Yu (1990)",
      "  found N >= 500 needed for the discrimination parameter to be",
      "  recovered accurately (estimated-vs-true correlation >= 0.85).",
      "",
      "Treat these as a starting point, the same way the EFA/CFA ratios",
      "above should be treated -- actual required N also depends on test",
      "length, how well the test's difficulty range matches the",
      "examinee population (\"targeting\"), and how much precision the",
      "specific application needs.",
      sep = "\n"
    ),
    worked_example = paste(
      "Calibrating a new 20-item scale: if a simple Rasch/1PL model fits,",
      "50 well-targeted examinees is a workable minimum for a pilot",
      "calibration; if a 2PL model is needed (items differ meaningfully",
      "in discrimination), at least 500 examinees are recommended; if a",
      "3PL model is needed (e.g. a multiple-choice test where guessing",
      "matters), at least 1000. A polytomous (Likert-type, graded",
      "response) scale needs at least 500 examinees by the same logic --",
      "notably MORE than the simplest dichotomous Rasch case, since",
      "polytomous items carry more parameters to estimate per item.",
      sep = "\n"
    ),
    citation = paste(
      "Linacre JM. Sample size and item calibration [or person measure]",
      "stability. Rasch Meas Trans. 1994;7(4):328.",
      "",
      "Hulin CL, Lissak RI, Drasgow F. Recovery of two- and three-",
      "parameter logistic item characteristic curves: a Monte Carlo",
      "study. Appl Psychol Meas. 1982;6(3):249-260.",
      "",
      "Reise SP, Yu J. Parameter recovery in the graded response model",
      "using MULTILOG. J Educ Meas. 1990;27(2):133-144."
    ),
    backend = "rule-of-thumb lookup (Linacre 1994; Hulin, Lissak & Drasgow 1982; Reise & Yu 1990); no external package required"
  )
)
