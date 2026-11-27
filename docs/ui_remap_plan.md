# UI remap: finding a calculator (proposal, 24 Nov 2026)

Status: decided with the owner on 24 Nov 2026 (grouping, one set of names, four front-door changes) and 27 Nov 2026 (Effect Sizes
stays first; Attrition goes to group 7; the checklist is regrouped too). Step 1 built 27 Nov 2026; the rest in the order below, one
commit each, tests after each, and any open question cleared with the owner first.

## What is wrong now

- The Plan sidebar has 20 groups for 71 calculators; 11 groups hold a single calculator, and "General Statistical Tests" holds 15.
- Three different groupings: the sidebar (20 groups), Browse (47 families) and the guide's end points. Names differ between them.
- Home and "Find a calculator" are two top tabs plus a toggle; a first-time visitor has to know which door to use.
- A calculator's name alone ("Proportions", "Variance Tests") does not say what question it answers.

## Decisions (24 Nov 2026)

1. **Regroup the Plan sidebar into 7 groups, led by study design** (the owner looks for a calculator by its design).
2. **One set of names everywhere**: the sidebar, Browse and Studies use these groups, with the 47 families as sub-headings.
3. First round also includes: **Home and Find merged into one start page**, a **filter box** at the top of the sidebar, a
   **one-line description** under each calculator, and **recently used / favourites** (kept in the browser).

## The seven groups (every calculator once; ids unchanged, so links, Studies and the guide keep working)

Effect Sizes stays first, above the seven groups, because many calculators link to it (owner, 27 Nov 2026).

| Group | Calculators |
|---|---|
| 1. Estimate (surveys and descriptive) | proportion, means, rate, ratio, stratified, cluster, lqas, capture_recapture, rule_of_three, survey_selection, survey_weights |
| 2. Trials and experiments | pilot, simon, tost, noninferiority, crossover, group_sequential, subgroup_interaction, glmm, tsa, stepped_wedge, patient_units, resource_equation, randomization |
| 3. Observational and natural experiments | case_control, cohort, sccs, mendelian, its, did, ecological |
| 4. Survival | logrank, competing_risks, rmst |
| 5. Tests, relationships and models | correlation, chisq, regression, anova_general, logistic, exact_tests, rm_anova, nonparametric, variance, multiplicity, manova, bayesian, longitudinal, multilevel, meta_power |
| 6. Diagnosis, agreement, prediction and measurement | diagnostic, roc, agreement, prediction, efa_cfa |
| 7. Other designs and general tools | attrition, qualitative, evpi, epidemic_model |

Group 5 stays long (15). Inside it, Browse's families (Correlation, Chi-square, Regression, ...) become sub-headings so it reads as
five short lists. Analyze keeps its two groups.

## Build order

1. Regroup (`module_workbenches` in `R/registry.R`); a test that every module is in exactly one group and the counts add up. **Done 27 Nov
   2026**; the checklist's calculator sections were regrouped in the same order (every line kept; old section names stay in the headings).
2. Browse and Studies use the same group names. **Done 27 Nov 2026**: Browse by study design shows the families under the sidebar's
   group headings (each family's group is where most of its calculators sit, `study_design_family_group()`), with "Analyze (data you
   already have)" last; "Study planning tools" became four families (survey field tools, randomization list, attrition, epidemic
   models), the same 15 designs; Proportions and Precision-based stay whole under Estimate; Browse by test family is unchanged. Each
   Studies section shows its group name above its title (on screen; the Word file is unchanged).
3. One-line description under each calculator (from the catalogue's `answers` text, shortened; a test that every module has one).
4. Filter box over the sidebar list (client-side; works in the browser build and on phones).
5. Recently used / favourites (browser storage with try/catch; the page must work without it).
6. Merge Home and Find into one start page with three doors: I have a question (guide), I know the test or name (search), I want
   to browse.

Risks: the phone shell and the browser tests open calculators by title (`ui_open_module()`), so titles must not change; lazy loading
(`lazy_modules.R`) lists modules by id, so only the groups move. Each step ships on its own so any can be dropped.
