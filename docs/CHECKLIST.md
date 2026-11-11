# Checklist

Every item of the project, done or open, in one list. **This is the only place where status is kept.**

- **Done:** tick the item (`- [x]`) and add a line to `NEWS.md` under the current date.
- **New:** add it to its section with the next free number of that section's ID; an ID is never reused or renumbered.
  A new design or decision also goes into `docs/SDD.md`.
- **Then** run `Rscript tools/docs/build_pending.R`: it rewrites `docs/PENDING.md` (the open items only, by the same sections).
  `tests/testthat/test-docs_pending.R` fails when PENDING is out of date, so the two cannot drift apart.

Key: `- [x]` done, `- [ ]` open. **[owner]** only the repository owner can do it; **[blocked]** waits on something outside the code
(a paper, a package, an account), with what would unblock it; **[paused]** stopped by an owner decision; **[optional]** nothing promised.
Calculator lines give the design as the app's catalog names it, the source of its formula and, where the help page names one, the package
function it is computed with or tested against; the help page in the app has the full reference and the worked example. History: `NEWS.md`
and `docs/archive/` (the old roadmap, plan, to-do list and checklists, frozen on 6 November 2026).

## 1. Owner steps (OWN)

Steps only the owner can take that belong to no section below; the section items marked **[owner]** are listed with their sections.

- [x] **OWN-01** Licence GPL-3, name `epidemiologysuite`, scope and distribution decisions D1-D5 (28 Sep 2026; `SDD.md`, section 17).
- [x] **OWN-02** Repository renamed `Epidemiology_suite`, version 1.0.0, Zenodo DOI, ORCID (30 Oct - 3 Nov 2026).
- [x] **OWN-03** Automatic deletion of merged branches (owner setting, November 2026).
- [ ] **OWN-04** **[owner]** Decision D6: when to reopen the paused items (PRED, section 2).

## 2. Calculators (Plan: Sample Size and Analyze)

All 215 designs of the app's catalog are built (6 Nov 2026); the open items are designs not built yet, or the open half of a built one.
The guide's end points for designs not built yet are tested to be listed here (`tests/testthat/test-design_tree.R`).

### Plan: Effect Sizes (ES)

- [x] **ES-01** Effect size: Cohen's d and Hedges' g from two means (SDs or variances) -- Cohen 1988
- [x] **ES-02** Effect size: Cohen's d from a t statistic -- Cohen 1988; `stats::t.test`
- [x] **ES-03** Effect size: d for paired measurements (from the SDs and their correlation) -- Cohen 1988
- [x] **ES-04** Effect size: Cohen's f for several means (from means and SD, eta-squared or F) -- Cohen 1988
- [x] **ES-05** Effect size: odds ratio, risk ratio, risk difference and Cohen's h from two proportions (also case-control) -- Cohen 1988;
  `pwr::ES.h`
- [x] **ES-06** Effect size: Cohen's w and Cramer's V for a chi-square test -- Cohen 1988; `pwr::ES.w1`
- [x] **ES-07** Effect size: hazard ratio from median survival or survival probabilities
- [x] **ES-08** Effect size: convert between d, r, odds ratio, R-squared and f-squared -- Chinn 2000
- [x] **ES-09** Effect size: mean and SD from a median and interquartile range -- Wan et al. 2014
- [x] **ES-10** Effect size: phi from a table of matched case-control pairs -- Dupont 1988

### Plan: Descriptive & Estimation (DESC)

- [x] **DESC-01** Single proportion -- precision-based (no reference value) -- Cochran 1977; `epiR::epi.sssimpleestb`
- [x] **DESC-02** Single proportion vs. known/reference value -- Cohen 1988; `pwr::pwr.p.test`, `pwr::ES.h`
- [x] **DESC-03** Two independent proportions -- Cohen 1988; `pwr::pwr.2p.test`, `pwr::ES.h`
- [x] **DESC-04** Post-hoc pairwise comparison of proportions (Bonferroni-adjusted) -- Chow et al. 2003;
  `TrialSize::OneWayANOVA.PairwiseComparison`
- [x] **DESC-05** Single mean -- precision-based (no reference value) -- Levy & Lemeshow 1999; `epiR::epi.sssimpleestc`
- [x] **DESC-06** Single mean vs. known value -- Cohen 1988; `pwr::pwr.t.test`
- [x] **DESC-07** Two independent means -- Cohen 1988; `pwr::pwr.t.test`
- [x] **DESC-08** Two independent means, unequal group sizes -- Cohen 1988; `pwr::pwr.t2n.test`
- [x] **DESC-09** Two independent means, unequal variances (Welch's t-test) -- Julious 2004
- [x] **DESC-10** Two paired means (e.g. pre-post) -- Cohen 1988; `pwr::pwr.t.test`
- [x] **DESC-11** Three or more group means -- Cohen 1988; `pwr::pwr.anova.test`
- [x] **DESC-12** Planned linear contrast among k group means -- Chow et al. 2003; `TrialSize::Dose.Response.Linear`
- [x] **DESC-13** Post-hoc pairwise comparison of means (Bonferroni-adjusted) -- Chow et al. 2003; `TrialSize::OneWayANOVA.pairwise`
- [x] **DESC-14** Incidence rate, precision-based -- Barker 2002; `presize::prec_rate`
- [x] **DESC-15** Comparison of two incidence rates -- Demidenko 2007; `WebPower::wp.poisson`
- [x] **DESC-16** Poisson regression, continuous predictor -- Signorini 1991; `powerMediation::sizePoisson`
- [x] **DESC-17** Comparison of two negative binomial rates -- Zhu & Lakkis 2014; `MKpower::power.nb.test`
- [x] **DESC-18** Risk ratio -- precision-based -- Koopman 1984; `presize::prec_riskratio`
- [x] **DESC-19** Odds ratio -- precision-based -- Gart & Zweifel 1967; `presize::prec_or`
- [x] **DESC-20** Rate ratio -- precision-based -- Rothman & Greenland 2018; `presize::prec_rateratio`

### Plan: Survey & Cross-Sectional (SVY)

- [x] **SVY-01** Two-sample mark-recapture (Chapman-Petersen), precision-based -- Chapman 1951
- [x] **SVY-02** Cluster / multistage sampling -- design effect (DEFF) -- Kish 1965
- [x] **SVY-03** Cluster designs -- calculate the design effect from the variance between clusters -- Kish 1965
- [x] **SVY-04** Cluster / multistage sampling -- design effect, variable cluster size -- Donner & Klar 2000
- [x] **SVY-05** Cluster survey precision (WHO EPI-style, proportion) -- Levy & Lemeshow 1999; `epiR::epi.ssclus2estb`
- [x] **SVY-06** Two-stage PPS sampling -- optimal cluster allocation (take b) -- Hansen et al. 1953
- [x] **SVY-07** Stratified sampling -- total size and per-stratum allocation -- Cochran 1977
- [x] **SVY-08** Lot Quality Assurance Sampling (LQAS) -- Robertson & Valadez 1984

- [ ] **SVY-09** **[blocked]** LQAS, open half: cluster-LQAS (heterogeneity-adjusted). *Unblock:* a citable formula with a worked example.
### Plan: Observational Studies (OBS)

- [x] **OBS-01** Unmatched case-control study -- Dupont 1988; `epiR::epi.sscc`
- [x] **OBS-02** Matched case-control study (1:1 or 1:m) -- Dupont 1988; `epiR::epi.sscc`
- [x] **OBS-03** Matched case-control study, measured exposure (1:1 or 1:m) -- Lachin 2008; `powerSurvEpi::powerConLogistic.bin`,
  `survival::clogit`
- [x] **OBS-04** Case-crossover study -- Dupont 1988; `epiR::epi.sscc`
- [x] **OBS-05** Nested case-control study -- Lachin 2008; `powerSurvEpi::powerConLogistic.bin`, `survival::clogit`
- [x] **OBS-06** Case-cohort study -- Cai & Zeng 2004
- [x] **OBS-07** Cohort study (relative risk) -- Kelsey et al. 1986; `epiR::epi.sscohortc`
- [x] **OBS-08** Self-controlled case series (SCCS) -- Musonda et al. 2006
- [x] **OBS-09** Ecological study guidance (group-level design, no formula) -- Morgenstern 1995

- [ ] **OBS-10** **[blocked]** Propensity-score-matched designs (matching efficiency): `MatchIt` / `Matching` are analysis-only and the
  efficiency depends on each data set's overlap. *Unblock:* a published planning heuristic with a worked example.
- [ ] **OBS-11** **[blocked]** Time-varying exposure (OPTITXS; Basagana & Spiegelman 2010, 2011): not on CRAN, papers not reachable.
  *Unblock:* paper access or the OPTITXS source.
- [ ] **OBS-12** Interrupted time series (segmented regression), reached by FIND-16: sample size or power. Candidate source, not read:
  Zhang, Wagner & Ross-Degnan 2011 (simulation-based power).
- [ ] **OBS-13** Controlled before-after / difference-in-differences, reached by FIND-16: sample size. No source found yet.
- [ ] **OBS-14** Regression discontinuity, reached by FIND-16: sample size. Candidate sources, not read: Schochet 2009; Cattaneo,
  Titiunik & Vazquez-Bare 2019.
- [ ] **OBS-15** Mendelian randomisation, reached by FIND-16: power. Candidate sources, not read: Brion, Shakhbazov & Visscher 2013;
  Burgess 2014.
### Plan: Diagnostic & Screening (DX)

- [x] **DX-01** Sensitivity & specificity -- precision-based (no reference value) -- Buderer 1996
- [x] **DX-02** Sensitivity & specificity vs. known/reference value -- Akoglu 2022
- [x] **DX-03** Two independent (unpaired) diagnostic tests -- Casagrande & Pike 1978
- [x] **DX-04** Two paired diagnostic tests (same subjects) -- Connor 1987
- [x] **DX-05** Predictive values (PPV/NPV), precision-based -- Altman & Bland 1994
- [x] **DX-06** Likelihood ratios (LR+/LR-), precision-based -- Simel et al. 1991; `presize::prec_lr`, `presize::prec_pos_lr`
- [x] **DX-07** Diagnostic odds ratio (DOR) -- Glas et al. 2003
- [x] **DX-08** Single ROC AUC vs. chance (0.5) -- Obuchowski et al. 2004; `pROC::power.roc.test`
- [x] **DX-09** Compare two correlated (paired) ROC AUCs

- [ ] **DX-10** **[blocked]** Multi-reader multi-case (MRMC) studies, Obuchowski-Rockette / DBM: `iMRMC`'s Roe-Metz model (6 fixed
  effects, 18 variance components) is too large for one batch. *Unblock:* a multi-batch effort with `iMRMC` as the reference.
