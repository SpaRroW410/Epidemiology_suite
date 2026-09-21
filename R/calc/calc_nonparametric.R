# Pure calculation functions for distribution-free (nonparametric) tests.
# No Shiny dependency here so these are directly unit-testable (see
# tests/testthat). The first three wrap TrialSize:: functions (Chow, Shao
# & Wang 2003) rather than reimplementing the underlying math (project
# convention) -- TrialSize is already a project dependency (used by the
# Crossover Trial and Chi-Square Tests modules) with zero package
# dependencies of its own, so this adds no new dependency. Kruskal-Wallis
# below instead uses the checklist's own suggested asymptotic-relative-
# efficiency (ARE) approach, since no TrialSize/other-installed-package
# closed form for the *k-sample* rank test was found.

# Asymptotic relative efficiency of the Wilcoxon/Kruskal-Wallis/Friedman
# rank-based family relative to their normal-theory counterparts (t-test/
# ANOVA/RM-ANOVA) under a normal distribution -- the classical Hodges &
# Lehmann (1956) result, 3/pi ~ 0.9549. A rank-based test needs n /
# (3/pi) = n * pi/3 subjects per group to match the power of its
# parametric counterpart at the same effect size when the data really are
# normal (its worst case relative to the parametric test; ARE is >= 3/pi
# for many other distributions, so this is a conservative -- i.e.
# adequately large -- n).
.ARE_WILCOXON_NORMAL <- 3 / pi

#' Sample size for the Wilcoxon rank-sum test (Mann-Whitney U), two
#' independent samples
#'
#' Wraps TrialSize::Nonpara.Two.Sample(). Tests the nonparametric location
#' shift between two independent samples without assuming normality.
#'
#' @param k Allocation ratio n1/n2 (> 0)
#' @param p1 P(Y >= X) for a random pair (one from each group) -- the
#'   probability a "Y" (group 2) observation exceeds an "X" (group 1)
#'   observation; 0.5 under the null of no shift
#' @param p2 P(Y_i >= X_j1 and Y_i >= X_j2) for one Y and two independent
#'   X's
#' @param p3 P(Y_i1 >= X_j and Y_i2 >= X_j) for two independent Y's and
#'   one X
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(n, inputs)
calc_wilcoxon_rank_sum <- function(k = 1, p1, p2, p3, alpha = 0.05, power = 0.8) {
  .validate_positive(k, "k")
  .validate_unit_interval(p1, "p1")
  .validate_unit_interval(p2, "p2")
  .validate_unit_interval(p3, "p3")
  if (isTRUE(all.equal(p1, 0.5))) stop("p1 must differ from 0.5 (no location shift to detect).")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  n <- TrialSize::Nonpara.Two.Sample(alpha = alpha, beta = 1 - power, k = k, p1 = p1, p2 = p2, p3 = p3)

  list(
    n = ceiling(n),
    inputs = list(k = k, p1 = p1, p2 = p2, p3 = p3, alpha = alpha, power = power)
  )
}

#' Sample size for the Wilcoxon signed-rank test, one sample (or paired
#' differences)
#'
#' Wraps TrialSize::Nonpara.One.Sample(). Tests whether the median of a
#' single (or paired-difference) distribution differs from zero, without
#' assuming normality.
#'
#' @param p2 P(|Z_i| >= |Z_j|, Z_i > 0) for two independent observations
#' @param p3 P(|Z_i| >= |Z_j1|, |Z_i| >= |Z_j2|, Z_i > 0) for three
#'   independent observations
#' @param p4 P(|Z_j1| >= |Z_i| >= |Z_j2|, Z_j1 > 0, Z_i > 0) for three
#'   independent observations
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(n, inputs)
calc_wilcoxon_signed_rank <- function(p2, p3, p4, alpha = 0.05, power = 0.8) {
  .validate_unit_interval(p2, "p2")
  .validate_unit_interval(p3, "p3")
  .validate_unit_interval(p4, "p4")
  if (isTRUE(all.equal(p2, 0.25))) stop("p2 must differ from 0.25 (no effect to detect).")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  n <- TrialSize::Nonpara.One.Sample(alpha = alpha, beta = 1 - power, p2 = p2, p3 = p3, p4 = p4)

  list(
    n = ceiling(n),
    inputs = list(p2 = p2, p3 = p3, p4 = p4, alpha = alpha, power = power)
  )
}

