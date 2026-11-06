# Stage 0 of docs/design_identification_algorithm.md: free-text keyword
# heuristics that pre-fill home_design_tree.R's guided wizard instead of requiring
# every question to be clicked through by hand. Deliberately keyword-based,
# not LLM-based -- this app has no LLM API wired in anywhere and is otherwise
# fully self-contained/deterministic/unit-tested, and the algorithm doc's own
# section 0.3 explicitly frames keyword heuristics as the graceful-degrade
# design for offline/no-API operation. Never lets the parser choose a final
# module on its own: it only pre-selects home_design_tree.R option indices a human
# would otherwise click, and it stops the instant no rule matches, handing
# control back to the manual wizard exactly where it left off.
#
# Coverage is deliberately partial: rules exist for the Stage-1 root branch (including an
# explicit-analysis cue for the Analyze branch and its sub-branch table),
# the estimation sub-branch, and the comparison path (allocation ->
# selection basis -> case-control matching -> outcome type -> groups ->
# dependence) -- the phrasing patterns the algorithm doc itself discusses.
# The RCT-internals branch (individual vs. cluster allocation, superiority
# vs. non-inferiority intent) has no rules yet: real text rarely states
# these as cleanly as a keyword table can capture, and a wrong high-
# confidence guess there is worse than stopping one question early.

# Research questions phrased by topic (ROADMAP "Expanding the guide's free-text reader"):
# - descriptive topics (knowledge-attitude-practice, awareness, utilization, pattern of ...) are surveys of a population: routed to an estimate;
# - "determinants / factors associated / risk factors / predictors / correlates of X" are NOT routed: docs/design_identification_algorithm.md
#   (section 0.3 and "Never collapse ... at Low confidence") says they are ambiguous between a cross-sectional survey, a case-control study,
#   a cohort and a prediction model, and the guide must show the candidates and let the user choose. walk_free_text() flags them
#   (flags$ambiguous = "determinants") and the guide offers the four routes (.rq_routes, R/design_wizard.R).
.free_text_topic_pattern <- paste0(
  "knowledge,? attitudes?|\\bkap\\b|\\bkabp?\\b|awareness (of|about|regarding)|perceptions? (of|about|regarding)|",
  "practices? (of|about|regarding|related)|utili[sz]ation of|uptake of|coverage of|pattern of")
.free_text_determinants_pattern <- paste0(
  "determinants?|factors? (associated|related|influencing|affecting|contributing|responsible)|associated factors|risk factors?|",
  "predictors? (of|for)|correlates of")

# Flags read from the whole description, whatever path the rules take (used by the guide's last step):
#   determinants  the question asks what is associated with the outcome, so the association needs its own sample size too
#   population    a population named by place or setting (city, district, village, schools ...), so cluster sampling is likely
.free_text_flags <- function(text) {
  has <- function(p) grepl(p, text, ignore.case = TRUE, perl = TRUE)
  list(
    # FIND-19 signals (warnings in the guide, never a change of route): a harmful exposure, unless the text is about treating or
    # preventing it; an outcome that is rare or takes years to develop; data that already exist; individual-level wording
    harmful = has("smok|tobacco|alcohol|toxin|pesticide|arsenic|\\blead (exposure|poisoning)|heavy metal|radiation|air pollution|trauma|abuse|violence|poverty") &&
      !has("cessation|quit|stop(ping)?|reduc|prevent|control|treat|counsel|educat|awareness|intervention (to|for|on)|spray|vector|insecticid|bed.?net"),
    rare_outcome = has("\\brare\\b|cancer|carcinoma|leuk(a)?emia|lymphoma|mesothelioma|birth defect|congenital|anomal|motor neuron|\\bals\\b|dementia|decades|long latency"),
    existing_data = has("records|registry|register\\b|database|claims|charts|\\bnfhs\\b|\\bdhs\\b|national (family )?(health )?survey|secondary (data|analysis)|existing data|routine(ly collected)? data"),
    prospective = has("prospective"),
    individual = has("\\b(individuals?|patients?|persons?|people|men|women|children|mothers)\\b.{0,40}\\b(who|with|risk|more likely|odds)\\b"),
    determinants = grepl(.free_text_determinants_pattern, text, ignore.case = TRUE, perl = TRUE),
    population = grepl("\\b(city|cities|town|district|block|villages?|communit(y|ies)|slums?|urban|rural|wards?|schools?|colleges?|universit(y|ies)|households?|state|province|region)\\b",
                       text, ignore.case = TRUE, perl = TRUE)
  )
}

