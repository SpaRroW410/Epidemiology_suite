# Pending

> Generated from `docs/CHECKLIST.md` by `tools/docs/build_pending.R`; do not edit by hand. Tick an item in the checklist when
> it is done and run the script again (a test fails while this file is out of date).

**91 open** of 362 items (271 done).

## Waiting for the owner

- **OWN-04** Decision D6: when to reopen the paused items (PRED, section 2).
- **FIND-09** A list of 50-100 real research questions / thesis titles (community medicine, public health) to test the reader against.
- **STUDY-06** Open one downloaded file in Word (desktop and phone) and try Insert > Equation > LaTeX on a formula.
- **STUDY-07** Real-phone check on Connect Cloud and the browser build: sleep, switch apps, reload.
- **PKG-06** Release on r-universe, then submit to CRAN: the steps are in `docs/release.md` (a new version number first; `v1.0.0` is the release Zenodo archived on 31 Oct 2026).
- **PKG-07** File the two upstream bug reports drafted in `docs/upstream_reports.md`: presize as an issue on its GitHub tracker, pmsampsize by e-mail to its maintainer (it has no tracker); both still unfixed on CRAN on 6 Nov 2026.
- **DIST-06** Republish on Connect Cloud after each merge; try the redirect, Find, Effect Size, the links, the server notice and dark mode on a real phone (Android and iPhone / Safari).
- **DIST-07** Long-term hosting: check the Connect Cloud free-plan limits (apps, active hours, memory, idle sleep); decide whether a paid plan or the Docker image elsewhere is needed.
- **DIST-08** After the repository rename: check the Pages address; rename `EPIDEMIOLOGICASUITE_OPEN` to `EPIDEMIOLOGYSUITE_OPEN` on Connect if it was set there.

## 1. Owner steps (OWN) -- 1 open

- [ ] **OWN-04** **[owner]** Decision D6: when to reopen the paused items (PRED, section 2).

## 2. Calculators (Plan: Sample Size and Analyze) -- 40 open

### Plan: Survey & Cross-Sectional (SVY)

- [ ] **SVY-09** **[blocked]** LQAS, open half: cluster-LQAS (heterogeneity-adjusted). *Unblock:* a citable formula with a worked example.

### Plan: Observational Studies (OBS)

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

- [ ] **DX-10** **[blocked]** Multi-reader multi-case (MRMC) studies, Obuchowski-Rockette / DBM: `iMRMC`'s Roe-Metz model (6 fixed
  effects, 18 variance components) is too large for one batch. *Unblock:* a multi-batch effort with `iMRMC` as the reference.
- [ ] **DX-11** **[blocked]** ROC comparison, open half: Unpaired AUCs (two independent AUCs; `pROC::power.roc.test` does not support
  them). *Unblock:* a separately verified formula.

### Plan: Agreement & Reliability (AGR)

- [ ] **AGR-06** **[blocked]** Method comparison by Deming / Passing-Bablok regression: `deming`, `mcr`, `MethComp` are analysis-only; the
  literature is simulation-based. *Unblock:* a citable simulation protocol (e.g. Linnet) to reproduce.
- [ ] **AGR-07** Agreement, open half: weighted kappa.

### Plan: Several Measurements per Patient (UNIT)

- [ ] **UNIT-04** Eyes / lesions per patient, open half: binary outcome with both treatments in each patient (clustered McNemar; needs a
  checked source), a patient-by-treatment variance part for the split designs, unequal allocation, different numbers of units in the two
  arms, and the analysis side (Rosner-Milton / Obuchowski tests).

### Plan: Clinical Trials (TRIAL)

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

- [ ] **SURV-09** **[blocked]** One-sample survival vs. a historical control (Finkelstein et al. 2003; Schmidt et al. 2015): the sources
  with the equations were not reachable. *Unblock:* the paper or the NCSS / PASS manual, and one worked example.

### Plan: Prediction Models (PRED)

- [ ] **PRED-05** **[paused]** External validation, time-to-event (Riley et al. 2022): paused by the owner pending paper access
  (`pmvalsampsize` may have a time-to-event branch worth checking first). Reopen: decision D6.
- [ ] **PRED-06** **[paused]** Model updating / recalibration; machine-learning model sample size; calibration-assessment sample size:
  paused by the owner, same reason.

### Plan: Health Economics / Value of Information (HE)

- [ ] **HE-03** Value of information, open half: multi-parameter EVPPI and non-normal outcomes (only the single-parameter, known-SD case
  ships).

### Plan: General Statistical Tests (GEN)

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

## 3. Finding a calculator: the guide, search and Find tab (FIND) -- 8 open

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
- [ ] **FIND-24** **[optional]** Clinical codes for record-based studies (WHO ICD-10, ICD-10-CM, SNOMED CT, LOINC, RxNorm), taken only
  from the official code lists and never generated; needs a decision on which lists and their licence terms.