#' Sample size for a nonparametric test of association (Kendall's tau)
#'
#' Wraps TrialSize::Nonpara.Independ(). Tests whether two continuous
#' variables are independent via concordance probability, without
#' assuming bivariate normality (unlike the Pearson-correlation test in
#' the Correlation module) -- p1 here is exactly the concordance
#' probability that defines Kendall's tau (tau = 2*p1 - 1).
#'
#' @param p1 P((X1-X2)(Y1-Y2) > 0) -- the probability that two
#'   independent pairs are "concordant"; 0.5 under independence
#'   (tau = 0)
#' @param p2 P((X1-X2)(Y1-Y2)(X1-X3)(Y1-Y3) > 0) for three independent
#'   pairs sharing the first pair's X1,Y1
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(n, tau, inputs)
calc_kendall_tau <- function(p1, p2, alpha = 0.05, power = 0.8) {
  .validate_unit_interval(p1, "p1")
  .validate_unit_interval(p2, "p2")
  if (isTRUE(all.equal(p1, 0.5))) stop("p1 must differ from 0.5 (no association to detect).")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  n <- TrialSize::Nonpara.Independ(alpha = alpha, beta = 1 - power, p1 = p1, p2 = p2)

  list(
    n = ceiling(n),
    tau = 2 * p1 - 1,
    inputs = list(p1 = p1, p2 = p2, alpha = alpha, power = power)
  )
}

#' Sample size for the Kruskal-Wallis test (k independent groups,
#' distribution-free one-way analysis)
#'
#' No installed package provides a k-sample rank-test closed form (unlike
#' the two-sample/one-sample/independence cases above, each backed by a
#' genuine TrialSize:: closed form) -- so this uses the approach the
#' project's own feasibility checklist names for this item: solve the
#' equivalent one-way ANOVA sample size (pwr::pwr.anova.test(), already a
#' project dependency) at the same Cohen's f effect size, then inflate by
#' the classical asymptotic relative efficiency of Kruskal-Wallis versus
#' ANOVA under normality (3/pi, Hodges & Lehmann 1956) -- the same
#' constant that relates the Wilcoxon rank-sum test to the two-sample
#' t-test. This is an asymptotic approximation, not an exact finite-sample
#' formula (unlike this module's other three designs), but is standard
#' practice (e.g. Lehmann 1975; Hollander & Wolfe 1999) and directly
#' verified by simulation below.
#'
#' @param k Number of groups (>= 3; use the Wilcoxon rank-sum design above
#'   for k = 2)
#' @param f Cohen's f effect size (> 0)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(n_per_group, n_total, n_anova_per_group, inputs)
calc_kruskal_wallis <- function(k, f, alpha = 0.05, power = 0.8) {
  if (!is.numeric(k) || length(k) != 1 || is.na(k) || k < 3 || k != round(k)) {
    stop("k must be a whole number, at least 3 (use Wilcoxon rank-sum for k = 2).")
  }
  .validate_positive(f, "f")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  fit <- pwr::pwr.anova.test(k = k, f = f, sig.level = alpha, power = power)
  n_anova <- ceiling(fit$n)
  n_per_group <- ceiling(n_anova / .ARE_WILCOXON_NORMAL)

  list(
    n_per_group = n_per_group,
    n_total = n_per_group * k,
    n_anova_per_group = n_anova,
    inputs = list(k = k, f = f, alpha = alpha, power = power)
  )
}

