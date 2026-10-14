# Metadata for the Analyze: Diagnostic Test Evaluation module (ROADMAP Track B1):
# formula text, plain-language explanation, worked example and citation per
# design. Content is data, rendered generically by mod_analyze_dx.R.

.analyze_dx_layout <- paste(
  "The counts are laid out as **test result by true disease status**:",
  "",
  "|  | Disease + | Disease - |",
  "|---|---|---|",
  "| Test + | TP | FP |",
  "| Test - | FN | TN |",
  "",
  sep = "\n"
)

analyze_dx_content <- list(
  single = list(
    title = "Diagnostic test evaluation from a 2x2 table",
    formula_latex = paste0(
      "$$Se=\\frac{TP}{TP+FN},\\quad Sp=\\frac{TN}{TN+FP},\\quad PPV=\\frac{TP}{TP+FP},\\quad NPV=\\frac{TN}{TN+FN}$$",
      "$$LR^{+}=\\frac{Se}{1-Sp},\\quad LR^{-}=\\frac{1-Se}{Sp},\\quad ",
      "\\operatorname{SE}(\\ln LR^{+})=\\sqrt{\\tfrac1{TP}-\\tfrac1{TP+FN}+\\tfrac1{FP}-\\tfrac1{FP+TN}}$$",
      "At a stated prevalence $\\pi$ the predictive values follow from Bayes' rule,",
      "$$PPV=\\frac{Se\\,\\pi}{Se\\,\\pi+(1-Sp)(1-\\pi)},\\quad NPV=\\frac{Sp\\,(1-\\pi)}{Sp\\,(1-\\pi)+(1-Se)\\,\\pi}$$",
      "with logit-scale interval $\\operatorname{expit}\\{\\operatorname{logit}(\\widehat{PPV})\\pm z\\,\\operatorname{SE}(\\ln LR^{+})\\}$ ",
      "and, for NPV, $\\operatorname{SE}(\\ln LR^{-})$ -- prevalence only shifts the logit."
    ),
    explanation = paste(
      .analyze_dx_layout,
      "**Sensitivity** and **specificity** are properties of the test; their intervals are binomial,",
      "either Clopper-Pearson *exact* (the default; never narrower than it should be) or Wilson *score*.",
      "",
      "**PPV and NPV depend on prevalence.** Read straight from the counts they describe the sample, so",
      "they are only meaningful if the sample's disease prevalence is the prevalence you care about",
      "(a cross-sectional or cohort sample). If subjects were sampled by disease status (a case-control",
      "style evaluation), or you want the values in another setting, choose *At a stated prevalence*:",
      "PPV and NPV are then recomputed from Se and Sp by Bayes' rule, with an approximate (delta-method)",
      "interval that is accurate for moderate or large samples and can be too narrow when a cell count",
      "is very small.",
      "",
      "A zero cell leaves the affected likelihood-ratio interval undefined; nothing is added to the cells.",
      sep = "\n"
    ),
    worked_example = paste(
      "Scott et al. (2008), Table 1, as used in the `epiR::epi.tests()` help page: a new test was trialled",
      "on 1586 patients; 670 of the 744 disease-positive patients tested positive and 640 of the 842",
      "disease-negative patients tested negative (TP = 670, FP = 202, FN = 74, TN = 640).",
      "Sensitivity is 0.90 (95% CI 0.88 to 0.92), specificity 0.76 (0.73 to 0.79) and the positive",
      "likelihood ratio 3.75 (3.32 to 4.24) -- the published figures, reproduced by this calculator.",
      "From the counts PPV = 0.77 (0.74 to 0.80) and NPV = 0.90 (0.87 to 0.92). At a prevalence of 10%",
      "the same test has PPV 0.29 and NPV 0.99.",
      sep = "\n"
    ),
    citation = paste(
      "Clopper CJ, Pearson ES. The use of confidence or fiducial limits illustrated in the case of the",
      "binomial. Biometrika 1934;26:404-413; Wilson EB. Probable inference, the law of succession, and",
      "statistical inference. J Am Stat Assoc 1927;22:209-212; Simel DL, Samsa GP, Matchar DB. Likelihood",
      "ratios with confidence: sample size estimation for diagnostic test studies. J Clin Epidemiol",
      "1991;44:763-770; Mercaldo ND, Lau KF, Zhou XH. Confidence intervals for predictive values with an",
      "emphasis to case-control studies. Stat Med 2007;26:2170-2183; Scott IA, et al. 2008 (Table 1, as",
      "cited in the epiR::epi.tests() help page). Cross-checked against epiR::epi.tests()."
    ),
    backend = "closed-form estimators (Clopper-Pearson / Wilson, Simel, Mercaldo); verified against epiR::epi.tests()"
  ),
  combined = list(
    title = "Combining 2 to 6 tests: serial and parallel testing",
    formula_latex = paste0(
      "$$\\text{Parallel (positive if ANY test is positive):}\\quad Se=1-\\prod_i(1-Se_i),\\quad Sp=\\prod_i Sp_i$$",
      "$$\\text{Serial (positive only if ALL tests are positive):}\\quad Se=\\prod_i Se_i,\\quad Sp=1-\\prod_i(1-Sp_i)$$",
      "$$PPV=\\frac{Se\\,\\pi}{Se\\,\\pi+(1-Sp)(1-\\pi)},\\qquad NPV=\\frac{Sp\\,(1-\\pi)}{Sp\\,(1-\\pi)+(1-Se)\\,\\pi}$$",
      "Intervals (when the numbers of diseased and non-diseased subjects behind each test are given): ",
      "$\\operatorname{Var}(Se)=\\sum_i\\left(\\partial Se/\\partial Se_i\\right)^2 Se_i(1-Se_i)/n_{D,i}$, likewise for $Sp$ ",
      "with $n_{\\bar D,i}$, then the logit-scale delta method."
    ),
    explanation = paste(
      "Give each test's sensitivity and specificity (in %) and the **prevalence of disease in the",
      "population the testing strategy will be used in**. Between 2 and 6 tests can be combined.",
      "",
      "- **Parallel testing** (all tests done together; positive if *any* is positive) *raises*",
      "  sensitivity and lowers specificity -- useful for ruling a disease out (high NPV).",
      "- **Serial testing** (a second test only after a positive first; positive only if *all* are",
      "  positive) *lowers* sensitivity and raises specificity -- useful for confirming disease (high PPV).",
      "",
      "**Assumption: the tests are conditionally independent given disease status**, i.e. a diseased",
      "patient's results on different tests are independent. Tests that measure related things are",
      "usually positively dependent, and then the real combined performance is worse than shown (the",
      "gain in parallel sensitivity and in serial specificity is overstated); see Vacek (1985). For",
      "dependent tests estimate the joint results directly in a study.",
      "",
      "Optionally enter the number of diseased and non-diseased subjects behind each test's figures to",
      "get 95% confidence intervals for the combined sensitivity, specificity, PPV and NPV. They treat",
      "each test's figures as independent estimates (separate samples); if all tests were done on the",
      "same patients they are approximate. Leave the numbers blank to get point estimates only.",
      sep = "\n"
    ),
    worked_example = paste(
      "Illustrative figures (not from a study): three tests with sensitivities 90%, 80%, 85% and",
      "specificities 70%, 90%, 80%, used where 10% of those tested have the disease.",
      "Parallel: Se = 1 - 0.1 x 0.2 x 0.15 = 99.7%, Sp = 0.7 x 0.9 x 0.8 = 50.4%, PPV 18.3%, NPV 99.9%.",
      "Serial: Se = 0.9 x 0.8 x 0.85 = 61.2%, Sp = 1 - 0.3 x 0.1 x 0.2 = 99.4%, PPV 91.9%, NPV 95.7%.",
      "The unit tests verify these formulas by enumerating every one of the 2^k result patterns.",
      sep = "\n"
    ),
    citation = paste(
      "Product rule for independent events (derivation checked by exhaustive enumeration of result",
      "patterns in the unit tests); Vacek PM. The effect of conditional dependence on the evaluation of",
      "diagnostic tests. Biometrics 1985;41:959-968 (the independence assumption); logit-scale delta-method",
      "intervals as in Mercaldo ND, Lau KF, Zhou XH. Stat Med 2007;26:2170-2183."
    ),
    backend = "closed-form product rule; delta-method intervals (checked against simulation)"
  )
)
