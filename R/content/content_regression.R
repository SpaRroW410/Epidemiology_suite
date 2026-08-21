# Metadata for the Multiple Regression module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_regression.R (SDD 4.2: "content is data, not
# hardcoded UI").

regression_content <- list(
  r2 = list(
    title = "Multiple Linear Regression, R-Squared Deviation From Zero",
    formula_latex = paste0(
      "$$f^2 = \\frac{R^2}{1 - R^2}$$",
      "$$n = v + u + 1 \\quad \\text{(} u \\text{ = predictors, } v \\text{ solved from } f^2, \\alpha, \\text{power)}$$"
    ),
    explanation = paste(
      "This calculator finds the sample size needed to detect that a",
      "multiple linear regression model's overall R-squared is",
      "significantly greater than zero, given a fixed number of predictors",
      "-- the \"fixed model, R-squared deviation from zero\" test in Cohen",
      "(1988).",
      "",
      "- **r2** - the R-squared you expect the full model to achieve.",
      "- **num_predictors** - the number of predictor variables in the",
      "  model (a categorical predictor with k levels contributes k-1).",
      "- **alpha, power** - as elsewhere.",
      "",
      "f^2 = R^2 / (1 - R^2) is Cohen's effect size for this test (small",
      "~0.02, medium ~0.15, large ~0.35). This only tests whether the model",
      "explains more variance than chance overall -- it says nothing about",
      "which individual predictors are significant, or about testing an",
      "R-squared *increase* from adding a specific set of predictors to an",
      "existing model (a related but separate test, not covered here).",
      sep = "\n"
    ),
    worked_example = paste(
      "Cohen (1988)'s own effect-size convention (Exercise 9.1, p. 424):",
      "R-squared = 0.10 (a small-to-medium effect, f^2 = 0.1111) with 5",
      "predictors. At alpha = 0.05 and 80% power, this calculator returns",
      "n = 122. As a check on the underlying method: Cohen's own textbook",
      "exercise with this same f^2, u = 5 predictors and v = 89 denominator",
      "df (n = 95) gives an achieved power of 0.6736 -- reproduced exactly",
      "by pwr::pwr.f2.test().",
      sep = "\n"
    ),
    citation = paste(
      "Cohen J. Statistical Power Analysis for the Behavioral Sciences.",
      "2nd ed. Hillsdale, NJ: Lawrence Erlbaum Associates; 1988, Exercise",
      "9.1 p. 424. (as implemented by pwr::pwr.f2.test)."
    ),
    backend = "pwr::pwr.f2.test()"
  )
)