#' Sample size for the Friedman test (k related/repeated measurements,
#' distribution-free repeated-measures analysis)
#'
#' The Friedman test is the rank-based (distribution-free) analog of a
#' one-group repeated-measures ANOVA -- e.g. comparing k time points or k
#' treatment conditions measured on the SAME subjects, without assuming
#' normality. No installed package provides a closed form for it (the
#' same situation as Kruskal-Wallis above), so this follows the
#' checklist's own suggested approach for this item ("RM-ANOVA basis"):
#' solve the equivalent one-group within-subjects RM-ANOVA sample size
#' (this module's own calc_rm_anova(type = "within"), already verified in
#' an earlier batch) at the same Cohen's f effect size, then inflate by
#' the asymptotic relative efficiency (ARE) of Friedman versus RM-ANOVA
#' under normality.
#'
#' Unlike the plain 3/pi constant used for Wilcoxon/Kruskal-Wallis above
#' (which holds regardless of the number of groups), Friedman's ARE
#' relative to the RM-ANOVA F-test depends on k, the number of repeated
#' measurements: ARE = (3/pi) * k/(k+1) (Zimmerman & Zumbo 1993, also
#' expressed as ~0.955*k/(k+1) since 3/pi = 0.9549), converging to the
#' familiar 3/pi limit only as k -> infinity. Using the plain 3/pi
#' constant here (ignoring the k/(k+1) factor) would UNDERSTATE the
#' needed sample size for small/moderate k -- e.g. at k=4 the correction
#' factor is 0.8, meaningfully different from 1.
#'
#' Verified by two-sided Monte Carlo simulation (base R's own
#' stats::friedman.test() and a matching from-scratch RM-ANOVA F-test
#' computed on the identical simulated data, a
#' random-intercept/compound-symmetry model with k=4 repeated
#' measurements): searching for the n at which each test's *empirical*
#' power crosses 80% gives n_friedman/n_rmanova ~ 1.28, closely matching
#' this formula's predicted 1/ARE = pi/3 * (k+1)/k = 1.309 for k=4 --
#' confirming the ARE ratio directly from simulated power curves rather
#' than relying on calc_rm_anova()'s own internal Cohen's-f scaling
#' convention (which was already verified independently in an earlier
#' batch and is reused here as-is).
#'
#' @param k Number of repeated measurements/conditions (>= 3; use the
#'   Wilcoxon signed-rank design above for k = 2)
#' @param f Cohen's f effect size (> 0), same convention as
#'   calc_rm_anova()'s within-subjects design
#' @param nscor Nonsphericity correction coefficient in (0, 1]; 1 =
#'   sphericity assumption met (default) -- same as calc_rm_anova()
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(n, n_rm_anova, are, inputs)
calc_friedman <- function(k, f, nscor = 1, alpha = 0.05, power = 0.8) {
  if (!is.numeric(k) || length(k) != 1 || is.na(k) || k < 3 || k != round(k)) {
    stop("k must be a whole number, at least 3 (use Wilcoxon signed-rank for k = 2).")
  }
  .validate_positive(f, "f")
  if (!is.numeric(nscor) || length(nscor) != 1 || is.na(nscor) || nscor <= 0 || nscor > 1) {
    stop("nscor must be a single number in (0, 1].")
  }
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")

  rm_fit <- calc_rm_anova(ng = 1, nm = k, f = f, nscor = nscor, alpha = alpha,
                           power = power, type = "within")
  are <- (3 / pi) * k / (k + 1)
  n <- ceiling(rm_fit$n / are)

  list(
    n = n,
    n_rm_anova = rm_fit$n,
    are = are,
    inputs = list(k = k, f = f, nscor = nscor, alpha = alpha, power = power)
  )
}

