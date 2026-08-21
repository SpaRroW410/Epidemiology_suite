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
  )
)
