# To do

> What is left, in one list, refined with the owner on 3 November 2026. What is done is struck through in [`PLAN.md`](PLAN.md);
> the reasoning and evidence are in [`ROADMAP.md`](ROADMAP.md). Tick an item here when it is done and note it in the roadmap.

*Items marked **[owner]** need a decision or an action only the repository owner can take. Items marked **[blocked]** wait on
something outside the code (a paper, a package, an account). Work is collected on one branch at a time, not a pull request per change.*

---

## A. Owner steps

- [ ] **[owner]** Republish on Connect Cloud; on a real phone (Android and iPhone / Safari) try the redirect, the Find and Effect Size tabs,
  the "Calculate this" links, the new server-version notice and dark mode.
- [ ] **[owner]** Long-term hosting: check the Connect Cloud free-plan limits (apps, active hours, memory, idle sleep); decide whether a paid plan
  or the Docker image elsewhere is needed.
- [ ] **[owner]** File the two upstream bug reports: drafts in `docs/upstream_reports.md` (pmsampsize continuous criterion 4 sign error; presize
  prec_pos_lr / prec_neg_lr ignoring conf.level).
- [ ] **[owner]** Release: r-universe, then CRAN. Author details are done (3 Nov 2026: ORCID 0000-0002-1918-5100 from forecastsuite, in
  `DESCRIPTION`, `CITATION.cff`, `inst/CITATION`). `R CMD check --as-cran` gives 0 errors; its warnings and notes come from the check machine.
- [ ] **[owner]** D6: when to reopen the paused items (section I).

## B. Studies: a working record of calculations (built 3 Nov 2026; decisions S1-S5 in `ROADMAP.md` §10)

- [x] S-1 Storage in the browser tab only (`sessionStorage`), restored after a reload or a dropped connection; "Add this result to [Study v]
  Add" under every result through the shared export hook (64 calculators), with Undo; the Studies tab with one drop-down (studies, "+ New
  study" up to 10, Recent calculations), name, entries, remove, Clear (3 Nov 2026, `R/mod_studies.R`). The Download button comes with S-2.
- [x] S-1 Tables for repeated use of one calculator and design (the inputs that vary as columns, the constant ones listed once) (3 Nov 2026).
- [x] S-1 Recent calculations: last 20, recorded once a result has been stable for 3 s after the user has changed something in that
  calculator (loading a calculator records nothing), without duplicates (3 Nov 2026).
- [x] Add to study for the randomization list and survey selection too, with their own methods paragraph (the list itself stays in the
  CSV download); the ecological and qualitative pages are guidance only and calculate nothing (3 Nov 2026).
- [ ] Readable names for more calculators (only names with one meaning are labelled; the rest keep their short name).
- [x] S-2 Built-in .docx writer (no new runtime package; `R/docx_writer.R`): XML parts, stored zip with CRC-32, headings, tables with a
  repeated header row; each formula in LaTeX for Word's Insert > Equation, with a plain-text form where every command is known (222 of the app's
  396 formula blocks); numbered references with the suite's own citation; made in R and saved by the browser (3 Nov 2026).
- [x] S-2 Tests: CRC-32 check value and `digest`, base64 against `jsonlite`, `unzip -t`, every part parsed by `xml2`, read back by `officer`,
  converted by LibreOffice; browser test of the download (3 Nov 2026).
- [ ] S-2 left: **[owner]** open one downloaded file in Word (desktop and phone) and try Insert > Equation > LaTeX on a formula.
- [x] S-3 "Add this design choice" at the end of the guide (the design, the calculator, the questions and answers; first in the tab and
  the Word file); a note on each result (a Comment line, or a Comment column in a table) and on the study (under the title); move a result up
  or down within its table and a section up or down; readable names ("Significance level (alpha)") for names that mean one thing in every
  calculator, and per calculator for those that do not (d, p1, r, ...); others keep their short name (3 Nov 2026).
- [x] S-4 Analyze results: the 11 Analyze tools use the shared export hook, so they have Add to study (3 Nov 2026).
- [ ] S-4 **[owner]** real-phone check on Connect Cloud (sleep, switch apps, reload) and the browser build.
- [ ] Check: Word on phones, Google Docs and LibreOffice (whether pasted LaTeX can be turned into an equation there; table styles); a long study on a phone.