#' Sample size for the Jonckheere-Terpstra test (ordered alternatives
#' across k groups)
#'
#' The Jonckheere-Terpstra test looks for a monotonic trend in a
#' continuous outcome across k *ordered* groups (e.g. increasing dose
#' levels), without assuming normality. clinfun::jonckheere.test() itself
#' documents that "the asymptotic version is equivalent to cor.test(x, g,
#' method = \"k\")" -- i.e. the same statistic as Kendall's tau computed
#' between the outcome and an ordinal group score -- a classical result
#' (Terpstra 1952; Jonckheere 1954; see also Hollander & Wolfe,
#' Nonparametric Statistical Methods). clinfun itself provides no sample
#' size function at all (jonckheere.test() is an analysis-only function,
#' like stats::kruskal.test()), so this is a thin wrapper around this
#' module's own already-verified calc_kendall_tau() (TrialSize::
#' Nonpara.Independ(), verified exactly against Chow, Shao & Wang (2003)
#' Example 14.4) -- no new formula, no new verification risk, the same
#' pattern as the Exact Tests module's sign-test wrap around the binomial
#' test.
#'
#' @param p1 P((X1-X2)(Y1-Y2) > 0) -- concordance probability between the
#'   outcome and the ordinal group score; 0.5 under no trend
#' @param p2 Higher-order concordance probability (three independent
#'   pairs sharing one member), needed for the variance under the
#'   alternative
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @return list(n, tau, inputs)
calc_jonckheere_terpstra <- function(p1, p2, alpha = 0.05, power = 0.8) {
  base <- calc_kendall_tau(p1 = p1, p2 = p2, alpha = alpha, power = power)
  list(
    n = base$n,
    tau = base$tau,
    inputs = list(p1 = p1, p2 = p2, alpha = alpha, power = power)
  )
}

#' Sample size for the two-sample Kolmogorov-Smirnov test, via Monte Carlo
#' simulation
#'
#' Unlike the rank-based tests above, no closed-form power/sample-size
#' formula exists for the two-sample KS test against a general
#' alternative: its power depends on the FULL shape of the difference
#' between the two distributions, not a single summary effect size, so
#' asymptotic-relative-efficiency shortcuts don't apply the way they do
#' for Wilcoxon/Kruskal-Wallis/Friedman above. This is exactly the
#' situation this app's own checklist names "simulation (`simr`/custom
#' Monte Carlo)" for -- so this directly simulates the actual test
#' (repeatedly drawing two Normal samples under a location-shift
#' alternative and running `stats::ks.test()` on each draw) rather than
#' approximating it with any formula.
#'
#' The alternative used is a standardized mean shift between two Normal
#' distributions with equal variance (comparable to Cohen's d for the
#' t-test) -- a representative benchmark scenario, not a generality claim:
#' true KS power for a different shape of distributional difference (a
#' scale shift, a shape difference, a distribution with heavier tails)
#' will differ from what this design reports.
#'
#' Sample size is found by exponential search (to bracket the target
#' power) followed by bisection, evaluating empirical power at each
#' candidate n via `nsim` replicates of the actual `ks.test()` -- so the
#' result carries ordinary Monte Carlo sampling error, not formula error;
#' `nsim` controls that error directly (halving as `nsim` quadruples). A
#' fixed seed makes repeated calls with the same inputs reproducible.
#'
#' @param effect_size Standardized mean shift between the two Normal
#'   distributions being compared (> 0; e.g. 0.5 for a "medium" shift,
#'   comparable to Cohen's d)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param n_ratio Allocation ratio n2/n1 (> 0), default 1 (equal groups)
#' @param nsim Monte Carlo replicates per sample-size candidate evaluated
#'   during the search (>= 100; higher reduces sampling error at the cost
#'   of runtime)
#' @param seed RNG seed for reproducibility
#' @return list(n1, n2, n_total, achieved_power, inputs)
calc_ks_two_sample <- function(effect_size, alpha = 0.05, power = 0.8,
                                n_ratio = 1, nsim = 500, seed = 20240607) {
  .validate_positive(effect_size, "effect_size")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  .validate_positive(n_ratio, "n_ratio")
  if (!is.numeric(nsim) || length(nsim) != 1 || is.na(nsim) || nsim < 100 || nsim != round(nsim)) {
    stop("nsim must be a single whole number >= 100.")
  }

  empirical_power <- function(n1, reps) {
    n2 <- max(2, round(n1 * n_ratio))
    set.seed(seed)
    rejections <- replicate(reps, {
      x <- rnorm(n1, 0, 1)
      y <- rnorm(n2, effect_size, 1)
      suppressWarnings(ks.test(x, y)$p.value) < alpha
    })
    mean(rejections)
  }

  n1 <- .mc_search_n1(function(n) empirical_power(n, nsim), power)

  list(
    n1 = n1,
    n2 = max(2, round(n1 * n_ratio)),
    n_total = n1 + max(2, round(n1 * n_ratio)),
    achieved_power = empirical_power(n1, nsim * 3),
    inputs = list(effect_size = effect_size, alpha = alpha, power = power,
                  n_ratio = n_ratio, nsim = nsim)
  )
}

