# Roadmap — from Sample Size Calculator to Epidemiology Suite

| | |
|---|---|
| **Status** | Active — authoritative forward plan |
| **Last reviewed** | 28 September 2026 (full codebase + docs review) |
| **Owner** | Dr. Mukul Maheshwari |

**How the docs fit together**

- **This file** — where the project goes next, in what order, and why. Every open or
  blocked item lives here with the condition that would unblock it. Nothing is
  removed from this roadmap because it is hard; it is only re-tiered.
- [`checklist_by_design.md`](checklist_by_design.md) /
  [`checklist_by_test.md`](checklist_by_test.md) — per-item build status and the
  verification evidence behind every shipped sample-size design.
- [`SDD.md`](SDD.md) — architecture, module contract, conventions.
- [`project-brief.md`](project-brief.md) — the original brief (historical).

---

## 1. Where the project stands

| Measure | Value |
|---|---|
| Calculator modules | **49**, in 14 navbar groups |
| Individual designs | **~155** (152 in the Browse catalog + 3 Longitudinal designs missing from it, see F2) |
| Checklist coverage | By design: **81 / 94** done (13 open) · By test: **69 / 74** done (5 open) |
| Unit tests | **474** `test_that()` blocks across 54 files, every design checked against a published worked example, a real package (oracle), or simulation |
| Runtime packages | **19** in `global.R` + `survival`/`stats` from base R |
| Verification-only packages | ~30 more (installed from the `github.com/cran` mirror, used only to check reimplementations — never shipped) |
| Wizard coverage | "Which calculator?" reaches **14 / 49** modules (see F1) |
| Distribution | Source-only (clone + `shiny::runApp()`); no package, no CI, no hosted build |

The sample-size catalog is now effectively complete within the project's own rules
(every formula traceable to a published source and verified numerically; no new
runtime dependency without a decision). Everything still open is either genuinely
hard to reimplement safely, has no citable method, or needs a source this sandbox
cannot reach — see §4.

---

## 2. Review findings (28 Sep 2026)

