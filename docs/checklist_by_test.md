# Sample Size Calculator — Master Checklist (by Statistical Test)

> **Status note (cross-referenced against the codebase 2026-08-20):** see the
> same note at the top of `checklist_by_design.md` — ticks reflect what's
> actually live, with an inline note where our backend differs from the one
> named here.

-----

## ============================================================

## FILE 2 — STATISTICAL-TEST-BASED CHECKLIST (G*Power mirror + extensions)

## ============================================================

### Legend / How to use

- `- [ ]` = not yet implemented. **[CORE]** / **[ADV]** as in File 1.
- **G*Power column:** Yes / Partial / No, with menu path where known. G*Power selection is two-step (Test family → Statistical test) or design-based (Tests menu → parameter class → design).
- **Effect-size metrics** used across G*Power: d/dz (t), f & f² (F/ANOVA/regression), w (χ²), h (proportions), q (two correlations), r (correlation).
- All five G*Power analysis types (a priori / post hoc / compromise / criterion / sensitivity) should be exposed per calculator where feasible; a priori (solve N) is the v1 default, post hoc (achieved power) is your planned second module.

-----

### t tests — G*Power **t** family

- [x] **[CORE]** One-sample t (mean vs constant) — d — `pwr::pwr.t.test(type="one.sample")` — GP: t → Means: one sample — *(implemented: Means → "Single mean vs. known value", `calc_means_1s()`)*
- [x] **[CORE]** Two independent means, equal n — d — `pwr::pwr.t.test(type="two.sample")` — GP: t → Means: two independent groups — *(implemented: Means → "Two independent means", `calc_means_2s_indep()`)*
- [x] **[CORE]** Two independent means, unequal n — d, n ratio — `pwr::pwr.t2n.test`  — GP: Yes — *(implemented: Means module's new "Two independent means, unequal group sizes" design, `calc_means_2s_unequal_n()`; verified backend against Cohen (1988) Exercise 2.3 p.437 (d=0.6, n1=90, n2=60 -> power=0.9737 exactly))*
- [x] **[ADV]** Welch t (unequal variances) — SD1, SD2, ratio — `MESS::power_t_test` / simulation — GP: Partial — *(implemented: Means → "Two independent means, unequal variances (Welch's t-test)", `calc_means_welch()`; `MESS` isn't installed and this sandbox has no CRAN access to add it, so this uses the standard large-sample normal-approximation formula from the sample-size literature (Julious 2004; Rosner) that keeps the two variances separate rather than pooling them -- exactly how Welch's t-test itself treats them. Verified two ways: (1) with sigma1=sigma2 it reduces algebraically to `TrialSize::TwoSampleMean.Equality()`'s own documented example exactly (n=63); (2) for genuinely unequal variances (sigma1=1, sigma2=2, mu1=0, mu2=0.5) it returns n=157/group, confirmed by a 5,000-replicate Monte Carlo simulation using R's own Welch t-test (`stats::t.test(var.equal=FALSE)`, empirical power 0.793 vs. the 0.80 target))*
- [x] **[CORE]** Paired t — dz (mean & SD of differences) — `pwr::pwr.t.test(type="paired")` — GP: t → Means: two dependent (matched pairs) — *(implemented: Means → "Two paired means", `calc_means_paired()`)*
- [x] **[ADV]** Point-biserial correlation — r — GP: t → Correlation: point biserial — *(implemented: Correlation → "Point-biserial correlation", `calc_correlation_point_biserial()`; converts r to Cohen's d = 2r/sqrt(1-r^2) and reuses `pwr::pwr.t.test()`; verified r=0.5 -> d=1.1547 -> n=13/group (26 total), cross-checked by simulation)*
- [x] **[ADV]** Regression coefficient / linear bivariate slope — slope, SDx, SDy — GP: t → Linear bivariate regression — *(implemented: Correlation → "Regression coefficient (bivariate slope)", `calc_regression_slope()`; uses the exact identity r = slope*SDx/SDy and reuses `pwr::pwr.r.test()`; verified slope=0.5, SDx=2, SDy=4 -> r=0.25 -> n=123, cross-checked by simulation)*

### z tests — G*Power **z** family

- [x] **[CORE]** Single proportion — h (or p vs p0) — `pwr::pwr.p.test`  — GP: Exact (binomial) / z — *(implemented: Proportions → "Single proportion vs. known/reference value", `calc_proportion_1s()`; the module also has a separate precision-based single-proportion design not in this row — see `checklist_by_design.md` §1)*
- [x] **[CORE]** Two proportions — h — `pwr::pwr.2p.test`, `pwr::pwr.2p2n.test` (unequal) — GP: z → Proportions: two independent groups — *(implemented: Proportions → "Two independent proportions", `calc_proportion_2s()`; equal-n only — `pwr.2p2n.test`'s unequal-n case not built)*
- [ ] **[ADV]** Logistic regression (simple/multiple) — OR, predictor distribution, R² with covariates — `WebPower::wp.logistic` — GP: z → Logistic regression (Faul 2009)
- [ ] **[ADV]** Poisson regression — rate ratio, exposure distribution — `WebPower::wp.poisson` — GP: z → Poisson regression (Faul 2009)

### F tests — G*Power **F** family

- [x] **[CORE]** One-way ANOVA — f, k groups — `pwr::pwr.anova.test` , `WebPower::wp.anova` — GP: F → ANOVA: fixed effects, omnibus — *(implemented: Means → "Three or more independent groups (one-way ANOVA)", `calc_means_anova()`, converts raw group means + SD to Cohen's f)*
- [x] **[ADV]** Two-way / factorial ANOVA (main effects & interactions) — f, numerator df — GP: F → ANOVA: fixed effects, special — *(implemented: new Factorial ANOVA / ANCOVA module, `calc_anova_general()` wrapping `pwr::pwr.f2.test()` -- the same general linear-model F-test engine already used by the Multiple Regression module, since Cohen (1988) treats ANOVA/ANCOVA and multiple regression as one "F tests" family; user supplies the effect's own numerator df (u) directly. Cross-validated against `pwr::pwr.anova.test()`'s one-way-ANOVA special case (u=k-1): k=4, f=0.25 -> 180 total (dedicated formula) vs. 179 total (general engine), agreeing to within the expected per-group-vs-total-df rounding difference)*
- [x] **[ADV]** Repeated-measures ANOVA (between, within, interaction) — f, #measurements, correlation, nonsphericity ε — `WebPower::wp.rmanova` — GP: F → ANOVA: repeated measures — *(implemented: new RM-ANOVA / Mixed ANOVA module, `calc_rm_anova(type = "between"/"within"/"interaction")`, closed-form reimplementation of `WebPower::wp.rmanova()`'s noncentral-F algorithm (Cohen 1988) rather than depending on `WebPower` (its `MASS`/`lme4`/`lavaan`/`PearsonDS` Depends and `dplyr` Imports are far heavier than this one function needs, and `wp.rmanova()` itself never calls into any of them). Between-effect verified exactly against that package's own documented example (ng=3, nm=4, f=0.36, nscor=0.7, power=0.8 -> n=110); within-effect and interaction verified by independently running the identical extracted algorithm with fixed inputs, since those specific combinations aren't in WebPower's own published examples)*
- [x] **[ADV]** ANCOVA — f, #covariates, #groups — `WebPower::wp.rmanova`-family / GP: F → ANCOVA — nMaster — *(implemented: same Factorial ANOVA / ANCOVA module and `calc_anova_general()` backend as the factorial-ANOVA item above -- an ANCOVA group effect is the same general F-test with u = (a-1) for a groups, just a different denominator-df context; not `WebPower`, avoiding its heavy `lme4`/`lavaan`/`dplyr`/`PearsonDS` dependency chain)*
- [ ] **[ADV]** MANOVA (global & special effects, incl. Hotelling's T²) — GP: F → MANOVA
- [x] **[ADV]** Mixed (split-plot) ANOVA — GP: F → ANOVA: repeated measures, within-between — *(implemented: same RM-ANOVA / Mixed ANOVA module, "Group x time interaction" design -- the split-plot interaction test is the `type = "interaction"` case of the same `calc_rm_anova()` engine as the item above; verified n=226 for ng=3, nm=3, f=0.25, nscor=0.8, power=0.8 against an independent run of the identical extracted algorithm)*
- [x] **[CORE]** Multiple linear regression, R² deviation from zero — f² — `pwr::pwr.f2.test` — GP: F → Linear multiple regression: fixed model R² deviation from zero — *(implemented: new Multiple Regression module, `calc_regression_f2()`; backend verified against Cohen (1988) Exercise 9.1 p.424 (u=5, v=89, f2=0.1111 -> power=0.6736 exactly))*
- [ ] **[ADV]** Multiple regression, R² increase (hierarchical) — f² for added set — GP: F → …R² increase
- [ ] **[ADV]** Random-model multiple regression — GP: F (Faul 2009)
- [x] **[ADV]** Planned contrasts; post-hoc comparisons with multiplicity adjustment — *(implemented: planned contrasts via the Means module's "Planned linear contrast (k-group means)" design, `calc_means_planned_contrast()`, wrapping `TrialSize::Dose.Response.Linear()` (verified exactly against Chow, Shao & Wang (2003) Example 11.1: n=178); post-hoc multiplicity-adjusted comparisons via a new "Post-hoc pairwise comparison (Bonferroni-adjusted)" design in BOTH the Means module (`calc_means_posthoc_pairwise()`, wrapping `TrialSize::OneWayANOVA.pairwise()`) and the Proportions module (`calc_proportion_posthoc_pairwise()`, wrapping `TrialSize::OneWayANOVA.PairwiseComparison()`) -- both zero-dependency `TrialSize` functions, applying the standard Bonferroni correction (alpha/tau for tau planned comparisons) to the usual two-sample sample-size formula. Since neither function's own Rd file prints a numeric worked answer, both formulas were independently re-derived from first principles and confirmed to reproduce the package's own output exactly: means version (tau=3, sigma=4, margin=3) -> n=38/group; proportions version (Chow/Shao/Wang's own two examples, tau=2) -> n=96 and n=44 per group)*

### χ² tests — G*Power **χ²** family

- [x] **[CORE]** Goodness of fit — w, df — `pwr::pwr.chisq.test` (`ES.w1`) — GP: χ² → Goodness-of-fit — *(implemented: Chi-Square Tests → "Goodness of fit", `calc_chisq_gof()`)*
- [x] **[CORE]** Test of independence / association (R×C) — w, df — `pwr::pwr.chisq.test` (`ES.w2`) — GP: χ² → contingency tables — *(implemented: Chi-Square Tests → "Test of independence", `calc_chisq_independence()`, dynamic R×C proportion-matrix UI (rows/cols 2-5); also cross-referenced as the "3+ group proportions" catalog entry)*
- [x] **[ADV]** McNemar's (paired proportions) — OR, proportion discordant — GP: χ² → McNemar (exact) — *(implemented: Chi-Square Tests → "McNemar's test (paired proportions)", `calc_mcnemar()`, wraps `TrialSize::McNemar.Test()` -- `TrialSize` already a zero-dependency project dependency, no new package. Verified exactly against Chow, Shao & Wang (2003) Example 6.4.3: p10=0.5, p01=0.2 (psai=0.4, paid=0.7), alpha=0.05, power=0.80 -> n=59 pairs)*
- [ ] **[ADV]** Cochran's Q (k paired proportions)
- [x] **[ADV]** Mantel–Haenszel (stratified OR) — PASS CMH — *(implemented: Chi-Square Tests → "Mantel-Haenszel (stratified proportions)", `calc_mantelhaenszel()`, wrapping `TrialSize::Propensity.Score.strata()` (weighted Mantel-Haenszel test) and `TrialSize::Propensity.Score.nostrata()` (naive pooled comparison, shown side by side) -- `TrialSize` already a zero-dependency project dependency. Verified exactly against Chow, Shao & Wang (2003) Example 15.2.3: J=5 strata, phi=2, alpha=0.05, power=0.80 -> stratified n=447 vs. naive pooled n=1151, both matching the textbook's own two worked answers)*
- [x] **[ADV]** Cochran–Armitage trend — dose-response proportions — Epi Info StatCalc (χ² for trend) — *(implemented: Chi-Square Tests → "Cochran-Armitage trend test (dose-response)", `calc_cochran_armitage_trend()`, wrapping `TrialSize::Cochran.Armitage.Trend()` -- already a zero-dependency project dependency. Verified exactly against Chow, Shao & Wang (2003) Example 11.5 (pi=(0.1,0.3,0.5,0.7), di=(1,2,3,4), equal allocation, delta=1 -> n=8/group, 32 total, matching the textbook's own worked answer). Note: the closely related `TrialSize::Dose.Response.binary()` was found broken in an earlier batch -- this is a different, independently verified function from the same package)*
- [x] **[ADV]** Single-variance χ² test — *(implemented: new Variance Tests module → "Single-variance test (vs. a reference SD)", `calc_variance_single()`; closed-form chi-squared power function solved via `uniroot()` (no package -- `TrialSize::ISV.Equality()`/`ISCV.Equality()` were investigated and found broken, see below); verified sigma0=10, sigma1=14, one-sided greater, alpha=0.05, power=0.80 -> n=28, cross-checked by 20,000-replicate Monte Carlo simulation (empirical power 0.814))*

### Exact tests — G*Power **Exact** family

- [x] **[CORE]** Fisher's exact (2×2) — p1, p2, allocation — GP: Exact → Proportions: inequality, two independent (Fisher) — *(implemented: new Exact Tests module's "Fisher's exact test" design, `calc_fisher_exact()` wrapping `Exact::power.exact.test(method="fisher")`, searching n1 upward for the first n1 whose exact power clears the target and stays there for 2 more steps -- exact-test power is non-monotonic in n (Chernick & Liu 2002), so a naive single-n search can land on a fragile spike. Verified: package's own doc example (p1=.15, p2=.60, n1=15, n2=30) reproduces power=0.8049 exactly; our search at ratio=2 finds n1=14 (achieved power 0.8195), one step earlier than the package's illustrative n1=15 -- a real instance of that non-monotonicity, not a discrepancy)*
- [x] **[CORE]** Binomial test (single proportion) — p, p0 — GP: Exact → Proportion: difference from constant — *(implemented: new Exact Tests module's "Binomial test" design, `calc_binomial_exact()`, searching n via base R's own `stats::binom.test()` (no external package needed) with the same stability-window search as Fisher's exact above. Verified: p0=.1, p1=.3, alpha=.05, power=.8 -> n=25, achieved exact power=0.8065, confirmed stable through n=27)*
- [x] **[ADV]** Exact Poisson (rare event vs standard) — Epi Info StatCalc (Poisson) — *(implemented: Exact Tests module's "Exact Poisson test" design, `calc_poisson_exact()`, searching person-time T upward via base R's own `stats::poisson.test()` (no external package needed), same stability-window search as the Binomial Test design (exact-test power is non-monotonic, Chernick & Liu 2002). Verified: rate0=5, rate1=10, alpha=.05, power=.8 -> T=3 (30 expected events), achieved exact power=0.8854, independently confirmed by a 20,000-replicate Monte Carlo simulation (empirical power 0.8835))*
- [ ] **[ADV]** Correlation, bivariate normal (exact) — r — GP: Exact → Correlation: bivariate normal
- [x] **[ADV]** Proportions difference, unconditional exact — GP: Exact → Proportions: inequality, unconditional — *(implemented: Exact Tests module's "Boschloo's exact test" design, `calc_boschloo_exact()`, wrapping `Exact::power.exact.test(method="boschloo")` -- already a project dependency (used for Fisher's exact test) -- the classic unconditional exact test for two proportions. Verified by the known theoretical relationship (Boschloo 1970: uniformly at least as powerful as Fisher's exact test): p1=.30, p2=.60, alpha=.05, power=.8 -> boschloo n1=44 (88 total) vs. fisher n1=48 (96 total) on identical inputs)*

### Correlation & regression

- [x] **[CORE]** Pearson correlation — r — `pwr::pwr.r.test` — GP: Exact/t → Correlation — *(implemented: Correlation module, `calc_correlation()`)*
- [ ] **[ADV]** Spearman / Kendall's tau — via ARE inflation of Pearson — *(partially implemented: Kendall's tau now built -- new Nonparametric Tests module → "Kendall's tau (nonparametric association)", `calc_kendall_tau()`, wraps `TrialSize::Nonpara.Independ()`, a direct closed-form using concordance probabilities (tau = 2*p1 - 1) rather than ARE-inflation of a Pearson-correlation n; verified exactly against Chow, Shao & Wang (2003) Example 14.4: p1=0.6, p2=0.7, alpha=0.05, power=0.80 -> n=135. Spearman's rho still not built -- no equivalent direct closed form identified yet, would still need the ARE-inflation route or its own dedicated formula)*
- [x] **[ADV]** Partial correlation — r, #controlled variables — GP: Yes — *(implemented: Correlation → "Partial correlation (controlling for k covariates)", `calc_correlation_partial()`; reuses `pwr::pwr.r.test()`'s zero-order-correlation engine and adds k for the covariates (Cohen 1988's own power tables read partial correlation off the same table as zero-order correlation, entered with n-k). Verified r=0.3, k=2, alpha=0.05, power=0.80 -> n=87 (zero-order n=85 + 2), cross-checked by a 5,000-replicate Monte Carlo simulation (empirical power 0.826))*
- [x] **[ADV]** Compare two independent correlations — q (Fisher r-to-z) — `pwr` (manual) — GP: z → Correlations: two independent Pearson r's — *(implemented: Correlation module → "Compare two independent correlations", `calc_correlation_two_independent()`, closed-form (Cohen 1988) since `pwr` has no dedicated two-sample function for this case (only `pwr.r.test()` for one correlation vs. zero). Verified against UCLA OARC's own G*Power worked example (r1=0.89, r2=0.76, alpha=0.05 two-sided): power=0.90 -> n=61/group (matches exactly under both round-to-nearest and this project's ceiling() convention); power=0.80/0.70 -> n=47/38 per group here vs. the published table's round-to-nearest 46/37, a rounding-direction difference, not a formula discrepancy)*
- [ ] **[ADV]** Compare two dependent correlations (common / non-common index) — GP: z (Faul 2009)
- [ ] **[ADV]** Simple/multiple linear regression (fixed & random model) — see F family
- [x] **[ADV]** Logistic regression (with/without covariate adjustment) — see z family — `WebPower::wp.logistic` — *(implemented: new Logistic Regression module, `calc_logistic_binary()`/`calc_logistic_continuous()` wrapping `powerMediation::SSizeLogisticBin()`/`SSizeLogisticCon()` (Hsieh, Bloch & Larsen 1998) rather than `WebPower::wp.logistic` -- `powerMediation` has zero package dependencies (`Depends: R, stats` only) versus WebPower's heavy dependency chain. Verified against the paper's own published tables exactly: binary predictor (p1=0.4, p2=0.5, B=0.5, alpha=0.05, power=0.95) → n=1281 (Table I); continuous predictor (p1=0.5, OR=exp(0.405), alpha=0.05, power=0.95) → n=317 (Table II). "With covariate adjustment" is not covered -- only the simple (single-predictor) case)*
- [ ] **[ADV]** Poisson / negative binomial regression — `WebPower::wp.poisson`
- [x] **[ADV]** Cox regression — HR, event proportion, covariate SD/correlation — `powerSurvEpi` — *(implemented: see Survival tests section below — Log-Rank / Survival module's Cox regression designs)*
- [ ] **[ADV]** Ordinal (proportional odds) / multinomial regression — PASS proportional-odds; Whitehead (1993)

### Non-parametric tests (handled via ARE inflation / Noether / simulation)

- [x] **[ADV]** Mann–Whitney U / Wilcoxon rank-sum — d then ×ARE (≈1.05 for normal) — GP: t → Means (Wilcoxon option) — nMaster; *Noether (1987)* — *(implemented: new Nonparametric Tests module → "Wilcoxon rank-sum (Mann-Whitney U, two independent groups)", `calc_wilcoxon_rank_sum()`, wraps `TrialSize::Nonpara.Two.Sample()` -- a direct distribution-free closed form (Chow, Shao & Wang 2003) using rank-concordance probabilities, rather than the checklist's suggested ARE-inflation-of-Cohen's-d shortcut; `TrialSize` already a zero-dependency project dependency. Verified exactly against that package's own documented example: k=1, p1=0.7, p2=0.8, p3=0.8, alpha=0.05, power=0.80 -> n=54)*
- [x] **[ADV]** Wilcoxon signed-rank — GP: Yes (parent distribution options) — nMaster — *(implemented: same Nonparametric Tests module → "Wilcoxon signed-rank (one sample / paired differences)", `calc_wilcoxon_signed_rank()`, wraps `TrialSize::Nonpara.One.Sample()`, same closed-form-not-ARE approach as above. Verified exactly: p2=0.3, p3=0.4, p4=0.05, alpha=0.05, power=0.80 -> n=383)*
- [x] **[ADV]** Kruskal–Wallis — ANOVA n ×ARE / simulation — *(implemented exactly as this line names: Nonparametric Tests → "Kruskal-Wallis (k independent groups)", `calc_kruskal_wallis()`; no installed package provides a k-sample rank-test closed form, so this solves the equivalent one-way ANOVA n via `pwr::pwr.anova.test()` (already a project dependency) and inflates by the classical asymptotic relative efficiency 3/pi (Hodges & Lehmann 1956) -- the same constant relating Wilcoxon rank-sum to the two-sample t-test. Verified by simulation using the actual `kruskal.test()`: k=3, f=0.25, alpha=0.05, power=0.80 -> ANOVA n=53/group, KW n=56/group (168 total), empirical power 0.812 at n=56 vs. only 0.787 at the unadjusted ANOVA n=53)*
- [ ] **[ADV]** Friedman — RM-ANOVA basis / simulation
- [x] **[ADV]** Sign test — `pwr`/exact binomial — nMaster — *(implemented: Exact Tests module → "Sign test (paired data / one-sample median)", `calc_sign_test()`, a thin wrapper around the existing `calc_binomial_exact()` design with p0 fixed at 0.5 -- the sign test IS an exact binomial test against 0.5 (Conover 1999), so no new math or dependency, just the same verified `stats::binom.test()`-based search exposed under the sign test's own framing)*
- [x] **[ADV]** Jonckheere–Terpstra (ordered alternatives) — `clinfun` (odds ratios per group) — *(implemented: Nonparametric Tests → "Jonckheere-Terpstra (ordered alternatives)", `calc_jonckheere_terpstra()`. `clinfun::jonckheere.test()` itself provides no sample-size function at all (analysis-only, like `stats::kruskal.test()`), but its own documentation states "the asymptotic version is equivalent to `cor.test(x, g, method="k")`" -- exactly Kendall's tau between the outcome and an ordinal group score (Terpstra 1952; Jonckheere 1954) -- so this is a thin wrapper around this module's own verified `calc_kendall_tau()`, reproducing its Chow, Shao & Wang (2003) Example 14.4 answer bit-for-bit (n=135))*
- [ ] **[ADV]** Kolmogorov–Smirnov; runs test; general permutation — simulation (`simr`/custom Monte Carlo)

### Survival tests

- [x] **[CORE]** Log-rank — Schoenfeld / Freedman / Lakatos — `powerSurvEpi`, `gsDesign::nSurv` — *(implemented: Log-Rank / Survival module, `calc_logrank()` wrapping `powerSurvEpi::ssizeCT.default()`; verified against Rosner (2006) Example 14.42 → nE=nC=294, total=588, exact match)*
- [x] **[ADV]** Cox PH — `powerSurvEpi` — *(implemented: Log-Rank / Survival module's new "Cox regression -- binary covariate" and "Cox regression -- continuous covariate" designs, `calc_cox_binary()`/`calc_cox_continuous()` wrapping `powerSurvEpi::ssizeEpi.default()`/`ssizeEpiCont.default()`; verified against the packages' own documented examples — Latouche et al. (2004) binary example → n=139; Hsieh & Lavori (2000) continuous example → n=107)*
- [ ] **[ADV]** Gray's test (competing risks) — `powerCompRisk`
- [ ] **[ADV]** RMST comparison — `SSRMST`
- [ ] **[ADV]** Weighted log-rank (non-PH) — `npsurvSS`/simulation

### Agreement statistics

- [x] **[CORE]** Kappa — `kappaSize` — *(implemented: Agreement/Reliability → "Cohen's kappa", `calc_kappa()`, wraps `presize::prec_kappa()` → `kappaSize`)*
- [x] **[CORE]** ICC (forms 1,1 / 2,1 / 3,1 …) — `ICC.Sample.Size`, `presize::prec_icc` — *(implemented: Agreement/Reliability → "ICC", `calc_icc()`, wraps `presize::prec_icc()` (Bonett 2002); form-specific (1,1 vs 2,1 vs 3,1) distinctions per Zou 2012 not separately exposed)*
- [x] **[ADV]** CCC; Bland–Altman LoA — `presize` — *(implemented: Bland-Altman LoA — Agreement/Reliability module's "Bland-Altman limits of agreement" design, `calc_agreement_bland_altman()` wrapping `presize::prec_lim_agree()`; Lin's CCC — same module's "Lin's concordance correlation coefficient (CCC)" design, `calc_agreement_ccc()`, closed-form (Lin 1989/2000) rather than a package wrap (no CRAN package implements a dedicated CCC sample-size function), reimplementing the exact asymptotic variance formula already used internally by `epiR::epi.ccc()` (already a project dependency) and cross-verified against real runs of that function)*

### Multiple-comparison procedures

- [ ] **[ADV]** Bonferroni-adjusted α → inflated n (wrap any calculator with α/m)
- [ ] **[ADV]** Holm; FDR / Benjamini–Hochberg adjusted sample size; family-wise error control — `ssize.fdr`

### Equivalence / non-inferiority test forms

- [x] **[CORE]** TOST for means — `PowerTOST`, `TOSTER::power_t_TOST` — *(implemented: Equivalence (TOST) module, `calc_tost_means()` wrapping `PowerTOST::sampleN.TOST(logscale=FALSE, design="parallel")`; verified against the package's own documented example → n=48, achieved power=0.815435)*
- [x] **[CORE]** TOST for proportions — `TOSTER`, `PowerTOST` — *(implemented: Equivalence (TOST) module's new "Two proportions" design, `calc_tost_proportions()` wrapping `epiR::epi.ssequb(type="equivalence")` rather than `TOSTER`/`PowerTOST` -- neither has a dedicated proportions-TOST function, but epiR's equivalence family covers it; verified against Machin/Campbell/Tan/Tan (2009) p.113 (Bennett et al. 1979 cryptococcal meningitis trial) -> n=166 total, exact textbook match)*
- [x] **[ADV]** Non-inferiority margins for RR / OR / HR / difference — `TrialSize`, `SampleSize4ClinicalTrials` — *(partially implemented: difference already covered for means/proportions via `epiR::epi.ssninfc()`/`epi.ssninfb()`; added this batch -- Non-Inferiority module's new "Odds ratio" design, `calc_noninferiority_or()`, wrapping `TrialSize::RelativeRisk.NIS()` (relabeled as odds-ratio-based, since its formula and its `RelativeRisk.Equality()` sibling are both built on the log odds ratio pt(1-pc)/(pc(1-pt)), not the relative risk pt/pc, despite the package's naming -- verified against Chow, Shao & Wang (2003) Example 4.6.4: pt=0.4, pc=0.25, margin=0.2, k=1, alpha=0.05, power=0.80 -> n=242/group), and "Hazard ratio (Cox PH)" design, `calc_noninferiority_hr()`, wrapping `TrialSize::Cox.NIS()` (verified against Example 7.3.4: hr=2, margin=0.5, p1=0.5, d=0.8 -> n=829). True relative-risk-scale (not odds-ratio) non-inferiority still not found in either named package)*

### Multilevel / mixed-model / GEE tests

- [ ] **[ADV]** Mixed-model tests (2/3-level) — `powerlmm`, `longpower`
- [ ] **[ADV]** GEE-based tests — `longpower::liu.liang.linear.power` — *Liu & Liang (1997); Rochon (1998)*

### Bayesian sample-size approaches

- [ ] **[ADV]** Bayes factor design analysis — `BFDA`, `bfpwr` — *Schönbrodt & Wagenmakers*
- [ ] **[ADV]** Assurance / expected power — `PowerTOST` (exp.* functions); PASS assurance procedures
- [ ] **[ADV]** Average coverage criterion; HPD interval width — `BayesianPower`

### Simulation-based power (no closed form)

- [ ] **[ADV]** Monte Carlo for GLMMs / complex designs — `simr` (from fitted `lme4` model), `Superpower` (factorial ANOVA), `SimEngine`

### Sequential / adaptive test procedures

- [x] **[ADV]** O'Brien–Fleming / Pocock boundaries — `gsDesign`, `rpact` — *(implemented: new Group Sequential Design module (`calc_group_sequential_normal()`/`_binary()`/`_survival()`), wrapping `clinfun::gsdesign.normal()`/`.binomial()`/`.survival()` -- `clinfun` already a project dependency (used for Simon two-stage), avoiding `gsDesign`/`rpact` (both confirmed not installed in this sandbox, no network access to CRAN). These functions parameterize the boundary as a "power family" (0 = Pocock, 0.5 = O'Brien-Fleming) rather than literal Lan-DeMets alpha-spending, but reproduce both classic boundary shapes at its endpoints. Verified: the single-look (fixed-design) special case reproduces the classic Schoenfeld (1983) log-rank event formula exactly for survival (66 events for HR=0.5, alpha=0.05, power=0.80) and the exact Z_(1-alpha/2)+Z_(1-beta) drift for all three outcome types; the binomial case cross-checked against `pwr::pwr.2p.test` within the expected variance-formula tolerance. Discovered the underlying functions use internal Monte-Carlo integration (`mvtnorm::pmvnorm`) that varies by +/-1 subject run-to-run without a fixed seed -- this app's wrapper functions set a fixed seed for reproducibility, documented explicitly in the code)*
- [ ] **[ADV]** Lan–DeMets alpha spending — `gsDesign`, `rpact`
- [ ] **[ADV]** Conditional power; futility boundaries; SSR — `gsDesign::ssrCP`, `condPower`

### Tests for variance / rates / counts

- [x] **[ADV]** Single-variance & two-variance (F) tests — *(implemented: new Variance Tests module — single-variance chi-squared test (see above) plus "Two-variance test (compare two groups)", `calc_variance_two()`; closed-form F-distribution power function solved via `uniroot()` (equal group sizes), same `TrialSize::ISV.Equality()`/`ISCV.Equality()` dead end documented in the module's code comments and content; verified sigma1=10, sigma2=14, two-sided, alpha=0.05, power=0.80 -> n=72/group (144 total), cross-checked by 20,000-replicate Monte Carlo simulation (empirical power 0.804))*
- [x] **[ADV]** One-sample & two-sample Poisson rate — `epiR`, Epi Info StatCalc — *(fully covered by three already-built designs, not one new calculator: the one-sample case by the Incidence Rate module's precision-based design (`calc_rate_precision()`, `presize::prec_rate()`) and the Exact Tests module's "Exact Poisson test" (`calc_poisson_exact()`, `stats::poisson.test()`, ADV batch 24); the two-sample case by the Incidence Rate module's "Comparison of two rates" design (`calc_rate_comparison()`, a closed-form Poisson-regression Wald test verified against `WebPower::wp.poisson()`'s own documented example). No `epiR`-specific Poisson function exists to wrap (`epiR` has none), so these closed-form/base-R routes were used instead)*

### Summary mapping table (selected CORE items)

|Scenario                      |Typical inputs                |R package/function                            |G*Power|Original source                   |Status|
|------------------------------|------------------------------|----------------------------------------------|-------|----------------------------------|------|
|Single proportion (prevalence)|p, precision, conf, N         |`epiR::epi.sssimpleestb`; `presize::prec_prop`|Partial|Fleiss; Lwanga-Lemeshow           |✅ built (closed-form Cochran, not the named package)|
|Two independent means         |d, α, power                   |`pwr::pwr.t.test`                             |Yes    |Cohen (1988)                      |✅ built|
|Two proportions               |h, α, power, ratio            |`pwr::pwr.2p.test`                            |Yes    |Cohen (1988)                      |✅ built|
|One-way ANOVA                 |f, k, α, power                |`pwr::pwr.anova.test`                         |Yes    |Cohen (1988)                      |✅ built|
|Pearson correlation           |r, α, power                   |`pwr::pwr.r.test`                             |Yes    |Cohen (1988)                      |✅ built|
|Multiple regression           |f², #predictors               |`pwr::pwr.f2.test`                            |Yes    |Cohen (1988)                      |✅ built|
|Unmatched case-control        |%exposed controls, OR, ratio  |`epiR::epi.sscc`                              |No     |Schlesselman (1982)               |✅ built|
|Cohort/RR                     |p0, RR, ratio                 |`epiR::epi.sscohortc`                         |No     |Kelsey; Fleiss                    |✅ built|
|Log-rank / survival           |HR, accrual, follow-up        |`powerSurvEpi`; `gsDesign::nSurv`             |No     |Schoenfeld (1983); Freedman (1982)|✅ built|
|Cohen's kappa                 |κ0, κ1, proportions, #raters  |`kappaSize`                                   |No     |Rotondi; Flack                    |✅ built|
|ICC (reliability)             |ICC, #raters, CI/power        |`ICC.Sample.Size`                             |No     |Zou (2012)                        |✅ built (via `presize`/Bonett 2002, not `ICC.Sample.Size`/Zou)|
|Diagnostic Se/Sp              |Se, prevalence, precision     |`presize::prec_sens`                          |No     |Buderer (1996)                    |✅ built (closed-form, not `presize`)|
|Single ROC AUC                |AUC, ratio, α, power          |`pROC::power.roc.test`                        |No     |Hanley & McNeil (1982)            |✅ built|
|Prediction model              |R²/C-stat, #params, prevalence|`pmsampsize`                                  |No     |Riley et al. (2019)               |✅ built|
|Bioequivalence (2×2)          |CV, GMR, BE limits            |`PowerTOST::sampleN.TOST`                     |No     |Diletti et al. (1991)             |✅ built (also replicate 2×2×4/2×3×3 designs; see below)|
|Equivalence/NI means          |margin, difference            |`PowerTOST`; `TrialSize`                      |No     |Julious (2004)                    |✅ built (raw-units `PowerTOST::sampleN.TOST`, not `TrialSize`)|
|Simon phase II                |p0, p1, α, β                  |`clinfun::ph2simon`                           |No     |Simon (1989)                      |✅ built|
|Pilot rule-of-thumb           |(none / expected effect)      |rule: n=12/arm                                |No     |Julious (2005)                    |✅ built|

-----

## Recommendations (staged build plan)

See `checklist_by_design.md` — the staged build plan (Stage 1–4) and caveats apply identically to both files and aren't duplicated here.