- [ ] **DX-11** **[blocked]** ROC comparison, open half: Unpaired AUCs (two independent AUCs; `pROC::power.roc.test` does not support
  them). *Unblock:* a separately verified formula.
### Plan: Agreement & Reliability (AGR)

- [x] **AGR-01** Cohen's kappa (categorical agreement, no gold standard) -- Donner & Eliasziw 1987; `presize::prec_kappa`
- [x] **AGR-02** Intraclass correlation - ICC (continuous agreement, no gold standard) -- Bonett 2002; `presize::prec_icc`
- [x] **AGR-03** Cronbach's alpha (scale internal consistency) -- Bonett & Wright 2015; `presize::prec_cronb`
- [x] **AGR-04** Bland-Altman limits of agreement -- Bland & Altman 1986; `presize::prec_lim_agree`
- [x] **AGR-05** Lin's concordance correlation coefficient (CCC) -- Lin 1989; `epiR::epi.ccc`

- [ ] **AGR-06** **[blocked]** Method comparison by Deming / Passing-Bablok regression: `deming`, `mcr`, `MethComp` are analysis-only; the
  literature is simulation-based. *Unblock:* a citable simulation protocol (e.g. Linnet) to reproduce.
- [ ] **AGR-07** Agreement, open half: weighted kappa.
### Plan: Several Measurements per Patient (UNIT)

- [x] **UNIT-01** Several units per patient (eyes, lesions, patches), same treatment in all of a patient's units -- two means -- Donner &
  Klar 2000; `clusterPower::cpa.normal`
- [x] **UNIT-02** Several units per patient (eyes, lesions, patches), same treatment in all of a patient's units -- two proportions --
  Donner & Klar 2000; `clusterPower::cpa.binary`
- [x] **UNIT-03** Both treatments in every patient (split-face, split-body, one eye per arm) -- two means -- Cohen 1988

- [ ] **UNIT-04** Eyes / lesions per patient, open half: binary outcome with both treatments in each patient (clustered McNemar; needs a
  checked source), a patient-by-treatment variance part for the split designs, unequal allocation, different numbers of units in the two
  arms, and the analysis side (Rosner-Milton / Obuchowski tests).
### Plan: Clinical Trials (TRIAL)

- [x] **TRIAL-01** Stepped-wedge cluster-randomized trial (continuous outcome) -- Hooper et al. 2016
- [x] **TRIAL-02** Subgroup / interaction testing sample-size inflation (4x rule) -- Brookes et al. 2004
- [x] **TRIAL-03** Cluster-randomized trial, continuous outcome (Monte Carlo LMM) -- Bolker et al. 2009; `lme4::lmer`
- [x] **TRIAL-04** Cluster-randomized trial, binary outcome (Monte Carlo GLMM) -- Bolker et al. 2009; `lme4::glmer`
- [x] **TRIAL-05** Growth curve model, group difference in slope (Monte Carlo LMM) -- Green & MacLeod 2016; `lme4::lmer`, `simr::doTest`
- [x] **TRIAL-06** 2x2 crossover trial (continuous outcome) -- test for a difference -- Chow et al. 2003;
  `TrialSize::TwoSampleCrossOver.Equality`
- [x] **TRIAL-07** Pilot / feasibility study -- Julious 2005
- [x] **TRIAL-08** Simon two-stage Phase II design -- Simon 1989; `clinfun::ph2simon`
- [x] **TRIAL-09** Equivalence of two means (TOST) -- Phillips 1990; `PowerTOST::sampleN.TOST`
- [x] **TRIAL-10** Equivalence of two proportions (TOST) -- Bennett et al. 1979; `epiR::epi.ssequb`
- [x] **TRIAL-11** Pharmacokinetic bioequivalence crossover (TOST) -- Phillips 1990; `PowerTOST::sampleN.TOST`
- [x] **TRIAL-12** Bioequivalence crossover, expected power (assurance) -- Julious & Owen 2006; `PowerTOST::expsampleN.TOST`
- [x] **TRIAL-13** Non-inferiority trial, two means -- Chow et al. 2008; `epiR::epi.ssninfc`
- [x] **TRIAL-14** Non-inferiority trial, two proportions -- Chow et al. 2008; `epiR::epi.ssninfb`
- [x] **TRIAL-15** Non-inferiority trial, odds ratio -- Chow et al. 2003; `TrialSize::RelativeRisk.NIS`
- [x] **TRIAL-16** Non-inferiority trial, hazard ratio (Cox PH) -- Chow et al. 2003; `TrialSize::Cox.NIS`
- [x] **TRIAL-17** Group sequential design, continuous outcome -- Wang & Tsiatis 1987; `clinfun::gsdesign.normal`
- [x] **TRIAL-18** Group sequential design, binary outcome -- Casagrande et al. 1978; `clinfun::gsdesign.binomial`
- [x] **TRIAL-19** Group sequential design, time-to-event outcome -- Schoenfeld 1983; `clinfun::gsdesign.survival`
- [x] **TRIAL-20** Lan-DeMets alpha-spending design, continuous outcome (2 looks) -- Lan & DeMets 1983
- [x] **TRIAL-21** Trial sequential analysis, risk ratio
- [x] **TRIAL-22** Trial sequential analysis, odds ratio
- [x] **TRIAL-23** Trial sequential analysis, risk difference
- [x] **TRIAL-24** Trial sequential analysis, mean difference