free_text_rules <- list(

  # Analysis of counts the user already has. Checked first, but only on phrases that
  # state analysis of existing data outright ("2x2 table", Mantel-Haenszel, SMR,
  # "analyze the counts I have"): words such as "vaccine efficacy" or "sensitivity"
  # alone also occur in planning text and must not be hijacked.
  root = list(
    # Planning logistics, named outright (a sample-size request that merely mentions dropouts is not matched).
    list(pattern = "randomi[sz]ation (list|schedule|sequence)|(generate|create|make) (a )?(random(i[sz]ation)? )?(allocation )?(list|sequence|schedule)|allocation (list|sequence|schedule)|block randomi[sz]ation|permuted.?block|(inflate|adjust|increase)\\w* (the )?sample size (for|to allow for) (attrition|dropouts?|drop.?out|non.?response|loss(es)? to follow.?up)",
         option_index = 11, confidence = "Medium"),
    list(pattern = "(calculate|compute|work out|convert|find|get)( the| an| my)? (effect size|cohen'?s? ?[dfhw]\\b)|effect size (from|calculator|converter)|\\bd from a t.?statistic|hazard ratio from (the )?median",
         option_index = 11, confidence = "Medium"),
    list(pattern = "probability proportional to size|\\bpps\\b|sampling frame|systematic sampl|\\bepi\\b.{0,20}(cluster|survey)|30\\s?(x|by|\\*)\\s?7|survey weights?|design weights?|sampling weights?|post.?stratif|inverse probability of selection|select(ion of)? (a |the )?(survey )?sample (from|of)",
         option_index = 11, confidence = "Medium"),
    list(pattern = "herd.?immunity|\\bseir\\b|\\bsir (model|epidemic)|\\br0\\b|basic reproduction number|epidemic model(l)?ing|coverage (is )?(needed|required) (to|for) (reach|achieve|stop|control)",
         option_index = 11, confidence = "Medium"),
    list(pattern = "secondary attack rate|food.?specific attack|attack rates? (table|by exposure|for each (food|exposure))|aberration (detection|alarm)|\\bears\\b.{0,20}(c[123]|aberration|surveillance)|\\bcusum\\b|outbreak (investigation|detection)|syndromic surveillance",
         option_index = 10, confidence = "Medium"),
    list(pattern = "(have|with) (the |some |my |our )?(summary )?(counts|numbers) (already|i|we|and)|analy[sz]e (the |my |our )?(counts|summary|data (i|we) (already )?(have|collected))|already (have|collected) (the )?(counts|data|numbers)|from (the )?(summary )?counts|\\b2\\s?x\\s?2 table|mantel.?haenszel|standardi[sz]ed mortality ratio|\\bsmr\\b|confidence interval (for|of) (a |the |an )?(proportion|mean|rate|incidence)",
         option_index = 10, confidence = "Medium"),
    # a case report or case series (not a self-controlled case series, not a trial's case report form)
    list(pattern = "(?<!controlled )(?<!controlled-)\\bcase.?series\\b|\\bcase report(?!\\s*form)|\\ba (rare )?case of\\b",
         option_index = 15, confidence = "High"),
    # mixed methods before qualitative: a mixed-methods description usually also says "qualitative"
    list(pattern = "mixed.?methods?|explanatory sequential|exploratory sequential|convergent (parallel )?design|multi.?method",
         option_index = 14, confidence = "High"),
    list(pattern = "qualitative|in-depth interview|\\bfgd\\b|focus group|thematic|phenomenolog|grounded theory|ethnograph",
         option_index = 6, confidence = "High"),
    list(pattern = "validity of|accuracy of|diagnostic (accuracy|test|study)|screening test|predictive value|\\bppv\\b|\\bnpv\\b|sensitivity|specificity|gold standard|index test|\\bauc\\b|\\broc\\b",
         option_index = 4, confidence = "High"),
    list(pattern = "agreement|reliability|reproducibility|inter-observer|interobserver|concordance|\\bkappa\\b|\\bicc\\b",
         option_index = 5, confidence = "High"),
    list(pattern = "develop a model|develop and validate|prognostic|risk score|nomogram|predict\\w*\\s+model",
         option_index = 3, confidence = "High"),
    # Checked before the estimation cues below per the algorithm doc's own
    # section 0.2 disambiguation rule: presence of a stated comparator (two
    # groups/arms, "compare", "between X and Y") governs even when an
    # estimation-sounding word like "proportion of" also appears in the same
    # sentence (e.g. "comparing the proportion of X between two groups").
    list(pattern = "meta.?analys|trial sequential|pooled (effect|estimate)",
         option_index = 7, confidence = "High"),
    list(pattern = "systematic review|scoping review|umbrella review|overview of (systematic )?reviews|evidence (gap )?map|meta.?synthesis|meta.?ethnograph|qualitative evidence synthesis|literature review|review of (the )?literature",
         option_index = 13, confidence = "High"),
    # Mendelian randomisation is a comparison (an exposure's effect), not the genetics branch below
    list(pattern = "mendelian randomi[sz]ation|genetic instruments?|genetic variants? as (an? )?(instrument|proxy|proxies)",
         option_index = 2, confidence = "High"),
    list(pattern = "\\blqas\\b|lot quality|\\bpilot\\b|feasibility|rare events?|\\banimal|\\bmice\\b|\\brats\\b|preclinical|psychometric|factor analysis|questionnaire development|\\bgwas\\b|genetic|genomic|genome.?wide|value of information|\\bevpi\\b",
         option_index = 9, confidence = "Medium"),
    list(pattern = "(?<!intracluster )(?<!intra-cluster )(?<!intraclass )(?<!intra-class )correlat(?!es\\s+of)|\\bregression\\b|\\bancova\\b|linear model",
         option_index = 8, confidence = "High"),
    list(pattern = "compar(e|ed|es|ing|ison)|dose.?finding|phase (i|ii|iii|1|2|3)\\b|multiplicity|multiple (primary )?(endpoints|comparisons)|interim analys|group.?sequential|bayesian|non.?inferior|equivalen|stepped.?wedge|cross.?over|case.?crossover|self.?controlled|\\bsccs\\b|nested case|case.?cohort|ecological study|case.?control|cases and controls|\\bcohorts?\\b|exposed (and|versus|vs\\.?) unexposed|\\bt-?tests?\\b|\\banova\\b|chi.?square|mann.?whitney|wilcoxon|\\blog.?rank|\\bhazard ratio|survival analysis|difference (in|of|between)|\\bversus\\b|\\bvs\\.?\\b|association between|\\brandomi[sz]e\\b|effect of|effectiveness of|efficacy of|impact of|randomi[sz]ed|allocated|\\btrial\\b|\\barm\\b|followed up|incidence of|developed over|cases and controls|case-control|non-inferior|equivalent|bioequivalence|between (two|2|three|3) (groups|arms)|interrupted time.?series|segmented regression|difference.?in.?differences?|regression discontinuity|natural experiment|quasi.?experiment|controlled before|pre.?post|before.?(and|&)?.?after",
         option_index = 2, confidence = "Medium"),
    # Descriptive research questions phrased by topic (knowledge-attitude-practice, awareness, utilization, pattern of ...) name no design;
    # with no comparison or follow-up words (the rule above wins when there are) they are surveys of a population. Determinants questions
    # are deliberately not routed here (see .free_text_determinants_pattern).
    list(pattern = .free_text_topic_pattern, option_index = 1, confidence = "Medium"),
    list(pattern = "prevalence of|estimate the|proportion of|magnitude of|assess the burden|mean level of|to determine the level|incidence rate of",
         option_index = 1, confidence = "High")
  ),

  planning_type = list(
    list(pattern = "effect size|cohen'?s? ?[dfhw]\\b|convert (an? )?(odds ratio|d|r)\\b|from a t.?statistic|standardi[sz]ed (mean )?difference|phi (from|coefficient)|hazard ratio from|median (survival )?to (hazard|mean)|mean and sd from",
         option_index = 6, confidence = "High"),
    list(pattern = "herd.?immunity|\\bseir\\b|\\bsir\\b|\\br0\\b|reproduction number|epidemic|vaccination coverage|coverage (needed|required)", option_index = 5, confidence = "High"),
    list(pattern = "weight|post.?stratif|raking|calibrat|effective sample size|design effect of the weights", option_index = 4, confidence = "High"),
    list(pattern = "sampling frame|\\bpps\\b|proportional to size|systematic|\\bepi\\b|30\\s?(x|by|\\*)\\s?7|random sample|select(ion of)? (a |the )?(survey )?sample|cluster", option_index = 3, confidence = "High"),
    list(pattern = "attrition|drop.?out|drop.?in|non.?response|loss(es)? to follow|non.?complian", option_index = 2, confidence = "High"),
    list(pattern = "random",                                                                   option_index = 1, confidence = "High")
  ),

  planning_epi_type = list(
    list(pattern = "growth rate|doubling|final (size|attack)|estimate r0|r0 from",     option_index = 3, confidence = "High"),
    list(pattern = "simulat|\\bseir\\b|\\bsir\\b|epidemic curve|peak|final size|infections averted", option_index = 2, confidence = "High"),
    list(pattern = "threshold|coverage|herd",                                          option_index = 1, confidence = "High")
  ),

  analyze_outbreak_type = list(
    list(pattern = "secondary|household contacts|contacts of",                         option_index = 3, confidence = "High"),
    list(pattern = "fatality|death",                                                   option_index = 4, confidence = "High"),
    list(pattern = "food|exposure|vehicle|risk ratio|which",                           option_index = 2, confidence = "High"),
    list(pattern = "attack rate",                                                      option_index = 1, confidence = "Medium")
  ),

  analyze_surv_type = list(
    list(pattern = "cusum|cumulative sum|poisson",                                     option_index = 2, confidence = "High"),
    list(pattern = "\\bears\\b|c[123]\\b|aberration|compare each day",                 option_index = 1, confidence = "Medium")
  ),

  planning_sel_type = list(
    list(pattern = "\\bepi\\b|30\\s?(x|by|\\*)\\s?7",                option_index = 4, confidence = "High"),
    list(pattern = "proportional to size|\\bpps\\b|cluster",        option_index = 3, confidence = "High"),
    list(pattern = "systematic|every (k|kth|k-th|nth|n-th)",        option_index = 2, confidence = "High"),
    list(pattern = "simple random|random sample",                    option_index = 1, confidence = "Medium")
  ),

  planning_weight_type = list(
    list(pattern = "effective sample size|kish|design effect",       option_index = 2, confidence = "Medium"),
    list(pattern = "weight|nonresponse|non.?response|post.?stratif", option_index = 1, confidence = "Medium")
  ),

  planning_rand_type = list(
    list(pattern = "strat|\\bsites?\\b|centre|center",   option_index = 2, confidence = "Medium"),
    list(pattern = "simple|unrestricted|coin",              option_index = 3, confidence = "Medium"),
    list(pattern = "block",                                 option_index = 1, confidence = "High")
  ),

  planning_attr_type = list(
    list(pattern = "drop.?in|drop.?out|non.?complian|cross.?over|crossover", option_index = 3, confidence = "Medium"),
    list(pattern = "each arm|per arm|differ\\w* (loss|attrition)|by arm",     option_index = 2, confidence = "Medium"),
    list(pattern = "attrition|non.?response|loss(es)? to follow|stages?",      option_index = 1, confidence = "High")
  ),

  analyze_type = list(
    list(pattern = "aberration|\\bears\\b|\\bcusum\\b|syndromic|series of (case )?counts|unusual rise|early warning", option_index = 12, confidence = "High"),
    list(pattern = "outbreak|attack rate|case.?fatality|food.?specific|secondary attack", option_index = 11, confidence = "High"),
    list(pattern = "mantel.?haenszel|stratif|confound",                              option_index = 2, confidence = "High"),
    list(pattern = "\\bsmr\\b|standardi[sz]ed|age.?adjusted|direct standardi|indirect standardi", option_index = 5, confidence = "High"),
    list(pattern = "vaccine (efficacy|effectiveness)|\\bve\\b",                       option_index = 7, confidence = "High"),
    list(pattern = "person.?(years|time)|incidence rate|rate ratio",                 option_index = 3, confidence = "High"),
    list(pattern = "mcnemar|\\bkappa\\b|agreement|chi.?square for trend|cochran.?armitage|paired", option_index = 4, confidence = "High"),
    list(pattern = "serial|parallel",                                                option_index = 9, confidence = "Medium"),
    list(pattern = "sensitivity|specificity|\\bppv\\b|\\bnpv\\b|predictive value",   option_index = 8, confidence = "High"),
    list(pattern = "confidence interval (for|of)",                                   option_index = 10, confidence = "Medium"),
    list(pattern = "two (proportions|means|groups)|difference (in|of|between) (two )?(proportions|means)", option_index = 6, confidence = "Medium"),
    list(pattern = "\\b2\\s?x\\s?2\\b|risk ratio|relative risk|odds ratio|risk difference", option_index = 1, confidence = "High")
  ),

  rel_type = list(
    list(pattern = "\\bcox\\b|time.to.event|survival",                      option_index = 6, confidence = "High"),
    list(pattern = "logistic|binary outcome",                              option_index = 3, confidence = "High"),
    list(pattern = "ordinal|proportional odds",                            option_index = 4, confidence = "High"),
    list(pattern = "poisson|count outcome|negative binomial",              option_index = 5, confidence = "High"),
    list(pattern = "linear|continuous outcome|\\bancova\\b|multiple regression", option_index = 2, confidence = "High"),
    list(pattern = "correlat|pearson|spearman|kendall",                    option_index = 1, confidence = "High")
  ),

  corr_type = list(
    list(pattern = "spearman|rank",                                        option_index = 2, confidence = "High"),
    list(pattern = "kendall",                                              option_index = 3, confidence = "High"),
    list(pattern = "point.?biserial",                                      option_index = 4, confidence = "High"),
    list(pattern = "pearson",                                              option_index = 1, confidence = "High")
  ),

  meta_type = list(
    list(pattern = "network",                                              option_index = 3, confidence = "High"),
    list(pattern = "trial sequential|information size|\\btsa\\b",           option_index = 2, confidence = "High"),
    list(pattern = "number of studies|how many studies",                   option_index = 1, confidence = "High")
  ),

  agree_scale = list(
    list(pattern = "cronbach|internal consistency",                        option_index = 5, confidence = "High"),
    list(pattern = "bland|limits of agreement",                            option_index = 3, confidence = "High"),
    list(pattern = "\\bccc\\b|concordance correlation",                     option_index = 4, confidence = "High"),
    list(pattern = "deming|passing.?bablok",                               option_index = 6, confidence = "High"),
    list(pattern = "\\bicc\\b|intraclass|continuous",                       option_index = 2, confidence = "High"),
    list(pattern = "kappa|categorical|present.{0,3}absent",                option_index = 1, confidence = "High")
  ),

  diag_type = list(
    list(pattern = "\\bauc\\b|\\broc\\b|area under",                         option_index = 6, confidence = "High"),
    list(pattern = "predictive value|\\bppv\\b|\\bnpv\\b",                   option_index = 5, confidence = "High"),
    list(pattern = "likelihood ratio",                                     option_index = 7, confidence = "High"),
    list(pattern = "diagnostic odds",                                      option_index = 8, confidence = "High"),
    list(pattern = "mrmc|multi.?reader",                                   option_index = 9, confidence = "High"),
    list(pattern = "precision|confidence interval|margin|estimate (the )?(sensitivity|specificity)", option_index = 1, confidence = "Medium")
  ),

  other_purpose = list(
    list(pattern = "\\blqas\\b|lot quality|survey|sampling|multistage",       option_index = 1, confidence = "Medium"),
    list(pattern = "scale|questionnaire|factor analysis|psychometric|\\bsem\\b|\\birt\\b", option_index = 2, confidence = "Medium"),
    list(pattern = "rare event|surveillance|zero events|rule of three",    option_index = 3, confidence = "Medium"),
    list(pattern = "animal|\\bmice\\b|\\brats\\b|preclinical",              option_index = 4, confidence = "High"),
    list(pattern = "pilot|feasibility",                                    option_index = 5, confidence = "High"),
    list(pattern = "value of information|\\bevpi\\b|\\bevsi\\b",             option_index = 6, confidence = "High"),
    list(pattern = "gwas|genetic|genomic|microarray",                      option_index = 7, confidence = "High")
  ),

  est_type = list(
    list(pattern = "proportion|prevalence",  option_index = 1, confidence = "High"),
    list(pattern = "\\bmean\\b|average",      option_index = 2, confidence = "High"),
    list(pattern = "incidence rate|rate of",  option_index = 3, confidence = "High"),
    list(pattern = "risk ratio|odds ratio|rate ratio", option_index = 4, confidence = "Medium"),
    # a topic question: a measured outcome ("levels", "score") is a mean; otherwise (smoking, use of, knowledge, practice ...) a proportion
    list(pattern = "\\blevels?\\b|\\bscores?\\b|\\bconcentrations?\\b", option_index = 2, confidence = "Medium"),
    list(pattern = .free_text_topic_pattern, option_index = 1, confidence = "Medium")
  ),

  ratio_type = list(
    list(pattern = "risk ratio|relative risk", option_index = 1, confidence = "High"),
    list(pattern = "odds ratio",               option_index = 2, confidence = "High"),
    list(pattern = "rate ratio",               option_index = 3, confidence = "High")
  ),

  allocation = list(
    # assigned by a programme, a policy or a law, and studied afterwards (a natural experiment); not when the text says randomised
    list(pattern = paste0("(?s)^(?!.*\\brandomi[sz]).*(natural experiment|(policy|programme|program|law|act|scheme|ban|tax|mandate|regulation|mission|campaign)\\b.{0,60}\\b",
                          "(introduc|implement|launch|roll.?out|enact|came into)|(introduc|implement|launch|roll.?out|enact)\\w*\\b.{0,40}\\b(policy|programme|program|law|scheme|ban|tax|mandate|regulation)|",
                          "(before and after|since) the (ban|policy|law|programme|program|scheme|mandate))"),
         option_index = 4, confidence = "Medium"),
    # assigned by the team without randomisation; before the next rule, whose "randomised" also matches "non-randomised"
    list(pattern = "non.?randomi[sz]ed|not (be )?randomi[sz]ed|without randomi[sz]ation|quasi.?experiment",
         option_index = 3, confidence = "High"),
    list(pattern = "\\brandomi[sz]e\\b|we (will )?(allocate|assign)\\b|randomi[sz]ed|allocated|assigned|\\btrial\\b|\\barm\\b|placebo|(?<!case)(?<!case-)(?<!case )cross.?over|stepped.?wedge|bioequivalen|non.?inferior|equivalen|multiplicity|interim|group.?sequential|bayesian|platform|basket|umbrella|phase (i|ii|2|1)\\b|dose.?finding|single.?arm",
         option_index = 1, confidence = "High"),
    list(pattern = "cohort|followed up|incidence of|developed over|cases and controls|case.?control|cross.?sectional|exposed (and|versus|vs\\.?|or) unexposed|observational|registry|retrospective|prospective|case.?crossover|self.?controlled|\\bsccs\\b|nested|case.?cohort|ecological|propensity|mendelian|genetic instrument",
         option_index = 2, confidence = "Medium")
  ),

  quasi_type = list(
    list(pattern = "interrupted time.?series|segmented regression|\\bits\\b|time.?series",           option_index = 1, confidence = "High"),
    list(pattern = "regression discontinuity|\\brdd\\b|cut.?off|threshold",                         option_index = 3, confidence = "High"),
    list(pattern = "difference.?in.?differences?|controlled before|comparison (group|district|area|village|block|state)s?|control (group|district|area|village|block)s?",
         option_index = 2, confidence = "High"),
    list(pattern = "pre.?post|pre.?test|before.?(and|&)?.?after|baseline and (end|follow)",           option_index = 4, confidence = "High")
  ),

  prepost_outcome = list(
    list(pattern = "\\bmean\\b|score|level of|blood pressure|weight|h(a)?emoglobin|\\bbmi\\b",         option_index = 1, confidence = "Medium"),
    list(pattern = "proportion|prevalence|percentage|practi[cs]e|uptake|coverage|yes.?no",           option_index = 2, confidence = "Medium")
  ),

  review_type = list(
    list(pattern = "scoping|evidence (gap )?map|mapping review",                                     option_index = 3, confidence = "High"),
    list(pattern = "umbrella|overview of (systematic )?reviews|review of (systematic )?reviews",      option_index = 5, confidence = "High"),
    list(pattern = "meta.?synthesis|meta.?ethnograph|qualitative (evidence )?synthesis|qualitative systematic", option_index = 6, confidence = "High"),
    list(pattern = "network",                                                                        option_index = 4, confidence = "High"),
    list(pattern = "narrative synthesis|without (a )?meta.?analysis|\\bswim\\b",                        option_index = 2, confidence = "High"),
    list(pattern = "meta.?analys|pool",                                                              option_index = 1, confidence = "High")
  ),

  qual_approach = list(
    list(pattern = "phenomenolog|lived experience",                                                  option_index = 1, confidence = "High"),
    list(pattern = "grounded theory|constant comparative|theoretical sampling",                     option_index = 2, confidence = "High"),
    list(pattern = "ethnograph|participant observation|field ?work",                                 option_index = 3, confidence = "High"),
    list(pattern = "case study",                                                                     option_index = 4, confidence = "High"),
    list(pattern = "thematic|qualitative descriptive|content analysis",                              option_index = 5, confidence = "High")
  ),

  mm_sequence = list(
    list(pattern = "explanatory",                                                                    option_index = 1, confidence = "High"),
    list(pattern = "exploratory|instrument development|develop (a |an )?(scale|questionnaire|tool)", option_index = 2, confidence = "High"),
    list(pattern = "convergent|parallel|concurrent|triangulat",                                      option_index = 3, confidence = "High"),
    list(pattern = "embedded|nested|process evaluation|within (a|the) trial",                        option_index = 4, confidence = "High")
  ),

  case_desc = list(
    list(pattern = "case.?series|series of",                                                         option_index = 2, confidence = "High"),
    list(pattern = "case report|a (rare )?case of|one patient|single patient",                       option_index = 1, confidence = "High")
  ),

  eco_time = list(
    list(pattern = "trend|over time|over (the )?(years|decades?)|time.?series|panel|longitudinal|\\b(19|20)\\d\\d\\s?(-|to)\\s?(19|20)\\d\\d\\b", option_index = 2, confidence = "High"),
    list(pattern = "cross.?sectional|single (year|period)|at one time|snapshot",                     option_index = 1, confidence = "High")
  ),

  exp_unit = list(
    # several eyes / lesions / patches per patient: both treatments in each patient first (split-face, fellow eye), then the same treatment for all of a patient's units
    list(pattern = "split.?(face|body|mouth|eye)|fellow eye|contralateral|one eye (per|in each|on each|for each)|(left|right) (eye|side|half)|each patient (gets?|receives?|has) both|both treatments in (each|every) patient",
         option_index = 8, confidence = "High"),
    list(pattern = "both eyes|each eye|two eyes|eyes per patient|per eye\\b|lesions? per (patient|person|subject)|patches? per (patient|person|subject)|multiple lesions|several lesions|teeth per (patient|person)|bilateral|several measurements per (patient|person|subject)|clustered within (patient|person|subject)",
         option_index = 7, confidence = "High"),
    list(pattern = "stepped.?wedge",                                         option_index = 4, confidence = "High"),
    list(pattern = "cross.?over",                                            option_index = 3, confidence = "High"),
    list(pattern = "n.?of.?1|single subject",                                option_index = 5, confidence = "High"),
    list(pattern = "cluster|villages?|schools?|wards?|\\bphcs?\\b|hospitals? (were|are) randomi|communities",
         option_index = 2, confidence = "High"),
    list(pattern = "individual(ly)?|patients|participants|subjects|volunteers|children were randomi|women were randomi|\\btrial\\b|randomi[sz]ed|bioequivalen|phase (i|ii|2|1)\\b|single.?arm",
         option_index = 1, confidence = "Medium")
  ),

  pu_outcome = list(
    list(pattern = "binary|yes.?no|event|healed|cured|response|proportion|prevalence|incidence|present or absent|odds",
         option_index = 2, confidence = "Medium"),
    list(pattern = "continuous|mean|score|pressure|thickness|acuity|measurement|diameter|size|level",
         option_index = 1, confidence = "Medium")
  ),

  exp_intent = list(
    list(pattern = "bioequivalen|pharmacokinetic",                           option_index = 4, confidence = "High"),
    list(pattern = "non.?inferior",                                          option_index = 2, confidence = "High"),
    list(pattern = "equivalen",                                              option_index = 3, confidence = "High"),
    list(pattern = "single.arm|phase (ii|2)\\b|simon",                      option_index = 5, confidence = "High"),
    list(pattern = "interim|group.?sequential",                              option_index = 6, confidence = "High"),
    list(pattern = "multiplicity|co.?primary|several primary",               option_index = 7, confidence = "Medium"),
    list(pattern = "subgroup|interaction",                                   option_index = 8, confidence = "Medium"),
    list(pattern = "bayes",                                                  option_index = 9, confidence = "Medium"),
    list(pattern = "dose.?finding|phase (i|1)\\b|3\\+3|continual reassessment",   option_index = 10, confidence = "High"),
    list(pattern = "platform|basket|umbrella",                               option_index = 11, confidence = "High"),
    list(pattern = "superior|better|compar|differ|versus|\\bvs\\b|time to|hazard|survival|reduc|improv|effect of",          option_index = 1, confidence = "Medium")
  ),

  selection_basis = list(
    list(pattern = "mendelian randomi[sz]ation|genetic instruments?|genetic variants? as (an? )?(instrument|proxy|proxies)", option_index = 11, confidence = "High"),
    list(pattern = "nested case",                                         option_index = 4, confidence = "High"),
    list(pattern = "case.?cohort",                                        option_index = 5, confidence = "High"),
    list(pattern = "case.?crossover",                                     option_index = 6, confidence = "High"),
    list(pattern = "self.?controlled case|\\bsccs\\b",                      option_index = 7, confidence = "High"),
    list(pattern = "ecological",                                          option_index = 8, confidence = "High"),
    list(pattern = "propensity",                                          option_index = 9, confidence = "High"),
    list(pattern = "time.?varying exposure",                              option_index = 10, confidence = "High"),
    list(pattern = "cases and controls|case.?control|patients with .* and without",
         option_index = 2, confidence = "High"),
    list(pattern = "cohort|followed up|incidence of|developed over|exposed (and|versus|vs\\.?|or) unexposed|prospective|retrospective|exposure",
         option_index = 1, confidence = "Medium"),
    list(pattern = "cross.?sectional|both.{0,20}same time|simultaneous",
         option_index = 3, confidence = "Medium")
  ),

  cohort_outcome = list(
    list(pattern = "time to|survival|hazard|kaplan|log.?rank|\\bcox\\b",              option_index = 4, confidence = "High"),
    # dose-response (4 Nov 2026): ordered levels of exposure, or exposure measured on a scale
    list(pattern = "dose.?response|trend (in|across)|ordered (levels|categories|groups)|graded exposure|levels of exposure|tertiles?|quartiles?|quintiles?",
         option_index = 6, confidence = "Medium"),
    list(pattern = "per unit (of|increase)|per (1|one|10|ten)[- ]?(unit|mg|year|point)|continuous exposure|exposure measured",
         option_index = 7, confidence = "Medium"),
    list(pattern = "per person|person.?(years|time|days)|incidence rate|rate ratio",   option_index = 3, confidence = "High"),
    list(pattern = "ordinal|likert|\\bgrade\\b|\\bstage\\b",                          option_index = 5, confidence = "High"),
    list(pattern = "\\bmean\\b|median|interquartile|\\biqr\\b|average|continuous|blood pressure|\\bbp\\b|haemoglobin|hemoglobin|\\bhb\\b|\\bbmi\\b|weight|\\bscore\\b|concentration|\\blevels?\\b|difference in",
         option_index = 2, confidence = "Medium"),
    list(pattern = "relative risk|risk ratio|\\brr\\b|incidence of|risk of|developed|occurrence|cumulative incidence|binary|proportion",
         option_index = 1, confidence = "Medium")
  ),

  cc_exposure_type = list(
    # ordered or categorical exposure (4 Nov 2026), before the measurement and yes/no cues
    list(pattern = "dose.?response|trend (in|across)|ordered (levels|categories|groups)|never.{0,12}former.{0,12}current|pack.?years? (groups|categories)|tertiles?|quartiles?|quintiles?",
         option_index = 4, confidence = "Medium"),
    list(pattern = "(three|3|four|4|several) (or more )?(unordered )?(categories|types|groups) of exposure|categories of exposure|type of (occupation|exposure)",
         option_index = 3, confidence = "Medium"),
    list(pattern = "\\bmean\\b|median|interquartile|\\biqr\\b|average|continuous|concentration|\\bserum\\b|\\blevels?\\b|difference in|haemoglobin|hemoglobin|\\bbmi\\b|blood pressure|\\bscore\\b",
         option_index = 2, confidence = "Medium"),
    list(pattern = "odds ratio|matched|unmatched|exposed|exposure|smok|\\buse\\b|history|yes.?no|binary|present|absent|\\bever\\b",
         option_index = 1, confidence = "Medium")
  ),

  cc_cont_matching = list(
    list(pattern = "1:[2-9m]|1-to-[2-9]|(two|three|four|five|several|multiple|2|3|4|5) controls (per|for each|to each) case|controls per case",
         option_index = 4, confidence = "High"),
    list(pattern = "individually matched|1:1|1-to-1|paired",                 option_index = 2, confidence = "High"),
    list(pattern = "frequency.matched|frequency matched",                  option_index = 3, confidence = "High"),
    list(pattern = "unmatched|no matching|not matched",                    option_index = 1, confidence = "High")
  ),

  cc_matching = list(
    list(pattern = "individually matched|1:1|1:m|1-to-1",
         option_index = 2, confidence = "High"),
    list(pattern = "frequency.matched|frequency matched",
         option_index = 3, confidence = "High"),
    list(pattern = "unmatched|no matching|not matched",
         option_index = 1, confidence = "High")
  ),

  outcome_type = list(
    list(pattern = "time to|survival|recurrence.free|time-to-event",
         option_index = 6, confidence = "High"),
    list(pattern = "ordinal|likert|\\bstage\\b|\\bgrade\\b",
         option_index = 4, confidence = "High"),
    list(pattern = "count\\b|episodes per|person-time|person-years",
         option_index = 5, confidence = "Medium"),
    list(pattern = "binary|cured|cure rate|response rate|prevalence|odds ratio|relative risk|risk ratio|positive.{0,10}negative|dichotomous|proportion (of|with|who|cured|vaccinated|immuni[sz]ed)",
         option_index = 2, confidence = "Medium"),
    list(pattern = "categorical|blood group|diagnosis categor",
         option_index = 3, confidence = "Medium"),
    list(pattern = "continuous|\\bmean\\b|median|interquartile|\\biqr\\b|length of stay|average|\\bscore\\b|\\bbp\\b|\\bhb\\b|\\bbmi\\b|blood pressure|haemoglobin|hemoglobin|weight|cholesterol|glucose|concentration|\\bfev1?\\b",
         option_index = 1, confidence = "Medium")
  ),

  cont_summary = list(
    list(pattern = "median|interquartile|\\biqr\\b|skewed|non.?normal",                                    option_index = 2, confidence = "High"),
    list(pattern = "\\bmean\\b|average|standard deviation|\\bsd\\b|normally distributed",                  option_index = 1, confidence = "Medium")
  ),

  groups_count = list(
    list(pattern = "3 or more group|three or more group|(three|3|four|4|several|multiple|k) (groups|arms|treatments|drugs)|\\banova\\b",
         option_index = 3, confidence = "Medium"),
    list(pattern = "(2|two) (independent |separate )?(groups|arms|treatments|drugs|cohorts|samples|populations|means|proportions)|\\bversus\\b|\\bvs\\b",
         option_index = 2, confidence = "Medium"),
    list(pattern = "reference value|known value|historical value",
         option_index = 1, confidence = "Medium")
  ),

  dependence_q = list(
    list(pattern = "paired|before.after|before-after|matched pairs|same subjects",
         option_index = 2, confidence = "Medium"),
    list(pattern = "independent|two independent groups|separate groups",
         option_index = 1, confidence = "Medium")
  )
)

