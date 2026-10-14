# Metadata for the Non-Inferiority module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_noninferiority.R (SDD 4.2: "content is data, not
# hardcoded UI").

noninferiority_content <- list(
  means = list(
    title = "Non-Inferiority Trial, Continuous (Means) Outcome",
    formula_latex = paste0(
      "$$H_0: \\mu_s - \\mu_n \\ge \\Delta \\quad \\text{vs.} \\quad ",
      "H_1: \\mu_s - \\mu_n < \\Delta$$"
    ),
    explanation = paste(
      "Use this when the goal is to show a new treatment is *not much",
      "worse* than a standard treatment (rather than to show it's",
      "different or better) -- e.g. because the new treatment is safer,",
      "cheaper, or easier to administer. Unlike an equivalence trial (which",
      "rules out differences in *either* direction), a non-inferiority",
      "trial only rules out the new treatment being worse by more than the",
      "margin; it can still be much better.",
      "",
      "- **New / standard mean** - the expected mean outcome in the new-",
      "  and standard-treatment groups.",
      "- **sd** - the expected population standard deviation.",
      "- **Non-inferiority margin** - the largest (standard - new)",
      "  difference still considered acceptable; must be positive.",
      "- **alpha** - the one-sided significance level (non-inferiority",
      "  tests are inherently one-sided).",
      "- **power** - the desired probability of concluding non-inferiority.",
      "- **ratio** - new-group size divided by standard-group size.",
      sep = "\n"
    ),
    worked_example = paste(
      "Chow, Shao & Wang (2008, p. 61-62): a trial comparing two",
      "cholesterol-lowering agents on LDL, testing non-inferiority. Both",
      "groups are expected to average 0.20 units (sd = 0.10), and a 0.05",
      "unit change is considered clinically meaningful. At alpha = 0.05",
      "(one-sided) and 80% power, this calculator returns n = 50 per group",
      "(100 total) -- exactly the textbook's own printed answer.",
      sep = "\n"
    ),
    citation = paste(
      "Chow S, Shao J, Wang H. Sample Size Calculations in Clinical",
      "Research. Chapman & Hall/CRC Biostatistics Series; 2008, p. 61-62.",
      "(as implemented by epiR::epi.ssninfc)."
    ),
    backend = "epiR::epi.ssninfc()"
  ),

  proportions = list(
    title = "Non-Inferiority Trial, Binary (Proportions) Outcome",
    formula_latex = paste0(
      "$$H_0: P_s - P_n \\ge \\Delta \\quad \\text{vs.} \\quad ",
      "H_1: P_s - P_n < \\Delta$$"
    ),
    explanation = paste(
      "The proportions counterpart of the means version above -- use this",
      "to show a new treatment's success rate is not much worse than a",
      "standard treatment's, within a pre-specified margin.",
      "",
      "- **New / standard proportion** - the expected proportion of",
      "  successes (e.g. cure rate) in the new- and standard-treatment",
      "  groups.",
      "- **Non-inferiority margin** - the largest (standard - new)",
      "  difference still considered acceptable; must be positive.",
      "- **alpha** - the one-sided significance level.",
      "- **power** - the desired probability of concluding non-inferiority.",
      "- **ratio** - new-group size divided by standard-group size.",
      sep = "\n"
    ),
    worked_example = paste(
      "Chow, Shao & Wang (2008, p. 90): a trial of two antimicrobial",
      "agents for skin infections, testing non-inferiority. The new agent",
      "is expected to cure 85% of patients vs. 65% for the standard, and a",
      "10 percentage-point difference is considered of no clinical",
      "significance. At alpha = 0.05 (one-sided) and 80% power, this",
      "calculator returns n = 25 per group (50 total) -- exactly the",
      "textbook's own printed answer.",
      sep = "\n"
    ),
    citation = paste(
      "Chow S, Shao J, Wang H. Sample Size Calculations in Clinical",
      "Research. Chapman & Hall/CRC Biostatistics Series; 2008, p. 90.",
      "(as implemented by epiR::epi.ssninfb)."
    ),
    backend = "epiR::epi.ssninfb()"
  ),

  odds_ratio = list(
    title = "Non-Inferiority Trial, Odds Ratio Outcome",
    formula_latex = paste0(
      "$$H_0: \\log(OR) \\le \\Delta \\quad \\text{vs.} \\quad H_1: \\log(OR) > \\Delta$$",
      "$$OR = \\frac{p_t(1-p_c)}{p_c(1-p_t)}$$"
    ),
    explanation = paste(
      "Use this to show a new treatment's odds of a binary outcome are",
      "not much worse than a standard treatment's, expressed as an odds",
      "ratio rather than a raw proportion difference.",
      "",
      "- **pt, pc** - the expected probability of the outcome in the",
      "  test/new-treatment and control/standard groups.",
      "- **Non-inferiority margin** - the largest acceptable log-odds-ratio",
      "  still considered non-inferior (0 means the new treatment's odds",
      "  must be at least as good; a small negative number allows some",
      "  acceptable shortfall).",
      "- **k (allocation ratio)** - n_test / n_control.",
      "- **alpha** - the one-sided significance level.",
      "- **power** - the desired probability of concluding non-inferiority.",
      "",
      "This wraps `TrialSize::RelativeRisk.NIS()` -- despite that",
      "function's name, its formula (and its non-inferiority-free sibling",
      "`RelativeRisk.Equality()`) is built on the log **odds ratio**",
      "pt(1-pc)/(pc(1-pt)), not the relative risk pt/pc, so this app labels",
      "the design by what the formula actually computes rather than by",
      "the package's own (inconsistent) naming.",
      sep = "\n"
    ),
    worked_example = paste(
      "Chow, Shao & Wang (2003), Example 4.6.4: pt = 0.4, pc = 0.25",
      "(implied odds ratio = 2), a non-inferiority margin of 0.2 on the",
      "log-odds-ratio scale, equal allocation (k = 1), alpha = 0.05",
      "(one-sided), and 80% power. This calculator returns n = 242 per",
      "group (484 total), matching the textbook's own worked answer",
      "exactly.",
      sep = "\n"
    ),
    citation = paste(
      "Chow SC, Shao J, Wang H. Sample Size Calculations in Clinical",
      "Research. New York: Marcel Dekker; 2003. Section 4.6."
    ),
    backend = "TrialSize::RelativeRisk.NIS()"
  ),

  hazard_ratio = list(
    title = "Non-Inferiority Trial, Hazard Ratio (Cox PH) Outcome",
    formula_latex = paste0(
      "$$H_0: \\log(HR) \\ge \\Delta \\quad \\text{vs.} \\quad H_1: \\log(HR) < \\Delta$$",
      "$$n = \\frac{(Z_{1-\\alpha} + Z_{1-\\beta})^2}{(\\log(HR) - \\Delta)^2 \\, p_1(1-p_1)\\, d}$$"
    ),
    explanation = paste(
      "Use this to show a new treatment's hazard (event) rate is not much",
      "worse than a standard treatment's, for a time-to-event outcome",
      "analyzed via a Cox proportional-hazards model.",
      "",
      "- **hr** - the expected hazard ratio (treatment vs. control); values",
      "  below 1 favor the new treatment.",
      "- **Non-inferiority margin** - the largest acceptable log-hazard-",
      "  ratio still considered non-inferior (typically a small positive",
      "  number, since HR > 1 usually means worse outcomes).",
      "- **p1** - the proportion of patients allocated to the treatment",
      "  group.",
      "- **d** - the overall probability of observing an event during the",
      "  study (drives how much information the trial accumulates).",
      "- **alpha** - the one-sided significance level.",
      "- **power** - the desired probability of concluding non-inferiority.",
      sep = "\n"
    ),
    worked_example = paste(
      "Chow, Shao & Wang (2003), Example 7.3.4: an expected hazard ratio",
      "of 2, a non-inferiority margin of 0.5 on the log-hazard-ratio",
      "scale, half the patients allocated to treatment (p1 = 0.5), an 80%",
      "probability of observing an event (d = 0.8), alpha = 0.05",
      "(one-sided), and 80% power. This calculator returns n = 829,",
      "matching the textbook's own worked answer exactly.",
      sep = "\n"
    ),
    citation = paste(
      "Chow SC, Shao J, Wang H. Sample Size Calculations in Clinical",
      "Research. New York: Marcel Dekker; 2003. Section 7.3."
    ),
    backend = "TrialSize::Cox.NIS()"
  )
)