- [ ] **TRIAL-25** **[blocked]** Dose-finding / phase I (3+3, CRM): the output is operating characteristics at a fixed n. *Unblock:* an
  operating-characteristics simulator, verified against `dfcrm::crmsim()`.
- [ ] **TRIAL-26** **[blocked]** Platform / basket / umbrella trials. *Unblock:* the same simulator framework, or a multi-arm
  group-sequential design verified against `rpact`.
- [ ] **TRIAL-27** **[blocked]** N-of-1 trials: `nof1` / `Nof1` not reachable, no single accepted formula. *Unblock:* a citable
  period-count formula with a worked example.
- [ ] **TRIAL-28** Stepped-wedge, open half: binary outcome (`clusterPower::cpa.sw.binary()` is a numerical GEE procedure, no closed form).
- [ ] **TRIAL-29** Group sequential / Lan-DeMets, open half: the spending-function design with 3+ looks and for binary / survival
  outcomes; blinded sample-size re-estimation (`spass`-style).
- [ ] **TRIAL-30** Trial sequential analysis, open half: the heterogeneity-adjusted (random-effects / diversity-adjusted) information size.
- [ ] **TRIAL-31** **[blocked]** Non-inferiority, open half: a true relative-risk-scale margin (`TrialSize::RelativeRisk.NIS()` is
  odds-ratio based, so it ships as the OR design). *Unblock:* a verified RR-scale source.
- [ ] **TRIAL-32** Bioequivalence, open half: reference-scaled designs for highly variable drugs (RSABE / ABEL); simulation-based in
  `PowerTOST`, not wired in.
### Plan: Survival Analysis (SURV)

- [x] **SURV-01** Log-rank test (comparing two survival curves) -- Freedman 1982; `powerSurvEpi::ssizeCT.default`
- [x] **SURV-02** Cox proportional-hazards regression -- binary covariate -- Latouche et al. 2004; `powerSurvEpi::ssizeEpi.default`
- [x] **SURV-03** Cox proportional-hazards regression -- continuous covariate -- Hsieh & Lavori 2000; `powerSurvEpi::ssizeEpiCont.default`
- [x] **SURV-04** Stratified log-rank test, exponential survival -- Palta & Amini 1985; `powerSurvEpi::ssize.stratify`
- [x] **SURV-05** Log-rank test with accrual, follow-up & noncompliance -- Peterson & George 1993; `Hmisc::cpower`
- [x] **SURV-06** Weighted log-rank test under non-proportional hazards (Monte Carlo) -- Harrington & Fleming 1982; `survival::survdiff`
- [x] **SURV-07** Joint cause-specific/any-cause hazard test (competing risks) -- Yang & Fung 2017; `powerCompRisk::powerCompRisk`,
  `mvtnorm::pmvnorm`
- [x] **SURV-08** Restricted mean survival time (RMST) comparison -- Uno et al. 2014; `SSRMST::ssrmst`, `survRM2::rmst2`

- [ ] **SURV-09** **[blocked]** One-sample survival vs. a historical control (Finkelstein et al. 2003; Schmidt et al. 2015): the sources
  with the equations were not reachable. *Unblock:* the paper or the NCSS / PASS manual, and one worked example.
### Plan: Prediction Models (PRED)

- [x] **PRED-01** Prediction model development -- binary outcome -- Riley et al. 2019; `pmsampsize::pmsampsize`
- [x] **PRED-02** Prediction model development -- continuous outcome -- Riley et al. 2019; `pmsampsize::pmsampsize`
- [x] **PRED-03** Prediction model development -- survival outcome -- Riley et al. 2020; `pmsampsize::pmsampsize`
- [x] **PRED-04** Prediction model external validation -- binary outcome -- Riley et al. 2021; `pmvalsampsize::pmvalsampsize`,
  `pROC::ci.auc`

- [ ] **PRED-05** **[paused]** External validation, time-to-event (Riley et al. 2022): paused by the owner pending paper access
  (`pmvalsampsize` may have a time-to-event branch worth checking first). Reopen: decision D6.
- [ ] **PRED-06** **[paused]** Model updating / recalibration; machine-learning model sample size; calibration-assessment sample size:
  paused by the owner, same reason.
### Plan: Surveillance (SURVL)

- [x] **SURVL-01** Upper bound on an unseen event rate (rule of three) -- Hanley & Lippman-Hand 1983
- [x] **SURVL-02** Sample size to detect at least one event -- Hanley & Lippman-Hand 1983
- [x] **SURVL-03** Detect at least one case, imperfect test (finite population) -- Cannon 2001

### Plan: Preclinical / Animal Studies (PRE)

- [x] **PRE-01** Resource equation method (animal studies) -- Mead 1988

### Plan: Qualitative / Mixed Methods (QUAL)

- [x] **QUAL-01** Qualitative / mixed methods sample size guidance -- Guest et al. 2006

### Plan: Psychometrics / Scale Development (PSY)

- [x] **PSY-01** EFA/CFA subjects-per-item sample size guidance -- Costello & Osborne 2005
- [x] **PSY-02** CFA/SEM test of close fit via RMSEA -- MacCallum et al. 1996
- [x] **PSY-03** IRT item calibration -- minimum sample size by model type -- Linacre 1994

### Plan: Health Economics / Value of Information (HE)

- [x] **HE-01** Value of information (EVPI) for a cost-effectiveness decision
- [x] **HE-02** Value of sample information (EVSI) and optimal sample size (ENBS)

- [ ] **HE-03** Value of information, open half: multi-parameter EVPPI and non-normal outcomes (only the single-parameter, known-SD case
  ships).
### Plan: Study Planning Tools (PLAN)

- [x] **PLAN-01** Inflate a sample size for attrition and non-response (one or several stages)
- [x] **PLAN-02** Inflate each arm for different expected losses
- [x] **PLAN-03** Inflate a sample size for drop-out and drop-in (non-compliance) -- Lachin 1981
- [x] **PLAN-04** Randomization list: permuted blocks (reproducible from a seed) -- Altman & Bland 1999
- [x] **PLAN-05** Randomization list: permuted blocks within strata (sites, prognostic groups) -- Altman & Bland 1999
- [x] **PLAN-06** Randomization list: simple (unrestricted) randomization -- Altman & Bland 1999

### Plan: Survey & Field Tools (FIELD)

- [x] **FIELD-01** Survey sample selection: simple random sample from a list (reproducible) -- Madow 1949
- [x] **FIELD-02** Survey sample selection: systematic sample, every k-th unit from a random start -- Madow 1949
- [x] **FIELD-03** Survey sample selection: PPS systematic (probability proportional to size), e.g. choosing clusters -- Madow 1949;
  `sampling::UPsystematic`
- [x] **FIELD-04** WHO EPI cluster survey (30 x 7): choose the clusters from a village list -- Madow 1949
- [x] **FIELD-05** Survey design weights and nonresponse adjustment by weighting class -- Madow 1949
- [x] **FIELD-06** Effective sample size and design effect of a set of survey weights (Kish) -- Kish 1965

### Plan: Infectious Disease Models (IDM)

