# Software Design Document
## Comprehensive Sample Size Calculator for Community Medicine / Epidemiology

| | |
|---|---|
| **Status** | Draft v0.1 |
| **Date** | 18 August 2026 |
| **Author** | Mukul |
| **Type** | R Shiny web application |

---

## 1. Purpose & Scope

### 1.1 Purpose
Define the architecture, module design, content model, and roadmap for an R Shiny
application that provides sample size and power calculations relevant to community
medicine, epidemiology, and clinical research — with an explained-formula help
system, original-source citations, and a post-hoc power module — so the codebase
stays maintainable as calculators are added over time by one primary developer,
with possible future contributors.

### 1.2 In scope
- Sample size / power calculators across common epidemiological and clinical
  study designs (see §7 catalog)
- Per-calculator help content: formula, plain-language explanation, worked example
- Per-calculator citation to the original methodological source
- Post-hoc / achieved power module, appropriately caveated
- Single-user, stateless, browser-based tool (no accounts, no saved sessions in v1)

### 1.3 Out of scope (v1)
- User accounts, saved calculation history, PDF report export
- Full study design consulting (randomization, blinding, analysis plans)
- Meta-analysis / systematic review sample size pooling
- Mobile-native app (responsive web only)

---

## 2. Background

Existing tools (OpenEpi, PS: Power and Sample Size, Epi Info StatCalc, and various
single-purpose R/Shiny apps such as `presize`, `rashnu`) each cover part of this
space, but none combine broad calculator coverage with an in-app, citation-backed
explanation of each formula and a properly-framed post-hoc power module. This
project's value is that combination, plus long-term extensibility — not novel
statistical methodology.

---

## 3. Goals & Success Criteria

| Goal | Success criterion |
|---|---|
| Correctness | Every calculator's output matches published worked examples and/or cross-checks against OpenEpi/PS within rounding tolerance |
| Extensibility | A new calculator can be added by creating one new module file, without touching existing modules |
| Transparency | Every result is traceable to a stated formula and a cited original source |
| Usability | A student with no statistics background can get a correct result using in-app guidance alone |
| Maintainability | Codebase understandable and modifiable by one part-time developer over months/years |

---

## 4. System Architecture

### 4.1 High-level layers

```
┌─────────────────────────────────────────────┐
│  UI Shell (bslib::page_navbar)               │
│  - Home / About                              │
│  - One nav tab per calculator family         │
│  - Post-hoc Power tab                        │
└───────────────┬───────────────────────────────┘
                │
┌───────────────▼───────────────────────────────┐
│  Calculator Modules (mod_*.R)                 │
│  Each = {UI fn, server fn, metadata}          │
│  Sub-tabs: Calculate | Formula/Help | Reference│
└───────────────┬───────────────────────────────┘
                │
┌───────────────▼───────────────────────────────┐
│  Computation Layer                            │
│  Thin wrappers around pwr / presize / epiR /  │
│  WebPower / pwrss / TrialSize                 │
└───────────────┬───────────────────────────────┘
                │
┌───────────────▼───────────────────────────────┐
│  Content Layer                                │
│  Per-module metadata: formula (LaTeX string), │
│  explanation text, citation, package/function │
└─────────────────────────────────────────────┘
```

### 4.2 Design principles
- **Modules are self-contained.** A module owns its inputs, its calculation call,
  and its help/reference content. No shared mutable state between modules.
- **Computation is separated from presentation.** Each module's server function
  calls a plain R function (testable outside Shiny) that wraps the underlying
  package call — this makes unit testing possible without spinning up the app.
- **Content is data, not hardcoded UI.** Formula text, explanation, and citation
  live in a metadata list/YAML per module, rendered generically — adding a
  calculator means adding data + one calculation function, not new UI code.

---

## 5. Technology Stack

| Layer | Choice | Notes |
|---|---|---|
| App framework | R Shiny | matches existing R fluency |
| UI theme/layout | `bslib::page_navbar()` | modern Bootstrap 5 theming, tabs |
| Formula rendering | MathJax via `withMathJax()` | built into Shiny |
| Modularity | Shiny modules (`NS()`, `moduleServer()`) | standard pattern |
| Stats backends | `pwr`, `presize`, `epiR`, `WebPower`, `pwrss`, `TrialSize` | wrap, don't reimplement |
| Testing | `testthat` | unit tests on computation functions |
| Version control | Git / GitHub | |
| Deployment (v1) | shinyapps.io free tier | |
| Deployment (future option) | Shinylive (WebAssembly, static hosting) | flagged for later; see §11 |