#' Walk home_design_tree.R's node registry from root using free-text keyword
#' rules, exactly mirroring design_wizard_server()'s own manual-click
#' traversal (design_wizard.R's observeEvent(input$design_wizard_next, ...)):
#' apply any opt$set flags, append a trace entry, resolve next_id (string or
#' function(flags)). Stops the instant a node has no rule table or no rule
#' matches -- an honest "couldn't infer further, please continue manually"
#' degrade, never a guess.
#' @noRd
# The guide's state after a fixed sequence of answers from the root (option indices), as if they had been clicked: used for the routes a
# user picks for an ambiguous research question. `flags` are kept (e.g. determinants, population).
.walk_answers <- function(answers, flags = list(), nodes = design_nodes) {
  node_id <- "root"; trace <- list()
  for (idx in answers) {
    node <- nodes[[node_id]]
    if (isTRUE(node$terminal)) break
    opt <- node$options[[idx]]
    if (!is.null(opt$set)) for (nm in names(opt$set)) flags[[nm]] <- opt$set[[nm]]
    trace <- c(trace, list(list(question = node$question, answer = opt$label)))
    node_id <- if (is.function(opt$next_id)) opt$next_id(flags) else opt$next_id
  }
  list(node_id = node_id, trace = trace, flags = flags)
}

