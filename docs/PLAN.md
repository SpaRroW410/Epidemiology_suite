# Epidemiological suite: the plan at a glance

*Updated 29 October 2026. Struck-through items are done (the date in brackets is when). The reasoning, evidence and the full
list of blocked sample-size items are in [`ROADMAP.md`](ROADMAP.md); the flat checklist of everything open is
[`to_do_later.md`](to_do_later.md). The package is still named `epidemiologicasuite`; the app and the suite are shown to people as
**Epidemiological suite**.*

**Where it stands:** 65 calculators (49 sample-size, 11 analysis, 2 planning, 2 survey, 1 infectious-disease models), 156 designs,
three versions live or ready (browser build on GitHub Pages, phone/server version on Posit Connect Cloud, R package), default test
suite 907 blocks with 0 failures.

---

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
- [ ] Hosting decision for the long term (Connect Cloud free-plan limits not verified; shinyapps.io is closing to new apps)
- [ ] Home-screen icon (PWA), then an Android wrapper (TWA); iOS stays PWA only; desktop wrapper not recommended
- [ ] Multi-user scaling (Phase 6, background computation)

## Phase 4 — Interface, next up  (mock-ups approved in principle, no icons before headings)

- [ ] **A. Task-first Home:** one search box, four task cards (Plan a study, Analyze counts I have, Outbreak and surveillance, Survey and field work), a "not sure?" guide; the 45-row accordion moves behind "Browse all"
- [ ] **B. Calculator pages with progressive disclosure:** essential inputs first, "Advanced options" folded, a sticky result card, Formula / Reference / Curves / Export folded; built once in the shared module layout so all 65 pages change together
- [ ] **C. Phone shell:** bottom navigation, one question per screen for the guide, large result card; the most common 8–10 calculators first, the rest loaded when opened
- [ ] Search across all calculators (jump straight to a calculator from any page)
- [ ] Re-run the layout and accessibility scans after each step (`tools/ui-audit/audit.R`, `a11y.R`)
- [ ] Still to do for accessibility: a person's keyboard and screen-reader walk-through, text descriptions for plots, dark-mode plots, text-resize checks, a layout pass on a real phone

## Phase 5 — The R package for analysts

- [ ] Public function API (`ss_*()` family: one function per design, plus text, curve and export helpers)
- [ ] RStudio / Positron addin: "Find a sample-size calculator"
- [ ] Vignettes per family; more help pages
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

## Design mock-ups (29 Oct 2026; pictures only, nothing here is built yet)

Today's pages: [Home](design-mockups/current_home.png), [calculator](design-mockups/current_calculator.png). Proposals:
[A task-first Home](design-mockups/a_home.png), [B calculator with progressive disclosure](design-mockups/b_calc.png),
[C phone shell](design-mockups/c_phone.png), [D function API and addin](design-mockups/d_pkg.png). Decision so far: no icons or emoji
before headings.
