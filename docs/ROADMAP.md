# Roadmap — Epidemiological suite: from Sample Size Calculator to Epidemiology Suite

> **Plan at a glance (what is done and what is next): [`PLAN.md`](PLAN.md).** This file keeps the reasoning and the evidence.

| | |
|---|---|
| **Status** | Active — authoritative forward plan |
| **Last reviewed** | 28 September 2026 (full codebase + docs review) |
| **Owner** | Dr. Mukul Maheshwari |
| **Name** | **Epidemiological suite** as shown in the app; the R package is `epidemiologicasuite` (decision D3) |
| **Licence** | GPL-3 (decision D2) |

**How the docs fit together**

- **This file** — where the project goes next, in what order, and why. Every open or
  blocked item lives here with the condition that would unblock it. Nothing is
  removed from this roadmap because it is hard; it is only re-tiered.
- [`checklist_by_design.md`](checklist_by_design.md) /
  [`checklist_by_test.md`](checklist_by_test.md) — per-item build status and the
  verification evidence behind every shipped sample-size design.
- [`SDD.md`](SDD.md) — architecture, module contract, conventions.
- [`project-brief.md`](project-brief.md) — the original brief (historical).
- [`sample size calculator review.pdf`](sample%20size%20calculator%20review.pdf) — the
  scope checklist sent for colleague review (94 designs + 72 tests). Cross-checked
  on 28 Sep 2026: every row is either done in the checklists or listed in §4 below.

---

## 1. Where the project stands

| Measure | Value |
|---|---|
| Calculator modules | **66** (50 sample-size calculators, 11 Analyze tools, 2 planning tools, 2 survey tools, 1 infectious-disease model tool), in 17 groups in the Plan workbench and 2 in Analyze |
| Individual designs | **159**, all in the Browse catalog (F2 fixed) |
| Checklist coverage | By design: **81 / 94** done (13 open) · By test: **69 / 74** done (5 open) |
| Unit tests | **907** test blocks in the default run (0 failures, 101 skipped as slow) across 83 test files, every design checked against a published worked example, a real package (oracle), or simulation |
| Runtime packages | `DESCRIPTION` `Imports`: `shiny`, `bslib`, `clinfun`, `PowerTOST`, `Exact`, `kappaSize`, `mvtnorm`, `lme4`, plus `survival`, `stats`, `graphics`, `utils` (was 19; twelve removed in items 16 and the stage 2 that followed, each reimplemented and checked against the original) |
| Verification-only packages | ~30 more (installed from the `github.com/cran` mirror, used only to check reimplementations — never shipped) |
| Wizard coverage | "Which calculator?" reaches **49 / 49** modules and all 156 catalog entries, enforced by tests (F1 fixed) |
| Distribution | Installable package (`remotes::install_github()` + `run_app()`), no hosted build. CI on GitHub Actions; versions locked in `renv.lock` |

The sample-size catalog is now effectively complete within the project's own rules
(every formula traceable to a published source and verified numerically; no new
runtime dependency without a decision). Everything still open is either genuinely
hard to reimplement safely, has no citable method, or needs a source this sandbox
cannot reach — see §4.

---

## 2. Review findings (28 Sep 2026)

