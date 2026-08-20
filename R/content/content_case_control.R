# Metadata for the Case-Control module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_case_control.R (SDD 4.2: "content is data, not
# hardcoded UI").

case_control_content <- list(
  unmatched = list(
    title = "Unmatched Case-Control Study",
    formula_latex = paste0(
      "$$n = \\left(\\frac{Z_{1-\\alpha/2}\\sqrt{(r+1)\\bar p(1-\\bar p)} + ",
      "Z_{1-\\beta}\\sqrt{r\\,p_1(1-p_1) + p_0(1-p_0)}}{r(p_1-p_0)}\\right)^2 (r+1) ",
      "\\quad \\text{(Fleiss/Kelsey approx.; package computes exactly per Dupont 1988)}$$",
      "$$p_1 = \\frac{OR \\times p_0}{1 - p_0 + OR \\times p_0}, ",
      "\\quad \\bar p = \\frac{p_1 + r\\,p_0}{r+1}$$"
    ),
    explanation = paste(
      "In an unmatched case-control study, cases and controls are sampled",
      "independently (not paired), and exposure status is compared between",
      "the two groups after the fact -- appropriate when you cannot",
      "practically match each case to a specific control.",
      "",
      "- **p0** - the expected prevalence of exposure among controls",
      "  (from prior literature or pilot data).",
      "- **OR** - the odds ratio you want to be able to detect.",
      "- **ratio (r)** - the number of controls per case (1 for 1:1, 2",
      "  for 1:2, etc.) -- more controls per case increases power for a",
      "  fixed number of cases, with diminishing returns beyond about 4.",
      "- **alpha, power** - as elsewhere.",
      "- **N (optional)** - a finite eligible-population size, if",
      "  sampling from a limited pool (applies a finite population",
      "  correction).",
      "",
      "Power calculations use the uncorrected chi-square test (not",
      "Fisher's exact test).",
      sep = "\n"
    ),
    worked_example = paste(
      "Woodward (2014), Example 8.17: a case-control study of smoking and",
      "coronary heart disease (CHD) is planned, comparing newly diagnosed",
      "CHD cases with controls. About 30% of men without CHD are smokers",
      "(p0 = 0.30). To detect an odds ratio of 2.0 with 90% power using a",
      "two-sided 0.05 test, with equal cases and controls (ratio = 1),",
      "this calculator returns n = 376 total: 188 cases and 188 controls.",
      sep = "\n"
    ),
    citation = paste(
      "Dupont WD. Power calculations for matched case-control studies.",
      "Biometrics. 1988;44(4):1157-1168. (methodology, also covers the",
      "unmatched case); Woodward M. Epidemiology: Study Design and Data",
      "Analysis. 3rd ed. Chapman & Hall/CRC; 2014. pp. 295-329 (worked",
      "examples); Kelsey JL, Thompson WD, Evans AS. Methods in",
      "Observational Epidemiology. Oxford University Press; 1986."
    ),
    backend = "epiR::epi.sscc(method = \"unmatched\")"
  ),

  matched = list(
    title = "Matched Case-Control Study (1:1 or 1:m)",
    formula_latex = paste0(
      "$$n = \\text{solved from } \\phi \\text{ (correlation of matched-pair exposures), } ",
      "p_0, OR, r \\text{ per Dupont (1988)}$$"
    ),
    explanation = paste(
      "In a matched case-control study, each case is individually matched",
      "to one or more controls (e.g. by age, sex, neighborhood) before",
      "comparing exposure status -- reducing confounding, and usually",
      "needing fewer subjects than the equivalent unmatched design for the",
      "same power, because matching removes between-pair variability.",
      "",
      "- **p0** - the expected prevalence of exposure among controls.",
      "- **OR** - the odds ratio you want to be able to detect.",
      "- **phi (correlation)** - the correlation between case and control",
      "  exposures within matched pairs. If unknown, Dupont (1988)",
      "  suggests 0.2 (moderate) as a reasonable default rather than",
      "  assuming independence (phi = 0); this can also be estimated from",
      "  a pilot 2x2 table.",
      "- **ratio (m)** - controls per case (1 for 1:1 matching, more for",
      "  1:m).",
      "- **alpha, power** - as elsewhere.",
      sep = "\n"
    ),
    worked_example = paste(
      "Dupont (1988), p. 1164: a matched case-control study will quantify",
      "the association between an exposure and an outcome. Prevalence of",
      "exposure in controls is 60% (p0 = 0.60), and the correlation",
      "between matched case/control exposures is moderate (phi = 0.2). To",
      "detect an odds ratio of 3.0 with 80% power using a two-sided 0.05",
      "test, with 1:1 matching, this calculator returns n = 162: 81 cases",
      "and 81 controls. With 1:3 matching instead, it returns n = 204: 51",
      "cases and 153 controls -- fewer cases needed, at the cost of more",
      "controls overall.",
      sep = "\n"
    ),
    citation = paste(
      "Dupont WD. Power calculations for matched case-control studies.",
      "Biometrics. 1988;44(4):1157-1168."
    ),
    backend = "epiR::epi.sscc(method = \"matched\")"
  )
)
