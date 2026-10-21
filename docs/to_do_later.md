# To do later

Everything that is **not finished yet**, in one list, in roadmap order (start to end), so it can be picked up later
without reading the whole [`ROADMAP.md`](ROADMAP.md). The roadmap stays the source of truth for the reasoning and the
evidence; this file is the checklist. Tick an item here when it is done *and* record it in the roadmap.

*Compiled 21 October 2026 from the roadmap as it then stood (items 1-19 and the browser/Docker work done; item 20 started).
Items marked **[owner]** need a decision or an action only the repository owner can take (an account, a setting, a
budget, a name). Items marked **[blocked]** wait on something outside the code (a paper, a package, an account).*

---

## 1. Open from the priority list (§3 of the roadmap)

### P0 / P1 leftovers
- [ ] **Async compute for Monte Carlo designs (finding F9, item 7 second half).** The "Calculate" button exists; still missing is
  `shiny::ExtendedTask` with a background process so one user's running simulation does not block the other users of the
  same R process. Matters as soon as the app is hosted for several people.
- [ ] **`bindCache()` for closed-form results** (Track E, P2): cheap speed-up for repeated identical inputs.
- [ ] **Accessibility and mobile audit, dark mode (finding F11, item 22).** A WCAG AA pass (labels, contrast, keyboard use,
  screen-reader names for the generated tables and plots), a small-screen layout pass for the calculator forms, a dark theme.
  English only (D5).

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
- [ ] Remaining low-weight imports: `pwr`, `powerMediation`, `pmsampsize`, `pROC` (each under 1 MB; reimplement and test against
  the package as was done for `epiR`, `Hmisc`, `tseries`, `BayesFactor`, `rstatix`).
- [ ] Moderate: `presize`, `powerSurvEpi`, `TrialSize`.
- [ ] Higher risk, defer: `PowerTOST` (also what breaks the browser build), `Exact` / Boschloo (needs `rootSolve`, no WebAssembly
  build), `clinfun` (`ph2simon`, group-sequential). `lme4` stays (the Monte Carlo mixed-model designs need it); `mvtnorm`, `shiny`,
  `bslib` stay.
- [ ] Re-check `epi.ssdetect()` against epiR 3.0.0 (different interface; the app follows 2.0.67 semantics).

### Browser build / offline (item 15, spike done)
- [ ] A real Shinylive build of the *package* (the spike sources the R files into a generated app): the start-up step that loads
  `MASS` and `lme4` first, the `MASS` bundling hint, and a webR build of the package itself.
- [ ] Trial Sequential Analysis (risk ratio) did not finish within 150 s in the last browser crawl (it did in earlier ones): measure and
  speed up or gate it.
- [ ] Browser-build message for the designs that cannot load (TOST means, Fisher, Boschloo): done in the app as a plain message;
  re-check after any dependency change.
- [ ] Measure the real first-load time on a phone connection, mobile memory use, and the TWA / Capacitor wrappers before
  promising an offline Android app. Re-run the spike against the newest webR. **Decision D5 stays open until then.**
- [ ] The `shinylive-spike` workflow runs the whole crawl on every push that touches `tools/webr-spike/`; once the build is
  settled, park it again (`if: false`) or move it to a weekly schedule.

### Documentation site (item 17, built)
- [ ] **[owner]** Settings > Pages > Source: *GitHub Actions*, then merge the working branch to `main` so the `docs` workflow deploys.
- [ ] **[owner]** The Pages build error reported on 17 Oct: the exact message and where it shows (Settings > Pages, Actions tab, or
  an e-mail) were never supplied; `.nojekyll` was added as a guess.
- [ ] Look at the built site once (navigation, search, MathJax) -- pkgdown could not be run in the development sandbox.
- [ ] Custom domain; a "Try it online" link once a hosted or browser build exists; a link from each calculator page to the
  matching place in the app.

---

## 2. P3 -- distribution and larger workbenches (items 18-22)

### 18. Hosting, Docker, PWA, Android, desktop
- [x] Docker image + CI smoke test (done 21 Oct 2026).
- [ ] **[owner]** Where to host (shinyapps.io, Posit Connect, Fly.io / Render / a VPS running the image) and the budget.
- [ ] First publish of the image to GHCR (happens on the first push to `main` or a `v*` tag; not exercised yet).
- [ ] Multi-user scaling: ShinyProxy or several replicas, until F9 (`ExtendedTask`) is done.
- [ ] Image size and an arm64 build (amd64 only today).
- [ ] HTTPS and a domain; then the **PWA** (D4: manifest + service worker), the **Android TWA** (D5a, recommended APK route),
  the **Capacitor bundle** (D5b, needs the browser build), **iOS** via PWA (D6), the **desktop wrapper** (D7, Tauri/Electron).
- [ ] The earlier note that a two-line `app.R` keeps shinyapps.io working was never tested: test a real shinyapps.io deploy.

### 19. Release channels (Track C3 / C4)
- [ ] r-universe release (automatic binaries, including WebAssembly builds).
- [ ] CRAN: split a computation-only core from the app (C3), Monte Carlo tests behind `skip_on_cran()`, fast examples, ASCII-only
  source (escape `²` and the like), `R CMD check` clean, `available::available("epidemiologicasuite")` for the name.
- [ ] Public API (C2): decide the exported function names (a consistent `ss_*()` family), more than the two help pages that exist,
  vignettes per family.
- [ ] **[owner]** Rename the GitHub repository from `Sample_size_all` (changes the install path), `Authors@R` details, first public
  release number and a `NEWS.md`.

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
- [ ] **Free-text study-design parser** -- open: RCT internals (individual vs. cluster, superiority vs. non-inferiority)
- [ ] **Non-inferiority margins (RR / OR / HR / difference)** -- open: True **relative-risk-scale** margin. `TrialSize::RelativeRisk.NIS()` is really odds-ratio-based, so it ships as the OR design; no verified RR-scale source yet. *Added 28 Sep 2026 from the review-PDF cross-check*
- [ ] **Holm / FDR** -- open: **Holm's step-down** as its own design. Bonferroni (shipped) is Holm's most conservative step; Holm's later thresholds depend on the observed p-values, so there is no single planning alpha — needs a simulation-based design. *Added 28 Sep 2026*
- [ ] **Value of information (EVPI / EVSI)** -- open: Multi-parameter EVPPI and non-Normal outcomes (only the single-parameter, known-SD case ships). *Added 28 Sep 2026*
- [ ] **Bioequivalence (TOST)** -- open: Reference-scaled designs for highly variable drugs (RSABE / ABEL): the 2×2, 2×2×4 and 2×3×3 designs ship with fixed 80–125% limits; `PowerTOST::sampleN.RSABE()`/`sampleN.scABEL()` exist in a runtime package but are simulation-based and not wired in. (Named in the checklist, not in the review PDF.) *Added 28 Sep 2026*
- [ ] **Multi-arm vs. common control** -- open: Dunnett for **binary** outcomes (means only; the wizard falls back to Bonferroni/Sidak two-proportion n). *Added 28 Sep 2026*

### A.4 Wizard
- [ ] Free-text parser: the RCT-internals branch (individual vs cluster allocation, superiority vs non-inferiority) has no
  keyword rules, deliberately; revisit with real user phrasing.

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
