# Metadata for the Analyze: 2x2 table module (ROADMAP Track B1): formula text,
# plain-language explanation, worked example and citation per design. Content is
# data, rendered generically by mod_analyze_2x2.R.

.analyze_2x2_formulas <- paste0(
  "$$\\widehat{RR}=\\frac{a/(a+b)}{c/(c+d)},\\quad ",
  "\\operatorname{SE}(\\ln \\widehat{RR})=\\sqrt{\\tfrac1a-\\tfrac1{a+b}+\\tfrac1c-\\tfrac1{c+d}}$$",
  "$$\\widehat{OR}=\\frac{ad}{bc},\\quad \\operatorname{SE}(\\ln \\widehat{OR})=\\sqrt{\\tfrac1a+\\tfrac1b+\\tfrac1c+\\tfrac1d}$$",
  "$$\\widehat{RD}=\\hat p_1-\\hat p_0,\\quad \\operatorname{SE}=\\sqrt{\\tfrac{\\hat p_1(1-\\hat p_1)}{a+b}+\\tfrac{\\hat p_0(1-\\hat p_0)}{c+d}}$$",
  "$$AF_e=\\frac{RR-1}{RR},\\qquad PAF=\\frac{ad-bc}{(a+c)(c+d)},\\qquad NNT=\\frac{1}{|RD|}$$",
  "Intervals for RR and OR are $\\exp(\\ln\\hat\\theta \\pm z\\,\\operatorname{SE})$; for $AF_e$ the RR limits are transformed; ",
  "for PAF, $1-\\exp\\{\\ln(1-PAF)\\mp z\\sqrt{\\operatorname{Var}}\\}$ with $\\operatorname{Var}=(b+PAF\\,(a+d))/(N\\,c)$."
)

.analyze_2x2_layout <- paste(
  "The table is laid out with **rows = exposure** and **columns = outcome**:",
  "",
  "|  | Outcome + | Outcome - |",
  "|---|---|---|",
  "| Exposed | a | b |",
  "| Unexposed | c | d |",
  "",
  sep = "\n"
)

.analyze_2x2_citation <- paste(
  "Katz D, Baptista J, Azen SP, Pike MC. Obtaining confidence intervals for the relative risk in",
  "cohort studies. Biometrics 1978;34:469-474; Woolf B. On estimating the relation between blood group",
  "and disease. Ann Hum Genet 1955;19:251-253; Jewell NP. Statistics for Epidemiology. Chapman & Hall/CRC;",
  "2004; Altman DG. Confidence intervals for the number needed to treat. BMJ 1998;317:1309-1312;",
  "Rothman KJ, Greenland S, Lash TL. Modern Epidemiology. 3rd ed. Lippincott Williams & Wilkins; 2008.",
  "Cross-checked against epiR::epi.2by2() (Stevenson M, et al., epiR package)."
)

analyze_2x2_content <- list(
  cohort = list(
    title = "2x2 table: cohort study (risk ratio, risk difference)",
    formula_latex = .analyze_2x2_formulas,
    explanation = paste(
      .analyze_2x2_layout,
      "Use this when subjects were followed from exposure to outcome (a cohort study or a trial arm",
      "comparison), so the **risk** of the outcome in each exposure group is estimable. You get the risk",
      "ratio, odds ratio, risk difference, the attributable fraction among the exposed, the population",
      "attributable fraction and the number needed to treat (benefit) or harm, each with a Wald-type",
      "confidence interval, plus Pearson's chi-square and Fisher's exact test.",
      "",
      "A cell of zero makes the log-based interval undefined; the app reports that rather than adding 0.5",
      "to every cell. Fisher's exact test is the safer test when an expected count is below 5.",
      sep = "\n"
    ),
    worked_example = paste(
      "Willeberg (1977), as used in the `epiR::epi.2by2()` help page: 13 of 2176 cats fed dry cat food and",
      "5 of 3354 cats not fed it developed feline urologic syndrome (a = 13, b = 2163, c = 5, d = 3349).",
      "Treated as a cohort the risk ratio is 4.01 (95% CI 1.43 to 11.23) and 75% (95% CI 30% to 91%) of",
      "the cases among the exposed are attributable to the exposure -- the figures published with that",
      "example, reproduced by this calculator.",
      sep = "\n"
    ),
    citation = .analyze_2x2_citation,
    backend = "closed-form estimators (Katz, Woolf, Wald, Jewell, Altman); verified against epiR::epi.2by2(method = \"cohort.count\")"
  ),
  cross_sectional = list(
    title = "2x2 table: cross-sectional study (prevalence ratio, prevalence difference)",
    formula_latex = .analyze_2x2_formulas,
    explanation = paste(
      .analyze_2x2_layout,
      "Use this when exposure and outcome were measured together at one time (a survey or",
      "cross-sectional study). The formulas are those of the cohort table but the quantities are",
      "**prevalences**: you get the prevalence ratio and difference rather than risks, together with the",
      "odds ratio, the attributable fractions and the number needed, each with a confidence interval.",
      "Temporal order is not established, so read the attributable fractions as associations rather than",
      "causal effects.",
      sep = "\n"
    ),
    worked_example = paste(
      "Willeberg (1977), the `epiR::epi.2by2()` cross-sectional example: 13 of 2176 cats fed dry cat food",
      "and 5 of 3354 cats not fed it had feline urologic syndrome (a = 13, b = 2163, c = 5, d = 3349).",
      "The prevalence in exposed cats was 4.01 (95% CI 1.43 to 11.23) times that in unexposed cats, and",
      "75% (95% CI 30% to 91%) of the cases among exposed cats were attributable to the exposure.",
      sep = "\n"
    ),
    citation = .analyze_2x2_citation,
    backend = "closed-form estimators (Katz, Woolf, Wald, Jewell, Altman); verified against epiR::epi.2by2(method = \"cross.sectional\")"
  ),
  case_control = list(
    title = "2x2 table: case-control study (odds ratio)",
    formula_latex = .analyze_2x2_formulas,
    explanation = paste(
      .analyze_2x2_layout,
      "Use this when subjects were sampled by **outcome** (cases and controls). Risks cannot be estimated",
      "from such a sample, so only the **odds ratio** is reported (with a Woolf interval), together with",
      "the exposed attributable fraction $(OR-1)/OR$ -- valid as an estimate of the fraction among the",
      "exposed cases when the outcome is rare -- and the population attributable fraction (Jewell 2004),",
      "which uses the exposure prevalence among the cases.",
      "",
      "Here, 'Exposed' and 'Unexposed' are the rows and 'Outcome +' the cases (a + c) and 'Outcome -' the",
      "controls (b + d).",
      sep = "\n"
    ),
    worked_example = paste(
      "The Willeberg (1977) counts again (a = 13, b = 2163, c = 5, d = 3349), now read as a case-control",
      "sample: odds ratio 4.03 (95% CI 1.43 to 11.31), population attributable fraction 54.3% (95% CI 3.7%",
      "to 78.3%) -- the figures `epiR::epi.2by2(method = \"case.control\")` returns for the same counts.",
      sep = "\n"
    ),
    citation = .analyze_2x2_citation,
    backend = "closed-form estimators (Woolf, Jewell); verified against epiR::epi.2by2(method = \"case.control\")"
  )
)