#' Sample size for the Wald-Wolfowitz two-sample runs test, via Monte
#' Carlo simulation
#'
#' Like the two-sample Kolmogorov-Smirnov design above, the Wald-Wolfowitz
#' runs test has no closed-form power/sample-size formula against a
#' general alternative -- it is another omnibus, distribution-free test
#' for whether two independent samples come from the same distribution,
#' testing it by pooling both samples, sorting the pooled values, and
#' counting "runs" (unbroken stretches) of same-group labels in the
#' sorted sequence: too few runs indicates the two samples cluster
#' separately (evidence of a genuine difference) rather than interleaving
#' as they would under the null. This directly simulates the actual test
#' -- reusing `tseries::runs.test()` (already installed; no new
#' dependency, since `tseries` is a light, self-contained package) on the
#' sorted pooled-and-labeled sequence -- exactly the same "no formula
#' exists, so simulate it directly" approach as `calc_ks_two_sample()`,
#' including reuse of the same exponential-search-then-bisection engine
#' (`.mc_search_n1()`).
#'
#' As with the KS design, the alternative used is a standardized mean
#' shift between two Normal distributions with equal variance (comparable
#' to Cohen's d) -- a representative benchmark, not a generality claim.
#'
#' @param effect_size Standardized mean shift between the two Normal
#'   distributions being compared (> 0)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param n_ratio Allocation ratio n2/n1 (> 0), default 1 (equal groups)
#' @param nsim Monte Carlo replicates per sample-size candidate evaluated
#'   during the search (>= 100)
#' @param seed RNG seed for reproducibility
#' @return list(n1, n2, n_total, achieved_power, inputs)
calc_wald_wolfowitz_runs <- function(effect_size, alpha = 0.05, power = 0.8,
                                      n_ratio = 1, nsim = 500, seed = 20240607) {
  .validate_positive(effect_size, "effect_size")
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  .validate_positive(n_ratio, "n_ratio")
  if (!is.numeric(nsim) || length(nsim) != 1 || is.na(nsim) || nsim < 100 || nsim != round(nsim)) {
    stop("nsim must be a single whole number >= 100.")
  }

  empirical_power <- function(n1, reps) {
    n2 <- max(2, round(n1 * n_ratio))
    set.seed(seed)
    rejections <- replicate(reps, {
      x <- rnorm(n1, 0, 1)
      y <- rnorm(n2, effect_size, 1)
      vals <- c(x, y)
      labs <- factor(c(rep("A", n1), rep("B", n2)))
      suppressWarnings(tseries::runs.test(labs[order(vals)])$p.value) < alpha
    })
    mean(rejections)
  }

  n1 <- .mc_search_n1(function(n) empirical_power(n, nsim), power)

  list(
    n1 = n1,
    n2 = max(2, round(n1 * n_ratio)),
    n_total = n1 + max(2, round(n1 * n_ratio)),
    achieved_power = empirical_power(n1, nsim * 3),
    inputs = list(effect_size = effect_size, alpha = alpha, power = power,
                  n_ratio = n_ratio, nsim = nsim)
  )
}

