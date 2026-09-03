# Metadata for the Correlation module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_correlation.R (SDD 4.2: "content is data, not
# hardcoded UI").

correlation_content <- list(
  pearson = list(
    title = "Pearson Correlation Coefficient",
    formula_latex = paste0(
      "$$Z' = \\text{arctanh}(r) = \\frac{1}{2}\\ln\\!\\left(\\frac{1+r}{1-r}\\right)$$",
      "$$n = \\left(\\frac{Z_{1-\\alpha/2} + Z_{1-\\beta}}{Z'}\\right)^2 + 3$$"
    ),
    explanation = paste(
      "This calculator finds the sample size needed to detect a Pearson",
      "correlation coefficient of a given size between two continuous",
      "variables, using Fisher's z' (arctanh) transformation to",
      "approximate the sampling distribution of r.",
      "",
      "- **r** - the correlation coefficient you expect to find/detect",
      "  (conventionally, |r| ~0.1 small, ~0.3 medium, ~0.5 large, per",
      "  Cohen's conventions).",
      "- **alpha** - the significance level (Type I error rate), typically",
      "  0.05.",
      "- **power** - the desired probability of detecting a true",
      "  correlation (1 - Type II error rate), typically 0.8 or 0.9.",
      "- **Alternative hypothesis** - two-sided by default; use",
      "  one-sided only if you have a directional hypothesis (e.g. \"the",
      "  correlation is positive\").",
      "",
      "The Pearson correlation assumes the two variables are bivariate",
      "normal; if that assumption is doubtful, a rank-based coefficient",
      "may be more appropriate -- see the Nonparametric Tests module's",
      "Kendall's tau design.",
      sep = "\n"
    ),
    worked_example = paste(
      "Cohen (1988)'s conventional medium effect size: to detect a",
      "correlation of r = 0.3 at alpha = 0.05 (two-sided) with 80% power,",
      "this calculator returns n = 85 -- one of the most frequently",
      "quoted sample-size figures in the behavioral and health sciences",
      "literature.",
      sep = "\n"
    ),
    citation = paste(
      "Cohen J. Statistical Power Analysis for the Behavioral Sciences.",
      "2nd ed. Hillsdale, NJ: Lawrence Erlbaum Associates; 1988.",
      "(Fisher z' transformation and correlation power analysis, as",
      "implemented by pwr::pwr.r.test)."
    ),
    backend = "pwr::pwr.r.test()"
  ),

  two_independent = list(
    title = "Compare Two Independent Pearson Correlations",
    formula_latex = paste0(
      "$$q = \\left|\\,\\text{arctanh}(r_1) - \\text{arctanh}(r_2)\\,\\right|$$",
      "$$n_{\\text{per group}} = \\left(\\frac{Z_{1-\\alpha/2} + Z_{1-\\beta}}{q}\\right)^2 + 3$$"
    ),
    explanation = paste(
      "Use this to test whether the strength of a correlation between",
      "two variables differs between two independent groups (e.g. does",
      "a screening test correlate more strongly with the reference",
      "standard in one population than another?), rather than testing",
      "one correlation against zero.",
      "",
      "- **r1, r2** - the correlation coefficients you expect in each",
      "  group; they must differ, since the test detects a difference",
      "  between them.",
      "- **alpha, power, Alternative hypothesis** - as elsewhere.",
      "",
      "Cohen's q (the difference between the two Fisher z'-transformed",
      "correlations) plays the same effect-size role here that d plays",
      "for two means, or h for two proportions -- conventionally, q ~0.1",
      "small, ~0.3 medium, ~0.5 large. No dedicated `pwr` function covers",
      "this two-sample case (only the single-correlation-vs-zero test",
      "does), so this reimplements Cohen's own closed-form formula",
      "directly.",
      sep = "\n"
    ),
    worked_example = paste(
      "UCLA OARC's own G*Power worked example: comparing an established",
      "chemical-detection test (r1 = 0.89) against a cheaper new test",
      "(r2 = 0.76) using independent soil samples, two-sided alpha =",
      "0.05. At 90% power, this calculator returns n = 61 per group,",
      "matching the published table exactly; at 80% and 70% power the",
      "published table shows n = 46 and n = 37 (rounded to the nearest",
      "integer), while this calculator -- consistent with every other",
      "calculator in this app -- rounds UP to guarantee the target power",
      "is met, returning n = 47 and n = 38 respectively.",
      sep = "\n"
    ),
    citation = paste(
      "Cohen J. Statistical Power Analysis for the Behavioral Sciences.",
      "2nd ed. Hillsdale, NJ: Lawrence Erlbaum Associates; 1988. Worked",
      "example: UCLA Office of Advanced Research Computing, \"G*Power",
      "Data Analysis Examples: Power Analysis for Correlations\"",
      "(Correlations: Two independent Pearson r's)."
    ),
    backend = "closed-form (Cohen 1988)"
  ),

  point_biserial = list(
    title = "Point-Biserial Correlation (Continuous vs. Dichotomous Variable)",
    formula_latex = paste0(
      "$$d = \\frac{2r}{\\sqrt{1-r^2}} \\quad \\text{(Cohen 1988)}$$",
      "$$n_{\\text{per group}} = \\text{solved from } d, \\alpha, \\text{power (two-sample t-test)}$$"
    ),
    explanation = paste(
      "A point-biserial correlation is a Pearson correlation between a",
      "continuous variable and a naturally dichotomous (0/1) grouping",
      "variable -- e.g. \"does score correlate with sex/treatment group?\"",
      "Testing it against zero is mathematically the same question as a",
      "two-independent-samples t-test on the continuous variable across",
      "the two groups, so this calculator converts the expected",
      "correlation to Cohen's *d* and reuses the same two-sample t-test",
      "machinery as the Means module.",
      "",
      "- **r** - the expected point-biserial correlation between the",
      "  continuous outcome and the two-group membership variable.",
      "- **alpha, power** - as elsewhere.",
      "",
      "Use this framing when your research question is naturally phrased",
      "as a correlation (\"how strongly does X relate to group\"); use the",
      "Means module's \"Two independent means\" design directly if you'd",
      "rather think in terms of an assumed difference and SD -- both give",
      "the same answer for the same effect.",
      sep = "\n"
    ),
    worked_example = paste(
      "For an expected point-biserial correlation of r = 0.5 between a",
      "continuous outcome and a two-group indicator, this calculator",
      "converts to Cohen's d = 1.1547 and returns n = 13 per group (26",
      "total) at alpha = 0.05 (two-sided) and 80% power -- independently",
      "confirmed by simulating data at r = 0.5 and checking the fitted",
      "correlation and equivalent group-mean difference both recover the",
      "intended value.",
      sep = "\n"
    ),
    citation = paste(
      "Cohen J. Statistical Power Analysis for the Behavioral Sciences.",
      "2nd ed. Hillsdale, NJ: Lawrence Erlbaum Associates; 1988, ch. 2",
      "(the r-to-d conversion for equal group sizes)."
    ),
    backend = "closed-form (Cohen 1988) via pwr::pwr.t.test()"
  ),

  regression_slope = list(
    title = "Simple Linear Regression Slope",
    formula_latex = paste0(
      "$$r = \\frac{b \\cdot SD_x}{SD_y} \\quad \\text{(exact identity for one predictor)}$$",
      "$$n = \\text{solved from } r, \\alpha, \\text{power (Fisher z')}$$"
    ),
    explanation = paste(
      "Testing whether a simple (one-predictor) linear regression slope",
      "differs from zero is *exactly* the same test as whether the",
      "Pearson correlation between the predictor and outcome differs",
      "from zero -- not an approximation, a mathematical identity",
      "(r = slope x SDx / SDy) for the one-predictor case. This",
      "calculator converts your raw-scale slope and SDs to the implied",
      "correlation and reuses the Pearson-correlation calculator's",
      "engine.",
      "",
      "- **slope** - the assumed/expected regression slope, in the",
      "  outcome's units per unit of the predictor.",
      "- **SDx, SDy** - the standard deviations of the predictor and the",
      "  outcome.",
      "- **alpha, power** - as elsewhere.",
      "",
      "If you already know the expected correlation directly, use the",
      "Pearson Correlation design above instead -- this one exists for",
      "when your assumption is more naturally phrased as a raw-scale",
      "slope (e.g. \"a 1-unit increase in exposure raises the outcome by",
      "b units\") than as a standardized correlation.",
      sep = "\n"
    ),
    worked_example = paste(
      "For an assumed slope of 0.5 (outcome units per predictor unit),",
      "with SDx = 2 and SDy = 4, this calculator computes the implied",
      "correlation r = 0.5 x 2 / 4 = 0.25 and returns n = 123 at",
      "alpha = 0.05 (two-sided) and 80% power -- independently confirmed",
      "by simulating data with this exact slope/SDx/SDy combination and",
      "checking that both the fitted slope and correlation recover the",
      "intended values.",
      sep = "\n"
    ),
    citation = paste(
      "Kutner MH, Nachtsheim CJ, Neter J, Li W. Applied Linear",
      "Statistical Models. 5th ed. McGraw-Hill/Irwin; 2005 (the",
      "slope-correlation identity for simple linear regression)."
    ),
    backend = "closed-form identity via pwr::pwr.r.test()"
  ),

  partial = list(
    title = "Partial Correlation (Controlling for k Covariates)",
    formula_latex = paste0(
      "$$Z' = \\text{arctanh}(r)$$",
      "$$n = \\left(\\frac{Z_{1-\\alpha/2} + Z_{1-\\beta}}{Z'}\\right)^2 + 3 + k$$"
    ),
    explanation = paste(
      "A partial correlation is the correlation between two variables",
      "after statistically removing (\"controlling for\") the effect of",
      "one or more other covariates -- e.g. the correlation between diet",
      "and blood pressure, adjusted for age and BMI. Testing a partial",
      "correlation against zero uses the same Fisher z' transformation as",
      "an ordinary correlation, but loses one degree of freedom per",
      "covariate controlled for, so a partial-correlation study needs k",
      "more subjects than the equivalent zero-order-correlation study for",
      "the same r, alpha, and power (Cohen 1988's own power tables read",
      "partial correlation off the *same* table as zero-order correlation,",
      "just entered with n' = n - k).",
      "",
      "- **r** - the expected partial correlation, controlling for the",
      "  covariates.",
      "- **k** - the number of covariates being controlled for (a whole",
      "  number, at least 1 -- use the plain Correlation design above if",
      "  k = 0).",
      "- **alpha, power** - as elsewhere.",
      "",
      "This reuses `pwr::pwr.r.test()`'s zero-order-correlation engine and",
      "simply adds k to the result -- verified by simulation: generating",
      "data with a known partial correlation (via residualizing the",
      "outcome and predictor on k simulated covariates) and fitting a",
      "multiple regression recovers empirical power matching the target",
      "closely at the computed n.",
      sep = "\n"
    ),
    worked_example = paste(
      "For an expected partial correlation of r = 0.3 controlling for",
      "k = 2 covariates, at alpha = 0.05 (two-sided) and 80% power, this",
      "calculator returns n = 87 (the zero-order n = 85, plus 2 for the",
      "covariates) -- independently confirmed by a 5,000-replicate Monte",
      "Carlo simulation (empirical power 0.826, closely matching the 0.80",
      "target).",
      sep = "\n"
    ),
    citation = paste(
      "Cohen J. Statistical Power Analysis for the Behavioral Sciences.",
      "2nd ed. Hillsdale, NJ: Lawrence Erlbaum Associates; 1988, ch. 3",
      "(partial correlation power analysis via the zero-order correlation",
      "table, entered with n - k)."
    ),
    backend = "closed-form (Cohen 1988) via pwr::pwr.r.test()"
  ),

  two_dependent = list(
    title = "Compare Two Dependent (Overlapping) Pearson Correlations",
    formula_latex = paste0(
      "$$c = \\frac{r_{x_1x_2}(1-2\\bar r^2) - \\tfrac{1}{2}\\bar r^2(1-2\\bar r^2-r_{x_1x_2}^2)}{(1-\\bar r^2)^2}, \\quad \\bar r^2 = \\frac{r_{yx_1}^2+r_{yx_2}^2}{2}$$",
      "$$n = \\left(\\frac{(Z_{1-\\alpha/2}+Z_{1-\\beta})\\sqrt{2-2c}}{|Z'_{yx_1}-Z'_{yx_2}|}\\right)^2 + 3$$"
    ),
    explanation = paste(
      "Use this to test whether a variable Y correlates more strongly",
      "with X1 than with X2, when X1 and X2 are BOTH measured on the",
      "SAME sample as Y -- e.g. \"is a new biomarker more strongly",
      "correlated with disease severity than the old biomarker, measured",
      "in the same patients?\" This needs a different formula than the",
      "\"Compare two independent correlations\" design above, which",
      "assumes r1 and r2 come from two separate, unrelated samples: here",
      "the two correlations are statistically dependent (both involve Y),",
      "so the test must account for that dependence via the third",
      "pairwise correlation, r_x1x2 (the correlation between X1 and X2",
      "themselves).",
      "",
      "- **r_yx1, r_yx2** - the correlations you expect between Y and each",
      "  of X1 and X2; they must differ, since the test detects a",
      "  difference between them.",
      "- **r_x1x2** - the expected correlation between X1 and X2 (the two",
      "  variables being compared, not involving Y). The three",
      "  correlations together must form a valid (positive-definite) 3x3",
      "  correlation matrix.",
      "- **alpha, power, Alternative hypothesis** - as elsewhere.",
      "",
      "This is Steiger (1980)'s Fisher z'-transformation test for two",
      "correlations sharing one variable in common: the covariance c",
      "between the two z'-transformed correlations depends on r_x1x2, and",
      "the sample-size formula solves the resulting Z-test for n directly",
      "(c does not itself depend on n).",
      "",
      "Only the \"one variable in common\" case is covered here (comparing",
      "r_yx1 to r_yx2). Comparing two correlations that share NO variable",
      "at all (e.g. r_yx1 vs r_zx2, needing all six pairwise correlations",
      "among four variables) is not covered.",
      sep = "\n"
    ),
    worked_example = paste(
      "For r_yx1 = 0.4, r_yx2 = 0.6, r_x1x2 = 0.3, alpha = 0.05",
      "(two-sided) and 80% power, this calculator returns n = 183.",
      "Verified two ways: this formula's Z-statistic reproduces the",
      "psych package's own exact implementation of Steiger's original",
      "t-test (which itself reproduces Steiger (1980)'s own classic",
      "textbook example -- r_yx1=.4, r_yx2=.5, r_x1x2=.1, n=103 ->",
      "t=-0.89 -- exactly) within 0.01 of the t-value at every sample",
      "size tested; and a 5,000-replicate Monte Carlo simulation at the",
      "computed n=183 (generating trivariate normal data and testing each",
      "replicate with the psych package's exact test) gives an empirical",
      "power of 0.816, closely matching the 0.80 target.",
      sep = "\n"
    ),
    citation = paste(
      "Steiger JH. Tests for comparing elements of a correlation matrix.",
      "Psychol Bull. 1980;87(2):245-251 (eq. 14-15, the Fisher",
      "z'-transformation test for two correlations sharing one variable",
      "in common). Cross-checked against psych::r.test()'s",
      "implementation of the same paper's eq. 3-4 (exact raw-r t-test)."
    ),
    backend = "closed-form (Steiger 1980)"
  )
)
