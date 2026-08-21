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
  )
)
