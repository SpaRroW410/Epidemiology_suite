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
      "- **OR** - the odds ratio you want to be able to detect, or instead",
      "  **p1**, the proportion of cases you expect to be exposed (the odds",
      "  ratio is then p1 (1 - p0) / (p0 (1 - p1)); see the formula above).",
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
    backend = "closed form (Kelsey et al. 1996); identical to epiR::epi.sscc(method = \"unmatched\"), which it is tested against"
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
      "- **OR** - the odds ratio you want to be able to detect, or instead",
      "  **p1**, the proportion of cases you expect to be exposed: the odds",
      "  ratio is then p1 (1 - p0) / (p0 (1 - p1)), the same relation the",
      "  formula uses (p1 = OR p0 / (1 - p0 + OR p0)).",
      "- **phi (correlation)** - the correlation between case and control",
      "  exposures within matched pairs. If unknown, Dupont (1988)",
      "  suggests 0.2 (moderate) as a reasonable default rather than",
      "  assuming independence (phi = 0). It can also be calculated from a",
      "  table of matched pairs from a pilot or a published study: with a",
      "  pairs in which both were exposed, b only the case, c only the",
      "  control and d neither, phi = (ad - bc) / sqrt((a+b)(c+d)(a+c)(b+d)),",
      "  the phi coefficient of that table (the correlation of two yes/no",
      "  variables). The same table gives p1 = (a+b)/n and p0 = (a+c)/n.",
      "- **ratio (m)** - controls per case (1 for 1:1 matching, more for",
      "  1:m).",
      "- **alpha, power** - as elsewhere.",
      "",
      "**Also used for case-crossover studies.** A case-crossover design",
      "(each case's exposure in a hazard/case period compared to their OWN",
      "exposure in one or more control periods, rather than to a separate",
      "matched person) is mathematically a 1:M matched case-control design",
      "with M control periods per case (Maclure 1991; Mittleman, Maclure &",
      "Robins 1995) -- so this same calculator, with p0/phi/ratio",
      "reinterpreted as control-PERIOD exposure prevalence/correlation/",
      "count, applies directly; that equivalence, and the standard use of",
      "this Dupont (1988) formula for case-crossover planning, is",
      "confirmed in Dharmarajan, Lee & Izem (2019). Their same paper,",
      "however, shows this formula (and other pre-2019 methods) CAN",
      "UNDERESTIMATE the true required N for case-crossover specifically",
      "across a range of realistic inputs, and proposes corrected methods",
      "that no R package currently implements -- treat a case-crossover",
      "result from this calculator as an optimistic (possibly too small)",
      "planning estimate, not a precise one, pending a package that",
      "implements their correction.",
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
      "Biometrics. 1988;44(4):1157-1168. Case-crossover use: Maclure M.",
      "The case-crossover design: a method for studying transient effects",
      "on the risk of acute events. Am J Epidemiol. 1991;133(2):144-153;",
      "Mittleman MA, Maclure M, Robins JM. Control sampling strategies for",
      "case-crossover studies: an assessment of relative efficiency. Am J",
      "Epidemiol. 1995;142(1):91-98; Dharmarajan S, Lee JY, Izem R. Sample",
      "size estimation for case-crossover studies. Stat Med.",
      "2019;38(6):956-968 (confirms the matched-case-control equivalence",
      "and formula choice, and documents its underestimation risk)."
    ),
    backend = "closed form (Dupont 1988, as in epiR); identical to epiR::epi.sscc(method = \"matched\"), which it is tested against"
  ),

  nested = list(
    title = "Matched Sets: Conditional Logistic Regression (Nested Case-Control, or a Measured Exposure 1:1 or 1:m)",
    formula_latex = paste0(
      "$$N = \\frac{(Z_{1-\\alpha/2} + Z_{1-\\beta})^2}{\\theta^2\\, \\sigma^2\\, \\dfrac{n_D\\, n_H}{n_D+n_H}\\,(1-R^2)}",
      "\\qquad \\sigma^2 = p_E(1-p_E) \\text{ for an exposure that is present or absent}$$",
      "$$\\theta = \\log(OR) \\;=\\; \\frac{\\log(OR_{SD})}{\\sigma} \\;=\\; \\frac{\\mu_{cases} - \\mu_{controls}}{\\sigma^2}",
      "\\qquad \\text{one case and } m \\text{ controls: } N = \\left[\\frac{(Z_{1-\\alpha/2} + Z_{1-\\beta})\\,\\sigma}{\\mu_{cases} - \\mu_{controls}}\\right]^2 \\frac{m+1}{m}$$"
    ),
    explanation = paste(
      "Matched sets -- each case with one or more controls matched to it (age, sex, place, or the time at risk in a nested",
      "case-control study) -- are analysed with conditional logistic regression. This design gives the number of sets for the",
      "score test of the exposure (Lachin 2008). It applies to a nested case-control study and to any individually matched",
      "case-control study, with one control per case or several.",
      "",
      "- **Exposure present or absent:** the odds ratio and **pE**, the probability of exposure (among controls, or overall).",
      "- **A measured exposure** (a level, a score, a dose): the effect as the **mean exposure in cases and in their matched",
      "  controls**, as an **odds ratio per SD**, or as an **odds ratio per unit**; and **sigma**, the SD of the exposure",
      "  *within matched sets*. If the matching factors are only weakly related to the exposure, the SD among controls (or in",
      "  the population) will do; strong matching on a correlate of the exposure makes the SD within sets smaller, and a",
      "  smaller sigma asks for more sets for the same mean difference.",
      "- **nD, nH** - cases and controls per set (nD = 1, nH = 4 for 1:4 matching).",
      "- **R2** - proportion of the exposure's variation explained by other covariates in the model; 0 if none.",
      "",
      "With **one control per case** this is the comparison of paired means: the SD of the case-control differences is",
      "sigma x sqrt(2), and the number is the z-test version of the paired t-test (which asks for one or two more pairs).",
      "Each extra control adds less: with m controls the number of cases is (m + 1) / m times K, i.e. 2K for 1:1, 1.5K for",
      "1:2, 1.33K for 1:3, 1.25K for 1:4.",
      "",
      "**Two or more cases per set:** the information per set used here is nD x nH / (nD + nH), the null variance of the",
      "cases' total. Lachin's paper writes nD x [1 - 1 / C(nD + nH, nD)] (eq. 22-23, 35), which is the same for one case per",
      "set but larger for two or more; simulated data analysed with conditional logistic regression (1500 data sets per",
      "design) reach the planned 80% power with the factor used here and 51-66% with the paper's. powerSurvEpi's",
      "powerConLogistic.bin() uses the factor used here; its powerConLogistic.con() uses the paper's.",
      sep = "\n"
    ),
    worked_example = paste(
      "**Measured exposure** -- Lachin (2008), sec. 4.1: 125 cases with 2 matched controls each give 85% power (two-sided",
      "alpha 0.05) for an odds ratio of 1.39 per SD. This calculator, with the odds ratio per SD 1.39, nD = 1, nH = 2 and 85%",
      "power, returns 125 sets (375 subjects). For the biomarker of that example (SD 8.41) the same effect is an odds ratio of",
      "1.040 per unit, or cases 2.77 above their controls on average (the paper, rounding theta to 0.038, gives 2.69; with 2.69",
      "the calculator returns 132 sets).",
      "",
      "**Exposure present or absent** -- the example of powerSurvEpi::powerConLogistic.bin(): OR = 3.5, pE = 0.15, 1:2",
      "matching, R2 = 0, alpha 0.05, 80% power: 59 sets (177 subjects).",
      sep = "\n"
    ),
    citation = paste(
      "Lachin JM. Sample size evaluation for a multiply matched case-control study using the score test from a conditional",
      "logistic (discrete Cox PH) regression model. Stat Med 2008;27(14):2509-2523. doi:10.1002/sim.3057 (PMC3626499); eq. 25,",
      "27, 32, 34, 35 and the examples of sec. 4.1. Erratum: Stat Med 2018;37(10):1765-1766. doi:10.1002/sim.7598 (corrects eq.",
      "28 only). Not read: Tang Y. Comments on Lachin (2008). Stat Med 2009;28(1):175-177, with the author's reply."
    ),
    backend = paste(
      "closed form written out in the app; equal to powerSurvEpi::powerConLogistic.bin() throughout, and to",
      "powerConLogistic.con() for one case per set (compared with the package in the tests; the package is not a dependency).",
      "Checked by simulation with survival::clogit (5 Nov 2026)."
    )
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
