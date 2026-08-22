# Pure calculation functions for prediction/prognostic model development
# sample size. No Shiny dependency here so these are directly unit-testable
# (see tests/testthat). Wraps pmsampsize::pmsampsize() rather than
# reimplementing the underlying math (project convention) -- Riley et al.'s
# criteria are involved (overfitting, R-squared precision, outcome-risk
# precision) and are exactly what this package already implements.

#' Sample size for developing a prediction model with a binary outcome
#'
#' Wraps pmsampsize::pmsampsize(type = "b"). Provide exactly one of
#' csrsquared (a Cox-Snell R-squared taken/adjusted from an existing model)
#' or cstatistic (a C-statistic from an existing model, converted to an
#' approximate Cox-Snell R-squared via Riley et al. 2020's simulation-based
#' approach).
#'
#' @param parameters Number of candidate predictor parameters (whole number >= 1)
#' @param prevalence Expected outcome prevalence/proportion (0,1)
#' @param csrsquared Expected Cox-Snell R-squared of the new model (0,1), or NULL
#' @param cstatistic Reported C-statistic of an existing model (0.5,1), or NULL
#' @param shrinkage Desired shrinkage factor at internal validation (0,1); default 0.9
#' @return list(n, events, csrsquared, max_r2a, nag_r2, epp, inputs)
calc_prediction_binary <- function(parameters, prevalence, csrsquared = NULL,
                                    cstatistic = NULL, shrinkage = 0.9) {
  if (is.null(csrsquared) == is.null(cstatistic)) {
    stop("Provide exactly one of csrsquared or cstatistic (not both, not neither).")
  }
  if (!is.numeric(parameters) || length(parameters) != 1 || is.na(parameters) ||
        parameters < 1 || parameters != round(parameters)) {
    stop("parameters must be a single whole number >= 1.")
  }
  .validate_unit_interval(prevalence, "prevalence")
  .validate_unit_interval(shrinkage, "shrinkage")
  if (!is.null(csrsquared)) .validate_unit_interval(csrsquared, "csrsquared")
  if (!is.null(cstatistic)) {
    if (!is.numeric(cstatistic) || length(cstatistic) != 1 || is.na(cstatistic) ||
          cstatistic <= 0.5 || cstatistic >= 1) {
      stop("cstatistic must be a single number strictly between 0.5 and 1.")
    }
  }

  res <- pmsampsize::pmsampsize(
    type = "b", parameters = parameters, prevalence = prevalence, shrinkage = shrinkage,
    csrsquared = if (is.null(csrsquared)) NA else csrsquared,
    cstatistic = if (is.null(cstatistic)) NA else cstatistic
  )

  list(
    n = res$sample_size,
    events = ceiling(res$events),
    csrsquared = res$rsquared,
    max_r2a = res$max_r2a,
    nag_r2 = res$nag_r2,
    epp = res$EPP,
    inputs = list(parameters = parameters, prevalence = prevalence,
                  csrsquared = csrsquared, cstatistic = cstatistic, shrinkage = shrinkage)
  )
}

#' Sample size for developing a prediction model with a continuous outcome
#'
#' Wraps pmsampsize::pmsampsize(type = "c").
#'
#' @param parameters Number of candidate predictor parameters (whole number >= 1)
#' @param intercept Expected mean outcome value in the population
#' @param sd Expected standard deviation of outcome values (> 0)
#' @param rsquared Expected R-squared of the new model (0,1) -- use an
#'   adjusted R-squared from a prior development study, or an apparent R-
#'   squared from a prior external validation
#' @param shrinkage Desired shrinkage factor at internal validation (0,1); default 0.9
#' @param mmoe Acceptable multiplicative margin of error for the intercept; default 1.1
#' @return list(n, rsquared, spp, intercept_lci, intercept_uci, inputs)
calc_prediction_continuous <- function(parameters, intercept, sd, rsquared,
                                        shrinkage = 0.9, mmoe = 1.1) {
  if (!is.numeric(parameters) || length(parameters) != 1 || is.na(parameters) ||
        parameters < 1 || parameters != round(parameters)) {
    stop("parameters must be a single whole number >= 1.")
  }
  .validate_number(intercept, "intercept")
  .validate_positive(sd, "sd")
  .validate_unit_interval(rsquared, "rsquared")
  .validate_unit_interval(shrinkage, "shrinkage")
  .validate_positive(mmoe, "mmoe")

  res <- pmsampsize::pmsampsize(type = "c", parameters = parameters, intercept = intercept,
                                 sd = sd, rsquared = rsquared, shrinkage = shrinkage, mmoe = mmoe)

  list(
    n = res$sample_size,
    rsquared = res$r2a,
    spp = res$SPP,
    intercept_lci = res$int_lci,
    intercept_uci = res$int_uci,
    inputs = list(parameters = parameters, intercept = intercept, sd = sd,
                  rsquared = rsquared, shrinkage = shrinkage, mmoe = mmoe)
  )
}

#' Sample size for developing a prediction model with a survival (time-to-event) outcome
#'
#' Wraps pmsampsize::pmsampsize(type = "s").
#'
#' @param parameters Number of candidate predictor parameters (whole number >= 1)
#' @param rate Expected overall event rate in the population (same time
#'   units as timepoint/meanfup, > 0)
#' @param timepoint Timepoint of interest for prediction (same time units as rate/meanfup, > 0)
#' @param meanfup Expected mean follow-up time (same time units as rate/timepoint, > 0)
#' @param csrsquared Expected Cox-Snell R-squared of the new model (0,1)
#' @param shrinkage Desired shrinkage factor at internal validation (0,1); default 0.9
#' @return list(n, events, csrsquared, max_r2a, nag_r2, epp, inputs)
calc_prediction_survival <- function(parameters, rate, timepoint, meanfup,
                                      csrsquared, shrinkage = 0.9) {
  if (!is.numeric(parameters) || length(parameters) != 1 || is.na(parameters) ||
        parameters < 1 || parameters != round(parameters)) {
    stop("parameters must be a single whole number >= 1.")
  }
  .validate_positive(rate, "rate")
  .validate_positive(timepoint, "timepoint")
  .validate_positive(meanfup, "meanfup")
  .validate_unit_interval(csrsquared, "csrsquared")
  .validate_unit_interval(shrinkage, "shrinkage")

  res <- pmsampsize::pmsampsize(type = "s", parameters = parameters, rate = rate,
                                 timepoint = timepoint, meanfup = meanfup,
                                 csrsquared = csrsquared, shrinkage = shrinkage)

  list(
    n = res$sample_size,
    events = ceiling(res$events),
    csrsquared = res$r2a,
    max_r2a = res$max_r2a,
    nag_r2 = res$nag_r2,
    epp = res$EPP,
    inputs = list(parameters = parameters, rate = rate, timepoint = timepoint,
                  meanfup = meanfup, csrsquared = csrsquared, shrinkage = shrinkage)
  )
}
