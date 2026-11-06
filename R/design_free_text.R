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
  list(
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
    list(pattern = "qualitative|in-depth interview|\\bfgd\\b|focus group|thematic",
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
    list(pattern = "meta.?analys|systematic review|trial sequential|pooled (effect|estimate)",
         option_index = 7, confidence = "High"),
    list(pattern = "\\blqas\\b|lot quality|\\bpilot\\b|feasibility|rare events?|\\banimal|\\bmice\\b|\\brats\\b|preclinical|psychometric|factor analysis|questionnaire development|\\bgwas\\b|genetic|genomic|genome.?wide|value of information|\\bevpi\\b",
         option_index = 9, confidence = "Medium"),
    list(pattern = "(?<!intracluster )(?<!intra-cluster )(?<!intraclass )(?<!intra-class )correlat(?!es\\s+of)|\\bregression\\b|\\bancova\\b|linear model",
         option_index = 8, confidence = "High"),
    list(pattern = "compar(e|ed|es|ing|ison)|dose.?finding|phase (i|ii|iii|1|2|3)\\b|multiplicity|multiple (primary )?(endpoints|comparisons)|interim analys|group.?sequential|bayesian|non.?inferior|equivalen|stepped.?wedge|cross.?over|case.?crossover|self.?controlled|\\bsccs\\b|nested case|case.?cohort|ecological study|case.?control|cases and controls|\\bcohorts?\\b|exposed (and|versus|vs\\.?) unexposed|\\bt-?tests?\\b|\\banova\\b|chi.?square|mann.?whitney|wilcoxon|\\blog.?rank|\\bhazard ratio|survival analysis|difference (in|of|between)|\\bversus\\b|\\bvs\\.?\\b|association between|effect of|efficacy of|impact of|randomi[sz]ed|allocated|\\btrial\\b|\\barm\\b|followed up|incidence of|developed over|cases and controls|case-control|non-inferior|equivalent|bioequivalence|between (two|2|three|3) (groups|arms)",
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
    list(pattern = "randomi[sz]ed|allocated|assigned|\\btrial\\b|\\barm\\b|placebo|(?<!case)(?<!case-)(?<!case )cross.?over|stepped.?wedge|bioequivalen|non.?inferior|equivalen|multiplicity|interim|group.?sequential|bayesian|platform|basket|umbrella|phase (i|ii|2|1)\\b|dose.?finding|single.?arm",
         option_index = 1, confidence = "High"),
    list(pattern = "cohort|followed up|incidence of|developed over|cases and controls|case.?control|cross.?sectional|exposed (and|versus|vs\\.?|or) unexposed|observational|registry|retrospective|prospective|case.?crossover|self.?controlled|\\bsccs\\b|nested|case.?cohort|ecological|propensity",
         option_index = 2, confidence = "Medium")
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

    matched <- NULL
    for (r in rule_set) {
      if (grepl(r$pattern, text, ignore.case = TRUE, perl = TRUE)) {
        matched <- r
        break
      }
    }
    if (is.null(matched)) break

    opt <- node$options[[matched$option_index]]
    if (!is.null(opt$set)) for (nm in names(opt$set)) flags[[nm]] <- opt$set[[nm]]

    trace <- c(trace, list(list(question = node$question, answer = opt$label,
                                 confidence = matched$confidence)))
    node_id <- if (is.function(opt$next_id)) opt$next_id(flags) else opt$next_id
  }

  # flags read from the whole text (they never override a flag the answers set)
  for (nm in names(tf <- .free_text_flags(text))) if (isTRUE(tf[[nm]]) && is.null(flags[[nm]])) flags[[nm]] <- TRUE
  # a determinants question that named no design: the guide shows the candidate designs instead of choosing one
  if (length(trace) == 0 && isTRUE(flags$determinants)) flags$ambiguous <- "determinants"
  list(node_id = node_id, trace = trace, flags = flags,
       reached_terminal = isTRUE(nodes[[node_id]]$terminal))
}