## C. Small items

- [ ] **About the three versions:** an information panel (Home or Cite) with a table comparing the phone / server version (Posit Connect
  Cloud), the browser version (GitHub Pages) and the R package: where it runs, whether inputs leave the device, internet needed, start-up
  time, speed of the simulations (background workers), devices it suits, Studies storage, how to install or open it, how to cite it.
- [ ] Links for inputs where a converter gives a different quantity (the Welch design's two SDs; the SD from a median and IQR gives one); the
  logistic designs' odds ratios ("per one-SD increase", ordinal) have no converter.
- [ ] More glossary terms and information tips on request (35 terms now).
- [ ] Re-run the axe scan (`tools/ui-audit/a11y.R`) on the Find tab, the Effect Size tab, the pinned "Use this value" panel and the server notice.
- [ ] Split `test-ui_smoke.R` by area, so a failure points to one file.
- [ ] "Advanced options" folded inside the remaining ~60 calculators (done for Proportions, Means, Case-Control, Cohort, Correlation, Diagnostic
  Accuracy, Variance Tests, Multiplicity): decide per calculator which inputs are optional.
- [ ] Wizard: a cohort with a *continuous exposure* (dose-response) and a case-control with a *categorical* exposure still go to the yes/no
  routes; a case-control with several controls per case and a measured exposure uses the paired test (1:m is approximate).
- [ ] Re-check `epi.ssdetect()` against epiR 3.0.0 (different interface; the app follows 2.0.67 semantics).
- [ ] Optional: re-derive `kappaSize`'s kappa tables (2-6 raters, 2-5 categories) and drop that package.
- [ ] Optional: wrappers `ss_text()`, `ss_curve()`, `ss_export()` around the `ss_result` object; decide the public naming (C2) and add
  per-family vignettes (survival, trials, diagnostic accuracy, surveillance).

## C2. Guide: research questions (plan at the end of `ROADMAP.md`)

- [x] When nothing in a description is recognised, say so and how to rephrase (it showed nothing before) (3 Nov 2026).
- [ ] **[owner]** A list of 50-100 real research questions / thesis titles (community medicine, public health) to test the reader against.
- [ ] A test battery of those questions with the route each should take; measure the hit rate before and after each change.
- [x] Rules for topic phrasings (4 Nov 2026): knowledge-attitude-practice, awareness, utilization and pattern questions reach a survey
  estimate. "Determinants / factors associated / risk factors / predictors / correlates of X" are ambiguous (the algorithm doc, section 0.3:
  never collapse them to one design), so the guide shows four candidates with a line on when each applies (a survey now, case-control,
  cohort, prediction model) and continues from the one chosen; an explicit design word (case-control, trial, cohort, correlation) still
  wins. After the survey route, the last step points to the association's own sample size (two groups, or multiple logistic / linear
  regression; a mean for "levels" or "scores"), and a population named by place gets a box about cluster sampling and the design effect.
  14 questions in `test-research_questions.R` (written for the test, not real titles).
- [ ] More phrasings once the owner's list is in: "effect / effectiveness / impact of" without a design word (trial or quasi-experimental:
  ask), "association between" (ask which design), "incidence / follow-up", "survival / time to", "accuracy / screening".
- [ ] Ask instead of guessing when a phrase fits several designs (offer two or three starting points).
- [x] Several objectives, first step: a determinants question ends with the estimate plus buttons to the association calculators, each
  with Add to study (4 Nov 2026). [ ] A guide that asks for each objective in turn.
- [ ] A language-model reader only by a separate decision (no API, nothing sent anywhere in the browser version).

## D. Interface and accessibility

- [ ] A person's keyboard and screen-reader walk-through (a scan cannot judge reading order or whether names make sense).
- [ ] Dark-mode plots (plots stay white); text-resize and reduced-motion checks.
- [ ] Phone: the dark-mode switch is hidden on phones; a layout pass on a real phone; optional slimmer phone-only app.
- [ ] Optional: two-column layout on wide screens (inputs left, result right).
- [ ] Revisit with real usage: Home quick links and cards, the background loading order and the four start-up calculators.
- [ ] The keyword parser is deliberately conservative; a language-model option would need an API decision (the app has none).

## E. Distribution and infrastructure

