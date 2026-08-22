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
- [ ] **[ADV]** Welch t (unequal variances) — SD1, SD2, ratio — `MESS::power_t_test` / simulation — GP: Partial
- [x] **[CORE]** Paired t — dz (mean & SD of differences) — `pwr::pwr.t.test(type="paired")` — GP: t → Means: two dependent (matched pairs) — *(implemented: Means → "Two paired means", `calc_means_paired()`)*
- [ ] **[ADV]** Point-biserial correlation — r — GP: t → Correlation: point biserial
- [ ] **[ADV]** Regression coefficient / linear bivariate slope — slope, SDx, SDy — GP: t → Linear bivariate regression

### z tests — G*Power **z** family

- [x] **[CORE]** Single proportion — h (or p vs p0) — `pwr::pwr.p.test`  — GP: Exact (binomial) / z — *(implemented: Proportions → "Single proportion vs. known/reference value", `calc_proportion_1s()`; the module also has a separate precision-based single-proportion design not in this row — see `checklist_by_design.md` §1)*
- [x] **[CORE]** Two proportions — h — `pwr::pwr.2p.test`, `pwr::pwr.2p2n.test` (unequal) — GP: z → Proportions: two independent groups — *(implemented: Proportions → "Two independent proportions", `calc_proportion_2s()`; equal-n only — `pwr.2p2n.test`'s unequal-n case not built)*
- [ ] **[ADV]** Logistic regression (simple/multiple) — OR, predictor distribution, R² with covariates — `WebPower::wp.logistic` — GP: z → Logistic regression (Faul 2009)
- [ ] **[ADV]** Poisson regression — rate ratio, exposure distribution — `WebPower::wp.poisson` — GP: z → Poisson regression (Faul 2009)

### F tests — G*Power **F** family

- [x] **[CORE]** One-way ANOVA — f, k groups — `pwr::pwr.anova.test` , `WebPower::wp.anova` — GP: F → ANOVA: fixed effects, omnibus — *(implemented: Means → "Three or more independent groups (one-way ANOVA)", `calc_means_anova()`, converts raw group means + SD to Cohen's f)*
- [ ] **[ADV]** Two-way / factorial ANOVA (main effects & interactions) — f, numerator df — GP: F → ANOVA: fixed effects, special
- [ ] **[ADV]** Repeated-measures ANOVA (between, within, interaction) — f, #measurements, correlation, nonsphericity ε — `WebPower::wp.rmanova` — GP: F → ANOVA: repeated measures
- [ ] **[ADV]** ANCOVA — f, #covariates, #groups — `WebPower::wp.rmanova`-family / GP: F → ANCOVA — nMaster
- [ ] **[ADV]** MANOVA (global & special effects, incl. Hotelling's T²) — GP: F → MANOVA
- [ ] **[ADV]** Mixed (split-plot) ANOVA — GP: F → ANOVA: repeated measures, within-between
- [x] **[CORE]** Multiple linear regression, R² deviation from zero — f² — `pwr::pwr.f2.test` — GP: F → Linear multiple regression: fixed model R² deviation from zero — *(implemented: new Multiple Regression module, `calc_regression_f2()`; backend verified against Cohen (1988) Exercise 9.1 p.424 (u=5, v=89, f2=0.1111 -> power=0.6736 exactly))*
- [ ] **[ADV]** Multiple regression, R² increase (hierarchical) — f² for added set — GP: F → …R² increase
- [ ] **[ADV]** Random-model multiple regression — GP: F (Faul 2009)
- [ ] **[ADV]** Planned contrasts; post-hoc comparisons with multiplicity adjustment

### χ² tests — G*Power **χ²** family

- [x] **[CORE]** Goodness of fit — w, df — `pwr::pwr.chisq.test` (`ES.w1`) — GP: χ² → Goodness-of-fit — *(implemented: Chi-Square Tests → "Goodness of fit", `calc_chisq_gof()`)*
- [x] **[CORE]** Test of independence / association (R×C) — w, df — `pwr::pwr.chisq.test` (`ES.w2`) — GP: χ² → contingency tables — *(implemented: Chi-Square Tests → "Test of independence", `calc_chisq_independence()`, dynamic R×C proportion-matrix UI (rows/cols 2-5); also cross-referenced as the "3+ group proportions" catalog entry)*
- [ ] **[ADV]** McNemar's (paired proportions) — OR, proportion discordant — GP: χ² → McNemar (exact)
- [ ] **[ADV]** Cochran's Q (k paired proportions)
- [ ] **[ADV]** Mantel–Haenszel (stratified OR) — PASS CMH
- [ ] **[ADV]** Cochran–Armitage trend — dose-response proportions — Epi Info StatCalc (χ² for trend)
- [ ] **[ADV]** Single-variance χ² test

### Exact tests — G*Power **Exact** family

- [x] **[CORE]** Fisher's exact (2×2) — p1, p2, allocation — GP: Exact → Proportions: inequality, two independent (Fisher) — *(implemented: new Exact Tests module's "Fisher's exact test" design, `calc_fisher_exact()` wrapping `Exact::power.exact.test(method="fisher")`, searching n1 upward for the first n1 whose exact power clears the target and stays there for 2 more steps -- exact-test power is non-monotonic in n (Chernick & Liu 2002), so a naive single-n search can land on a fragile spike. Verified: package's own doc example (p1=.15, p2=.60, n1=15, n2=30) reproduces power=0.8049 exactly; our search at ratio=2 finds n1=14 (achieved power 0.8195), one step earlier than the package's illustrative n1=15 -- a real instance of that non-monotonicity, not a discrepancy)*
- [x] **[CORE]** Binomial test (single proportion) — p, p0 — GP: Exact → Proportion: difference from constant — *(implemented: new Exact Tests module's "Binomial test" design, `calc_binomial_exact()`, searching n via base R's own `stats::binom.test()` (no external package needed) with the same stability-window search as Fisher's exact above. Verified: p0=.1, p1=.3, alpha=.05, power=.8 -> n=25, achieved exact power=0.8065, confirmed stable through n=27)*
- [ ] **[ADV]** Exact Poisson (rare event vs standard) — Epi Info StatCalc (Poisson)
- [ ] **[ADV]** Correlation, bivariate normal (exact) — r — GP: Exact → Correlation: bivariate normal
- [ ] **[ADV]** Proportions difference, unconditional exact — GP: Exact → Proportions: inequality, unconditional

### Correlation & regression

- [x] **[CORE]** Pearson correlation — r — `pwr::pwr.r.test` — GP: Exact/t → Correlation — *(implemented: Correlation module, `calc_correlation()`)*
- [ ] **[ADV]** Spearman / Kendall's tau — via ARE inflation of Pearson
- [ ] **[ADV]** Partial correlation — r, #controlled variables — GP: Yes
- [ ] **[ADV]** Compare two independent correlations — q (Fisher r-to-z) — `pwr` (manual) — GP: z → Correlations: two independent Pearson r's
- [ ] **[ADV]** Compare two dependent correlations (common / non-common index) — GP: z (Faul 2009)
- [ ] **[ADV]** Simple/multiple linear regression (fixed & random model) — see F family
- [ ] **[ADV]** Logistic regression (with/without covariate adjustment) — see z family — `WebPower::wp.logistic`
- [ ] **[ADV]** Poisson / negative binomial regression — `WebPower::wp.poisson`
- [ ] **[ADV]** Cox regression — HR, event proportion, covariate SD/correlation — `powerSurvEpi`
- [ ] **[ADV]** Ordinal (proportional odds) / multinomial regression — PASS proportional-odds; Whitehead (1993)

### Non-parametric tests (handled via ARE inflation / Noether / simulation)

- [ ] **[ADV]** Mann–Whitney U / Wilcoxon rank-sum — d then ×ARE (≈1.05 for normal) — GP: t → Means (Wilcoxon option) — nMaster; *Noether (1987)*
- [ ] **[ADV]** Wilcoxon signed-rank — GP: Yes (parent distribution options) — nMaster
- [ ] **[ADV]** Kruskal–Wallis — ANOVA n ×ARE / simulation
- [ ] **[ADV]** Friedman — RM-ANOVA basis / simulation
- [ ] **[ADV]** Sign test — `pwr`/exact binomial — nMaster
- [ ] **[ADV]** Jonckheere–Terpstra (ordered alternatives) — `clinfun` (odds ratios per group)
- [ ] **[ADV]** Kolmogorov–Smirnov; runs test; general permutation — simulation (`simr`/custom Monte Carlo)

### Survival tests

- [x] **[CORE]** Log-rank — Schoenfeld / Freedman / Lakatos — `powerSurvEpi`, `gsDesign::nSurv` — *(implemented: Log-Rank / Survival module, `calc_logrank()` wrapping `powerSurvEpi::ssizeCT.default()`; verified against Rosner (2006) Example 14.42 → nE=nC=294, total=588, exact match)*
- [ ] **[ADV]** Cox PH — `powerSurvEpi`
- [ ] **[ADV]** Gray's test (competing risks) — `powerCompRisk`
- [ ] **[ADV]** RMST comparison — `SSRMST`
- [ ] **[ADV]** Weighted log-rank (non-PH) — `npsurvSS`/simulation

### Agreement statistics

- [x] **[CORE]** Kappa — `kappaSize` — *(implemented: Agreement/Reliability → "Cohen's kappa", `calc_kappa()`, wraps `presize::prec_kappa()` → `kappaSize`)*
- [x] **[CORE]** ICC (forms 1,1 / 2,1 / 3,1 …) — `ICC.Sample.Size`, `presize::prec_icc` — *(implemented: Agreement/Reliability → "ICC", `calc_icc()`, wraps `presize::prec_icc()` (Bonett 2002); form-specific (1,1 vs 2,1 vs 3,1) distinctions per Zou 2012 not separately exposed)*
- [ ] **[ADV]** CCC; Bland–Altman LoA — `presize` — *(partially implemented: Bland-Altman LoA now built — Agreement/Reliability module's "Bland-Altman limits of agreement" design, `calc_agreement_bland_altman()` wrapping `presize::prec_lim_agree()`; Lin's CCC still not built — no lightweight verified package with a dedicated sample-size function identified yet)*

### Multiple-comparison procedures

- [ ] **[ADV]** Bonferroni-adjusted α → inflated n (wrap any calculator with α/m)
- [ ] **[ADV]** Holm; FDR / Benjamini–Hochberg adjusted sample size; family-wise error control — `ssize.fdr`

### Equivalence / non-inferiority test forms

- [x] **[CORE]** TOST for means — `PowerTOST`, `TOSTER::power_t_TOST` — *(implemented: Equivalence (TOST) module, `calc_tost_means()` wrapping `PowerTOST::sampleN.TOST(logscale=FALSE, design="parallel")`; verified against the package's own documented example → n=48, achieved power=0.815435)*
- [x] **[CORE]** TOST for proportions — `TOSTER`, `PowerTOST` — *(implemented: Equivalence (TOST) module's new "Two proportions" design, `calc_tost_proportions()` wrapping `epiR::epi.ssequb(type="equivalence")` rather than `TOSTER`/`PowerTOST` -- neither has a dedicated proportions-TOST function, but epiR's equivalence family covers it; verified against Machin/Campbell/Tan/Tan (2009) p.113 (Bennett et al. 1979 cryptococcal meningitis trial) -> n=166 total, exact textbook match)*
- [ ] **[ADV]** Non-inferiority margins for RR / OR / HR / difference — `TrialSize`, `SampleSize4ClinicalTrials`

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

- [ ] **[ADV]** O'Brien–Fleming / Pocock boundaries — `gsDesign`, `rpact`
- [ ] **[ADV]** Lan–DeMets alpha spending — `gsDesign`, `rpact`
- [ ] **[ADV]** Conditional power; futility boundaries; SSR — `gsDesign::ssrCP`, `condPower`

### Tests for variance / rates / counts

- [ ] **[ADV]** Single-variance & two-variance (F) tests
- [ ] **[ADV]** One-sample & two-sample Poisson rate — `epiR`, Epi Info StatCalc

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
|Single ROC AUC                |AUC, ratio, α, power          |`pROC::power.roc.test`                        |No     |Hanley & McNeil (1982)            |not built|
|Prediction model              |R²/C-stat, #params, prevalence|`pmsampsize`                                  |No     |Riley et al. (2019)               |not built|
|Bioequivalence (2×2)          |CV, GMR, BE limits            |`PowerTOST::sampleN.TOST`                     |No     |Diletti et al. (1991)             |not built|
|Equivalence/NI means          |margin, difference            |`PowerTOST`; `TrialSize`                      |No     |Julious (2004)                    |✅ built (raw-units `PowerTOST::sampleN.TOST`, not `TrialSize`)|
|Simon phase II                |p0, p1, α, β                  |`clinfun::ph2simon`                           |No     |Simon (1989)                      |✅ built|
|Pilot rule-of-thumb           |(none / expected effect)      |rule: n=12/arm                                |No     |Julious (2005)                    |✅ built|

-----

## Recommendations (staged build plan)

See `checklist_by_design.md` — the staged build plan (Stage 1–4) and caveats apply identically to both files and aren't duplicated here.
