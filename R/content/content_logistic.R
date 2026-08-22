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
  )
)
