# Sample Size Calculator

An R Shiny web app for sample size and power calculations for community
medicine, epidemiology, and clinical research, with an explained-formula help
tab and original-source citation for every calculator. Background and full
design rationale: [`docs/project-brief.md`](docs/project-brief.md) and
[`docs/SDD.md`](docs/SDD.md). The full calculator backlog (~90 scenarios,
by study design and by statistical test, staged into a 4-phase build plan)
lives in [`docs/checklist_by_design.md`](docs/checklist_by_design.md) and
[`docs/checklist_by_test.md`](docs/checklist_by_test.md) — check those,
not the SDD, for what's built and what's next.

This is Phase 1 (app shell, Home finders, Proportions module) plus the start
of Phase 2: thirty complete calculator modules -- all Stage-1 CORE items
from the master checklists are now built, plus two "quick wins" batches of
further CORE items, and the start of Stage 2 (analytical depth) --

- **Proportions** (`R/modules/mod_proportion.R`) -- single proportion
  (precision-based, Cochran's formula, with optional finite population
  correction), single proportion vs. known value, two independent
  proportions; plus a post-hoc pairwise comparison design (Bonferroni-
  adjusted, wraps `TrialSize::OneWayANOVA.PairwiseComparison()`) for sizing
  one specific pairwise comparison out of several planned across a
  multi-group study -- verified against Chow, Shao & Wang (2003) Example
  4.4.2 (n=96 and n=44 per group for its two worked cases)
- **Means** (`R/modules/mod_means.R`) -- single mean, precision-based
  (wraps `epiR::epi.sssimpleestc()`), single mean vs. known value, two
  independent means (equal or unequal group sizes, the latter via
  `pwr::pwr.t2n.test()`), two paired means (before-after / matched pairs),
  and three or more independent groups (one-way ANOVA, wraps
  `pwr::pwr.anova.test()`, converting raw group means to Cohen's f); plus a
  planned linear contrast design for testing one pre-specified comparison
  across k group means (e.g. a linear dose-response trend) rather than the
  ANOVA design's omnibus "any groups differ" question, wrapping
  `TrialSize::Dose.Response.Linear()` -- verified exactly against Chow,
  Shao & Wang (2003) Example 11.1 (n=178); and a post-hoc pairwise
  comparison design (Bonferroni-adjusted, wraps
  `TrialSize::OneWayANOVA.pairwise()`) for sizing one specific pairwise
  comparison of two group means out of several planned comparisons --
  both post-hoc designs' formulas were independently re-derived from the
  standard two-sample sample-size formula with alpha/tau in place of
  alpha, since neither package function's own documentation prints a
  numeric worked answer; plus a Welch's-t-test (unequal-variance)
  independent-means design, `calc_means_welch()` -- `MESS::power_t_test()`
  isn't installed and this sandbox has no CRAN access to add it, so this
  keeps the two group variances separate in the noncentrality calculation
  rather than pooling them (the standard large-sample normal-approximation
  formula, Julious 2004; Rosner), verified two ways: with equal variances
  it reduces exactly to `TrialSize::TwoSampleMean.Equality()`'s own
  documented example (n=63), and for unequal variances (sigma1=1,
  sigma2=2) a Monte Carlo simulation using R's own Welch t-test confirmed
  empirical power 0.793 against the 0.80 target at n=157/group
- **Diagnostic Accuracy** (`R/modules/mod_diagnostic.R`) -- sensitivity &
  specificity, precision-based or vs. a known/reference value, comparing
  two diagnostic tests (unpaired or paired), all per Akoglu (2022)'s
  practical guide, plus predictive values (PPV/NPV, precision-based --
  Buderer's prevalence-adjustment logic extended to Altman & Bland 1994's
  PPV/NPV formulas) and likelihood ratios (LR+/LR-, wrapping
  `presize::prec_pos_lr()`/`prec_neg_lr()`, Simel, Samsa & Matchar 1991)
  -- plus the diagnostic odds ratio (DOR), a thin wrapper reusing the
  module's own two-independent-tests engine (Sn=P1, 1-Sp=P2 -- testing
  DOR=1 is mathematically the same comparison), verified Sn=0.80/Sp=0.70
  -> DOR=9.33, n=19/group (38 total) -- see that module's own doc comments
  and `R/content/content_diagnostic.R` for the full formula set and
  citations (Buderer 1996, Casagrande & Pike 1978, Connor 1987, Obuchowski
  1998, Altman & Bland 1994, Simel et al 1991, Glas et al 2003)
- **Agreement / Reliability** (`R/modules/mod_agreement.R`) -- for when
  there's *no* gold standard at all, only two raters/methods being compared
  to each other: Cohen's kappa (categorical, wraps `presize::prec_kappa()` /
  Donner & Eliasziw 1987, Rotondi & Donner 2012), the intraclass
  correlation coefficient (continuous, wraps `presize::prec_icc()` / Bonett
  2002), Cronbach's alpha (scale internal consistency, wraps
  `presize::prec_cronb()` / Bonett & Wright 2015), Bland-Altman limits
  of agreement (wraps `presize::prec_lim_agree()` / Bland & Altman 1986),
  and Lin's concordance correlation coefficient (closed-form, Lin 1989/
  2000 -- no CRAN package implements a dedicated CCC sample-size
  function, so this reimplements the exact asymptotic variance formula
  that `epiR::epi.ccc()` itself already uses internally for its own
  confidence interval; epiR is already a project dependency)
- **Case-Control** (`R/modules/mod_case_control.R`) -- unmatched and matched
  (1:1 or 1:m) case-control studies, both wrapping `epiR::epi.sscc()`
  (Dupont 1988; Woodward 2014); nested case-control (binary or continuous
  exposure), wrapping `powerSurvEpi::powerConLogistic.bin()`/`.con()`
  (Lachin 2008 §3.1/§3.3); and case-cohort, closed-form reimplementation
  of `gap::ccsize()`'s sample-size equation (Cai & Zeng 2004) rather than
  a runtime dependency on `gap`, whose `dplyr`/`ggplot2`/`plotly`/`Rdpack`
  imports are far heavier than this one formula needs
- **Cohort / RR** (`R/modules/mod_cohort.R`) -- cohort/cross-sectional
  relative-risk studies, wrapping `epiR::epi.sscohortc()` (Kelsey,
  Thompson & Evans 1986; Woodward 2014)
- **Correlation** (`R/modules/mod_correlation.R`) -- Pearson correlation,
  wrapping `pwr::pwr.r.test()` (Cohen 1988); plus comparing two
  independent correlations via Cohen's q effect size (Fisher z),
  closed-form since `pwr` has no dedicated two-sample function for this
  case; plus a point-biserial correlation design (converts r to Cohen's
  d = 2r/sqrt(1-r^2) and reuses `pwr::pwr.t.test()`; verified r=0.5 ->
  d=1.1547 -> n=13/group, cross-checked by simulation) and a simple
  linear regression slope design (uses the exact identity
  r = slope*SDx/SDy and reuses `pwr::pwr.r.test()`; verified slope=0.5,
  SDx=2, SDy=4 -> r=0.25 -> n=123); and a partial correlation design
  (controlling for k covariates), reusing `pwr::pwr.r.test()`'s
  zero-order-correlation engine plus k additional subjects, since testing
  a partial correlation loses one degree of freedom per covariate (Cohen
  1988's own tables read partial correlation off the same table as
  zero-order correlation, entered with n-k); verified r=0.3, k=2 -> n=87,
  cross-checked by simulation; and a "compare two dependent (overlapping)
  correlations" design, for testing whether Y correlates more strongly
  with X1 than X2 when both are measured on the SAME sample (unlike the
  independent-correlations design above), closed-form (Steiger 1980's
  Fisher z'-transformation Z-test, eq. 14-15, since no installed package
  implements this as a sample-size formula) -- verified against the
  `psych` package's `r.test()` (an analysis, not sample-size, function
  implementing Steiger's exact raw-r t-statistic, eq. 3-4, confirmed to
  reproduce Steiger's own 1980 textbook example exactly: r_yx1=.4,
  r_yx2=.5, r_x1x2=.1, n=103 -> t=-0.89) and by simulation: r_yx1=0.4,
  r_yx2=0.6, r_x1x2=0.3, alpha=0.05, power=0.80 -> n=183, empirical power
  0.816 at 5,000 replicates; and a Spearman rank correlation design -- no
  installed package provides a Spearman-specific closed form, so this
  does exactly what this app's own checklist names for this item:
  solves the equivalent Pearson-correlation n via this module's own
  `calc_correlation()`, then inflates it by the classical asymptotic
  relative efficiency of Spearman's rho relative to Pearson's r under
  bivariate normality, 9/pi^2 ~ 0.9119 (Hotelling & Pabst 1936; Fieller,
  Hartley & Pearson 1957) -- the same ARE-inflation pattern already used
  by the Nonparametric Tests module's Kruskal-Wallis and Friedman
  designs. Verified: r=0.3, alpha=0.05, 80% power -> Pearson n=85,
  Spearman n=94; independently confirmed by a 3,000-replicate Monte
  Carlo simulation of the actual `stats::cor.test(method="spearman")` on
  simulated bivariate normal data at rho=0.3 -- empirical power 0.796 at
  n=94 (matching the 0.80 target) versus only 0.752 at the unadjusted
  n=85