- [x] **IDM-01** Herd-immunity threshold and vaccination coverage needed (with imperfect vaccine efficacy) -- Kermack & McKendrick 1927;
  `stats::uniroot`
- [x] **IDM-02** SIR / SEIR epidemic simulation with vaccination (final size, peak, infections averted) -- Kermack & McKendrick 1927;
  `deSolve::ode`
- [x] **IDM-03** R0 from an epidemic growth rate (doubling time) or from a final attack fraction -- Kermack & McKendrick 1927

### Plan: General Statistical Tests (GEN)

- [x] **GEN-01** Two paired/dependent proportions (e.g. before-after, matched pairs) -- Chow et al. 2003; `TrialSize::McNemar.Test`
- [x] **GEN-02** Three or more group proportions -- Cohen 1988; `pwr::ES.w2`, `pwr::pwr.chisq.test`
- [x] **GEN-03** Pearson correlation
- [x] **GEN-04** Compare two independent correlations -- Cohen 1988
- [x] **GEN-05** Compare two dependent (overlapping) correlations -- Steiger 1980
- [x] **GEN-06** Point-biserial correlation -- Cohen 1988; `pwr::pwr.t.test`
- [x] **GEN-07** Simple linear regression slope -- Kutner et al. 2005; `pwr::pwr.r.test`
- [x] **GEN-08** Partial correlation (controlling for k covariates) -- Cohen 1988; `pwr::pwr.r.test`
- [x] **GEN-09** Spearman rank correlation (ARE-inflated) -- Hotelling & Pabst 1936; `pwr::pwr.r.test`
- [x] **GEN-10** Chi-square goodness of fit -- Cohen 1988; `pwr::ES.w1`, `pwr::pwr.chisq.test`
- [x] **GEN-11** Chi-square test of independence / association (R x C table) -- Cohen 1988; `pwr::ES.w2`, `pwr::pwr.chisq.test`
- [x] **GEN-12** McNemar's test (paired proportions) -- Chow et al. 2003; `TrialSize::McNemar.Test`
- [x] **GEN-13** Mantel-Haenszel test (stratified proportions) -- Chow et al. 2003; `TrialSize::Propensity.Score.strata`,
  `TrialSize::Propensity.Score.nostrata`
- [x] **GEN-14** Cochran-Armitage trend test (dose-response) -- Chow et al. 2003; `TrialSize::Cochran.Armitage.Trend`
- [x] **GEN-15** Cochran's Q test (k >= 3 paired/repeated binary measurements) -- Cochran 1950; `rstatix::cochran_qtest`
- [x] **GEN-16** Longitudinal group-slope-difference test (GEE/GLS, Liu & Liang) -- Liu & Liang 1997; `longpower::liu.liang.linear.power`
- [x] **GEN-17** Longitudinal group-slope difference (Diggle et al.) -- Diggle et al. 2002; `longpower::diggle.linear.power`
- [x] **GEN-18** Longitudinal group-slope difference (Ard & Edland) -- Ard & Edland 2011; `longpower::edland.linear.power`
- [x] **GEN-19** Longitudinal group-slope difference with dropout (Hu, Mackey & Thomas) -- Mackey & Thomas 2021;
  `longpower::hu.mackey.thomas.linear.power`
- [x] **GEN-20** Multilevel model, two-level (subjects, repeated measures)
- [x] **GEN-21** Multilevel model, three-level (subjects nested in clusters)
- [x] **GEN-22** Required number of studies (k) for a planned meta-analysis -- Hedges & Pigott 2004
- [x] **GEN-23** MMRM with dropout, AR(1) correlation (Lu, Luo & Chen) -- Luo & Chen 2008; `longpower::power.mmrm.ar1`
- [x] **GEN-24** Factorial ANOVA / ANCOVA (general F-test) -- Cohen 1988; `pwr::pwr.f2.test`
- [x] **GEN-25** Logistic regression -- binary predictor -- Hsieh et al. 1998; `powerMediation::SSizeLogisticBin`
- [x] **GEN-26** Logistic regression -- continuous predictor -- Hsieh et al. 1998; `powerMediation::SSizeLogisticCon`
- [x] **GEN-27** Ordinal (proportional odds) regression, two groups -- Whitehead 1993; `Hmisc::posamsize`
- [x] **GEN-28** Multiple logistic regression, covariate-adjusted -- binary predictor -- Hsieh et al. 1998;
  `powerMediation::SSizeLogisticBin`
- [x] **GEN-29** Multiple logistic regression, covariate-adjusted -- continuous predictor -- Hsieh et al. 1998;
  `powerMediation::SSizeLogisticCon`
- [x] **GEN-30** Repeated-measures ANOVA -- between-subjects effect -- Cohen 1988; `WebPower::wp.rmanova`
- [x] **GEN-31** Repeated-measures ANOVA -- within-subjects effect -- Cohen 1988; `WebPower::wp.rmanova`
- [x] **GEN-32** Wilcoxon rank-sum test (Mann-Whitney U)
- [x] **GEN-33** Wilcoxon signed-rank test (one sample / paired)
- [x] **GEN-34** Kendall's tau (nonparametric association)
- [x] **GEN-35** Kruskal-Wallis test (k independent groups) -- Hodges & Lehmann 1956; `pwr::pwr.anova.test`
- [x] **GEN-36** Jonckheere-Terpstra test (ordered alternatives)
- [x] **GEN-37** Friedman test (k related/repeated measurements) -- Zimmerman & Zumbo 1993
- [x] **GEN-38** Kolmogorov-Smirnov test (two independent samples, Monte Carlo)
- [x] **GEN-39** Wald-Wolfowitz runs test (two independent samples, Monte Carlo)
- [x] **GEN-40** Animal/preclinical K-sample rank test (Lehmann alternative, Monte Carlo)
- [x] **GEN-41** Mixed (split-plot) ANOVA -- group x time interaction -- Cohen 1988; `WebPower::wp.rmanova`
- [x] **GEN-42** Binomial test, single proportion (exact) -- Chernick & Liu 2002; `stats::binom.test`
- [x] **GEN-43** Fisher's exact test, two independent proportions -- Calhoun 2002; `Exact::power.exact.test`
- [x] **GEN-44** Boschloo's exact test, two independent proportions (unconditional) -- Boschloo 1970; `Exact::power.exact.test`
- [x] **GEN-45** Exact Poisson test, single rate vs. reference -- Chernick & Liu 2002; `stats::poisson.test`
- [x] **GEN-46** Sign test (paired data / one-sample median)
- [x] **GEN-47** Multiple linear regression, R-squared deviation from zero -- Cohen 1988; `pwr::pwr.f2.test`
- [x] **GEN-48** Hierarchical multiple regression, R-squared increase -- Cohen 1988; `pwr::pwr.f2.test`
- [x] **GEN-49** Single-variance test (vs. a reference SD) -- Rosner 2015
- [x] **GEN-50** Two-variance test (compare two groups) -- Rosner 2015
- [x] **GEN-51** Precision-based SD estimation (CI width, no hypothesis test) -- Rosner 2015
- [x] **GEN-52** Multiplicity-adjusted: one proportion vs. reference
- [x] **GEN-53** Multiplicity-adjusted: two independent proportions
- [x] **GEN-54** Multiplicity-adjusted: one mean vs. reference
- [x] **GEN-55** Multiplicity-adjusted: two independent means
- [x] **GEN-56** Multiplicity-adjusted: two independent means, FDR (Benjamini-Hochberg)-controlled
- [x] **GEN-57** Multiplicity-adjusted: two-sample microarray/genomics, FDR-controlled (exact) -- Liu & Hwang 2007
- [x] **GEN-58** Multi-arm trial vs. common control (Dunnett-adjusted) -- Dunnett 1955; `mvtnorm::qmvt`
- [x] **GEN-59** Two-group Hotelling's T-squared test (MANOVA, two groups) -- Rencher 2002
- [x] **GEN-60** Bayesian assurance, two-arm proportions trial (log odds ratio) -- Spiegelhalter & Freedman 1986; `Hmisc::gbayes2`
- [x] **GEN-61** Bayes Factor Design Analysis, two-sample means -- Schoenbrodt & Wagenmakers 2018; `BayesFactor::ttestBF`

