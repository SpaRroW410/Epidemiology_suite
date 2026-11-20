# Approximate mean and standard deviation from a median and interquartile range, for planning a comparison of means when the pilot
# data or the literature report medians (ROADMAP; owner's request of 2 Nov 2026: "median with IQR should lead to paired / unpaired
# mean differences").
#
# Wan X, Wang W, Liu J, Tong T. Estimating the sample mean and standard deviation from the sample size, median, range and/or
# interquartile range. BMC Med Res Methodol 2014;14:135. doi:10.1186/1471-2288-14-135 (PMID 25524443, PMC4383202; read through
# PubMed Central). Scenario C3 (first quartile, median, third quartile and sample size known):
#   mean ~ (q1 + m + q3) / 3                                      (their formula 14)
#   SD   ~ (q3 - q1) / (2 qnorm((0.75 n - 0.125) / (n + 0.25)))   (their formula 16, Blom's approximation of the expected quartiles)
# As n grows the denominator tends to 2 qnorm(0.75) = 1.349, the Cochrane Handbook's IQR / 1.35. Both assume roughly normal data;
# for a clearly skewed outcome a rank-based test (Wilcoxon / Mann-Whitney) is the alternative, and the app says so.

#' Approximate mean and standard deviation from the median and interquartile range
#'
#' Wan et al. (2014), scenario C3: mean = (q1 + median + q3) / 3 and SD = (q3 - q1) / (2 qnorm((0.75 n - 0.125) / (n + 0.25))).
#' Use the results as the mean and SD of a means calculator when only a median and IQR are available. The estimates assume roughly
#' normal data; when the outcome is clearly skewed, consider a rank-based test instead.
#'
#' @param median Sample median
#' @param q1,q3 First and third quartiles (q1 <= median <= q3, q1 < q3)
#' @param n Sample size the quartiles come from (>= 2); for the SD only (large n gives IQR / 1.349)
#' @return A named list of class `ss_result` with `mean`, `sd`, `divisor` (the denominator of the SD formula) and `inputs`.
#' @examples
#' calc_mean_sd_from_median_iqr(median = 45, q1 = 38, q3 = 54, n = 60)
#' @export
calc_mean_sd_from_median_iqr <- function(median, q1, q3, n = 100) {
  for (x in list(list(median, "median"), list(q1, "q1"), list(q3, "q3"))) .validate_number(x[[1]], x[[2]])
  if (!(q1 <= median && median <= q3) || q1 >= q3) stop("The quartiles must satisfy q1 <= median <= q3, with q1 < q3.")
  if (!is.numeric(n) || length(n) != 1 || is.na(n) || n < 2) stop("n must be a single number >= 2.")
  divisor <- 2 * stats::qnorm((0.75 * n - 0.125) / (n + 0.25))
  new_ss_result(list(
    mean = (q1 + median + q3) / 3,
    sd = (q3 - q1) / divisor,
    divisor = divisor,
    inputs = list(median = median, q1 = q1, q3 = q3, n = n)
  ))
}