# The words a rule matched, as shown in the guide's trail: trimmed, at most 60 characters.
.free_text_words <- function(w) {
  if (!length(w)) return(NULL)
  w <- trimws(gsub("\\s+", " ", w))
  if (nchar(w) > 60) w <- paste0(substr(w, 1, 57), "...")
  w
}

# Questions where a description can state two answers outright. Each cue is deliberately narrow (a design named, not a word such as
# "followed up" that trials share): when cues of two answers both occur, the guide asks.
.free_text_conflicts <- list(
  allocation = list(
    list(option_index = 1, pattern = "(?<!non-)(?<!non )(?<!not )(?<!not be )\\brandomi[sz](ed|e)\\b|\\brandomly (allocated|assigned)\\b"),
    list(option_index = 2, pattern = "\\bcohort study\\b|\\bcase.?control\\b|\\bcross.?sectional\\b|\\bregistry\\b|\\bobservational\\b|\\bsecondary (data|analysis)\\b")
  )
)

.free_text_conflict <- function(node_id, text) {
  cues <- .free_text_conflicts[[node_id]]
  if (is.null(cues)) return(NULL)
  hit <- Filter(function(cue) grepl(cue$pattern, text, ignore.case = TRUE, perl = TRUE), cues)
  if (length(unique(vapply(hit, function(cue) cue$option_index, numeric(1)))) < 2) return(NULL)
  list(node_id = node_id,
       words = vapply(hit, function(cue) .free_text_words(regmatches(text, regexpr(cue$pattern, text, ignore.case = TRUE, perl = TRUE))), ""),
       options = vapply(hit, function(cue) cue$option_index, numeric(1)))
}