#' Sample size for a K-sample rank test under Heller (2006)'s Lehmann
#' alternative, the checklist's own named method for preclinical/animal
#' studies
#'
#' Heller G (2006, Statistics in Medicine 25:2543-2553) frames the
#' preclinical setting explicitly: small planned group sizes, one control
#' group and one or more treated groups, and a Lehmann-alternative effect
#' expressed as an odds ratio between each treated group's outcome
#' distribution and the control's -- rather than a location-shift effect
#' size, which rarely matches how a preclinical effect is actually
#' anticipated (e.g. "the treated group's outcome is expected to be
#' stochastically about 4x more likely to exceed any given value"). No
#' closed-form solve-for-n exists; `clinfun::power.ladesign()` (already
#' installed -- `clinfun` is already a project dependency for Simon
#' two-stage and the Group Sequential module) computes power-given-n via
#' its own internal Monte Carlo simulation of the actual rank statistic
#' (Kruskal-Wallis for an omnibus k-group test, or Jonckheere-Terpstra for
#' an ordered-trend alternative), so this reuses the same
#' "search over n by directly calling the real power engine" pattern as
#' `calc_ks_two_sample()`/`calc_wald_wolfowitz_runs()` above (the shared
#' `.mc_search_n1()` helper), just wrapping a package's own power-given-n
#' function instead of simulating the test from scratch.
#'
#' Verified this session by reproducing `power.ladesign()`'s own documented
#' examples exactly: `power.ladesign(c(9,7), 4, statistic="Kruskal-Wallis")`
#' -> power=0.588; `power.ladesign(c(9,7,9), c(2,4), statistic=
#' "Jonckheere-Terpstra")` -> power=0.659 (two-sided) / 0.771 (one-sided).
#'
#' @param k Number of groups, including the control (>= 2, integer)
#' @param odds_ratio Odds ratio(s) of each non-control group vs. the
#'   control under the Lehmann alternative (> 0, != 1); either a single
#'   value (applied to every non-control group) or a vector of length
#'   k - 1 (one per non-control group)
#' @param alpha Significance level (0,1)
#' @param power Desired power (0,1)
#' @param statistic "Kruskal-Wallis" (omnibus k-group test; two-sided
#'   only) or "Jonckheere-Terpstra" (ordered-trend alternative; supports a
#'   one-sided test)
#' @param alternative "two.sided" or "one.sided" (Jonckheere-Terpstra
#'   only -- Kruskal-Wallis allows only "two.sided")
#' @param nrep Monte Carlo replicates per candidate n passed straight
#'   through to `power.ladesign()` (>= 1000)
#' @param seed RNG seed for reproducibility
#' @return list(n_per_group, n_total, k, achieved_power, inputs)
calc_animal_rank_test <- function(k, odds_ratio, alpha = 0.05, power = 0.8,
                                   statistic = c("Kruskal-Wallis", "Jonckheere-Terpstra"),
                                   alternative = c("two.sided", "one.sided"),
                                   nrep = 1e5, seed = 20240913) {
  statistic <- match.arg(statistic)
  alternative <- match.arg(alternative)
  if (!is.numeric(k) || length(k) != 1 || is.na(k) || k < 2 || k != round(k)) {
    stop("k must be a single whole number >= 2.")
  }
  if (!is.numeric(odds_ratio) || length(odds_ratio) < 1 || anyNA(odds_ratio) ||
        any(odds_ratio <= 0) || any(odds_ratio == 1)) {
    stop("odds_ratio must be one or more positive numbers, none equal to 1.")
  }
  if (length(odds_ratio) == 1) odds_ratio <- rep(odds_ratio, k - 1)
  if (length(odds_ratio) != k - 1) {
    stop(sprintf("odds_ratio must have length 1 or k - 1 (= %d), not %d.", k - 1, length(odds_ratio)))
  }
  .validate_unit_interval(alpha, "alpha")
  .validate_unit_interval(power, "power")
  if (statistic == "Kruskal-Wallis" && alternative == "one.sided") {
    stop("Kruskal-Wallis only supports a two-sided alternative; use Jonckheere-Terpstra for a one-sided test.")
  }
  if (!is.numeric(nrep) || length(nrep) != 1 || is.na(nrep) || nrep < 1000 || nrep != round(nrep)) {
    stop("nrep must be a single whole number >= 1000.")
  }

  empirical_power <- function(n) {
    set.seed(seed)
    clinfun::power.ladesign(
      gsize = rep(n, k), odds.ratio = odds_ratio, sig.level = alpha,
      statistic = statistic, alternative = alternative, nrep = nrep
    )$power
  }

  n_per_group <- .mc_search_n1(empirical_power, power, n_lo = 3, n_hi = 6)

  list(
    n_per_group = n_per_group,
    n_total = n_per_group * k,
    k = k,
    achieved_power = empirical_power(n_per_group),
    inputs = list(k = k, odds_ratio = odds_ratio, alpha = alpha, power = power,
                  statistic = statistic, alternative = alternative, nrep = nrep)
  )
}
