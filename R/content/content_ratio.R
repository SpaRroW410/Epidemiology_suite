# Metadata for the Ratio Estimation module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_ratio.R (SDD 4.2: "content is data, not hardcoded UI").

ratio_content <- list(
  risk_ratio = list(
    title = "Risk Ratio (Relative Risk) -- Precision-Based",
    formula_latex = paste0(
      "$$n \\text{ solved so the } (1-\\alpha)\\text{ CI for the risk ratio } ",
      "p_1/p_2 \\text{ has the desired width (Koopman 1984; Katz et al. 1978)}$$"
    ),
    explanation = paste(
      "Use this when planning a study to *estimate* a risk ratio (e.g.",
      "from a cohort study) to a target precision, rather than to test a",
      "specific hypothesis with a power target -- the precision-based",
      "counterpart to the Cohort/RR module's hypothesis-test design.",
      "",
      "- **p1, p2** - the risk (proportion) you expect in the exposed and",
      "  unexposed groups.",
      "- **r (allocation ratio)** - n2/n1 (1 = equal groups).",
      "- **Desired CI width** - the full width of the confidence interval",
      "  you want for the estimated risk ratio.",
      "- **Method** - Koopman's score interval (recommended, matches",
      "  Pearson's chi-squared test) or Katz's log-transform interval.",
      sep = "\n"
    ),
    worked_example = paste(
      "Validated against Fagerland, Lydersen & Laake (2015), Table 5: 7",
      "events in 34 exposed vs. 1 event in 34 unexposed (risk ratio = 7)",
      "gives a 95% CI of width 41.35 (Koopman) at n1 = n2 = 34 -- this",
      "calculator reproduces that width exactly, and solving in reverse",
      "for that same target width returns essentially the same n.",
      sep = "\n"
    ),
    citation = paste(
      "Koopman PAR. Confidence intervals for the ratio of two binomial",
      "proportions. Biometrics. 1984;40:513-517; Katz D, Baptista J, Azen",
      "SP, Pike MC. Obtaining confidence intervals for the risk ratio in",
      "cohort studies. Biometrics. 1978;34:469-474; Fagerland MW,",
      "Lydersen S, Laake P. Recommended confidence intervals for two",
      "independent binomial proportions. Stat Methods Med Res.",
      "2015;24(2):224-254."
    ),
    backend = "presize::prec_riskratio()"
  ),

  odds_ratio = list(
    title = "Odds Ratio -- Precision-Based",
    formula_latex = paste0(
      "$$n \\text{ solved so the } (1-\\alpha)\\text{ CI for the odds ratio has the desired width}$$"
    ),
    explanation = paste(
      "Use this when planning a study (e.g. a case-control study) to",
      "*estimate* an odds ratio to a target precision, rather than to",
      "test a specific hypothesis with a power target -- the",
      "precision-based counterpart to the Case-Control module's",
      "hypothesis-test designs.",
      "",
      "- **p1, p2** - the proportion with the outcome/exposure you expect",
      "  in each group.",
      "- **r (allocation ratio)** - n2/n1 (1 = equal groups).",
      "- **Desired CI width** - the full width of the confidence interval",
      "  you want for the estimated odds ratio.",
      "- **Method** - `indip_smooth` (default, recommended along with",
      "  `gart`), `gart`, or `woolf`'s log-transform interval.",
      sep = "\n"
    ),
    worked_example = paste(
      "presize's own documented example: 10% vs. 15% event rates, 100",
      "subjects per group (200 total) gives a 95% CI of width 1.207",
      "(indip_smooth). This calculator reproduces that width exactly, and",
      "solving in reverse for a target width of 1.207 returns n1 = n2 =",
      "100, matching the documented example's own sample size.",
      sep = "\n"
    ),
    citation = paste(
      "Gart JJ, Zweifel JR. On the bias of various estimators of the",
      "logit and its variance. Biometrika. 1967;54:181-187; Woolf B. On",
      "estimating the relation between blood group and disease. Ann Hum",
      "Genet. 1955;19:251-253; Fagerland MW, Lydersen S, Laake P.",
      "Recommended confidence intervals for two independent binomial",
      "proportions. Stat Methods Med Res. 2015;24(2):224-254."
    ),
    backend = "presize::prec_or()"
  ),

  rate_ratio = list(
    title = "Rate Ratio -- Precision-Based",
    formula_latex = paste0(
      "$$n \\text{ solved so the } (1-\\alpha)\\text{ CI for the rate ratio has the desired precision level}$$"
    ),
    explanation = paste(
      "Use this when planning a study to *estimate* a rate ratio (from",
      "person-time/incidence-rate data) to a target precision, rather",
      "than to test a specific hypothesis -- the precision-based",
      "counterpart to the Incidence Rate module's rate-comparison design.",
      "",
      "- **rate1, rate2** - the event rate you expect in the exposed and",
      "  unexposed groups (same time units for both).",
      "- **r (allocation ratio)** - n2/n1 (1 = equal groups).",
      "- **Desired precision level** - the ratio of the CI's upper limit",
      "  to its lower limit (e.g. 3.81 means the upper bound is 3.81",
      "  times the lower bound) -- rate ratios are reported and reasoned",
      "  about multiplicatively, so precision is expressed as a ratio",
      "  rather than an additive width (Rothman & Greenland 2018).",
      sep = "\n"
    ),
    worked_example = paste(
      "Rothman & Greenland (2018)'s own worked example: rates of 0.5 and",
      "3 (rate ratio = 1/6), 20 subjects per group, gives a 95% CI with",
      "an upper-to-lower precision level of 3.81. This calculator",
      "reproduces that precision level exactly, and solving in reverse",
      "for a target precision level of 3.81 returns essentially the same",
      "n1 = n2 = 20.",
      sep = "\n"
    ),
    citation = paste(
      "Rothman KJ, Greenland S. Planning study size based on precision",
      "rather than power. Epidemiology. 2018;29(5):599-603."
    ),
    backend = "presize::prec_rateratio()"
  )
)
