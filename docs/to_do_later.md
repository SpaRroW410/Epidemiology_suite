# To do later

> The plan at a glance, with finished items struck through, is [`PLAN.md`](PLAN.md); this file is the long flat checklist behind it.

Everything that is **not finished yet**, in one list, in roadmap order (start to end), so it can be picked up later
without reading the whole [`ROADMAP.md`](ROADMAP.md). The roadmap stays the source of truth for the reasoning and the
evidence; this file is the checklist. Tick an item here when it is done *and* record it in the roadmap.

*Compiled 21 October 2026 and brought up to date on 29 October 2026 (items 1-22 built or started; Connect Cloud version, phone layout, task-first Home, exported functions with help pages, Cite tab and accessibility done; the new open items are in section 6).
Items marked **[owner]** need a decision or an action only the repository owner can take (an account, a setting, a
budget, a name). Items marked **[blocked]** wait on something outside the code (a paper, a package, an account).*

---

## 1. Open from the priority list (§3 of the roadmap)

### P0 / P1 leftovers
- [x] **Async compute for Monte Carlo designs (finding F9, item 7 second half)** -- done 31 Oct 2026: background computation with `mirai` (owner's decision, 31 Oct 2026): on a server the 10 Monte Carlo calculators run in a separate R process through `shiny::ExtendedTask` (`R/background.R`), the Calculate button shows "Calculating...", and the results are identical to the in-session ones (same seed and random-number generator, checked by the tests). One worker by default; `EPIDEMIOLOGYSUITE_WORKERS` (or `options(epidemiologysuite.workers)`) sets the number, 0 turns it off. `mirai` is suggested, not required: without it, or in the browser build, the calculation runs in the session. In the browser build a simulation now runs only when Calculate is pressed.
- [x] **Caching of repeated results** (Track E, P2; done 30 Oct 2026): result cache for the 10 Monte Carlo calculators (`R/memo_cache.R`, `memo_calc()`): a repeated identical calculation (same inputs and seed) is returned at once, shared by every session of the R process, at most 200 results kept, switch off with `options(epidemiologysuite.cache = FALSE)`. Closed-form results are not cached on purpose: they take microseconds, less than building the key, so `bindCache()` would add nothing there.
- [x] **Accessibility, dark mode (finding F11, item 22), first pass done 28 Oct 2026:** axe-core scan of every calculator (WCAG A/AA, desktop + phone, light + dark) fixed to 0 violations (`tools/ui-audit/a11y.R`), dark-mode switch added. English only (D5).
- [ ] Still open from item 22: a person's keyboard and screen-reader walk-through (a scan cannot judge reading order or whether names make sense), dark-mode plots (the text descriptions of the plots are done), text-resize / reduced-motion checks, a phone layout pass on a real phone.

### Analyze workbench (item 13, done) -- left out on purpose
- [ ] Ury-Wiggins (1985) SMR limits: epiR's own code comment says its reference code was wrong and the constants could not be
  verified from the paper. **[blocked]** paper access.
- [ ] Adjusted vaccine efficacy / effectiveness from a model (logistic, Cox, test-negative with covariates): needs raw data or
  adjusted estimates as input; out of scope while the suite is summary-data only (D1).
- [ ] Exact (conditional) confidence intervals for the *stratified* rate ratio (only the Mantel-Haenszel Wald interval is offered).
- [ ] Regidor et al. 1993 (the source epiR's comments give for the Byar SMR interval) could not be found; not cited.
- [ ] Read the original papers behind the formulas that were verified numerically but not read (Rothman & Boice 1979, Greenland &
  Robins 1985, Newcombe 1998, Miettinen & Nurminen 1985, Mee 1984, Koopman 1984, Orenstein 1985, Lachin 1981, Rouder et al.
  2009, Matts & Lachin 1988 and the others named in the roadmap). **[blocked]** paper access.

### Planning tools (item 14, done)
- [ ] Possible extensions, none promised: minimization / covariate-adaptive allocation, cluster- and stepped-wedge randomization
  lists, a downloadable PDF/Word protocol section (today: a copyable paragraph and CSV/JSON/BibTeX/RIS downloads).

### Dependency reduction (item 16, done in part)
- [x] (done 28 Oct 2026, see ROADMAP) Remaining low-weight imports: `pwr`, `powerMediation`, `pmsampsize`, `pROC` (each under 1 MB; reimplement and test against
  the package as was done for `epiR`, `Hmisc`, `tseries`, `BayesFactor`, `rstatix`).
- [x] (done 28 Oct 2026) Moderate: `presize`, `powerSurvEpi`, `TrialSize`. Left: `kappaSize` (kappa cell-probability tables, 8 large functions) is now the direct import instead of `presize`; re-deriving it would remove one more package.
- [ ] Higher risk, defer: `PowerTOST` (also what breaks the browser build), `Exact` / Boschloo (needs `rootSolve`, no WebAssembly
  build), `clinfun` (`ph2simon`, group-sequential). `lme4` stays (the Monte Carlo mixed-model designs need it); `mvtnorm`, `shiny`,
  `bslib` stay.
- [ ] Re-check `epi.ssdetect()` against epiR 3.0.0 (different interface; the app follows 2.0.67 semantics).

### Browser build / offline (item 15, spike done)
- [x] A real Shinylive build of the package -- done 21 Oct 2026 (`tools/pages/make_app.R`, `app` job of the `docs` workflow: export, boot in headless Chrome from `/app/`, pass/fail check; first passing run: UI visible after 77 s, first calculation 12 s, 64 MB transferred). It is assembled from the package's own `R/` directory (sourced, not a webR-compiled package: the package has no compiled code). Published to Pages under `/app/` beside the pkgdown site **only from `main`**.
- [x] Pages is on and the browser build is published from `main` (done by the owner, 27 Oct 2026). Phones now go to the Connect Cloud version instead; **[owner]** still to try it on a real phone.
- [ ] The browser build downloads about 64 MB on first visit; consider trimming (drop unused heavy packages once item 16 is finished) and measure on a real phone connection.
- [ ] Trial Sequential Analysis (risk ratio) did not finish within 150 s in the last browser crawl (it did in earlier ones): measure and
  speed up or gate it.
- [ ] Browser-build message for the designs that cannot load (TOST means, Fisher, Boschloo): done in the app as a plain message;
  re-check after any dependency change.
- [ ] Measure the real first-load time on a phone connection, mobile memory use, and the TWA / Capacitor wrappers before
  promising an offline Android app. Re-run the spike against the newest webR. **Decision D5 stays open until then.**
- [ ] The `shinylive-spike` workflow runs the whole crawl on every push that touches `tools/webr-spike/`; once the build is
  settled, park it again (`if: false`) or move it to a weekly schedule.

### Documentation site (item 17, built)
- [x] Settings > Pages > Source: *GitHub Actions* and the merge to `main` (done by the owner).
- [ ] **[owner]** The Pages build error reported on 17 Oct: the exact message and where it shows (Settings > Pages, Actions tab, or
  an e-mail) were never supplied; `.nojekyll` was added as a guess.
- [ ] Look at the built site once (navigation, search, MathJax) -- pkgdown could not be run in the development sandbox.
- [ ] Custom domain; a "Try it online" link once a hosted or browser build exists; a link from each calculator page to the
  matching place in the app.

---

## 2. P3 -- distribution and larger workbenches (items 18-22)

### 18. Hosting, Docker, PWA, Android, desktop
- [x] Docker image + CI smoke test (done 21 Oct 2026).
- [x] Hosting for phones: Posit Connect Cloud, deployed from the auto-built `connect` branch (28 Oct 2026). [ ] **[owner]** Long-term choice and budget: free-plan limits are not verified; shinyapps.io is closing to new apps (docs/hosting.md).
- [ ] First publish of the image to GHCR (happens on the first push to `main` or a `v*` tag; not exercised yet).
- [ ] Multi-user scaling: F9 is done (background workers); for many simultaneous users, more workers or several replicas (ShinyProxy) -- check the memory each worker uses on the chosen host first.
- [ ] Image size and an arm64 build (amd64 only today).
- [ ] HTTPS and a domain; then the **PWA** (D4: manifest + service worker), the **Android TWA** (D5a, recommended APK route),
  the **Capacitor bundle** (D5b, needs the browser build), **iOS** via PWA (D6), the **desktop wrapper** (D7, Tauri/Electron).
- [ ] The earlier note that a two-line `app.R` keeps shinyapps.io working was never tested: test a real shinyapps.io deploy.

### 19. Release channels (Track C3 / C4)
- [ ] r-universe release (automatic binaries, including WebAssembly builds).
- [ ] CRAN: split a computation-only core from the app (C3), Monte Carlo tests behind `skip_on_cran()`, fast examples, ASCII-only
  source (escape `²` and the like), `R CMD check` clean, `available::available("epidemiologysuite")` for the name.
- [ ] Public API (C2): decide the exported function names (a consistent `ss_*()` family), more than the two help pages that exist,
  vignettes per family.
- [ ] **[owner]** Rename the GitHub repository (done 30 Oct 2026: `Sample_size_all` -> `Epidemiology_suite`), first release number (done: 1.0.0),
  `NEWS.md` (done 30 Oct 2026); `Authors@R` details for CRAN are still open.

### 20. Survey / field epidemiology (B3), outbreak and surveillance (B4), infectious-disease teaching models (B5)
- [x] **B3** sample selection (SRS, systematic, PPS, EPI 30 x 7) and survey weights -- done 21 Oct 2026.
- [ ] B3 extras, none promised: post-stratification / raking to external totals, weight trimming, variance estimation for the selected design, two-stage selection of subjects inside clusters, an AAPOR-style response-rate table.
- [x] **B4** rates from counts: attack rate, exposure-specific table, secondary attack rate, case fatality -- done 21 Oct 2026.
- [x] **B4** aberration detection from counts (EARS C1-C3, CUSUM normal and Poisson) on a pasted series -- done 21 Oct 2026. Not done, none promised: seasonal / day-of-week baselines (e.g. Farrington-type or regression-based detection), two-sided CUSUM, an adjustable false-alarm-rate calculator (ARL table), and a shape check of the series (zero-inflation).
- [ ] **B4** line-list upload, epidemic curves, R0 / Rt (`EpiEstim` for Rt; check webR availability) -- **deferred by D1** with B6.
- [x] **B5** SIR / SEIR teaching models with vaccination, herd-immunity threshold, coverage needed, R0 from growth rate or final size (base-R RK4, no `deSolve` at run time) -- done 21 Oct 2026. Not done, none promised: waning immunity / births and deaths (endemic SIRS), vaccination during the epidemic (time-varying coverage), age-structured mixing and a contact matrix, leaky vs all-or-nothing vaccine distinction, stochastic runs, a calibration of the model to pasted case counts.

### 21. Evidence synthesis and the raw-data workbench
- [ ] **B7** pooling from study summaries (fixed / random effects, forest plot); `metafor` is heavy, so a base-R implementation
  verified against it is the likely route.
- [ ] **B6** raw-data analysis workbench (upload CSV, "Table 1", crude / adjusted estimates, Kaplan-Meier) -- **deferred by D1**;
  needs a data-privacy policy first.
- [ ] **B8** teaching mode: interactive power curves, sampling-distribution and CI-coverage demos (rides on the curves of item 10).

### 22. Accessibility, mobile, dark mode
- [ ] See section 1 (F11).

---

## 3. Sample-size catalog (Track A of the roadmap)

These come from the three tables in section 4 of the roadmap and are copied here word for word in short form; the roadmap has
the full wording and the checklists (`docs/checklist_by_design.md`, `docs/checklist_by_test.md`) have the per-design status
(at the last count, 13 designs and 5 tests open).

### A.1 Not built (each with what would unblock it)

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

### A.2 Paused by the owner (do not start until reopened)

- [ ] **External validation — time-to-event (Riley et al. 2022)** -- Paused at the owner's request pending paper access. Note for later: `pmvalsampsize` (already used for the binary case from its GitHub mirror) may have a time-to-event branch worth checking first
- [ ] **Model updating / recalibration; ML model sample size; calibration-assessment sample size** -- Paused at the owner's request, same reason

### A.3 Shipped, with an open half

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
- [x] **Free-text study-design parser** -- RCT internals done 27 Oct 2026 (unit, intent, outcome, groups rules; an unqualified "trial" is assumed individually randomised and the trail shows it as Medium confidence)
- [ ] **Non-inferiority margins (RR / OR / HR / difference)** -- open: True **relative-risk-scale** margin. `TrialSize::RelativeRisk.NIS()` is really odds-ratio-based, so it ships as the OR design; no verified RR-scale source yet. *Added 28 Sep 2026 from the review-PDF cross-check*
- [ ] **Holm / FDR** -- open: **Holm's step-down** as its own design. Bonferroni (shipped) is Holm's most conservative step; Holm's later thresholds depend on the observed p-values, so there is no single planning alpha — needs a simulation-based design. *Added 28 Sep 2026*
- [ ] **Value of information (EVPI / EVSI)** -- open: Multi-parameter EVPPI and non-Normal outcomes (only the single-parameter, known-SD case ships). *Added 28 Sep 2026*
- [ ] **Bioequivalence (TOST)** -- open: Reference-scaled designs for highly variable drugs (RSABE / ABEL): the 2×2, 2×2×4 and 2×3×3 designs ship with fixed 80–125% limits; `PowerTOST::sampleN.RSABE()`/`sampleN.scABEL()` exist in a runtime package but are simulation-based and not wired in. (Named in the checklist, not in the review PDF.) *Added 28 Sep 2026*
- [ ] **Multi-arm vs. common control** -- open: Dunnett for **binary** outcomes (means only; the wizard falls back to Bonferroni/Sidak two-proportion n). *Added 28 Sep 2026*

### A.3b Several measurements per patient (asked and built 29 Oct 2026)
- [x] Eyes / Lesions per Patient module: treatment between patients (two means, two proportions; fixed or varying units per patient),
  treatment within patients (split-face, one eye per arm; two means), and "units per patient needed" for a fixed number of patients,
  with the floor. Checked against `clusterPower::cpa.normal()` / `cpa.binary()`, `pwr` and simulation.
- [ ] Open: binary outcome with both treatments in each patient (clustered McNemar; needs a checked source), a patient-by-treatment
  variance part for the split designs, unequal allocation, different numbers of units in the two arms, the Rosner-Milton / Obuchowski
  style tests for the analysis side, cluster-count curves for the units-needed mode.

### A.4 Wizard
- [x] Free-text parser: RCT internals now have rules (27 Oct 2026); revisit with real user phrasing.

---

## 4. Decisions waiting for the owner

| # | Question | Where it matters |
|---|---|---|
| D6 | When to reopen the paused items (Riley et al. 2022 external validation; model updating / ML model sample size) | roadmap A.2; suggested: when paper access is available |
| D5 | Offline / Android route: only after the browser build is measured on a phone | section 1 (browser build), item 18 |
| -- | Hosting platform and budget | item 18 |
| -- | Enable GitHub Pages (source: GitHub Actions) and merge to `main` | documentation site |
| -- | Repository name, first release, CRAN or r-universe first | item 19 |
| -- | Whether to widen the suite beyond summary-data tools (raw-data workbench, line-list epidemic curves, Rt) | D1, items 20-21 |

---

## 5. Housekeeping

- [ ] Section 1 of the roadmap ("Where the project stands") now has the module and import counts; its test counts, checklist
  coverage and wizard figures (487 test blocks, 81/94, 49/49) are still the 28 September values.
- [ ] Re-snapshot `renv.lock` if a dependency is added or removed (it still lists the removed runtime packages, which is
  intended: the tests use them as oracles).
- [ ] Keep `docs/checklist_by_design.md` / `checklist_by_test.md` in step with the Analyze and planning modules (they predate them).

### Start-up, wizard and UI (27 Oct 2026)
- [x] Lazy loading in the browser build on CI: UI visible 77 s -> 27 s, first calculation 12 s -> 5.4 s. [ ] Still to measure on a real phone.
- [ ] The 64 MB package download of the browser build is the remaining start-up cost; trimming needs the item-16 dependency work.
- [ ] Background loading order and the four start-up calculators are a guess at what people use first: revisit with real usage.
- [ ] Wizard: a cohort with a *continuous exposure* (dose-response) and a case-control with a *categorical* exposure still go to the
  yes/no routes; a case-control with several controls per case and a measured exposure uses the paired test (1:m is approximate).
- [ ] The keyword parser is deliberately conservative; a language-model option would need an API decision (the app has none).
- [ ] UI audit: not run on a real phone or with a screen reader; item 22 (accessibility, dark mode) is still open.

### Dependency reduction stage 2 (28 Oct 2026)
- [ ] Re-snapshot `renv.lock` (it still lists the seven removed runtime packages and kappaSize's place has changed).
- [ ] Optional: re-derive `kappaSize`'s kappa tables (2-6 raters, 2-5 categories) and drop the last of the easy/moderate set.
- [ ] Report the two package bugs upstream (pmsampsize continuous criterion 4 sign error; presize prec_pos_lr / prec_neg_lr ignoring conf.level).
- [ ] Remaining heavier ones: `PowerTOST`, `Exact`, `clinfun`, `lme4` (see the dependency section above).

### Three versions (28 Oct 2026, see docs/hosting.md)
- [ ] **[owner]** Create the Posit Connect Cloud account, publish from the branch `connect`, then put its address in `tools/pages/mobile_url.txt` (PR).
- [ ] Open the Connect version on a phone; if it works, the "lite" mobile webR build is not needed (dropped from the plan).
- [ ] Check the Connect Cloud free-plan limits (apps, active hours, memory) and idle sleep; decide if a paid plan or the Docker image elsewhere is needed.
- [ ] Mention in the app that the server version sends inputs to the server (the browser version does not); add to the Connect build's home text.
- [ ] Phone layout pass (single column, large touch targets) now that phones will use the server version (item 22).
- [ ] Async / several users on one R process (F9) matters more once phones use the server version.

---

## 6. Added on 29 October 2026 (open items)

### Interface
- [ ] "Advanced options" folded inside the other ~60 calculators (done for Proportions, Means, Case-Control, Cohort, Correlation, Diagnostic Accuracy and, 30 Oct, the alternative hypothesis of Variance Tests and Multiplicity Adjustment): decide per calculator which inputs are optional, most-used first. Looked at on 30 Oct and left as they are: Longitudinal (one alternative-hypothesis choice per design, and the Diggle design defaults to one-sided, which should stay visible) and Group Sequential (the alternative belongs to the boundary set-up). The other modules have no optional inputs of this kind.
- [ ] Two-column layout on wide screens (inputs left, result right) -- optional now that the result is pinned.
- [ ] Phone: a separate slimmer app with only the common calculators (not built; the phone layout is the same app); the dark-mode switch is hidden on phones; a check on a **real phone and in Safari** (only an emulated iPhone has been tried).
- [ ] A person's keyboard and screen-reader walk-through; dark-mode plots (plots stay white); text-resize and reduced-motion checks.
- [ ] Home: the quick links and cards are a guess at what people use first -- revisit with real usage.

### Package and citation
- [x] Three vignettes (Getting started, Sample sizes from R, Analysing summary data from R), 30 Oct 2026. [ ] More per-family vignettes (survival, trials, diagnostic accuracy, surveillance) and more examples where a calculator has several designs.
- [ ] r-universe release, then CRAN: split a computation-only core from the app, `skip_on_cran()` for the Monte Carlo and browser tests, ASCII-only source, a name decision. `R CMD check --as-cran` already passes the package checks.
- [ ] **[owner]** Zenodo: archive a release and send the DOI; put it in `R/citation_info.R`, `CITATION.cff` and `inst/CITATION` (docs/hosting.md, "Adding the Zenodo DOI"); the first record was removed because its version tag was wrong; publish the release `v1.0.0` again (the version is now 1.0.0, set in `DESCRIPTION`, `R/citation_info.R`, `CITATION.cff` and `inst/CITATION`).
- [ ] **[owner]** Rename the repository (then update the addresses in the same three files, the Pages and Connect addresses, and `mobile_url.txt` if the Connect address changes).
- [ ] Possible wrappers `ss_text()`, `ss_curve()`, `ss_export()` around the `ss_result` object; the `calc_*` names are the public API for now.

### Eyes / Lesions per Patient (built 29 Oct 2026)
- [ ] Binary outcome with both treatments in each patient (clustered McNemar; needs a checked source), a patient-by-treatment variance part for the split designs, unequal allocation, different numbers of units in the two arms, the analysis side (Rosner-Milton / Obuchowski tests).

### Housekeeping
- [x] The checklists now list the Analyze, planning, survey, outbreak, epidemic-model and eyes / lesions tools (`checklist_by_design.md` §18, `checklist_by_test.md`, 29 Oct 2026).
- [ ] `renv.lock` still lists packages that were removed from the runtime (intended: the tests use them as oracles) and not the packages added for the tests (`shinytest2`, `chromote`, ...); re-snapshot when convenient.
- [ ] The sandbox's `R CMD check` ends with a locale warning and a clock note that are not the package's; confirm on a normal machine or in CI.
