# Metadata for the Competing Risks module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_competing_risks.R (SDD 4.2: "content is data, not
# hardcoded UI").

competing_risks_content <- list(
  joint = list(
    title = "Joint Test of a Cause-Specific Hazard and the Any-Cause Hazard",
    formula_latex = paste0(
      "$$\\text{Chi-square joint: } D_{\\chi^2} \\text{ solves } ",
      "1-\\beta = \\Pr\\!\\big(\\chi^2_2(\\nu) > \\chi^2_{2,1-\\alpha}\\big)$$",
      "$$\\text{Maximum joint: } D_{\\max} \\text{ solves a bivariate-normal ",
      "quadrant probability at a jointly-calibrated critical value } c_m$$"
    ),
    explanation = paste(
      "In competing-risks data (e.g. death from the disease of interest",
      "vs. death from other causes), analyzing only the CAUSE-SPECIFIC",
      "hazard (treating other-cause deaths as censoring) or only the",
      "ANY-CAUSE hazard (overall mortality) alone can each be",
      "underpowered on its own. Yang, Fung & Li (2017) propose jointly",
      "testing both and give three ways to combine them into a single",
      "test, each needing a somewhat different number of cause-1 events",
      "(and total patients) to reach the target power:",
      "",
      "- **Chi-square joint test** - combines the two (correlated)",
      "  standardized statistics into a single 2-df chi-square statistic.",
      "- **Maximum joint test** - rejects if EITHER component statistic",
      "  clears a critical value calibrated jointly across both (usually",
      "  needs the fewest events of the three).",
      "- **Bonferroni joint test** - tests each hazard separately at",
      "  alpha/2 and takes the larger of the two required sample sizes",
      "  (the simplest, most conservative option).",
      "",
      "- **lambda_11** - the cause-1 (event of interest) cause-specific",
      "  hazard in group 1.",
      "- **hr_1** - the cause-1 cause-specific hazard ratio, group 1 vs. 2.",
      "- **hr_all** - the any-cause hazard ratio, group 1 vs. 2.",
      "- **rr** - the relative risk of a cause-1 failure vs. an any-cause",
      "  failure in group 1 (must satisfy hr_1 > rr * hr_all).",
      "- **accrual, follow_up** - the enrollment period's length, and the",
      "  total study duration (follow_up > accrual).",
      "- **attrition** - the loss-to-follow-up rate.",
      "- **a1** - the proportion of patients allocated to group 1.",
      "- **alpha, power** - as elsewhere (two-sided test).",
      sep = "\n"
    ),
    worked_example = paste(
      "Reproducing `powerCompRisk::powerCompRisk()`'s own documented",
      "example exactly: lambda_11 = 0.3, rr = 0.8, hr_1 = 1.44, hr_all =",
      "1.33, attrition = 0.1, accrual = 1, follow_up = 8, a1 = 0.5, alpha",
      "= 0.05, power = 0.8 (i.e. beta = 0.2). This calculator returns:",
      "chi-square joint test -> 290 cause-1 events, 436 total patients;",
      "maximum joint test -> 252 events, 378 patients; Bonferroni joint",
      "test -> 288 events, 430 patients -- all matching the package's own",
      "printed output exactly, reproduced by directly running the",
      "package's own publicly-readable source code.",
      sep = "\n"
    ),
    citation = paste(
      "Yang Q, Fung WK, Li G. Sample size determination for jointly",
      "testing a cause-specific hazard and the any-cause hazard in the",
      "presence of competing risks. UCLA Department of Biostatistics",
      "Technical Report; 2017."
    ),
    backend = "closed-form reimplementation of powerCompRisk::powerCompRisk() (via mvtnorm::pmvnorm())"
  )
)
