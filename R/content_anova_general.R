# Metadata for the Factorial ANOVA / ANCOVA module: formula text,
# plain-language explanation, worked example, and citation. Content is
# data, rendered generically by mod_anova_general.R (SDD 4.2: "content is
# data, not hardcoded UI").

anova_general_content <- list(
  anova_general = list(
    title = "Factorial ANOVA / ANCOVA -- General Linear Model F-Test",
    formula_latex = paste0(
      "$$f^2 = \\frac{\\eta^2}{1-\\eta^2}$$",
      "$$n_{total} = v + u + 1 \\quad\\text{where } v \\text{ solves the noncentral-F power equation for } F(u, v)$$"
    ),
    explanation = paste(
      "Use this for a **factorial ANOVA** main effect or interaction, or",
      "an **ANCOVA** group effect (adjusting for one or more covariates)",
      "-- any fixed-effects design where the significance test for the",
      "effect you care about is an F-test. This is the same general",
      "linear-model F-test engine used by the Multiple Regression module",
      "(Cohen 1988 treats ANOVA/ANCOVA and multiple regression as one",
      "unified \"F tests\" family, sharing the same effect-size (f-squared)",
      "and noncentral-F machinery -- only the meaning of the degrees of",
      "freedom changes).",
      "",
      "- **u (numerator df)** - the degrees of freedom for the SPECIFIC",
      "  effect being tested: (a-1) for a main effect with a levels;",
      "  (a-1)(b-1) for an a x b interaction; (a-1) for an ANCOVA group",
      "  effect with a groups (same as a one-way ANOVA with that many",
      "  groups, but the denominator df will differ once covariates are",
      "  in the model).",
      "- **Effect size** - either Cohen's f-squared directly, or a",
      "  partial eta-squared (the proportion of variance the effect",
      "  explains after accounting for other model terms), automatically",
      "  converted via f2 = eta2/(1-eta2). Cohen's (1988) conventions:",
      "  f2 = 0.02 (small), 0.15 (medium), 0.35 (large).",
      "- **alpha, power** - as elsewhere.",
      "",
      "The result is the TOTAL sample size across all groups/conditions",
      "combined (not per group) -- for a balanced factorial design, divide",
      "by the total number of cells to get the size per cell.",
      sep = "\n"
    ),
    worked_example = paste(
      "Cross-checked against a one-way ANOVA special case (u = k-1 for a",
      "k-group design), which this project's Means module already builds",
      "and verifies via `pwr::pwr.anova.test()`: for k=4 groups, Cohen's",
      "f=0.25 (medium; f2=0.0625), alpha=0.05, 80% power, the dedicated",
      "one-way formula gives n=45/group (180 total). This general F-test",
      "engine, given u=3 (=k-1) and f2=0.0625, gives 179 total -- matching",
      "to within the expected rounding-convention difference (one-way",
      "ANOVA rounds up the per-group n and multiplies by k; the general",
      "engine rounds up the total residual df directly). For a genuine",
      "factorial or ANCOVA design, u would instead reflect the specific",
      "effect's own degrees of freedom.",
      sep = "\n"
    ),
    citation = paste(
      "Cohen J. Statistical Power Analysis for the Behavioral Sciences.",
      "2nd ed. Hillsdale, NJ: Lawrence Erlbaum; 1988. Chapters 8",
      "(Analysis of Variance and Covariance) and 9 (F Tests of Variance",
      "Proportions)."
    ),
    backend = "closed form written out in the app, equal to pwr::pwr.f2.test() (compared with the package in the tests; the package is not a dependency)"
  )
)
