# Metadata for the Difference-in-Differences module: formula text, plain-language explanation, worked example and citation, rendered
# generically by mod_did.R. Content is data, not hard-coded UI. Source and checks: see R/calc_did.R.

did_content <- list(
  did = list(
    title = "Difference-in-differences (controlled before-after) with repeated measures",
    formula_latex = paste0(
      "$$\\mathrm{Var}(\\hat\\theta) = \\left(\\frac{1}{n_0} + \\frac{1}{n_1}\\right)\\left(\\frac{1}{b} + \\frac{1}{k}\\right)(1 - \\rho)\\,\\sigma^2$$",
      "$$\\text{power} = P\\left(\\left|T'_{n_0+n_1-2}\\!\\left(\\tfrac{|\\delta|}{SE(\\hat\\theta)}\\right)\\right| > t_{1-\\alpha/2,\\,n_0+n_1-2}\\right)$$"
    ),
    explanation = paste(
      "Use this to plan a **difference-in-differences** (controlled before-after) study: a group of units (people, clinics,",
      "districts) that gets an intervention and a comparison group that does not, with the same continuous outcome measured on",
      "every unit at one or more time points **before** and **after** the intervention starts. The effect is the change in the",
      "intervention group beyond the change in the comparison group. The groups need not be randomised, and may differ at the start.",
      "",
      "- **delta** - the effect to detect, in the units of the outcome (the extra change in the intervention group).",
      "- **SD** - the standard deviation of the outcome between units at one time point.",
      "- **rho** - the correlation between two measurements of the same unit at different times. The higher it is, the more each",
      "  unit serves as its own control and the fewer units are needed. Take it from earlier data on the same outcome; the source's",
      "  examples range from 0.55 to 0.75.",
      "- **b, k** - the number of time points before and after the start. For a fixed total, equal numbers before and after give",
      "  the most power: a second baseline measurement is worth as much as a second follow-up.",
      "- **Comparison units per intervention unit** - 1 for equal groups.",
      "",
      "**Assumptions.** An immediate effect that then stays the same; the same correlation between any two time points (compound",
      "symmetry); complete data; and, as in every difference-in-differences analysis, that the two groups would have changed alike",
      "without the intervention (parallel trends), which no sample size can make true. The method does not apply when units are",
      "picked for the intervention *because* their outcome was high or low beforehand (regression to the mean).",
      "",
      "**A correction to the source.** The variance formula above is the source's equation 6. Its equation 7 and worked example",
      "then give a sample size without the factor 2 that equation 6 implies for two equal groups, so its printed numbers are half",
      "of what is needed: for its example (b = 1, k = 3, rho = 0.55, delta = 0.5 SD) it prints 19 units per group, which gives 49%",
      "power; 39 per group are needed for 80%. A simulation of 20 000 studies per setting agrees with equation 6 and with this",
      "calculator (49.2% simulated against 49.1% calculated at 19 per group; 79.1% against 79.3% at 38).",
      "",
      "Not covered: clusters measured through samples of different people each time, covariates, a gradual effect, unequal",
      "correlations over time, and binary or count outcomes.",
      sep = "\n"
    ),
    worked_example = paste(
      "Effect delta = 0.5 SD (sd = 1), correlation rho = 0.55, one measurement before and three after (b = 1, k = 3), equal groups,",
      "5% significance, 80% power: the standard error must fall to about 0.175, which needs **39 units per group (78 in all)**; the",
      "power is then 80.4%. With two measurements before and two after (b = 2, k = 2) the same study needs 30 per group. With 30",
      "intervention units and b = k = 2 the power is 81.0%.",
      sep = "\n"
    ),
    citation = paste(
      "Hu Y, Hoover DR. Simple power and sample size estimation for non-randomized longitudinal difference in differences studies.",
      "J Biom Biostat. 2018;9(5):415. PMID 31360594 (equation 6; see the correction above for its equation 7)."
    ),
    backend = "closed-form (Hu & Hoover 2018, equation 6; noncentral t)"
  )
)
