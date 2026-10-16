# Study planning: inflating a required analyzable sample size for attrition,
# non-response and non-compliance (ROADMAP Track B2, item 14). Closed forms, no package.
#
# Losses: if a fraction d of those enrolled is lost before the analysis, the analyzable
# number is n_enrolled (1 - d), so reaching n_required needs
#     n_enrolled = n_required / (1 - d)                  (rounded up)
# NOT n_required (1 + d), which under-recruits (20% loss on 100 needs 125, not 120).
# Several independent stages (non-response, refusal, loss to follow-up, ...) multiply:
#     n_enrolled = n_required / prod(1 - d_i).
# This is the standard retention argument (e.g. Kirkwood & Sterne, Essential Medical
# Statistics, 2nd ed. 2003; Rothman, Greenland & Lash, Modern Epidemiology) and an
# identity, so it is verified by recomputing the expected completers, not against a package.
#
# Differential loss by arm: each arm is inflated by its own retention. Inflating cannot remove
# the bias that differential loss produces; only the number is restored.
#
# Non-compliance (dilution): in an intention-to-treat comparison, if a fraction R_E of the
# treatment arm drops out (receives the control condition) and a fraction R_C of the control
# arm drops in (receives the treatment), the expected difference in means or proportions
# shrinks to (1 - R_E - R_C) times the planned difference, and the required sample size grows
# by 1 / (1 - R_E - R_C)^2. This relation is DERIVED here from "n is proportional to
# 1 / (difference)^2 with the variance unchanged" and checked by simulation in the unit tests;
# it is the form usually attributed to Lachin JM, Control Clin Trials 1981;2:93-113 (the paper
# exists, but its equations were not read for this tool). It is exact only when the variance
# does not depend on the effect (means with a fixed SD) and approximate for proportions, where
# the better route is to recompute the sample size from the diluted proportions.

.ceil_tol <- function(x) ceiling(round(x, 8))

.attr_validate_n <- function(x, label) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || !is.finite(x) || x < 1) {
    stop(sprintf("%s must be a single number >= 1.", label))
  }
}
.attr_validate_loss <- function(x, label) {
  if (!is.numeric(x) || length(x) != 1 || is.na(x) || !is.finite(x) || x < 0 || x >= 1) {
    stop(sprintf("%s must be a single number from 0 up to (but not including) 1, e.g. 0.2 for 20%%.", label))
  }
}

#' Inflate a required sample size for losses at one or several stages
#'
#' @param n_required Number that must be analyzable at the end.
#' @param losses Fraction lost at each stage, in order (1 to 6 values, each in [0, 1)).
#' @param stages Optional labels for the stages.
calc_attrition_stages <- function(n_required, losses, stages = NULL) {
  .attr_validate_n(n_required, "The required sample size")
  if (!is.numeric(losses) || length(losses) < 1 || length(losses) > 6) stop("Give between 1 and 6 loss fractions.")
  for (i in seq_along(losses)) .attr_validate_loss(losses[i], sprintf("Loss fraction %d", i))
  k <- length(losses)
  if (is.null(stages)) stages <- paste("Stage", seq_len(k))
  retention_stage <- 1 - losses
  retention <- prod(retention_stage)
  n_enrolled <- .ceil_tol(n_required / retention)
  total_loss <- 1 - retention
  naive <- .ceil_tol(n_required * (1 + sum(losses)))
  expected_after <- n_enrolled * cumprod(retention_stage)
  out <- list(
    n_enrolled = n_enrolled, n_required = n_required, extra_to_recruit = n_enrolled - n_required,
    overall_retention = retention, overall_loss = total_loss,
    n_if_loss_added_instead = naive, expected_analyzable = expected_after[k], n_stages = k
  )
  for (i in seq_len(k)) {
    out[[paste0("loss_", i)]] <- losses[i]
    out[[paste0("expected_after_stage_", i)]] <- expected_after[i]
  }
  out$inputs <- list(n_required = n_required, stages = paste(stages, collapse = " | "),
                     losses = paste(losses, collapse = ", "))
  attr_stages <- stages
  res <- new_ss_result(out)
  attr(res, "stages") <- attr_stages
  res
}

#' Inflate per-arm sample sizes for differential losses
#'
#' @param n_required Required analyzable number in each arm (length 2 to 6).
#' @param losses Expected loss fraction in each arm (same length).
#' @param arms Optional arm labels.
calc_attrition_arms <- function(n_required, losses, arms = NULL) {
  if (!is.numeric(n_required) || length(n_required) < 2 || length(n_required) > 6) stop("Give between 2 and 6 arms.")
  if (!is.numeric(losses) || length(losses) != length(n_required)) stop("Give one loss fraction for each arm.")
  k <- length(n_required)
  for (i in seq_len(k)) {
    .attr_validate_n(n_required[i], sprintf("The required number in arm %d", i))
    .attr_validate_loss(losses[i], sprintf("The loss fraction in arm %d", i))
  }
  if (is.null(arms)) arms <- paste("Arm", seq_len(k))
  enrol <- .ceil_tol(n_required / (1 - losses))
  mean_loss <- 1 - sum(n_required) / sum(n_required / (1 - losses))     # loss rate of the inflated design overall
  simple_avg <- .ceil_tol(sum(n_required) / (1 - mean(losses)))
  out <- list(
    n_enrolled_total = sum(enrol), n_required_total = sum(n_required),
    extra_to_recruit = sum(enrol) - sum(n_required),
    overall_loss = mean_loss,
    n_total_if_average_loss_used = simple_avg
  )
  for (i in seq_len(k)) {
    out[[paste0("n_enrolled_arm_", i)]] <- enrol[i]
    out[[paste0("n_required_arm_", i)]] <- n_required[i]
    out[[paste0("loss_arm_", i)]] <- losses[i]
  }
  out$inputs <- list(arms = paste(arms, collapse = " | "), n_required = paste(n_required, collapse = ", "),
                     losses = paste(losses, collapse = ", "))
  res <- new_ss_result(out)
  attr(res, "arms") <- arms
  res
}

#' Inflate a sample size for drop-out and drop-in (dilution of the treatment contrast)
#'
#' @param n_required Sample size computed for full compliance.
#' @param dropout Fraction of the treatment arm that stops treatment (drop-out), in [0, 1).
#' @param dropin Fraction of the control arm that takes up the treatment (drop-in), in [0, 1).
calc_attrition_noncompliance <- function(n_required, dropout, dropin) {
  .attr_validate_n(n_required, "The required sample size")
  .attr_validate_loss(dropout, "The drop-out fraction")
  .attr_validate_loss(dropin, "The drop-in fraction")
  if (dropout + dropin >= 1) stop("Drop-out plus drop-in must be below 1: with 100% non-compliance no effect could be seen.")
  dilution <- 1 - dropout - dropin
  new_ss_result(list(
    n_adjusted = .ceil_tol(n_required / dilution^2), n_required = n_required,
    dilution_factor = dilution, inflation_factor = 1 / dilution^2,
    n_if_simple_loss_used = .ceil_tol(n_required / dilution),
    inputs = list(n_required = n_required, dropout = dropout, dropin = dropin)
  ))
}