- [ ] **FIND-25** Design cards for the guide's end points the registry lacks: diagnostic accuracy (STARD), agreement and reliability,
  prediction models (TRIPOD), self-controlled case series, case-cohort, propensity-score and time-varying designs, phase II and
  dose-finding trials; each with its sources checked as in SRC-06.

## 4. Studies: a working record of calculations (STUDY) -- 4 open

- [ ] **STUDY-06** **[owner]** Open one downloaded file in Word (desktop and phone) and try Insert > Equation > LaTeX on a formula.
- [ ] **STUDY-07** **[owner]** Real-phone check on Connect Cloud and the browser build: sleep, switch apps, reload.
- [ ] **STUDY-08** Readable names for more calculators (only names with one meaning are labelled now).
- [ ] **STUDY-09** Check Word on phones, Google Docs and LibreOffice (pasted LaTeX, table styles); a long study on a phone.

## 5. Interface and accessibility (UI) -- 5 open

- [ ] **UI-11** A person's keyboard and screen-reader walk-through (a scan cannot judge reading order or whether names make sense).
- [ ] **UI-12** Dark-mode plots (plots stay white); text-resize and reduced-motion checks.
- [ ] **UI-13** Phone: the dark-mode switch is hidden on phones; a layout pass on a real phone; **[optional]** a slimmer phone-only app.
- [ ] **UI-14** **[optional]** Two-column layout on wide screens (inputs left, result right).
- [ ] **UI-15** Revisit with real usage: Home quick links and cards, the background loading order and the four start-up calculators.

## 6. The R package (PKG) -- 5 open

- [ ] **PKG-06** **[owner]** Release on r-universe, then submit to CRAN: the steps are in `docs/release.md` (a new version number first;
  `v1.0.0` is the release Zenodo archived on 31 Oct 2026).
- [ ] **PKG-07** **[owner]** File the two upstream bug reports drafted in `docs/upstream_reports.md`: presize as an issue on its GitHub
  tracker, pmsampsize by e-mail to its maintainer (it has no tracker); both still unfixed on CRAN on 6 Nov 2026.
- [ ] **PKG-08** **[optional]** Tell powerSurvEpi's maintainer that `powerConLogistic.con()` uses Lachin's information factor, which is too
  large for two or more cases per set (NEWS, 5 Nov 2026); Tang's 2009 comment (Stat Med 28:175-177) was not read and may say the same.
- [ ] **PKG-09** **[optional]** Split a computation-only core package from the app (CRAN).
- [ ] **PKG-12** **[optional]** Ask epiR's maintainer about 3.0.0's population attributable fraction interval for a single 2 x 2 table:
  it is built from the limits of the two risks' intervals, where 2.0.67 reported Jewell's (2004) interval (this app keeps Jewell's).

## 7. Versions, hosting and distribution (DIST) -- 10 open

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

## 8. Engineering and quality (ENG) -- 3 open

- [ ] **ENG-07** Re-snapshot `renv.lock` when convenient (it lists packages removed from the runtime and not the test-only ones).
- [ ] **ENG-08** The sandbox's `R CMD check` ends with a locale warning and a clock note that are not the package's; confirm on a normal
  machine or in CI.
- [ ] **ENG-10** Bring `renv.lock` up to the current CRAN versions (lme4 2.1-0, mvtnorm 1.4-2, epiR 3.0.0, officer 0.7.7, ...): the suite
  passes with them (6 Nov 2026, PKG-11); the test workflow, the server version and the browser build still use the locked ones.

## 9. Sources not yet read (SRC) -- 6 open

- [ ] **SRC-01** **[blocked]** Rothman & Boice 1979, Greenland & Robins 1985, Newcombe 1998, Miettinen & Nurminen 1985, Mee 1984, Koopman
  1984, Orenstein 1985, Lachin 1981, Rouder et al. 2009, Matts & Lachin 1988, Lachin & Foulkes 1986, and the others named in the
  archived ROADMAP. *Unblock:* paper access.
- [ ] **SRC-02** **[blocked]** Kish 1965 (design effect); Killip et al. 2004 and Chinn 2000 in full (only the abstracts were read).
- [ ] **SRC-03** A source for "design effect 1.5 or 2 when nothing is known" (the owner's wording; no source checked).
- [ ] **SRC-04** Regidor et al. 1993 (epiR's source for the Byar SMR interval) could not be found; not cited.
- [ ] **SRC-05** **[blocked]** Tang Y. Comments on Lachin (2008). Stat Med 2009;28:175-177, and the author's reply.
- [ ] **SRC-07** **[blocked]** Two card statements stay marked as suggestions: a crossover washout of more than five half-lives and a
  non-inferiority margin preserving at least half the control effect; both come from regulatory guidance (bioequivalence; FDA 2016
  non-inferiority) that is not in PubMed and was not read. *Unblock:* reading the guidance documents.

## 10. Bigger workbenches and extensions (WB) -- 9 open

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
