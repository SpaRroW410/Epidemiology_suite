# Find: the "Methodological Routing Architect" material (received 6 November 2026)

The owner drafted this with Gemini and shared it from Google Drive (folder `Methodological_Routing_Architect`, 4 files, created
6 Nov 2026), to speed up the Find items of `../CHECKLIST.md` (section 3). It is **source material, not the specification**: what is
built goes into `../design_identification_algorithm.md` and the code. It is kept here so the work does not depend on access to the Drive
folder.

| Drive file | Here |
|---|---|
| `01_state_and_terminology_schema.json` | Summarised below (the parameters and their values) |
| `02_master_algorithm_pseudocode.md` | Summarised below (the tree, the guardrails, the search-block builder) |
| `03_study_design_registry_37.md` | [`03_study_design_registry_37.md`](03_study_design_registry_37.md), as received apart from removing the export's escape characters. Part A: for each of 37 designs a fallback design, three threats to validity with mitigations, the EQUATOR guideline and effect measure, a workflow sketch. Part B: MeSH / Emtree / CINAHL terms and a PubMed filter per design. Row 18 (factorial) is cut off in the source after the start of its workflow cell. |
| `04_phase1_llm_extractor_prompt.md` | Summarised below (the system prompt of the language-model reader) |

## What it proposes

1. **A reader** (a language model with a fixed JSON schema) fills study parameters from the user's words, never guessing: a parameter
   stays empty unless stated or unambiguous; "effect / impact" does not make a study interventional; existing records, registries or
   national surveys make the data secondary. It also maps the population, exposure, comparator and outcome to MeSH, Emtree,
   CINAHL / PsycINFO, free-text synonyms and clinical codes (ICD-10-CM, SNOMED CT, LOINC, RxNorm).
2. **A session state**: each parameter is *known*, *missing and blocking* or *missing, not blocking*, with the quote that set it.
3. **A fixed tree** of five nodes, asked one question at a time (the first blocking parameter):

| Node | Parameter | Values → design |
|---|---|---|
| 1 Data origin | `data_origin` | literature synthesis → 1A; secondary data (adds the constraint "retrospective or cross-sectional only"); primary data |
| 1A Synthesis type | `synthesis_subtype` | systematic review with meta-analysis; without meta-analysis; scoping review; network meta-analysis; umbrella review; qualitative evidence synthesis |
| 2 Paradigm | `epistemological_paradigm` | qualitative → 2A; mixed methods → 2B; quantitative → 3 |
| 2A Qualitative focus | `qualitative_focus` | phenomenology; grounded theory; ethnography; qualitative case study; qualitative descriptive |
| 2B Mixed-methods sequence | `mixed_methods_sequence` | explanatory sequential; exploratory sequential; convergent parallel; embedded |
| 3 Manipulation | `investigator_manipulation` | yes → 4; no → 5 |
| 4 Randomisation | `randomization_feasible`, `experimental_subtype`, `quasi_subtype` | randomised: parallel, crossover, factorial, cluster, stepped-wedge, non-inferiority; not randomised: controlled before-after / difference-in-differences, interrupted time series, regression discontinuity, single-arm pre-post |
| 5 Observational | `unit_of_analysis`, `ecological_temporality`, `has_comparison_group`, `descriptive_subtype`, `observational_sampling` | group level: ecological snapshot or time trend; no comparison: case report, case series, descriptive cross-sectional; comparison: analytical cross-sectional, prospective cohort, retrospective cohort, case-control, nested case-control, case-crossover, Mendelian randomisation |

4. **Guardrails**: (a) a harmful exposure (smoking, toxins, radiation, trauma, poverty, pathogens, adverse drug reactions) makes the
   study observational; (b) group-level data with an individual-level question raise an ecological-fallacy lock; (c) a rare outcome or
   long latency is flagged; (d) secondary data turn a prospective cohort into a retrospective one; (e) "genetics" plus the words SNP /
   variant / Mendelian / polygenic route to Mendelian randomisation.
5. **Output**: the design's card from the registry, and PubMed concept blocks (MeSH, MeSH/subheading, `[tiab]` synonyms joined by OR).

## Review (6 Nov 2026)

What it adds to the guide: literature reviews, mixed methods, quasi-experiments (difference-in-differences, interrupted time series,
regression discontinuity, single-arm pre-post), time-trend ecological studies, Mendelian randomisation, case reports and series; the
"never guess" rule and the one-question gate; and a design card for every end point.

Problems found, and how the build will treat them:

- **No branch for diagnostic accuracy, agreement / reliability, prediction models or estimating one value**, and the tree stops at the
  design name where the guide goes on to the outcome type and the calculator. *Merged into the existing guide instead of replacing it.*