- [ ] Browser build: about 64 MB on first visit; trim it and measure first load and memory on a real phone connection (on 3 Nov 2026, desktop:
  38.9 s until Home is usable, "Start the guide" 2.4 s, a Home quick link 0.4 s; `tools/ui-audit/live_timing.js`). D5 (offline / Android
  route) waits on that measurement; re-run against the newest webR.
- [ ] Park the `shinylive-spike` workflow (`if: false`) or move it to a weekly schedule.
- [ ] Documentation site: look at it once (navigation, search, MathJax); custom domain; "Try it online" links; a link from each calculator
  page to the app.
- [ ] Docker: first publish to GHCR, image size, an arm64 build.
- [ ] Multi-user scaling: more background workers or replicas (ShinyProxy); check each worker's memory on the chosen host first.
- [ ] HTTPS and a domain; then the PWA (D4), the Android TWA (D5a), iOS via the PWA (D6), a desktop wrapper (D7).
- [ ] Test a real shinyapps.io deploy (the two-line `app.R` note was never tested), if still wanted.
- [ ] Optional: split a computation-only core package from the app (C3).

## F. Bigger workbenches

- [ ] **B7** Evidence synthesis from study summaries (fixed / random effects, forest plot), base R, checked against `metafor`.
- [ ] **B8** Teaching mode: interactive power curves, sampling-distribution and CI-coverage demos.
- [ ] **B3** survey extras, none promised: post-stratification / raking, weight trimming, variance estimation for the selected design, two-stage
  selection inside clusters, an AAPOR-style response-rate table.
- [ ] **B4** surveillance extras, none promised: seasonal / day-of-week baselines (Farrington-type or regression), two-sided CUSUM, a
  false-alarm-rate calculator.
- [ ] **B5** model extras, none promised: waning immunity, births and deaths (endemic SIRS), vaccination during the epidemic, age structure.
- [ ] **Later, outside the browser app (decision D1, 3 Nov 2026):** the raw-data workbench (B6: upload, Table 1, adjusted estimates,
  Kaplan-Meier) and line lists, epidemic curves, R0 / Rt (B4). Too memory-heavy for the browser build; kept for a later full (server) app,
  to be merged with the owner's `Easy_analysis` application. Needs a data-privacy policy first.

## G. Planning and Analyze extensions (none promised)

- [ ] Planning: minimization / covariate-adaptive allocation, cluster- and stepped-wedge randomization lists, a downloadable protocol section
  (partly covered by Studies, section B).
