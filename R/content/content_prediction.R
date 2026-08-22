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
  )
)
