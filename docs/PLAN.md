# Epidemiological suite: the plan at a glance

*Updated 29 October 2026. Struck-through items are done (the date in brackets is when). The reasoning, evidence and the full
list of blocked sample-size items are in [`ROADMAP.md`](ROADMAP.md); the flat checklist of everything open is
[`to_do_later.md`](to_do_later.md). The package is still named `epidemiologicasuite`; the app and the suite are shown to people as
**Epidemiological suite**.*

**Where it stands:** 66 calculators (50 sample-size, 11 analysis, 2 planning, 2 survey, 1 infectious-disease models), 159 designs,
three versions live or ready (browser build on GitHub Pages, phone/server version on Posit Connect Cloud, R package), default test
suite 940 blocks with 0 failures; 195 calculation functions exported with help pages.

---

## Waiting for you (owner decisions and steps)

- [ ] Merge PR #11 (it contains #10 as well), then click **Republish** on Connect Cloud; try the phone redirect on a real phone
- ~~Version bumped to **1.0-alpha** (30 Oct; the tag of the release is `v1.0-alpha`; DESCRIPTION carries 0.99.0 because R accepts only numbers there)~~
- [ ] Zenodo: the first record (wrong version tag) was removed; publish the `v1.0-alpha` release again and send the new **DOI**
- [ ] Decide on a background-process package (`mirai` or `future`) for running slow simulations without blocking other users (also changes the browser build)
- [ ] Long-term hosting (Connect Cloud free-plan limits are not verified); rename of the GitHub repository (changes install and citation addresses)
- [ ] The Pages build error text from 17 Oct, if it still happens

## Phase 1 — Foundations  (all done)

- ~~Wizard and catalog re-synced with the app, every module reachable~~ (28 Sep)
- ~~Fast/slow test split, CI on every push, locked dependencies~~ (28 Sep)
- ~~Standard result object, results export (CSV / JSON / BibTeX / RIS) and a justification paragraph for every module~~ (28 Sep)
- ~~Power / sensitivity curves~~ (14 Oct)
- ~~R package skeleton (`DESCRIPTION`, `NAMESPACE`, `run_app()`, tests no longer `source()` files)~~ (14 Oct)
- ~~Automated UI smoke tests in headless Chrome~~ (14 Oct)
- ~~Explicit "Calculate" button for the slow Monte Carlo modules~~ (28 Sep; the second half, running them in the background, is Phase 6)

## Phase 2 — Widening the suite  (done, with extras listed)

- ~~Analyze workbench: 11 summary-data tools (2×2, rates, Mantel-Haenszel, standardization, diagnostic accuracy, vaccine efficacy, …)~~ (Oct)
- ~~Planning tools: randomization lists, attrition inflation~~ (16 Oct)
- ~~Survey tools: sample selection (SRS, systematic, PPS, EPI 30×7) and survey weights~~ (21 Oct)
- ~~Outbreak and surveillance: attack rates, aberration detection (EARS, CUSUM)~~ (21 Oct)
- ~~Teaching models: SIR / SEIR with vaccination~~ (21 Oct)
- ~~Plain-language study-design parser and wizard battery (101 descriptions, 636 click paths checked)~~ (27 Oct)
- ~~Several measurements per patient (eyes, lesions, patches, split-face): patients needed when treatment is given to whole patients (two means, two proportions) or to each patient's units (two means), units per patient needed for a fixed number of patients, and the floor that extra units cannot get below~~ (29 Oct; checked against clusterPower, pwr and simulation; not covered: binary outcome with both treatments in each patient, unequal allocation, patient-by-treatment interaction)
- Not promised, kept on the list: raking / post-stratification, seasonal detection baselines, age-structured models, line-list upload and R0 / Rt (deferred by decision D1)

## Phase 3 — Reaching people on every device

- ~~Documentation site (pkgdown) on GitHub Pages~~ (17 Oct)
- ~~Browser build (Shinylive) published on GitHub Pages~~ (21 Oct)
- ~~Docker image with a CI smoke test~~ (21 Oct)
- ~~Lazy loading with a progress indicator (UI visible 77 s → 27 s in CI)~~ (27 Oct)
- ~~Start-up status panel for the browser build (explains the wait, copyable log)~~ (27 Oct)
- ~~Measured why phones fail on the browser build (about 1 GB of memory, 64 MB download)~~ (27 Oct)
- ~~Phone / server version on Posit Connect Cloud, deployed from the `connect` branch, built and checked in CI~~ (28 Oct)
- ~~Automatic redirect of phones and tablets to that version~~ (28 Oct; to be confirmed on a real phone)
- ~~Accessibility scan (axe-core, WCAG A/AA) of every calculator, light and dark, fixed to 0 violations; dark-mode switch~~ (28 Oct)
- ~~Header renamed to "Epidemiological suite"~~ (29 Oct)
- ~~Cite tab: the citation in APA, Vancouver, Harvard, IEEE, MLA, Chicago, BibTeX, RIS and a Methods sentence, with copy and download; `CITATION.cff` and `citation()` too~~ (29 Oct). **Owner step:** archive a release on Zenodo and send the DOI (three places to edit, see docs/hosting.md)
- [ ] Hosting decision for the long term (Connect Cloud free-plan limits not verified; shinyapps.io is closing to new apps)
- [ ] Home-screen icon (PWA), then an Android wrapper (TWA); iOS stays PWA only; desktop wrapper not recommended
- [ ] Multi-user scaling (Phase 6, background computation)

