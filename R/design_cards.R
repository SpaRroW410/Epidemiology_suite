# Design cards for the guide's end points (CHECKLIST FIND-21; decision F3 in docs/SDD.md, section 17).
#
# Drafted from the owner's routing material (docs/find_routing/03_study_design_registry_37.md, written with Gemini) and edited.
# A statement carries a source only when the source was read for it (PubMed, 6-7 Nov 2026; the list is .design_card_sources
# below and docs/find_routing/README.md). Every other statement is shown with a warning sign whose hover reads "Suggestion only --
# no confirmed source". Two of the draft's figures were contradicted by their sources and are corrected here: the F > 10 rule for
# Mendelian randomisation (Burgess & Thompson 2011 call it misleading) and "8-12 time points" for an interrupted time series
# (Bernal, Cummins & Gasparrini 2017: there is no fixed minimum).
#
# Which card a guide end point shows: the terminal's own `card` (designs that are a single end point), otherwise the `design`
# flag set by the answer that decided the design (home_design_tree.R). An end point with neither shows no card.

# --- sources -------------------------------------------------------------------------------------------------------------------
# Each was looked up in PubMed and resolves to the record named; `read` says what was read for the statements that cite it.
.design_card_sources <- list(
  prisma2020   = list(short = "PRISMA 2020", cite = "Page MJ et al. The PRISMA 2020 statement. BMJ 2021;372:n71", pmid = "33782057", doi = "10.1136/bmj.n71", read = "abstract"),
  prisma_scr   = list(short = "PRISMA-ScR", cite = "Tricco AC et al. PRISMA extension for scoping reviews (PRISMA-ScR). Ann Intern Med 2018;169:467-473", pmid = "30178033", read = "record"),
  prisma_nma   = list(short = "PRISMA-NMA", cite = "Hutton B et al. PRISMA extension for network meta-analyses. Ann Intern Med 2015;162:777-784", pmid = "26030634", read = "record"),
  prior        = list(short = "PRIOR", cite = "Gates M et al. Reporting guideline for overviews of reviews of healthcare interventions (PRIOR). BMJ 2022;378:e070849", pmid = "35944924", read = "record"),
  swim         = list(short = "SWiM", cite = "Campbell M et al. Synthesis without meta-analysis (SWiM) in systematic reviews: reporting guideline. BMJ 2020;368:l6890", pmid = "31948937", doi = "10.1136/bmj.l6890", read = "abstract"),
  entreq       = list(short = "ENTREQ", cite = "Tong A et al. Enhancing transparency in reporting the synthesis of qualitative research: ENTREQ. BMC Med Res Methodol 2012;12:181", pmid = "23185978", read = "record"),
  emerge       = list(short = "eMERGe", cite = "France EF et al. Improving reporting of meta-ethnography: the eMERGe reporting guidance. BMC Med Res Methodol 2019;19:25", pmid = "30709371", read = "record"),
  coreq        = list(short = "COREQ", cite = "Tong A, Sainsbury P, Craig J. Consolidated criteria for reporting qualitative research (COREQ). Int J Qual Health Care 2007;19:349-357", pmid = "17872937", read = "record"),
  srqr         = list(short = "SRQR", cite = "O'Brien BC et al. Standards for reporting qualitative research (SRQR). Acad Med 2014;89:1245-1251", pmid = "24979285", read = "record"),
  gramms       = list(short = "GRAMMS", cite = "O'Cathain A, Murphy E, Nicholl J. The quality of mixed methods studies in health services research (GRAMMS). J Health Serv Res Policy 2008;13:92-98", pmid = "18416914", read = "record"),
  consort2025  = list(short = "CONSORT 2025", cite = "Hopewell S et al. CONSORT 2025 statement: updated guideline for reporting randomised trials. Lancet 2025", pmid = "40245901", doi = "10.1016/S0140-6736(25)00672-5", read = "abstract"),
  consort_cluster   = list(short = "CONSORT cluster", cite = "Campbell MK et al. CONSORT 2010 statement: extension to cluster randomised trials. BMJ 2012;345:e5661", pmid = "22951546", doi = "10.1136/bmj.e5661", read = "record"),
  consort_crossover = list(short = "CONSORT crossover", cite = "Dwan K et al. CONSORT 2010 statement: extension to randomised crossover trials. BMJ 2019;366:l4378", pmid = "31366597", read = "record"),
  consort_ni   = list(short = "CONSORT non-inferiority", cite = "Piaggio G et al. Reporting of noninferiority and equivalence randomized trials: extension of the CONSORT 2010 statement. JAMA 2012;308:2594-2604", pmid = "23268518", read = "record"),
  consort_sw   = list(short = "CONSORT stepped-wedge", cite = "Hemming K et al. Reporting of stepped wedge cluster randomised trials: extension of the CONSORT 2010 statement. BMJ 2018;363:k1614", pmid = "30413417", read = "record"),
  trend        = list(short = "TREND", cite = "Des Jarlais DC et al. Improving the reporting quality of nonrandomized evaluations of behavioral and public health interventions: the TREND statement. Am J Public Health 2004;94:361-366", pmid = "14998794", read = "record"),
  strobe       = list(short = "STROBE", cite = "von Elm E et al. The Strengthening the Reporting of Observational Studies in Epidemiology (STROBE) statement. Lancet 2007;370:1453-1457", pmid = "18064739", read = "record"),
  record       = list(short = "RECORD", cite = "Benchimol EI et al. The REporting of studies Conducted using Observational Routinely-collected health Data (RECORD) statement. PLoS Med 2015;12:e1001885", pmid = "26440803", read = "record"),
  care         = list(short = "CARE", cite = "Gagnier JJ et al. The CARE guidelines: consensus-based clinical case reporting guideline development. Glob Adv Health Med 2013;2:38-43", pmid = "24416692", read = "record"),
  process      = list(short = "PROCESS 2020", cite = "Agha RA et al. The PROCESS 2020 guideline: updating consensus Preferred Reporting Of CasE Series in Surgery. Int J Surg 2020;84:231-235", pmid = "33189880", doi = "10.1016/j.ijsu.2020.11.005", read = "abstract"),
  strobe_mr    = list(short = "STROBE-MR", cite = "Skrivankova VW et al. Strengthening the reporting of observational studies in epidemiology using Mendelian randomization (STROBE-MR). JAMA 2021;326:1614-1621", pmid = "34698778", read = "record"),
  zhang_yu1998 = list(short = "Zhang & Yu 1998", cite = "Zhang J, Yu KF. What's the relative risk? JAMA 1998;280:1690-1691", pmid = "9832001", doi = "10.1001/jama.280.19.1690", read = "abstract"),
  barros2003   = list(short = "Barros & Hirakata 2003", cite = "Barros AJD, Hirakata VN. Alternatives for logistic regression in cross-sectional studies. BMC Med Res Methodol 2003;3:21", pmid = "14567763", doi = "10.1186/1471-2288-3-21", read = "abstract"),
  burgess2011  = list(short = "Burgess & Thompson 2011", cite = "Burgess S, Thompson SG. Avoiding bias from weak instruments in Mendelian randomization studies. Int J Epidemiol 2011;40:755-764", pmid = "21414999", doi = "10.1093/ije/dyr036", read = "abstract"),
  peer2008     = list(short = "Pe'er et al. 2008", cite = "Pe'er I et al. Estimation of the multiple testing burden for genomewide association studies of nearly all common variants. Genet Epidemiol 2008;32:381-385", pmid = "18348202", doi = "10.1002/gepi.20303", read = "abstract"),
  pieper2014   = list(short = "Pieper et al. 2014", cite = "Pieper D et al. Systematic review finds overlapping reviews were not mentioned in every other overview. J Clin Epidemiol 2014;67:368-375", pmid = "24581293", doi = "10.1016/j.jclinepi.2013.11.007", read = "abstract"),
  jadad1997    = list(short = "Jadad et al. 1997", cite = "Jadad AR, Cook DJ, Browman GP. A guide to interpreting discordant systematic reviews. CMAJ 1997;156:1411-1416", pmid = "9164400", read = "abstract"),
  bernal2017   = list(short = "Bernal et al. 2017", cite = "Bernal JL, Cummins S, Gasparrini A. Interrupted time series regression for the evaluation of public health interventions: a tutorial. Int J Epidemiol 2017;46:348-355", pmid = "27283160", doi = "10.1093/ije/dyw098", read = "full text")
)

