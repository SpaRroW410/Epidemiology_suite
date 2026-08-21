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
      "(Spearman's rho, Kendall's tau) may be more appropriate -- this",
      "calculator does not cover those directly.",
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
  )
)
