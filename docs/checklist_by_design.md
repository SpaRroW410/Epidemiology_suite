# Sample Size Calculator — Master Checklist (by Study Design)

> **Status note (cross-referenced against the codebase 2026-08-20):** boxes below
> are ticked only where a live Shiny module already implements that exact
> calculator, with a short `*(implemented: ...)*` note pointing at the module.
> Where our implementation uses a different backend than the one this checklist
> names (closed-form formula instead of the suggested package, or vice versa),
> that's flagged explicitly rather than silently ticked — see
> `docs/SDD.md` §7 and the "Backend deviations" note at the end of this file.
> A handful of already-built calculators don't fit either file's row shape
> exactly (e.g. our Proportions module's *"single proportion vs. known
> value"* hypothesis test, and its optional finite-population correction);
> those are cross-referenced inline too.

Two complementary, copy-pasteable markdown files for your R Shiny sample size calculator. **File 1** is organized by study design (how a medical researcher thinks). **File 2** is organized by statistical test and explicitly mirrors G*Power's catalog, then extends beyond it. Save each block as its own `.md` file in the repository (e.g. `checklist_by_design.md` and `checklist_by_test.md`).

**How the two files relate:** every calculator should be reachable from *both* files — a researcher lands via File 1 ("I'm doing a case-control study"), a statistician via File 2 ("I'll run a Mann-Whitney U"). Cross-reference module IDs when you build them so the same Shiny module serves both entry points.

**Scope framing (verified):** G*Power organizes tests into five test families (Exact, F, t, χ², z) and offers five analysis types per test — a priori, post hoc, compromise, criterion, sensitivity — per Faul, Erdfelder, Lang & Buchner (2007, *Behavior Research Methods* 39:175–191) and Faul, Erdfelder, Buchner & Lang (2009, *Behavior Research Methods* 41:1149–1160). Commercial breadth for benchmarking: PASS covers "over 1200 statistical test and confidence interval scenarios" per NCSS.com (the PASS 2025 procedure-list page instead cites "over 680," so the figure is version-dependent); nQuery "includes calculations for over 1,000 sample sizes and power scenarios" per Statsols/Wikipedia. nMaster 2.0 (CMC Vellore) covers means (incl. ANCOVA, repeated measures), proportions, agreement (kappa, ICC), diagnostic tests, correlation/regression, survival (log-rank, Cox, exponential), cluster designs, equivalence/bioequivalence, epidemiological (cohort, matched/unmatched case-control) and clinical-trial designs, plus sign/Wilcoxon/Mann-Whitney tests.

-----

## ============================================================

## FILE 1 — STUDY-DESIGN-BASED CHECKLIST

## ============================================================

### Legend / How to use

- `- [ ]` = calculator not yet implemented; tick when the Shiny module is live.
- **[CORE]** = build for v1 (high-frequency in Indian community-medicine/public-health/clinical research). **[ADV]** = advanced/stretch for later phases.
- Each item lists: *scenario → typical inputs → R package/function → original citation*.
- Architecture note (already decided by you): one Shiny module per calculator, wrapping the named R package rather than reimplementing formulas; per-calculator help tab renders the formula + the cited original source.
- Where a calculator has no closed-form R package, fall back to **simulation** (`simr`, custom Monte Carlo) and flag it in the UI.

-----

### 1. Descriptive / Estimation studies

- [x] **[CORE]** Single proportion / prevalence — inputs: expected p, absolute (or relative) precision, confidence level, optional population size N (FPC) — `epiR::epi.sssimpleestb`,  `presize::prec_prop` — *Fleiss, Levin & Paik; Lwanga & Lemeshow (WHO 1991)* — *(implemented: Proportions → "Single proportion — precision-based", `calc_proportion_precision()`; backend is a closed-form Cochran/Naing-Winn-Rusli formula, not `presize::prec_prop`/`epiR` — see deviations note)*
- [x] **[CORE]** Single mean — inputs: SD, precision (CI half-width), confidence — `presize::prec_mean` — *Bland (2009) BMJ 339:b3985 (CI-width rationale)* — *(implemented: Means module's new "Single mean, precision-based" design, `calc_means_single_precision()` wrapping `epiR::epi.sssimpleestc()` rather than `presize::prec_mean` -- verified against epiR's own documented example, N=20, mean=75, sd=15, relative epsilon=0.20 -> n=4)*
- [x] **[CORE]** Incidence rate estimation — inputs: expected rate, person-time, precision — `presize::prec_rate` — *Rothman & Greenland, Modern Epidemiology* — *(implemented: new Incidence Rate module, `calc_rate_precision()` wrapping `presize::prec_rate()`; verified against presize's own documented example, rate=2.5, conf.width=2.243 -> 21 events, ~8.4 person-time)*
- [ ] **[ADV]** Ratio estimation (precision of RR / OR / rate ratio) — `presize::prec_riskratio`, `presize::prec_or`, `presize::prec_rateratio`
- [ ] **[CORE]** Precision / CI-width framework (Rothman–Greenland) — generic engine feeding many estimation modules
- [x] **[CORE]** Finite population correction — inputs: N, computed n → corrected n = n/(1+n/N) — *(implemented: inside `calc_proportion_precision()`'s optional `N` argument)*
- [ ] **[ADV]** Variance / SD estimation precision

### 2. Cross-sectional / Survey designs

- [x] **[CORE]** Simple random sample for a proportion — as §1 with survey framing — *(implemented: same module as §1's single-proportion precision calculator)*
- [ ] **[CORE]** Stratified sampling — inputs: strata sizes, within-stratum variances, allocation (proportional/Neyman)
- [ ] **[CORE]** Cluster / multistage with design effect — inputs: ICC (ρ), average cluster size m; DEFF = 1 + (m − 1)ρ; effective n = n×DEFF — *Kish; Killip et al.*
- [ ] **[ADV]** Complex/multistage survey (PPS) — DEFF depends on ρ and take b, not on number of PSUs (DHS WP30)
- [ ] **[ADV]** Lot Quality Assurance Sampling (LQAS) — inputs: upper/lower thresholds, decision rule, α/β — *Robertson & Valadez (2006); cluster-LQAS: Hedt-Gauthier et al. (2013) Emerg Themes Epidemiol 10:11*
- [ ] **[ADV]** Two-stage cluster survey (WHO EPI 30×7 / 30×30) — *Henderson & Sundaresan (1982)*
- [ ] **[ADV]** Capture–recapture — `Rcapture` (analysis); planning via WinPepi — *Chapman estimator*

### 3. Analytical observational studies

- [x] **[CORE]** Cohort / cross-sectional (RR, risk difference, incidence) — inputs: p0 (unexposed risk), RR or p1, ratio unexposed:exposed, power, conf — `epiR::epi.sscohortc` (count), `epiR::epi.sscohortt` (time) — *Kelsey et al.; Fleiss (OpenEpi methods)* — *(implemented: Cohort / RR module, `calc_cohort()`, wraps `epiR::epi.sscohortc()`; person-time variant `epi.sscohortt` not built)*
- [x] **[CORE]** Unmatched case-control — inputs: % controls exposed, OR (or % cases exposed), controls:cases ratio, power, conf — `epiR::epi.sscc`  — *Schlesselman (1982); Kelsey; Fleiss with/without correction (OpenEpi/Epi Info StatCalc)* — *(implemented: Case-Control → "Unmatched", `calc_case_control_unmatched()`, wraps `epiR::epi.sscc(method="unmatched")`)*
- [x] **[CORE]** Matched case-control 1:1 and 1:m — inputs: exposure prevalence in controls, OR, correlation of exposure, m controls/case — `epiR::epi.sscc(method="matched")` — *Dupont (1988); PS software (Dupont & Plummer)* — *(implemented: Case-Control → "Matched", `calc_case_control_matched()`, wraps `epiR::epi.sscc(method="matched")`)*
- [ ] **[ADV]** Frequency-matched design
- [ ] **[ADV]** Nested case-control / case-cohort — *Prentice; efficiency vs full cohort*
- [ ] **[ADV]** Case-crossover
- [ ] **[ADV]** Self-controlled case series — `SCCS`
- [ ] **[ADV]** Ecological studies (note confounding/aggregation caveats)
- [x] **[CORE]** Comparison of two incidence rates (person-time) — `epiR::epi.sscompc` — Epi Info Poisson — *(implemented: Incidence Rate module's new "Comparison of two rates" design, `calc_rate_comparison()` -- closed-form Demidenko (2007) Poisson-regression Wald-test formula (comparing two rates via person-time is algebraically Poisson regression with one binary predictor), not `epi.sscompc` (which is actually for continuous outcomes, a mismatch in this checklist's own suggestion). Verified against WebPower::wp.poisson()'s own documented example (rate_ref=2.798, rate_ratio=0.8938, prop_exposed=0.53 -> n=944) without taking a dependency on WebPower itself, whose Depends: (lme4, lavaan, dplyr, PearsonDS) are far heavier than this one formula needs)*

### 4. Diagnostic & screening studies

- [x] **[CORE]** Sensitivity / specificity given prevalence — inputs: expected Se (or Sp), disease prevalence, precision, total n — `presize::prec_sens`, `presize::prec_spec` — nMaster; *Buderer (1996)* — *(implemented: Diagnostic Accuracy → "precision-based", `calc_diagnostic_accuracy()`; backend is a closed-form Buderer formula, not `presize::prec_sens`/`prec_spec` — see deviations note. Module also has 3 designs beyond this checklist row: vs. known/reference value, two independent tests, two paired tests — see `checklist_by_test.md`'s Agreement/Diagnostic sections and `docs/SDD.md` §7)*
- [x] **[CORE]** PPV / NPV — inputs: Se, Sp, prevalence, precision — `presize` (derive from 2×2) — *easy near-term add: reuses the same Se/Sp/prevalence inputs already in the Diagnostic Accuracy module* — *(implemented: Diagnostic Accuracy module's new "Predictive values (PPV/NPV)" design, `calc_diagnostic_ppv_npv()` -- closed-form, extending Buderer's prevalence-adjustment logic (already used by this module's Se/Sp design) to PPV/NPV via Altman & Bland (1994)'s formulas; presize has no dedicated PPV/NPV function, confirmed by inspecting its full function list. Verified via a self-consistent worked example (sens=.9, spec=.85, prevalence=.2 -> PPV=0.60, NPV=0.9714, n=1230))*
- [x] **[ADV]** Likelihood ratios (LR+, LR−) — `presize::prec_lr` — *(implemented: Diagnostic Accuracy module's new "Likelihood ratios (LR+/LR-)" design, `calc_diagnostic_likelihood_ratio()` wrapping `presize::prec_pos_lr()`/`prec_neg_lr()`; verified against Simel, Samsa & Matchar (1991) Problems 1 (LR+ -> n=173) and 2 (LR- -> n=160, exact))*
- [x] **[CORE]** Single ROC AUC vs null (0.5) — inputs: expected AUC, allocation ratio neg:pos, α, power — `pROC::power.roc.test` — *Hanley & McNeil (1982) Radiology 143:29–36; Obuchowski (1994)* — *(implemented: new ROC / AUC module, `calc_roc_auc()` wrapping `pROC::power.roc.test()`; verified against pROC's own aSAH/S100B biomarker worked example, auc=0.73, alpha=0.05, power=0.95, kappa=1.7 → ncases=30, ncontrols=51, total=81, exact after ceiling)*
- [ ] **[ADV]** Compare two AUCs, paired or unpaired — inputs: AUC1, AUC2, correlation, allocation — `pROC::power.roc.test` — *Hanley & McNeil (1983, correlated); Obuchowski & McClish (1997) Stat Med 16:1529–1542*
- [ ] **[ADV]** Diagnostic odds ratio
- [ ] **[ADV]** Multi-reader multi-case (MRMC) — *Obuchowski & Rockette; Dorfman-Berbaum-Metz* (simulation/`iMRMC`)
- [ ] **[ADV]** Index-test vs reference-standard accuracy study

### 5. Agreement / reliability studies

- [x] **[CORE]** Cohen's kappa — inputs: expected κ, null κ, category proportions, #raters — `kappaSize` (binary/multinomial, 2–6 raters) — *Rotondi & Donner; Flack et al.* — *(implemented: Agreement/Reliability → "Cohen's kappa", `calc_kappa()`, wraps `presize::prec_kappa()` → `kappaSize`)*
- [ ] **[ADV]** Weighted kappa; Fleiss kappa (>2 raters) — `kappaSize` — *partially covered: our kappa calculator already supports 2-6 raters and 2-5 categories via the same `kappaSize::CIBinary/CI3Cats/CI4Cats/CI5Cats` backend (the multi-rater generalization), but this hasn't been separately tested/labeled for the >2-rater case, and weighted kappa (differential penalty for near-miss categories) is not covered at all — left unticked pending that*
- [x] **[CORE]** Intraclass correlation coefficient (ICC) — inputs: expected ICC, #raters/measurements, CI width or power — `ICC.Sample.Size` (*Zou 2012, Stat Med, doi:10.1002/sim.5466*), `presize::prec_icc` — *(implemented: Agreement/Reliability → "ICC", `calc_icc()`, wraps `presize::prec_icc()` / Bonett 2002 — a different formula from Zou (2012); see deviations note)*
- [x] **[ADV]** Bland–Altman limits of agreement — inputs: expected SD of differences, CI width — `presize::prec_lim_agree` — *Bland & Altman (1986)* — *(implemented: Agreement/Reliability module's new "Bland-Altman limits of agreement" design, `calc_agreement_bland_altman()`; verified against presize's own documented example, conf.width=0.1 -> n=4610)*
- [ ] **[ADV]** Lin's concordance correlation coefficient (CCC)
- [x] **[ADV]** Cronbach's alpha (internal consistency) — `presize::prec_cronb` — *(implemented: Agreement/Reliability module's new "Cronbach's alpha" design, `calc_agreement_cronbach()`; verified against presize's own documented example, k=5, calpha=0.7, conf.width=0.1 -> n=349, exact)*
- [ ] **[ADV]** Test-retest / inter- & intra-rater reliability — WinPepi PAIRSetc

### 6. Clinical trials

- [x] **[CORE]** Parallel 2-arm superiority — means: `stats::power.t.test`, `pwr::pwr.t.test`; proportions: `stats::power.prop.test`, `pwr::pwr.2p.test` — OpenEpi, nMaster — *Cohen (1988)* — *(implemented: Means → "Two independent means", Proportions → "Two independent proportions" — covered across two outcome-type modules rather than a single unified "Clinical Trials" module)*
- [ ] **[ADV]** Multi-arm superiority (with multiplicity)
- [x] **[CORE]** Non-inferiority (means / proportions) — inputs: NI margin, expected difference, one-sided α — `SampleSize4ClinicalTrials`, `TrialSize` — *(implemented: new Non-Inferiority module, `calc_noninferiority_means()`/`calc_noninferiority_proportions()` wrapping `epiR::epi.ssninfc()`/`epi.ssninfb()` rather than the suggested packages; verified against Chow/Shao/Wang (2008) p.61-62 (means -> n=100) and p.90 (proportions -> n=50), both exact textbook matches)*
- [x] **[CORE]** Equivalence (TOST) — inputs: equivalence bounds, expected difference — `PowerTOST`, `TOSTER` — *(implemented: Equivalence (TOST) module, `calc_tost_means()` wrapping `PowerTOST::sampleN.TOST(logscale=FALSE, design="parallel")`; verified against the package's own documented example (mean_diff=-0.05, margin=0.2, sd=0.2 → n=48, achieved power=0.815435))*
- [ ] **[ADV]** Bioequivalence crossover 2×2 & replicate (2×2×4, 2×3×3), RSABE/ABEL — inputs: CV (within-subject), GMR (T/R ratio), BE limits 0.80–1.25, design — `PowerTOST::sampleN.TOST` — *Diletti, Hauschke & Steinijans (1991); Owen's Q exact*
- [ ] **[ADV]** Cluster-randomized trials (ICC/DEFF, variable cluster size) — `clusterPower`, `CRTSize` — *Donner & Klar*
- [ ] **[ADV]** Stepped-wedge CRT — `swCRTdesign`, `SWSamp`, `clusterPower` — *Hussey & Hughes (2007) Contemp Clin Trials 28:182–191; Hemming & Taljaard (2016) J Clin Epidemiol 69:137–146*
- [ ] **[ADV]** Factorial designs (main effects ± interaction)
- [ ] **[CORE]** Crossover trials (2×2, continuous) — `PowerTOST`, nMaster
- [ ] **[ADV]** N-of-1 trials
- [x] **[CORE]** Pilot / feasibility (rules of thumb) — Julious (2005) *Pharmaceutical Statistics* 4:287–291: "the recommendation is a sample size of 12 per group… justifications… based on rationale about feasibility; precision about the mean and variance; and regulatory considerations"; stepped rules Whitehead et al. (2016); Lancaster et al. (2004) — PASS "Pilot Study Rules of Thumb" (flat vs stepped, Machin et al. 2018) — *(implemented: Pilot / Feasibility module, `calc_pilot_sd_precision()` — flat 12/arm rule-of-thumb banner plus an interactive CI-for-SD precision tool; verified n=12 → 95% CI multipliers 0.708x–1.698x, the standard Julious 2005 illustration)*
- [ ] **[ADV]** Dose-finding / phase I (3+3, CRM) — `dfcrm`, `bcrm`
- [x] **[ADV]** Phase II single-arm — Simon (1989) *Controlled Clinical Trials* 10:1–10 two-stage designs "optimal in the sense that the expected sample size is minimized if the regimen has low activity subject to constraints upon… type 1 and type 2 errors"; also A'Hern, Gehan, Fleming — `clinfun::ph2simon`, `ph2mult`, `gen2stage` — *(implemented: Simon Two-Stage module, `calc_simon()` wrapping `clinfun::ph2simon()`, reporting both minimax and optimal designs; verified against the classic textbook example pu=0.2, pa=0.4, alpha=beta=0.1 → minimax n=36 (r1=3,n1=19,r=10), optimal n=37 (r1=3,n1=17,r=10), matching `ph2simon`'s own printed output exactly)*
- [ ] **[ADV]** Group sequential & adaptive designs — `gsDesign`, `rpact` — *Jennison & Turnbull; O'Brien-Fleming; Pocock; Lan-DeMets alpha spending*
- [ ] **[ADV]** Blinded/unblinded sample size re-estimation — `gsDesign::ssrCP`, `spass`
- [ ] **[ADV]** Platform / basket / umbrella trials (simulation)

### 7. Survival / time-to-event studies

- [x] **[CORE]** Log-rank test — inputs: HR (or median survivals), accrual + follow-up, allocation, α, power → **required number of events** then total N — `powerSurvEpi::ssizeCT`, `gsDesign::nSurv` — *Schoenfeld (1981) Biometrika 68:316–319; Schoenfeld (1983) Biometrics 39:499–503; Freedman (1982) Stat Med 1:121–129* — *(implemented: Log-Rank / Survival module, `calc_logrank()` wrapping `powerSurvEpi::ssizeCT.default()` (Freedman 1982 method, cumulative event probabilities); verified against Rosner (2006) Example 14.42 — pE=0.3707, pC=0.4890, HR=0.7 → nE=nC=294, total=588, exact match)*
- [ ] **[CORE]** Cox proportional hazards (binary & non-binary covariate) — `powerSurvEpi::ssizeEpi`, `powerSurvEpi::powerEpi` — *Schoenfeld (1983); Latouche et al. (2004) Stat Med 23:3263–3274*
- [ ] **[ADV]** Exponential survival (parametric) — `gsDesign::nSurv` — *Lachin & Foulkes (1986) Biometrics 42:507–519; Rubinstein, Gail & Santner (1981)*
- [ ] **[ADV]** Accrual + follow-up designs (non-uniform entry) — *Lakatos (1988) * — `gsDesign::nSurv`, `npsurvSS`
- [ ] **[ADV]** Competing risks — *Latouche et al. (2004)*; Gray's test — `powerCompRisk`
- [ ] **[ADV]** Restricted mean survival time (RMST) — `SSRMST` — *Uno et al.; Yung & Liu*
- [ ] **[ADV]** Non-proportional hazards / weighted log-rank — *Yung & Liu (2020)*
- [ ] **[ADV]** One-sample survival vs historical control

### 8. Prediction / prognostic model studies

- [x] **[CORE]** Model development — binary, continuous, or time-to-event — inputs: #candidate predictor parameters, anticipated R²/C-statistic, outcome prevalence or rate, mean follow-up — `pmsampsize` — *Riley et al. Part I continuous (2019 Stat Med 38:1262–1275, doi:10.1002/sim.7993), Part II binary/time-to-event (2019 Stat Med 38:1276–1296, doi:10.1002/sim.7992), BMJ 2020;368:m441.* Part I criteria (verbatim): the minimum n should give "(i) small optimism… global shrinkage factor of ≥0.9; (ii) small absolute difference of ≤0.05 in the apparent and adjusted R²; (iii) precise estimation… of the residual standard deviation; and (iv) precise estimation of the mean predicted outcome value." — *(implemented: new Prediction Model module, `calc_prediction_binary()`/`calc_prediction_continuous()`/`calc_prediction_survival()` wrapping `pmsampsize::pmsampsize()` (binary supports either Cox-Snell R² or a reported C-statistic, converted via Riley et al. 2021 Stat Med 40:859–864's seeded simulation); verified against the papers' own worked examples exactly — binary (24 params, prevalence=0.174, csrsquared=0.288) → n=662, events=116; continuous (25 params, intercept=1.9, sd=0.6, rsquared=0.2) → n=918; survival (30 params, rate=0.065, timepoint=2, meanfup=2.07, csrsquared=0.051) → n=5143, events=692)*
- [ ] **[ADV]** External validation — binary outcome — `pmvalsampsize` — *Riley et al. (2021) Stat Med 40:4230–4251*
- [ ] **[ADV]** External validation — time-to-event — *Riley et al. (2022)  Stat Med*
- [ ] **[ADV]** Model updating / recalibration; ML model sample size; calibration-assessment sample size

### 9. Genetic / omics & high-dimensional

- [ ] **[ADV]** GWAS / candidate-gene association — inputs: MAF, OR/GRR, disease prevalence, genetic model, genome-wide α (e.g. 5×10⁻⁸) — `genpwr` (*Moore, Jacobson & Fingerlin 2019, Hum Hered 84:256–271*), Quanto, `Haplin` (family triads)
- [ ] **[ADV]** Gene–environment interaction — `genpwr`, Quanto
- [ ] **[ADV]** Microarray / RNA-seq differential expression, FDR-controlled — `ssize`, `RNASeqPower`, `PROPER`
- [ ] **[ADV]** Multiple-testing (FDR/Bonferroni) sample-size inflation

### 10. Psychometric / questionnaire / scale development

- [ ] **[ADV]** EFA/CFA subjects-per-item rules of thumb
- [ ] **[ADV]** CFA/SEM via RMSEA — inputs: df (from model), null vs alternative RMSEA, α, power — `semPower` (*Moshagen & Bader 2024, Behavior Research Methods 56:2901–2922*), `WebPower::wp.sem.rmsea`, `semTools::findRMSEAsamplesize` — *MacCallum, Browne & Sugawara (1996) Psychological Methods 1:130–149*
- [ ] **[ADV]** IRT calibration; validation studies

### 11. Qualitative & mixed methods (non-formula — acknowledge, don't fake precision)

- [ ] **[ADV]** Saturation-based guidance — *Guest, Bunce & Johnson (2006) Field Methods 18:59–82: "saturation occurred within the first twelve interviews, although basic elements for metathemes were present as early as six interviews."*
- [ ] **[ADV]** Information power — *Malterud, Siersma & Guassora (2016) Qual Health Res 26:1753–1760* (n depends on aim, sample specificity, theory, dialogue quality, analysis strategy)
- [ ] **[ADV]** Purposive/theoretical sampling narrative guidance (present as guidance panel, no numeric output)

### 12. Health economics / outcomes

- [ ] **[ADV]** Cost-effectiveness study sample size (net-benefit framework)
- [ ] **[ADV]** Value of information (EVPI/EVSI) — `voi`

### 13. Pharmacovigilance / surveillance

- [x] **[CORE]** Rule of three — inputs: n → upper 95% bound on unseen AE ≈ 3/n; or n to detect ≥1 event given incidence — *Hanley & Lippman-Hand (1983)* — *(implemented: new Rule of Three module, `calc_rule_of_three_bound()` + `calc_rule_of_three_n()`, closed-form; verified against the classic n=30 illustration -> approx 3/30=0.0999, exact 0.0950)*
- [ ] **[ADV]** Detecting rare adverse events (binomial/Poisson); signal detection thresholds

### 14. Laboratory / animal / preclinical

- [ ] **[ADV]** Resource equation method (E between 10–20) — *Mead; Charan & Kantharia*
- [ ] **[ADV]** Animal-study rank tests — `clinfun` (*Heller 2006, K-sample rank test, Lehmann alternative*)
- [ ] **[ADV]** Method-comparison studies (Deming/Passing-Bablok) — `presize` LoA

### 15. Meta-analysis

- [ ] **[ADV]** Trial sequential analysis / (diversity-adjusted) optimal information size — inputs: control event rate, RRR/effect, α, β, heterogeneity D² — `RTSA` — *Wetterslev, Thorlund, Brok & Gluud (2008) J Clin Epidemiol 61:64–75; Wetterslev et al. (2017) BMC Med Res Methodol 17:39; Lan-DeMets boundaries*
- [ ] **[ADV]** Power / effective sample size for (network) meta-analysis — `metapower`

### 16. Real-world evidence / advanced observational

- [ ] **[ADV]** Propensity-score-matched designs (account for matching efficiency)
- [ ] **[ADV]** RWE database studies (large-N, precision-driven)
- [ ] **[ADV]** Subgroup & interaction testing — note the **"4× rule"**: detecting an interaction of the same magnitude as a main effect needs ~4× the sample size (Brookes et al. 2004)

### 17. Repeated measures / longitudinal designs

- [ ] **[ADV]** Linear mixed models, rate of change — inputs: visit times, random intercept/slope variances, residual variance, slope difference δ — `longpower::lmmpower` (methods: diggle, liuliang, edland, hu) — *Diggle, Heagerty, Liang & Zeger (2002) Analysis of Longitudinal Data 2nd ed.; Ard & Edland (2011) J Alzheimers Dis 26(S3):369–377* (package: *Iddi & Donohue 2022, R Journal 14(1):264–282, doi:10.32614/RJ-2022-022*)
- [ ] **[ADV]** MMRM (mixed model repeated measures) with missing data — inputs: correlation matrix or AR(1) ρ, per-visit retention, SD, allocation, δ — `longpower::power.mmrm`, `longpower::power.mmrm.ar1` — *Lu, Luo & Chen (2008) Int J Biostatistics 4(1), doi:10.2202/1557-4679.1098*
- [ ] **[ADV]** Multilevel (2- and 3-level, with dropout) — inputs: n1 time points, n2 subjects/cluster, n3 clusters, ICCs, slope variance ratio, dropout — `powerlmm::study_parameters` + `get_power` (+ `shiny_powerlmm`) — *extends Galbraith & Marschner (2002) Control Clin Trials 23:257–271*
- [ ] **[ADV]** GEE-based (marginal models) — `longpower::liu.liang.linear.power` — *Liu & Liang (1997) Biometrics 53:937–947; Rochon (1998) Stat Med 17:1643–1658 (Wald χ², damped-exponential correlation — no confirmed dedicated CRAN package, use Liu-Liang route or custom code)*
- [ ] **[ADV]** Time-varying exposure — inputs: exposure ICC, per-time prevalence, CS/damped-exponential correlation — **OPTITXS / OPTITXS.r** (Yale CMIPS; not on CRAN) — *Basagaña & Spiegelman (2010) Stat Med 29:181–192 (rates of change); Basagaña, Liao & Spiegelman (2011) Stat Methods Med Res 20:471–487 (main effect)* — flag: using time-invariant formulas overestimates required N
- [ ] **[ADV]** Growth curve models (simulation) — `simr`

-----

## Recommendations (staged build plan)

**Stage 1 — v1 CORE release (target ~25 modules).** Build everything tagged **[CORE]** in both files. These map almost 1:1 to what OpenEpi, Epi Info StatCalc, nMaster and the `pwr`/`epiR`/`presize`/`pROC` packages already cover, so wrapping is fast and validation is easy (cross-check outputs against OpenEpi/G*Power). Prioritize, in order: single proportion, single mean, two means (t), two proportions, unmatched case-control, cohort/RR, one-way ANOVA, correlation, chi-square (GoF + independence), diagnostic Se/Sp, ICC, kappa, log-rank, Simon two-stage, pilot rules-of-thumb, TOST equivalence. This set answers the large majority of Indian community-medicine/public-health protocol needs.

**Stage 1.5 — study design identification wizard, guided-tree half (done).** Between finishing Stage 1 CORE and starting Stage 2, built the "Which calculator?" guided decision tree (`docs/design_identification_algorithm.md` Stages 1-5, `R/home/design_tree.R`, `R/home/design_wizard.R`) — deliberately sequenced here rather than at the very end, so every Stage-1 module is reachable by a guided Q&A (not just by name) before the backlog of unbuilt designs grows large enough to make "not yet built" the most common answer. Routes to built modules now; every unbuilt terminal still names its intended module/backend/citation so the tree doesn't need reworking as Stage 2+ modules land — they just flip existing terminals from "not built" to a live catalog jump. This is only half of the source document, though — its Stage 0 (free-text/PICO parsing) is deferred to **Stage 5** below, not bundled in here.

**Stage 2 — analytical depth (in progress).** Add the G*Power F-family completeness (factorial/RM-ANOVA, ANCOVA, MANOVA, regression R² increase), the full correlation/regression suite (`WebPower`), matched case-control variants, ROC comparison (`pROC`), Bland-Altman/CCC/Cronbach (`presize`), and prediction-model development (`pmsampsize`) — the latter is increasingly demanded by journals and is a differentiator versus OpenEpi. Batch 1 (done): Cronbach's alpha and Bland-Altman limits of agreement (Agreement/Reliability module), likelihood ratios LR+/LR- (Diagnostic Accuracy module) — all lightweight `presize` wraps needing no new dependencies. Batch 2 (done): new Prediction Model module (binary/continuous/survival, `pmsampsize`) and new ROC/AUC module (single-AUC-vs-chance, `pROC`) — both packages evaluated for dependency weight before adoption (pmsampsize: `Depends: R (>= 2.1)` only; pROC: `Imports: methods, Rcpp` only). Comparing two AUCs (`pROC`'s two-curve case) was deliberately left open — it requires either fitted `roc` objects on real data or a full set of binormal parameters (A1,B1,A2,B2,rn,ra, optional FPR bounds), not a simple summary-statistic input suitable for this app. Still open: F-family ANOVA completeness, `WebPower`-based regression/correlation extensions, matched case-control variants, compare-two-AUCs, and Lin's CCC.

**Stage 3 — advanced/trial designs.** Cluster-randomized and stepped-wedge (`clusterPower`/`swCRTdesign`), group-sequential/adaptive (`gsDesign`/`rpact`), survival extensions (RMST, competing risks), bioequivalence replicate designs (`PowerTOST`), longitudinal/MMRM (`longpower`/`powerlmm`).

**Post-hoc/achieved-power module — deliberately last, possibly cut.** Originally planned as part of Stage 3 (reuse each Stage-1/2 module's engine, solving for power instead of N). Decision (2026-08-21): build this only after everything else above is done, not alongside it — and reconsider whether to build it at all once the app's calculator surface is large, given the methodological controversy noted in the Caveats section below.

**Stage 4 — niche/simulation & non-formula.** Genetic (`genpwr`), SEM (`semPower`), trial sequential analysis (`RTSA`), simulation engine (`simr`) for designs with no closed form, and guidance-only panels for qualitative (Guest; Malterud) and resource-equation animal studies.

**Stage 5 — study design identification wizard, free-text half.** After Stage 4, come back and build Stage 0 of `docs/design_identification_algorithm.md`: free-text/PICO input parsing (keyword heuristics and/or an LLM parsing layer that extracts P/I-E/C/O/T slots and pre-fills the guided wizard's answers) instead of requiring every question to be clicked through by hand. Deliberately last, not alongside Stage 1.5 — the guided tree only pays off once most of its terminals point at live modules rather than "not yet built" notes, so free-text convenience is worth adding once that's mostly true, not before. Keep the tree itself deterministic per the source document: the parsing layer only ever populates slots/answers, it never chooses the final module on its own.

**Benchmarks that should change the plan:**

- If a wrapped package is unmaintained or its results diverge from G*Power/PASS by >1 unit on validation cases, either pin a version or reimplement the single formula (your "wrap not reimplement" rule should bend here).
- If usage analytics show heavy traffic to any **[ADV]** module (e.g. stepped-wedge, prediction models), promote it into the next release ahead of remaining CORE items.
- For any calculator lacking a CRAN package (LQAS cluster, time-varying exposure/OPTITXS, MRMC ROC, platform trials), default to a documented simulation module and label it clearly as approximate.

## Caveats

- **Version-dependent counts.** The "PASS >1200 / >680" and "nQuery >1000" figures vary by product version and page; treat them as ballpark benchmarks, not fixed targets. Your value proposition is free + open-source + Indian-context help tabs + original citations, not raw procedure count.
- **G*Power menu paths** are given from the published manuals/papers; verify the exact string in G*Power 3.1.9.7 when you write each help tab, as some wording differs between distribution-based and design-based entry.
- **Non-parametric power** in G*Power and most R packages uses asymptotic relative efficiency (ARE) inflation or parent-distribution assumptions, not exact rank-test power; state the method and its assumptions in-app. Simulation is the honest fallback.
- **`epiR` / OpenEpi** report several methods (Kelsey, Fleiss with/without continuity correction) that give different n for the same case-control inputs; expose the method choice and cite each, as OpenEpi does.
- **Bioequivalence** inputs must be entered as ratios (0.80–1.25), not percentages, in `PowerTOST`; `sampleN.TOST` returns *total* (even) N, not per-arm — a common user error to guard against in the UI.
- **`pwr` returns per-group n** for two-sample tests; multiply by #arms and adjust for dropout — surface an explicit "inflate for attrition" field in every trial module.
- **Rochon (1998) GEE** and **Basagaña/Spiegelman time-varying-exposure** methods have **no confirmed dedicated CRAN package**; implement via `longpower` (Liu-Liang) or the authors' standalone OPTITXS program respectively, and flag as such.
- **`genpwr` CRAN status:** the package page notes issues needing fixing before an early-2026 deadline; confirm it still installs before committing to it, or wrap Quanto logic instead.
- **Qualitative "sample size"** items are guidance, not formulas — render them as advisory panels (information power dimensions; Guest's 6–12 finding) with no numeric "N" output, to avoid false precision.
- **Post-hoc power** on observed effects is statistically controversial (it is a deterministic function of the p-value); your planned achieved-power module should compute power for *pre-specified* meaningful effect sizes and warn against "observed-effect" post-hoc power in the help tab.

## Backend deviations from this checklist (already-built calculators)

- **Single proportion precision / Simple random sample for a proportion** — this checklist names `epiR::epi.sssimpleestb` / `presize::prec_prop`; the app uses a closed-form Cochran (1977) formula instead (same math, verified against the well-known n=385 default), since it predates this checklist and no CRAN package was substituted in afterward. Candidate for reconciliation in Stage 1 cleanup — see the open question in the chat reply.
- **Diagnostic Se/Sp precision-based** — this checklist names `presize::prec_sens`/`prec_spec`; the app uses a closed-form Buderer (1996) formula instead, verified exactly against the source article's own worked example (n=1383). Same reconciliation question applies.
- **ICC** — this checklist names `ICC.Sample.Size` (Zou 2012); the app wraps `presize::prec_icc()` (Bonett 2002) instead — a different but also well-established formula for the same problem, already the plan's own alternate suggestion in the Agreement/reliability row. No change needed unless Zou (2012)'s method is specifically wanted.
