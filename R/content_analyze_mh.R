# Metadata for the Analyze: Mantel-Haenszel module (ROADMAP Track B1): formula
# text, plain-language explanation, worked example and citation per design.
# Content is data, rendered generically by mod_analyze_mh.R.

.analyze_mh_formulas <- paste0(
  "For stratum $i$ with cells $a_i,b_i,c_i,d_i$, margins $N_{1i}=a_i+b_i$, $N_{0i}=c_i+d_i$, $M_{1i}=a_i+c_i$ and total $T_i$:",
  "$$\\widehat{OR}_{MH}=\\frac{\\sum_i a_id_i/T_i}{\\sum_i b_ic_i/T_i},\\qquad ",
  "\\widehat{RR}_{MH}=\\frac{\\sum_i a_iN_{0i}/T_i}{\\sum_i c_iN_{1i}/T_i},\\qquad ",
  "\\widehat{RD}_{MH}=\\frac{\\sum_i (a_iN_{0i}-c_iN_{1i})/T_i}{\\sum_i N_{1i}N_{0i}/T_i}$$",
  "$$\\chi^2_{MH}=\\frac{\\left(\\sum_i a_i-E_i\\right)^2}{\\sum_i V_i},\\quad E_i=\\frac{N_{1i}M_{1i}}{T_i},\\ ",
  "V_i=\\frac{N_{1i}N_{0i}M_{1i}M_{0i}}{T_i^2(T_i-1)}\\quad(1\\ \\mathrm{df})$$",
  "$$\\chi^2_{\\text{Woolf}}=\\sum_i w_i\\left(\\ln\\widehat{OR}_i-\\ln\\widehat{OR}_W\\right)^2,\\ w_i=1/\\operatorname{Var}(\\ln\\widehat{OR}_i);\\qquad ",
  "\\chi^2_{BD}=\\sum_i\\frac{(a_i-A_i^*)^2}{\\operatorname{Var}(a_i\\mid \\widehat{OR}_{MH})}\\quad(k-1\\ \\mathrm{df})$$",
  "where $A_i^*$ is the expected $a_i$ when the stratum odds ratio equals $\\widehat{OR}_{MH}$; Tarone's correction subtracts ",
  "$\\left(\\sum_i (a_i-A_i^*)\\right)^2/\\sum_i \\operatorname{Var}_i$. Intervals use the Robins-Breslow-Greenland variance ",
  "of $\\ln\\widehat{OR}_{MH}$, the Greenland-Robins variance of $\\ln\\widehat{RR}_{MH}$ and Sato's variance of $\\widehat{RD}_{MH}$."
)

.analyze_mh_layout <- paste(
  "Enter one row per **stratum** (a level of the confounder, e.g. an age group). Each stratum is a",
  "2x2 table: **a** = exposed with the outcome, **b** = exposed without, **c** = unexposed with,",
  "**d** = unexposed without. Between 2 and 8 strata can be entered.",
  "",
  sep = "\n"
)

.analyze_mh_citation <- paste(
  "Mantel N, Haenszel W. Statistical aspects of the analysis of data from retrospective studies of disease.",
  "J Natl Cancer Inst 1959;22:719-748; Robins J, Breslow N, Greenland S. Estimators of the Mantel-Haenszel",
  "variance consistent in both sparse data and large-strata limiting models. Biometrics 1986;42:311-323;",
  "Greenland S, Robins JM. Estimation of a common effect parameter from sparse follow-up data. Biometrics",
  "1985;41:55-68; Sato T. On the variance estimator for the Mantel-Haenszel risk difference. Biometrics",
  "1989;45:1323-1324; Woolf B. Ann Hum Genet 1955;19:251-253; Breslow NE, Day NE. Statistical Methods in",
  "Cancer Research, Vol 1. IARC; 1980; Tarone RE. On heterogeneity tests based on efficient scores.",
  "Biometrika 1985;72:431-435. Cross-checked against epiR::epi.2by2(), stats::mantelhaen.test() and",
  "DescTools::BreslowDayTest()."
)

analyze_mh_content <- list(
  cohort = list(
    title = "Mantel-Haenszel analysis of stratified 2x2 tables: cohort / trial / cross-sectional",
    formula_latex = .analyze_mh_formulas,
    explanation = paste(
      .analyze_mh_layout,
      "Use this to **adjust an exposure-outcome association for a confounder** by stratifying on it.",
      "The app gives the crude (collapsed) and the Mantel-Haenszel adjusted odds ratio, risk ratio and risk",
      "difference with confidence intervals, and the change from crude to adjusted: a change of more than about",
      "10% is the usual rule of thumb for confounding.",
      "",
      "Before trusting one pooled number, look at the **homogeneity tests** (Woolf, Breslow-Day, Tarone): a small",
      "p-value means the effect differs between strata (effect modification) and a single pooled estimate can",
      "mislead; report the stratum-specific estimates instead. These tests have little power with few or small",
      "strata, so a non-significant result does not prove the effect is the same everywhere. The",
      "**Cochran-Mantel-Haenszel test** asks whether exposure and outcome are associated after accounting for the strata.",
      "",
      "Mantel-Haenszel estimators remain valid when some strata have zero cells (their advantage over",
      "inverse-variance pooling); the Woolf tests need all four cells non-zero, so they use only those strata.",
      "Nothing is added to the cells.",
      sep = "\n"
    ),
    worked_example = paste(
      "Illustration (hypothetical counts, not from a study): three strata with (a, b, c, d) = (20, 10, 15, 45),",
      "(30, 25, 20, 60) and (12, 8, 40, 70). Mantel-Haenszel OR = 3.80 (95% CI 2.31 to 6.26), RR = 2.14",
      "(1.63 to 2.80), RD = 0.316 (0.204 to 0.428); CMH chi-square = 29.13 (1 df), p < 0.001; Breslow-Day = 1.455",
      "(2 df), p = 0.48: no evidence the stratum effects differ. These figures equal `epiR::epi.2by2()`,",
      "`stats::mantelhaen.test()` and `DescTools::BreslowDayTest()` on the same tables.",
      sep = "\n"
    ),
    citation = .analyze_mh_citation,
    backend = "closed-form Mantel-Haenszel estimators and tests; verified against epiR::epi.2by2(), mantelhaen.test(), DescTools::BreslowDayTest()"
  ),
  case_control = list(
    title = "Mantel-Haenszel analysis of stratified 2x2 tables: case-control",
    formula_latex = .analyze_mh_formulas,
    explanation = paste(
      .analyze_mh_layout,
      "For a case-control study (subjects sampled by outcome: **a** and **c** are the cases, **b** and **d** the",
      "controls) only the **odds ratio** is reported -- crude and Mantel-Haenszel adjusted, with confidence",
      "intervals -- together with the Cochran-Mantel-Haenszel test and the homogeneity tests of the stratum odds",
      "ratios. Risk ratios and risk differences cannot be estimated from a case-control sample.",
      sep = "\n"
    ),
    worked_example = paste(
      "The same three illustration strata read as a case-control study give the same pooled odds ratio,",
      "3.80 (95% CI 2.31 to 6.26), CMH chi-square 29.13 and Breslow-Day 1.455 (2 df).",
      sep = "\n"
    ),
    citation = .analyze_mh_citation,
    backend = "closed-form Mantel-Haenszel estimators and tests; verified against epiR::epi.2by2(), mantelhaen.test(), DescTools::BreslowDayTest()"
  )
)