- **Chi-Square Tests** (`R/modules/mod_chisq.R`) -- goodness of fit and test
  of independence/association for an R x C table (dynamic 2-5 x 2-5
  proportion-matrix UI), both wrapping `pwr::pwr.chisq.test()` +
  `pwr::ES.w1()`/`ES.w2()` (Cohen 1988); the independence design also serves
  as the Proportions module's "3+ group proportions" entry in the Home
  finder; plus McNemar's test for paired/matched proportions (the same
  subjects measured twice), wrapping `TrialSize::McNemar.Test()` (Chow,
  Shao & Wang 2003) -- `TrialSize` already a zero-dependency project
  dependency; and a Mantel-Haenszel design for comparing two proportions
  across J confounding strata (age bands, severity categories,
  propensity-score strata), wrapping `TrialSize::Propensity.Score.strata()`
  (the weighted Mantel-Haenszel test) alongside
  `TrialSize::Propensity.Score.nostrata()` (the naive pooled comparison,
  shown side by side to illustrate the cost of ignoring confounding
  strata) -- verified exactly against Chow, Shao & Wang (2003) Example
  15.2.3 (stratified n=447 vs. pooled n=1151); plus a Cochran-Armitage
  trend test for dose-response proportions across ordered groups, wrapping
  `TrialSize::Cochran.Armitage.Trend()` -- verified exactly against Chow,
  Shao & Wang (2003) Example 11.5 (n=8/group, 32 total). Note: the closely
  related `TrialSize::Dose.Response.binary()` was found broken in an
  earlier batch -- this is a different, independently verified function
  from the same package; plus Cochran's Q test for k >= 3 paired binary
  measurements (`calc_cochran_q()`), generalizing McNemar's test beyond
  two conditions. No installed package provides a sample-size/power
  FORMULA for Cochran's Q specifically (only analysis functions exist --
  `rstatix`, already an installed dependency, has `cochran_qtest()`;
  `TrialSize::Stuart.Maxwell.Test()`, investigated for this item's
  neighborhood in an earlier batch, was found genuinely broken).
  Rather than fabricate a closed-form approximation, this directly
  simulates the actual test -- `rstatix::cochran_qtest()` itself, run on
  correlated binary data from a random-intercept logistic model (the
  standard way to simulate correlated binary repeated measures) -- the
  same "simulate the real test" approach already used for the KS,
  Wald-Wolfowitz runs, and weighted log-rank designs. Verified directly
  by Rscript: p=(0.2,0.3,0.4,0.5) across k=4 conditions,
  sigma2_subject=1, alpha=0.05, target power=0.8 -> n=57, simulated
  achieved power 0.829; required n increases monotonically with target
  power (n=41 at power=0.7, n=72 at power=0.9)
- **Pilot / Feasibility** (`R/modules/mod_pilot.R`) -- the flat 12/arm
  rule-of-thumb (Julious 2005) plus an interactive tool showing how precise
  a pilot's estimated SD is at a given n (95% CI multipliers on the observed
  SD), from chi-square CI-for-variance theory; no formal power calculation
  since pilots aren't powered studies
- **Simon Two-Stage** (`R/modules/mod_simon.R`) -- Phase II single-arm
  designs, wrapping `clinfun::ph2simon()` (Simon 1989), reporting both the
  minimax (smallest maximum n) and optimal (smallest expected n under the
  null) designs
- **Equivalence (TOST)** (`R/modules/mod_tost.R`) -- two one-sided tests, for
  a mean difference on the raw/untransformed scale (wraps
  `PowerTOST::sampleN.TOST(logscale = FALSE, design = "parallel")`; Phillips
  1990; Diletti, Hauschke & Steinijans 1991), for two proportions (wraps
  `epiR::epi.ssequb(type = "equivalence")` -- no lightweight package with a
  dedicated proportions-TOST function was found), or for a pharmacokinetic
  bioequivalence crossover on the log-ratio scale -- classical 2x2, or the
  2x2x4 full-replicate/2x3x3 partial-replicate designs used for RSABE/ABEL
  approaches (wraps `PowerTOST::sampleN.TOST(logscale = TRUE)`, same
  package/citations, verified exactly against its own documented example:
  CV=30%, theta0=0.95, 80-125% limits -> n=40 for 2x2, n=20 for 2x2x4, n=30
  for 2x3x3); plus a bioequivalence crossover design based on EXPECTED
  power (assurance / probability of trial success) rather than a
  fixed/known CV, wrapping `PowerTOST::expsampleN.TOST(prior.type = "CV")`
  -- averages over the sampling uncertainty in the CV estimate itself,
  given how many subjects the prior/pilot study that produced it had;
  verified exactly against the package's own documented example (CV=30%
  from a prior study with m=30 subjects, same 80-125% limits and
  theta0=0.95 -> n=42, achieved expected power=0.8063, versus n=40 for
  the fixed-CV design on the identical inputs)
- **Log-Rank / Survival** (`R/modules/mod_logrank.R`) -- two-arm
  time-to-event studies (required N from event probabilities), wrapping
  `powerSurvEpi::ssizeCT()` (Freedman 1982; Rosner 2006); Cox
  proportional-hazards regression for a binary or continuous covariate of
  interest (optionally adjusting for a correlated covariate), wrapping
  `powerSurvEpi::ssizeEpi()`/`ssizeEpiCont()` (Latouche et al. 2004;
  Hsieh & Lavori 2000); and a stratified log-rank test under exponential
  survival (per-stratum allocation, event rates under the null, and a
  common hazard ratio), wrapping `powerSurvEpi::ssize.stratify()` (Palta
  & Amini 1985); and a log-rank design with a non-uniform accrual period,
  minimum follow-up time, and noncompliance (control-arm drop-ins and
  intervention-arm non-adherers), wrapping `Hmisc::cpower()` (Peterson &
  George 1993; Lachin & Foulkes 1986; Schoenfeld 1983) -- verified by
  reproducing the package's own documented example exactly (18% control
  mortality, 15% reduction, 1.5-year accrual, 5-year minimum follow-up,
  15% drop-in/25% non-adherence, 80% power -> n=14,634 total, matching
  the package's own `uniroot()` search to within rounding); and a
  weighted log-rank design for NON-proportional hazards (`calc_weighted_
  logrank()`) -- the checklist's named package, `npsurvSS`, isn't
  installable from CRAN in this sandbox, and its own source (read from
  its public GitHub CRAN mirror) implements an 11-file numerical-
  integration engine judged too large to safely reimplement, so this
  instead directly simulates the actual Fleming-Harrington G^rho
  weighted log-rank test (Harrington & Fleming 1982) via the already-
  installed `survival::survdiff(rho=...)`, under a DELAYED or an
  EARLY/FADING non-PH effect shape. Verified by reproducing the well-
  documented, opposite-direction behavior of this test family: with
  hazard0=0.15, hr=0.5, change_time=4, accrual=12, tot_time=30, 80%
  power -- for a DELAYED effect, rho=0 (ordinary log-rank) needs n=280
  total vs. rho=1's n=1,080 (nearly 4x more, since rho=1 wastes weight
  on the early no-difference period); for the mirror-image EARLY/FADING
  effect, the ranking flips: rho=0 needs n=510 vs. rho=1's n=266 (fewer
  than half) -- both directions matching textbook predictions exactly