# --- cards ---------------------------------------------------------------------------------------------------------------------
# A statement is list(text, src): src names entries of .design_card_sources, or NULL (shown with the warning sign).
.s <- function(text, src = NULL) list(text = text, src = src)
.threat <- function(threat, mitigation, src = NULL) list(threat = threat, mitigation = mitigation, src = src)

design_cards <- list(

  # ---- reviews ----
  sr_meta = list(title = "Systematic review with meta-analysis",
    fallback = .s("If the studies are too different to pool, a systematic review without meta-analysis, reporting the synthesis with SWiM.", "swim"),
    threats = list(
      .threat("Publication bias (small or negative studies unpublished)", "Search trial registries and grey literature; inspect a funnel plot."),
      .threat("Heterogeneity between studies", "Random-effects model; subgroup analysis or meta-regression planned in the protocol."),
      .threat("Risk of bias in the included studies", "Assess each study (RoB 2 for trials, ROBINS-I for non-randomised studies); repeat the analysis without the high-risk ones.")),
    guideline = "prisma2020", measure = "Pooled RR, OR, HR or (standardised) mean difference, with heterogeneity (I-squared)",
    workflow = "Search -> remove duplicates -> two reviewers screen -> risk of bias -> random-effects forest plot"),

  sr_narrative = list(title = "Systematic review without meta-analysis",
    fallback = .s("If the literature is too sparse or varied for a focused question, a scoping review."),
    threats = list(
      .threat("Vote counting by p-values", "Synthesise the direction and size of effects with the methods SWiM describes.", "swim"),
      .threat("Selective outcome reporting", "Register the protocol (e.g. PROSPERO) and compare reported outcomes with trial registries."),
      .threat("Groupings chosen after seeing the results", "Pre-specify how studies will be grouped for the synthesis, and report it.", "swim")),
    guideline = c("prisma2020", "swim"), measure = "Direction and range of effects, by pre-specified group",
    workflow = "Search -> screen -> risk of bias -> group studies -> structured synthesis (SWiM)"),

  scoping = list(title = "Scoping review",
    fallback = .s("If the mapping finds enough similar studies for a focused question, a systematic review."),
    threats = list(
      .threat("Scope creep", "Fix the population, concept and context in a protocol before searching.", "prisma_scr"),
      .threat("Reading the map as evidence of effect", "State that the review maps the evidence; critical appraisal is optional in a scoping review.", "prisma_scr"),
      .threat("Inconsistent data charting", "Pilot the charting form and calibrate the reviewers on a sample.")),
    guideline = "prisma_scr", measure = "Evidence map: counts by population, concept, setting and study design",
    workflow = "Protocol (population, concept, context) -> broad search -> screening -> charting -> evidence map"),

  nma = list(title = "Network meta-analysis",
    fallback = .s("If the treatments are not comparable across trials (intransitivity), separate pairwise meta-analyses."),
    threats = list(
      .threat("Intransitivity (effect modifiers differ between comparisons)", "Compare the distribution of likely effect modifiers across the comparisons."),
      .threat("Inconsistency between direct and indirect evidence", "Test it (node-splitting, global tests) and report it."),
      .threat("A sparse or unbalanced network", "Report the network's geometry: which treatments were compared directly, and how often.", "prisma_nma")),
    guideline = "prisma_nma", measure = "League table of relative effects; rankings with their uncertainty",
    workflow = "Search -> network graph -> transitivity check -> direct + indirect pooling -> rankings"),

  umbrella = list(title = "Umbrella review (review of reviews)",
    fallback = .s("If the existing reviews are out of date or of low quality, a new systematic review of the primary studies."),
    threats = list(
      .threat("The same primary studies counted in several reviews", "Measure the overlap with the corrected covered area (CCA) and report it.", "pieper2014"),
      .threat("Reviews that disagree", "Use Jadad's decision algorithm for discordant reviews.", "jadad1997"),
      .threat("Inheriting the flaws of the reviews", "Appraise each review (e.g. AMSTAR 2 or ROBIS).")),
    guideline = "prior", measure = "Summary of the reviews' estimates and their certainty",
    workflow = "Search for reviews -> appraise -> overlap matrix (CCA) -> synthesis across reviews"),

  qes = list(title = "Qualitative evidence synthesis",
    fallback = .s("If the qualitative studies are too thin for an interpretive synthesis, a scoping review that catalogues them."),
    threats = list(
      .threat("Findings stripped of their context", "Extract the context of each study with its findings."),
      .threat("The reviewers' own interpretation", "Keep a reflexive record and an audit trail of how themes were translated across studies."),
      .threat("Unclear confidence in the findings", "Rate confidence in each synthesised finding (GRADE-CERQual).")),
    guideline = c("entreq", "emerge"), measure = "Synthesised themes or a line of argument",
    workflow = "Purposive search -> appraisal -> code the studies' findings -> translate across studies -> synthesis"),

  # ---- qualitative ----
  phenomenology = list(title = "Phenomenological study",
    fallback = .s("If participants cannot reflect in depth or answers are needed quickly, a qualitative descriptive study."),
    threats = list(
      .threat("The researcher's preconceptions", "Write down and set aside prior assumptions before collecting data (bracketing)."),
      .threat("Superficial interviews", "Open, experience-focused questions; long interviews."),
      .threat("Generalising beyond the sample", "Describe the participants and context in detail; check the description with participants.")),
    guideline = c("coreq", "srqr"), measure = "The essence of the experience, with its themes",
    workflow = "Purposive sample -> bracketing -> in-depth interviews -> analysis -> essential description"),

  grounded = list(title = "Grounded theory study",
    fallback = .s("If sampling cannot follow the theory (fixed access to participants), a qualitative descriptive study with thematic analysis."),
    threats = list(
      .threat("Stopping before the theory is saturated", "Continue theoretical sampling until new data add nothing to the categories."),
      .threat("Forcing an existing theory onto the data", "Constant comparison; delay the literature framework."),
      .threat("Ignoring cases that do not fit", "Seek out negative and deviant cases and integrate them.")),
    guideline = c("coreq", "srqr"), measure = "A theory of the process, with its categories",
    workflow = "Initial sample <-> constant comparison and theoretical sampling -> coding -> theory"),

  ethnography = list(title = "Ethnography",
    fallback = .s("If long immersion in the setting is not possible, a qualitative case study."),
    threats = list(
      .threat("People behave differently when observed", "Prolonged engagement so that participants grow used to the researcher."),
      .threat("Losing analytic distance", "Regular debriefing with colleagues outside the field; reflexive field notes."),
      .threat("Seeing the setting only through gatekeepers", "Observe and interview across levels and roles; use documents and artefacts.")),
    guideline = c("coreq", "srqr"), measure = "A thick description of the culture and its practices",
    workflow = "Entry to the field -> participant observation and field notes -> key informants -> description"),

  case_study = list(title = "Qualitative case study",
    fallback = .s("If several sources within the case are not available, a qualitative descriptive study."),
    threats = list(
      .threat("Unclear boundaries of the case", "Define the place, time and organisation of the case first."),
      .threat("Relying on one source", "Combine interviews, observation and documents."),
      .threat("Findings that do not transfer", "Describe the context fully; compare cases if there are several.")),
    guideline = c("coreq", "srqr"), measure = "Within-case and cross-case findings",
    workflow = "Define the case -> interviews + documents + observation -> within-case analysis -> report"),

  qual_descriptive = list(title = "Qualitative descriptive study (thematic analysis)",
    fallback = .s("If breadth across many people matters more than depth, a survey with open questions."),
    threats = list(
      .threat("Staying at the surface", "Pilot the interview guide with people like the participants; probe."),
      .threat("One coder's reading", "Code part of the transcripts independently and reconcile the codebook."),
      .threat("Socially desirable answers", "Build rapport, assure anonymity, ask indirectly where needed.")),
    guideline = c("coreq", "srqr"), measure = "Themes, with supporting quotations",
    workflow = "Purposive sample -> semi-structured interviews or focus groups -> coding -> themes"),

  # ---- mixed methods ----
  mm_explanatory = list(title = "Explanatory sequential mixed methods",
    fallback = .s("If there is no time to wait for the quantitative results, a convergent design."),
    threats = list(
      .threat("The two phases not connected", "Choose interviewees from the quantitative respondents, by the results to be explained."),
      .threat("Losing participants between phases", "Ask for consent to re-contact during the first phase."),
      .threat("Explaining the wrong results", "Decide which results the interviews will explain, and show both in a joint display.")),
    guideline = "gramms", measure = "Quantitative estimates and a joint display with the explanations",
    workflow = "Quantitative data and analysis -> select respondents -> interviews -> joint display"),

  mm_exploratory = list(title = "Exploratory sequential mixed methods",
    fallback = .s("If a validated instrument already exists, a convergent design with that instrument."),
    threats = list(
      .threat("Themes poorly turned into items", "Map quotations to items; test the items with cognitive interviews."),
      .threat("Validating on the same people", "Validate the instrument in a new, adequately sized sample (see Scale development)."),
      .threat("Running out of time before phase 2", "Plan milestones for both phases from the start.")),
    guideline = "gramms", measure = "An instrument or taxonomy, and its quantitative validation",
    workflow = "Qualitative exploration -> build the instrument -> quantitative validation in a new sample"),

  mm_convergent = list(title = "Convergent mixed methods",
    fallback = .s("If the two strands are likely to disagree and need a follow-up to resolve it, an explanatory sequential design."),
    threats = list(
      .threat("The strands ask about different things", "Design the survey and the interview guide around the same concepts."),
      .threat("Disagreement left unresolved", "Plan in advance how divergent findings will be handled."),
      .threat("Merged only in the discussion", "Merge the results formally, e.g. in a side-by-side joint display.")),
    guideline = "gramms", measure = "A joint display and the conclusions drawn from both strands",
    workflow = "Survey + interviews in parallel -> separate analyses -> merge in a joint display"),

  mm_embedded = list(title = "Embedded mixed methods (qualitative work in a trial)",
    fallback = .s("If the qualitative work could change the trial's conduct or unblind it, a trial without it (but then a null result cannot be told apart from a failed implementation)."),
    threats = list(
      .threat("The qualitative work changes behaviour in the trial", "Interview a subset, or after the primary outcome is collected."),
      .threat("Unblinding the outcome assessors", "Keep the qualitative team separate from the outcome assessment."),
      .threat("A token qualitative strand", "Plan it as a process evaluation (fidelity, context, mechanisms) linked to the trial's results.")),
    guideline = c("consort2025", "gramms"), measure = "The trial's effect, with the process evaluation's findings",
    workflow = "Trial (enrol -> randomise -> follow up) + interviews on delivery and acceptability -> integration"),

  # ---- trials ----
  parallel_rct = list(title = "Parallel-group randomised trial",
    fallback = .s("If randomisation is refused or not feasible, a controlled before-after study or a cohort with propensity scores, which cannot protect against unmeasured confounding."),
    threats = list(
      .threat("Allocation that can be foreseen or changed", "Central, computer-generated randomisation with concealed allocation."),
      .threat("Knowing the allocation changes care or assessment", "Blind participants and outcome assessors where possible (placebo or sham)."),
      .threat("Drop-out and non-adherence", "Analyse by intention to treat; per-protocol analysis as a sensitivity analysis.")),
    guideline = "consort2025", measure = "Risk ratio, risk difference, hazard ratio or mean difference",
    workflow = "Eligible people -> concealed randomisation -> intervention vs control -> blinded outcome (ITT)"),

  crossover = list(title = "Crossover trial",
    fallback = .s("If the treatment cures, acts for a long time or many drop out between periods, a parallel-group trial (which needs more participants)."),
    threats = list(
      .threat("Carryover from the first period", "A washout long enough for the first treatment's effect to end; more than five half-lives is often quoted."),
      .threat("Period effects (the condition changes over time)", "Use a stable, chronic condition; include period in the analysis."),
      .threat("Drop-out between periods", "Keep the periods short; plan for it in the sample size.")),
    guideline = "consort_crossover", measure = "Within-person difference (mean difference or paired odds ratio)",
    workflow = "Randomise the sequence -> A, washout, B  |  B, washout, A -> within-person comparison"),

  cluster_rct = list(title = "Cluster randomised trial",
    fallback = .s("If every cluster must eventually receive the intervention, a stepped-wedge trial; if too few clusters can be randomised, a controlled before-after study."),
    threats = list(
      .threat("Recruiting people after the clusters are allocated", "Identify and recruit participants before randomising the clusters, or keep recruiters blind."),
      .threat("Ignoring the correlation within clusters", "Inflate the sample size by the design effect and analyse with mixed models or GEE (Cluster / Design Effect calculator)."),
      .threat("Imbalance between few clusters", "Stratified or covariate-constrained randomisation.")),
    guideline = "consort_cluster", measure = "Cluster-adjusted RR, OR or mean difference, with the ICC",
    workflow = "Identify clusters -> enrol -> randomise clusters -> mixed-model or GEE analysis"),

  stepped_wedge = list(title = "Stepped-wedge cluster randomised trial",
    fallback = .s("If outcomes follow strong time trends (seasons, other programmes), a parallel cluster trial."),
    threats = list(
      .threat("Confounding by time", "Adjust for calendar time in the analysis."),
      .threat("Clusters acting before their step", "Tell each cluster its crossover date only shortly before it."),
      .threat("Correlation that changes over time", "Model correlation that decays with time between measurements.")),
    guideline = "consort_sw", measure = "Intervention effect adjusted for time",
    workflow = "All clusters control -> clusters switch in random order, step by step -> time-adjusted analysis"),

  noninferiority = list(title = "Non-inferiority or equivalence trial",
    fallback = .s("If the active control's effect is uncertain or the margin needs an unreachable sample size, a superiority trial."),
    threats = list(
      .threat("Sloppy conduct makes the arms look alike", "Report intention-to-treat and per-protocol analyses; both should support the conclusion."),
      .threat("A margin that is too wide", "Justify the margin from the control's effect in earlier placebo-controlled trials; preserving at least half of it is often required."),
      .threat("A control that would not have beaten placebo here", "Keep population, dose and adherence as in the trials that established the control.")),
    guideline = "consort_ni", measure = "Confidence interval of the difference compared with the margin",
    workflow = "Eligible people -> randomise: new vs standard -> ITT + per-protocol -> CI vs margin"),

  # ---- quasi-experiments ----
  did = list(title = "Controlled before-after study / difference-in-differences",
    fallback = .s("If no comparison group follows the same trend, an interrupted time series."),
    threats = list(
      .threat("The groups' trends were not parallel before", "Several measurements before the start, to check the pre-intervention trends."),
      .threat("Who is in each group changes over time", "Follow the same people or units (panel data), or weight for the changes."),
      .threat("Something else happened in one group only", "Look for other events; use a placebo date as a check.")),
    guideline = "trend", measure = "Difference-in-differences estimate",
    workflow = "Intervention and comparison groups -> before -> start -> after -> difference of the differences"),

  its = list(title = "Interrupted time series",
    fallback = .s("If another event coincides with the start, a controlled interrupted time series with a comparison series or outcome.", "bernal2017"),
    threats = list(
      .threat("Other events at the same time (history)", "Add a control series or a control outcome that the intervention cannot affect; model known time-varying confounders.", "bernal2017"),
      .threat("Seasonality and autocorrelation", "Adjust for season (calendar month, Fourier terms or splines); check residual autocorrelation and correct it (e.g. Prais regression, ARIMA).", "bernal2017"),
      .threat("Too little power", "There is no fixed minimum number of time points: power depends on the split before and after, the variability, the effect and seasonality; simulate it in advance.", "bernal2017")),
    guideline = c("trend", "record"), measure = "Immediate change in level and change in slope",
    workflow = "Time points before -> start (impact model fixed in advance) -> time points after -> segmented regression"),

  rdd = list(title = "Regression discontinuity design",
    fallback = .s("If people can shift their score across the cut-off, a cohort with propensity scores (losing the local comparison at the cut-off)."),
    threats = list(
      .threat("Scores manipulated around the cut-off", "Check the density of the score at the cut-off (McCrary test)."),
      .threat("Wrong shape of the relation with the score", "Local polynomial regression with a data-driven bandwidth; vary the bandwidth."),
      .threat("Not everyone follows the cut-off", "A fuzzy design (instrumental-variable analysis).")),
    guideline = "trend", measure = "Effect at the cut-off (local average treatment effect)",
    workflow = "Score -> cut-off -> compare just below with just above -> jump at the cut-off"),

  prepost = list(title = "Single-arm pre-post study",
    fallback = .s("With several measurements before the start, an interrupted time series; with a comparison group, a controlled before-after study."),
    threats = list(
      .threat("Regression to the mean", "Measure the baseline more than once; do not select people for extreme values."),
      .threat("Change that would have happened anyway (maturation, time trends)", "Keep follow-up short; prefer objective measures; state that the design cannot separate these."),
      .threat("Practice effects from repeated testing", "Use alternate forms of the questionnaire.")),
    guideline = "trend", measure = "Paired mean difference, or paired proportions (McNemar)",
    workflow = "One group -> before -> intervention -> after -> within-person change"),

  # ---- observational and descriptive ----
  ecological = list(title = "Ecological study (one period)",
    fallback = .s("If individual records can be obtained, an analytical cross-sectional study at the individual level."),
    threats = list(
      .threat("Ecological fallacy", "Keep conclusions at the group level."),
      .threat("Confounding at the group level", "Standardise rates (e.g. by age); allow for spatial correlation."),
      .threat("Results that depend on how areas are drawn", "Repeat the analysis at another level of aggregation.")),
    guideline = "strobe", measure = "Correlation or regression slope between group rates",
    workflow = "Areas or groups -> exposure rate and outcome rate per group -> group-level regression"),

  ecological_trend = list(title = "Ecological time-trend study",
    fallback = .s("With a known start date for a programme, an interrupted time series; with individual records within areas, a multilevel cohort."),
    threats = list(
      .threat("Ecological fallacy over time", "Keep conclusions at the group level."),
      .threat("The population changes (migration, turnover)", "Use denominators for each year; adjust for demographic change."),
      .threat("Coding and diagnosis change over the years", "Check for changes in definitions (e.g. ICD revisions) and allow for them.")),
    guideline = c("strobe", "record"), measure = "Trend or rate ratio over time, by area",
    workflow = "Areas followed over years -> yearly rates -> panel (fixed-effects) regression"),

  case_report = list(title = "Case report",
    fallback = .s("If more patients with the same picture can be found, a case series."),
    threats = list(
      .threat("Over-interpreting one patient", "Present it as hypothesis-generating."),
      .threat("A coincidental association", "For a suspected drug reaction, assess causality with a structured scale (e.g. Naranjo)."),
      .threat("Incomplete records", "Check the timeline against laboratory, imaging and pathology records.")),
    guideline = "care", measure = "A structured timeline of the case",
    workflow = "Patient -> history and investigations -> course and outcome -> report"),

  case_series = list(title = "Case series",
    fallback = .s("To test whether an exposure is linked to the condition, a case-control study or a cohort."),
    threats = list(
      .threat("No comparison group", "Report proportions with confidence intervals; make no comparative claims."),
      .threat("Referral and selection bias", "Include consecutive patients; describe where they came from."),
      .threat("Inconsistent definitions and follow-up", "Use a strict case definition and one abstraction form.")),
    guideline = c("process", "care"), measure = "Proportions, medians with IQR, or survival curves",
    workflow = "Case definition -> consecutive patients -> standard abstraction -> description"),

  descriptive_cs = list(title = "Descriptive cross-sectional survey (prevalence)",
    fallback = .s("To compare prevalence between groups, an analytical cross-sectional study (sized for that comparison)."),
    threats = list(
      .threat("Non-response", "Follow up non-responders; compare them with responders; weight for non-response."),
      .threat("A sampling frame that misses people", "Probability sampling from a complete frame; post-stratification weights."),
      .threat("Prevalence reflects survival as well as incidence", "Say whether it is point or period prevalence; do not read it as risk.")),
    guideline = "strobe", measure = "Prevalence with its (design-weighted) confidence interval",
    workflow = "Population frame -> probability sample -> measure -> weighted prevalence"),

  analytic_cs = list(title = "Analytical cross-sectional study",
    fallback = .s("If it matters that exposure came before the outcome, a cohort (from records) or a case-control study."),
    threats = list(
      .threat("Which came first is unknown", "Ask about exposures that cannot be changed by the outcome (fixed or past)."),
      .threat("The odds ratio exaggerates a common outcome", "When the outcome is common (more than about 10%), the odds ratio no longer approximates the ratio of proportions; estimate the prevalence ratio (Poisson regression with robust variance, or log-binomial).", c("zhang_yu1998", "barros2003")),
      .threat("Measuring exposure and outcome together (recall, common method)", "Use records or objective measures for one of them where possible.")),
    guideline = "strobe", measure = "Prevalence ratio (or prevalence odds ratio)",
    workflow = "Sample -> measure exposure and outcome together -> 2 x 2 -> adjusted prevalence ratio"),

  cohort = list(title = "Cohort study (prospective or from records)",
    fallback = .s("If the outcome is rare or takes years to develop, a nested case-control study within an existing cohort, or a case-control study."),
    threats = list(
      .threat("Loss to follow-up that differs between groups", "Track participants actively; weight for censoring (IPCW)."),
      .threat("Confounding", "Draw the causal diagram before the analysis; adjust, match or weight on propensity scores."),
      .threat("From records: immortal time and misclassified codes", "Start follow-up at the same time zero for both groups (target trial emulation); use validated code lists.")),
    guideline = c("strobe", "record"), measure = "Risk ratio, rate ratio or hazard ratio",
    workflow = "People free of the outcome -> exposed vs unexposed -> follow-up -> compare incidence"),

  case_control = list(title = "Case-control study",
    fallback = .s("If complete records of the source population exist, a cohort from records; for a brief exposure with an acute outcome, a case-crossover study."),
    threats = list(
      .threat("Recall bias", "Use records made before the outcome, or controls with another illness."),
      .threat("Controls from a different population", "Draw controls from the same source population as the cases (incidence density sampling)."),
      .threat("Early disease changing the exposure (reverse causation)", "Ignore exposure in a window before symptom onset (lag).")),
    guideline = "strobe", measure = "Odds ratio (conditional logistic regression if matched)",
    workflow = "Cases and controls -> exposure looked back -> odds ratio"),

  nested_cc = list(title = "Nested case-control study",
    fallback = .s("If the measurement is cheap or already done for everyone, analyse the full cohort."),
    threats = list(
      .threat("Laboratory batch effects", "Analyse each case with its controls in the same batch, blind to status."),
      .threat("Controls not matched on time", "Sample controls from those still at risk when each case occurs (risk-set sampling)."),
      .threat("Stored samples degrade", "Match on storage time and freeze-thaw cycles.")),
    guideline = "strobe", measure = "Odds ratio from conditional logistic regression (estimates the rate ratio)",
    workflow = "Cohort with stored samples -> all cases -> risk-set controls -> assay -> conditional OR"),

  case_crossover = list(title = "Case-crossover study",
    fallback = .s("For a slow-acting exposure, a case-control study; to use all of each person's time, a self-controlled case series."),
    threats = list(
      .threat("Things that change within a person at the same time", "Adjust for other short-term exposures (e.g. other drugs, temperature)."),
      .threat("Trends in exposure over time", "Time-stratified control windows (e.g. same weekday in the same month)."),
      .threat("A wrongly chosen hazard window", "Repeat the analysis with other window lengths.")),
    guideline = "strobe", measure = "Odds ratio from the within-person comparison",
    workflow = "Cases with an acute event -> exposure in the hazard window vs control windows -> matched OR"),

  mr = list(title = "Mendelian randomisation",
    fallback = .s("If no strong genetic instruments exist, a cohort analysed as a target trial emulation (open to confounding)."),
    threats = list(
      .threat("Variants that affect the outcome by other routes (pleiotropy)", "Sensitivity analyses (MR-Egger, weighted median, outlier methods)."),
      .threat("Weak instruments", "Bias from weak instruments runs towards the confounded observational estimate and falls as the F-statistic rises; the rule of thumb that F > 10 avoids bias is misleading. Choose instruments in advance, not by the F-statistic in the same data.", "burgess2011"),
      .threat("Population stratification", "Restrict to one ancestry; adjust for genetic principal components.")),
    guideline = "strobe_mr", measure = "Causal OR or beta per unit (or SD) of the exposure",
    workflow = "Variants (genome-wide significant, p < 5e-8) -> associated with exposure -> effect on outcome -> IVW + sensitivity",
    workflow_src = "peer2008")
)