- [ ] Analyze: exact (conditional) intervals for the *stratified* rate ratio (only the Mantel-Haenszel Wald interval is offered).
- [ ] Analyze: adjusted vaccine efficacy from a model (logistic, Cox, test-negative with covariates): needs raw data; with the later full app (D1).
- [ ] Analyze: Ury-Wiggins (1985) SMR limits. **[blocked]** paper access (epiR's own comment says its reference code was wrong).

## H. Sources not yet read (flagged in the app's help text)

- [ ] Papers behind formulas that were verified numerically but not read: Rothman & Boice 1979, Greenland & Robins 1985, Newcombe 1998,
  Miettinen & Nurminen 1985, Mee 1984, Koopman 1984, Orenstein 1985, Lachin 1981, Rouder et al. 2009, Matts & Lachin 1988 and the others
  named in the roadmap. **[blocked]** paper access.
- [ ] Kish 1965 (design effect); Killip et al. 2004 and Chinn 2000 in full (only the abstracts were read). **[blocked]** paper access.
- [ ] A source for "design effect 1.5 or 2 when nothing is known" (the owner's wording; no source checked).
- [ ] Regidor et al. 1993 (the source epiR's comments give for the Byar SMR interval) could not be found; not cited.

## I. Sample-size catalog

### Not built (each with what would unblock it)
- [ ] **Multi-reader multi-case (MRMC) — Obuchowski-Rockette / DBM** -- `iMRMC` is installable, but its Roe-Metz simulation model needs 6 fixed effects + 18 variance components before the OR/DBM analysis step — too large to reimplement and verify safely in one batch *Unblock:* Dedicated multi-batch effort using `iMRMC` as oracle; or relax the vendoring rule and wrap `iMRMC` directly
- [ ] **Dose-finding / phase I (3+3, CRM)** -- Output is *operating characteristics at a fixed n*, not a required n; needs full simulation of the sequential Bayesian/MLE dose-escalation procedure *Unblock:* Build a reusable "operating-characteristics simulator" module type, verify against `dfcrm::crmsim()` (installed)
- [ ] **Platform / basket / umbrella trials** -- `basket` is analysis-only; `gsbDesign` is a different (two-arm) tool *Unblock:* Same simulator framework as CRM; or a multi-arm group-sequential design verified against `rpact` (installed)
- [ ] **N-of-1 trials** -- `nof1`/`Nof1` unreachable (not on the CRAN mirror); no single accepted formula *Unblock:* CRAN/Bioconductor access, or a citable period-count formula with a worked example
- [ ] **One-sample survival vs. historical control** -- Closed form exists (Finkelstein et al. 2003; Schmidt et al. 2015) but every source with the equations is network-blocked here; web-search snippets aren't enough to verify *Unblock:* Access to the paper or the NCSS/PASS manual; verify one worked example
- [ ] **GWAS / candidate-gene association** -- `genpwr`/`Haplin` installed, but both are numerical-MLE engines (root-finding over likelihood surfaces, many model combinations) *Unblock:* Multi-batch effort with `genpwr` as oracle, or relax vendoring for this one family
- [ ] **Gene–environment interaction** -- Same engine as GWAS *Unblock:* Same as GWAS
- [ ] **Microarray / RNA-seq DE (`ssize`, `RNASeqPower`, `PROPER`)** -- All three are Bioconductor-only, unreachable. *Partly served* by the exact Liu & Hwang FDR design (Multiplicity module) *Unblock:* Bioconductor access
- [ ] **Deming / Passing-Bablok method comparison** -- `deming`, `mcr`, `MethComp` all installed and confirmed analysis-only; literature is simulation-based *Unblock:* A citable simulation protocol (e.g. Linnet) to reproduce, then a Monte Carlo design
- [ ] **Propensity-score-matched designs (matching efficiency)** -- `MatchIt`/`Matching`/`ATE` analysis-only; efficiency depends on each dataset's covariate overlap *Unblock:* A published planning heuristic with a worked example; or a data-driven tool inside the future analysis workbench (B6)
- [ ] **Time-varying exposure (OPTITXS)** -- Not on CRAN; formulas in Basagaña & Spiegelman (2010, 2011) not reachable *Unblock:* Paper access, or the OPTITXS source
- [ ] **Random-model multiple regression (Gatsonis & Sampson 1989)** -- No R package implements it; `WebPower::wp.regression()` is fixed-model only *Unblock:* Paper access; verify against G*Power's random-model output
- [ ] **Exact bivariate-normal correlation test** -- Needs Fisher's exact distribution of r; no package to verify against *Unblock:* Reproduce G*Power's "Exact – bivariate normal" worked values from a citable table
- [ ] **General permutation-test power** -- No general formula by definition (KS and runs tests are covered) *Unblock:* Out of scope unless a specific statistic is named
- [ ] **Average coverage criterion / HPD interval width (Joseph & Belisle)** -- `BayesianPower` installed but implements a different (Bayes-factor) method; *partly served* by Bayesian assurance + BFDA *Unblock:* Paper access or an R implementation to verify against

### Paused by the owner (do not start until reopened, decision D6)
- [ ] **External validation — time-to-event (Riley et al. 2022)** -- Paused at the owner's request pending paper access. Note for later: `pmvalsampsize` (already used for the binary case from its GitHub mirror) may have a time-to-event branch worth checking first
- [ ] **Model updating / recalibration; ML model sample size; calibration-assessment sample size** -- Paused at the owner's request, same reason

### Shipped, with an open half
- [ ] **Stepped-wedge CRT** -- open: Binary outcome (`clusterPower::cpa.sw.binary()` is a numerical GEE procedure, no closed form)
- [ ] **Multilevel 2-/3-level** -- open: With dropout (`powerlmm`'s matrix-based missing-data calculation)
- [ ] **MMRM** -- open: General missing-data MMRM beyond the AR(1)/dropout design
- [ ] **GEE marginal models** -- open: Damped-exponential correlation variant
- [ ] **Group sequential / Lan-DeMets** -- open: 3+ looks, and binary/survival outcomes for the spending-function design; `spass`-style blinded SSR
- [ ] **Trial sequential analysis** -- open: Heterogeneity-adjusted (random-effects / diversity-adjusted) information size
- [ ] **Meta-analysis power** -- open: Network meta-analysis
- [ ] **ROC comparison** -- open: Unpaired AUCs (`pROC` doesn't support it)
- [ ] **LQAS** -- open: Cluster-LQAS (heterogeneity-adjusted)
- [ ] **MANOVA** -- open: Global test for k > 2 groups and special-effect contrasts
- [ ] **Compare two dependent correlations** -- open: Non-common-index case
- [ ] **Ordinal / multinomial regression** -- open: Nominal (multinomial) half
- [ ] **Agreement** -- open: Weighted kappa
- [ ] **Non-inferiority margins (RR / OR / HR / difference)** -- open: True **relative-risk-scale** margin. `TrialSize::RelativeRisk.NIS()` is really odds-ratio-based, so it ships as the OR design; no verified RR-scale source yet. *Added 28 Sep 2026 from the review-PDF cross-check*
- [ ] **Holm / FDR** -- open: **Holm's step-down** as its own design. Bonferroni (shipped) is Holm's most conservative step; Holm's later thresholds depend on the observed p-values, so there is no single planning alpha — needs a simulation-based design. *Added 28 Sep 2026*
- [ ] **Value of information (EVPI / EVSI)** -- open: Multi-parameter EVPPI and non-Normal outcomes (only the single-parameter, known-SD case ships). *Added 28 Sep 2026*
- [ ] **Bioequivalence (TOST)** -- open: Reference-scaled designs for highly variable drugs (RSABE / ABEL): the 2×2, 2×2×4 and 2×3×3 designs ship with fixed 80–125% limits; `PowerTOST::sampleN.RSABE()`/`sampleN.scABEL()` exist in a runtime package but are simulation-based and not wired in. (Named in the checklist, not in the review PDF.) *Added 28 Sep 2026*
- [ ] **Multi-arm vs. common control** -- open: Dunnett for **binary** outcomes (means only; the wizard falls back to Bonferroni/Sidak two-proportion n). *Added 28 Sep 2026*
- [ ] **Eyes / Lesions per Patient** -- open: binary outcome with both treatments in each patient (clustered McNemar; needs a checked source), a
  patient-by-treatment variance part for the split designs, unequal allocation, different numbers of units in the two arms, the analysis side
  (Rosner-Milton / Obuchowski tests).

## J. Housekeeping

- [ ] `ROADMAP.md` section 1: the checklist coverage and wizard figures (81/94, 49/49) are still the 28 September values.
- [ ] Keep `docs/checklist_by_design.md` / `checklist_by_test.md` in step with the Analyze, planning and Effect Size tools.
- [ ] Re-snapshot `renv.lock` when convenient: it lists packages removed from the runtime (intended: the tests use them as oracles) and not
  the test-only packages (`shinytest2`, `chromote`, ...).
- [ ] The sandbox's `R CMD check` ends with a locale warning and a clock note that are not the package's; confirm on a normal machine or in CI.

---

## Done on 3 November 2026 (this list's last refresh)

- ~~Author details for CRAN: ORCID added from forecastsuite~~
- ~~Pre-fill the Effect Size converter from the calculator: 9 links copy what the calculator already holds (group means and SD, eta-squared,
  the medians or event probabilities, the control exposure, the paired SDs and correlation, Cohen's d) and open the converter on the route the
  calculator was using~~
- ~~Dark-mode contrast crawl and live-site timing kept as tools: `tools/ui-audit/contrast.R` (+ `contrast.js`), `tools/ui-audit/live_timing.js`~~
- ~~Re-measure the live browser build after #33~~ (numbers in section E)
- ~~Browser-build message for TOST, Fisher and Boschloo~~: no longer needed (they were rewritten in R on 31 Oct; no design is blocked in the browser)
- ~~A notice in the server (Connect) version that inputs are sent to the server~~ (closable)
- Dropped from the list: OpenEpi screenshots (not needed), the 17 October Pages error (not happening), branch deletion (automatic now).
- The old section 7 of 3 November (brought back by #37) is removed again: each of its items is in sections A, C and H above, or done.