# Warnings for the guide (FIND-19): shown with the trail; the route is never changed by them. Each names what in the description
# raised it and what to check.
.free_text_warnings <- function(flags, trace, nodes = design_nodes) {
  answers <- vapply(trace, function(t) t$answer, "")
  said <- function(node, i) nodes[[node]]$options[[i]]$label %in% answers
  out <- character()
  if (isTRUE(flags$harmful) && said("allocation", 1))
    out <- c(out, paste("The description names an exposure that harms people, and the guide took it as assigned by the study team.",
                        "Assigning people to a harmful exposure is not ethical; if you are studying people who already have it, choose",
                        "\"I only observe what happened naturally\" instead. If the team assigns a treatment or prevention for it, ignore this."))
  if (isTRUE(flags$existing_data) && said("allocation", 1))
    out <- c(out, paste("The description mentions data that already exist (records, a registry or a survey), and the guide took the",
                        "intervention as assigned by the study team. Existing data are observational: check the answer to \"Who determines who",
                        "receives the exposure\"."))
  if (isTRUE(flags$existing_data) && isTRUE(flags$prospective))
    out <- c(out, paste("The description says prospective and also mentions existing records. A cohort assembled from records that already",
                        "exist is retrospective (historical): the sample-size calculation is the same, but the follow-up is what the records hold."))
  if (isTRUE(flags$rare_outcome) && said("selection_basis", 1))
    out <- c(out, paste("The outcome looks rare or slow to develop, and the route is a cohort. A cohort then needs many people or many years;",
                        "a case-control or nested case-control study usually needs far fewer (selected on their outcome)."))
  if (isTRUE(flags$individual) && said("selection_basis", 8))
    out <- c(out, paste("The design is ecological (group-level data), but the description speaks of individuals. Group data cannot show",
                        "which individuals have the outcome (the ecological fallacy): use individual data, or phrase the question about the groups."))
  out
}