- **Incidence Rate** (`R/modules/mod_rate.R`) -- precision-based estimation
  of an incidence rate (number of events, then person-time, wrapping
  `presize::prec_rate()`), plus comparison of two rates via person-time
  (closed-form Demidenko 2007 Poisson-regression formula, reproducing
  WebPower's `wp.poisson()` exactly without that package's heavy
  dependency chain); plus Poisson regression with a continuous predictor
  (e.g. a biomarker level rather than an exposed/unexposed group),
  wrapping `powerMediation::sizePoisson()` (Signorini 1991) -- already a
  project dependency (used by the Logistic Regression module); verified
  exactly against the package's own documented example: beta0=0.1,
  beta1=0.5, predictor mean=0/variance=1, mean exposure time=1, no
  over-dispersion, alpha=0.05, power=0.80 -> n=28; plus comparison of two
  NEGATIVE BINOMIAL rates (`calc_negative_binomial_rates()`) -- a
  genuinely different model than Poisson regression's linear-in-mean
  `phi` over-dispersion adjustment above: negative binomial has a
  quadratic mean-variance relationship (Var(Y) = mu + mu^2/theta), the
  standard model when over-dispersion grows with the mean (e.g.
  recurrent-event counts like hospitalizations or exacerbations).
  `MKpower` (the package providing this method, `power.nb.test()`)
  isn't installable from CRAN in this sandbox, so its source -- a
  single, self-contained closed-form function (Zhu & Lakkis 2014) --
  was read directly from its public GitHub CRAN mirror and transcribed.
  Verified exactly against the package's own documented example
  (mu0=10, RR=1.5, theta=1/5, duration=1, ssize_ratio=1.5, approach=3,
  power=0.8 -> n0=405/n1=607, matching the package's own n0=404.2/
  n1=606.3 to within rounding), then independently confirmed two ways
  by Monte Carlo: reproducing the paper's own test statistic on
  simulated `MASS::rnegbin()` data gives empirical power 0.814, and a
  genuinely different check -- fitting `MASS::glm.nb()` (which
  ESTIMATES the dispersion from data, unlike the design formula) and
  using its own Wald test -- gives empirical power 0.797, both closely
  bracketing the formula's 0.8 target
- **Ratio Estimation** (`R/modules/mod_ratio.R`) -- precision-based
  estimation of a risk ratio, odds ratio, or rate ratio (a target
  confidence-interval width rather than a power target), wrapping
  `presize::prec_riskratio()` (Koopman 1984; Katz et al. 1978),
  `presize::prec_or()` (Gart & Zweifel 1967; Woolf 1955), and
  `presize::prec_rateratio()` (Rothman & Greenland 2018)
- **Multiple Regression** (`R/modules/mod_regression.R`) -- R-squared
  deviation from zero for a multiple linear regression model, wrapping
  `pwr::pwr.f2.test()` (Cohen 1988); plus R-squared increase (hierarchical
  regression), testing whether adding a set of new predictors to an
  existing model significantly raises R-squared, same `pwr::pwr.f2.test()`
  backend with Cohen (1988) section 9.7's effect-size/df mapping (verified:
  R-squared 0.30 -> 0.40 adding 2 of 5 total predictors, alpha=0.05,
  power=0.80 -> n=64)
- **Non-Inferiority** (`R/modules/mod_noninferiority.R`) -- means or
  proportions, wrapping `epiR::epi.ssninfc()` / `epi.ssninfb()` (Chow, Shao
  & Wang 2008); plus odds ratio and hazard ratio (Cox PH), wrapping
  `TrialSize::RelativeRisk.NIS()` / `Cox.NIS()` (Chow, Shao & Wang 2003)
  -- despite its name, `RelativeRisk.NIS()`'s formula (confirmed from its
  source, shared with its `RelativeRisk.Equality()` sibling) is built on
  the log odds ratio, not the relative risk, so this app labels the
  design by what it actually computes
- **Group Sequential Design** (`R/modules/mod_group_sequential.R`) --
  interim-monitoring trial designs (continuous, binary, or time-to-event
  outcome) with planned interim analyses and a Pocock-to-O'Brien-Fleming
  efficacy/futility boundary family, wrapping
  `clinfun::gsdesign.normal()`/`.binomial()`/`.survival()` --
  `clinfun` already a project dependency (used for Simon Two-Stage);
  avoids `gsDesign`/`rpact`, both unavailable in this sandbox. Verified:
  the single-look (fixed-design) special case reproduces the classic
  Schoenfeld (1983) log-rank event formula exactly (66 events for
  HR=0.5, alpha=0.05, 80% power) and the exact Z_(1-alpha/2)+Z_(1-beta)
  drift statistic for all three outcome types. Note: the underlying
  package functions use internal Monte-Carlo integration that varies
  slightly run-to-run without a fixed seed -- this module's calc layer
  fixes one internally so results are exactly reproducible
- **Rule of Three** (`R/modules/mod_rule_of_three.R`) -- the upper bound on
  an unseen adverse-event rate given zero events observed, or the sample
  size needed to have a good chance of observing at least one event of an
  assumed rate; closed-form (Hanley & Lippman-Hand 1983); plus a more
  realistic "prove disease/defect freedom" design for a known finite
  population and an imperfect test (single test, or two combined in
  series/parallel), wrapping `epiR::epi.ssdetect()` -- verified against
  the package's own worked examples (n=65, n=15) and, for the two-test
  case, against independently hand-derived series/parallel test-
  combination formulas (n=44 series, n=38 parallel)
