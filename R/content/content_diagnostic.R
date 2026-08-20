# Metadata for the Diagnostic Accuracy module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_diagnostic.R (SDD 4.2: "content is data, not hardcoded
# UI").

diagnostic_content <- list(
  sens_spec = list(
    title = "Sensitivity & Specificity — Given Disease Prevalence (Buderer's Method)",
    formula_latex = paste0(
      "$$n_{Sn} = \\frac{Z_{1-\\alpha/2}^2 \\, Sn(1-Sn)}{W_{Sn}^2 \\times P}$$",
      "$$n_{Sp} = \\frac{Z_{1-\\alpha/2}^2 \\, Sp(1-Sp)}{W_{Sp}^2 \\times (1-P)}$$",
      "$$N = \\max(n_{Sn},\\, n_{Sp})$$"
    ),
    explanation = paste(
      "Estimating a diagnostic test's sensitivity and specificity is",
      "different from a typical one- or two-sample study: only subjects",
      "who truly *have* the target condition contribute information to the",
      "sensitivity estimate, and only subjects who truly *do not* contribute",
      "to the specificity estimate. That means the prevalence of the",
      "condition in the sampled population determines how many *total*",
      "subjects are needed to get enough of each group -- ignoring",
      "prevalence and sizing the study as if it were a single proportion",
      "will under-power one of the two estimates.",
      "",
      "- **Sn** - the expected sensitivity of the test.",
      "- **Sp** - the expected specificity of the test.",
      "- **P** - the expected prevalence of the target condition in the",
      "  population you will sample from.",
      "- **W_Sn, W_Sp** - the desired precision (confidence interval",
      "  half-width) for sensitivity and specificity respectively, e.g.",
      "  0.05 for a result reported as \"sensitivity +/- 5 percentage",
      "  points\". These can be set equal, or looser/tighter for whichever",
      "  metric matters more to your study.",
      "- **Confidence level** - typically 0.95 (95%), giving Z = 1.96.",
      "",
      "n_Sn and n_Sp are each the *total* sample size (not just the",
      "diseased or healthy subgroup) needed to hit that metric's precision",
      "target at the given prevalence -- Buderer's insight was folding",
      "prevalence into the denominator so both formulas already return a",
      "total N. Since a single study draws one sample serving both",
      "estimates, take N = the larger of the two: whichever metric is",
      "further from 0.5, or whichever side of the prevalence split is",
      "smaller, will tend to dominate.",
      "",
      "**Common pitfall:** low prevalence dramatically inflates the",
      "required total sample size for sensitivity (few diseased subjects",
      "per enrollee), and high prevalence does the same for specificity",
      "(few healthy subjects per enrollee) -- always compute both n_Sn and",
      "n_Sp and report the total needed for whichever binds, rather than",
      "sizing the study on sensitivity or specificity alone.",
      sep = "\n"
    ),
    worked_example = paste(
      "Suppose a new rapid test is expected to have 90% sensitivity",
      "(Sn = 0.90) and 85% specificity (Sp = 0.85), in a population where",
      "the target condition has 30% prevalence (P = 0.30). At 95%",
      "confidence (Z = 1.96) and a desired precision of +/-5 percentage",
      "points for both (W_Sn = W_Sp = 0.05), this calculator returns",
      "n_Sn = 461 and n_Sp = 280 -- so N = 461 (sensitivity binds),",
      "implying roughly 139 diseased and 323 non-diseased subjects at the",
      "assumed 30% prevalence.",
      sep = "\n"
    ),
    citation = paste(
      "Buderer NM. Statistical methodology: I. Incorporating the",
      "prevalence of disease into the sample size calculation for",
      "sensitivity and specificity. Acad Emerg Med. 1996;3(9):895-900.",
      "(original method); Akoglu H. User's guide to sample size",
      "estimation in diagnostic accuracy studies. Turk J Emerg Med.",
      "2022;22(4):177-185. (worked practical guide to this and related",
      "diagnostic-accuracy sample size methods)."
    ),
    backend = "Closed-form (Buderer's method); no external package required"
  )
)
