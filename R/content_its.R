# Metadata for the Interrupted Time Series module: formula text, plain-language explanation, worked example and citation, rendered
# generically by mod_its.R. Content is data, not hard-coded UI. Sources and checks: see R/calc_its.R.

.its_citation <- paste(
  "Model: Bernal JL, Cummins S, Gasparrini A. Interrupted time series regression for the evaluation of public health interventions:",
  "a tutorial. Int J Epidemiol. 2017;46(1):348-355. doi:10.1093/ije/dyw098. Power is calculated from the generalised least squares",
  "variance of the change under first-order autocorrelated errors. Checked against the simulated power in Beard E, Brown J, Shahab L.",
  "Sample size requirements to evaluate policies in addiction research using interrupted time series analysis (ITS): tools and",
  "guidance. Addiction. 2026;121(3):695-712. doi:10.1111/add.70220 (Tables 1 and 3), and against a simulation of fitted models."
)

.its_common_help <- paste(
  "- **SD** - the standard deviation of the series around its trend: how far a typical time point lies from the fitted line.",
  "  Take it from the residuals of a line fitted to past data. (If you know the white-noise SD s of an AR(1) model instead, the SD",
  "  here is s / sqrt(1 - rho^2).)",
  "- **rho** - the correlation between the errors of neighbouring time points (first-order autocorrelation); 0 if time points are",
  "  independent. Estimate it from past data; monthly health series are often between 0.2 and 0.6. Higher autocorrelation means",
  "  less information per time point.",
  "- **Time points** - one per period of aggregated data (months, quarters, weeks), before and after the interruption. For a",
  "  fixed total, an interruption near the middle gives the most power.",
  "- **Baseline trend in the model** - leave on unless you are sure the series was flat before the interruption.",
  "- **Level and slope change estimated together** - the usual segmented regression estimates both; turn off to fit only the",
  "  change you test (more power, but wrong if the other change exists).",
  "",
  "**What the number means.** This is a calculation that treats the autocorrelation as known and gives the power of a test that",
  "keeps its significance level. In practice the autocorrelation is estimated, and with short series (under about 50 time points)",
  "the fitted test rejects too often when nothing changed (10 to 17% instead of 5% in simulations), so no calculation of this",
  "kind is reliable there: there is no fixed minimum number of time points (Bernal et al. 2017), but short series need care.",
  "",
  "Not covered: seasonality, a control series (controlled interrupted time series), counts with a Poisson model, gradual or",
  "delayed effects, several interruptions, and higher-order autocorrelation. For those, simulate (Beard et al. 2026 give code).",
  sep = "\n"
)

.its_formula <- paste0(
  "$$Y_t = \\beta_0 + \\beta_1 t + \\beta_2 X_t + \\beta_3 (t - t_0) X_t + e_t, \\qquad e_t = \\rho\\, e_{t-1} + u_t$$",
  "$$\\mathrm{Var}(\\hat\\beta) = \\sigma^2\\left(X^\\top R^{-1} X\\right)^{-1}, \\quad R_{ij} = \\rho^{|i-j|} \\qquad ",
  "\\text{power} = P\\left(\\left|T'_{n-p}\\!\\left(\\tfrac{|\\beta_k|}{SE(\\hat\\beta_k)}\\right)\\right| > t_{1-\\alpha/2,\\,n-p}\\right)$$"
)

its_content <- list(
  level = list(
    title = "Interrupted time series: change in level (segmented regression)",
    formula_latex = .its_formula,
    explanation = paste(
      "Use this to plan an **interrupted time series**: an outcome measured at many time points before and after a policy,",
      "programme or event, analysed by segmented regression. This design tests a **change in level**: an immediate, lasting step up",
      "or down at the interruption (beta2 in the model).",
      "",
      "- **Change in level** - the step you want to detect, in the units of the outcome (for example 2 admissions per 1000).",
      .its_common_help,
      sep = "\n"
    ),
    worked_example = paste(
      "Monthly data, a step of 2 units to detect, SD around the trend 1.5, autocorrelation 0.3, the usual model (baseline trend,",
      "level and slope change), interruption at the midpoint, 5% significance. With 24 months before and 24 after, the standard",
      "error of the step is 1.07 and the power only 0.45. For 80% power **123 months** are needed (62 before, 61 after; standard error",
      "0.71). If the series can be assumed flat with no slope change (both options off), 32 months are enough: the model matters",
      "as much as the data.",
      sep = "\n"
    ),
    citation = .its_citation,
    backend = "closed-form (generalised least squares variance with AR(1) errors; noncentral t)"
  ),
  slope = list(
    title = "Interrupted time series: change in slope (segmented regression)",
    formula_latex = .its_formula,
    explanation = paste(
      "Use this to plan an **interrupted time series** analysed by segmented regression when the effect is expected to build up",
      "gradually. This design tests a **change in slope**: the trend after the interruption differs from the trend before it",
      "(beta3 in the model).",
      "",
      "- **Change in slope** - the change in trend to detect, in units of the outcome per time point (for example -0.1 per month).",
      .its_common_help,
      sep = "\n"
    ),
    worked_example = paste(
      "A change in slope of 0.05 units per time point, AR(1) errors with autocorrelation 0.5 and white-noise SD 1 (so SD = 1 /",
      "sqrt(1 - 0.25) = 1.155), 50 time points before and 50 after, baseline trend in the model: the calculated power is 0.45. In",
      "simulations of the fitted model the same setting gives about 0.54 (0.55 in Beard et al. 2026, Table 3), because that test",
      "rejects about 9% of the time when nothing changed. For 80% power by the calculation, 133 time points are needed.",
      sep = "\n"
    ),
    citation = .its_citation,
    backend = "closed-form (generalised least squares variance with AR(1) errors; noncentral t)"
  )
)
