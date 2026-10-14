# Metadata for the Logistic Regression module: formula text,
# plain-language explanation, worked example, and citation. Content is
# data, rendered generically by mod_logistic.R (SDD 4.2: "content is
# data, not hardcoded UI").

logistic_content <- list(
  binary = list(
    title = "Simple Logistic Regression -- Binary Predictor",
    formula_latex = paste0(
      "$$n = \\frac{\\left(Z_{1-\\alpha/2}\\sqrt{p(1-p)/B} + ",
      "Z_{power}\\sqrt{p_1(1-p_1)+p_2(1-p_2)(1-B)/B}\\right)^2}",
      "{(p_1-p_2)^2(1-B)}$$"
    ),
    explanation = paste(
      "Use this to size a study whose primary analysis is a simple",
      "logistic regression, logit(p) = beta0 + beta1*X, with a **binary**",
      "predictor X (e.g. exposed vs. unexposed), testing whether",
      "beta1 = 0 (equivalently, whether the odds ratio for X equals 1).",
      "",
      "- **p1** - the event rate (outcome prevalence) when X = 0.",
      "- **p2** - the event rate when X = 1.",
      "- **prop_x1** - the proportion of the sample expected to have",
      "  X = 1.",
      "- **alpha, power** - as elsewhere (two-sided test).",
      sep = "\n"
    ),
    worked_example = paste(
      "Hsieh, Bloch & Larsen (1998), Table I \"Balanced design with high",
      "event rates\": p1 = 0.4, p2 = 0.5, a balanced predictor",
      "(prop_x1 = 0.5), alpha = 0.05 (two-sided), 95% power. This",
      "calculator returns n = 1281, matching the paper's own published",
      "table exactly.",
      sep = "\n"
    ),
    citation = paste(
      "Hsieh FY, Bloch DA, Larsen MD. A simple method of sample size",
      "calculation for linear and logistic regression. Stat Med.",
      "1998;17(14):1623-1634."
    ),
    backend = "powerMediation::SSizeLogisticBin()"
  ),
  continuous = list(
    title = "Simple Logistic Regression -- Continuous Predictor",
    formula_latex = paste0(
      "$$n = \\frac{\\left(Z_{1-\\alpha/2}+Z_{power}\\right)^2}",
      "{p_1(1-p_1)\\,[\\log(OR)]^2}$$"
    ),
    explanation = paste(
      "Use this to size a study whose primary analysis is a simple",
      "logistic regression with a **continuous** predictor X (e.g. age,",
      "a biomarker level), testing whether beta1 = 0 (equivalently,",
      "whether the odds ratio equals 1).",
      "",
      "- **p1** - the event rate at the mean of the predictor X.",
      "- **OR** - the expected odds ratio for a one-SD increase in X.",
      "- **alpha, power** - as elsewhere (two-sided test).",
      sep = "\n"
    ),
    worked_example = paste(
      "Hsieh, Bloch & Larsen (1998), Table II \"Balanced design (1)\":",
      "p1 = 0.5, OR = exp(0.405) (a one-SD increase in X roughly",
      "1.5-folds the odds), alpha = 0.05 (two-sided), 95% power. This",
      "calculator returns n = 317, matching the paper's own published",
      "table exactly.",
      sep = "\n"
    ),
    citation = paste(
      "Hsieh FY, Bloch DA, Larsen MD. A simple method of sample size",
      "calculation for linear and logistic regression. Stat Med.",
      "1998;17(14):1623-1634."
    ),
    backend = "powerMediation::SSizeLogisticCon()"
  ),
  ordinal = list(
    title = "Ordinal (Proportional Odds) Logistic Regression -- Two Groups",
    formula_latex = paste0(
      "$$n \\text{ solved from Whitehead (1993)'s proportional-odds}$$",
      "$$\\text{information formula, given } p_1,\\dots,p_k, \\text{OR}, \\alpha, \\text{power}$$"
    ),
    explanation = paste(
      "Use this to compare two groups on an **ordinal** outcome with 3 or",
      "more ordered categories (e.g. none/mild/moderate/severe pain) via",
      "the proportional-odds model, rather than a binary outcome -- the",
      "generalization of the binary logistic regression designs above to",
      "an ordered categorical response. The power of this test equals the",
      "power of a Wilcoxon rank-sum test on the same data, but with ties",
      "(repeated category values) handled properly.",
      "",
      "- **p (category probabilities)** - the expected proportion of",
      "  subjects in each ordered category, AVERAGED over the two groups",
      "  (must sum to 1). E.g. for a 4-category pain scale you might",
      "  expect 10% none, 20% mild, 40% moderate, 30% severe.",
      "- **Odds ratio** - the odds ratio between the two groups under the",
      "  proportional-odds assumption (the same odds ratio applies at",
      "  every category cutpoint).",
      "- **Allocation fraction** - the proportion of the sample in group 1",
      "  (0.5 for equal allocation).",
      "- **alpha, power** - as elsewhere.",
      "",
      "This also reports the design's efficiency relative to an equivalent",
      "study with a fully continuous (not categorized) response -- fewer",
      "categories, or categories with very unequal probabilities, lose",
      "some efficiency relative to a continuous outcome.",
      sep = "\n"
    ),
    worked_example = paste(
      "Back-pain severity study, from Hmisc's own documented example:",
      "4 ordered categories (none/mild/moderate/severe) with expected",
      "probabilities p = (0.1, 0.2, 0.4, 0.3), an odds ratio of 1.2",
      "between two treatment groups, equal allocation, alpha = 0.05",
      "(two-sided), 80% power. This calculator returns n = 3149 (the",
      "design's efficiency relative to a continuous response is 0.90) --",
      "reproduced exactly by directly running Hmisc::posamsize(), and",
      "cross-checked by running Hmisc::popower() at n = 3148, which",
      "reproduces power = 0.80 exactly.",
      sep = "\n"
    ),
    citation = paste(
      "Whitehead J. Sample size calculations for ordered categorical",
      "data. Stat Med. 1993;12(24):2257-2271; Julious SA, Campbell MJ.",
      "Letter to the Editor. Stat Med. 1996;15(10):1065-1066 (confirms",
      "the formula's accuracy for the binary-response special case). (as",
      "implemented by Hmisc::posamsize()/popower(), Frank Harrell)."
    ),
    backend = "Hmisc::posamsize()"
  ),
  binary_adjusted = list(
    title = "Multiple Logistic Regression, Covariate-Adjusted -- Binary Predictor",
    formula_latex = paste0(
      "$$n_{\\text{multiple}} = \\frac{n_{\\text{simple}}}{1-R^2}$$"
    ),
    explanation = paste(
      "Use this when the predictor of interest (binary) will be entered",
      "into a MULTIPLE logistic regression model ALONGSIDE other",
      "covariates (e.g. adjusting for age, sex, or baseline severity),",
      "rather than alone. Hsieh, Bloch & Larsen (1998) -- the same paper",
      "behind the simple binary-predictor design above -- show that the",
      "simple-model sample size must be inflated by the variance",
      "inflation factor 1 / (1 - R-squared), exactly the same style of",
      "correction already used elsewhere in this app for Cox regression",
      "(the \"squared correlation with adjustment covariate\" term in the",
      "Log-Rank / Survival module's Cox designs).",
      "",
      "- **p1, p2, prop_x1** - as in the simple binary-predictor design.",
      "- **R-squared** - the squared multiple correlation between the",
      "  predictor of interest and the OTHER covariates in the model (0 =",
      "  uncorrelated with the other covariates, reducing to the simple",
      "  case; closer to 1 means the other covariates largely predict this",
      "  one, requiring more collinearity-adjusted information).",
      "- **alpha, power** - as elsewhere (two-sided test).",
      sep = "\n"
    ),
    worked_example = paste(
      "At R-squared = 0, this reduces EXACTLY to the simple-predictor",
      "design's own worked example (Hsieh, Bloch & Larsen 1998, Table I:",
      "p1=0.4, p2=0.5, prop_x1=0.5, alpha=0.05, 95% power -> n=1281). At",
      "R-squared = 0.5, the required n exactly doubles to n=2562 -- the",
      "variance inflation factor 1/(1-0.5) = 2, applied directly to the",
      "already-verified simple-model n.",
      sep = "\n"
    ),
    citation = paste(
      "Hsieh FY, Bloch DA, Larsen MD. A simple method of sample size",
      "calculation for linear and logistic regression. Stat Med.",
      "1998;17(14):1623-1634 (variance inflation factor for multiple",
      "covariates)."
    ),
    backend = "closed-form wrapper around powerMediation::SSizeLogisticBin()"
  ),
  continuous_adjusted = list(
    title = "Multiple Logistic Regression, Covariate-Adjusted -- Continuous Predictor",
    formula_latex = paste0(
      "$$n_{\\text{multiple}} = \\frac{n_{\\text{simple}}}{1-R^2}$$"
    ),
    explanation = paste(
      "Same variance-inflation adjustment as the binary-predictor version",
      "above, applied instead to the simple continuous-predictor design.",
      "",
      "- **p1, or** - as in the simple continuous-predictor design.",
      "- **R-squared** - the squared multiple correlation between the",
      "  predictor of interest and the OTHER covariates in the model.",
      "- **alpha, power** - as elsewhere (two-sided test).",
      sep = "\n"
    ),
    worked_example = paste(
      "At R-squared = 0, this reduces EXACTLY to the simple-predictor",
      "design's own worked example (Hsieh, Bloch & Larsen 1998, Table II:",
      "p1=0.5, OR=exp(0.405), alpha=0.05, 95% power -> n=317). At",
      "R-squared = 0.3, the required n is the same n divided by 0.7,",
      "matching the variance inflation factor exactly.",
      sep = "\n"
    ),
    citation = paste(
      "Hsieh FY, Bloch DA, Larsen MD. A simple method of sample size",
      "calculation for linear and logistic regression. Stat Med.",
      "1998;17(14):1623-1634 (variance inflation factor for multiple",
      "covariates)."
    ),
    backend = "closed-form wrapper around powerMediation::SSizeLogisticCon()"
  )
)
