# Glossary of the terms the calculators use (owner's request of 2 Nov 2026: "an information toggle / hover-over for words like phi").
# One list, used for the small (i) beside a term in a calculator (info_tip(), mod_shared_info.R) and for the Glossary page under
# "Find a calculator". Each entry: label (as shown), short (one or two sentences, shown in the popover), long (a fuller plain-
# language explanation for the Glossary page), formula (plain text, optional) and source (optional).
#
# The definitions are standard textbook ones, written for a reader who is not a statistician. A `source` is given only where a
# specific convention or formula comes from a particular work; Cohen's conventions are attributed to Cohen (1988), whose book was
# not read in this session (the formulas are checked against the pwr package). Nothing here is a claim about a particular study.

glossary <- list(
  alpha = list(
    label = "Significance level (alpha)",
    short = "The chance you accept of declaring a difference when there is none (a false alarm). Usually 0.05.",
    long = paste("The probability of a false-positive result (a type I error) that you are willing to accept. 0.05 means 1 chance in 20.",
                 "A smaller alpha needs a larger sample. 'Two-sided' splits alpha between the two directions a difference could go."),
    formula = "Confidence level = 1 - alpha"),
  power = list(
    label = "Power",
    short = "The chance that the study finds a difference of the size you specify, if it really exists. Usually 0.80 or 0.90.",
    long = paste("1 - beta, where beta is the probability of missing a true difference of the planned size (a type II error).",
                 "More power needs a larger sample."),
    formula = "Power = 1 - beta"),
  confidence_level = list(
    label = "Confidence level",
    short = "How often an interval built this way would contain the true value if the study were repeated. Usually 95%.",
    long = "The interval's long-run coverage: with 95%, about 95 of 100 repeated studies would give an interval that contains the true value."),
  effect_size = list(
    label = "Effect size",
    short = "How big the difference or association is, on a scale that does not depend on the units: it is what a sample-size calculation is built around.",
    long = paste("A standardized measure of how large an effect is (Cohen's d, f, h, w, an odds ratio, a hazard ratio ...). The larger the effect",
                 "you want to detect, the smaller the sample needed. Use the Effect Size tab to work one out from means, proportions or test statistics.")),
  cohens_d = list(
    label = "Cohen's d",
    short = "The difference between two means in units of the standard deviation. 0.2 small, 0.5 medium, 0.8 large (Cohen's conventions).",
    long = paste("(mean 1 - mean 2) / pooled SD. A d of 0.5 means the group means are half a standard deviation apart. Cohen suggested",
                 "0.2, 0.5 and 0.8 as small, medium and large only for use when nothing better is known; they are not thresholds."),
    formula = "d = (mean1 - mean2) / pooled SD", source = "Cohen J. Statistical Power Analysis for the Behavioral Sciences, 2nd ed. 1988."),
  hedges_g = list(
    label = "Hedges' g",
    short = "Cohen's d with a small correction for the upward bias it has in small samples.",
    long = "g = d x J, where J is slightly below 1 and approaches 1 as the groups get larger; with more than about 20 per group g and d are almost the same.",
    formula = "g = d x J(df), df = n1 + n2 - 2", source = "Hedges LV. J Educ Stat 1981;6:107-128 (not read; checked by simulation)."),
  cohens_f = list(
    label = "Cohen's f",
    short = "The spread of the group means divided by the within-group SD, for three or more groups. 0.10 small, 0.25 medium, 0.40 large.",
    long = paste("f = SD of the group means / common SD within groups; f squared = eta-squared / (1 - eta-squared). For two groups f = d / 2.",
                 "It is the effect size that ANOVA, Kruskal-Wallis and repeated-measures sample-size calculations ask for."),
    formula = "f = sd(means) / sd(within)", source = "Cohen 1988."),
  cohens_h = list(
    label = "Cohen's h",
    short = "The difference between two proportions on the arcsine scale, which makes proportions near 0 or 1 comparable. 0.2 small, 0.5 medium, 0.8 large.",
    long = "h = 2 asin(sqrt(p1)) - 2 asin(sqrt(p2)). Used by the proportion calculators because the same difference of 0.1 matters more near 0 than near 0.5.",
    formula = "h = 2 asin(sqrt(p1)) - 2 asin(sqrt(p2))", source = "Cohen 1988."),
  cohens_w = list(
    label = "Cohen's w",
    short = "The effect size for a chi-square test: how far the observed proportions are from those expected, overall. 0.1 small, 0.3 medium, 0.5 large.",
    long = "w = sqrt(chi-square / N). For a 2 x 2 table w equals phi. Cramer's V rescales it by the table's size so tables of different shapes can be compared.",
    formula = "w = sqrt(chi-square / N) = sqrt(sum (p1 - p0)^2 / p0)", source = "Cohen 1988."),
  eta2 = list(
    label = "Eta-squared",
    short = "The share of the total variation in the outcome that group membership explains (0 to 1).",
    long = "SS between groups / SS total. Converts to Cohen's f by f = sqrt(eta2 / (1 - eta2)). Partial eta-squared is the same idea after removing other factors.",
    formula = "eta2 = SS_between / SS_total"),
  phi = list(
    label = "phi (correlation of paired exposures)",
    short = "The correlation between two yes/no variables. In a matched case-control study: how alike the exposure of a case and its matched control tend to be (0 = unrelated).",
    long = paste("For two yes/no variables laid out as a 2 x 2 table (a, b, c, d), phi = (ad - bc) / sqrt((a+b)(c+d)(a+c)(b+d)). In a matched case-control",
                 "study phi is the correlation between the exposure of a case and the exposure of the control matched to it; it comes from a table of",
                 "matched pairs in a pilot or published study. If unknown, Dupont (1988) suggests 0.2. A larger phi means matching helps more."),
    formula = "phi = (ad - bc) / sqrt((a+b)(c+d)(a+c)(b+d))",
    source = "Dupont WD. Biometrics 1988;44:1157-68 (the app's matched case-control formula)."),
  odds_ratio = list(
    label = "Odds ratio (OR)",
    short = "How many times higher the odds of the outcome (or exposure) are in one group than in the other. 1 = no difference.",
    long = paste("Odds = p / (1 - p). OR = odds in group 1 / odds in group 0. It approximates the risk ratio when the outcome is rare. In a case-control study",
                 "it compares the odds of exposure in cases with the odds in controls."),
    formula = "OR = [p1 / (1 - p1)] / [p0 / (1 - p0)]"),
  risk_ratio = list(
    label = "Risk (prevalence) ratio, relative risk",
    short = "The risk of the outcome in the exposed divided by the risk in the unexposed. 1 = no difference.",
    long = "RR = p1 / p0, using the proportion with the outcome in each group (the risk in a cohort or trial, the prevalence in a cross-sectional study).",
    formula = "RR = p1 / p0"),
  risk_difference = list(
    label = "Risk difference",
    short = "The absolute difference between the two proportions, p1 - p0.",
    long = "Its reciprocal is the number needed to treat (or to harm). It is the natural scale for an absolute effect on a population.",
    formula = "RD = p1 - p0"),
  nnt = list(
    label = "Number needed to treat (NNT)",
    short = "How many people must be treated for one extra person to benefit, 1 / |risk difference|.",
    long = "When the difference is harmful it is the number needed to harm. It depends on the baseline risk, so it differs between populations.",
    formula = "NNT = 1 / |p1 - p0|"),
  hazard_ratio = list(
    label = "Hazard ratio (HR)",
    short = "The ratio of the event rates (hazards) in two groups at any moment of follow-up. Below 1 favours the first group.",
    long = paste("Assumes the ratio stays the same throughout follow-up (proportional hazards). With exponential survival the hazard is log(2) / median,",
                 "so HR = median in the control arm / median in the experimental arm; from event probabilities, HR = log(1 - pE) / log(1 - pC)."),
    formula = "HR = log(S_e) / log(S_c)"),
  rate_ratio = list(
    label = "Rate ratio",
    short = "The incidence rate (events per person-time) in one group divided by that in the other.",
    long = "Uses person-time, so groups followed for different lengths can be compared. 1 = no difference.",
    formula = "RR_rate = (events1 / time1) / (events0 / time0)"),
  person_time = list(
    label = "Person-time",
    short = "The total follow-up of all people, e.g. person-years: 10 people followed for 2 years = 20 person-years.",
    long = "The denominator of an incidence rate. People who leave the study early contribute only the time until they leave."),
  sd_variance = list(
    label = "Standard deviation and variance",
    short = "The SD is the typical distance of a measurement from the mean; the variance is the SD squared.",
    long = "A calculator that asks for an SD can be given the variance instead: SD = sqrt(variance). Take care not to enter one where the other is wanted.",
    formula = "variance = SD^2"),
  pooled_sd = list(
    label = "Pooled (common) standard deviation",
    short = "One SD that stands for both groups, assuming they vary equally; a weighted average of the two group SDs.",
    long = "With group sizes: sqrt(((n1 - 1) sd1^2 + (n2 - 1) sd2^2) / (n1 + n2 - 2)). Without them, equal sizes are assumed: sqrt((sd1^2 + sd2^2) / 2).",
    formula = "sp = sqrt(((n1-1) sd1^2 + (n2-1) sd2^2) / (n1+n2-2))"),
  paired_dz = list(
    label = "d for paired data (d_z)",
    short = "The mean of the before-after (or matched) differences divided by the SD of those differences.",
    long = "The SD of the differences depends on how strongly the two measurements are correlated: SD_diff^2 = sd1^2 + sd2^2 - 2 r sd1 sd2. The stronger the correlation, the smaller SD_diff and the larger d_z.",
    formula = "d_z = mean difference / SD of differences"),
  correlation = list(
    label = "Correlation (r)",
    short = "How closely two measurements move together, from -1 to +1. 0 = no linear relation. 0.1 small, 0.3 medium, 0.5 large (Cohen).",
    long = "r squared is the share of the variation in one variable that the other accounts for. For two groups, d and r convert into each other.",
    source = "Cohen 1988."),
  icc = list(
    label = "Intracluster (intraclass) correlation (ICC)",
    short = "How similar people in the same cluster (village, school, clinic) are, compared with people in different clusters. 0 = not at all.",
    long = "The larger it is, the less new information each extra person in a cluster adds, so more people are needed (see design effect). Typical values in community studies are small, 0.01 to 0.1, but vary a lot."),
  deff = list(
    label = "Design effect (DEFF)",
    short = "The factor by which cluster sampling inflates the sample size needed compared with simple random sampling.",
    long = "DEFF = 1 + (m - 1) x ICC, for m people per cluster. A DEFF of 2 means twice as many people are needed.",
    formula = "DEFF = 1 + (m - 1) ICC"),
  allocation_ratio = list(
    label = "Allocation ratio",
    short = "The size of one group relative to the other, e.g. 2 means group 2 has twice as many as group 1. 1 = equal groups.",
    long = "Equal groups need the fewest people in total for a given power; unequal groups are chosen for cost or for ethical reasons."),
  p0_controls = list(
    label = "Exposure among controls (p0)",
    short = "The proportion of controls who were exposed: the exposure you expect in people without the disease.",
    long = "Taken from the literature or a pilot study. With the odds ratio (or the proportion of cases exposed) it defines the effect to detect."),
  nonresponse = list(
    label = "Non-response / loss to follow-up",
    short = "The share of those enrolled you expect not to give usable data. Enrol n / (1 - r), not n x (1 + r).",
    long = "With 20% loss, 100 analyzable people need 125 enrolled, not 120. Inflating restores the number, not the bias if those lost differ from those who stay.",
    formula = "n_enrolled = n / (1 - r)"),
  median_iqr = list(
    label = "Median and interquartile range (IQR)",
    short = "The middle value, and the range holding the middle half of the values (first to third quartile). Used for skewed data.",
    long = paste("To plan with them, estimate a mean and SD: mean = (q1 + median + q3) / 3 and SD = IQR / about 1.35 (more exactly with the sample size).",
                 "Both assume roughly normal data; for clearly skewed data a rank-based test is the alternative."),
    source = "Wan X, Wang W, Liu J, Tong T. BMC Med Res Methodol 2014;14:135."),
  sensitivity = list(
    label = "Sensitivity",
    short = "Of the people who have the disease, the proportion the test correctly calls positive.",
    long = "Estimated only from people with the disease, so the number of diseased people, not the total, decides its precision."),
  specificity = list(
    label = "Specificity",
    short = "Of the people without the disease, the proportion the test correctly calls negative.",
    long = "Estimated only from people without the disease."),
  prevalence = list(
    label = "Prevalence",
    short = "The proportion of a population that has the condition at a given time.",
    long = "For a prevalence survey the sample size depends on the prevalence you expect: use 50% if unknown, which gives the largest sample."),
  absolute_relative = list(
    label = "Absolute and relative precision",
    short = "Absolute: the interval is estimate +/- d. Relative: estimate +/- a fraction of the estimate (d = epsilon x estimate).",
    long = "Relative precision suits small proportions and rates, where a fixed d would be too crude. A relative precision above 20% gives a wide interval."),
  kappa = list(
    label = "Kappa",
    short = "Agreement between two raters beyond what chance alone would give. 1 = perfect, 0 = chance level.",
    long = "Kappa depends on how common each category is, so the same percentage agreement can give very different kappas."),
  one_two_sided = list(
    label = "One-sided and two-sided tests",
    short = "A two-sided test detects a difference in either direction; a one-sided test only the direction you specified in advance.",
    long = "A one-sided test needs a smaller sample but cannot detect an effect in the opposite direction; two-sided is the usual default."),
  matched_pairs = list(
    label = "Matched pairs",
    short = "Each case is matched to one or more controls on factors such as age and sex, and the analysis uses the pairs.",
    long = "Matching removes the effect of the matching factors but needs a matched analysis; the sample-size calculation needs phi.")
)

# The entry for a term; stops for a term that is not defined, so a typo in a calculator fails a test rather than shows nothing.
glossary_entry <- function(term) {
  e <- glossary[[term]]
  if (is.null(e)) stop(sprintf("No glossary entry for '%s'.", term), call. = FALSE)
  e
}