walk_free_text <- function(text, nodes = design_nodes) {
  node_id <- "root"
  trace <- list()
  flags <- list()

  if (is.null(text) || !nzchar(trimws(text))) {
    return(list(node_id = node_id, trace = trace, flags = flags, reached_terminal = FALSE))
  }

  repeat {
    node <- nodes[[node_id]]
    if (isTRUE(node$terminal)) break

    rule_set <- free_text_rules[[node_id]]
    if (is.null(rule_set)) break

    # a description that fits two answers of this question outright: stop and ask instead of picking one (FIND-12, FIND-18)
    conflict <- .free_text_conflict(node_id, text)
    if (!is.null(conflict)) { flags$conflict <- conflict; break }

    matched <- NULL
    for (r in rule_set) {
      if (grepl(r$pattern, text, ignore.case = TRUE, perl = TRUE)) {
        matched <- r
        break
      }
    }
    if (is.null(matched)) break
    words <- regmatches(text, regexpr(matched$pattern, text, ignore.case = TRUE, perl = TRUE))

    opt <- node$options[[matched$option_index]]
    if (!is.null(opt$set)) for (nm in names(opt$set)) flags[[nm]] <- opt$set[[nm]]

    trace <- c(trace, list(list(question = node$question, answer = opt$label,
                                 confidence = matched$confidence, words = .free_text_words(words))))
    node_id <- if (is.function(opt$next_id)) opt$next_id(flags) else opt$next_id
  }

  # flags read from the whole text (they never override a flag the answers set)
  for (nm in names(tf <- .free_text_flags(text))) if (isTRUE(tf[[nm]]) && is.null(flags[[nm]])) flags[[nm]] <- TRUE
  # a determinants question that named no design: the guide shows the candidate designs instead of choosing one
  if (length(trace) == 0 && isTRUE(flags$determinants)) flags$ambiguous <- "determinants"
  flags$warnings <- .free_text_warnings(flags, trace, nodes)
  list(node_id = node_id, trace = trace, flags = flags,
       reached_terminal = isTRUE(nodes[[node_id]]$terminal))
}