- **Quasi-experiments are reachable only when the investigator assigns the intervention.** An interrupted time series or a
  difference-in-differences of a government policy using routine records, the commonest use of these designs, cannot be reached.
  *The guide will ask who assigned it (the team, or someone else such as a programme or a policy).*
- **The ethical guardrail overwrites a stated answer**: if the exposure looks harmful the study is set to observational even when the
  user said they randomise, and the "toxicity" / "chemically induced" subheadings trip it for ordinary drug and vaccine trials. *A
  warning that asks, never a silent change.*
- **The ecological-fallacy lock has no way out** (`ecological_fallacy_resolved` is never set). *A warning with the two ways to resolve
  it: individual-level data, or a group-level question.*
- **"variant" sends a study to Mendelian randomisation** ("COVID-19 variant", "variant angina"). *Only "Mendelian randomi[sz]ation" or
  "genetic instrument".*
- **A later answer silently replaces an earlier one.** *The guide shows the change and asks.*
- **Non-inferiority sits beside crossover and cluster** as if exclusive; it is a comparison intent that combines with any of them (as
  the guide already treats it).
- **Nested case-control and case-cohort are one design**; their analyses and sample sizes differ (both are built: OBS-05, OBS-06).
- **MeSH headings**: the 46 MeSH headings and publication types in Part B were looked up in the NLM MeSH vocabulary
  (`id.nlm.nih.gov/mesh`, 6 Nov 2026). 42 exist; 4 do not: `"Cluster Randomized Controlled Trials"[Mesh]` (rows 19, 20),
  `"Ecological Studies"[Mesh]` (26, 27), `"Factorial Design"[Mesh]` (18), and `"Equivalence Trials"[pt]` (21; the publication type
  is `"Equivalence Trial"`).
- **The PubMed filters are called "validated" but are not the published validated filters** (for example the Cochrane highly
  sensitive search strategy for randomised trials).
- **Generated codes**: a language model writing MeSH, Emtree, ICD, SNOMED CT, LOINC and RxNorm codes in one pass produces codes that
  look right and are not (see the four MeSH headings above). Emtree, CINAHL and PsycINFO are subscription vocabularies that cannot be
  checked here; ICD-10-CM is the US version (WHO ICD-10 is used in India).
- **The card text has no sources.** Claims that need one include: an interaction needs about four times the sample size (factorial);
  washout longer than five half-lives (crossover); 8-12 time points before and after (interrupted time series); prevalence ratio when
  the prevalence is above 10% (cross-sectional); a margin preserving at least half the control effect (non-inferiority); F < 10 and
  p < 5e-8 (Mendelian randomisation). Row 21's "sacrifice" sentence is garbled.

## Decisions (owner, 6 Nov 2026; `../SDD.md` section 17, F1-F4)

| # | Decision |
|---|---|
| F1 | **Deterministic reader only.** The tree, state and one-question gate are built and fed by the existing keyword reader (`R/design_free_text.R`); nothing is sent anywhere. A language-model reader stays optional (FIND-14). |
| F2 | **Merge into the existing guide**: keep its first question (estimate / compare / predict / diagnostic / agreement / qualitative) and add the new branches inside it; every end point leads to a calculator or says that none exists yet. |
| F3 | **Design cards from this text, edited.** A claim gets a citation where a source is found; otherwise it carries a warning mark whose hover says it is a suggestion only, with no confirmed source. |
| F4 | **Search terms from checkable sources only**: a PubMed builder with MeSH headings checked against NLM and published validated design filters; no Emtree / CINAHL / PsycINFO terms and no clinical codes for now. |

The work is listed in `../CHECKLIST.md` as FIND-15 to FIND-24, OBS-12 to OBS-15 and SRC-06.

**Built:** the branches and the reader (FIND-16 to FIND-20, 6 Nov 2026); the design cards from Part A of the registry
(`R/design_cards.R`, FIND-21, 7 Nov 2026), with each statement's source checked or the statement marked as a suggestion. Corrected on
checking: the F > 10 rule for Mendelian randomisation and the 8-12 time points for an interrupted time series.

**Built (8 Nov 2026):** the PubMed search builder (`R/pubmed_search.R`, FIND-22) with the published filters copied as printed
(Cochrane Handbook 6.5 technical supplement, Boxes 3.a and 3.b; PubMed Clinical Queries) and every other filter labelled as not
validated; the MeSH headings it prints are checked against NLM by `tools/find/check_mesh.R` (FIND-23). Of Part B's headings, the
four that do not exist are not used, and "Network Meta-Analysis" is a publication type (since MeSH 2025), not a subject heading.
