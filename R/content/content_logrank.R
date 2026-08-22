# Metadata for the Log-Rank / Survival module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_logrank.R (SDD 4.2: "content is data, not hardcoded UI").

logrank_content <- list(
  logrank = list(
    title = "Log-Rank Test (Comparing Two Survival Curves)",
    formula_latex = paste0(
      "$$m = \\frac{1}{k}\\left(\\frac{kHR+1}{HR-1}\\right)^2 ",
      "\\left(Z_{1-\\alpha/2}+Z_{1-\\beta}\\right)^2$$",
      "$$n_E = \\frac{mk}{k\\,p_E + p_C}, \\quad n_C = \\frac{m}{k\\,p_E + p_C}$$"
    ),
    explanation = paste(
      "Use this to size a study comparing time-to-event outcomes",
      "(survival, relapse, disease progression) between an experimental",
      "and control group over a fixed maximum follow-up period, under the",
      "Cox proportional-hazards assumption -- the standard method behind",
      "the log-rank test.",
      "",
      "- **pE** - the expected cumulative probability of the event in the",
      "  experimental group by the end of the maximum follow-up period",
      "  (not a rate -- a proportion who will have had the event).",
      "- **pC** - the same, for the control group.",
      "- **HR (hazard ratio)** - the postulated hazard ratio, experimental",
      "  vs. control (< 1 means the experimental group has a lower",
      "  event/hazard rate).",
      "- **ratio** - the number of participants in the experimental group",
      "  divided by the number in the control group.",
      "- **alpha, power** - as elsewhere (two-sided test).",
      "",
      "This method (Freedman 1982, via Rosner 2006) needs each group's",
      "*cumulative event probability over the study's follow-up*, not a",
      "person-time incidence rate -- if you only have incidence rates and",
      "a follow-up duration, first convert to a cumulative probability",
      "(e.g. via the exponential approximation p = 1 - exp(-rate x time))",
      "before using this calculator. It also assumes proportional hazards",
      "and complete follow-up (no staggered accrual) -- for staggered",
      "accrual and non-proportional-hazards designs, a more specialized",
      "method is needed (see docs/checklist_by_design.md's Survival",
      "section for further designs planned).",
      sep = "\n"
    ),
    worked_example = paste(
      "Rosner (2006), Example 14.42, p. 809: a clinical trial comparing",
      "survival between an experimental and control group, with an",
      "expected 5-year cumulative event probability of 37.07% in the",
      "experimental group (pE = 0.3707) and 48.90% in the control group",
      "(pC = 0.4890) -- corresponding to a hazard ratio of 0.7 -- equal",
      "group sizes (ratio = 1), alpha = 0.05 (two-sided), and 80% power.",
      "This calculator returns n = 294 per group (588 total), matching",
      "the textbook's own answer exactly.",
      sep = "\n"
    ),
    citation = paste(
      "Freedman LS. Tables of the number of patients required in clinical",
      "trials using the log-rank test. Stat Med. 1982;1(2):121-129;",
      "Rosner B. Fundamentals of Biostatistics. 6th ed. Belmont, CA:",
      "Thomson Brooks/Cole; 2006. Section 14.12, p. 807."
    ),
    backend = "powerSurvEpi::ssizeCT.default()"
  ),
  cox_binary = list(
    title = "Cox Proportional-Hazards Regression (Binary Covariate of Interest)",
    formula_latex = paste0(
      "$$n = \\frac{\\left(Z_{1-\\alpha/2}+Z_{1-\\beta}\\right)^2}",
      "{[\\log(\\theta)]^2\\, p(1-p)\\, \\psi\\, (1-\\rho^2)}$$"
    ),
    explanation = paste(
      "Use this to size a study where the primary analysis is a Cox",
      "proportional-hazards regression with a **binary** exposure/",
      "predictor of interest (X1), optionally adjusting for one other",
      "covariate (X2, binary or continuous) that may be correlated with it.",
      "",
      "- **power, alpha** - as elsewhere (two-sided test).",
      "- **theta** - the postulated hazard ratio for X1=1 vs. X1=0",
      "  (adjusted for X2, if any).",
      "- **p** - the proportion of subjects with X1=1 (the exposure",
      "  prevalence).",
      "- **psi** - the overall proportion of subjects expected to",
      "  experience the event of interest during the study (accounts for",
      "  competing risks/censoring -- not everyone need have the event).",
      "- **rho2** - the squared correlation between X1 and X2. Leave at 0",
      "  for a randomized trial or an unadjusted/univariate analysis; a",
      "  nonzero value inflates n to account for the loss of precision",
      "  from adjusting for a correlated covariate.",
      "",
      "When rho2 = 0 this reduces to the classic Schoenfeld (1983)",
      "formula; the general (adjusted) version is Latouche, Porcher &",
      "Chevret (2004)'s extension for competing-risks/adjusted models.",
      sep = "\n"
    ),
    worked_example = paste(
      "Latouche, Porcher & Chevret (2004), Section 5.2: a cohort study",
      "with a binary covariate of interest present in 39% of subjects",
      "(p = 0.39), an overall event probability of 50.5% (psi = 0.505), a",
      "postulated hazard ratio of 2 (theta = 2), a correlation of 0.132",
      "with an adjustment covariate (rho2 = 0.132^2), 80% power and",
      "alpha = 0.05 (two-sided). This calculator returns n = 139,",
      "matching the paper's own worked example exactly.",
      sep = "\n"
    ),
    citation = paste(
      "Latouche A, Porcher R, Chevret S. Sample size formula for",
      "proportional hazards modelling of competing risks. Stat Med.",
      "2004;23(20):3263-3274; Schoenfeld DA. Sample-size formula for the",
      "proportional-hazards regression model. Biometrics. 1983;39:499-503."
    ),
    backend = "powerSurvEpi::ssizeEpi.default()"
  ),
  cox_continuous = list(
    title = "Cox Proportional-Hazards Regression (Continuous Covariate of Interest)",
    formula_latex = paste0(
      "$$n = \\frac{\\left(Z_{1-\\alpha/2}+Z_{1-\\beta}\\right)^2}",
      "{[\\log(\\theta)]^2\\, \\sigma^2\\, \\psi\\, (1-\\rho^2)}$$"
    ),
    explanation = paste(
      "Use this to size a study where the primary analysis is a Cox",
      "proportional-hazards regression with a **continuous (or other",
      "non-binary)** exposure/predictor of interest, optionally adjusting",
      "for other covariates.",
      "",
      "- **power, alpha** - as elsewhere (two-sided test).",
      "- **theta** - the postulated hazard ratio per one-unit increase in",
      "  the covariate of interest.",
      "- **sigma^2** - the variance of the covariate of interest in the",
      "  study population.",
      "- **psi** - the overall proportion of subjects expected to",
      "  experience the event of interest during the study.",
      "- **rho2** - the squared multiple correlation between the covariate",
      "  of interest and any other adjustment covariates (R-squared of",
      "  regressing it on them). Leave at 0 for an unadjusted analysis.",
      sep = "\n"
    ),
    worked_example = paste(
      "Hsieh & Lavori (2000)'s own worked example (their p. 557; the",
      "authors' formula assumes a one-sided test, so their one-sided",
      "alpha = 0.05 corresponds to two-sided alpha = 0.1 as used here): a",
      "continuous covariate with variance sigma^2 = 0.3126^2, a postulated",
      "hazard ratio of e (theta = exp(1)), an overall event probability of",
      "73.8% (psi = 0.738), rho2 = 0.1837, and 80.6% power. This",
      "calculator returns n = 107, matching the paper's own worked example",
      "exactly.",
      sep = "\n"
    ),
    citation = paste(
      "Hsieh FY, Lavori PW. Sample-size calculation for the Cox",
      "proportional hazards regression model with nonbinary covariates.",
      "Control Clin Trials. 2000;21(6):552-560."
    ),
    backend = "powerSurvEpi::ssizeEpiCont.default()"
  )
)