| # | Finding | Evidence | Severity |
|---|---|---|---|
| F1 | **Wizard is badly out of sync with the app.** Only 14 of 49 modules are reachable from "Which calculator?", and 16 wizard endpoints still say "not yet built" for things that *are* built (ROC/AUC, Bland-Altman, CCC, Cronbach's alpha, ratio precision, crossover, stepped-wedge, bioequivalence, group sequential, nested case-control, case-cohort, SCCS, ordinal outcome, McNemar, prediction models) | `R/home/design_tree.R` terminals with `would_use` instead of `catalog_key` | **High** — the wizard is the main entry point for students and it currently gives wrong "not built" answers |
| F2 | **Browse catalog gaps.** "Two paired/dependent proportions" is marked `built = FALSE` though McNemar's test is live in Chi-Square Tests; Longitudinal's Diggle, Edland and Hu designs have no catalog entry, so they can't be found from Browse | `calculator_catalog` vs. each module's `design` radio values | Medium |
| F3 | **Stale documentation.** README described 24 modules, SDD's roadmap marked finished stages "not started", SDD appendix listed packages never used (`WebPower`, `pwrss`, `precisely`); one ticked checklist note (logistic covariate adjustment) still says "not covered" | fixed in this refresh (README, SDD, and the checklist note) | Low (fixed) |
| F4 | **No CI and no dependency lock.** Environment is rebuilt by `.claude/hooks/session-start.sh` from latest GitHub-mirror sources — not reproducible, and a package update could silently change a result | no `.github/`, no `renv.lock` | Medium |
| F5 | **Slow test suite.** Full run takes ~6–10 min, dominated by Monte Carlo tests (`test-calc_glmm.R` alone several minutes); there is no fast/slow split | observed across every batch | Medium |
| F6 | **No automated UI tests in the repo.** Every browser check so far was an ad-hoc Playwright script in a scratch directory | nothing under `tests/` beyond `testthat` unit tests | Medium |
| F7 | **Not yet package-shaped.** R packages need a flat `R/` directory (current code uses `R/calc/`, `R/modules/`, …), a `DESCRIPTION`/`NAMESPACE`, and no `source()`-based loading; tests `source()` files by relative path; `pacman::p_load()` auto-installs, which packages must not do | repo layout, `global.R`, test headers | Medium (blocks Track C) |
| F8 | **Licensing check needed before any public package release.** The project is MIT, but several modules were built by reading and transcribing source from GPL-licensed packages (e.g. `PracTools` GPL-3, `ssize.fdr` GPL-3, `voi` GPL-3, `clusterPower` GPL≥2, `semTools` GPL≥2, `simr` GPL≥2, `metapower` GPL-2, `WebPower` GPL≥3, `rpact` LGPL-3). Mathematical formulas aren't copyrightable, but closely transcribed code may count as a derivative work. *Not legal advice* — see decision D2 | package `DESCRIPTION` licenses; module header comments | **High** for Track C/D, none for private use |
| F9 | **Monte Carlo modules block the server.** Shiny runs one R process per app instance; a 5–25 s simulation (Monte Carlo Mixed Models, RMST, weighted log-rank, BFDA, KS/runs) freezes every other user on that instance, and these modules recompute on every input change | observed during browser verification | Medium (High once hosted for many users) |
| F10 | **No results export or report.** Users can't download results, a methods paragraph, or citations — the biggest gap versus how the output is actually used (protocols, theses, ethics submissions) | no download handlers anywhere | Medium |
| F11 | **Accessibility, mobile layout and i18n never audited.** | — | Low–Medium |

---

## 3. Priority list

Tiers are ordered by value ÷ effort and by what unblocks what. Work top-down; the
blocked sample-size items (§4) run in parallel whenever their unblock condition is met.

### P0 — hygiene, do next (small, high value)

1. **Re-sync the wizard (F1):** point all 16 stale terminals at their live catalog
   keys; add routes for the ~35 unreachable modules where the decision tree has a
   natural branch (survey/sampling, trials, survival, prediction, psychometrics,
   health economics, meta-analysis); add a unit test asserting every wizard
   terminal with a `catalog_key` resolves to a `built = TRUE` entry.
2. **Re-sync the catalog (F2):** point "paired proportions" at McNemar; add
   Diggle/Edland/Hu entries; add a unit test that every module `design` radio value
   has a catalog entry (the check used in this review, made permanent).
3. ~~Fix the stale logistic covariate-adjustment checklist note (F3).~~ Done in this
   refresh.
4. **Fast/slow test split (F5):** skip Monte Carlo tests unless an env var is set
   (`SSC_SLOW_TESTS=true`); target < 2 min for the default run.
5. **Add CI (F4):** GitHub Actions running the fast suite on every push, slow suite
   weekly/manual.
6. **Lock dependencies (F4):** add `renv.lock`; point the SessionStart hook at it.

### P1 — foundations for the suite

7. **Explicit "Calculate" button + async for Monte Carlo modules (F9)** — first
   `bindEvent()` on a button (no new deps), then `shiny::ExtendedTask` with a
   background process so one user's simulation never freezes another's.
8. **Standard result object** — have every `calc_*()` return a common S3 class
   (`n`, achieved power, inputs, method, citation) with `print`/`format`. Unblocks
   export, reports, the package API, and power curves in one go.
9. **Results export (F10)** — per-result "copy" and CSV/JSON download, a
   *sample-size justification paragraph* generator (design + inputs + result +
   citation, ready to paste into a protocol), citation export (BibTeX/RIS).
10. **Power/sensitivity curves** for every closed-form design (n vs. effect size,
    n vs. power).
11. **Package skeleton (Track C1)** + **licence decision (D2)**.
12. **Automated UI smoke tests (F6)** with `shinytest2` — one per module.

### P2 — first suite expansion + portability

13. **Analyze workbench v1** (Track B1) — OpenEpi-parity calculators from summary
    counts, almost entirely on `epiR` (already a dependency).
14. **Planning tools** (Track B2) — randomization lists, attrition/non-response
    inflation, protocol text.
15. **Shinylive feasibility spike** (Track D3) — decides the offline/APK path.
16. **Phase 8 dependency reduction, tier 1** (§9) — also de-risks D3 and CRAN.
17. **pkgdown documentation site** (free, GitHub Pages).

### P3 — distribution and larger workbenches

18. Hosted deployment + Docker image (D1), PWA (D4), Android APK via TWA (D5a),
    desktop wrapper (D7).
19. r-universe release, then CRAN (Track C4).
20. Survey/field-epi tools (B3), outbreak & surveillance (B4), ID modelling for
    teaching (B5).
21. Decide on (and possibly build) the raw-data analysis workbench (B6) and
    evidence synthesis (B7).
22. Accessibility/mobile audit, dark mode, translations (F11).

---

## 4. Track A — sample-size catalog: open, blocked and partial items (all kept)

Nothing here is dropped. Each item names what would unblock it; when that happens it
moves into the current priority tier.

### A.1 Open items (not built)

| Item | Why it is open | Unblock condition |
|---|---|---|
| Multi-reader multi-case (MRMC) — Obuchowski-Rockette / DBM | `iMRMC` is installable, but its Roe-Metz simulation model needs 6 fixed effects + 18 variance components before the OR/DBM analysis step — too large to reimplement and verify safely in one batch | Dedicated multi-batch effort using `iMRMC` as oracle; or relax the vendoring rule and wrap `iMRMC` directly |
| Dose-finding / phase I (3+3, CRM) | Output is *operating characteristics at a fixed n*, not a required n; needs full simulation of the sequential Bayesian/MLE dose-escalation procedure | Build a reusable "operating-characteristics simulator" module type, verify against `dfcrm::crmsim()` (installed) |
| Platform / basket / umbrella trials | `basket` is analysis-only; `gsbDesign` is a different (two-arm) tool | Same simulator framework as CRM; or a multi-arm group-sequential design verified against `rpact` (installed) |
| N-of-1 trials | `nof1`/`Nof1` unreachable (not on the CRAN mirror); no single accepted formula | CRAN/Bioconductor access, or a citable period-count formula with a worked example |
| One-sample survival vs. historical control | Closed form exists (Finkelstein et al. 2003; Schmidt et al. 2015) but every source with the equations is network-blocked here; web-search snippets aren't enough to verify | Access to the paper or the NCSS/PASS manual; verify one worked example |
| GWAS / candidate-gene association | `genpwr`/`Haplin` installed, but both are numerical-MLE engines (root-finding over likelihood surfaces, many model combinations) | Multi-batch effort with `genpwr` as oracle, or relax vendoring for this one family |
| Gene–environment interaction | Same engine as GWAS | Same as GWAS |
| Microarray / RNA-seq DE (`ssize`, `RNASeqPower`, `PROPER`) | All three are Bioconductor-only, unreachable. *Partly served* by the exact Liu & Hwang FDR design (Multiplicity module) | Bioconductor access |
| Deming / Passing-Bablok method comparison | `deming`, `mcr`, `MethComp` all installed and confirmed analysis-only; literature is simulation-based | A citable simulation protocol (e.g. Linnet) to reproduce, then a Monte Carlo design |
| Propensity-score-matched designs (matching efficiency) | `MatchIt`/`Matching`/`ATE` analysis-only; efficiency depends on each dataset's covariate overlap | A published planning heuristic with a worked example; or a data-driven tool inside the future analysis workbench (B6) |
| Time-varying exposure (OPTITXS) | Not on CRAN; formulas in Basagaña & Spiegelman (2010, 2011) not reachable | Paper access, or the OPTITXS source |
| Random-model multiple regression (Gatsonis & Sampson 1989) | No R package implements it; `WebPower::wp.regression()` is fixed-model only | Paper access; verify against G*Power's random-model output |
| Exact bivariate-normal correlation test | Needs Fisher's exact distribution of r; no package to verify against | Reproduce G*Power's "Exact – bivariate normal" worked values from a citable table |
| General permutation-test power | No general formula by definition (KS and runs tests are covered) | Out of scope unless a specific statistic is named |
| Average coverage criterion / HPD interval width (Joseph & Belisle) | `BayesianPower` installed but implements a different (Bayes-factor) method; *partly served* by Bayesian assurance + BFDA | Paper access or an R implementation to verify against |

### A.2 Paused by the owner (do not start until reopened)

| Item | Status |
|---|---|
| External validation — time-to-event (Riley et al. 2022) | Paused at the owner's request pending paper access. Note for later: `pmvalsampsize` (already used for the binary case from its GitHub mirror) may have a time-to-event branch worth checking first |
| Model updating / recalibration; ML model sample size; calibration-assessment sample size | Paused at the owner's request, same reason |

### A.3 Partially covered (shipped, with an open half)

| Shipped item | Open half |
|---|---|
| Stepped-wedge CRT | Binary outcome (`clusterPower::cpa.sw.binary()` is a numerical GEE procedure, no closed form) |
| Multilevel 2-/3-level | With dropout (`powerlmm`'s matrix-based missing-data calculation) |
| MMRM | General missing-data MMRM beyond the AR(1)/dropout design |
| GEE marginal models | Damped-exponential correlation variant |
| Group sequential / Lan-DeMets | 3+ looks, and binary/survival outcomes for the spending-function design; `spass`-style blinded SSR |
| Trial sequential analysis | Heterogeneity-adjusted (random-effects / diversity-adjusted) information size |
| Meta-analysis power | Network meta-analysis |
| ROC comparison | Unpaired AUCs (`pROC` doesn't support it) |
| LQAS | Cluster-LQAS (heterogeneity-adjusted) |
| MANOVA | Global test for k > 2 groups and special-effect contrasts |
| Compare two dependent correlations | Non-common-index case |
| Ordinal / multinomial regression | Nominal (multinomial) half |
| Agreement | Weighted kappa |
| Free-text study-design parser | RCT internals (individual vs. cluster, superiority vs. non-inferiority) |

---

## 5. Track B — expanding into an epidemiology suite

**Vision.** Follow a study through its whole life, not just the sample-size step:

```
Plan  ─────────▶  Collect  ─────────▶  Analyze  ─────────▶  Report  ─────────▶  Teach
sample size        sampling frames      summary-data         export, methods      curves,
randomization      survey weights       calculators          text, citations      simulations
protocol text      EPI/LQAS tools       (then raw data)
```

The existing 49 modules become the **Plan → Sample size** section. The same
conventions carry over unchanged: every calculator has Calculate / Formula-Help /
Reference tabs, a pure `calc_*()` function, a citation, and a test against a
published worked example.

| Workbench | Contents | Reuse / new deps | Priority | Effort |
|---|---|---|---|---|
| **B1 Analyze from summary data** ("OpenEpi parity") | 2×2 tables: RR, OR, RD, attributable risk, PAF, NNT with CIs; stratified Mantel-Haenszel + homogeneity; CIs for proportions (Wilson, exact, …) and means; person-time rates and rate ratios; direct/indirect standardization and SMR; diagnostic-test evaluation from counts (Se, Sp, PPV, NPV, LRs with CIs); kappa from a table; McNemar/matched-pair analysis; chi-square for trend; vaccine efficacy | Almost all in **`epiR`** (already a dependency: `epi.2by2`, `epi.conf`, `epi.tests`, `epi.directadj`, `epi.indirectadj`, `epi.kappa`, …) — near-zero new dependencies; benchmark against OpenEpi and `epiR`'s own examples | **P2 — first** | Medium |
| **B2 Study planning tools** | Randomization lists (simple, block, stratified; seeded, reproducible), allocation-concealment guidance, attrition / non-response inflation, sample-size justification text (also in P1 export) | Base R | P2 | Low |
| **B3 Survey & field epidemiology** | Sampling-frame selection (SRS, systematic, PPS systematic), EPI 30×7 cluster selection, design weights, non-response adjustment | Base R; `PracTools` logic already studied | P3 | Low–Medium |
| **B4 Outbreak investigation & surveillance** | Attack rates, secondary attack rate, case-fatality; epidemic curves from an uploaded line list; R0/Rt; aberration detection (EARS C1–C3, CUSUM) | Needs data upload; `ggplot2`; `EpiEstim` for Rt (check WebAssembly availability first) | P3 | Medium–High |
| **B5 Infectious-disease modelling (teaching)** | SIR/SEIR with vaccination, herd-immunity threshold, coverage needed | Base-R ODE stepping to stay light (or `deSolve`, compiled) | P3 | Medium |
| **B6 Raw-data analysis workbench** | Upload CSV → descriptive "Table 1", crude/adjusted estimates, Kaplan-Meier | Many new deps; data-privacy policy needed | P3 — **scope decision first (D1)** | High |
| **B7 Evidence synthesis** | Pooling from study summaries (fixed/random effects), forest plots | `metafor` (heavy) | P3 | Medium |
| **B8 Teaching mode** | Interactive power curves, sampling-distribution and CI-coverage demos | Base R + plotting | Rides on P1 item 10 | Low–Medium |

**Cross-cutting features** (benefit every workbench): common result object and export
(P1), bookmarkable/shareable URLs (Shiny bookmarking), dark mode
(`bslib::input_dark_mode()`), accessibility (WCAG AA), translations.

**Navigation redesign needed.** 14 dropdowns already fill the navbar and `bslib`
dropdowns can't nest. With several workbenches, move to a top level of workbenches
(Plan / Collect / Analyze / Report / Learn) with a sidebar or grouped dropdown
(header items + separators) inside each. The Home hub's Browse catalog and wizard
extend to cover analysis tasks too. The app title also changes from "Sample Size
Calculator" to the suite name (D3).

---

## 6. Track C — making it an R package

The codebase is already close: computation is in pure functions with roxygen-style
comments, content is data, and tests use `testthat`.

**C1 — installable package (P1).**
- Add `DESCRIPTION` (Imports = the 19 runtime packages), generate `NAMESPACE` with
  roxygen2.
- Flatten `R/` (required by R packages). File names are already prefixed
  (`calc_`, `content_`, `mod_`, `home_`/`design_`), so this is mechanical.
- Replace `global.R`'s `source()` loop and `pacman::p_load()` with the package
  namespace; expose `run_app()`. Keep a two-line root `app.R`
  (`pkgload::load_all(); run_app()`) so shinyapps.io deploys keep working.
- Rewrite test headers to use the package (drop the `source()` lines).
- Install path: `remotes::install_github("SpaRroW410/Sample_size_all")`.

**C2 — public API (P2).** Decide exported names (e.g. a consistent `ss_*()` family),
adopt the common result class (P1 item 8), write one vignette per family, publish a
**pkgdown** site.

**C3 — split for CRAN (P3).** A computation-only core package (no Shiny, CRAN-friendly)
plus an app package that depends on it. CRAN needs: Monte Carlo tests behind
`skip_on_cran()`, fast examples, ASCII-only code (escape `²` etc.), the licence
question resolved (F8/D2), and ≤ 20 Imports (Phase 8 helps).

**C4 — release channels (P3).** GitHub → **r-universe** (automatic binaries,
including WebAssembly builds for webR, which Track D3 needs) → CRAN.

**Name.** To be decided (D3). Check CRAN/Bioconductor for collisions first — e.g.
`epicalc` is an archived CRAN package, and `epiR`/`epitools`/`epibasix` exist.

---

## 7. Track D — deployment and distribution

| Option | How | Offline? | Needs a server? | Feasibility today | Main blockers / notes |
|---|---|---|---|---|---|
| **D1 Hosted web** | shinyapps.io, Posit Connect Cloud, own VPS with Shiny Server, or **Docker** (`rocker/shiny`) for institutional servers / ShinyProxy | No | Yes | **Feasible now** | Needs F9 (async) before many concurrent users; free tiers have hour limits |
| **D2 R package** | `install_github()` / r-universe / CRAN, then `run_app()` | Yes (local R) | No | After C1 | Users need R installed — fine for faculty/researchers |
| **D3 Shinylive (WebAssembly) static site** | `shinylive::export()` → GitHub Pages; runs entirely in the browser | Yes, after first load | **No** | **Conditional — needs a spike** | Every runtime package needs a webR binary (check each of the 19 on `repo.r-wasm.org`); compiled packages (`lme4`, `BayesFactor`, `Hmisc`, `mvtnorm`, …) are the risk; first load downloads tens of MB. Mitigate with Phase 8 and lazy per-module loading. Could not be checked from this sandbox (egress blocked) |
| **D4 PWA** (installable web app) | Manifest + service worker on top of D3 (offline) or D1 (online shell) | With D3 | With D1 | After D3/D1 | Low effort; installs on Android, iOS, desktop from the browser |
| **D5a Android APK — Trusted Web Activity** | Bubblewrap/PWABuilder wraps the D4 site into a Play-Store APK/AAB | With D3 | No (static hosting) | After D4 | Needs an HTTPS domain + Digital Asset Links; small APK; **recommended APK route** |
| **D5b Android APK — Capacitor bundle** | Ships the Shinylive export *inside* the APK | Fully | No | Spike after D3 | Larger APK (webR runtime + packages); webR worker inside an Android WebView must be tested |
| **D5c Android APK — thin WebView** | APK that just opens the hosted D1 URL | No | Yes | Feasible now | Least value; only a stopgap |
| — Native R on Android | — | — | — | **Not feasible** | There is no R runtime for Android apps |
| **D6 iOS** | PWA via Safari (D4); App Store wrapper via Capacitor later | With D3 | No | After D4 | App Store review, developer fee |
| **D7 Desktop (Win/macOS/Linux)** | Tauri/Electron wrapper around the D3 export; or portable R + app | Yes | No | After D3 (wrapper) | Before D3, the R package (D2) is the desktop story |

**Recommended order:** D1 (Docker + hosted) and D2 first → D3 spike → D4 → D5a →
D7. The D3 spike is the single decision point for everything offline, which is why
Phase 8 dependency reduction matters beyond tidiness.

---

## 8. Track E — engineering and quality

| Item | Detail | Tier |
|---|---|---|
| CI | GitHub Actions: fast suite on push, slow suite weekly/manual | P0 |
| Reproducible environment | `renv.lock`; SessionStart hook restores from it | P0 |
| Test split | Env-var-gated Monte Carlo tests; default run < 2 min | P0 |
| Consistency tests | Every wizard terminal and module design resolves to a built catalog entry | P0 |
| UI tests | `shinytest2`, one smoke test per module | P1 |
| Async compute | Calculate button, then `ExtendedTask` for Monte Carlo modules | P1 |
| Result object | Common S3 class across all `calc_*()` | P1 |
| Caching | `bindCache()` for pure closed-form results | P2 |
| Accessibility / mobile | WCAG AA audit, small-screen layout pass | P3 |

---

## 9. Phase 8 — dependency reduction (existing plan, now P2)

Shrink `global.R`'s runtime list by reimplementing formulas where that is tractable,
using the project's established "read the source, transcribe, verify numerically"
pattern (licence caveat F8 applies). This now serves three goals: reproducibility,
Shinylive/APK feasibility (fewer compiled packages), and CRAN's Imports limit.

- *Low effort / high value:* `pwr`, `Hmisc` (3 functions used), `tseries::runs.test()`
  (also a speed win inside simulations), `powerMediation`, `pmsampsize`, `pROC`.
- *Moderate:* `presize`, `epiR`*, `powerSurvEpi`, `TrialSize`, `BayesFactor::ttestBF()`.
- *Higher risk — defer:* `clinfun::ph2simon`, `Exact` (Boschloo), `PowerTOST`,
  `clinfun::gsdesign.*`.
- *Keep:* `mvtnorm`, `shiny`, `bslib`.

\* `epiR` becomes *more* valuable once the Analyze workbench (B1) builds on it, so
reconsider removing it at that point.

---

## 10. Decisions needed from the owner

| # | Decision | Why it matters | Suggested default |
|---|---|---|---|
| D1 | Suite scope: summary-data calculators only, or also a raw-data analysis workbench? | B6 roughly doubles the project's size and adds data-privacy duties | Summary-data first (B1–B5); revisit B6 after B1 ships |
| D2 | Licence: keep MIT (with a clean-room policy and re-derivation of transcribed code) or relicense to GPL-3? | Needed before any public package/CRAN release (F8) | GPL-3 is the simplest fit with the source packages; get advice if the institution has a policy |
| D3 | Suite and package name; one package or core + app split | Everything user-facing and the CRAN submission | Pick the name now; single package until CRAN, then split |
| D4 | Primary distribution target: hosted web, or offline/APK first? | Sets the urgency of Phase 8 and the D3 spike | Hosted + R package first; APK after the D3 spike succeeds |
| D5 | Languages: English only, or add Hindi/regional languages? | Affects how UI text is stored (translation keys vs. literals) | English now, but store new UI text so it can be translated later |
| D6 | When to reopen the two paused items (A.2) | They're waiting on paper access | Reopen once paper access is available |

---

## 11. Suggested milestones

| Milestone | Contents | Exit criterion |
|---|---|---|
| **M0 Hygiene** | P0 items 1–6 | Wizard and catalog tests pass; CI green; fast suite < 2 min |
| **M1 Foundations** | Calculate button + async, result object, export + justification text, power curves, package skeleton, licence decision | `run_app()` works from an installed package; results downloadable |
| **M2 Analyze v1** | B1 calculators + navigation redesign | Reproduces OpenEpi/`epiR` worked examples; wizard covers analysis tasks |
| **M3 Portability** | Shinylive spike, Phase 8 tier 1, pkgdown site | Go/no-go on offline/APK, with evidence |
| **M4 Planning & field tools** | B2, B3 | Randomization lists reproducible by seed |
| **M5 Distribution** | Docker + hosted, PWA, APK (TWA), r-universe | Installable on Android; installable from r-universe |
| **M6 Surveillance, modelling, CRAN** | B4, B5, C3 | CRAN check clean |
| **Ongoing** | Track A items whenever their unblock condition is met | — |
