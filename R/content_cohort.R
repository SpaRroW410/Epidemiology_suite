# Metadata for the Cohort / RR module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_cohort.R (SDD 4.2: "content is data, not hardcoded UI").

cohort_content <- list(
  cohort = list(
    title = "Cohort Study (Relative Risk)",
    formula_latex = paste0(
      "$$n_{\\text{per group}} = \\left(\\frac{Z_{1-\\alpha/2}\\sqrt{(r+1)\\bar p(1-\\bar p)} + ",
      "Z_{1-\\beta}\\sqrt{r\\,p_1(1-p_1) + p_0(1-p_0)}}{r(p_1-p_0)}\\right)^2 (r+1) / r ",
      "\\quad \\text{(approx.; package computes exactly)}$$",
      "$$RR = p_1 / p_0$$"
    ),
    explanation = paste(
      "In a cohort study, groups are defined by *exposure status* first",
      "(exposed vs. unexposed), then followed forward to see who develops",
      "the outcome -- the reverse of a case-control study. This also",
      "applies to cross-sectional studies that estimate relative risk",
      "directly.",
      "",
      "- **p0** - the expected incidence risk of the outcome in the",
      "  unexposed group (from prior literature).",
      "- **p1** - the expected incidence risk of the outcome in the",
      "  exposed group. The implied relative risk is RR = p1/p0.",
      "- **ratio (r)** - the number in the exposed group divided by the",
      "  number in the unexposed group.",
      "- **alpha, power** - as elsewhere.",
      "- **N (optional)** - a finite eligible-population size, if",
      "  sampling from a limited pool (applies a finite population",
      "  correction).",
      "",
      "This uses individual count data (each subject classified",
      "exposed/unexposed and outcome/no-outcome), as opposed to person-time",
      "data -- appropriate for a fixed follow-up period rather than",
      "variable-length observation.",
      sep = "\n"
    ),
    worked_example = paste(
      "Woodward (2014): a study is planned to assess a new treatment for",
      "anoestrus in dairy cattle. The proportion of cows responding is",
      "expected to be 30% in the treatment (exposed) group (p1 = 0.30)",
      "and 15% in the control (unexposed) group (p0 = 0.15). At 80% power",
      "and a two-sided 0.05 test, with equal group sizes (ratio = 1), this",
      "calculator returns n = 242 total: 121 in each group (implied",
      "RR = 2.0).",
      sep = "\n"
    ),
    citation = paste(
      "Kelsey JL, Thompson WD, Evans AS. Methods in Observational",
      "Epidemiology. Oxford University Press; 1986. pp. 254-284;",
      "Woodward M. Epidemiology: Study Design and Data Analysis. 3rd ed.",
      "Chapman & Hall/CRC; 2014. pp. 295-329 (worked examples)."
    ),
    backend = "epiR::epi.sscohortc()"
  )
)