# Cards that rest on statements of one source each, listed for the tests: none of the numbers the draft gave without a source is
# shown as sourced.
.design_card_unsourced_numbers <- c("five half-lives", "at least half")

# --- which card -------------------------------------------------------------------------------------------------------------
.design_card_key <- function(node, flags) {
  key <- if (!is.null(node$card)) node$card else flags$design
  if (is.null(key) || !key %in% names(design_cards)) NULL else key
}

# --- rendering ---------------------------------------------------------------------------------------------------------------
.design_card_unsourced_label <- "Suggestion only -- no confirmed source"

.design_card_mark <- function(src) {
  if (length(src)) {
    tags$span(class = "dc-src small text-muted",
              paste0(" (", paste(vapply(src, function(k) .design_card_sources[[k]]$short, ""), collapse = "; "), ")"))
  } else {
    tags$span(class = "dc-unsourced ms-1", role = "img", tabindex = "0", title = .design_card_unsourced_label,
              `aria-label` = .design_card_unsourced_label, "\u26a0")
  }
}

.render_design_card <- function(key) {
  if (is.null(key)) return(NULL)
  card <- design_cards[[key]]
  srcs <- unique(c(card$fallback$src, unlist(lapply(card$threats, `[[`, "src")), card$guideline, card$workflow_src))
  tags$details(class = "design-card card card-body mt-3 mb-2",
    tags$summary(class = "fw-semibold", paste("Design card:", card$title)),
    p(class = "small text-muted mt-2 mb-2", "Planning notes for this design. A ", .design_card_mark(NULL),
      " marks a suggestion with no confirmed source; the others name the source checked for them (listed below)."),
    p(class = "mb-1", strong("If this design is not feasible: "), card$fallback$text, .design_card_mark(card$fallback$src)),
    p(class = "mb-1", strong("Main threats and what to do")),
    tags$ul(class = "mb-2", lapply(card$threats, function(t)
      tags$li(strong(paste0(t$threat, ": ")), t$mitigation, .design_card_mark(t$src)))),
    p(class = "mb-1", strong("Report with: "),
      paste(vapply(card$guideline, function(k) .design_card_sources[[k]]$cite, ""), collapse = "; ")),
    p(class = "mb-1", strong("Main effect measure: "), card$measure),
    p(class = "mb-2", strong("Workflow: "), code(card$workflow), if (!is.null(card$workflow_src)) .design_card_mark(card$workflow_src)),
    tags$details(class = "small",
      tags$summary("Sources"),
      tags$ol(lapply(srcs, function(k) {
        s <- .design_card_sources[[k]]
        tags$li(HTML(paste0(htmltools::htmlEscape(paste0(s$cite, ". PMID ", s$pmid)),
                            if (!is.null(s$doi)) paste0(". ", as.character(tags$a(href = paste0("https://doi.org/", s$doi), target = "_blank",
                                                                                   rel = "noopener", paste0("doi:", s$doi)))),
                            htmltools::htmlEscape(paste0(" (", s$read, " read)")))))
      }))))
}