## Phase 4 — Interface  (first part done 29 Oct; mock-ups approved in principle, no icons before headings)

- ~~**A. Task-first Home:** one search box (searches all built designs by name and description), quick links to the six most used calculators, four task cards, a "not sure?" guide banner; the 45-row accordion, the wizard and the formulas moved behind one folded section~~ (29 Oct)
- [ ] **B. Calculator pages with progressive disclosure.** Done for every calculator at once (29 Oct): ~~Export and Power / sensitivity curves are folded panels, closed by default (and the curves are not drawn until opened); a short result stays pinned at the bottom of the window while the inputs above are edited~~. Still open: "Advanced options" folded inside each calculator (a per-module change, most-used first), a two-column layout on wide screens, a design-selector that is not a long radio list
- ~~**C. Phone layout** (the same app, one URL): on screens up to 575 px wide the navbar becomes a bar of large tabs at the bottom (Home, Plan, Analyze, Cite), the long calculator list becomes one drop-down grouped like the list, controls and buttons get touch-sized heights, and the pinned result sits above the bar; wide screens are unchanged~~ (29 Oct). Not done: a separate slimmer app with only the common calculators, one-question-per-screen for the guide (the guide already shows one question at a time), the dark-mode switch on phones (they follow the phone's setting), a check on a real phone
- ~~Search from every page: a small search box in the navbar next to the dark-mode switch, the same search as on Home~~ (29 Oct)
- [ ] Re-run the layout and accessibility scans after each step (`tools/ui-audit/audit.R`, `a11y.R`)
- [ ] Still to do for accessibility: a person's keyboard and screen-reader walk-through, dark-mode plots, text-resize checks, a layout pass on a real phone. ~~Text descriptions for the plots~~ done 29 Oct: the power / sensitivity curves, the surveillance chart and the epidemic-model chart carry an alt text with axes, ranges, trend and the current value, computed from the same numbers as the plot

## Phase 5 — The R package for analysts

- ~~Public function API for the calculations themselves: all 195 `calc_*()` functions are exported, each with a help page (every argument described, the value described, a worked example taken from a verified test); `tests/testthat/test-help_pages.R` keeps it so~~ (29 Oct; owner decision: export all). The names stay `calc_*` (the planned `ss_*()` family was dropped); a smaller friendlier set of wrappers (`ss_text()`, `ss_curve()`, `ss_export()`) is still possible
- ~~RStudio / Positron addin "Find a sample size calculator", `ss_find()` search from the console, and `run_app(calculator = ...)` to open the app on one calculator~~ (29 Oct)
- ~~Vignettes: Getting started, Sample sizes from R, Analysing summary data from R (built with the package; also on the documentation site under "Using it from R")~~ (30 Oct). More per-family vignettes can follow
- ~~Bug found and fixed while writing them: `print()` of a result showed a raw list in an installed package (the S3 methods were not registered in `NAMESPACE`)~~ (30 Oct)
- [ ] Release: r-universe (binaries, including WebAssembly), then CRAN (computation core split from the app, ASCII-only source, fast examples, clean `R CMD check`)
- [ ] **[owner]** Rename the GitHub repository (changes the install path), author details, first release number, `NEWS.md`

## Phase 6 — Engineering and speed

- [ ] Background computation for the slow Monte Carlo designs (`ExtendedTask`), so one user's run does not block the others
- [ ] `bindCache()` for repeated closed-form results
- [ ] Dependencies: ~~tier 1 (17 Oct) and the easy / moderate packages (28 Oct) removed from the runtime: five packages (tier 1) and seven (stage 2) reimplemented and checked against the originals, two upstream bugs found and corrected~~; left: `PowerTOST`, `Exact`, `clinfun`, `kappaSize` (optional), `lme4` stays
- [ ] Re-snapshot `renv.lock`; report the two upstream bugs (pmsampsize, presize)
- [ ] Trial Sequential Analysis speed in the browser build

## Phase 7 — Bigger workbenches  (later, some need decisions)

- [ ] Evidence synthesis from study summaries (fixed / random effects, forest plot), checked against `metafor`
- [ ] Teaching mode: interactive power curves, sampling-distribution and CI-coverage demos
- [ ] Raw-data workbench (Table 1, crude and adjusted estimates, Kaplan-Meier) and line-list epidemic curves, R0 / Rt: **deferred by decision D1**; needs a data-privacy policy first

## Always on: the sample-size catalog

~~Catalog essentially complete within the project rules~~ (81 of 94 designs and 69 of 74 tests done); the rest are open, blocked or partly covered, each with the condition that would unblock it (a paper, a package, an account). Full list: ROADMAP section 4.

---

## Design mock-ups (29 Oct 2026; A, the shared parts of B and D are now built, C is not)

Today's pages: [Home](design-mockups/current_home.png), [calculator](design-mockups/current_calculator.png). Proposals:
[A task-first Home](design-mockups/a_home.png), [B calculator with progressive disclosure](design-mockups/b_calc.png),
[C phone shell](design-mockups/c_phone.png), [D function API and addin](design-mockups/d_pkg.png). Decision so far: no icons or emoji
before headings.