- **Exact Tests** (`R/modules/mod_exact_tests.R`) -- the binomial test
  (single proportion) and Fisher's exact test (two independent
  proportions), both more accurate than the normal-approximation designs
  elsewhere in this app for small samples. Both search upward over n
  (via `stats::binom.test()` and `Exact::power.exact.test()` respectively)
  rather than solving a closed-form equation, since exact-test power is
  genuinely non-monotonic in n (Chernick & Liu 2002) -- a stability check
  guards against recommending a fragile single-n spike; plus Boschloo's
  exact test (the classic *unconditional* exact test for two proportions,
  uniformly at least as powerful as Fisher's exact -- verified directly:
  n1=44 vs. Fisher's n1=48 for identical inputs), wrapping the same
  `Exact::power.exact.test()` with `method = "boschloo"` (noticeably
  slower to compute than Fisher's exact, since it searches a
  nuisance-parameter grid internally); plus the exact Poisson test
  (single rate vs. a reference/standard rate), searching person-time via
  `stats::poisson.test()`, the count-data analog of the binomial-test
  design above; plus the sign test (paired data / one-sample median), a
  thin wrapper around the binomial-test design with the reference
  proportion fixed at 0.5 (the sign test IS an exact binomial test
  against 0.5), so no new math or dependency
- **Prediction Model** (`R/modules/mod_prediction.R`) -- minimum sample
  size for developing a binary, continuous, or time-to-event prediction/
  prognostic model, wrapping `pmsampsize::pmsampsize()` (Riley et al. 2019
  Stat Med Parts I & II; Riley et al. 2020 BMJ 368:m441); the binary design
  additionally accepts either a Cox-Snell R² or a reported C-statistic
  (converted via Riley et al. 2021 Stat Med 40:859-864's seeded simulation);
  plus an "External validation (binary outcome)" design for sizing a study
  that externally validates an *already-developed* model (Riley et al. 2021
  Stat Med 40:4230-4251) -- `pmvalsampsize` is not installed in this
  environment and CRAN is unreachable, so its `pmvalsampsize_bin.R` source
  was read from its public GitHub CRAN mirror and directly transcribed for
  the "normal" and "beta" linear-predictor-distribution options (O/E ratio,
  calibration slope, C-statistic, and an optional standardised net benefit
  criterion -- required n is the largest of whichever are requested);
  verified against the package's own two worked examples exactly (n=4,563
  and n=4,252) and independently against actual `glm()`-fitted calibration
  SEs and `pROC::ci.auc()` CI widths on simulated data
- **ROC / AUC** (`R/modules/mod_roc.R`) -- sample size for a single ROC
  curve's AUC against the chance diagonal (0.5), wrapping
  `pROC::power.roc.test()` (Obuchowski, Lieber & Wians 2004); plus a
  "Compare two correlated (paired) AUCs" design, `calc_compare_two_aucs()`,
  wrapping the same function's list/binormal-parameter method (Obuchowski
  & McClish 1997) -- each curve described by its own binormal A/B shape
  parameters, with separate case/control correlations between the two
  tests; verified by literally reproducing Obuchowski & McClish (1997)'s
  own Example 2 (also pROC's own documentation example): A1=2.6, B1=1,
  A2=1.9, B2=1, rn=ra=0.6, delta=0.037, partial AUC restricted to FPR in
  [0,0.2] -> raw ncases=ncontrols=107.02, matching the package's own
  computation (this app's always-round-up convention gives 108/108/216;
  the package's own doc illustrates with the nearest whole number, 107).
  The unpaired-AUCs case is not implemented -- `power.roc.test()` itself
  doesn't support it ("Power calculation for unpaired ROC curves is not
  implemented", per the package's own documentation)
- **Cluster / Design Effect** (`R/modules/mod_cluster.R`) -- inflates an
  already-computed simple-random-sample size for cluster/multistage
  sampling (villages, schools, health facilities), closed-form DEFF = 1 +
  (m-1)*rho (Kish 1965), no package needed; plus a cluster survey
  precision design (WHO EPI-style) that solves the full two-stage design
  -- number of clusters (PSUs) and total individuals (SSUs) -- in one
  step for a target proportion precision, wrapping
  `epiR::epi.ssclus2estb()` -- verified against Levy & Lemeshow (1999)'s
  own worked example (67 clusters, rising to 81 with variable cluster
  size, or falling to 60 with a finite population of 220 clusters).
  Note: `epiR::epi.ssclus1estb()` ("one-stage") is, on inspection of its
  source, byte-for-byte identical to `epi.ssclus2estb()` ("two-stage"),
  so this one design covers both cases
- **Stratified Sampling** (`R/modules/mod_stratified.R`) -- total sample
  size and per-stratum allocation (proportional or optimal/Neyman) for a
  population divided into strata, closed-form (Cochran 1977; Kauermann &
  Kuechenhoff 2011) rather than a runtime dependency on `samplingbook`,
  whose `Depends: pps, sampling, survey` chain is far heavier than this
  one formula needs -- verified to reproduce that package's own
  documented examples exactly
- **LQAS** (`R/modules/mod_lqas.R`) -- Lot Quality Assurance Sampling:
  classifies a small area/program "lot" as high- or low-performing
  against two coverage thresholds, rather than estimating a proportion
  precisely, `calc_lqas()`, closed-form (no package needed -- a direct
  binomial operating-characteristic search over sample size n and
  decision threshold d using base R's `pbinom()`) per Robertson & Valadez
  (2006); verified against a real published worked example located via
  web search -- the widely-used LQAS "n=19" rule for a 50%/80% coverage
  threshold pair -- this calculator recovers exactly n=19, d=13 at
  alpha=beta=0.10, matching the published rule's own reported
  classification-error figures (alpha~6.8%, beta~8.4%, total ~15%),
  independently cross-checked against a second, mirror-image published
  example by binomial symmetry
- **Resource Equation (Animal Studies)** (`R/modules/mod_resource_equation.R`)
  -- sizes small, exploratory animal studies with no prior effect-size
  estimate to power against, via Mead's error-degrees-of-freedom rule of
  thumb (E = N - T, target E between 10 and 20), `calc_resource_equation_size()`
  (recommend a sample size) / `calc_resource_equation_check()` (check the
  adequacy of a chosen one); pure arithmetic, no package needed; verified
  against Charan & Kantharia (2013)'s own worked example located via web
  search -- 5 groups of 10 rats each (N=50) -> E=45, "more than needed"
- **Subgroup / Interaction Testing** (`R/modules/mod_subgroup_interaction.R`)
  -- inflates an already-computed main-effect sample size to the size
  needed to reliably detect a treatment-by-subgroup interaction (the
  "4x rule"), `calc_subgroup_interaction()`, pure arithmetic
  (4/effect_ratio^2) -- no package needed or exists for this general,
  test-agnostic multiplier; verified against Brookes et al. (2004)'s own
  two headline findings located via web search -- a same-magnitude
  interaction needs exactly 4x the main-effect n (100 -> 400); a
  half-magnitude interaction needs exactly 16x (100 -> 1,600) -- both
  additionally re-derived independently from first-principles z-based
  power formulas rather than only trusting the paper's summary numbers
- **Qualitative Sample Size Guidance** (`R/modules/mod_qualitative.R`)
  -- unlike every other module in this app, this one has NO formula and
  computes NO number, per this checklist section's own explicit framing
  ("non-formula -- acknowledge, don't fake precision"; "present as
  guidance panel, no numeric output"). Presents the field's own three
  established frameworks as reference content instead: saturation-based
  guidance (Guest, Bunce & Johnson 2006, including their own quoted
  finding -- "saturation occurred within the first twelve interviews...
  present as early as six interviews" -- with the caveat that it's
  specific to their homogeneous study population); information power
  (Malterud, Siersma & Guassora 2016's five dimensions -- study aim,
  sample specificity, use of established theory, quality of dialogue,
  analysis strategy); and purposive/theoretical sampling (Patton
  2002/2015's purposeful-sampling typology; Glaser & Strauss 1967's
  founding grounded-theory theoretical-sampling method). No calc_*.R
  file or numeric worked example exists for this module -- its tests
  instead verify the content itself (every topic present, citations and
  the Guest et al. quote reproduced accurately)
- **Crossover Trial (2x2)** (`R/modules/mod_crossover.R`) -- a 2x2
  crossover trial's sample size for a continuous outcome, testing for a
  difference (not equivalence -- see the Equivalence (TOST) module for
  that), wrapping `TrialSize::TwoSampleCrossOver.Equality()` (Chow, Shao
  & Wang 2003); `TrialSize` has zero package dependencies
- **Factorial ANOVA / ANCOVA** (`R/modules/mod_anova_general.R`) -- a
  general linear-model F-test for a factorial ANOVA main effect or
  interaction, or an ANCOVA group effect, wrapping `pwr::pwr.f2.test()`
  (Cohen 1988) -- the same engine already used by the Multiple Regression
  module, since Cohen treats ANOVA/ANCOVA and regression as one unified
  "F tests" family; effect size accepted as either Cohen's f-squared or
  partial eta-squared
- **Logistic Regression** (`R/modules/mod_logistic.R`) -- simple logistic
  regression with a binary or continuous predictor, wrapping
  `powerMediation::SSizeLogisticBin()`/`SSizeLogisticCon()` (Hsieh, Bloch
  & Larsen 1998) rather than `WebPower::wp.logistic`; `powerMediation`
  has zero package dependencies; plus ordinal (proportional odds)
  regression comparing two groups on an outcome with 3+ ordered
  categories, wrapping `Hmisc::posamsize()` (Whitehead 1993) -- verified
  exactly against Hmisc's own documented example (a back-pain severity
  study, 4 categories, p=(0.1,0.2,0.4,0.3), odds ratio=1.2, equal
  allocation, alpha=0.05, power=0.80 -> n=3149, efficiency 0.90 relative
  to a continuous response; cross-checked via `Hmisc::popower()` at
  n=3148, reproducing power=0.80 exactly); plus two covariate-adjusted
  (multiple regression) designs for the binary- and continuous-predictor
  cases, applying Hsieh, Bloch & Larsen (1998)'s own 1/(1-R²) variance
  inflation factor directly to the simple-model sample size above (R² =
  the predictor of interest's squared multiple correlation with the
  model's other covariates) -- at R²=0 both reduce exactly to the simple
  case (n=1281 binary, n=317 continuous); at R²=0.5 the binary design's n
  exactly doubles
- **Self-Controlled Case Series** (`R/modules/mod_sccs.R`) -- sample size
  for an SCCS study of a transient exposure's association with an event,
  with an optional age-effect stratification (Musonda, Farrington &
  Whitaker 2006); closed-form reimplementation of `SCCS::samplesize()`'s
  algorithm rather than a runtime dependency on `SCCS`, whose
  `Imports: survival, splines, corpcor, fda, R.methodsS3, gnm` chain is
  far heavier than this one formula needs -- verified to reproduce all
  three of that package's documented examples exactly
- **RM-ANOVA / Mixed ANOVA** (`R/modules/mod_rm_anova.R`) -- sample size
  for a between-subjects group effect, a within-subjects (repeated-
  measures) effect, or their interaction (the classic mixed/split-plot
  ANOVA test), closed-form reimplementation of
  `WebPower::wp.rmanova()`'s noncentral-F algorithm (Cohen 1988) rather
  than a runtime dependency on `WebPower`, whose `MASS`/`lme4`/`lavaan`/
  `PearsonDS` dependencies are far heavier than this one function needs
  and which that function itself never calls into; the between-effect
  design reproduces the package's own documented example exactly
- **Nonparametric Tests** (`R/modules/mod_nonparametric.R`) -- Wilcoxon
  rank-sum (Mann-Whitney U, two independent groups), Wilcoxon
  signed-rank (one sample / paired differences), and Kendall's tau
  (nonparametric association), all wrapping `TrialSize::Nonpara.Two.Sample()`/
  `Nonpara.One.Sample()`/`Nonpara.Independ()` (Chow, Shao & Wang 2003) --
  genuine distribution-free closed forms using rank/concordance
  probabilities directly, not an ARE-inflation shortcut on top of a
  parametric calculation; `TrialSize` already a zero-dependency project
  dependency; plus the Kruskal-Wallis test (k >= 3 independent groups) --
  no installed package has a k-sample rank-test closed form, so this one
  design *does* use the ARE-inflation shortcut the checklist itself names
  for this item: solves the equivalent one-way ANOVA n via
  `pwr::pwr.anova.test()`, then inflates by the classical 3/pi asymptotic
  relative efficiency (Hodges & Lehmann 1956); verified against the real
  `kruskal.test()` by simulation (k=3, f=0.25 -> ANOVA n=53/group, KW
  n=56/group, empirical power 0.812 vs. only 0.787 unadjusted); plus the
  Jonckheere-Terpstra test (monotonic trend across ordered groups) --
  `clinfun::jonckheere.test()` (already used for Simon two-stage) turns
  out to provide no sample-size function at all, but its own
  documentation states its asymptotic version is exactly equivalent to
  Kendall's tau between the outcome and an ordinal group score (Terpstra
  1952; Jonckheere 1954), so this is a thin wrapper around the Kendall's
  tau design above -- reproduces its Chow, Shao & Wang (2003) Example
  14.4 answer bit-for-bit (n=135); and the Friedman test (k >= 3 related/
  repeated measurements on the SAME subjects) -- following the same
  "RM-ANOVA basis" ARE-inflation approach as Kruskal-Wallis above but with
  a k-dependent correction: solves the equivalent one-group within-subjects
  RM-ANOVA n via this app's own `calc_rm_anova()`, then inflates by
  (3/pi) x k/(k+1) (Zimmerman & Zumbo 1993) rather than the plain 3/pi
  constant, which only holds in the k -> infinity limit; verified by
  simulation searching for the n at which the real `stats::friedman.test()`
  and a from-scratch RM-ANOVA F-test each cross 80% empirical power on
  identical simulated data (k=4) -- ratio n_Friedman/n_RM-ANOVA ~1.30,
  closely matching the formula's predicted 1/ARE = pi/3 x 5/4 = 1.309;
  plus the two-sample Kolmogorov-Smirnov test -- unlike every other
  design in this module, no closed-form power formula exists against a
  general alternative (KS power depends on the full shape of the
  distributional difference, not one effect-size number), so this design
  does exactly what this app's own checklist prescribes for it: direct
  Monte Carlo simulation of the actual `stats::ks.test()`, under a
  standardized-mean-shift Normal alternative comparable to Cohen's d,
  found via exponential search then bisection over candidate n. A fixed
  internal seed makes repeated calls with identical inputs reproducible.
  Verified: effect_size=0.5 (medium shift), alpha=0.05, 80% power,
  nsim=500 -> n=91/group, simulated achieved power 0.797 -- versus the
  equivalent two-sample t-test's n=64/group, the expected efficiency loss
  since KS is a general-purpose omnibus test, not tuned to a location
  shift specifically; plus the two-sample Wald-Wolfowitz runs test --
  another omnibus distribution-free test with no closed-form power
  formula, built the same way: direct Monte Carlo simulation of
  `tseries::runs.test()` (newly added dependency, already installed) on
  the pooled-and-sorted group-label sequence, reusing the identical
  exponential-search-then-bisection engine (factored out as a shared
  `.mc_search_n1()` helper in `calc_utils.R`). Verified: effect_size=0.8
  (large shift), alpha=0.05, 80% power, nsim=500 -> n=216/group,
  simulated achieved power 0.817 -- far more than the equivalent KS
  design's n=37/group at the same effect size, correctly reflecting that
  the runs test discards each observation's magnitude and uses only its
  rank position, a comparatively weak omnibus test against a plain
  location shift
- **Variance Tests** (`R/modules/mod_variance.R`) -- a single-variance test
  against a reference SD, and a two-variance test comparing two groups,
  both closed-form (chi-squared/F distribution respectively, solved via
  `uniroot()`, no package needed). `TrialSize::ISV.Equality()` and
  `ISCV.Equality()` were investigated as possible backends first and
  found to be broken in the installed package -- `ISV.Equality()`'s loop
  computes a ratio but never uses it, silently returning `NULL`, and
  `ISCV.Equality()` has a literal missing multiplication operator in its
  source and throws a runtime error on any input -- so this app
  reimplements the standard formulas directly instead, each verified by
  20,000-replicate Monte Carlo simulation since no citable printed
  worked example was available (single-variance: sigma0=10, sigma1=14,
  one-sided greater -> n=28, empirical power 0.814; two-variance:
  sigma1=10, sigma2=14, two-sided -> n=72/group, empirical power 0.804)
- **Multiplicity Adjustment** (`R/modules/mod_multiplicity.R`) -- the
  first module in this app that is explicitly a generic wrapper rather
  than its own dedicated test: given a family-wise alpha and m planned
  simultaneous comparisons, computes the Bonferroni (alpha/m, always
  valid) or Sidak (1-(1-alpha)^(1/m), exact under independence) adjusted
  per-comparison alpha, then plugs it straight into this app's own
  already-verified one-proportion/two-proportion/one-mean/two-mean
  formulas -- literally "wrap any calculator with alpha/m", no new
  formula or verification risk beyond the correction algebra itself.
  Verified: m=1 reduces exactly to the un-adjusted base calculator's own
  n; worked example (two independent proportions, p1=0.50 vs p2=0.65,
  m=4, alpha=0.05, power=0.80) -> Bonferroni n=241/group (482 total) vs.
  n=170/group (340 total) unadjusted, Sidak n=240/group. Holm's
  step-down correction is not offered as a third method since its
  threshold is data-dependent (no single a priori alpha to plan against);
  plus a fifth design controlling the FALSE DISCOVERY RATE instead of the
  family-wise error rate -- `calc_multiplicity_fdr_means()`, for two
  independent means, given m total tests and an assumed proportion pi1
  truly non-null. The checklist's own named package, `ssize.fdr`, is not
  installed and CRAN is unreachable from this sandbox, so the closed form
  (alpha* = fdr_level x m1 x power / (m0 x (1-fdr_level)), from the
  expected-FDR self-consistency equation FDR = E[false rejections] /
  E[total rejections]) was independently derived from the standard
  Benjamini & Hochberg (1995) FDR definition, then independently verified
  twice by directly simulating the ACTUAL Benjamini-Hochberg procedure
  (`stats::p.adjust(method="BH")` on simulated two-sample t-test p-values
  from a mix of true nulls and true non-nulls) at the resulting n: m=1000,
  pi1=0.1 (m1=100), d=2, fdr_level=0.1, target average power=0.8 -> n=8/
  group, 500-replicate simulation gives empirical average FDR 0.082
  (target 0.1) and empirical average power 0.794 (target 0.8); m=500,
  pi1=0.1 (m1=50), d=1, fdr_level=0.05, target average power=0.9 ->
  n=36/group, 400-replicate simulation gives empirical average FDR 0.045
  (target 0.05) and empirical average power 0.904 (target 0.9)
- **MANOVA / Hotelling's T²** (`R/modules/mod_manova.R`) -- the two-group
  special case of MANOVA: comparing two independent groups on p >= 1
  continuous outcome variables JOINTLY via Hotelling's T-squared test.
  No installed package provides a Hotelling's T² sample-size function, so
  `calc_manova_hotelling()` reimplements the standard noncentral-F
  approach directly (Rencher 2002; the general Vonesh & Schork 1986
  framework), converting the squared Mahalanobis distance D² between the
  two group mean vectors into a noncentral F(p, 2n-p-1) test -- the same
  noncentral-F machinery this app's other F-test modules already use.
  Verified two ways: at p=1 this formula reduces EXACTLY to the ordinary
  two-sample t-test (D²=Cohen's d²; d=0.5, alpha=0.05, power=0.80 -> n=64,
  bit-for-bit identical to `pwr::pwr.t.test()`); for a genuine
  multivariate case (p=3 correlated outcomes, D²=0.1243, alpha=0.05,
  power=0.80 -> n=178/group), a 5,000-replicate Monte Carlo simulation
  computing the actual two-sample Hotelling's T² statistic on simulated
  trivariate normal data gives empirical power 0.8068, closely matching
  the 0.80 target. Global (k>2 group) MANOVA and special-effects
  contrasts are not covered
- **Bayesian Design Analysis** (`R/modules/mod_bayesian.R`, formerly
  "Bayesian Assurance" -- renamed when a second, genuinely different
  Bayesian method was added) -- sample size for a target *assurance*
  (prior-averaged power) in a two-arm proportions trial on the log odds
  ratio scale, when the true treatment effect is itself uncertain rather
  than fixed at one assumed value. Places a Normal or Uniform prior on
  the log odds ratio and reports the probability, averaged over that
  prior, that the trial's confidence interval will exclude a
  minimally-worthwhile effect (Spiegelhalter & Freedman 1986).
  `calc_bayesian_assurance_or()` wraps `Hmisc::gbayes2()` (already a
  project dependency; no new package needed) rather than reimplementing
  its numerical-integration engine. Verified by reproducing the package's
  own documented examples exactly: a Uniform(log(1.2), log(1.3)) prior,
  p1=p2=0.3, equal allocation, alpha=0.05, target assurance=0.90 ->
  n=2,120/arm, matching the package's own `uniroot()` example to within
  rounding; and its 50:50 Gaussian-mixture-prior example reproduces the
  package's own printed assurance value of 0.6133338 exactly; plus a
  second, genuinely different design -- Bayes Factor Design Analysis
  (BFDA) for two-sample means, `calc_bfda_ttest()`. Ordinary power
  analysis asks what sample size gives X% probability of a significant
  p-value; BFDA (Schönbrodt & Wagenmakers 2018) asks what sample size
  gives X% probability that the actual Bayes factor (BF10, the JZS
  default Bayesian t-test of Rouder et al. 2009, via
  `BayesFactor::ttestBF()`) exceeds a chosen evidence threshold (e.g.
  BF10 > 10, "strong evidence"). BFDA has no closed form by design -- the
  method itself IS direct simulation -- so this reuses the same
  exponential-search-then-bisection engine (`.mc_search_n1()`) as the
  Nonparametric Tests module's KS/runs-test designs, but warm-started
  from the classical two-sample t-test n (`pwr::pwr.t.test()`) since
  `ttestBF()` is far slower per call (~7ms) than `ks.test()`/`runs.test()`
  (~0.3ms). Verified: Cohen's d=0.5, BF10 threshold=10, target
  probability=0.8, nsim=100 -> n=129/group, versus the classical test's
  n=64/group -- BFDA needing roughly double the classical n to reach a
  stringent evidence threshold matches the direction reported in the
  original paper's own simulations. Independently confirmed by a
  separate, larger (400-replicate) simulation: P(BF10>10)=0.835 at n=129
  (matching the 0.80 target) vs. only 0.75 at n=110, confirming n=129 is
  a genuine crossing point rather than search noise
- **Competing Risks** (`R/modules/mod_competing_risks.R`) -- joint test of
  a cause-specific hazard and the any-cause hazard in the presence of
  competing risks (the setting Gray's test addresses). No installed
  package covers this and CRAN is unreachable from this sandbox, so
  rather than fabricate a formula, `powerCompRisk::powerCompRisk()`'s
  actual algorithm was read directly from the package's own public source
  on its read-only GitHub CRAN mirror
  (`https://raw.githubusercontent.com/cran/powerCompRisk/master/R/powerCompRisk.R`)
  -- the underlying published method (Yang, Fung & Li, "Sample size
  determination for jointly testing a cause-specific hazard and the
  any-cause hazard in the presence of competing risks," UCLA
  Biostatistics Technical Report, 2017) does not change across package
  versions, so a genuine archived/mirrored copy of the source is as valid
  a "real" source as an installed package. `calc_competing_risks_joint()`
  reimplements it as closed-form root-finding (`uniroot()` +
  `mvtnorm::pmvnorm()` for the bivariate-normal joint test statistic),
  computing all three of the package's reported designs -- chi-square
  joint test, maximum joint test, and Bonferroni joint test. Verified by
  reproducing the fetched source's own documented worked example exactly:
  lambda_11=0.3, HR_1=1.44, HR_all=1.33, RR=0.8, accrual=1, follow_up=8,
  attrition=0.1, a1=0.5, alpha=0.05, power=0.8 -> chi-square joint test:
  290 events/436 total; maximum joint test: 252 events/378 total;
  Bonferroni joint test: 288 events/430 total -- matching the package's
  own printed output exactly
- **RMST Comparison** (`R/modules/mod_rmst.R`) -- sample size for a
  two-arm comparison of restricted mean survival time (RMST), a
  model-free, directly interpretable alternative to the hazard ratio
  that doesn't require the proportional-hazards assumption (superiority,
  margin=0, or non-inferiority, margin>0, per Uno et al. 2014, 2015).
  Neither `SSRMST` (the checklist's named package) nor its own internal
  dependency `survRM2` are installable from CRAN in this sandbox, so
  both packages' actual source was read directly from their public
  GitHub CRAN mirrors -- `SSRMST::ssrmst()` and `survRM2::rmst2()`. This
  confirmed `rmst2()`'s "unadjusted" RMST-difference test reduces
  exactly to summing each arm's own Kaplan-Meier-area RMST variance
  (the same one-arm estimator `SSRMST` already carries internally,
  credited there to survRM2), so `calc_rmst_comparison()` fully
  reimplements both packages' method using only `survival::survfit()`
  -- no new package dependency. The method itself IS Monte Carlo by
  design (there's no closed form for the RMST-difference confidence
  interval under staggered accrual and administrative censoring), so
  this reuses the same exponential-search-then-bisection engine
  (`.mc_search_n1()`) as the Nonparametric Tests and Bayesian Design
  Analysis modules' simulation-based designs, reporting both of the
  method's variance estimators (separate and pooled). Verified by
  reproducing `SSRMST`'s own documented example scenarios (ac_period=35,
  tot_time=510, tau=500): a non-inferiority test with identical arms
  (scale0=scale1=8500, margin=18, target power=0.8) needs n=206/arm,
  achieving simulated power 0.780; a superiority test with a large true
  effect (scale0=4000, scale1=8500, target power=0.8) needs n=432/arm,
  achieving simulated power 0.823; and required n increases
  monotonically with target power (n_total=680 at power=0.7, 950 at
  power=0.9)
- **Longitudinal / MMRM** (`R/modules/mod_longitudinal.R`, renamed from
  "Longitudinal Slope Difference" now that it covers a second method) --
  sample size for detecting a difference in linear SLOPE (rate of
  change) between two groups measured repeatedly at the same visit
  times, under a random-intercept + random-slope + residual-error
  covariance structure (the standard linear mixed model for
  longitudinal data). `longpower` (the checklist's named package for
  GEE-based longitudinal tests) isn't installable from CRAN in this
  sandbox, so `liu.liang.linear.power()`'s source -- a single, self-
  contained function with no cross-file dependencies -- was read
  directly from its public GitHub CRAN mirror and reimplemented. Liu &
  Liang (1997)'s general GLS/GEE-style method accepts arbitrary
  covariate matrices, too general for a simple form UI, so
  `calc_longitudinal_slope_diff()` wraps its single most common real-
  world use (the two-group slope-difference case). Verified by
  reproducing the function's own documented Alzheimer's-disease
  vignette example exactly: 7 visits (0 to 1.5 years, step 0.25), slope
  difference=1.5, random-intercept variance=55, random-slope
  variance=24, intercept-slope correlation=0.8, residual variance=10,
  alpha=0.05, target power=0.80 -> N=415 total (208/arm), matching the
  package's own vignette statement -- "the study would require about
  207 subjects per arm" -- exactly (raw N=414.62, 207.31/arm). Plus a
  second design, MMRM (mixed model of repeated measures) with dropout
  under an AR(1) correlation structure (`calc_mmrm_ar1()`), wrapping
  `longpower::power.mmrm.ar1()` -- from the same package, again a
  single self-contained function, read from the same GitHub CRAN
  mirror. Verified exactly against the package's own documented
  "approximate simulation results from Table 5" of Lu, Luo & Chen
  (2008): rho=0.6, arm-1 retention=(1,0.76,0.63,0.52), arm-2
  retention=(1,0.87,0.81,0.78), sigma=1, delta=0.9,
  lambda=sqrt(1.25/1.75), target power=0.904 -> N=81 total (37/44 per
  arm), matching the package's own companion example exactly (which
  fixes N=81 and solves back for rho, recovering rho=0.585, close to
  the input 0.6 -- explained by N=81 being a rounded integer, not the
  exact unrounded root 80.61). Plus two more slope-difference methods
  (of `longpower::lmmpower()`'s four total; liuliang is above, hu
  remains uncovered): `calc_longitudinal_diggle()`
  (`longpower::diggle.linear.power()`, Diggle et al 2002) and
  `calc_longitudinal_edland()` (`longpower::edland.linear.power()`, Ard
  & Edland 2011), both read from the same GitHub CRAN mirror. Diggle
  verified by literally reproducing the printed 3x3 table on page 29 of
  Diggle et al (2002) (rho=0.2/0.5/0.8 x sigma2=100/200/300, delta=0.5,
  one-sided alpha=0.05, power=0.80 -> exact match on every cell:
  n=313/625/938, 196/391/586, 79/157/235 per group). Edland verified
  against its own documented Alzheimer's-disease example (raw N=414.62)
  and independently against this module's own Liu & Liang design, which
  gives the identical raw N=414.62 for the mathematically-equivalent
  scenario -- two different derivations landing on the same number.
  Plus the fourth and final `lmmpower()` method, `calc_longitudinal_hu()`
  (`longpower::hu.mackey.thomas.linear.power()`, Hu, Mackey & Thomas
  2021) -- the only one of the four that directly models monotone
  study-subject attrition (dropout) rather than assuming complete data
  throughout -- verified against 3 of the package's own documented
  round-trip examples exactly (same ADAS-cog-style pilot estimates:
  equal allocation/two-sided -> n=180/180; 2:1 allocation -> n=270/135;
  one-sided -> n=142/142). All four `lmmpower()` methods are now
  implemented in this module

Everything else in `docs/checklist_by_design.md` / `docs/checklist_by_test.md`
(advanced survival designs, post-hoc power, and the much larger Stage 2-4
backlog in those two files) remains "coming soon" in the Home hub, per
the staged build plan.

### Top navbar: grouped by study design, simple to difficult

With 24 calculator modules, one flat top-level tab per module became
unworkably crowded, so `app.R` groups them into 10 `bslib::nav_menu()`
dropdowns instead of listing them flat, ordered to match
`docs/checklist_by_design.md`'s own Part-1 study-design section numbers
(already simple -> difficult): Descriptive & Estimation, Survey &
Cross-Sectional, Observational Studies, Diagnostic & Screening, Agreement &
Reliability, Clinical Trials, Survival Analysis, Prediction Models,
Surveillance, and General Statistical Tests (the handful of modules with no
single natural study-design home -- Correlation, Chi-Square, Multiple
Regression, Factorial ANOVA/ANCOVA, Logistic Regression, Exact Tests -- kept
together here, same duality as `checklist_by_design.md` vs.
`checklist_by_test.md`). The grouping itself lives in `global.R`'s
`module_groups` list (which module ids collapse under which dropdown title,
in what order) -- `app.R` just builds one `nav_menu()` per entry; adding a
calculator to the *navbar* still only means appending to `module_registry`
plus placing its id in the right `module_groups` entry, nothing about
`app.R`'s structure changes. Total top-level nav items: Home + 10 dropdowns
= 11, down from 26 flat tabs (Home, "Which calculator?", and 24 modules).

### Home hub: welcome + three ways to find/understand a calculator

The Home tab is a short welcome, then one "Helper" area (`R/home/home_hub.R`)
bundling three tabs so none of them need their own crowding top-level nav
item:

- **"Browse calculators"** (`R/home/home_finder.R`) -- a single toggle
  ("By study design" / "By test family") over an accordion of every
  built calculator at once (collapsed by default so ~20-21 family panels
  stay scannable), rather than the old one-family-at-a-time dropdown. "By
  study design" uses `study_design_families`; "By test family" is a second,
  parallel index, `test_families` (both in `home_catalog.R`), mirroring
  G*Power/the scope-review checklist's "Part 2 -- By Statistical Test"
  groupings (t/z/F/chi-square/exact tests, correlation & regression,
  survival tests, agreement statistics, equivalence/non-inferiority forms).
  Toggling never duplicates a calculator -- both axes point at the same
  `calculator_catalog` entries and the same jump-button mechanism (below);
  it's purely a second browsing lens over one set of live modules.
- **"Which calculator? (guided wizard)"** (`R/home/design_wizard.R`) -- asks
  one question at a time (primary aim, experimental vs. observational,
  selection basis, outcome type, groups) per
  [`docs/design_identification_algorithm.md`](docs/design_identification_algorithm.md),
  shows its reasoning trace as you answer, and ends on a jump button into a
  live module -- or an honest "not yet built" note (naming the module/
  backend/citation the checklists already call for) if that branch isn't
  implemented yet. `R/home/design_tree.R` holds the question/terminal node
  registry. v1 scope is guided-tree only -- no free-text/PICO parsing yet.
- **"Formulas & LaTeX"** (`home_hub.R`'s `home_sandbox_ui()`) -- a short
  explainer of this app's `$$...$$`/MathJax formula convention, plus a live
  sandbox: type LaTeX and see it rendered instantly. See "Formula LaTeX
  source + copy button" below for the matching feature on every calculator's
  own formula display.

Both `home_finder.R` and `design_wizard.R` expose a `*_body()` UI-fragment
function (not a full page) plus their existing `*_server()`, composed
together by `home_hub.R`'s `home_panel_ui()`/`home_server()` -- same
non-module, top-level pattern as before (see "Non-idiomatic patterns"
below), just assembled from three pieces instead of mounted as separate nav
panels.

### Look & feel

`app.R`'s `bs_theme()` uses the "litera" Bootswatch preset with the
"Source Serif 4" Google Font for both body and heading text (a clean,
academic look, and a serif companion to the widely-used Source Sans family
used across scientific publishing). Google Fonts load client-side at the
browser, not server-side -- no new R package -- so this needs the end user's
browser to reach `fonts.googleapis.com`; it degrades gracefully to a system
serif font if that's blocked, same as `withMathJax()`'s formula rendering
degrading gracefully (no crash, just unstyled/untypeset content) if
`mathjax.rstudio.com` is unreachable.

## Requirements

- R (>= 4.1)
- `pacman` (installed automatically by `global.R` if missing), which in turn
  installs/loads `shiny`, `bslib`, `pwr`, `presize` (which itself pulls in
  `kappaSize`). `testthat` is only needed to run the test suite:
  ```r
  install.packages("testthat")
  ```

## Running the app

```r
shiny::runApp()
```

or from a shell:

```sh
Rscript -e 'shiny::runApp()'
```

## Running tests

```r
testthat::test_dir("tests/testthat")
```

## Repository structure

```
app.R                      # entry point: builds grouped navbar, wires modules + Home hub
global.R                   # pacman::p_load(), source()s R/, module_registry + module_groups
R/
├── modules/                # UI + server per calculator (mod_*.R), + mod_shared_ui.R
├── calc/                   # pure calculation functions, no Shiny (calc_*.R)
├── content/                 # per-module metadata: formula, text, citation (content_*.R)
└── home/                    # Home hub: finder, wizard, catalog (see below)
tests/testthat/            # unit tests on calc_*.R functions
docs/                       # project brief and software design document
www/                         # custom CSS/JS/logo, if added later
```

## Module contract

Every calculator is three files that plug into one registry entry. Nothing
outside those three files changes when you add a calculator.

1. **`R/calc/calc_<name>.R`** — pure R functions, no Shiny. Validate inputs,
   call the underlying stats package (prefer wrapping `pwr`, `presize`,
   `epiR`, `WebPower`, `pwrss`, or `TrialSize` over reimplementing formulas),
   and return a plain list of results. Because these have no Shiny
   dependency, they're directly unit-testable — see
   `tests/testthat/test-calc_proportion.R` for the pattern. Generic input
   validators (`.validate_number()`, `.validate_positive()`,
   `.validate_unit_interval()`, `.validate_population()`) live in the shared
   `R/calc/calc_utils.R` rather than being redefined per file — reuse those
   instead of writing a new one with the same check.

2. **`R/content/content_<name>.R`** — a plain R list (or one list per
   sub-design, as in `content_proportion.R`) with:
   - `title`
   - `formula_latex` — one or more MathJax display-math blocks, each wrapped
     in `$$...$$` and typically built with `paste0()` when there's more than
     one (e.g. `paste0("$$h = ...$$", "$$n = ...$$")`) — no separator needed,
     consecutive `$$...$$` blocks just render as consecutive equations. Since
     this is an R string, every LaTeX backslash has to be doubled (`\\frac`,
     `\\alpha`) — R itself treats a single `\` as an escape character. The
     in-app "Formulas & LaTeX" tab on the Home page explains this same
     convention to end users and has a live sandbox to experiment in.
   - `explanation` — markdown, plain-language description of each parameter
   - `worked_example` — markdown, a worked numeric example
   - `citation` — full citation of the original methodological source
   - `backend` — which package/function implements the method

   Content is data, not hardcoded UI — help/reference tabs render this list
   generically.

3. **`R/modules/mod_<name>.R`** — the Shiny module:
   - `mod_<name>_ui(id)` — a `tabsetPanel()` with **Calculate** / **Formula /
     Help** / **Reference** sub-tabs, following `mod_proportion.R`. On the
     Formula/Help tab, render each formula with
     `render_formula_block(<content>$formula_latex)` (from the shared
     `R/modules/mod_shared_ui.R`, sourced automatically like every other
     `mod_*.R` file) rather than a bare `withMathJax(HTML(...))` call — it
     renders the same MathJax output plus a collapsible "Show LaTeX source"
     block with a copy-to-clipboard button, so this is a drop-in replacement,
     not an alternative.
   - `mod_<name>_server(id)` — reads inputs, calls the `calc_*` function
     inside a `reactive()` + `tryCatch()`, and renders the result or a
     validation message
   - a small metadata list (`id`, `nav_title`) for the registry

   If the family has more than one design (e.g. Proportions' precision/
   known-value/two-sample split), add a `design` `radioButtons()` +
   `conditionalPanel()` per design, as in `mod_proportion.R`. A
   single-design family doesn't need one — `mod_diagnostic.R` has no
   `design` input at all, since it's one calculation with no variants to
   switch between.

### Wiring it in

Add one entry to `module_registry` in `global.R`:

```r
module_registry <- list(
  list(id = proportion_meta$id, title = proportion_meta$nav_title,
       ui = mod_proportion_ui, server = mod_proportion_server),
  list(id = means_meta$id, title = means_meta$nav_title,
       ui = mod_means_ui, server = mod_means_server)
)
```

`app.R` builds the navbar by iterating this list — it does not need to
change when you add a calculator.

## Home page calculator finder

The Home tab's "Browse calculators" section offers one toggle over two
parallel indexes, both driven by `R/home/home_catalog.R`:

- **By study design** — `study_design_families`, matching
  `docs/checklist_by_design.md`'s own sections (Proportions, Means,
  Case-Control, ...); also mirrors `docs/SDD.md` §7's catalog table.
- **By test family** — `test_families`, matching
  `docs/checklist_by_test.md`'s G*Power-style groupings (t tests, z tests, F
  tests, chi-square tests, exact tests, correlation & regression, survival
  tests, agreement statistics, equivalence/non-inferiority forms).

Both resolve to entries in `calculator_catalog` (in `home_catalog.R`) and
render as one accordion (collapsed by default) of family panels via
`.render_catalog_entry()`. An entry with `built = TRUE` renders as a button
that jumps to the right nav tab and presets that module's internal design
selector; `built = FALSE` renders a "coming soon" note. **When you add a new
calculator module, also add its catalog entry/entries** (and, if it starts a
new family, an entry in `study_design_families` and/or `test_families`) —
otherwise the finder will describe it as not yet implemented even after
you've built it.

## Non-idiomatic-for-plain-R patterns used here

A couple of things in this codebase aren't standard base-R idiom; noted here
since they're easy to miss when skimming the module code.

- **`conditionalPanel()` JS condition strings.** `mod_proportion.R` shows/hides
  input blocks with `conditionalPanel(condition = "input['proportion-design'] ==
  'single'")`. This condition is evaluated as **JavaScript in the browser**,
  not R — and because Shiny modules namespace every input id (prefixing it
  with the module id, e.g. `proportion-design` instead of `design`), the
  condition string is built with `ns("design")` rather than hardcoded, so it
  stays correct if the module is ever mounted under a different id.

- **`do.call()` to build `page_navbar()`'s (and `nav_menu()`'s) tabs
  dynamically.** `app.R` builds one `nav_menu()` per `module_groups` entry
  (each via `do.call(nav_menu, c(list(title = g$title), panels))`, since a
  group's member-module list is itself built at runtime from
  `module_groups`), then passes the whole list of `nav_menu()`s to
  `do.call(page_navbar, c(list(id = ..., title = ..., theme = ...),
  list(home_panel), group_menus))` instead of writing
  `page_navbar(title = ..., home_panel, nav_menu_1, nav_menu_2, ...)` by
  hand. `do.call()` is base R (not Shiny/JS-specific) but is worth flagging
  if you haven't used it before: it calls a function with an argument list
  assembled at runtime, which is how a variable number of dropdowns (and
  variable number of modules within each) gets passed into `...`.

- **`moduleServer()` / `NS()`.** Standard Shiny modules pattern: `NS(id)`
  namespaces UI element ids so multiple instances of a module (or multiple
  modules) never collide, and `moduleServer(id, function(input, output,
  session) {...})` gives the server function a matching, isolated input/output
  scope. Every `mod_*.R` file must use both.

- **`pacman::p_load()` instead of `library()`.** `global.R` installs
  `pacman` itself if missing (`if (!requireNamespace("pacman", quietly =
  TRUE)) install.packages("pacman")`), then calls
  `pacman::p_load(shiny, bslib, pwr)`. Unlike `library()`, `p_load()`
  installs a package automatically if it isn't already present, so a fresh
  clone of this repo doesn't need a separate "install these packages" step
  before `shiny::runApp()` works.

- **Updating a module's input from outside the module.** `home_finder.R`'s
  server logic runs at the top level (not inside `moduleServer()`), and on a
  finder button click it calls `updateRadioButtons(session,
  "proportion-design", selected = ...)` using the module's fully-namespaced
  input id directly, rather than `ns("design")`. This works because
  `update*Input()` functions address inputs by their raw, on-the-page DOM id
  — namespacing (`ns()`) is only needed *inside* a module, to build that
  same id from the bare name. Called from the root session, the
  already-namespaced string is exactly what's needed.

- **`bslib::nav_select()`.** `page_navbar(id = "main_nav", ...)` gives the
  navbar an id; `nav_select("main_nav", "Proportions", session = session)`
  then switches the active tab programmatically (used by the Home hub's
  "jump to calculator" buttons and the guided wizard) instead of the user
  clicking the tab themselves. Targets by nav title regardless of whether
  that `nav_panel` sits directly on the navbar or nested inside a
  `nav_menu()` dropdown (see "Top navbar" above) -- grouping modules into
  dropdowns didn't require any change to this jump mechanism.

- **`numericInput(..., value = NA)` for an optional field.** The precision
  calculator's population size `N` is optional (no finite population
  correction if omitted). `numericInput(ns("N_precision"), ..., value =
  NA)` renders as an empty field in the browser rather than showing a
  literal `NA` — an HTML `<input type="number">` can't hold non-numeric
  text, so it just displays blank. Server-side, an untouched or
  user-cleared field comes back as `NULL` or `NA` respectively; the server
  code normalizes both to `NULL` before calling `calc_proportion_precision()`,
  which treats `N = NULL` as "no correction."

- **`session$ns()` for dynamically created inputs.** `mod_agreement.R`'s
  kappa design needs one proportion input per category, and the number of
  categories is itself a user choice (2-5) -- so those inputs can't be
  written statically in `mod_agreement_ui()`. Instead, `mod_agreement_server()`
  builds them inside a `renderUI()` on the server side, and namespaces each
  one with `session$ns("prop_1")` rather than the `ns()` closure the static
  UI function uses. Both produce the identical namespaced id -- `ns()` is
  just `session$ns()` captured once at UI-build time and handed to the UI
  function as a convenience; server-side code reaches the same namespace
  through the session object directly, since it doesn't have that closure
  in scope.

## Adding the next module

Copy `R/calc/calc_proportion.R`, `R/content/content_proportion.R`, and
`R/modules/mod_proportion.R`, rename to the new calculator, swap the formula
and stats-package call, then:

1. Add one entry to `module_registry` in `global.R`.
2. Flip (or add) its entry/entries in `calculator_catalog` in
   `R/home/home_catalog.R` from `built = FALSE` to `built = TRUE`, with the
   right `nav_target`/`module_input_id`/`design_value`, so the Home finders
   pick it up.

See `docs/SDD.md` §7 for the full calculator catalog and phase plan (means,
case-control, cohort/RR, diagnostic accuracy, correlation, precision-based,
post-hoc power).
