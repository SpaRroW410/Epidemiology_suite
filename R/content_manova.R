# Metadata for the MANOVA / Hotelling's T-squared module: formula text,
# plain-language explanation, worked example, and citation. Content is
# data, rendered generically by mod_manova.R (SDD 4.2: "content is data,
# not hardcoded UI").

manova_content <- list(
  hotelling = list(
    title = "Two-Group Hotelling's T-Squared Test (MANOVA, Two Groups)",
    formula_latex = paste0(
      "$$D^2 = (\\mu_1-\\mu_2)'\\Sigma^{-1}(\\mu_1-\\mu_2) \\quad \\text{(squared Mahalanobis distance)}$$",
      "$$n \\text{ solved from noncentral } F(p,\\, 2n-p-1),\\ \\lambda = \\tfrac{n}{2}D^2$$"
    ),
    explanation = paste(
      "Use this to compare two independent groups on SEVERAL continuous",
      "outcome variables JOINTLY (e.g. several symptom-severity scores,",
      "or several biomarkers measured at once) -- the two-group special",
      "case of MANOVA, testing whether the two groups' mean VECTORS",
      "differ, using Hotelling's T-squared statistic. This is more",
      "appropriate than running a separate t-test on each outcome",
      "variable when the outcomes are correlated and you want a single",
      "overall test that (implicitly) controls the combined Type I error",
      "across all of them.",
      "",
      "- **p (number of response variables)** - how many outcome",
      "  variables are being compared jointly (use the Means module's",
      "  \"Two independent means\" design instead if p = 1, a single",
      "  outcome).",
      "- **D-squared (squared Mahalanobis distance)** - the multivariate",
      "  generalization of Cohen's d-squared: how far apart the two",
      "  groups' mean vectors are, standardized by their (assumed common)",
      "  covariance structure. Conventionally, small ~0.25, medium ~0.50,",
      "  large ~1.0 (loosely following Cohen's d benchmarks applied per",
      "  dimension), though the right value depends heavily on how",
      "  correlated the outcome variables are -- pilot data or a",
      "  hypothesized mean-vector/covariance-matrix pair is the most",
      "  reliable source.",
      "- **alpha, power** - as elsewhere.",
      "",
      "Hotelling's T-squared test statistic, converted to an F statistic",
      "with p and 2n-p-1 degrees of freedom (n = the size of EACH of the",
      "two equal-sized groups), follows a noncentral F distribution under",
      "the alternative with noncentrality (n/2) x D-squared -- exactly the",
      "same noncentral-F machinery already used elsewhere in this app",
      "(the ANOVA/regression F-test modules), just with a different",
      "effect-size/df mapping specific to the multivariate two-sample",
      "case.",
      sep = "\n"
    ),
    worked_example = paste(
      "At p = 1 outcome variable, this reduces EXACTLY to the ordinary",
      "two-independent-samples t-test: D-squared = Cohen's d-squared, and",
      "for d = 0.5, alpha = 0.05, power = 0.80 this calculator returns",
      "n = 64 per group -- identical to the Means module's own",
      "two-independent-means design for the same d (both derive from the",
      "identical noncentral-F/t relationship).",
      "",
      "For a genuine multivariate case, p = 3 correlated outcome",
      "variables with squared Mahalanobis distance D-squared = 0.1243,",
      "alpha = 0.05, and 80% power: this calculator returns n = 178 per",
      "group (356 total). Independently confirmed by a 5,000-replicate",
      "Monte Carlo simulation -- generating trivariate normal data for",
      "both groups and computing the actual two-sample Hotelling's",
      "T-squared statistic on each replicate -- giving an empirical power",
      "of 0.8068, closely matching the 0.80 target.",
      sep = "\n"
    ),
    citation = paste(
      "Rencher AC. Methods of Multivariate Analysis. 2nd ed. New York:",
      "Wiley; 2002 (two-sample Hotelling's T-squared power via the",
      "noncentral F distribution). Vonesh EF, Schork MA. Sample sizes in",
      "the multivariate analysis of repeated measurements. Biometrics.",
      "1986;42(3):601-610 (the general noncentral-F approach to",
      "multivariate sample-size planning that this app's own docs name",
      "for the MANOVA checklist item)."
    ),
    backend = "closed-form (noncentral F distribution, Rencher 2002)"
  )
)