| # | Finding | Evidence | Severity |
|---|---|---|---|
| F1 | **Fixed (28 Sep 2026).** ~~Wizard is badly out of sync with the app.~~ Only 14 of 49 modules are reachable from "Which calculator?", and 16 wizard endpoints still say "not yet built" for things that *are* built (ROC/AUC, Bland-Altman, CCC, Cronbach's alpha, ratio precision, crossover, stepped-wedge, bioequivalence, group sequential, nested case-control, case-cohort, SCCS, ordinal outcome, McNemar, prediction models) | `R/home/design_tree.R` terminals with `would_use` instead of `catalog_key` | Was **High**. Now: every built entry is reachable (curated branches + a generated "I already know which test" branch); the 14 remaining "not built" endpoints are exactly the open/paused items in §4, and a test checks each one is listed there |
| F2 | **Fixed (28 Sep 2026).** ~~Browse catalog gaps.~~ "Two paired/dependent proportions" is marked `built = FALSE` though McNemar's test is live in Chi-Square Tests; Longitudinal's Diggle, Edland and Hu designs have no catalog entry, so they can't be found from Browse | `calculator_catalog` vs. each module's `design` radio values; now checked by `tests/testthat/test-catalog_consistency.R` | Was Medium |
| F3 | **Stale documentation.** README described 24 modules, SDD's roadmap marked finished stages "not started", SDD appendix listed packages never used (`WebPower`, `pwrss`, `precisely`); one ticked checklist note (logistic covariate adjustment) still says "not covered" | fixed in this refresh (README, SDD, and the checklist note) | Low (fixed) |
| F4 | **Addressed (28 Sep 2026)** — CI + `renv.lock` added (P0 items 5–6). Was: ~~No CI and no dependency lock.~~ Environment is rebuilt by `.claude/hooks/session-start.sh` from latest GitHub-mirror sources — not reproducible, and a package update could silently change a result | no `.github/`, no `renv.lock` | Medium |
| F5 | **Fixed (28 Sep 2026)** — default run ~1 min, 27 Monte Carlo tests behind `S2R_SLOW_TESTS=true`. Was: ~~Slow test suite.~~ Full run takes ~6–10 min, dominated by Monte Carlo tests (`test-calc_glmm.R` alone several minutes); there is no fast/slow split | observed across every batch | Medium |
| F6 | **Fixed (14 Oct 2026, item 12).** ~~No automated UI tests in the repo.~~ `tests/testthat/test-ui_smoke.R` drives every module in headless Chrome via `shinytest2` | `tests/testthat/test-ui_smoke.R`, `helper-ui.R` | Done |
| F7 | **Fixed (14 Oct 2026, item 11).** ~~Not yet package-shaped.~~ `R/` is flat, `DESCRIPTION`/`NAMESPACE` exist, `global.R` and `pacman::p_load()` are gone, tests no longer `source()` files. The installed package passes `R CMD check`'s test step | repo layout, `DESCRIPTION`, `NAMESPACE`, `R/run_app.R`, `R/registry.R` | Done |
| F8 | **Resolved by relicensing to GPL-3 (D2, 28 Sep 2026).** Background: the project was MIT, but several modules were built by reading and transcribing source from GPL-licensed packages (e.g. `PracTools` GPL-3, `ssize.fdr` GPL-3, `voi` GPL-3, `clusterPower` GPL≥2, `semTools` GPL≥2, `simr` GPL≥2, `metapower` GPL-2, `WebPower` GPL≥3, `rpact` LGPL-3). Mathematical formulas aren't copyrightable, but closely transcribed code may count as a derivative work. *Not legal advice.* GPL-3 is compatible with all of these (GPL-2-only `metapower` is the one to watch: it was a verification reference, not a code source to ship) | package `DESCRIPTION` licenses; module header comments | Resolved; keep module header comments naming each source |
| F9 | **Partly addressed (28 Sep 2026).** Shiny runs one R process per app instance; a 5–25 s simulation (Monte Carlo Mixed Models, RMST, weighted log-rank, BFDA, KS/runs/animal-rank) used to recompute on every input change — fixed, see P1 item 7. Still true: one user's simulation blocks every other user on the same app instance while it runs — needs `ExtendedTask` (P1 item 7, second half) | observed during browser verification | Was Medium (High once hosted); recompute-storm risk resolved, cross-user blocking remains |
| F10 | **Resolved (28 Sep 2026).** Every module (except the two guidance-only ones) now offers CSV/JSON/BibTeX/RIS download and a justification paragraph — see P1 item 9 | download handlers exist for all 47 calculator modules | Was Medium; resolved |
| F11 | **Largely addressed (28 Oct 2026, item 22).** ~~Accessibility and mobile layout never audited.~~ Layout was audited earlier (`tools/ui-audit/audit.R`); an axe-core accessibility scan (WCAG 2.0/2.1 A and AA rules) of every calculator at desktop and phone width found five kinds of problem on all or most pages, now fixed (see item 22 below). Not done: a screen-reader and keyboard walk-through by a person, which a machine scan cannot replace. Translations are not planned (English only, D5) | `tools/ui-audit/a11y.R` | Low |
| F12 | **Fixed (17 Oct 2026).** ~~Open (found by the item 15 spike).~~ The theme uses `bslib::font_google("Source Serif 4")`, which downloads the font file when the page is first rendered. Without internet at that moment (a Shinylive build, an air-gapped server, `R CMD check` on a locked-down machine) the page fails to render at all | `R/run_app.R` (theme) | Medium; fix by shipping the font or using a system font stack; needed for any offline route |
| F13 | **Fixed (17 Oct 2026, item 16).** ~~Open (found by the item 15 spike).~~ The app only works with the epiR version pinned in `renv.lock` (2.0.67). Current CRAN `epiR` (3.0.0, also what the webR repository serves) changed `epi.ssdetect()` (`prev`/`finite.correction`/`conf.level` became `pstar`/`se.psu`/`ss.se`), so Rule of Three "imperfect test" fails on a fresh install; the other `epi.ss*` calls were not re-checked against 3.0.0 | `R/calc_rule_of_three.R`; epiR 3.0.0 source | High for CRAN / fresh installs; best fixed by removing `epiR` from the runtime (item 16) rather than chasing its API |
| F14 | **Fixed (17 Oct 2026, item 16).** ~~Open (found by the item 15 spike).~~ `rstatix` is declared an import for one call (`cochran_qtest`, Cochran's Q); it costs 21.8 MB of unique dependencies in a browser build and a long install otherwise | `R/calc_chisq.R:320` | Low effort, high weight reduction |

---

## 3. Priority list

Tiers are ordered by value ÷ effort and by what unblocks what. Work top-down; the
blocked sample-size items (§4) run in parallel whenever their unblock condition is met.

### P0 — hygiene, do next (small, high value)

1. ~~**Re-sync the wizard (F1).**~~ Done: stale terminals point at live modules;
   new branches for relationships, survey sampling, psychometrics, rare events,
   animal studies, pilots, value of information, genetics, meta-analysis,
   prediction, survival, rates, longitudinal, 3+ groups, multiplicity, Bayesian and
   group-sequential designs; plus a generated "I already know which test" branch
   from `test_families`. Tests: every built entry and every node reachable; every
   open terminal listed in §4.
2. ~~**Re-sync the catalog (F2).**~~ Done: paired proportions → McNemar;
   Diggle/Edland/Hu entries added; `test-catalog_consistency.R` checks navbar ↔
   catalog ↔ each module's `design` radio values, both ways.
3. ~~Fix the stale logistic covariate-adjustment checklist note (F3).~~ Done in this
   refresh.
4. ~~**Fast/slow test split (F5).**~~ Done: every test that took ≥ 5 s (27, all
   Monte Carlo or simulation-based) calls `skip_if_not_slow()`
   (`tests/testthat/helper-slow.R`) and runs only with `S2R_SLOW_TESTS=true`.
   Default run: ~1 min (was ~13 min); full run unchanged.
5. ~~**Add CI (F4).**~~ Done: `.github/workflows/tests.yml` runs the fast suite on
   every push and pull request, and the full suite weekly (Monday) or on demand.
6. ~~**Lock dependencies (F4).**~~ Done: `renv.lock` records R 4.3.3 and the 179
   packages (runtime + `testthat`/`withr`/`lmerTest` and their dependencies) the
   development environment actually runs; CI restores exactly these. The
   SessionStart hook cannot restore from it, because `cran.r-project.org` is
   blocked in the web sandbox — it keeps installing Ubuntu binaries and
   `github.com/cran` mirrors, and `renv.lock` is re-snapshotted after any package
   change (`renv::snapshot(packages = ...)`, see README).

### P1 — foundations for the suite

7. **Explicit "Calculate" button for Monte Carlo modules (F9), first half done
   (28 Sep 2026).** All 8 Monte Carlo designs (Monte Carlo Mixed Models' 3
   designs, RMST, weighted log-rank, BFDA, KS, Wald-Wolfowitz runs, animal rank
   test) now gate their `calc_*()` call behind a "Calculate" button
   (`monte_carlo_calculate_ui()`, `mod_shared_ui.R`) instead of recomputing on
   every keystroke — the reactive depends only on the design radio and the
   button (`isolate()`-wrapped otherwise), a no-new-deps pattern that doesn't
   need `bindEvent()`. Fast, closed-form designs in the same modules stay live.
   Still open: `shiny::ExtendedTask` with a background process, so one user's
   still-running simulation doesn't block others on the same app instance —
   the button alone doesn't fix that; it only stops *unwanted* recomputes.
8. **Standard result object — done for every `calc_*.R` file (28 Sep 2026).**
   `R/calc/calc_result.R`'s `new_ss_result()` wraps a `calc_*()` function's
   existing return list in class `ss_result` — additive only (every existing
   field name/value is kept exactly as-is, so `res$n` etc. keeps working
   unchanged; confirmed no test in this project compares a whole result object
   by identity, only by field) — plus generic `print.ss_result()`/
   `format.ss_result()` methods that recognize any `n*`/`k*`/`*power*`-named
   field as the headline, so no per-design method is needed. Deliberately
   does *not* try to force a single canonical field name (e.g. always `n`)
   across all ~156 designs, since that would mean rewriting each function's
   actual return shape, not just wrapping it — field names stay
   design-specific; export/reports (item 9) reads them via the catalog
   metadata already keyed by design, not by guessing a common name.
   Adopted across all 51 `calc_*.R` files (156 designs): pilot batch first
   (`calc_proportion.R`/`calc_means.R`, 13 designs), then every remaining
   file's matching final `list(...)` return wrapped mechanically, verified
   safe first (every match confirmed to be an unconditional final-statement
   return, none mid-function) and two non-matching cases fixed by hand
   (`calc_lan_demets.R`'s single-line return, `calc_lqas.R`'s `return(list(...))`
   inside a loop). A few functions were deliberately left unwrapped: internal
   numeric-only helpers never exposed to a module (e.g. `calc_sem_rmsea_power()`),
   and functions that already return an `ss_result` transitively by calling an
   already-wrapped one (e.g. `calc_sign_test()` calls `calc_binomial_exact()`;
   all four Bonferroni/Sidak `calc_multiplicity_*` wrappers call the now-wrapped
   proportion/means functions). Full suite (`S2R_SLOW_TESTS=true`, all 487
   tests including the 27 Monte Carlo ones): 0 failures, 0 errors. Playwright
   spot-check across 8 modules spanning different families (cohort, diagnostic,
   agreement, TOST, log-rank, correlation, nonparametric, cluster/DEFF): all
   render correctly, no page errors. Item 8 is done; items 9-10 (export,
   power curves) can now build on `ss_result` across the whole catalog.
9. **Results export (F10) — done for every module (28 Sep 2026).**
   `R/calc/calc_export.R` (pure functions, unit-tested, no Shiny) generic
   across every design via `ss_result` (item 8): `ss_result_to_csv()`/
   `_to_json()` (a flat one-row/one-object dump; nested `inputs` become
   dot-separated keys, a vector field collapses to a semicolon-separated
   string), `format_justification()` (a ready-to-paste protocol paragraph:
   design name + headline result(s) + inputs + citation/backend), and
   `format_citation_bibtex()`/`_ris()` (a generic `@misc`/`GEN` entry with
   the citation preserved verbatim in a note field — deliberately *not*
   parsed into structured author/year/journal, since this app's citations
   are free text and guessing those fields wrong is worse than not having
   them). `mod_shared_ui.R`'s `export_controls_ui()`/`render_export_handlers()`
   wire a "Copy paragraph" button + CSV/JSON/BibTeX/RIS downloads into a
   module in two lines, filenamed from the design (e.g.
   `epidemiologicasuite_two_independent_proportions.csv`).
   Found and fixed along the way (real bug, not sandbox-only — same root
   cause could bite a deployment with a similarly minimal locale): this
   sandbox has no working multibyte locale at all, under which R's own
   `gsub()`/`intToUtf8()` can corrupt or error on non-ASCII text passed
   through Shiny's dynamic (`renderText`) JSON serialization, though
   *static* UI text is unaffected. Fixed by transliterating the (small,
   audited) set of non-ASCII characters this app's citations actually use
   to ASCII — at the raw-byte level (`charToRaw()`/`rawToChar()`, not
   `gsub()`), since even locale-independent-looking string functions
   proved unreliable here. Adopted first for the same 2-module pilot as
   item 8 (Proportions, Means), then rolled out to all 45 remaining
   modules (every module except the two guidance-only ones, Ecological
   and Qualitative, which compute no numeric result).

   For the ~23 modules whose design-radio values match their `content_*.R`
   keys 1:1, `content_fn` is the direct `<id>_content[[input$design]]`.
   Five needed an explicit remap from radio value to real content key,
   found by diffing every module's actual radio choices against its
   content file's keys *before* wiring anything (not discovered after the
   fact): `correlation` ("single" → `pearson`), `exact_tests` ("sign" →
   `sign_test`), `roc` ("compare_two" → `compare_two_aucs`),
   `multiplicity` (four Bonferroni/Sidak designs share one `overview`
   entry, `fdr_means_2s` → `fdr`), `nonparametric` (7 of 9 radio values
   use short internal codes differing from the content file's full test
   names). Two further special cases: TSA dispatches on "outcome"
   (RR/OR/RD/MD, lower-cased) rather than "design"; Meta-Analysis Power's
   result bundles two companion `ss_result`s (required-k and
   achieved-power), so `render_export_handlers()` gained an optional
   `value_fn` parameter (default `res$value`) to pick the headline one.
   16 modules have only one design, so `content_fn` is a fixed
   `<id>_content$<key>` constant.

   **Two more real bugs found by a verification pass before committing**
   (a background pass ran the full test suite clean, then caught these
   live in the browser — exactly the failure mode unit tests can't see,
   since they test `calc_*()` functions directly, never a module's own
   `content_fn` wiring):
   - *Citation-merge bug (TSA, EVPI, Multilevel).* These three
     `content_*.R` files factor a `shared` entry holding the common
     `explanation`/`worked_example`/**`citation`** out of their per-design
     entries (which carry only `title`/`backend`) — so `content_fn`'s
     naive `X_content[[input$design]]` returned an entry with
     `citation = NULL`, and `format_justification()` correctly refused to
     silently omit the source, surfacing as a live, page-visible
     `shiny-output-error` on the justification text (and would have broken
     the BibTeX/RIS downloads too, same dependency). Fixed with
     `modifyList(X_content[[key]], list(citation = X_content$shared$citation))`
     in each of the three modules; the whole `R/content/*.R` tree was
     checked for the same `shared`-entry shape (`grep -l "shared = list("`)
     to confirm no other module has it.
   - *Headline-fallback bug (EVPI).* `format_justification()` refused to
     report a result with no field matching the `n*`/`k*`/`*power*`
     headline pattern — correct for catching a genuinely malformed
     result, but EVPI's own result is a monetary value
     (`evpi_per_patient`), not a sample size, by design (it answers "is
     more research worth it," not "how many subjects"). Fixed by falling
     back to reporting every top-level field when none match the pattern,
     rather than erroring; the function now only errors on a truly empty
     result (no fields besides `inputs`), which would indicate a bug
     elsewhere, not a design choice like EVPI's.

   Verified: full fast test suite (503 tests, 0 failures/0 errors, 27
   expected Monte Carlo skips) after every fix, not just once at the end;
   Playwright against a running instance — the original 2-module pilot
   (4 downloads + justification, 3 designs), a spot-check across 6 more
   diverse modules (one per dispatch shape: plain design radio, the TSA
   outcome case, three of the five remap cases, the Meta-Analysis Power
   value_fn case), and a full re-check of all three citation-merge fixes
   plus the EVPI fallback fix (justification text, and the BibTeX/RIS
   downloads specifically, since they share the same citation field) —
   all render correctly, no page errors, no server-log errors.
10. **Power/sensitivity curves -- done (14 Oct 2026); infrastructure and rollout
    history below.** `R/calc/calc_curve.R` (pure, unit-tested, no Shiny):
    `ss_curve_points(calc_fn, args, vary_param, vary_values)` recomputes a
    design's own headline n/k field (`.ss_curve_n_field()`, a narrower match
    than `calc_result.R`'s own headline detector -- deliberately excludes a
    `*power*`-named field, since the whole point of one of the two curves
    is to put power on the x axis while n stays the y axis throughout) by
    calling the *same* `calc_*()` function the point estimate already used,
    across a grid of one varying argument, holding every other argument at
    its current value; a grid point outside the formula's valid domain
    (e.g. an effect size the design's own validation rejects, or --
    `case_cohort` -- a hazard ratio too close to 1 for any feasible
    subcohort at this cohort size) is simply omitted, never fabricated.
    `.ss_curve_n_field()` matches in two tiers: a strict "starts with n/k"
    pattern first (preserves the exact field every already-wired design
    uses, e.g. `calc_means_welch()`'s `n_total` over its own `n1`/`n2`),
    falling back to n/k as a whole underscore-separated token anywhere in
    the name only when nothing strict matches (catches
    `calc_case_control_case_cohort()`'s `subcohort_n` -- a real sample
    size, just not spelled with an n/k *prefix*). Six generic scan-range
    helpers (`curve_range_proportion()`, `curve_range_correlation()`,
    `curve_range_ratio()`, `curve_range_within()`, `curve_range_around()`,
    `curve_range_power()`) are shared across every module's wiring so each
    one only has to pick the right helper and parameter name, not invent
    its own grid. `curve_range_within(lower, upper)` is the newest: a
    fractional-padded grid strictly inside an explicit bound set by
    *another input*, not a fixed domain -- needed for a TOST/
    bioequivalence effect that must stay strictly within its own
    equivalence margin or limits.

    `mod_shared_ui.R`'s `power_curves_ui()`/`render_power_curves()` render
    two `plotOutput()`s (base R graphics via `renderPlot()` -- no new
    dependency, unlike a `ggplot2`/`plotly` route) per module: "required n
    vs. effect size" and "required n vs. power", each marking the current
    on-screen values with a point. `render_power_curves()` takes a
    `curve_spec` function (same calling convention as
    `render_export_handlers()`'s `content_fn`) that returns either `NULL`
    (renders "Power curves are not yet available for this design.") or
    `list(calc_fn, args, effect = list(param, values, label), power =
    list(param, values))` for the current design.

    Adopted so far, one incremental batch at a time (same pattern as
    items 8/9), for the designs with one scalar effect parameter *and* a
    power argument to vary against a fixed effect size:
    - **Batch 1 (pilot, 28 Sep 2026):** Proportions (`single`,
      `two_sample`), Means (`single`, `two_sample`, `welch`, `paired`).
    - **Batch 2 (29 Sep 2026):** Cohort (its one design), Case-Control
      (`unmatched`, `matched`, `case_cohort` -- effect = OR or HR via the
      new `curve_range_ratio()`), Diagnostic Accuracy (`vs_reference`,
      `two_indep`, `two_paired`, `odds_ratio`), Correlation (`single`,
      `two_independent`, `point_biserial`, `regression_slope`, `partial`,
      `spearman` -- effect = a correlation via the new
      `curve_range_correlation()`, or for `regression_slope`, the slope
      itself via `curve_range_around(0, 3 * abs(current slope))`).
    - **Batch 3 (29 Sep 2026):** Crossover Trial 2x2 (its one design),
      Equivalence/TOST (`means`, `proportions`, `bioequivalence`,
      `assurance` -- effect = the test/reference difference or ratio via
      the new `curve_range_within()`, kept strictly inside the design's
      own margin/limits), Non-Inferiority (`means`, `proportions`,
      `odds_ratio`, `hazard_ratio`).
    - **Batch 4 (1 Oct 2026):** ROC/AUC (`single_auc` only -- effect = AUC
      via `curve_range_within(0.5, 1)`), Chi-Square Tests (`mcnemar`
      only), RM-ANOVA/Mixed ANOVA (all three effects: `between`, `within`,
      `interaction` -- one `calc_rm_anova()` dispatched by a `type` arg
      held fixed, effect = Cohen's f via the new
      `curve_range_multiplicative()`), Multiple Regression (`r2`, effect
      via `curve_range_proportion()`; `r2_increase`, effect = the full
      model's R-squared via `curve_range_within(r2_reduced, 1)`),
      Variance Tests (`single`, `two` -- effect = the varying SD via
      `curve_range_multiplicative()` around the fixed reference SD).
    - **Batch 5 (5 Oct 2026):** Factorial ANOVA/ANCOVA (effect dynamically
      follows whichever effect-size input is selected -- `f2` via
      `curve_range_multiplicative()`, `eta2` via `curve_range_proportion()`),
      Self-Controlled Case Series (flat/no-age-effects branch only --
      effect = `eexpo` via `curve_range_ratio()`), Competing Risks (its
      one design -- effect = `hr_1`), MANOVA/Hotelling's T-squared (its
      one design -- effect = `d2` via `curve_range_multiplicative()`),
      Multiplicity Adjustment (`proportion_1s`, `proportion_2s`,
      `means_1s`, `means_2s` -- each re-runs an already-wired base test
      with an adjusted alpha).

      Found and fixed a real, pre-existing bug while Playwright-checking
      this batch's MANOVA module, unrelated to the curves work itself:
      its nav_title ("MANOVA / Hotelling's T²") rendered in the navbar
      dropdown as literal garbled text ("T<c2><b2>"), the same no-
      multibyte-locale root cause documented under item 9 -- except that
      bug was previously believed confined to *dynamic* `renderText`
      output; this shows a *static* UI string (a module's own
      `nav_title`, built once at app start) can hit it too. Fixed by
      renaming to the ASCII `"MANOVA / Hotelling's T-squared"` (matching
      the spelled-out-word convention this app already uses for other
      squared quantities, e.g. "R-squared", "D-squared") in both
      `mod_manova.R` and the one cross-reference in `R/home/home_catalog.R`
      that has to name it exactly for wizard navigation; confirmed via
      `test-catalog_consistency.R`/`test-design_tree.R` and a fresh
      Playwright check of the rendered menu text.

      Found and fixed a real performance problem before shipping it, not
      after: Multiplicity's `dunnett` design has a single scalar effect
      (Cohen's d) and looked wireable like the rest of this batch, but
      `calc_multiplicity_dunnett()`'s internal `mvtnorm::qmvt()` root
      search measured ~1.4s *per call* -- a 40-point curve would take
      ~47s, and two curves per design would mean roughly a minute of
      unresponsiveness on every keystroke. Left unwired rather than
      shipped slow; a real fix needs a Calculate-button-gated pattern
      like the Monte Carlo designs (item 7's `monte_carlo_calculate_ui()`),
      not a plain live curve -- noted in `mod_multiplicity.R` as a
      dedicated follow-up, not silently dropped.
    - **Batch 6 (7 Oct 2026):** Logistic Regression (`binary`,
      `continuous`, `binary_adjusted`, `continuous_adjusted` -- effect =
      `p2` or the odds ratio via `curve_range_ratio()`), Incidence Rate
      (`comparison`, `poisson_regression`, `negative_binomial` -- effect
      = a rate ratio via `curve_range_ratio()`, or for
      `poisson_regression`, the log-rate-ratio slope `beta1` via
      `curve_range_around(0, 3 * abs(current beta1))`).

    - **Batch 7 (9 Oct 2026):** Log-Rank/Survival (`logrank`,
      `cox_binary`, `cox_continuous` -- effect = a hazard ratio via
      `curve_range_ratio()`), Stepped-Wedge CRT (its one design, effect =
      `d`), Trial Sequential Analysis (all four outcome types RR/OR/RD/MD
      -- `calc_tsa_information_size()` takes `beta`, not `power`, so the
      module wraps it in a tiny adapter exposing a `power` argument and
      the power axis reads as power), Meta-Analysis Power (`d` and `r`
      effect types; the `or` type takes a whole 2x2 table), Multilevel
      (`two_level`, `three_level` -- effect = `delta`).
      - `.ss_curve_n_field()` gained a third, last-resort tier
        (`^n[A-Za-z]`) for a count spelled with no underscore at all --
        `calc_stepped_wedge_normal()`'s `nclusters` matched neither of
        the first two tiers, so its first curve came back with zero rows
        (caught by timing the candidates, which printed `rows=0`); it can
        never outrank an earlier tier, and has its own unit test.
      - Declined on measured cost, same rule as Dunnett/Exact Tests:
        Log-Rank's `noncompliance` (`Hmisc::cpower` search, ~6.3s for a
        *single* call). `logrank` itself measured ~95ms/call (~3.8s for
        40 points), so that one design uses a 20-point grid for both its
        curves rather than being dropped.
      - Declined (no power argument): Subgroup/Interaction Testing
        (only `n_main_total` and an effect ratio).

    - **Batch 8 (9 Oct 2026):** Group Sequential Design (all four:
      `normal`, `binary`, `survival`, `lan_demets_normal`), Longitudinal/
      MMRM (all five: `slope_diff`, `mmrm_ar1`, `diggle`, `edland`, `hu` --
      effect = `delta`), Nonparametric Tests (`kruskal_wallis`,
      `friedman` -- effect = Cohen's f).
      - Measured, not assumed: the three power-family group-sequential
        designs cost ~140ms/call (boundary computation), so they use a
        12-point grid (~1.7s per curve); the Lan-DeMets 2-look design
        (~14ms/call) and every longitudinal design (<=0.35s for 40
        points) keep the full grid.
      - Two more modules turned out to have a power analog under another
        name -- found only because the "no power input" claim was checked
        against the actual inputs rather than just a `grep power`: LQAS
        (consumer's risk `beta`) and Simon Two-Stage (type II error
        `beta`). Both are wired through a small adapter exposing
        `power = 1 - beta`; Simon's adapter also flattens its nested
        minimax/optimal designs so the curve plots the minimax design's
        maximum n (20-point grid, ~60ms/call). Simon's first draft of
        this note had wrongly listed it as having no power input.
      - Declined on measured cost: Bayesian `assurance_or` (~1.1s/call),
        EFA/CFA `rmsea` (~0.31s/call, a brute-force scan over n).
      - Declined on semantics: Nonparametric's `rank_sum`, `signed_rank`,
        `kendall`, `jonckheere` take tuples of jointly-constrained
        probabilities (e.g. p2 is bounded by p1), so varying one alone
        would plot an inconsistent input set -- not a fabricated point,
        but a meaningless one.

      Earlier-batch exclusions, investigated before writing any wiring
      and each declined for a documented reason rather than silently
      skipped:
      - **Agreement/Reliability** (kappa, ICC, Cronbach's alpha,
        Bland-Altman, CCC): every design is precision-based (a target CI
        width, not a power/alpha hypothesis test) -- none has a `power`
        argument at all, so the whole effect/power curve pair this
        feature is built around doesn't apply. A "required n vs.
        precision" curve would be the right analog but is a different
        feature, not a drop-in reuse of `render_power_curves()`.
      - **Pilot/Feasibility**: same reason -- it's a precision
        illustration around a fixed rule-of-thumb n, not a hypothesis
        test, so there is no effect size or power to vary.
      - **Exact Tests** (binomial, Fisher, Boschloo, exact Poisson, sign
        test): each design has a power argument and looked wireable, but
        every one of them does an iterative/exact search per call --
        measured directly (not assumed) at ~0.39s (binomial), ~0.73s
        (Fisher), ~2.1s (Boschloo), ~0.21s (sign test), and only exact
        Poisson was fast (~0.05s). A default 40-point grid would take
        2-84 seconds per curve depending on design. Deferred whole, same
        reasoning as Multiplicity's `dunnett` in batch 5 -- needs either
        a design-specific reduced grid size or a Calculate-button gate,
        not a blanket live curve.

    **Completion (14 Oct 2026) -- the three open pieces, done.** After
    batch 8 the ROADMAP listed three remaining kinds of work; all three are
    now built:
    1. *Per-design leftovers* (designs with no single scalar effect, or one
       skipped for cost): `posthoc_pairwise` (Proportions, Means), Means
       `anova`/`planned_contrast`, ROC `compare_two`, Case-Control `nested`,
       Correlation `two_dependent`, Chi-Square `gof`/`independence`/
       `mantelhaenszel`/`cochran_armitage`, SCCS age groups, Logistic
       `ordinal`, Log-Rank `stratified`/`noncompliance`, Multiplicity's two
       FDR designs, Means' unequal-n design (found missing by the crawl
       below). Where the effect is a whole vector, the curve's x axis is a
       *multiplier on the differences* (`curve_scale_about()`; 1 = as
       entered): group means for ANOVA/contrasts, the gap between P1 and P0
       for goodness of fit, the departure from independence for an R x C
       table. Correlation `two_dependent` varies `r_yx2` only inside the range
       that keeps the correlation matrix valid.
    2. *Precision-based designs* (n against the key assumption and against
       the precision target, via a new optional axis `title`): Proportions,
       Means, Diagnostic (three designs), Incidence Rate, Variance, Agreement
       (all five), Subgroup/Interaction, Cluster (three), Stratified, Ratio
       (three), Capture-Recapture, Rule of Three (two), Resource Equation,
       Prediction Model (three).
    3. *Slow designs*: `render_power_curves(..., input = input)` plus a
       spec flag `gated` computes the curves only when the user clicks
       "Compute / recompute curves", never shows curves for inputs other than
       the ones they were computed from, and says how long it will take
       (measured: binomial ~8 s, Fisher ~12 s, sign ~17 s, Boschloo ~42 s,
       Dunnett ~26 s, RMSEA ~12 s). Every call also has a per-point time
       budget (`ss_curve_points(time_limit=)`; 2 s live, 4 s gated): an
       exact-power search near the null can need thousands of subjects, and
       the first gated run of the binomial test took 140 s because of just
       such points. Abandoned points are counted and disclosed on the plot.

    Two measurement mistakes were corrected on the way. Bayesian assurance
    (~1.1 s), EVSI and Log-Rank `noncompliance` (~6.3 s) had been declined or
    gated on a *single cold first call*; warmed up they take 5-20 ms (the
    first call loads packages), so they now run live. The same cold-call
    effect did not apply to Dunnett or the exact tests, whose full-grid
    timings were measured and are real. Lesson recorded: time a warmed-up
    call, and time the whole grid, before declining a design.

    **Verification by crawl.** A Playwright crawler
    (kept outside the repo; it becomes the basis for item 12) visited every
    design of every module, waited for Shiny to go idle (an earlier version
    judged the page before the server had updated and mistook the previous
    design's plot for the current one's -- the server-side check with
    `shiny::testServer()` confirmed no stale output), and for gated designs
    clicked the button and waited for the plots. Result: **44 of the 49
    modules and 136 browser states (designs, counting the nested
    toggles) show curves**, 0 page errors.

    **What is deliberately not wired, and why** (17 states):
    - *Monte Carlo* -- BFDA, KS, runs, animal-rank, weighted log-rank, GLMM
      (3 designs), RMST (and Cochran's Q): each point is a multi-second
      stochastic simulation, so a 40-point curve is minutes and noisy. This
      needs the background-process work of item 7 (`ExtendedTask`) first.
    - *Not an n-vs-assumption relationship* -- EVPI (a monetary value),
      EFA/CFA rule of thumb and IRT guidance (fixed ratios / a table),
      Resource Equation `check`, Rule of Three `bound` and Pilot (each computes
      a bound or a precision *from* n), Prediction external validation
      (simulation), Cluster `pps_optimal` (cost allocation).
    - *Inputs that are jointly constrained* -- Nonparametric `rank_sum`,
      `signed_rank`, `kendall`, `jonckheere` take tuples of related
      probabilities; varying one alone plots a set the user could not have
      meant.
    - *A whole table* -- Meta-Analysis Power's `or` type.

    Verified: full fast test suite (0 failures/0 errors, 27 expected
    Monte Carlo skips) after `global.R` was confirmed to source cleanly
    each time; Playwright against a running instance across all wired
    designs in every batch (both plots render, current-value point
    present, no page/console errors) and every explicitly-unwired design
    checked in the same passes (each correctly shows the "not yet
    available" message, no stale plot from a previously-selected design
    lingers after switching) -- including a direct per-call timing
    measurement (not just a visual check) for every candidate design
    before deciding whether to ship its curve, batches 5 and 6 alike.
    Running total, recounted directly from each module's own
    `render_power_curves()` wiring rather than carried forward from
    memory (the carried-forward figure quietly drifted off by a few each
    batch -- RM-ANOVA's three designs share one unconditional code path,
    which a naive per-batch tally undercounted): **78 designs wired
    across 31 modules** by batch 8; superseded by the completion block above (136 states across 44 modules).
11. **Package skeleton (Track C1) -- done (14 Oct 2026)**, named `epidemiologicasuite` (GPL-3).
    The app is now an installable R package; install with
    `remotes::install_github("SpaRroW410/Sample_size_all")`, run with
    `epidemiologicasuite::run_app()`.
    - **Layout.** `R/` flattened with `git mv` (162 files; no name collisions).
      `global.R` is gone: `R/registry.R` holds `module_registry()` (now a
      *function*, so it is evaluated after the whole namespace has loaded) and
      `module_groups`; `R/run_app.R` holds `epidemiologicasuite_app()` (the navbar
      shell, formerly `app.R`) and `run_app(...)` (= `shiny::runApp()`). Root
      `app.R` is `pkgload::load_all()` + `epidemiologicasuite_app()` for development.
    - **Load order.** Package files load alphabetically, and only one file had a
      load-time dependency: `design_tree.R` builds its "browse by test" branch from
      `home_catalog.R`'s `test_families`. It is renamed `home_design_tree.R` so it
      sorts after `home_catalog.R` (a comment in the file says why); the
      `test-design_tree.R` coverage tests would fail loudly if that ever broke.
    - **Dependencies.** `DESCRIPTION` `Imports` = the 19 former `p_load()` packages
      plus `survival`, `graphics`, `stats`, `utils`; `Suggests` = `testthat`,
      `withr`. These were found by parsing the code for `pkg::` calls
      (`getParseData`, not grep, which also hit comments and citation strings) and
      by `codetools::findGlobals()` for unqualified calls. Only `shiny` (imported
      whole) and a handful of `bslib`/`stats`/`graphics`/`utils` functions are
      called unqualified, so `NAMESPACE` is a short hand-written file (roxygen2 is
      not available in this environment; it must be kept in sync with `Imports`).
      The ~30 verification-only packages stay out of `Imports`.
    - **Tests.** All `source()` lines removed; the suite runs inside the package
      namespace via `testthat::test_local()` (CI updated), `tests/testthat.R` is
      `test_check("epidemiologicasuite")`. `test-catalog_consistency.R` calls
      `module_registry()`; the ROADMAP-tracking test in `test-design_tree.R` skips
      when `docs/` is absent (it is `.Rbuildignore`d from the installed package).
    - **Verified.** Fast suite via `test_local()`: 523 tests, 2043 assertions, 0
      failures/errors/warnings, 27 expected Monte Carlo skips. `R CMD build` +
      `R CMD INSTALL` in a `C` locale (the pure-ASCII `R/` from item 10 matters
      here); `R CMD check`: the tests step passes against the *installed*
      package; the installed app, started with `run_app()`, was driven in
      Chromium (Proportions result 385 with both curve plots, no page errors).
    - **Known `R CMD check` residue** (not blocking `install_github`): a
      `Sys.setlocale` warning that is this sandbox's missing `en_US.UTF-8`, not a
      package problem; no `man/` pages beyond the two exported functions (hand
      written); the `Authors@R` maintainer e-mail is `ryan00700@gmail.com`
      (required: `R CMD build` rejects a package with no maintainer e-mail;
      supplied by the owner on 14 Oct 2026, after a first version of this item
      used a GitHub no-reply address).
    - **Not done / still open (Track C1 leftovers).** The GitHub repository is
      still called `Sample_size_all` and the navbar title still reads "Sample Size
      Calculator" (renaming the repository changes the install path, so it is the
      owner's call). Deployment: a hosted deployment must now install the package
      and call `epidemiologicasuite::run_app()`/`epidemiologicasuite_app()` from its `app.R`;
      the earlier note that "a two-line `app.R` keeps shinyapps.io working" was
      not tested and is withdrawn until item 18 (hosted deployment, D1).
12. **Automated UI smoke tests (F6) -- done (14 Oct 2026)** with `shinytest2`.
    `tests/testthat/test-ui_smoke.R` (+ `helper-ui.R`) starts the app once in headless
    Chrome and opens each of the 49 modules: the module's navbar pane is on screen, no
    output is in a Shiny error state, its `result` output (where it has one) is
    non-empty; plus the Home hub start-up and a Browse jump, and a final check that no
    JavaScript/R error was logged. Fast lane: 52 tests, 252 assertions, ~2 min. With
    `S2R_SLOW_TESTS=true` a second lane switches through every design of every module's
    primary design radio (33 modules; the other 16 have no design selector and are
    covered by the default-state test): 101 tests, 359 assertions, 0 failures, ~7.5 min.
    Tests skip when `shinytest2`, Chrome or the repository's `app.R` is missing (so
    `R CMD check` on the installed package is unaffected) or with `S2R_SKIP_UI=true`.
    - **Real bugs the first runs found.** (1) The Home hub's Browse jump buttons had
      duplicate HTML ids -- 7 ids, whenever a calculator is listed under several
      families of one lens -- so a click could be shadowed; ids now carry lens and
      family position (`home_browse_button_ids()`, unit-tested). The comment in
      `home_finder.R` that claimed there were no duplicates was only true across the two
      lenses. (2) Shiny was also auto-sourcing `R/` next to the package that `app.R`
      loads (startup warning, code loaded twice): fixed with `_disable_autoload.R`.
    - **Test-harness lessons** (all cost time here): JS built by
      `sprintf` with an attribute selector breaks on a title containing an apostrophe
      ("MANOVA / Hotelling's T-squared") and `run_js()` swallows the syntax error, so
      the helper compares `data-value` in JS and waits for the `main_nav` input;
      `wait_for_idle()` alone can return before a freshly opened tab starts computing;
      `set_inputs()` to an unchanged value waits 30 s for an output update that never
      comes (`wait_ = FALSE`); Chrome needs `--no-sandbox` as root.
    - **Dependency caveat.** `shinytest2` is not in `renv.lock`: its current release
      (0.5.x) imports `httr2`, which needs `rlang >= 1.3.0` while the lock pins 1.1.3.
      Version 0.4.1 (uses `httr`) works with the locked packages; CI installs it with
      `remotes::install_version()`. CI run 26 confirmed it: the install step succeeded and the UI tests ran on the
      runner (`FAIL 0 | SKIP 76 | PASS 2484`; the 76 skips are the 27 Monte Carlo tests and
      the 49 every-design tests).
    - **Not covered (by design).** Numerical correctness (the unit tests do that),
      the click-gated curves and Monte Carlo Calculate buttons (checked in the item-10
      crawl, not asserted here), and visual appearance (no snapshot testing).

### P2 — first suite expansion + portability

13. **Analyze workbench v1** (Track B1) — OpenEpi-parity calculators from summary
    counts, almost entirely on `epiR` (already a dependency). **In progress (14 Oct 2026):
    slices 1-7 of ~9 done -- the 2x2 table, diagnostic-test evaluation, confidence intervals for
    proportions and means, stratified Mantel-Haenszel analysis, and person-time rates and rate
    ratios.**
    - **Done: "2x2 Table Analysis"** (`calc_analyze_2x2.R`, `content_analyze_2x2.R`,
      `mod_analyze_2x2.R`; 50th navbar module, new last dropdown "Analyze Summary Data").
      Three layouts (cohort/trial, cross-sectional, case-control) give RR or PR, OR, RD,
      attributable fraction among the exposed, population attributable fraction and
      NNT/NNH, each with a CI, plus Pearson chi-square and Fisher's exact test. Exports
      (justification paragraph, CSV/JSON/BibTeX/RIS) work through the shared controls.
    - **Verification.** The estimators are written out (Katz RR, Woolf OR, Wald RD,
      Jewell PAF, Altman NNT) instead of calling `epi.2by2()`, whose return shape has
      changed between epiR releases; `epi.2by2()` is the oracle: RR/OR/RD/AF/PAF
      agree to 1e-6 on four tables x two designs, and the case-control OR and PAF match
      too. The published Willeberg (1977) cat-food example from epiR's help page
      (RR 4.01, 1.43-11.23; 75% attributable, 30-91%) is reproduced. Two differences
      from epiR are deliberate: the case-control exposed attributable fraction uses the
      sample OR (epiR uses the conditional MLE), and a zero cell leaves the affected
      interval undefined and flagged instead of silently adding 0.5.
    - **Suite result.** Full fast suite including the browser UI tests (the new module is
      opened by `test-ui_smoke.R` like the other 49): 639 tests, 2659 assertions, 0
      failures/errors/warnings, 77 skips (27 Monte Carlo + 50 every-design UI tests).
    - **Slice 2 done: "Diagnostic Test Evaluation"** (`calc_analyze_diagnostic.R`,
      `content_analyze_dx.R`, `mod_analyze_dx.R`; 51st module, same dropdown).
      *One test* from its TP/FP/FN/TN: sensitivity, specificity, PPV, NPV, LR+, LR-,
      accuracy and Youden's index, each (except Youden) with a 95% CI -- Clopper-Pearson
      exact (default) or Wilson. PPV/NPV come from the counts (valid when the sample
      prevalence is the one of interest) or, at a **stated prevalence**, by Bayes' rule
      with a logit-scale delta-method CI (Mercaldo, Lau & Zhou 2007). *Combined testing*:
      serial ("all positive") and parallel ("any positive") strategies for **2-6 tests**
      from each test's Se/Sp (and optionally the numbers of diseased / non-diseased behind
      them, which switches on 95% CIs), with PPV/NPV at the stated prevalence.
    - **Slice 2 verification.** Single test equals `epiR::epi.tests()` (exact and Wilson)
      to 1e-6 on four tables and reproduces the published Scott et al. (2008) example
      (Se 0.90, 0.88-0.92; Sp 0.76, 0.73-0.79; LR+ 3.75, 3.32-4.24). The serial/parallel
      formulas are checked against an **exhaustive enumeration of all 2^k result
      patterns** for k = 2..6 (an independent oracle, since no package computes them).
      The combined-test variances are checked by simulation: the probability-scale variance
      of the combined Se/Sp matches 40,000 simulated studies to 3% even in small samples;
      the logit-scale SEs of the predictive values match to 3-5% **in large samples** only.
    - **Honest limits.** Combined-test figures assume the tests are *conditionally
      independent given disease*; with dependent tests the real performance is usually worse
      (Vacek 1985) -- the app says so beside the table. Delta-method intervals (stated-
      prevalence PPV/NPV, combined estimates) are asymptotic: in a first test with only 10
      false negatives the NPV interval was ~10% too narrow versus simulation, which is why
      the counts-based exact interval is the default and the help text says so. The
      combined CIs treat the per-test figures as independent estimates; if all tests were run
      on the same patients they are approximate. Formula provenance: serial/parallel Se/Sp
      are the product rule (derived and enumerated, not copied from a source with page
      references -- the help text says "derivation checked", not "from textbook X").
    - **Slice 3 done: "Confidence Intervals"** (`calc_analyze_ci.R`, `content_analyze_ci.R`,
      `mod_analyze_ci.R`; 52nd module). *Proportion* (x of n): six intervals side by side --
      Wilson score, Clopper-Pearson exact, Agresti-Coull, Jeffreys, mid-P exact and Wald (the
      last labelled "not recommended"; Brown, Cai & DasGupta 2001). *Mean and SD* from (n,
      mean, SD): Student t interval, normal-quantile interval and a chi-square interval for the
      SD. Verification: Wilson / exact / Agresti-Coull / Jeffreys equal `epiR::epi.conf()` on
      six (x, n) pairs and `binom.test()`; the mean interval equals `t.test()` on data built to
      have exactly that mean and SD; the mid-P limits satisfy their defining equation to 1e-8
      (epiR has no mid-P, so the definition is the oracle); coverage simulations: exact >=
      nominal, Wilson ~95%, SD interval 95% for normal data. **Two deliberate differences from
      epiR**, both at the boundary: Agresti-Coull is cut to [0, 1] (epiR returns -0.004 / 1.004
      for 1/10 and 9/10), and Jeffreys uses the Brown-Cai-DasGupta end-point convention (lower =
      0 at x = 0, upper = 1 at x = n; epiR returns 0.99998 for 25/25).
    - **Slice 4 done: "Stratified Analysis (Mantel-Haenszel)"** (`calc_analyze_mh.R`,
      `content_analyze_mh.R`, `mod_analyze_mh.R`; 53rd module). 2-8 strata of 2x2 tables, cohort or
      case-control layout. Crude (collapsed) and Mantel-Haenszel adjusted OR (Robins-Breslow-Greenland
      CI), RR (Greenland-Robins) and RD (Sato) with the crude-vs-adjusted change (the 10% confounding
      rule of thumb), stratum-specific estimates, the Cochran-Mantel-Haenszel test (with and without
      continuity correction) and homogeneity tests: Woolf (OR and RR), Breslow-Day and Tarone.
    - **Slice 4 verification.** Pooled OR/RR/RD and CIs equal `epiR::epi.2by2()` and the OR, CIs and
      both CMH statistics equal `stats::mantelhaen.test()` on three stratified data sets (including one
      with a zero cell); Breslow-Day and Tarone equal `DescTools::BreslowDayTest()` (installed from the
      CRAN mirror as an oracle only; not a dependency); the expected counts A* solve their defining
      equation to 1e-8; identical stratum ORs give homogeneity statistics of 0. **One deliberate
      difference from epiR:** epiR's OR homogeneity test is Woolf's test on Haldane-Anscombe (+0.5)
      corrected cells; this app computes the classic uncorrected Woolf test (1955) and the unit test
      reproduces epiR's number from the corrected cells to show that is the only difference. Zero cells:
      the pooled MH estimates use every stratum; the Woolf-type tests use only strata with all four cells
      non-zero and say so; Breslow-Day uses strata whose margins allow A*.
    - **Slice 5 done: "Rates and Rate Ratios"** (`calc_analyze_rates.R`, `content_analyze_rates.R`,
      `mod_analyze_rates.R`; 54th module). *One rate* (events, person-time, reported per a chosen
      multiplier): exact (Garwood), mid-P exact, Byar and Wald intervals side by side. *Two groups*:
      each rate with an exact CI; the **rate ratio** with exact (conditional binomial), mid-P exact
      and Wald-log intervals; the **rate difference** (Wald); the attributable fraction among the
      exposed and the **population attributable fraction**; and three tests of no difference (exact
      conditional, mid-P, score chi-square).
    - **Slice 5 verification.** Exact single-rate limits equal `epiR::epi.conf()` and the chi-square
      (Garwood) form; the rate-ratio exact CI and p-value equal `stats::poisson.test()` and
      `epiR::epi.2by2(method = "cohort.time")` on four data sets, as do the rate difference and the
      attributable fraction among the exposed; the score chi-square equals `prop.test(correct = FALSE)`;
      mid-P limits satisfy their defining equations to 1e-8; the published Feychting et al. (1998)
      example (IRR 0.46, 95% CI 0.38-0.55; RD -7.22 per 1000 person-years) is reproduced.
    - **Three things that differ from, or go beyond, epiR (all documented in the app).**
      (1) **Byar:** the unit-tested form is Rothman's a' = d + 1/2 variant that epiR implements
      (3.12-13.75 for 7 events in 1000 person-years); Byar's original formula in Breslow & Day (1987),
      which uses d and d + 1 and tracks the exact limits (2.80-14.42), is not offered because only epiR's
      form had an oracle -- the app labels it "(a + 1/2 form)". (2) **Population attributable fraction
      CI:** epiR combines separate limits of the overall and unexposed rates, ignoring that both contain the
      unexposed events; this app uses the delta method with the covariance, Var(ln(Ipop/I0)) = 1/d0 - 1/D.
      The two intervals differ a lot for small counts (epiR 21.5%-74.4% vs -17.7%-77.5% for 10/2000 vs 4/2500
      person-years); the unit tests check the SE against 20,000 simulated studies (3%) and the interval's
      coverage (95% +/- 2%). That interval is derived here, not taken from a cited source. (3) The mid-P
      two-sided p-value is twice the smaller one-sided mid-P tail.
    - **Not done in this slice:** stratified rate ratios (the Mantel-Haenszel IRR of epiR's cohort.time
      example, 4.39), standardized rates / SMR (next), and a rate-per-person-time sample-size link.
    - **Slice 6 done: "Paired, Agreement and Trend Tests"** (`calc_analyze_tests.R`,
      `content_analyze_tests.R`, `mod_analyze_tests.R`; 55th module; three designs).
      *McNemar* (paired 2x2): chi-square with and without continuity correction, exact and mid-P
      tests, matched-pair odds ratio with exact and Wald-log CIs, difference of the two positive
      proportions. *Cohen's kappa* (2-6 categories; unweighted, linear or quadratic weights): kappa with
      the Fleiss-Cohen-Everitt (1969) CI, test of kappa = 0, observed/chance agreement, PABAK, Landis-Koch
      labels (marked as a convention). *Chi-square for trend* (Cochran-Armitage; 2-8 ordered groups with
      optional scores) with Wilson CIs per group.
    - **Slice 6 verification.** McNemar equals `stats::mcnemar.test()` (both corrections) and `binom.test()`
      on four tables; kappa and CI equal `DescTools::CohenKappa()` for all three weightings on 2x2, 3x3 and
      4x4 tables, the unweighted SE equals the explicit 1969 Fleiss-Cohen-Everitt expression, and the 2x2
      kappa, PABAK and null-hypothesis SE equal `epiR::epi.kappa()` (whose CI uses the null-hypothesis SE,
      which is why this app does not copy epiR's interval); the trend statistic equals
      `stats::prop.trend.test()` with default and custom scores, and is unchanged by reversing the groups
      or rescaling the scores; the SE of the paired difference matches 20,000 simulated studies (3%).
      Known limits stated in the app: the paired-difference Wald interval is approximate, kappa depends on
      prevalence, the trend test detects only a linear trend.
    - **Slice 7 done: "Standardization and SMR"** (`calc_analyze_standardization.R`,
      `content_analyze_standardization.R`, `mod_analyze_standardization.R`; 56th module; three designs).
      *Direct standardization*: per-stratum events and person-time (2-12 strata) against a standard
      population; crude rate (exact CI) and directly standardized rate with the Fay-Feuer gamma CI;
      optionally a second group, with the ratio and difference of the two standardized rates.
      *Indirect*: person-time by stratum x reference rates -> expected events -> SMR. *SMR* from observed
      and expected counts. SMR intervals: six methods side by side (see below); four tests of SMR = 1.
    - **Slice 7 verification.** The published Thrusfield (2007) example from epiR's help page is
      reproduced to 7 digits (Glasgow standardized rate 0.2599, 95% CI 0.1964-0.3406, i.e. "26 (20 to 34)
      per 100 dog-years"); the direct rate, CI and crude rate equal `epiR::epi.directadj()` on four data
      sets including one with a zero-event stratum; standardizing to the group's own person-time gives the
      crude rate and variance (an identity check); expected counts equal `epiR::epi.indirectadj()`'s
      (52 and 140); the SMR exact interval and p-value equal `stats::poisson.test()`; mid-P limits satisfy
      their equations. The SE of the ratio and difference of two standardized rates matches 8,000 simulated
      studies (4%) -- **that comparison is derived here by the delta method, not from a cited source**.
    - **Deliberately not copied from epiR:** `epi.indirectadj()`'s SMR interval is the Poisson
      *quantile* of the observed count divided by the expected count (a discrete, non-standard interval,
      e.g. 0.846-1.404 for 58/52 against the exact 0.847-1.442); this app shows the exact (Ulm/Garwood), mid-P and
      other published intervals instead. `epi.conf(ctype = "smr")` does not compute O/E and was not used.
      Also not offered: indirectly adjusted rates (SMR x standard crude rate), which need the standard
      population's own crude rate; SMRs of different groups are not comparable and the app says so.
    - **SMR intervals: six methods side by side (added 16 Oct 2026 at the owner's request: "calculate it
      by all methods, compare them side by side, and leave it to the user").** Exact (Garwood/Ulm/Liddell),
      mid-P exact, Byar, Rothman-Greenland (log), Vandenbroucke (square root) and Wald (naive), with a note per
      method, plus four tests of SMR = 1 (exact Poisson, mid-P, chi-square (O-E)^2/E, Byar's z).
      *Citation search:* the existence, journal, volume and pages of Liddell 1984 (J Epidemiol Community Health
      38:85-88), Ulm 1990 (Am J Epidemiol 131:373-375), Vandenbroucke 1982 (Am J Epidemiol 115:303-304, DOI
      10.1093/oxfordjournals.aje.a113306), Ury & Wiggins 1985 (Am J Epidemiol 122:197-198), Miettinen 1974 (J Am
      Stat Assoc 69:380-382) and Rothman & Boice 1979 (NIH Publication 79-1649, 129 pp.) were confirmed by web
      search; Byar's limits are attributed to "Byar, unpublished" by Rothman & Boice (per the SEER documentation)
      and appear in Breslow & Day 1987 vol. II. **The original papers could not be read** (no full text was
      reachable from the sandbox), so the formulas were verified numerically instead: against **epiR 3.0.0's
      `epi.smr()`** (a CRAN release newer than the one in renv.lock, so its values are hard-coded in the unit
      test with their provenance), `stats::poisson.test()` and `DescTools::PoissonCI()`.
    - **Found while doing this (reported, not worked around):** epiR 3.0.0's `epi.smr(method = "fisher")`
      lower confidence limit differs from the exact (Garwood) lower limit -- 0.492 vs 0.330 for 4 observed / 3.3
      expected -- an apparent off-by-one in the root-finding (it solves P(X <= O) = 1 - alpha/2 instead of
      P(X <= O - 1)); the upper limit agrees. That method is not used. Its mid-P limits use `uniroot()`'s default
      tolerance (~1e-4, so they differ from this app's at the 5th digit). `epi.conf(ctype = "smr")` does not
      compute O/E at all. **Not offered:** the Ury-Wiggins (1985) shortcut, because epiR's own comment says its
      reference code was wrong and the constants could not be verified from the paper; and the Regidor et al.
      (1993) reference that epiR's code comments attribute the Byar interval to, which could not be found.
      Two Byar forms exist: this module uses the (O, O + 1) form of `epi.smr()`/Breslow & Day, which tracks the exact
      limits (0.326-3.103 vs exact 0.330-3.104 for 4/3.3); the person-time-rate module uses the O + 1/2 form that
      `epi.conf()` and `DescTools` implement (see slice 5).
    - **Wiring.** Three catalog entries (one per design radio value, as the consistency
      tests require), a study-design family and a test family, and a new wizard root
      option "Analyze counts I already have" -> "How were the subjects sampled?".
      The free-text wizard (`design_free_text.R`) does not yet know analysis keywords.
    - **Slice 8 done: "Compare Two Groups"** (`calc_analyze_compare.R`, module `analyze_compare`), again with
      several published methods side by side, the choice left to the user. *Two proportions* (x1/n1 vs x2/n2):
      difference by Wald, Wald with continuity correction, Agresti-Caffo, Newcombe hybrid score (with and without
      continuity correction), Miettinen-Nurminen score and Mee score; ratio by Koopman score, Katz log and
      adjusted log (+1/2, defined when a count is zero); odds ratio by conditional exact (Fisher) and Woolf; plus
      Pearson chi-square and Fisher tests. *Two means* (n, mean, SD per group): Welch and pooled-variance t
      intervals/tests, variance-ratio F interval/test, Cohen's d and Hedges' g with noncentral-t intervals.
    - **Slice 8 verification.** Every proportion interval was compared with `DescTools::BinomDiffCI()` /
      `BinomRatioCI()` on the 56/70 vs 48/80 example (Newcombe 1998). Wald, Agresti-Caffo, Newcombe and Katz agree
      to 1e-5; Miettinen-Nurminen, Mee and Koopman differ from DescTools by up to ~1e-4 because DescTools solves the
      score equation with `uniroot()`'s default tolerance (this app solves it to 1e-12; the unit tests check the
      score equation itself at the returned limits and use an absolute 5e-4 tolerance against DescTools). Odds ratios
      equal `fisher.test()`; t and variance-ratio results equal `t.test()` / `var.test()` on data constructed to
      have exactly the entered summary statistics; the noncentral-t limits satisfy their defining equation; and a
      1000-replicate coverage simulation checks that the score intervals sit near nominal coverage. Worked-example
      numbers shown in the app were re-read from the code (an earlier draft of the means example had wrong
      numbers and was corrected). The Miettinen-Nurminen N/(N-1) factor is included (Mee omits it), as in
      Newcombe/Fagerland et al.
    - **Citations (honest status).** Newcombe 1998 (Stat Med 17:873-890, 857-872), Miettinen & Nurminen 1985 (Stat
      Med 4:213-226), Mee 1984 (Biometrics 40:1175-1176), Koopman 1984 (Biometrics 40:513-517), Welch 1947,
      Hedges 1981 (J Educ Stat 6:107-128), Cumming & Finch 2001 (Educ Psychol Meas 61:532-574) and Fagerland,
      Lydersen & Laake 2015 (Stat Methods Med Res 24:224-254) are cited; the existence, volume and pages of
      Koopman, Hedges, Cumming & Finch and Fagerland et al. were confirmed by web search, the others (Newcombe, Miettinen-Nurminen, Mee, Welch) are cited as given in the
      DescTools/R documentation and were not independently web-checked. The original papers could not be read, so formulas are verified
      numerically against the packages above, not against the papers.
    - **Slice 9 done: stratified rate ratios and vaccine efficacy.**
      *Stratified rates* (new design `stratified` of the Rates module, 2-8 strata of events and person-time):
      Mantel-Haenszel rate ratio (Wald limits on the log scale, Greenland-Robins variance) and rate difference, the
      crude (collapsed) estimates beside them with the percent change, stratum-specific rate ratios (exact
      conditional CI), a Mantel-Haenszel-type score test and two homogeneity tests. *Vaccine efficacy* (new module
      `analyze_vaccine`): VE = 1 - RR, limits = 1 minus the limits of the ratio with the ends swapped, for three data
      types -- cases/participants (Koopman, Katz, adjusted log), cases/person-time (exact, mid-P, Wald), and
      case-control / test-negative counts (Woolf, conditional exact) -- the methods shown side by side.
    - **Slice 9 verification.** MH rate ratio, its limits, the MH rate difference with limits, the crude exact
      interval and the stratum-specific exact intervals all equal `epiR::epi.2by2(method = "cohort.time")` to 1e-8.
      The one-stratum limit equals the two-group tool, the score statistic of two identical strata is twice that of
      one, the result is invariant to rescaling person-time, and the Woolf statistic equals a weighted
      least-squares residual sum of squares (`lm`). A 3000-replicate simulation (slow lane) gives 95.0% coverage for
      the MH interval and 4-5% rejection for the null score test and both homogeneity tests when the rate ratio is
      common (about 60-150 events per stratum; with only ~12 events per stratum the Woolf test is conservative, 3.2%,
      as is typical for it). VE limits equal 1 minus the limits of `calc_analyze_compare_proportions()` /
      `calc_analyze_rate_ratio()`, a hand-built Clopper-Pearson interval mapped to VE, `fisher.test()` and the
      Woolf formula; the risk ratio the VE is built from equals `epiR::epi.2by2(method = "cohort.count")`.
    - **Honesty notes (slice 9).** (1) The *Breslow-Day-type homogeneity test for rate ratios is derived here* by
      analogy with the odds-ratio test (Pearson statistic of the exposed events against their expectation under the
      Mantel-Haenszel rate ratio, referred to chi-square on strata-with-events minus 1 df); it is labelled as derived
      in the app and its size is checked only by simulation. (2) The Mantel-Haenszel rate-ratio and rate-difference
      forms follow Rothman & Boice 1979 / Greenland & Robins 1985 (Biometrics 41:55-68) as implemented in epiR; the
      original papers and *Modern Epidemiology* could not be read here, so no chapter is cited and the formulas
      rest on the numerical agreement above. (3) For VE only Orenstein et al. 1985 (Bull World Health Organ
      63:1055-1068) was confirmed by web search. The BNT162b2 trial (Polack et al. 2020) is **not** cited: its
      primary interval was a Bayesian credible interval, not these confidence intervals. (4) VE here is crude -- no
      adjustment for confounding, waning or misclassification, and the app says so; VE = 1 - OR from a case-control
      study estimates 1 - RR only when controls represent the source population. The worked examples use
      illustrative numbers and are labelled as such.
    - **Free-text wizard: analysis keywords (done).** `design_free_text.R` now routes text that states analysis of
      existing data outright ("2x2 table", Mantel-Haenszel, SMR, "analyze the counts I have", "from the summary
      counts", "confidence interval for a proportion") to the Analyze branch, and a new `analyze_type` rule table picks
      the sub-branch (stratified, standardization, vaccine, rates, paired/agreement, diagnostic, intervals, two-group
      comparison, 2x2). Words like "vaccine efficacy" or "sensitivity" alone are deliberately *not* root cues, because
      planning text uses them too (tested: "sample size for a vaccine efficacy trial" still routes to Compare).
    - **Item 13 is complete** (nine slices). Not done, by choice: Ury-Wiggins SMR limits (constants unverifiable),
      adjusted VE from models, stratified rate-ratio exact (conditional) intervals.
14. **Planning tools** (Track B2) — **done (16 Oct 2026)**: randomization lists and attrition /
    non-response inflation; the protocol text already existed (the justification paragraph of
    item 9) and both new modules reuse or extend it.
    - **Randomization List** (`calc_randomization.R`, module `randomization`, group "Study Planning Tools" of the
      Plan workbench): simple, permuted-block (any allocation ratio, 2-8 arms, one fixed block size or several chosen
      at random per block) and stratified permuted-block lists; reproducible from a seed; CSV download of the full list;
      a methods paragraph with a bracketed placeholder for who generated and holds the list; guidance on allocation
      concealment. The generator is pinned inside the call (Mersenne-Twister, rejection sampling) and the caller's own
      random stream is restored, so the same seed gives the same list on any R >= 3.6 and other code is never disturbed.
    - **Attrition and Non-response** (`calc_attrition.R`, module `attrition`): enrol n / prod(1 - d_i) over 1-6 stages
      (shown against the common error n (1 + d)), per-arm inflation for different losses (with the contrast against
      using the average loss), and the drop-out / drop-in dilution factor 1 / (1 - R_E - R_C)^2.
    - **Verification.** No package computes "the right list", so the unit tests check the defining properties: exact
      balance in every complete block (ratios 1:1, 2:1:1, 2:1), every ordering of a block equally likely (chi-square
      over 6000 lists), block sizes drawn equally often, per-stratum balance and independence, long-run arm
      frequencies, reproducibility, the caller's RNG stream untouched, and regression values for fixed seeds (recorded
      from this code under R 4.3.3, so they guard against change but are not independent references). Attrition: the
      identities are recomputed from the expected number of analyzable participants, and a rounding guard avoids
      floating-point over-rounding (9 / (1 - 55/100) is 20.000000000000004 in floating point, which a bare ceiling()
      turns into 21 instead of 20; such cases occur for many n and whole-percent losses). A power simulation (slow lane) shows that with the
      inflated n the intention-to-treat z test reaches about the planned power, and with the uninflated n it does not.
    - **Honesty notes (item 14).** (1) The dilution formula was *derived here* (n is proportional to 1 / difference^2
      with the variance unchanged); Lachin JM, Control Clin Trials 1981;2:93-113 is the reference it is usually
      attributed to, whose existence was confirmed by web search but whose equations were not read; the app says so.
      It is approximate for proportions. (2) The retention formulas are identities and are labelled as such, with no
      citation. (3) Randomization references (Altman & Bland BMJ 1999;319:703-704; Schulz & Grimes Lancet
      2002;359:515-519 and 359:614-618; Matts & Lachin Control Clin Trials 1988;9:327-344) were confirmed by web
      search to exist with those volumes and pages (the search did not return the author list of the last one; the
      authorship is from memory); none could be read. (4) The methods paragraph does not claim concealment: it leaves a
      bracketed prompt for it. A seed makes a list reproducible, not secret -- the app says to keep it confidential.
      (5) The free-text wizard only routes text that names the planning task outright; a sample-size request that
      merely mentions dropouts still goes to Compare (tested).
15. **Shinylive feasibility spike** (Track D3) — **done (16 Oct 2026): conditional go for a static browser build; the offline/APK path is not yet decided.**
    - **How it was run.** The sandbox cannot reach `repo.r-wasm.org`, so the spike runs on GitHub's runners
      (`.github/workflows/shinylive-spike.yml`, `tools/webr-spike/`; the browser stage is parked with `if: false`, flip
      it to re-run). Stage 1 (`check_packages.R`) checks every runtime dependency against the webR package repository.
      Stage 2 builds the app with `shinylive::export()` and drives it in headless Chrome served from localhost, opening
      every module and every design radio value and recording output errors and validation messages. Network times
      are therefore *not* representative of a real phone connection.
    - **Packages.** The 20 non-base imports pull in 168 packages; 165 exist as WebAssembly builds. Missing: `rootSolve`
      (needed by `Exact`), `deSolve` and `quadprog`. The packages total about 180 MB of downloads before the webR
      runtime (the exported `shinylive/` folder alone is 77 MB); a first page load transferred about 170-190 MB.
    - **Booting.** A build with a patched font stack boots: the interface appears after about 75-120 s (runner, local
      server) and the first calculation takes about 7-12 s. Loading `PowerTOST` at start-up breaks the whole app (a
      shared library, `commonmark.so`, fails to load; bisected to `PowerTOST` alone, whose `cubature` dependency also
      fails to load at call time). The build that works leaves `PowerTOST` unattached, so only its own designs fail.
    - **Calculators.** Of 185 design options in 60 modules, **177 work**. 15 that looked empty after 25 s finish
      within about 46 s (Monte Carlo and simulation designs are slower in the browser). 5 are the app's own validation
      messages at default inputs (planned contrast of zero, identical proportions in two Chi-Square designs, a Meta-Analysis
      Power cell-count mismatch, and RMST with identical arms), which are not browser problems; judged from their wording
      and the default inputs, not re-run in the native app. **8 fail for real:** Equivalence (TOST) "means" (`cubature` cannot
      load), Exact Tests Fisher / Boschloo / Poisson / sign (`rootSolve` missing), Longitudinal Diggle and Edland
      ("LAPACK routines cannot be loaded"), and Rule of Three "detect_imperfect" (see F13 -- not specific to the browser).
    - **What is heaviest.** `epiR` drags in 86 packages (97.8 MB; 44.4 MB needed by nothing else, including `sf`, `s2`,
      `units`, `ggplot2`) for nine closed-form sample-size calls (`epi.sscc`, `epi.ssclus`, `epi.sscohortc`,
      `epi.sssimpleestc`, `epi.ssninfb`, `epi.ssninfc`, `epi.ssdetect`, `epi.ssequb`). `rstatix` (86.7 MB closure, 21.8 MB
      unique) is called exactly once, for Cochran's Q. Then `BayesFactor` (8.4 MB unique), `Hmisc` (5.9), `tseries` (4.7),
      `PowerTOST` (3.5). Dropping `epiR` and `rstatix` alone would remove about two thirds of the unique weight and make
      the browser (and CRAN) story far lighter; this is the concrete target for item 16.
    - **Browser-build fixes and re-crawl (17 Oct 2026).** Done in the app: the theme's Google Font download is replaced by a
      local font stack (F12 fixed); `solve()` / `chol()` fall back to a small base-R routine only when LAPACK is
      missing (`.solve_safe()`, `.chol_safe()`, tested against the real functions), which fixed the two Longitudinal designs;
      the Fisher / Boschloo (`Exact`) and the three bioequivalence (`PowerTOST`) designs now stop with "needs the R package
      ..., which cannot be loaded in this environment" instead of a package-loading error (`.require_pkg()`). Rule of Three
      "imperfect test" was fixed by item 16. Spike tooling only (not in the app): the browser app attaches just `shiny` and
      `bslib`, and a prelude loads `MASS` and `lme4` at start-up -- loading them late made `MASS.so`, then `rbibutils.so`,
      fail to load ("could not load dynamic lib"), so any real Shinylive build of the package needs the same prelude.
      **Result of the last full crawl (185 design options, 60 modules):** the interface appears after about 40-70 s, the first
      calculation after 6-11 s, the page transfers 64 MB (was 170-190 MB before item 16). 176 options render a result;
      5 show the app's own validation message at default inputs (not browser problems); 3 show the plain "needs the R
      package" message (TOST means, Fisher, Boschloo -- by design, no WebAssembly build of `rootSolve` / `cubature`); 1
      (Trial Sequential Analysis, RR) did not finish within 150 s in the last crawl although it did in earlier ones, so
      its browser speed is still open. Network times come from a CI runner and are not representative of a phone.
    - **Decision.** A static browser build (`shinylive`, GitHub Pages) is feasible and covers 96% of the designs today.
      It is worth offering as a *secondary* distribution once (a) item 16 has removed `epiR` and `rstatix` from the
      runtime path (cuts the first download by roughly a third to a half, to be measured), (b) the browser build gates the
      8 failing designs with a clear "not available in the browser version" message, and (c) the font change below is
      made. It should not yet be promised as the offline / APK route: first load is 170+ MB, only the `light`
      one-module case was timed on a real run, mobile memory limits were not tested, and the TWA / Capacitor wrappers
      (D5a, D5b) were not tried. Re-run the spike after item 16 and against the newest webR before deciding D5.
16. **Phase 8 dependency reduction, tier 1** (§9) — **done in part (17 Oct 2026): the six packages the item 15 spike
    identified as heaviest are out of the runtime.**
    - **Removed from `Imports`:** `epiR` (9 calls), `rstatix` (1), `Hmisc` (3), `tseries` (1), `BayesFactor` (1).
      Each call is replaced by a closed form in `R/calc_closed_forms.R`, transcribed from the function it replaced and
      **tested against the real function** over input grids (the packages moved to `Suggests` as oracles, so the tests skip
      cleanly where they are absent). Agreement is to floating-point noise, except the JZS Bayes factor (relative
      difference 1.8e-9 against `ttestBF`, whose own integration tolerance it is within).
    - **Results unchanged.** The seeded Monte Carlo designs (Cochran's Q, runs test, BFDA, noncompliance power) were run
      in the slow lane before and after and reproduce, and a direct before/after comparison of BFDA power at n = 20/40/60
      gives identical rejection rates. `BayesFactor`'s replacement is also about 80x faster per call (0.09 ms against
      7 ms), so the BFDA design is much quicker (its default `nsim` was left as it was).
    - **Measured effect** (the item 15 package check, same method): the dependency closure of the runtime imports went
      from **168 to 58 packages**, the download from **180 MB to 51 MB (-71%)**, and the packages with no WebAssembly build
      from **3 to 1** (`rootSolve`, needed by `Exact`). Imports in `DESCRIPTION`: 20 -> 15 non-base (14 listed plus `survival`).
    - **Bonus fix (F13).** Rule of Three "imperfect test" no longer depends on `epiR`'s changing `epi.ssdetect()`
      interface, so it works on a fresh install; the code follows the pinned 2.0.67 semantics, which are what the app's
      worked examples and tests were built on.
    - **Honesty notes.** (1) The replacements reproduce `epiR` 2.0.67 / `rstatix` / `Hmisc` 5.1.1 / `tseries` /
      `BayesFactor` *as they were*, including their rounding conventions; where those packages have quirks (e.g. `epi.ssninfb`
      leaves the treatment group unrounded when `r` is not 1), the quirk is kept so results do not move, and flagged in
      the code. (2) `epi.ssdetect()` in the current `epiR` 3.0.0 has a different interface and was not compared. (3)
      `Hmisc::cpower` cites Lachin & Foulkes (1986) in its own documentation; the formula was transcribed from the
      package, and Lachin & Foulkes was not read. (4) Rouder et al. 2009 (Psychon Bull Rev 16:225-237) was already cited in
      the app; the formula was transcribed from the usual statement of eq. 1 and verified numerically against
      `BayesFactor`, not read in the original.
    - **Still to do (tier 1 remainder, now low value for size):** `pwr`, `powerMediation`, `pmsampsize`, `pROC` (each
      under 1 MB). **Moderate:** `presize` (0.5 MB unique), `powerSurvEpi`, `TrialSize`. **Defer (higher risk):**
      `PowerTOST` (also what breaks the browser build: `cubature`), `Exact` (Boschloo; `rootSolve` has no WebAssembly
      build), `clinfun`. Largest remaining runtime weight: `lme4` (11 MB unique; used by the Monte Carlo mixed-model
      designs, so kept), then `survival`, `bslib`, `shiny`.
17. **pkgdown documentation site** (free, GitHub Pages) -- **built and passing in CI (17 Oct 2026); publishing waits for
    the owner to enable Pages and merge to `main`.**
    - **What it is.** `tools/docs/build_site_sources.R` generates, from the package itself, one page per calculator (60) from
      its `<module>_content` object -- title, formula (MathJax), explanation, worked example, citation and "implemented
      via", the same text as the app's Formula / Help and Reference tabs -- plus a calculator overview grouped by workbench
      and category, and pages for the roadmap, the software design and the study-design algorithm. Nothing generated is
      committed, so the site cannot drift from the app. `.github/workflows/docs.yml` builds it with pkgdown on every push
      (178 files, "Checking for problems" clean) and keeps it as an artifact; on `main` it deploys with
      `actions/deploy-pages`. Output goes to `site_out/`, not `docs/`, which holds the project's markdown documents.
    - **Checks done.** All 64 generated pages render with pandoc locally (482 formulas converted, no stray `$` in the
      calculator pages); the CI build passes. pkgdown itself could not be run in this sandbox, so the first look at the
      built site (navigation, search, MathJax in the browser) is for the owner or the next session: download the `site`
      artifact from the docs workflow.
    - **To publish:** Settings > Pages > Source: *GitHub Actions*, then merge this branch to `main` (the deploy job only
      runs from `main`). **Open:** a custom domain, a "Try it online" link once a hosted or browser build exists, and
      cross-links from each page to the matching section in the app.

### P3 — distribution and larger workbenches

18. Hosted deployment + Docker image (D1), PWA (D4), Android APK via TWA (D5a),
    desktop wrapper (D7). **Docker image done (21 Oct 2026); the rest is open.**
    - **Docker (D1, first half).** `Dockerfile` (pinned `rocker/r-ver:4.4.3`, dependencies installed from `DESCRIPTION` in a
      cached layer, package installed, unprivileged user, `$PORT`, health check), `.dockerignore`, `docker-compose.yml`.
      `.github/workflows/docker.yml` builds it, starts the container and drives it in headless Chrome
      (`tools/docker/smoke.mjs`: navbar appears, Rule of Three returns the exact bound 0.0950): the first CI run
      passed, with the navbar visible after 5.8 s. Pushes to `main` and `v*` tags also publish to
      `ghcr.io/<owner>/epidemiologicasuite` with the default `GITHUB_TOKEN` (not exercised yet: no push to `main` since).
    - **Not done / decisions for the owner.** *Where to host it* (shinyapps.io, Posit Connect, Fly.io / Render / a VPS
      running the image) needs an account and a budget; the image runs anywhere that runs a container. *Multi-user
      load*: Shiny is one R process per container, so concurrent simulations queue (F9, still open: `ExtendedTask`); put
      the image behind a proxy that starts one container per session (e.g. ShinyProxy) or scale replicas. *Image size and
      arm64* were not measured or built (amd64 only; Apple-silicon users get emulation). *HTTPS/domain*, **PWA** (D4) and
      the **Android TWA** (D5a) need a public HTTPS host first; the **desktop wrapper** (D7) is not started.
19. r-universe release, then CRAN (Track C4).
20. Survey/field-epi tools (B3), outbreak & surveillance (B4), ID modelling for
    teaching (B5). **B3, B4 (counts-based parts) and B5 done (21 Oct 2026); line lists, epidemic curves and Rt stay deferred (D1).**
    - **Survey Sample Selection** (`calc_survey.R`, module `survey_selection`, group "Survey & Field Tools" of the Plan
      workbench): simple random sample, systematic sample (random start, fractional interval allowed), PPS systematic
      (Madow 1949) with iterative certainty units and an optional random-order variant, and the **WHO EPI 30 x 7** design
      (clusters by PPS, a fixed number of subjects per cluster; the field selection of households is *not* computed and the
      app says so). Reproducible from a seed (the same pinned generator as the randomization lists); the table of selected
      units with inclusion probabilities and design weights downloads as CSV; a methods paragraph with a bracketed prompt.
    - **Survey Weights and Non-response** (module `survey_weights`): design weights N/n, nonresponse adjustment in weighting
      classes (adjusted weight N/r), weighted and unweighted response rates, Kish's effective sample size and design effect
      of weighting (1 + CV^2), from class counts or from a pasted list of weights; generic CSV/JSON/BibTeX/RIS export.
    - **Verification.** No package computes "the right sample", so the tests check the defining properties: exact sample size,
      no unit twice, inclusion probabilities by simulation over seeds (SRS, systematic, PPS), reproducibility and an untouched
      caller RNG, iterative certainty units on a hand-built frame, and for PPS the exact Horvitz-Thompson identity
      (sum of size / pi over the sample = frame total, checked over 120 random frames) -- which caught a real bug during
      development (a vectorised `ifelse()` returning a scalar). PPS systematic is also compared with
      `sampling::UPsystematic()` (installed from the `github.com/cran` mirror as an oracle only) for the same random start on
      60 random frames. Weights: identities (adjusted weights add up to the population; weighted response rate), the class
      function agrees with the list-of-weights function on the expanded weights, hand values (weights 1, 1, 2, 2 give n_eff 3.6),
      and a Monte Carlo check that the adjusted-weight estimator of a total is within 1% of the truth when response differs
      by class while ignoring nonresponse is off by more than 20%.
    - **Honesty notes.** Madow 1949 (Ann Math Stat 20:333-354), Henderson & Sundaresan 1982 (Bull World Health Organ
      60:253-260) and Bennett et al. 1991 (World Health Stat Q 44:98-106) were confirmed by web search to exist with those
      volumes and pages; Valliant, Dever & Kreuter 2013 (Springer) is a real book whose pages were not read; Kish 1965 was not
      looked up. None of the originals was read: the formulas are checked numerically, not against the papers. The treatment of
      certainty units is the usual one, written from the description rather than a transcription of a package. `PracTools`
      could not be installed here (its dependencies are heavy), so it was not used as an oracle. Weighting classes assume
      equal-probability sampling within a class; post-stratification to external totals, raking, trimming and variance
      estimation are not offered.
    - **Outbreak Measures** (`calc_analyze_outbreak.R`, module `analyze_outbreak`, Analyze workbench, group "Outbreaks and
      surveillance"): attack rate; the exposure-specific attack-rate table (one row per suspected food or event: attack rates of
      the exposed and unexposed, risk ratio with the Katz interval, risk difference, Fisher's exact p, share of cases exposed);
      secondary attack rate; case fatality, crude and among resolved cases, each with the six proportion intervals of the CI
      tool. Nothing new is estimated: the module re-arranges `calc_analyze_ci_proportion()` and `calc_analyze_2x2()` the way
      an outbreak investigation uses them, and carries the cautions in the interface (screening-table p-values are descriptive;
      the secondary-attack interval ignores household clustering; crude CFR is biased low and the resolved-case ratio high while
      cases are unresolved).
    - **Aberration Detection** (`calc_analyze_surveillance.R`, module `analyze_surveillance`): CDC EARS C1, C2 (2-day guard
      band) and C3 (sum of the last three C2 excesses over 1 SD), and a one-sided CUSUM in its normal form and its Poisson form
      (Lucas's reference value), on a pasted series of counts, with a two-panel base-R plot. **Verification:** C1 and C2
      equal `surveillance::earsC()` (installed from the `github.com/cran` mirror as an oracle only; thresholds matched by
      alpha = 1 - pnorm(3)); `earsC`'s C3 alarm rule drops the current-day term of the three-day sum, so it is **not** the
      definition used here and C3 is checked by direct recomputation (the difference is noted in the code and the Reference
      tab); the false-signal rate of C1 and C2 on stable normal counts equals the t-distribution value 0.0155 (simulation, slow
      lane); CUSUM run lengths in control (ARL 336 for k = 0.5, h = 4, one-sided) and after 0.5 and 1 sd shifts agree with
      `spc::xcusum.arl()` by simulation (slow lane). A mistake caught on the way: the "ARL 168 / 465" quoted for k = 0.5,
      h = 4 / 5 are the **two-sided** values; the one-sided ones are 336 and 931 (spc), and the header and help now say so.
    - **Epidemic Models and Herd Immunity** (`calc_epidemic_model.R`, module `epidemic_model`, new Plan group "Infectious
      Disease Models"): herd-immunity threshold 1 - 1/R0 and coverage needed with an imperfect vaccine (threshold / efficacy,
      flagged unattainable above 100%), Re = R0 (1 - cE), a deterministic SIR / SEIR epidemic with vaccination before the start
      stepped by fixed-step RK4 in base R (no solver package at run time), final size, peak, growth rate, doubling time and
      infections averted, plotted; and R0 from a doubling time (generation-interval relation for exponential stages) or from a final
      attack fraction. **Verification:** the stepped solution equals `deSolve::ode()` (lsoda, rtol 1e-11) for an SIR and an SEIR
      run; the final size equals the closed-form root of s = s0 exp(-R0 (1 - s - v)) and the textbook 79.7% for R0 = 2; the SIR
      peak equals i0 + s0 - (1 + ln(R0 s0)) / R0; SEIR has the same final size as SIR with a later and lower peak; the SEIR growth
      rate is the root of (r + sigma)(r + gamma) = sigma gamma R0 s0 and equals the measured early slope of the stepped run;
      R0 recovered from the stepped run's growth rate and final size (also with prior immunity) equals the input.
    - **Honesty notes.** Existence, journal, volume and pages confirmed by web search: Hutwagner et al. 2003 (J Urban Health
      80(Suppl 1):i89-i96), Fricker, Hegler & Dunfee 2008 (Stat Med **27:3407-3429**; I first had 3417 from memory and the search
      corrected it), Page 1954, Lucas 1985, Hethcote 2000 (SIAM Rev 42:599-653), Fine, Eames & Heymann 2011 (Clin Infect Dis
      52:911-916), Wallinga & Lipsitch 2007 (Proc R Soc B 274:599-604). **Not** web-confirmed: Kermack & McKendrick 1927,
      Anderson & May 1991, Hawkins & Olwell 1998, the CDC *Principles of Epidemiology* manual (all flagged as such in the
      Reference tabs). None of the originals was read; formulas are checked numerically. The models are teaching tools:
      homogeneous mixing, closed population, exponential stage durations, vaccination before the start only; the app says so.
      R0 from a growth rate uses exponential stages, and a more peaked generation interval would give a lower R0.
21. Raw-data analysis workbench (B6) — **deferred by D1** (summary-data only for now);
    evidence synthesis (B7) from study summaries stays in scope, and
    evidence synthesis (B7).
22. Accessibility/mobile audit, dark mode (F11) -- **done in part (28 Oct 2026).** Translations: not planned (D5, English only). Details below.

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
| Non-inferiority margins (RR / OR / HR / difference) | True **relative-risk-scale** margin. `TrialSize::RelativeRisk.NIS()` is really odds-ratio-based, so it ships as the OR design; no verified RR-scale source yet. *Added 28 Sep 2026 from the review-PDF cross-check* |
| Holm / FDR | **Holm's step-down** as its own design. Bonferroni (shipped) is Holm's most conservative step; Holm's later thresholds depend on the observed p-values, so there is no single planning alpha — needs a simulation-based design. *Added 28 Sep 2026* |
| Value of information (EVPI / EVSI) | Multi-parameter EVPPI and non-Normal outcomes (only the single-parameter, known-SD case ships). *Added 28 Sep 2026* |
| Bioequivalence (TOST) | Reference-scaled designs for highly variable drugs (RSABE / ABEL): the 2×2, 2×2×4 and 2×3×3 designs ship with fixed 80–125% limits; `PowerTOST::sampleN.RSABE()`/`sampleN.scABEL()` exist in a runtime package but are simulation-based and not wired in. (Named in the checklist, not in the review PDF.) *Added 28 Sep 2026* |
| Multi-arm vs. common control | Dunnett for **binary** outcomes (means only; the wizard falls back to Bonferroni/Sidak two-proportion n). *Added 28 Sep 2026* |

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
| **B4 Outbreak investigation & surveillance** | Attack rates, secondary attack rate, case-fatality; epidemic curves from an uploaded line list; R0/Rt; aberration detection (EARS C1–C3, CUSUM) | Needs data upload; `ggplot2`; `EpiEstim` for Rt (check WebAssembly availability first). Under D1 the rates-from-counts parts are in scope; line-list upload, epidemic curves and Rt are deferred with B6 | P3 | Medium–High |
| **B5 Infectious-disease modelling (teaching)** | SIR/SEIR with vaccination, herd-immunity threshold, coverage needed | Base-R ODE stepping to stay light (or `deSolve`, compiled) | P3 | Medium |
| **B6 Raw-data analysis workbench** | Upload CSV → descriptive "Table 1", crude/adjusted estimates, Kaplan-Meier | Many new deps; data-privacy policy needed | **Deferred (D1: summary-data calculators only).** Kept here; revisit after B1 ships | High |
| **B7 Evidence synthesis** | Pooling from study summaries (fixed/random effects), forest plots | `metafor` (heavy) | P3 | Medium |
| **B8 Teaching mode** | Interactive power curves, sampling-distribution and CI-coverage demos | Base R + plotting | Rides on P1 item 10 | Low–Medium |

**Cross-cutting features** (benefit every workbench): common result object and export
(P1), bookmarkable/shareable URLs (Shiny bookmarking), dark mode
(`bslib::input_dark_mode()`), accessibility (WCAG AA). English only (D5) — no translation layer planned.

**Navigation redesign -- done (14 Oct 2026, first part of milestone M2).** The navbar is
now a top level of *workbenches* with a grouped sidebar inside each, instead of one
dropdown per group (bslib dropdowns cannot nest, and 15 no longer fit). Built: **Home,
Plan: Sample Size** (the 49 calculators, 14 group headers) and **Analyze** (the two
summary-data tools). The navbar title is now "epidemiologicasuite" (D3).
- `R/registry.R`: `module_workbenches` (id, title, `nav_id`, groups) replaces
  `module_groups`; `module_workbench_of()` and `jump_to_module()` open a module from
  anywhere by selecting its workbench and then the module. `R/run_app.R` builds the UI with
  `bslib::navset_pill_list()` (a bare string in `...` becomes a group header) plus a small
  stylesheet: sticky, scrollable list, small-caps headers, and a height cap on phones.
- The Home hub's Browse buttons and the wizard use `jump_to_module()`; the UI smoke tests
  open modules the way a user does (workbench first, then module) and check both
  `input$main_nav` and the workbench's own input. New consistency tests: every module is in
  exactly one group of one workbench, ids/titles do not collide, every built catalog target
  resolves to a workbench.
- Found while building it: a capped-height Bootstrap 5 `.nav` **wraps into columns** unless
  `flex-direction: column; flex-wrap: nowrap` is set -- the first screenshot showed items
  spilling into a second column.
- **Not done:** Collect / Report / Learn workbenches do not exist yet (nothing to put in them);
  the sidebar has no search box (the Home hub's Browse/wizard remain the way to find a
  calculator by purpose); the Home page heading still reads "Comprehensive Sample Size
  Calculator"; bookmarkable URLs, dark mode and the accessibility pass listed under
  cross-cutting features are untouched. Checked in desktop-width screenshots (Plan, Analyze, a module deep in the list)
  and at phone width (390 px): the navbar collapses, the sidebar stacks above the calculator and
  scrolls inside its 40vh cap. Full suite incl. browser tests: 661 tests, 3055 assertions, 0
  failures/errors/warnings, 78 skips (27 Monte Carlo + 51 every-design UI tests).

---

## 6. Track C — making it an R package

The codebase is already close: computation is in pure functions with roxygen-style
comments, content is data, and tests use `testthat`.

**C1 — installable package (P1).**
- Add `DESCRIPTION` (Imports = the 19 runtime packages), generate `NAMESPACE` with
  roxygen2.
- Flatten `R/` (required by R packages). File names are already prefixed
  (`calc_`, `content_`, `mod_`, `home_`/`design_`), so this is mechanical.
- (done, item 11) Replace `global.R`'s `source()` loop and `pacman::p_load()` with the
  package namespace; expose `run_app()` and `epidemiologicasuite_app()`. Root `app.R` is a
  development shim (`pkgload::load_all()`); hosted deployment is untested (item 18, D1).
- Rewrite test headers to use the package (drop the `source()` lines).
- Install path: `remotes::install_github("SpaRroW410/Sample_size_all")`.

**C2 — public API (P2).** Decide exported names (e.g. a consistent `ss_*()` family),
adopt the common result class (P1 item 8), write one vignette per family, publish a
**pkgdown** site.

**C3 — split for CRAN (P3).** A computation-only core package (no Shiny, CRAN-friendly)
plus an app package that depends on it. CRAN needs: Monte Carlo tests behind
`skip_on_cran()`, fast examples, ASCII-only code (escape `²` etc.), the GPL-3
licence declared (D2), and ≤ 20 Imports (Phase 8 helps).

**C4 — release channels (P3).** GitHub → **r-universe** (automatic binaries,
including WebAssembly builds for webR, which Track D3 needs) → CRAN.

**Name.** `epidemiologicasuite` (D3, revised 14 Oct 2026). The package was first
called `sample2result`; the owner then asked for `epidemiologica_suite`, but an R
package name may contain only letters, digits and dots (no underscore), so it is
spelled `epidemiologicasuite` (the dotted `epidemiologica.suite` would also be
legal but reads like an S3 method name). Availability, checked 14 Oct 2026: no
`github.com/cran/epidemiologicasuite` repository exists (the CRAN mirror answers
for real packages such as `pwr` and not for this name), and a web search found no
package, repository or page with that name or the dotted/underscore variants. CRAN,
Bioconductor and the CRAN index were not directly reachable from the sandbox, so
confirm with `available::available("epidemiologicasuite")` before the first public
release. The GitHub repository is still `Sample_size_all` (renaming it is an owner
action and changes the install path); the navbar title changes with the suite
expansion (D3).

---

## 7. Track D — deployment and distribution

| Option | How | Offline? | Needs a server? | Feasibility today | Main blockers / notes |
|---|---|---|---|---|---|
| **D1 Hosted web** | shinyapps.io, Posit Connect Cloud, own VPS with Shiny Server, or **Docker** (`rocker/shiny`) for institutional servers / ShinyProxy | No | Yes | **Feasible now** | Needs F9 (async) before many concurrent users; free tiers have hour limits |
| **D2 R package** | `install_github()` / r-universe / CRAN, then `run_app()` | Yes (local R) | No | After C1 | Users need R installed — fine for faculty/researchers |
| **D3 Shinylive (WebAssembly) static site** | `shinylive::export()` → GitHub Pages; runs entirely in the browser | Yes, after first load | **No** | **Conditional — needs a spike** | Every runtime package needs a webR binary (check each of the 19 on `repo.r-wasm.org`); compiled packages (`lme4`, `BayesFactor`, `Hmisc`, `mvtnorm`, …) are the risk; first load downloads tens of MB. Mitigate with Phase 8 and lazy per-module loading. **Spike run 16 Oct 2026 (item 15): 165 of 168 packages exist for webR; 177 of 185 designs work; first load 170+ MB; see item 15 for the decision.** |
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
| CI | GitHub Actions: fast suite on push, slow suite weekly/manual | Done |
| Reproducible environment | `renv.lock`, restored by CI (the sandbox hook can't reach CRAN) | Done |
| Test split | Env-var-gated Monte Carlo tests; default run < 2 min | Done |
| Consistency tests | Every wizard terminal and module design resolves to a built catalog entry | Done |
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

## 10. Owner decisions

Recorded 28 September 2026.

| # | Question | Decision | Consequences |
|---|---|---|---|
| D1 | Suite scope: summary-data calculators only, or also a raw-data analysis workbench? | **Summary-data calculators only, for now** | B1–B5 and B7 (from summaries) stay in scope; B6 and the line-list parts of B4 are deferred, not dropped |
| D2 | Licence: keep MIT or relicense to GPL-3? | **GPL-3** | `LICENSE` replaced with the GPL-3 text; resolves F8. The package `DESCRIPTION` will say `License: GPL-3` |
| D3 | Suite and package name | **`epidemiologicasuite`** (was `sample2result`; `epidemiologica_suite` is not a legal package name) | Used for the package (C1), the app title and the suite; single package until CRAN, then consider a core + app split (C3) |
| D4 | Primary distribution target: hosted web, or offline/APK first? | **Offline / APK later** | Hosted web + R package first (D1, D2); the Shinylive spike (D3) and APK (D5a) stay at P2/P3 |
| D5 | Languages | **English only** | No translation layer; F11 narrows to accessibility and mobile layout |
| D6 | When to reopen the two paused items (A.2) | *Open* | Suggested: once paper access is available |

## 11. Suggested milestones

| Milestone | Contents | Exit criterion |
|---|---|---|
| **M0 Hygiene** | P0 items 1–6 | Wizard and catalog tests pass (done); fast suite < 2 min (done, ~1 min); CI green |
| **M1 Foundations** | Calculate button + async, result object, export + justification text, power curves, `epidemiologicasuite` package skeleton | `run_app()` works from an installed package; results downloadable |
| **M2 Analyze v1** | B1 calculators + navigation redesign | Reproduces OpenEpi/`epiR` worked examples; wizard covers analysis tasks |
| **M3 Portability** | Shinylive spike, Phase 8 tier 1, pkgdown site | Go/no-go on offline/APK, with evidence |
| **M4 Planning & field tools** | B2, B3 | Randomization lists reproducible by seed |
| **M5 Distribution** | Docker + hosted, PWA, APK (TWA), r-universe | Installable on Android; installable from r-universe |
| **M6 Surveillance, modelling, CRAN** | B4, B5, C3 | CRAN check clean |
| **Ongoing** | Track A items whenever their unblock condition is met | — |

### Hosting on GitHub Pages (decision of 21 Oct 2026)
Posit Connect / shinyapps.io are not the plan (the owner reports their token system is being discontinued; not verified here). The app is
published on GitHub Pages as a Shinylive (WebAssembly) build under `/app/`, next to the pkgdown documentation; the installed R package
contains everything, including the 8-9 designs that need compiled packages with no WebAssembly build (TOST means, Fisher, Boschloo),
which show a message with the install command in the browser. One codebase: `tools/pages/make_app.R` assembles the browser app from
`R/`, and the `app` job of the `docs` workflow requires that it boots in headless Chrome (UI up, a calculator renders, no source file
fails) before it is published. First passing CI run: UI visible after 77 s, first calculation after 12 s, 64 MB transferred. Bug found by
that check on its first run: Shinylive's package scan read `library(p, character.only = TRUE)` as a package called "p", so `bslib` was
never attached; fixed by attaching by name. Not yet done: publishing (needs the owner steps in `docs/to_do_later.md`), a phone test, and
trimming the download.


### Start-up time, the Home wizard and a UI audit (27 Oct 2026)
- **Lazy loading of the calculators** (`R/lazy_modules.R`, `epidemiologicasuite_app(lazy = TRUE)`): the page had about 65 modules, 1,500
  inputs and 5.4 MB of HTML before the first screen. Now only four basic calculators (Proportions, Means, Correlation, 2x2
  analysis) are built at start; the sidebars still list every calculator, the others are inserted when opened (or when a Home
  button or the wizard jumps to them) and one by one in the background after the first screen. An indicator beside the
  calculator lists shows what is ready and what is left (animated bar "20 of 61 ready", faint entries with a pulsing dot, a
  spinner on the next one, a tick when one becomes ready). **Measured locally** (R process + headless Chrome to a usable screen): 30 s
  before, 9 s after; DOM 5.4 MB -> 0.7 MB, 1,483 -> 101 inputs. **In the browser (WebAssembly) build on the CI runner:** UI visible after 27 s instead of 77 s, first calculation after 5.4 s instead of 12 s
  (the `app` job of the `docs` workflow prints these on every push; not measured on a phone). The package downloads (about 63 MB) are unchanged by this.
- **A bug the UI tests found in my first version:** a lazily loaded calculator's server started before the browser had bound its
  inputs, so renders that test `input$design` failed with "argument is of length zero" and flashed an error. Fixed by starting a
  module's server only after the browser reports the inserted UI as bound (`lazy_bound`); a UI test now fails on any such R error.
- **Home layout:** the helper card was a fill item, so it was as tall as the window with its content scrolling in a small
  window, and the free-text box was a 300 px, 2-row box that cut its placeholder. The card now grows with its content and the box
  is full width. UI tests check both.
- **Wizard tree:** after "selected on exposure" a cohort now asks for its outcome (risk -> relative risk, a measurement -> difference
  in means, rate per person-time -> rate ratio, time to event -> survival, ordinal); after "selected on outcome" a case-control
  study asks whether the exposure is yes/no (odds ratio) or a measurement (difference in mean levels: independent, paired when
  individually matched, or frequency-matched). Before, both went straight to relative risk / odds ratio and the cohort calculator
  note itself said to look in the Means module. A **Back** button was added.
- **Free-text rules:** new rules for trial unit and intent, cohort outcome, case-control exposure, nested case-control, case-cohort,
  case-crossover, SCCS, ecological, correlation / regression, meta-analysis, "other" designs, diagnostic and agreement
  sub-questions; fixes for "comparing" (the old pattern only matched "compare"), "case control" without a hyphen,
  and "intracluster correlation" (it was sent to the correlation calculators). The parser still stops at a question when a
  description does not settle it. A battery of 101 plain-language descriptions with their expected end node is in
  `tests/testthat/test-design_wizard_battery.R`; every complete click path through the wizard (636) is checked to end on a terminal
  with a valid catalog entry. Known limits: the parser is keywords, so unusual wording falls back to a question; "interrupted time
  series" has no calculator; the individual-vs-cluster assumption for a plain "trial" is shown in the trail as Medium confidence.
- **UI audit** (`tools/ui-audit/audit.R`, run by hand): every calculator and Home at 1366 px and 390 px: no horizontal scroll, no
  content wider than the window, no small scroll windows, no clipped inputs, no output or R errors, no console errors; the detector was
  checked against an injected fault. It covers layout and errors, not whether each result is numerically right (the unit tests do that).


### Accessibility and dark mode (28 Oct 2026, item 22 first pass)

`tools/ui-audit/a11y.R` opens every calculator (65) and Home in headless Chrome at 1366 px and 390 px and runs axe-core 4.10
(WCAG 2.0 / 2.1 level A and AA rules) on the page; `A11Y_DARK=true` repeats it in dark mode. First scan (before any fix): five rule
violations on nearly every page. What was wrong and what was done:

| Finding (axe rule) | Pages | Fix |
|---|---|---|
| `<html>` had no `lang` (html-has-lang) | all | `page_navbar(lang = "en")` |
| Text contrast below 4.5:1: litera's blue links/buttons (3.7:1), grey outline buttons (2.1:1), white on teal / amber alerts (3.0 / 2.0), red error text, and the dimmed "still loading" sidebar links | all | darker theme colours (primary, secondary, info, warning, danger); loading links are no longer dimmed (italic + the dot and bar instead) |
| `<ul>` containing `<li role="status">` (list) | all | the live region moved inside the `<li>` |
| Selectize drop-downs and the table-style input grids (2x2 tables, stratum rows, attrition stages) had no accessible name (label) | 26 | `R/accessibility.R`: selectize boxes are named from their label; grid inputs are named from their row label + column heading (e.g. "Exposed Outcome +"), composed from what is on screen |
| Scrolling text and result areas not reachable by keyboard (scrollable-region-focusable) | 61 | the same script gives them `tabindex=0`, a region role and a name |

New: a light / dark switch in the navbar (bslib `input_dark_mode`, starts from the operating-system setting); dark-mode colours for
the navbar and the outline buttons / error / warning text. The plots are base-R images with a white background and stay white in
dark mode.

Result after the fixes: **0 violations** in light mode on all 66 pages at both sizes (full scan); the full dark-mode scan found one more (the outline-primary button of Exact Tests), fixed and re-checked on that page, Home and Proportions rather than by a third full dark scan. Limits, stated plainly: axe finds what a machine can
(names, roles, contrast, structure); it cannot judge reading order, whether the generated names make sense to a screen-reader user,
focus order, or colour-only meaning in the plots. The grid-input names are built by a script from the page structure, so a new grid
layout needs checking. Not yet done: a manual keyboard and screen-reader walk-through, alt text / table summaries for the plots,
dark-mode versions of the plots, and text-resize and reduced-motion checks.

### Dependency reduction, stage 2: the easy and moderate packages (28 Oct 2026)
Seven more runtime packages were replaced by closed forms written out in the app and tested against the real package: **pwr**,
**powerMediation**, **pmsampsize**, **pROC** (easy) and **presize**, **powerSurvEpi**, **TrialSize** (moderate). The packages moved from
Imports to Suggests as verification oracles (`skip_if_not_installed()`); only `kappaSize` was added to Imports (see below). Files:
`R/calc_closed_forms_pwr.R` (Cohen's t / ANOVA / f2 / correlation / chi-square / proportion power, ES.h / ES.w, logistic and Poisson
regression sizes, ROC sizes), `R/calc_closed_forms_pm.R` (Riley et al. criteria), `R/calc_closed_forms_ts.R` (TrialSize formulas and
the powerSurvEpi survival and matched case-control formulas), `R/calc_closed_forms_presize.R` (precision-based sizes), with
`test-calc_closed_forms_{pwr,pm,ts,presize}.R` comparing each function with the package over grids of inputs (about 2,700 expectations;
sample sizes identical, power functions and intervals to 1e-10 or better).
- **What it buys, honestly.** The install closure goes from 77 to 68 packages and from 110 MB to 105 MB: **9 packages** (the seven plus
  `plyr` and `pracma`) and about **5 MB** of 110. Most of the weight is `shiny`, `bslib`, `lme4` and their dependencies, which stay.
  The gain is fewer packages to download in the browser build, fewer things that can fail to install or change their interface (the
  epiR 3.0 problem, F13), and every formula now traceable in the app's own source.
- **Two bugs in the packages, found while transcribing, and corrected (not copied):**
  1. `pmsampsize` 1.1.3 (latest on CRAN), continuous outcome, criterion 4 (precision of the intercept): the loop uses `+qt(0.025, df)`
     (negative), so when this criterion binds the interval limits swap, the ratio drops below 1 and the loop stops after one step.
     Example: parameters 2, intercept 1.9, sd 0.6, R2 0.2, mmoe 1.02 gives n = 237 with a "lower" limit 1.97 above the "upper" 1.83;
     the smallest n that really meets the criterion is about 765. The app had been reproducing this. Now the criterion is computed as
     defined and tested against its definition; when it does not bind, results equal the package.
  2. `presize::prec_pos_lr()` / `prec_neg_lr()` accept `conf.level` but do not pass it to `prec_lr()`, so the likelihood-ratio design
     always used 95%. Now the level is used (tested against `prec_lr()`); results change for any level other than 95%.
- **Not replaced: `kappaSize`.** Cohen's kappa sample size needs kappaSize's cell-probability tables for 2-6 raters and 2-5 categories
  (eight functions of 240-390 lines each); the thin `presize::prec_kappa()` wrapper around it is written out and `kappaSize` is now a
  direct import. Re-deriving the tables is possible but large and was not done.
- **Verified how:** each function against its package (identical sample sizes), plus the independent definition for the corrected
  criterion. The papers behind the formulas were not read (citations are those in the package documentation and the module content
  files); the Reference tab of each calculator now says "closed form written out in the app, equal to <package function> (compared
  with the package in the tests; the package is not a dependency)". `renv.lock` still lists the removed packages (re-snapshot pending).


### Three versions: browser build, phone/server version, R package (28 Oct 2026)
The owner's phones (Safari and Brave on iOS) show a spinner that never ends on the browser build. It starts in iPhone-sized Chromium, in
Linux WebKit and under a 4x CPU / 10 Mbit/s throttle (UI after 128 s), so the cause on the real devices could not be reproduced here; the
runtime alone needs about 775 MB (an empty Shiny page) and the app about 1.1 GB, above what many phones allow a tab. Decision: instead
of a cut-down "lite" webR build, keep the browser build for desktops and run the same package as an ordinary Shiny server on **Posit
Connect Cloud** for phones, redirecting phones automatically. `docs/hosting.md` describes the three versions and the owner's steps.
- `tools/connect/` + `.github/workflows/connect-bundle.yml`: builds the deployment bundle (`app.R`, `R/`, `manifest.json` with 68
  packages, all CRAN) on every change to the code, starts it as a plain Shiny app in headless Chrome and checks a calculation, and on
  `main` publishes it to the branch `connect` for Connect Cloud to deploy from. No Posit account or token is needed by CI.
- `tools/pages/mobile_redirect.html` + `inject_status.py` + `mobile_url.txt`: phones and tablets are sent to the Connect address once it is
  set (empty now: no redirect); `?full=1` keeps the browser build, `?mobile=1` undoes it. Tested in Chromium device emulation
  (iPhone, Pixel, iPad with the desktop-site user agent, desktop, `?full=1`, remembered choice, `?mobile=1`).
- **Not verified:** the Connect Cloud deployment itself (needs the owner's account), the free-plan limits, and any real phone. Posit
  announced that shinyapps.io takes no new apps after the end of 2026 and migrates accounts to Connect Cloud from January 2027
  (Posit's migration page; sources disagree on some dates), which is why Connect Cloud, not shinyapps.io, is the target.