- [ ] **GEN-62** **[blocked]** GWAS / candidate-gene association: `genpwr` / `Haplin` are numerical-MLE engines. *Unblock:* a multi-batch
  effort with `genpwr` as the reference.
- [ ] **GEN-63** **[blocked]** Gene-environment interaction: same engine as GWAS.
- [ ] **GEN-64** **[blocked]** Microarray / RNA-seq differential expression (`ssize`, `RNASeqPower`, `PROPER`, Bioconductor only); partly
  served by the exact Liu & Hwang FDR design (GEN-57). *Unblock:* Bioconductor access.
- [ ] **GEN-65** **[blocked]** Random-model multiple regression (Gatsonis & Sampson 1989): no R implementation. *Unblock:* paper access,
  checked against G*Power's random-model output.
- [ ] **GEN-66** **[blocked]** Exact bivariate-normal correlation test (Fisher's exact distribution of r). *Unblock:* G*Power's worked
  values from a citable table.
- [ ] **GEN-67** **[optional]** General permutation-test power: no general formula; out of scope unless a specific statistic is named (KS
  and runs tests are covered).
- [ ] **GEN-68** **[blocked]** Average coverage criterion / HPD interval width (Joseph & Belisle): `BayesianPower` implements a different
  method; partly served by Bayesian assurance and BFDA. *Unblock:* paper access or an implementation to verify against.
- [ ] **GEN-69** Meta-analysis power, open half: Network meta-analysis (no verified closed form yet).
- [ ] **GEN-70** Multilevel 2- / 3-level, open half: with dropout (`powerlmm`'s missing-data calculation).
- [ ] **GEN-71** MMRM, open half: general missing-data patterns beyond the AR(1) / dropout design.
- [ ] **GEN-72** GEE marginal models, open half: the damped-exponential correlation.
- [ ] **GEN-73** MANOVA, open half: the global test for k > 2 groups and special-effect contrasts.
- [ ] **GEN-74** Two dependent correlations, open half: the non-common-index case.
- [ ] **GEN-75** Ordinal / multinomial regression, open half: the nominal (multinomial) model.
- [ ] **GEN-76** Multiplicity, open half: Holm's step-down as its own design (no single planning alpha; needs simulation).
- [ ] **GEN-77** Multi-arm vs. common control, open half: Dunnett for binary outcomes (means only; the guide falls back to Bonferroni /
  Sidak).
### Analyze: From summary counts (AN)

- [x] **AN-01** Compare two proportions: difference, risk ratio, odds ratio (several interval methods) -- Newcombe 1998;
  `DescTools::BinomDiffCI`, `DescTools::BinomRatioCI`
- [x] **AN-02** Compare two means from summary statistics: difference, variance ratio, Cohen's d -- Welch 1947
- [x] **AN-03** Direct standardization: age-standardized rates, with a comparison of two groups -- Fay & Feuer 1997; `epiR::epi.directadj`
- [x] **AN-04** Indirect standardization: expected events from reference rates, and the SMR -- Liddell 1984; `stats::poisson.test`,
  `DescTools::PoissonCI`
- [x] **AN-05** Standardized mortality (morbidity) ratio from observed and expected events -- Liddell 1984; `stats::poisson.test`,
  `DescTools::PoissonCI`
- [x] **AN-06** Paired binary data: McNemar's test and matched-pair odds ratio (from counts) -- McNemar 1947; `stats::mcnemar.test`
- [x] **AN-07** Agreement between two raters or tests: Cohen's kappa (from a table) -- Cohen 1960; `DescTools::CohenKappa`,
  `epiR::epi.kappa`
- [x] **AN-08** Trend in proportions across ordered groups: chi-square for trend -- Cochran 1954; `stats::prop.trend.test`
- [x] **AN-09** Confidence interval for an incidence rate (events per person-time) -- Garwood 1936; `epiR::epi.conf`
- [x] **AN-10** Compare two rates: rate ratio, rate difference, attributable fractions (person-time) -- Kirkwood & Sterne 2003;
  `epiR::epi.2by2`
- [x] **AN-11** Rates in several strata: Mantel-Haenszel rate ratio and rate difference (person-time) -- Rothman & Boice 1979;
  `epiR::epi.2by2`
- [x] **AN-12** Vaccine efficacy from cases and participants (attack rates): 1 - risk ratio -- Orenstein et al. 1985; `epiR::epi.2by2`
- [x] **AN-13** Vaccine efficacy from cases and person-time (incidence rates): 1 - rate ratio -- Orenstein et al. 1985
- [x] **AN-14** Vaccine effectiveness from a case-control or test-negative study: 1 - odds ratio -- Orenstein et al. 1985
- [x] **AN-15** Stratified 2x2 tables: Mantel-Haenszel adjusted OR, RR, RD (cohort / trial) -- Mantel & Haenszel 1959; `epiR::epi.2by2`,
  `DescTools::BreslowDayTest`
- [x] **AN-16** Stratified 2x2 tables: Mantel-Haenszel adjusted odds ratio (case-control) -- Mantel & Haenszel 1959; `epiR::epi.2by2`,
  `DescTools::BreslowDayTest`
- [x] **AN-17** Confidence interval for a proportion (Wilson, exact, Agresti-Coull, Jeffreys, mid-P, Wald) -- Wilson et al. 1927;
  `epiR::epi.conf`
- [x] **AN-18** Confidence interval for a mean and a standard deviation (from n, mean, SD) -- Rosner
- [x] **AN-19** Analyze a diagnostic test from a 2x2 table (sensitivity, specificity, PPV, NPV) -- Clopper & Pearson 1934; `epiR::epi.tests`
- [x] **AN-20** Combine diagnostic tests: serial and parallel testing (2-6 tests) -- Vacek 1985
- [x] **AN-21** Analyze a 2x2 table: cohort / trial (risk ratio, risk difference) -- Katz et al. 1978; `epiR::epi.2by2`
- [x] **AN-22** Analyze a 2x2 table: cross-sectional (prevalence ratio) -- Katz et al. 1978; `epiR::epi.2by2`
- [x] **AN-23** Analyze a 2x2 table: case-control (odds ratio) -- Katz et al. 1978; `epiR::epi.2by2`

### Analyze: Outbreaks and surveillance (ANO)

- [x] **ANO-01** Outbreak attack rate (cases / population at risk) with confidence intervals -- `epiR::epi.conf`
- [x] **ANO-02** Outbreak investigation: exposure-specific attack rates and risk ratios (food-specific table)
- [x] **ANO-03** Secondary attack rate among contacts of cases
- [x] **ANO-04** Case fatality: crude and among resolved cases, with confidence intervals
- [x] **ANO-05** Aberration detection in a series of counts: EARS C1, C2, C3 -- Hutwagner et al. 2003; `surveillance::earsC`
- [x] **ANO-06** Aberration detection in a series of counts: CUSUM (normal or Poisson) -- Hutwagner et al. 2003; `spc::xcusum.arl`

## 3. Finding a calculator: the guide, search and Find tab (FIND)

- [x] **FIND-01** The guide ("Which calculator?"): a decision tree from the research question to the design and calculator, every built
  design reachable, a test that every end point opens a real calculator or is listed in this checklist (28 Sep 2026).
- [x] **FIND-02** Free-text reader: a description of the study is read for design, outcome and matching words and walks the tree as far as
  it can (`R/design_free_text.R`).
- [x] **FIND-03** Search box on Home and in the navbar, over every built design by name and description (29 Oct 2026).
- [x] **FIND-04** The Find tab: the guide and the browse lists (by design, by test) moved out of Home (1 Nov 2026).
- [x] **FIND-05** The guide says when nothing in a description was recognised, and how to rephrase (3 Nov 2026).
- [x] **FIND-06** Research questions phrased by topic: knowledge-attitude-practice, awareness, utilization reach a survey estimate;
  "determinants / risk factors of X" offer four candidate designs (survey, case-control, cohort, prediction model); the last step points to
  the association's own sample size and, for a place, to cluster sampling (4 Nov 2026).
- [x] **FIND-07** Routes for a cohort with ordered or scaled exposure, a case-control with categorical or ordered exposure (4 Nov 2026), and
  a matched case-control with a measured exposure, 1:1 or 1:m (5 Nov 2026).
- [x] **FIND-08** Glossary of 43 terms with info tips in the guide (4 Nov 2026).
- [ ] **FIND-09** **[owner]** A list of 50-100 real research questions / thesis titles (community medicine, public health) to test the
  reader against.
- [ ] **FIND-10** A test battery of those questions with the route each should take; the hit rate before and after each change.
- [ ] **FIND-11** More phrasings once the list is in: "effect / effectiveness / impact of" without a design word (trial or
  quasi-experimental: ask), "association between" (ask which design), "incidence / follow-up", "survival / time to", "accuracy / screening".
- [ ] **FIND-12** Ask instead of guessing when a phrase fits several designs (offer two or three starting points).
- [ ] **FIND-13** A guide that asks for each objective of a study in turn (the first step, buttons to the association calculators after a
  determinants question, is done).
- [ ] **FIND-14** **[optional]** A language-model reader, only by a separate decision (no API, nothing sent anywhere in the browser
  version). Not now: decision F1 (6 Nov 2026) keeps the reader deterministic.
- [x] **FIND-15** The owner's routing material (drafted with Gemini, shared from Google Drive) stored in `docs/find_routing/` with a
  review: the tree and guardrails summarised, the problems found, its 46 MeSH headings checked against NLM (4 do not exist or are
  misnamed); decisions F1-F4 (6 Nov 2026).
- [x] **FIND-16** New branches merged into the guide (F2): literature reviews (with and without meta-analysis, scoping, network, umbrella,
  qualitative evidence synthesis), mixed methods (explanatory, exploratory, convergent, embedded), the five qualitative approaches,
  quasi-experiments (controlled before-after / difference-in-differences, interrupted time series, regression discontinuity, single-arm
  pre-post), ecological snapshot or time trend, case report and case series, Mendelian randomisation. Every end point opens a calculator
  or names its open item; `test-design_tree.R` covers them. Built 6 Nov 2026.
- [x] **FIND-17** Who assigned the intervention: the study team (trial or quasi-experiment), or someone else such as a programme or a
  policy (a natural experiment, studied from routine data by interrupted time series, difference-in-differences or regression
  discontinuity). The source tree reaches quasi-experiments only when the team assigns. Built 6 Nov 2026 (two answers at "who determines",
  both to the quasi-experimental question).
- [x] **FIND-18** A study state asked one question at a time: each answer known or missing, with the words that set it; the guide asks the
  first missing question that blocks the route; a later answer that contradicts an earlier one is shown and asked about, never replaced
  silently. Built 6 Nov 2026: the guide was already one question at a time; each pre-filled answer now shows the words that set it, and a
  description that states two answers of "who determines" outright stops there and names both (`.free_text_conflicts` takes more
  questions).
- [x] **FIND-19** Warnings that ask, never silent changes: a harmful exposure proposed for assignment (suggest an observational design);
  group-level data with an individual-level question (ecological fallacy, with the two ways out: individual data or a group-level
  question); a rare outcome or long latency (case-control, nested case-control); existing records with a prospective design. Built 6 Nov
  2026, plus an assigned intervention in existing data.
- [x] **FIND-20** The keyword reader fills the new questions (F1): existing records, registries or national surveys (secondary data);
  review, qualitative and mixed-methods words; "we will assign / randomise"; group-level data; Mendelian randomisation only from
  "Mendelian randomi[sz]ation" or "genetic instrument" (not "variant"). Each rule gets cases in the FIND-10 battery. Built 6 Nov 2026; the
  cases are in `test-design_free_text.R` until the FIND-10 battery exists.
- [x] **FIND-21** A design card at the guide's end points (F3): fallback design and what it costs, three threats to validity with
  mitigations, reporting guideline, effect measure, workflow; from the registry text, edited; each statement cites a source checked for it
  (SRC-06) or carries a warning sign whose hover reads "Suggestion only -- no confirmed source". Built 7 Nov 2026 (`R/design_cards.R`): 35
  cards (reviews, qualitative approaches, mixed methods, trials, quasi-experiments, observational and descriptive designs, Mendelian
  randomisation), shown by the end point's own design or by the answer that decided the design; the registry's factorial row has no end
  point in the guide yet.
- [x] **FIND-22** A PubMed search builder (F4): the design's filter from a published validated filter where one exists (for example the
  Cochrane highly sensitive search strategy for randomised trials), otherwise marked "simple filter, not validated"; the user's concepts
  as `[tiab]` terms plus the MeSH headings they choose; the four wrong headings of the source corrected. Built 8 Nov 2026
  (`R/pubmed_search.R`), under the design card at each end point: Cochrane Boxes 3.a / 3.b (Handbook 6.5 technical supplement,
  section 3.6.1, read in full) for trials; PubMed Clinical Queries Therapy and Etiology (Haynes et al., copied from the PubMed help
  page with their sensitivity and specificity); PubMed's Systematic Review filter labelled as built into PubMed, not validated; design
  terms for every design labelled as not validated. All 78 filter choices were run through PubMed (E-utilities): results, no
  warnings. "Network Meta-Analysis" is used as the publication type it is.
- [x] **FIND-23** A test that every MeSH heading the app prints is in a stored list checked against NLM (with the MeSH year), and a
  `tools/` script that refreshes the list. Built 8 Nov 2026: `inst/extdata/mesh_checked.csv` (38 headings, publication types and
  subheadings with their NLM identifiers, MeSH 2026, including the example headings shown in the boxes), `tools/find/check_mesh.R`
  (NLM's MeSH SPARQL service, the chosen year only, names not entry terms), `test-pubmed_search.R`. Re-run the script when the terms
  change and after each year's MeSH is published.
- [ ] **FIND-24** **[optional]** Clinical codes for record-based studies (WHO ICD-10, ICD-10-CM, SNOMED CT, LOINC, RxNorm), taken only
  from the official code lists and never generated; needs a decision on which lists and their licence terms.
- [x] **FIND-25** Design cards for the guide's end points the registry lacks: diagnostic accuracy (STARD), agreement and reliability,
  prediction models (TRIPOD), self-controlled case series, case-cohort, propensity-score and time-varying designs, phase II and
  dose-finding trials; each with its sources checked as in SRC-06. Built 11 Nov 2026: 9 cards on 28 end points, 22 sources checked in
  PubMed (abstracts; STARD 2015, QUADAS-2, Lijmer 1999, GRRAS, Bland & Altman 1986, Feinstein & Cicchetti 1990, Koo & Li 2016,
  TRIPOD+AI, PROBAST, Riley 2019, Collins 2016, Whitaker 2006, Sharp 2014, Austin 2011, Hernan & Robins 2016, VanderWeele & Ding 2017,
  TARGET 2025, Suissa 2008, Robins 2000, Simon 1989, CONSORT-DEFINE, Le Tourneau 2009); statements without a checked source carry the
  "Suggestion only" mark. The PubMed builder covers them, with the Clinical Queries Diagnosis and Clinical Prediction Guides filters
  (validated); 55 MeSH headings checked. The single-arm phase II card names no reporting guideline (none found for that design).

## 4. Studies: a working record of calculations (STUDY)

Decisions S1-S5 are in `SDD.md`, section 17.

- [x] **STUDY-01** Storage in the browser tab only (`sessionStorage`), restored after a reload; "Add this result to [Study]" under every
  result (the shared export hook), Undo; the Studies tab with one drop-down (studies, "+ New study", Recent calculations) (3 Nov 2026).
- [x] **STUDY-02** Tables for repeated use of one calculator and design; Recent calculations (last 20, recorded once a result is stable)
  (3 Nov 2026).
- [x] **STUDY-03** Built-in .docx writer (no new runtime package): headings, tables, formulas as LaTeX for Word's Insert > Equation,
  numbered references; tested by reading the file back with `officer` and LibreOffice (3 Nov 2026).
- [x] **STUDY-04** "Add this design choice" from the guide; notes on results and studies; moving rows and sections; readable input names
  (3 Nov 2026).
- [x] **STUDY-05** Add to study for the Analyze tools, the randomization list and survey selection (3 Nov 2026).
- [ ] **STUDY-06** **[owner]** Open one downloaded file in Word (desktop and phone) and try Insert > Equation > LaTeX on a formula.
- [ ] **STUDY-07** **[owner]** Real-phone check on Connect Cloud and the browser build: sleep, switch apps, reload.
- [ ] **STUDY-08** Readable names for more calculators (only names with one meaning are labelled now).
- [ ] **STUDY-09** Check Word on phones, Google Docs and LibreOffice (pasted LaTeX, table styles); a long study on a phone.

## 5. Interface and accessibility (UI)

- [x] **UI-01** Workbench navigation: Home, Plan, Analyze, Find, Studies, Cite, with a grouped list inside each workbench (14 Oct 2026).
- [x] **UI-02** Task-first Home: search, quick links, task cards (29 Oct 2026).
- [x] **UI-03** Calculator pages with folded Export and curves; a short result pinned while inputs are edited (29 Oct 2026).
- [x] **UI-04** Phone layout: a bar of large tabs at the bottom, one drop-down for the calculator list, touch-sized controls (29 Oct 2026).
- [x] **UI-05** Dark mode; dark-mode contrast fixed (light boxes 1 Nov; buttons and success colour 4 Nov 2026).
- [x] **UI-06** Accessibility: axe-core scan (WCAG 2.0/2.1 A and AA) of every calculator and the other pages, light and dark, desktop and
  phone, at 0 violations; alt text on the plots (28 Oct - 4 Nov 2026).
- [x] **UI-07** Effect Size tab (ten converters), "Calculate this / Use this value" links from 30 calculator inputs, pre-filled from the
  calculator (1-4 Nov 2026).
- [x] **UI-08** The effect entered the way people know it (both means or the difference, OR / RR / RD, Cohen's f from means), absolute and
  relative precision with non-response in the precision calculators (1-2 Nov 2026).
- [x] **UI-09** "Advanced options" folded in the calculators that have optional settings (30 Oct, 4 Nov 2026).
- [x] **UI-10** A table comparing the three versions, on Home and the Cite tab, with the one in use marked (4 Nov 2026).
- [ ] **UI-11** A person's keyboard and screen-reader walk-through (a scan cannot judge reading order or whether names make sense).
- [ ] **UI-12** Dark-mode plots (plots stay white); text-resize and reduced-motion checks.
- [ ] **UI-13** Phone: the dark-mode switch is hidden on phones; a layout pass on a real phone; **[optional]** a slimmer phone-only app.
- [ ] **UI-14** **[optional]** Two-column layout on wide screens (inputs left, result right).
- [ ] **UI-15** Revisit with real usage: Home quick links and cards, the background loading order and the four start-up calculators.
- [x] **UI-16** A start-up screen for the browser build instead of Shinylive's spinner (`tools/pages/status_overlay.html`): what the app
  is and what is inside, the start-up progress, rotating feature tips, how to cite it, the author's papers (public ORCID record),
  workshops and other projects (public GitHub), a link to report a problem; light and dark, phone layout; it goes as soon as the app is on
  screen (7 Nov 2026). Conferences: none listed yet (a commented block in the file shows where to add them).

## 6. The R package (PKG)

- [x] **PKG-01** Installable package `epidemiologysuite` (GPL-3), `run_app()`, every `calc_*()` exported with a help page, an example and
  every argument described (29 Oct 2026).
- [x] **PKG-02** `ss_find()`, the RStudio / Positron addin, `run_app(calculator = ...)` (29 Oct 2026).
- [x] **PKG-03** Common result class with `print()`; `ss_text()`, `ss_export()`, `ss_curve()` (30 Oct, 4 Nov 2026).
- [x] **PKG-04** Vignettes: getting started, sample sizes, analysis, and by topic (survival, trials, diagnostic accuracy, surveillance)
  (30 Oct, 5 Nov 2026).
- [x] **PKG-05** CRAN groundwork: ASCII-only source, fast examples, browser tests skipped on CRAN, `R CMD check --as-cran` clean apart from
  check-machine notes; version 1.0.0, `NEWS.md`, Zenodo DOI 10.5281/zenodo.23794230, ORCID in `DESCRIPTION` (30 Oct - 3 Nov 2026).
- [ ] **PKG-06** **[owner]** Release on r-universe, then submit to CRAN: the steps are in `docs/release.md` (a new version number first;
  `v1.0.0` is the release Zenodo archived on 31 Oct 2026).
- [ ] **PKG-07** **[owner]** File the two upstream bug reports drafted in `docs/upstream_reports.md`: presize as an issue on its GitHub
  tracker, pmsampsize by e-mail to its maintainer (it has no tracker); both still unfixed on CRAN on 6 Nov 2026.
- [ ] **PKG-08** **[optional]** Tell powerSurvEpi's maintainer that `powerConLogistic.con()` uses Lachin's information factor, which is too
  large for two or more cases per set (NEWS, 5 Nov 2026); Tang's 2009 comment (Stat Med 28:175-177) was not read and may say the same.
- [ ] **PKG-09** **[optional]** Split a computation-only core package from the app (CRAN).
- [x] **PKG-10** Name confirmed with `available::available("epidemiologysuite")`: valid, free on CRAN, Bioconductor and GitHub
  (owner, 6 Nov 2026).
- [x] **PKG-11** A GitHub Action for the tarball (`.github/workflows/package.yml`): `R CMD build` once, `R CMD check --as-cran` of that
  file on Linux (R release and devel), Windows and macOS, an informational Windows-on-ARM install, and the tarball attached to the
  release on a version tag; green on all four with the current CRAN versions, R-devel 4.7.0 "Status: OK" (6 Nov 2026).
- [ ] **PKG-12** **[optional]** Ask epiR's maintainer about 3.0.0's population attributable fraction interval for a single 2 x 2 table:
  it is built from the limits of the two risks' intervals, where 2.0.67 reported Jewell's (2004) interval (this app keeps Jewell's).

## 7. Versions, hosting and distribution (DIST)

- [x] **DIST-01** Documentation site (pkgdown) on GitHub Pages, with a page per calculator (17 Oct 2026).
- [x] **DIST-02** Browser build (Shinylive / WebAssembly) on GitHub Pages, with a start-up status panel (21-27 Oct 2026).
- [x] **DIST-03** Docker image with a CI smoke test (21 Oct 2026).
- [x] **DIST-04** Phone / server version on Posit Connect Cloud from the `connect` branch, checked in CI; phones and tablets redirected to
  it;
  a notice that inputs go to the server (28 Oct - 3 Nov 2026).
- [x] **DIST-05** Lazy loading of calculators; the browser build loads only what is opened (27 Oct, 1 Nov 2026).
- [ ] **DIST-06** **[owner]** Republish on Connect Cloud after each merge; try the redirect, Find, Effect Size, the links, the server
  notice and dark mode on a real phone (Android and iPhone / Safari).
- [ ] **DIST-07** **[owner]** Long-term hosting: check the Connect Cloud free-plan limits (apps, active hours, memory, idle sleep); decide
  whether a paid plan or the Docker image elsewhere is needed.
- [ ] **DIST-08** **[owner]** After the repository rename: check the Pages address; rename `EPIDEMIOLOGICASUITE_OPEN` to
  `EPIDEMIOLOGYSUITE_OPEN` on Connect if it was set there.
- [ ] **DIST-09** Browser build: about 64 MB on first visit; trim it and measure first load and memory on a real phone connection (desktop,
  3 Nov 2026: 38.9 s until Home is usable; `tools/ui-audit/live_timing.js`). The offline / Android route waits on that measurement.
- [ ] **DIST-10** Park the `shinylive-spike` workflow (`if: false`) or move it to a weekly schedule.
- [ ] **DIST-11** Documentation site: look at it once (navigation, search, MathJax); custom domain; "Try it online" links; a link from each
  calculator page to the app.
- [ ] **DIST-12** Docker: first publish to GHCR, image size, an arm64 build.
- [ ] **DIST-13** Multi-user scaling: more background workers or replicas (ShinyProxy); check each worker's memory on the chosen host first.
- [ ] **DIST-14** HTTPS and a domain; then the installable web app (PWA), the Android wrapper (TWA), iOS via the PWA, a desktop wrapper.
- [ ] **DIST-15** **[optional]** Test a real shinyapps.io deploy, if still wanted.

## 8. Engineering and quality (ENG)

- [x] **ENG-01** CI on GitHub Actions (unit tests, browser tests, site, Docker, browser bundle, Connect bundle); `renv.lock` (Sep-Oct 2026).
- [x] **ENG-02** Every formula traced to a source and checked numerically against a published example, a package or a simulation; the tests
  hold the values (ongoing rule).
- [x] **ENG-03** Browser tests with `shinytest2`, split by area; every design of every module in the weekly slow lane (Oct - 4 Nov 2026).
- [x] **ENG-04** Background computation with `mirai` and `shiny::ExtendedTask` for the Monte Carlo calculators; result cache `memo_calc()`
  (30-31 Oct 2026).
- [x] **ENG-05** Runtime dependencies reduced to shiny, bslib, promises, clinfun, mvtnorm, lme4 and survival (`mirai`, suggested, for
  background computation on a server); the removed packages kept as test references (17 Oct - 4 Nov 2026).
- [x] **ENG-06** UI audit tools: `tools/ui-audit/audit.R`, `a11y.R`, `contrast.R`, `live_timing.js`.
- [x] **ENG-09** Project documents reorganised: SDD, this checklist (the only place status is kept), PENDING generated from it and
  tested, NEWS; the old roadmap, plan, to-do list and checklists archived (6 Nov 2026).
- [ ] **ENG-07** Re-snapshot `renv.lock` when convenient (it lists packages removed from the runtime and not the test-only ones).
- [ ] **ENG-08** The sandbox's `R CMD check` ends with a locale warning and a clock note that are not the package's; confirm on a normal
  machine or in CI.
- [ ] **ENG-10** Bring `renv.lock` up to the current CRAN versions (lme4 2.1-0, mvtnorm 1.4-2, epiR 3.0.0, officer 0.7.7, ...): the suite
  passes with them (6 Nov 2026, PKG-11); the test workflow, the server version and the browser build still use the locked ones.

## 9. Sources not yet read (SRC)

Formulas behind these were checked numerically (against a package or a published example) but the paper itself was not read; the app's
help text says so.

- [ ] **SRC-01** **[blocked]** Rothman & Boice 1979, Greenland & Robins 1985, Newcombe 1998, Miettinen & Nurminen 1985, Mee 1984, Koopman
  1984, Orenstein 1985, Lachin 1981, Rouder et al. 2009, Matts & Lachin 1988, Lachin & Foulkes 1986, and the others named in the
  archived ROADMAP. *Unblock:* paper access.
- [ ] **SRC-02** **[blocked]** Kish 1965 (design effect); Killip et al. 2004 and Chinn 2000 in full (only the abstracts were read).
- [ ] **SRC-03** A source for "design effect 1.5 or 2 when nothing is known" (the owner's wording; no source checked).
- [ ] **SRC-04** Regidor et al. 1993 (epiR's source for the Byar SMR interval) could not be found; not cited.
- [ ] **SRC-05** **[blocked]** Tang Y. Comments on Lachin (2008). Stat Med 2009;28:175-177, and the author's reply.
- [x] **SRC-06** Sources for the design-card claims (FIND-21), checked in PubMed 6-7 Nov 2026 (list in `R/design_cards.R`): the 23
  reporting guidelines resolve to their statements (CONSORT 2025 replaces 2010 for parallel trials); factorial interaction needs four
  times the sample size: confirmed in the full text of Montgomery, Peters & Little 2003 (not yet shown: no factorial end point);
  prevalence ratio when the outcome is common (Zhang & Yu 1998; Barros & Hirakata 2003); p < 5e-8 (Pe'er et al. 2008); corrected covered
  area (Pieper et al. 2014); Jadad's algorithm (1997). Contradicted by their sources and corrected: F > 10 for Mendelian randomisation
  (Burgess & Thompson 2011: misleading) and 8-12 time points for an interrupted time series (Bernal, Cummins & Gasparrini 2017: no fixed
  minimum).
- [ ] **SRC-07** **[blocked]** Two card statements stay marked as suggestions: a crossover washout of more than five half-lives and a
  non-inferiority margin preserving at least half the control effect; both come from regulatory guidance (bioequivalence; FDA 2016
  non-inferiority) that is not in PubMed and was not read. *Unblock:* reading the guidance documents.

## 10. Bigger workbenches and extensions (WB)

Scope decision D1 (`SDD.md`, section 17): calculators from summary data only; raw data goes to a later full (server) app.

- [ ] **WB-01** Evidence synthesis from study summaries (fixed / random effects, forest plot), base R, checked against `metafor`.
- [ ] **WB-02** Teaching mode: interactive power curves, sampling-distribution and CI-coverage demos.
- [ ] **WB-03** **[optional]** Survey extras: post-stratification / raking, weight trimming, variance estimation for the selected design,
  two-stage selection inside clusters, an AAPOR-style response-rate table.
- [ ] **WB-04** **[optional]** Surveillance extras: seasonal / day-of-week baselines (Farrington-type or regression), two-sided CUSUM, a
  false-alarm-rate calculator.
- [ ] **WB-05** **[optional]** Model extras: waning immunity, births and deaths (endemic SIRS), vaccination during the epidemic, age
  structure.
- [ ] **WB-06** **[optional]** Planning: minimization / covariate-adaptive allocation, cluster- and stepped-wedge randomization lists, a
  downloadable protocol section (partly covered by Studies).
- [ ] **WB-07** **[optional]** Analyze: exact (conditional) intervals for the stratified rate ratio (only the Mantel-Haenszel Wald interval
  is offered).
- [ ] **WB-08** **[blocked]** Analyze: Ury-Wiggins (1985) SMR limits (epiR's own comment says its reference code was wrong). *Unblock:*
  paper
  access.
- [ ] **WB-09** Later, outside the browser app (D1): the raw-data workbench (upload, Table 1, adjusted estimates, Kaplan-Meier, adjusted
  vaccine efficacy), line lists, epidemic curves, R0 / Rt; merged with the owner's `Easy_analysis` application; needs a data-privacy
  policy first.
