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
    backend = "closed form written out in the app, equal to pwr::pwr.f2.test() (compared with the package in the tests; the package is not a dependency)"
  ),
  r2_increase = list(
    title = "Hierarchical Multiple Regression, R-Squared Increase",
    formula_latex = paste0(
      "$$f^2 = \\frac{R^2_{full} - R^2_{reduced}}{1 - R^2_{full}}$$",
      "$$n = v + p_{total} + 1 \\quad \\text{(} u \\text{ = predictors added, } v \\text{ solved from } f^2, \\alpha, \\text{power)}$$"
    ),
    explanation = paste(
      "This calculator finds the sample size needed to detect that adding a",
      "set of new predictors to an existing (\"reduced\") regression model",
      "significantly increases R-squared -- the \"fixed model, R-squared",
      "increase\" test in Cohen (1988, section 9.7). This is a different",
      "question than the plain R-squared-vs-zero test above: here the",
      "reduced model's predictors are already in the model, and the",
      "question is whether the *new* predictors add anything.",
      "",
      "- **r2_reduced** - the R-squared of the existing model, without the",
      "  new predictors.",
      "- **r2_full** - the R-squared of the full model, with the new",
      "  predictors added (must exceed r2_reduced).",
      "- **num_predictors_added** - the number of new predictors being",
      "  added (a categorical predictor with k levels contributes k-1).",
      "- **num_predictors_total** - the total number of predictors in the",
      "  full model (reduced-model predictors plus the added ones).",
      "- **alpha, power** - as elsewhere.",
      "",
      "f^2 = (R^2_full - R^2_reduced) / (1 - R^2_full) is Cohen's effect",
      "size for this test, tested with u = the number of added predictors",
      "and v = the full model's residual degrees of freedom.",
      sep = "\n"
    ),
    worked_example = paste(
      "A reduced model with 3 predictors achieves R-squared = 0.30; adding",
      "2 more predictors (5 total) raises it to R-squared = 0.40, giving",
      "f^2 = (0.40 - 0.30) / (1 - 0.40) = 0.1667. At alpha = 0.05 and 80%",
      "power, this calculator returns n = 64 (v = 58 denominator df from",
      "pwr::pwr.f2.test(u = 2, f2 = 0.1667), plus 5 total predictors plus",
      "1). Verified by simulation: fitting nested lm() models on 10,000",
      "simulated datasets of size 64 and comparing via anova(reduced, full)",
      "gives an empirical power of ~0.78-0.80, the same small gap seen when",
      "simulating this app's own R-squared-vs-zero test the same way",
      "(random, not fixed, predictor draws) -- the well-known fixed- vs",
      "random-regressor distinction in Cohen (1988), not a formula error.",
      sep = "\n"
    ),
    citation = paste(
      "Cohen J. Statistical Power Analysis for the Behavioral Sciences.",
      "2nd ed. Hillsdale, NJ: Lawrence Erlbaum Associates; 1988, Section",
      "9.7. (as implemented by pwr::pwr.f2.test)."
    ),
    backend = "closed form written out in the app, equal to pwr::pwr.f2.test() (compared with the package in the tests; the package is not a dependency)"
  )
)