---

## 6. Repository Structure

```
sample-size-app/
├── app.R                      # entry point: builds navbar, wires modules
├── global.R                   # library() calls, source() of R/ files
├── R/
│   ├── modules/
│   │   ├── mod_proportion.R       # UI + server + metadata
│   │   ├── mod_means.R
│   │   ├── mod_case_control.R
│   │   ├── mod_cohort.R
│   │   ├── mod_diagnostic.R
│   │   ├── mod_correlation.R
│   │   ├── mod_precision.R
│   │   └── mod_posthoc_power.R
│   ├── calc/                      # pure calculation functions (testable, no Shiny)
│   │   ├── calc_proportion.R
│   │   ├── calc_means.R
│   │   └── ...
│   └── content/                   # per-module metadata: formula, text, citation
│       ├── content_proportion.R
│       └── ...
├── tests/
│   └── testthat/
│       ├── test-calc_proportion.R
│       └── ...
├── www/                        # any custom CSS/JS, logo
├── docs/
│   ├── project-brief.md
│   └── SDD.md                  # this document
└── README.md
```

---

## 7. Functional Design — Calculator Catalog

The full, detailed calculator backlog — ~90 scenarios across both a study-design
view and a statistical-test view (mirroring and extending G*Power's catalog) —
lives in two living checklist documents, not in this table:

- **[`checklist_by_design.md`](checklist_by_design.md)** — organized the way a
  medical researcher thinks ("I'm doing a case-control study"): 17 sections
  from descriptive/estimation studies through repeated-measures/longitudinal
  designs, each item tagged **[CORE]** (v1) or **[ADV]** (later), with typical
  inputs, the suggested R package/function, and the original citation.
- **[`checklist_by_test.md`](checklist_by_test.md)** — the same catalog
  organized by statistical test family (t / z / F / χ² / Exact, plus
  non-parametric, survival, agreement, equivalence, multilevel, Bayesian, and
  simulation-based methods), explicitly cross-referenced against G*Power's own
  test families and analysis types (Faul et al. 2007, 2009).

Every calculator should be reachable from *both* files (a researcher lands via
design, a statistician via test) — the same Shiny module serves both entry
points, and both files' checkboxes are ticked with a `*(implemented: ...)*`
note as each module goes live, so either file alone shows current build
status. Both files also carry a shared staged build plan (Stage 1 CORE
release through Stage 4 niche/simulation, plus Stage 1.5 and Stage 5 for the
design-identification wizard's two halves — see §7.1) and a set of caveats (version-
dependent vendor procedure counts, ARE-based non-parametric power, bio-
equivalence input conventions, packages with no confirmed CRAN presence,
etc.) — see those files rather than duplicating them here.

The table below is now just a snapshot of what's *actually live*, kept in
sync with the two checklists above (do not treat it as the source of truth
for what to build next):

| Family | Designs covered | Backend package/function | Status |
|---|---|---|---|
| Proportions | Precision-based (Cochran, +FPC); vs. known value; two independent; Bonferroni-adjusted post-hoc pairwise | closed-form (Cochran); `pwr::pwr.p.test`, `pwr::pwr.2p.test`, `TrialSize::OneWayANOVA.PairwiseComparison()` | Live |
| Means | Precision-based; one-sample, two-sample (equal + unequal n), two-sample unequal variances (Welch), paired, one-way ANOVA (3+ groups), planned linear contrast, Bonferroni-adjusted post-hoc pairwise | `epiR::epi.sssimpleestc()`; `pwr::pwr.t.test`, `pwr::pwr.t2n.test`, `pwr::pwr.anova.test`, closed-form normal approximation (Julious 2004) for Welch, `TrialSize::Dose.Response.Linear()`, `TrialSize::OneWayANOVA.pairwise()` | Live |
| Diagnostic accuracy | Precision-based (Buderer); vs. reference value; two tests, unpaired/paired; PPV/NPV; likelihood ratios (LR+/LR-); diagnostic odds ratio | closed-form (Buderer; Casagrande-Pike; Connor; Altman & Bland), all + Yates' correction; `presize::prec_pos_lr()`/`prec_neg_lr()` (Simel et al 1991); DOR reuses the two-independent-tests engine | Live |
| Agreement / reliability | Cohen's kappa; ICC; Cronbach's alpha; Bland-Altman LoA; Lin's CCC | `presize::prec_kappa()` (→ `kappaSize`); `presize::prec_icc()` (Bonett 2002); `presize::prec_cronb()` (Bonett & Wright 2015); `presize::prec_lim_agree()` (Bland & Altman 1986); closed-form (Lin 1989/2000, formula as used internally by `epiR::epi.ccc()`) | Live |
| Case-control | Unmatched; matched (1:1 or 1:m); nested (binary/continuous exposure); case-cohort | `epiR::epi.sscc()`; `powerSurvEpi::powerConLogistic.bin()`/`.con()`; closed-form (Cai & Zeng 2004) | Live |
| Cohort / RR | Cohort, cross-sectional, relative risk | `epiR::epi.sscohortc()` | Live |
| Correlation | Pearson correlation; comparing two independent correlations; comparing two dependent (overlapping) correlations; point-biserial correlation; simple regression slope; partial correlation; Spearman rank correlation | `pwr::pwr.r.test()`; closed-form (Cohen 1988); closed-form (Steiger 1980); `pwr::pwr.t.test()` via r-to-d conversion; `pwr::pwr.r.test()` via slope-to-r identity; `pwr::pwr.r.test()` + k covariates; `pwr::pwr.r.test()` inflated by 9/pi^2 ARE (Hotelling & Pabst 1936; Fieller, Hartley & Pearson 1957) | Live |
| Chi-square tests | Goodness of fit; test of independence (R×C); McNemar's (paired proportions); Mantel-Haenszel (stratified proportions); Cochran-Armitage trend (dose-response); Cochran's Q (k >= 3 paired binary measurements) | `pwr::pwr.chisq.test()` (`ES.w1`/`ES.w2`); `TrialSize::McNemar.Test()`; `TrialSize::Propensity.Score.strata()`/`.nostrata()`; `TrialSize::Cochran.Armitage.Trend()`; direct Monte Carlo simulation of `rstatix::cochran_qtest()` | Live |
| Pilot / feasibility | Flat 12/arm rule-of-thumb; interactive CI-for-SD precision | rule-of-thumb (Julious 2005); closed-form chi-square CI theory | Live |
| Simon two-stage | Phase II single-arm (minimax + optimal designs) | `clinfun::ph2simon()` | Live |
| Equivalence (TOST) | Two one-sided tests, means, proportions, PK bioequivalence crossover (2x2, 2x2x4, 2x3x3), and bioequivalence crossover with expected power/assurance (CV uncertainty) | `PowerTOST::sampleN.TOST(logscale=FALSE/TRUE)`; `epiR::epi.ssequb()`; `PowerTOST::expsampleN.TOST(prior.type="CV")` | Live |
| Log-rank / survival | Two-arm time-to-event, cumulative event probabilities; Cox PH regression (binary or continuous covariate); stratified log-rank (exponential survival); accrual/follow-up with drop-in/non-adherence; weighted log-rank under non-proportional hazards | `powerSurvEpi::ssizeCT()`; `ssizeEpi.default()`; `ssizeEpiCont.default()`; `ssize.stratify()` (Palta & Amini 1985); `Hmisc::cpower()` (Peterson & George 1993; Lachin & Foulkes 1986); direct Monte Carlo simulation of `survival::survdiff(rho=...)` (Fleming-Harrington G^rho family; Harrington & Fleming 1982) | Live |
| Incidence Rate | Precision-based, events + person-time; comparison of two rates; Poisson regression with a continuous predictor; comparison of two negative binomial (over-dispersed) rates | `presize::prec_rate()`; closed-form (Demidenko 2007); `powerMediation::sizePoisson()` (Signorini 1991); closed-form reimplementation of `MKpower::power.nb.test()` (Zhu & Lakkis 2014) | Live |
| Exact Tests | Binomial test (single proportion); Fisher's exact (two proportions); Boschloo's exact (unconditional, two proportions); exact Poisson (single rate); sign test | `stats::binom.test()` search; `Exact::power.exact.test()` search (methods "fisher"/"boschloo"); `stats::poisson.test()` search; `stats::binom.test()` search (p0 = 0.5) | Live |
| Multiple Regression | R-squared deviation from zero; R-squared increase (hierarchical) | `pwr::pwr.f2.test()` | Live |
| Non-Inferiority | Means, proportions, odds ratio, hazard ratio (Cox PH) | `epiR::epi.ssninfc()`, `epi.ssninfb()`; `TrialSize::RelativeRisk.NIS()`, `Cox.NIS()` | Live |
| Rule of Three | Upper bound on unseen event rate; n to detect >= 1 event; detect >= 1 case with an imperfect test in a finite population (single or two-test series/parallel) | closed-form (Hanley & Lippman-Hand 1983); `epiR::epi.ssdetect()` | Live |
| Group Sequential Design | Interim-monitoring trial design (continuous, binary, or survival outcome) with Pocock-to-O'Brien-Fleming efficacy/futility boundaries | `clinfun::gsdesign.normal()`/`.binomial()`/`.survival()` | Live |
| Prediction Model | Model development (binary, continuous, survival); external validation (binary) | `pmsampsize::pmsampsize()` (Riley et al. 2019/2020/2021); external validation reimplements `pmvalsampsize` (package not installed, source verified) (Riley et al. 2021) | Live |
| ROC / AUC | Single ROC AUC vs. chance (0.5); compare two correlated (paired) AUCs | `pROC::power.roc.test()` (Obuchowski et al. 2004; Obuchowski & McClish 1997) | Live |
| Cluster / design effect | Design-effect inflation of an existing base sample size; cluster survey precision (WHO EPI-style, proportion) | closed-form (Kish 1965); `epiR::epi.ssclus2estb()` | Live |
| Stratified Sampling | Total size + per-stratum allocation (proportional/Neyman) | closed-form (Cochran 1977; Kauermann & Kuechenhoff 2011) | Live |
| LQAS | Lot Quality Assurance Sampling (rapid area classification) | closed-form binomial operating-characteristic search (Robertson & Valadez 2006) | Live |
| Resource Equation (Animal Studies) | Recommend/check sample size via error degrees of freedom (E=N-T) | closed-form arithmetic (Mead 1988; Charan & Kantharia 2013) | Live |
| Subgroup / Interaction Testing | Inflate a main-effect sample size for a treatment-by-subgroup interaction test ("4x rule") | closed-form arithmetic (4/effect_ratio^2), Brookes et al. 2004 | Live |
| Qualitative Sample Size Guidance | Reference guidance for qualitative interview studies (saturation, information power, purposive/theoretical sampling) -- no formula, no numeric output | Guest, Bunce & Johnson 2006; Malterud, Siersma & Guassora 2016; Glaser & Strauss 1967; Patton 2002/2015 | Live |
| Monte Carlo GLMM (Cluster-Randomized Trial) | Two-arm cluster-randomized trial, continuous (LMM) or binary (GLMM) outcome, analyzed via the actual mixed-model likelihood-ratio test -- no closed-form formula exists, so directly simulated via `lme4::lmer()`/`glmer()` | Bolker et al. 2009; Judd, Westfall & Kenny 2017 | Live |
| Variance Tests | Single-variance test vs. a reference SD (chi-squared); two-variance test comparing two groups (F test) | closed-form (chi-squared/F distribution, `uniroot()` solve) | Live |
| Crossover Trial (2x2) | Continuous outcome, test for a difference (not equivalence) | `TrialSize::TwoSampleCrossOver.Equality()` (Chow, Shao & Wang 2003) | Live |
| Factorial ANOVA / ANCOVA | Main effects, interactions, ANCOVA group effects (general F-test) | `pwr::pwr.f2.test()` (Cohen 1988) | Live |
| Logistic Regression | Simple logistic regression, binary or continuous predictor; ordinal (proportional odds) regression, two groups; multiple-regression covariate-adjusted (variance-inflation) binary/continuous designs | `powerMediation::SSizeLogisticBin()`/`SSizeLogisticCon()` (Hsieh et al. 1998); `Hmisc::posamsize()` (Whitehead 1993); closed-form 1/(1-R²) inflation (Hsieh, Bloch & Larsen 1998) | Live |
| Self-Controlled Case Series | Cases-only design, risk-period vs. own-time comparison, optional age effects | closed-form (Musonda, Farrington & Whitaker 2006) | Live |
| RM-ANOVA / Mixed ANOVA | Between-subjects, within-subjects, and group x time interaction effects | closed-form (Cohen 1988; `WebPower::wp.rmanova()` algorithm) | Live |
| Nonparametric Tests | Wilcoxon rank-sum, Wilcoxon signed-rank, Kendall's tau, Kruskal-Wallis, Jonckheere-Terpstra, Friedman, Kolmogorov-Smirnov (two-sample), Wald-Wolfowitz runs test (two-sample) | `TrialSize::Nonpara.Two.Sample()`/`Nonpara.One.Sample()`/`Nonpara.Independ()` (Chow, Shao & Wang 2003); `pwr::pwr.anova.test()` inflated by 3/pi ARE (Hodges & Lehmann 1956); Jonckheere-Terpstra reuses the Kendall's tau engine (asymptotic equivalence); Friedman reuses `calc_rm_anova()` inflated by (3/pi)*k/(k+1) ARE (Zimmerman & Zumbo 1993); Kolmogorov-Smirnov and runs test via direct Monte Carlo simulation of `stats::ks.test()`/`tseries::runs.test()` (no closed form exists for either) | Live |
| Ratio Estimation | Precision-based risk ratio, odds ratio, rate ratio | `presize::prec_riskratio()`/`prec_or()`/`prec_rateratio()` | Live |
| Multiplicity Adjustment | Bonferroni/Sidak-adjusted sample size for one-/two-sample proportion or mean tests, given m planned simultaneous comparisons; FDR (Benjamini-Hochberg)-controlled sample size for two independent means | closed-form correction wrapping this app's own `calc_proportion_1s()`/`_2s()`/`calc_means_1s()`/`_2s()`; FDR design via an independently-derived, Monte-Carlo-verified closed form wrapping `pwr::pwr.t.test()` (Benjamini & Hochberg 1995) | Live |
| MANOVA / Hotelling's T² | Two-group Hotelling's T-squared test (p jointly-tested continuous outcomes) | closed-form noncentral F (Rencher 2002; Vonesh & Schork 1986 framework) | Live |
| Bayesian Design Analysis | Prior-averaged power (assurance) for a two-arm proportions trial, log odds ratio, given a Normal or Uniform prior on the true effect; Bayes Factor Design Analysis for two-sample means | `Hmisc::gbayes2()` (Spiegelhalter & Freedman 1986); direct Monte Carlo simulation of `BayesFactor::ttestBF()` (Rouder et al. 2009; Schönbrodt & Wagenmakers 2018) | Live |
| Longitudinal / MMRM | Two-group difference in linear slope (rate of change) over repeated visits, via all 4 `lmmpower()` methods (Liu & Liang, Diggle, Ard & Edland, Hu/Mackey/Thomas); or a mixed model of repeated measures (MMRM) with dropout, AR(1) correlation | closed-form reimplementation of `longpower::liu.liang.linear.power()` (Liu & Liang 1997), `diggle.linear.power()` (Diggle et al 2002), `edland.linear.power()` (Ard & Edland 2011), `hu.mackey.thomas.linear.power()` (Hu, Mackey & Thomas 2021), `power.mmrm.ar1()` (Lu, Luo & Chen 2008) | Live |
| Competing Risks | Joint test of a cause-specific hazard and the any-cause hazard (Gray's-test setting) | closed-form root-finding (`uniroot()` + `mvtnorm::pmvnorm()`), reimplemented from `powerCompRisk::powerCompRisk()`'s own public source (package not installable from CRAN in this sandbox; source read from its GitHub CRAN mirror) per Yang, Fung & Li (2017) | Live |
| RMST Comparison | Two-arm restricted mean survival time comparison (superiority or non-inferiority) | Monte Carlo simulation reimplemented from `SSRMST::ssrmst()` + `survRM2::rmst2()`'s own public source (neither package installable from CRAN in this sandbox; both read from their GitHub CRAN mirrors), using only `survival::survfit()`, per Uno et al. (2014, 2015) | Live |
| Precision-based (generic) | CI-width driven (risk diff/ratio) | `presize`, `precisely` | Not started |
| MANOVA (global, k>2 groups) | Global & special effects for k > 2 groups | Vonesh & Schork (1986) closed-form; not yet wrapped | Not started |
| Post-hoc / achieved power | Given n and observed effect, compute achieved power | reuse each module's engine, solve for power | Not started |

Each row above is (or will be) exactly one `mod_*.R` + `calc_*.R` +
`content_*.R` file set, following the module contract in §8.

**Top navbar.** With 24 modules live, one flat top-level nav tab per
calculator became unworkably crowded (26 items: Home, the wizard, and 24
modules). `app.R` now groups modules into `bslib::nav_menu()` dropdowns via
`global.R`'s `module_groups` list, ordered to match
`checklist_by_design.md`'s own Part-1 section numbers (already simple ->
difficult): Descriptive & Estimation, Survey & Cross-Sectional,
Observational Studies, Diagnostic & Screening, Agreement & Reliability,
Clinical Trials, Survival Analysis, Prediction Models, Surveillance, and
General Statistical Tests (the handful of modules — Correlation,
Chi-Square, Multiple Regression, Factorial ANOVA/ANCOVA, Logistic
Regression, Exact Tests — with no single natural study-design home).
Total: Home + 10 dropdowns = 11 top-level items. This is a navigation-layer
change only; `nav_select()` still targets a module by its nav title exactly
as before, whether that `nav_panel` sits directly on the navbar or nested
in a dropdown (see §8's registry-wiring note and the `home_finder.R`/
`design_wizard.R` mechanism in §7.1).

### 7.1 "Which calculator?" — the study design identification wizard

A third way into the app, alongside the Home finder in §7 above: a
guided-questionnaire wizard (a tab inside the Home hub, "Which calculator?
(guided wizard)" — folded in during the navbar/Home reorg once the module
count made a separate top-level nav panel for it too crowded) that walks a
researcher through Stage 1–5 of
[`docs/design_identification_algorithm.md`](design_identification_algorithm.md)
— primary aim, allocation/directionality, outcome type, groups/dependence
structure — one question at a time, showing the reasoning trace as it goes,
and ending on either a jump button into a live module (reusing the Home
finders' `nav_select()` + `updateRadioButtons()` mechanism) or an honest
"not yet built" note naming the module/backend/citation the checklists
already call for. It never silently decides, and a "start over" control is
always present.

Implementation: `R/home/design_tree.R` (a flat node registry — question
nodes with `options`, terminal nodes with either a `catalog_key` into
`calculator_catalog` or a `would_use`/`citation` pair) and
`R/home/design_wizard.R` (the UI/server, structured the same
non-Shiny-module way as `home_finder.R`, for the same reason: it needs to
jump the top-level navbar from the root session). `design_wizard.R` exposes
a `design_wizard_body()` UI-fragment function (not a full page) plus its
existing `design_wizard_server()`; `R/home/home_hub.R` composes it alongside
`home_finder.R`'s dual-taxonomy browser and a formula/LaTeX helper into one
"Home" nav panel — see §7 above and the top-navbar note there for why (26
flat top-level tabs became unworkable once the module count reached 24).

This is only the guided-tree half of the source document (its Stages 1–5;
build-plan **Stage 1.5**, done). Its Stage 0 — free-text/PICO input parsing
(keyword heuristics and/or an LLM layer that pre-fills the wizard's answers
instead of clicking through every question) — is the other half, and is
deliberately deferred to build-plan **Stage 5**, after Stage 4, rather than
bundled in here: every branch that reaches a calculator this app hasn't
built yet degrades to an honest "not yet built" placeholder for now, and
free-text parsing is worth adding once most of those placeholders have
flipped to live modules, not before.

---

## 8. Module Contract

Every calculator module follows the same three-part contract so the pattern is
copy-paste-modify for new additions.

**Metadata (content layer)** — plain R list, one per module:
```r
proportion_content <- list(
  title = "Single Proportion vs. Known Value",
  formula_latex = "$$n = \\frac{Z_{\\alpha/2}^2 \\, p(1-p)}{d^2}$$",
  explanation = "Where p is the expected proportion, d is the precision...",
  worked_example = "...",
  citation = "Naing L, Winn T, Rusli BN. Practical issues in calculating
               the sample size for prevalence studies. Arch Orofac Sci. 2006.",
  backend = "pwr::pwr.p.test"
)
```

**Calculation function (pure R, no Shiny)**:
```r
calc_proportion_ss <- function(p, d, conf_level = 0.95) {
  # validates inputs, calls pwr::pwr.p.test or closed-form formula,
  # returns a list(n = ..., inputs_echo = ...)
}
```

**Module UI/server (Shiny)**:
```r
mod_proportion_ui  <- function(id) { ... tabsetPanel(Calculate, Formula, Reference) ... }
mod_proportion_server <- function(id) { moduleServer(id, function(input, output, session) {
  # reads inputs, calls calc_proportion_ss(), renders result + validation messages
}) }
```

`app.R` wires modules into the navbar by iterating a registry list — adding a
calculator to the nav does not require editing `app.R`'s structure, only
appending to `module_registry` and placing its id in the appropriate
`module_groups` entry (both in `global.R`; see §7's "Top navbar" note).

---

## 9. Help / Reference Content Design
- Formula rendered via `render_formula_block(module_content$formula_latex)`
  (`R/modules/mod_shared_ui.R`) — wraps `withMathJax(HTML(...))` plus a
  collapsible raw-LaTeX view with a copy-to-clipboard button, so every
  formula's LaTeX source is visible/copyable without a separate feature per
  module. `formula_latex` itself is one or more `$$...$$` display-math
  blocks (concatenated with `paste0()` when there's more than one — see §8's
  example and `README.md`'s module-contract section for the exact
  convention, including the doubled-backslash escaping an R string needs).
- Explanation and worked example as plain markdown-rendered text
  (`shiny::markdown()` or `includeMarkdown()`)
- Reference sub-tab always shows: full citation, and which package/function
  implements the method, so users can verify independently

---

## 10. Post-hoc Power Module — Special Design Considerations
- Framed explicitly as **"achieved power for planning a replication study"**,
  not as a tool to explain a non-significant p-value
- Formula/Help tab must include a short methodological note (citing Hoenig &
  Heisey 2001, *"The Abuse of Power"*) on why observed power computed from a
  study's own effect size is a monotonic function of the p-value and should not
  be used to justify a null result
- Consider a soft UI nudge: after computing achieved power, surface a link back
  to the Precision-based (CI-width) module as the recommended alternative framing

---

## 11. Non-Functional Requirements

| Requirement | Detail |
|---|---|
| Extensibility | New calculator = new module + calc + content file; no changes to core app shell |
| Input validation | Every numeric input bounded/sanity-checked (e.g., proportions in [0,1]); inline error messages, not crashes |
| Performance | All calculations are closed-form/near-instant; no need for async or caching in v1 |
| Accessibility | Use `bslib` semantic components; label all inputs; sufficient color contrast |
| Browser support | Modern evergreen browsers (Chrome, Firefox, Edge); no IE support needed |
| Portability | Deployable to shinyapps.io as-is; flag any code that would block a future Shinylive port (e.g., avoid packages with compiled system dependencies not available in WebAssembly, where feasible) |

---

## 12. Testing Strategy
- **Unit tests** (`testthat`) on every `calc_*.R` function against known published
  worked examples (textbook or original-article numbers) — this is the primary
  correctness guardrail
- **Cross-validation**: for each calculator, one manual comparison run against
  OpenEpi and/or PS: Power and Sample Size with identical inputs, documented in
  the module's test file as a comment
- **Manual UI smoke test** per module before merging: invalid input handling,
  edge cases (p=0, p=1, n very small)

---

## 13. Deployment Architecture
- **v1**: shinyapps.io free tier, single app instance
- **Future option**: Shinylive export for static hosting (e.g., GitHub Pages) if
  wider distribution to other faculty/students without server costs becomes a
  priority — revisit once calculator catalog stabilizes, since some backend
  packages may need WebAssembly-compatible alternatives

---

## 14. Development Roadmap

Superseded by the 4-stage plan in `checklist_by_design.md` / `checklist_by_test.md`
("Recommendations (staged build plan)"), which is the authoritative, actively
maintained backlog. Summary:

| Stage | Scope | Status |
|---|---|---|
| 1 — v1 CORE (~25 modules) | Single proportion, single mean, two means, two proportions, unmatched case-control, cohort/RR, one-way ANOVA, correlation, chi-square, diagnostic Se/Sp, ICC, kappa, log-rank, Simon two-stage, pilot rules-of-thumb, TOST equivalence | All Stage-1 CORE items live: Proportions, Means (incl. ANOVA), Diagnostic Accuracy, Agreement/Reliability (kappa+ICC), Case-Control (unmatched+matched), Cohort/RR, Correlation, Chi-Square Tests (GoF+independence), Pilot/Feasibility, Simon Two-Stage, Equivalence (TOST), Log-Rank/Survival |
| 1.5 — study design identification wizard, guided-tree half | "Which calculator?" guided Q&A routing a research question to the right Stage-1 module (or an honest not-built note for anything later); see §7.1 and `docs/design_identification_algorithm.md` Stages 1-5 | Live — built deliberately right after Stage 1 finished and before Stage 2 starts, so every CORE module is reachable both by name and by guided description before the backlog grows further |
| 2 — analytical depth | F-family completeness (factorial/RM-ANOVA, ANCOVA, MANOVA), full correlation/regression suite, matched case-control, ROC comparison, Bland-Altman/CCC/Cronbach, prediction-model development (`pmsampsize`) | In progress -- Cronbach's alpha, Bland-Altman LoA, and likelihood ratios (LR+/LR-) live; F-family completeness, correlation/regression suite, matched case-control, ROC/AUC, CCC, and prediction models still open |
| 3 — advanced trial designs | Cluster-randomized/stepped-wedge, group-sequential/adaptive, survival extensions, bioequivalence replicate designs, longitudinal/MMRM | Bioequivalence replicate designs (2x2x4, 2x3x3) live in Equivalence (TOST); group-sequential designs (continuous/binary/survival, Pocock-to-O'Brien-Fleming boundaries) live in the new Group Sequential Design module; rest not started |
| 4 — niche/simulation & non-formula | Genetic (`genpwr`), SEM (`semPower`), trial sequential analysis, `simr`-based simulation, guidance-only qualitative/animal-study panels | `simr`-based simulation live (Monte Carlo GLMM module, built deliberately last per this stage's own framing); guidance-only panels live (Qualitative Sample Size Guidance, Resource Equation for animal studies); genetic, SEM, and trial sequential analysis still open (no installed/reachable package or safe reimplementation path found) |
| 5 — study design identification wizard, free-text half | Stage 0 of `docs/design_identification_algorithm.md`: free-text/PICO input parsing (keyword heuristics and/or an LLM parsing layer) that pre-fills the guided wizard's answers instead of requiring every question to be clicked through manually. Deliberately deferred until after Stage 4, once the guided tree's terminals mostly point at live modules rather than "not yet built" notes | Not started |
| — (last, maybe cut) | Post-hoc/achieved-power module | Deliberately deprioritized to the very end of the build order; may be dropped entirely if the app's scope grows large enough that it's not worth the added surface area (see the Post-hoc power caveat in §10 and the checklists) |
| — | Deployment polish; evaluate Shinylive | Not started |

The original Phase 1-6 table (superseded) is preserved in git history for
reference; Phase 1 (app shell + Proportions template) and most of Phase 2
(Means, diagnostic accuracy) are complete under the new numbering above.

---

## 15. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Formula errors silently produce wrong sample sizes | Mandatory unit test against a published worked example before a module is considered done |
| Scope creep slows down v1 | Phase 1 strictly limited to one working module end-to-end |
| Post-hoc power module misused/misinterpreted by users | In-app methodological caveat is non-optional, shown on the Calculate tab itself, not buried in Help |
| Package API changes (pwr/epiR versions) break calculators | Pin package versions in a lockfile (`renv`) |

---

## 16. Open Questions
- Public GitHub repo from the start, or private until Phase 2–3 complete?
- Any interest in `renv` for dependency locking given multi-month timeline?
- Should the Reference sub-tab link out to DOIs where available, or citation text only?
- **Backend reconciliation:** three already-live calculators use a closed-form
  formula where `checklist_by_design.md`/`checklist_by_test.md` name a
  specific CRAN package instead (Proportions' precision-based design: Cochran
  formula vs. `presize::prec_prop`/`epiR::epi.sssimpleestb`; Diagnostic
  Accuracy's precision-based design: Buderer formula vs.
  `presize::prec_sens`/`prec_spec`). Both are verified correct against
  published worked examples, so this is a style question, not a correctness
  one: reconcile to the named packages for consistency with the "wrap, don't
  reimplement" principle, or leave as-is since they predate the checklist and
  already work? See `checklist_by_design.md`'s "Backend deviations" section.
- **Checklist maintenance:** `checklist_by_design.md` / `checklist_by_test.md`
  are meant to be ticked off as modules go live (per their own legend) — needs
  a habit/reminder (e.g. as a step in each new module's PR/commit) so they
  don't drift out of sync with the codebase the way this table (§7) briefly did.

---

## Appendix: Core Dependencies
`shiny`, `bslib`, `pwr`, `presize`, `precisely`, `epiR`, `WebPower`, `pwrss`,
`TrialSize`, `kappaSize`, `testthat`, `renv` (optional)
