# Metadata for the Prediction Model module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_prediction.R (SDD 4.2: "content is data, not
# hardcoded UI").

prediction_content <- list(
  binary = list(
    title = "Prediction Model Development -- Binary Outcome",
    formula_latex = paste0(
      "$$n \\text{ solved from 3 criteria (Riley et al. 2018/2020): overfitting, ",
      "R^2 precision, outcome-risk precision}$$"
    ),
    explanation = paste(
      "Use this when developing a new multivariable prediction/diagnostic",
      "model for a binary outcome (e.g. disease present/absent), rather",
      "than testing a single predictor's effect. Riley et al.'s criteria",
      "size the study so that (i) the model doesn't overfit by more than a",
      "small, pre-specified shrinkage factor, (ii) the model's R-squared",
      "is estimated precisely, and (iii) the overall outcome risk is",
      "estimated precisely -- the largest of the three implied sample",
      "sizes is returned.",
      "",
      "- **parameters** - the number of candidate predictor *parameters*",
      "  (not variables) being considered for the model -- a categorical",
      "  predictor with k levels contributes k-1 parameters.",
      "- **prevalence** - the expected outcome prevalence/proportion in",
      "  the population you'll sample from.",
      "- **R-squared input method** - either a Cox-Snell R-squared taken",
      "  (and ideally adjusted for optimism) from a previous model in the",
      "  same field, or a reported C-statistic (AUC) from a previous",
      "  model, converted to an approximate Cox-Snell R-squared using",
      "  Riley et al. (2020)'s simulation-based method (given the same",
      "  prevalence).",
      "- **Shrinkage** - the desired degree of overfitting control at",
      "  internal validation; 0.9 (the default) means predictor effects",
      "  would need shrinking by 10% to correct for optimism.",
      "",
      "The older \"10 events per predictor parameter\" (EPP=10) rule of",
      "thumb is superseded by this approach -- it's shown here as one of",
      "the three criteria (EPP) for comparison, but the *final* n is",
      "whichever criterion is most demanding, not EPP alone.",
      sep = "\n"
    ),
    worked_example = paste(
      "Riley et al. (2018, Part II)'s own worked example: developing a",
      "model with 24 candidate predictor parameters, an expected outcome",
      "prevalence of 17.4%, and a Cox-Snell R-squared of 0.288 (taken from",
      "an existing model in the field). This calculator returns n = 662",
      "(115 events needed) -- exactly the article's own published answer.",
      "",
      "Using the same scenario but starting from a reported C-statistic of",
      "0.89 instead (converted via simulation to an approximate Cox-Snell",
      "R-squared of ~0.29), this calculator returns n = 661 -- consistent",
      "with the csrsquared-based answer, as expected.",
      sep = "\n"
    ),
    citation = paste(
      "Riley RD, Snell KIE, Ensor J, et al. Minimum sample size required",
      "for developing a multivariable prediction model: Part II binary",
      "and time-to-event outcomes. Stat Med. 2019;38(7):1276-1296;",
      "Riley RD, Van Calster B, Collins GS. A note on estimating the",
      "Cox-Snell R2 from a reported C statistic (AUROC) to inform sample",
      "size calculations for developing a prediction model with a binary",
      "outcome. Stat Med. 2021;40(4):859-864."
    ),
    backend = "pmsampsize::pmsampsize(type = \"b\")"
  ),

  continuous = list(
    title = "Prediction Model Development -- Continuous Outcome",
    formula_latex = paste0(
      "$$n \\text{ solved from 4 criteria (Riley et al. 2018): overfitting, ",
      "R^2 precision, residual-SD precision, mean-outcome precision}$$"
    ),
    explanation = paste(
      "The continuous-outcome counterpart of the binary design above --",
      "use this when developing a new multivariable prediction model for",
      "a continuous outcome (e.g. a symptom score, a lab value).",
      "",
      "- **parameters** - number of candidate predictor parameters.",
      "- **intercept** - the expected average outcome value in the",
      "  population (e.g. mean blood pressure).",
      "- **sd** - the expected standard deviation of outcome values.",
      "- **rsquared** - the expected R-squared of the new model; take the",
      "  *adjusted* R-squared if from a prior development study (the",
      "  apparent R-squared is optimistic), or the apparent R-squared if",
      "  from a prior *external validation* (unbiased, since that data",
      "  wasn't used to fit the model).",
      "- **Shrinkage, mmoe** - as elsewhere; mmoe (multiplicative margin",
      "  of error) controls precision of the estimated intercept.",
      sep = "\n"
    ),
    worked_example = paste(
      "Riley et al. (2018, Part I)'s own worked example: a model for a",
      "continuous outcome (e.g. FEV1) with 25 candidate predictor",
      "parameters, an expected R-squared of 0.2, population mean 1.9 and",
      "SD 0.6. This calculator returns n = 918 -- exactly the article's",
      "own published answer.",
      sep = "\n"
    ),
    citation = paste(
      "Riley RD, Snell KIE, Ensor J, et al. Minimum sample size required",
      "for developing a multivariable prediction model: Part I --",
      "continuous outcomes. Stat Med. 2019;38(7):1262-1275."
    ),
    backend = "pmsampsize::pmsampsize(type = \"c\")"
  ),

  survival = list(
    title = "Prediction Model Development -- Survival (Time-to-Event) Outcome",
    formula_latex = paste0(
      "$$n \\text{ solved from 3 criteria (Riley et al. 2018/2020): overfitting, ",
      "R^2 precision, event-risk precision}$$"
    ),
    explanation = paste(
      "The survival-outcome counterpart of the binary design above -- use",
      "this when developing a new multivariable prediction model for a",
      "time-to-event outcome (e.g. time to disease recurrence).",
      "",
      "- **parameters** - number of candidate predictor parameters.",
      "- **rate** - the expected overall event rate in the population",
      "  (same time units as timepoint/meanfup).",
      "- **timepoint** - the prediction horizon of interest.",
      "- **meanfup** - the expected mean follow-up duration in the",
      "  development dataset.",
      "- **csrsquared** - the expected Cox-Snell R-squared of the new",
      "  model, taken from an existing model in the field.",
      "- **Shrinkage** - as elsewhere.",
      sep = "\n"
    ),
    worked_example = paste(
      "Riley et al. (2020, BMJ)'s own worked example: 30 candidate",
      "predictor parameters, a Cox-Snell R-squared of 0.051 from an",
      "existing model, an overall event rate of 0.065 and mean follow-up",
      "of 2.07 years in the reference study, predicting at a 2-year",
      "horizon. This calculator returns n = 5143 (692 events needed) --",
      "exactly the article's own published answer.",
      sep = "\n"
    ),
    citation = paste(
      "Riley RD, Ensor J, Snell KIE, et al. Calculating the sample size",
      "required for developing a clinical prediction model. BMJ.",
      "2020;368:m441."
    ),
    backend = "pmsampsize::pmsampsize(type = \"s\")"
  ),

  external_validation = list(
    title = "External Validation of an Existing Prediction Model -- Binary Outcome",
    formula_latex = paste0(
      "$$n \\text{ = largest of up to 4 criteria (Riley et al. 2021): O/E ratio, ",
      "calibration slope, C-statistic, standardised net benefit}$$"
    ),
    explanation = paste(
      "Use this when *externally validating* an already-developed",
      "multivariable prediction/diagnostic model with a binary outcome in",
      "a new sample or setting -- as opposed to developing a new model",
      "(see the other Prediction Model designs above). Riley et al. (2021)",
      "define up to four independent precision criteria; the required n",
      "is whichever is largest.",
      "",
      "- **prevalence** - expected outcome prevalence in the validation sample.",
      "- **C-statistic** - the model's anticipated discrimination (AUC) at validation.",
      "- **LP distribution** - the calibration-slope criterion needs a",
      "  simulated distribution of the model's linear predictor (log-odds",
      "  scale) in the validation population -- either **Normal** (mean,",
      "  SD of the LP directly, e.g. from a reported histogram) or **Beta**",
      "  (shape parameters of the *predicted probabilities*, converted to",
      "  LP internally via the logit).",
      "- **O/E, calibration slope, C-statistic targets** - the anticipated",
      "  performance (default: perfect O/E=1, slope=1) and the target CI",
      "  width (acceptable precision) for each.",
      "- **Sensitivity / specificity / threshold** (optional) - if all",
      "  three are supplied, a fourth criterion (precision of the",
      "  standardised net benefit at that risk threshold) is also",
      "  computed and can drive the final n.",
      "",
      "Note: this implementation supports the two most common ways of",
      "specifying the LP distribution (Normal, Beta); the package's third,",
      "more fragile iterative option (deriving the LP distribution purely",
      "from a target C-statistic) is not implemented here.",
      sep = "\n"
    ),
    worked_example = paste(
      "Riley et al. (2021)'s own worked example (mechanical heart valve",
      "failure model): outcome prevalence 1.8%, reported C-statistic 0.8,",
      "LP distribution reported as approximately Normal with mean=-5,",
      "SD=2.5, targeting the default CI widths except O/E CI width=1.",
      "This calculator returns n = 4,563 (criterion 2, calibration slope,",
      "is the binding constraint; 83 events) -- matching the article's own",
      "published example (criteria: O/E n=905, C-slope n=4,563 [rounding",
      "to a very similar value from Monte Carlo simulation of the LP",
      "distribution], C-statistic n=4,252).",
      "",
      "Using the same scenario but with the predicted-probability",
      "distribution specified as Beta(0.5, 0.5) instead of Normal LP, this",
      "calculator returns n = 4,252 (criterion 3, C-statistic, becomes the",
      "binding constraint instead; 77 events) -- again matching the",
      "article's own alternative worked example.",
      sep = "\n"
    ),
    citation = paste(
      "Riley RD, Debray TPA, Collins G, Archer L, Ensor J, van Smeden M,",
      "Snell KIE. Minimum sample size for external validation of a",
      "clinical prediction model with a binary outcome. Stat Med.",
      "2021;40(19):4230-4251."
    ),
    backend = "Reimplementation of pmvalsampsize::pmvalsampsize(type = \"b\") -- package not installed, source verified against its own documented examples and independently against glm()-fitted calibration SEs and pROC::ci.auc() CI widths on simulated data"
  )
)
