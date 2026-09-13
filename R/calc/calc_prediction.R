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

#' Sample size for externally validating an existing prediction model with a binary outcome
#'
#' Reimplements pmvalsampsize::pmvalsampsize(type = "b") (Riley et al.
#' 2021's four validation criteria: O/E ratio, calibration slope,
#' C-statistic, standardised net benefit -- the required n is the largest
#' of whichever criteria are requested). pmvalsampsize is not installed in
#' this environment and CRAN is unreachable, so this is a direct
#' transcription of the package's own source (fetched from its GitHub CRAN
#' mirror), verified against the package's own documented examples and,
#' independently, against actual glm()-fitted calibration-slope SEs and
#' pROC::ci.auc() confidence-interval widths on simulated data (see
#' tests/testthat/test-calc_prediction.R). Only the "normal" and "beta"
#' options for the assumed linear-predictor (LP) distribution are
#' supported (criteria 2's calibration-slope precision needs a simulated
#' LP distribution) -- the package's third ("lpcstat") option is a more
#' fragile iterative procedure and is intentionally not reimplemented.
#'
#' @param prevalence Expected outcome prevalence in the validation sample (0,1)
#' @param cstatistic Anticipated C-statistic (AUC) of the model at validation (0.5,1)
#' @param lp_method Assumed distribution of the linear predictor (log-odds)
#'   for the calibration-slope criterion: "normal" (LP ~ Normal) or "beta"
#'   (predicted probabilities ~ Beta, converted to LP via logit)
#' @param lp_param1 First distribution parameter: mean (normal) or shape1/alpha (beta)
#' @param lp_param2 Second distribution parameter: sd (normal) or shape2/beta (beta)
#' @param oe Anticipated observed/expected ratio at validation; default 1 (perfect)
#' @param oeciwidth Target CI width for the O/E ratio; default 0.2
#' @param cslope Anticipated calibration slope at validation; default 1 (perfect)
#' @param csciwidth Target CI width for the calibration slope; default 0.2
#' @param cstatciwidth Target CI width for the C-statistic; default 0.1
#' @param sensitivity Anticipated sensitivity at the chosen risk threshold (optional)
#' @param specificity Anticipated specificity at the chosen risk threshold (optional)
#' @param threshold Risk threshold for net-benefit calculation (0,1), required
#'   together with sensitivity/specificity to compute the (optional) 4th criterion
#' @param nbciwidth Target CI width for the standardised net benefit; default 0.2
#' @param simobs Number of simulated observations for the LP distribution; default 1e6
#' @param seed Random seed for the LP simulation (calibration-slope criterion only)
#' @return list(n1, n2, n3, n4, n, events, se_oe, se_cslope, se_cstat, inputs)
calc_prediction_external_validation <- function(prevalence, cstatistic,
                                                 lp_method = c("normal", "beta"),
                                                 lp_param1, lp_param2,
                                                 oe = 1, oeciwidth = 0.2,
                                                 cslope = 1, csciwidth = 0.2,
                                                 cstatciwidth = 0.1,
                                                 sensitivity = NULL, specificity = NULL,
                                                 threshold = NULL, nbciwidth = 0.2,
                                                 simobs = 1e6, seed = 123456) {
  lp_method <- match.arg(lp_method)
  .validate_unit_interval(prevalence, "prevalence")
  if (!is.numeric(cstatistic) || length(cstatistic) != 1 || is.na(cstatistic) ||
        cstatistic <= 0.5 || cstatistic >= 1) {
    stop("cstatistic must be a single number strictly between 0.5 and 1.")
  }
  .validate_number(lp_param1, "lp_param1")
  .validate_number(lp_param2, "lp_param2")
  if (lp_method == "normal" && lp_param2 <= 0) stop("lp_param2 (sd) must be positive for the normal LP method.")
  if (lp_method == "beta" && (lp_param1 <= 0 || lp_param2 <= 0)) {
    stop("lp_param1 and lp_param2 (shape1, shape2) must be positive for the beta LP method.")
  }
  .validate_positive(oe, "oe")
  .validate_positive(oeciwidth, "oeciwidth")
  .validate_number(cslope, "cslope")
  .validate_positive(csciwidth, "csciwidth")
  .validate_positive(cstatciwidth, "cstatciwidth")
  .validate_positive(nbciwidth, "nbciwidth")
  has_nb <- !is.null(sensitivity) && !is.null(specificity) && !is.null(threshold)
  if (has_nb) {
    .validate_unit_interval(sensitivity, "sensitivity")
    .validate_unit_interval(specificity, "specificity")
    .validate_unit_interval(threshold, "threshold")
  }

  set.seed(seed)

  # Criterion 1 -- O/E ratio: iterate SE(ln OE) up until the implied CI width
  # reaches the target, then invert the standard-error-of-a-log-ratio formula.
  width_oe <- 0; se_oe <- 0
  while (width_oe < oeciwidth) {
    se_oe <- se_oe + 0.0001
    ub_oe <- exp(log(oe) + 1.96 * se_oe)
    lb_oe <- exp(log(oe) - 1.96 * se_oe)
    width_oe <- ub_oe - lb_oe
  }
  n1 <- ceiling((1 - prevalence) / (prevalence * se_oe^2))

  # Criterion 2 -- calibration slope: simulate the assumed LP distribution,
  # then use the Borenstein logistic-regression information matrix (I_00,
  # I_01, I_11 -- the expected Fisher information for a calibration model
  # LP -> outcome with true intercept 0 / slope 1) to get SE(c-slope).
  if (lp_method == "normal") {
    LP <- rnorm(n = simobs, mean = lp_param1, sd = lp_param2)
  } else {
    P <- rbeta(n = simobs, shape1 = lp_param1, shape2 = lp_param2)
    LP <- log(P / (1 - P))
  }
  expterm <- exp(LP) / ((1 + exp(LP))^2)
  I_00 <- mean(expterm)
  I_01 <- mean(LP * expterm)
  I_11 <- mean(LP * LP * expterm)
  se_cslope <- csciwidth / (2 * 1.96)
  n2 <- ceiling(I_00 / (se_cslope^2 * (I_00 * I_11 - I_01^2)))

  # Criterion 3 -- C-statistic: closed-form Hanley & McNeil (1982) variance
  # of the AUC, searched over candidate n for the smallest n meeting the
  # target CI width. No simulation involved.
  size <- 1:2000000
  se_cstatsq <- suppressWarnings(
    cstatistic * (1 - cstatistic) *
      (1 + (((size / 2) - 1) * ((1 - cstatistic) / (2 - cstatistic))) +
         ((((size / 2) - 1) * cstatistic) / (1 + cstatistic))) /
      (size * size * prevalence * (1 - prevalence))
  )
  ciwidth_vec <- 2 * 1.96 * sqrt(se_cstatsq)
  hit <- which(ciwidth_vec <= cstatciwidth)[1]
  if (is.na(hit)) stop("No feasible sample size found for the target C-statistic CI width.")
  n3 <- size[hit]
  se_cstat <- sqrt(se_cstatsq[hit])

  # Criterion 4 -- standardised net benefit (only if sensitivity/specificity/
  # threshold are all supplied). Closed form, no simulation.
  n4 <- NA_real_
  se_nb <- NA_real_; standardised_nb <- NA_real_
  if (has_nb) {
    nb <- (sensitivity * prevalence) - ((1 - specificity) * (1 - prevalence) * (threshold / (1 - threshold)))
    standardised_nb <- nb / prevalence
    w <- ((1 - prevalence) / prevalence) * (threshold / (1 - threshold))
    width_nb <- 0; se_nb <- 0
    while (width_nb < nbciwidth) {
      se_nb <- se_nb + 0.0001
      ub_nb <- standardised_nb + 1.96 * se_nb
      lb_nb <- standardised_nb - 1.96 * se_nb
      width_nb <- ub_nb - lb_nb
    }
    se_nb <- round(se_nb, 3)
    n4 <- ceiling((1 / se_nb^2) * (((sensitivity * (1 - sensitivity)) / prevalence) +
      (w^2 * specificity * (1 - specificity) / (1 - prevalence)) +
      (w^2 * (1 - specificity)^2 / (prevalence * (1 - prevalence)))))
  }

  nfinal <- max(n1, n2, n3, n4, na.rm = TRUE)

  list(
    n1 = n1, n2 = n2, n3 = n3, n4 = if (has_nb) n4 else NULL,
    n = nfinal, events = ceiling(nfinal * prevalence),
    se_oe = se_oe, se_cslope = se_cslope, se_cstat = se_cstat,
    standardised_nb = if (has_nb) standardised_nb else NULL,
    se_nb = if (has_nb) se_nb else NULL,
    inputs = list(prevalence = prevalence, cstatistic = cstatistic, lp_method = lp_method,
                  lp_param1 = lp_param1, lp_param2 = lp_param2, oe = oe, oeciwidth = oeciwidth,
                  cslope = cslope, csciwidth = csciwidth, cstatciwidth = cstatciwidth,
                  sensitivity = sensitivity, specificity = specificity, threshold = threshold,
                  nbciwidth = nbciwidth)
  )
}
