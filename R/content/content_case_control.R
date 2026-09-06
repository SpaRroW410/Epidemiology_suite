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
  ),

  nested = list(
    title = "Nested Case-Control Study",
    formula_latex = paste0(
      "$$N = \\frac{(Z_{1-\\alpha/2} + Z_{1-\\beta})^2}{\\theta^2\\, p_E(1-p_E)(1-R^2)\\, ",
      "\\dfrac{n_D\\, n_H}{n_D+n_H}} \\quad \\text{(binary exposure; Lachin 2008, \\S3.3)}$$",
      "$$N = \\frac{(Z_{1-\\alpha/2} + Z_{1-\\beta})^2}{\\theta^2\\, \\sigma^2\\, n_D\\, ",
      "\\left(1-\\dfrac{1}{\\binom{n_D+n_H}{n_D}}\\right)(1-R^2)} ",
      "\\quad \\text{(continuous exposure; Lachin 2008, \\S3.1)}$$",
      "$$\\theta = \\log(OR)$$"
    ),
    explanation = paste(
      "In a nested case-control study, cases and a sample of matched",
      "controls are drawn from within an existing cohort (rather than",
      "assembled separately), and their exposure histories are compared",
      "using conditional logistic regression -- much cheaper than",
      "measuring exposure on the whole cohort, at a small efficiency",
      "cost relative to a full-cohort analysis.",
      "",
      "- **OR** - the odds ratio you want to be able to detect (per unit",
      "  change in a continuous exposure, or between exposed/unexposed for",
      "  a binary exposure).",
      "- **pE (binary only)** - prevalence of exposure among the matched sets.",
      "- **sigma (continuous only)** - the standard deviation of the exposure.",
      "- **nD, nH** - number of cases and controls per matched set (e.g.",
      "  nD = 1, nH = 2 for 1:2 matching).",
      "- **R2** - proportion of variation in exposure already explained by",
      "  other covariates in the conditional logistic model; 0 if the",
      "  exposure of interest is the only covariate.",
      "- **alpha, power** - as elsewhere.",
      "",
      "The result is the number of matched sets required; total subjects",
      "= sets x (nD + nH).",
      sep = "\n"
    ),
    worked_example = paste(
      "Binary exposure -- Lachin (2008), §3.3: to detect OR = 3.5 with",
      "exposure prevalence pE = 0.15 in a 1:2 matched nested case-control",
      "study (nD = 1, nH = 2), with no adjustment covariates (R2 = 0),",
      "alpha = 0.05, and 80% power, this calculator returns 59 matched",
      "sets (177 subjects total).",
      "",
      "Continuous exposure -- Lachin (2008), §3.1: to detect OR = 1.39",
      "per SD of a continuous exposure (sigma = 1) with the same 1:2",
      "matching, alpha = 0.05, and 85% power, this calculator returns",
      "125 matched sets (375 subjects total).",
      sep = "\n"
    ),
    citation = paste(
      "Lachin JM. Biostatistical Methods: The Assessment of Relative",
      "Risks. 2nd ed. Wiley; 2008. §3.1 (continuous exposure, formulas",
      "24-25), §3.3 (binary exposure, formula 38)."
    ),
    backend = "powerSurvEpi::powerConLogistic.bin() / powerConLogistic.con()"
  ),

  case_cohort = list(
    title = "Case-Cohort Study",
    formula_latex = paste0(
      "$$B = \\frac{(Z_{1-\\alpha} + Z_{1-\\beta})^2}{\\theta^2\\, p_1(1-p_1)\\, p_D}, ",
      "\\quad m = \\left\\lceil \\frac{n\\,B\\,p_D}{n - B(1-p_D)} \\right\\rceil$$",
      "$$\\theta = \\log(HR)$$"
    ),
    explanation = paste(
      "In a case-cohort study, a random subcohort is sampled once from an",
      "already-assembled cohort of known size, and exposure/covariates are",
      "measured only in that subcohort plus all cases that occur anywhere",
      "in the full cohort -- cheaper than measuring covariates on everyone,",
      "and (unlike a nested case-control design) the same subcohort can be",
      "reused to study multiple outcomes.",
      "",
      "- **n** - the full cohort size (already fixed/known).",
      "- **pD** - the proportion of the full cohort expected to fail",
      "  (experience the event) over the study period.",
      "- **p1** - the proportion of the cohort in exposure/covariate",
      "  group 1 (group 2 is 1 - p1).",
      "- **hr** - the hazard ratio you want to be able to detect between",
      "  the two groups.",
      "- **alpha, power** - as elsewhere.",
      "",
      "The result is the required random subcohort size (a subset of the",
      "full cohort n).",
      sep = "\n"
    ),
    worked_example = paste(
      "Cai & Zeng (2004), ARIC study example: a full cohort of n = 15,792",
      "has an expected 3% failure proportion (pD = 0.03) and 25% of the",
      "cohort in the exposed group (p1 = 0.25). To detect a hazard ratio",
      "of 1.35 with a one-sided alpha = 0.05 and 80% power, this",
      "calculator returns a required subcohort size of 1,463. At HR =",
      "1.40 the required subcohort drops to 722, and at HR = 1.45 to 468",
      "-- all three reproduce the paper's own worked table exactly.",
      sep = "\n"
    ),
    citation = paste(
      "Cai J, Zeng D. Sample size/power calculation for case-cohort",
      "studies. Biometrics. 2004;60(4):1015-1024."
    ),
    backend = "closed-form (Cai & Zeng 2004)"
  )
)
