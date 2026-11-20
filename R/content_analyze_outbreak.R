# Metadata for the Analyze: Outbreak Measures module (ROADMAP Track B4, item 20): formula text, plain-language
# explanation, worked example and citation per design. Content is data, rendered generically by
# mod_analyze_outbreak.R.

.outbreak_citation <- paste(
  "Attack rate, secondary attack rate and case fatality are proportions, so the confidence intervals are the proportion",
  "intervals of this app (Wilson, Clopper-Pearson, Agresti-Coull, Jeffreys, mid-P, Wald), each verified against epiR, binom.test",
  "and prop.test. The exposure table uses the 2x2 cohort measures of this app (Katz risk-ratio interval, Fisher's exact test).",
  "The definitions follow the usual field-epidemiology usage, for example Centers for Disease Control and Prevention. Principles",
  "of Epidemiology in Public Health Practice, 3rd ed.; 2012 (Lesson 3; the manual exists, its text was not re-read for this",
  "tool). Nothing here is new methodology; the original sources of each formula are cited on the 2x2 and confidence-interval tools."
)

analyze_outbreak_content <- list(
  attack = list(
    title = "Attack rate",
    formula_latex = "$$\\text{attack rate}=\\frac{\\text{cases}}{\\text{population at risk}}$$",
    explanation = paste(
      "Enter the number of **cases** and the **population at risk** (everyone who could have become a case, for example all people who",
      "attended the event). The attack rate is a cumulative incidence over the whole outbreak period, not a rate per unit of time.",
      "It is shown as a proportion and as a percentage with six confidence intervals; the Wilson interval is a good default.",
      "",
      "Check that the denominator is the **population at risk**: people who were not exposed, or who were already immune, do not belong in it.",
      sep = "\n"
    ),
    worked_example = "30 cases among 120 people who ate at a gathering: attack rate 25.0%, Wilson 95% interval 18.1% to 33.4%.",
    citation = .outbreak_citation,
    backend = "calc_analyze_attack_rate() on calc_analyze_ci_proportion(); intervals verified against epiR::epi.conf, binom.test and prop.test"
  ),
  exposure = list(
    title = "Exposure-specific attack rates (food-specific attack-rate table)",
    formula_latex = paste0(
      "$$AR_{exposed}=\\frac{a}{a+b},\\quad AR_{unexposed}=\\frac{c}{c+d},\\quad RR=\\frac{AR_{exposed}}{AR_{unexposed}},\\quad RD=AR_{exposed}-AR_{unexposed}$$",
      "$$\\text{share of cases exposed}=\\frac{a}{a+c}$$"
    ),
    explanation = paste(
      "One row per suspected exposure (a food, a place, an event). For each, enter the number ill and the total **among those exposed**, and",
      "the number ill and the total **among those not exposed**. The table gives both attack rates, the **risk ratio** with its Katz",
      "confidence interval, the **risk difference**, Fisher's exact p-value and the percentage of all cases who were exposed.",
      "",
      "In a point-source outbreak the vehicle is usually the exposure with a **high risk ratio** that **most cases** (often 80% or more) were",
      "exposed to. This is a **screening table**: several exposures are tested at once, and exposures that were eaten together are correlated,",
      "so the p-values are descriptive. Follow it with a stratified analysis or a case-control comparison for the leading suspects.",
      sep = "\n"
    ),
    worked_example = "Salad: 40 of 50 exposed ill, 4 of 30 unexposed ill: attack rates 80.0% and 13.3%, risk ratio 6.0, 91% of cases ate the salad. Chicken: 25 of 60 and 19 of 20: risk ratio 0.44 (the unexposed were more often ill), so it is not the vehicle.",
    citation = .outbreak_citation,
    backend = "calc_analyze_exposure_table() on calc_analyze_2x2(design = \"cohort\"); rows equal the 2x2 tool and fisher.test()"
  ),
  secondary = list(
    title = "Secondary attack rate",
    formula_latex = "$$SAR=\\frac{\\text{secondary cases among contacts}}{\\text{susceptible contacts exposed to the primary cases}}$$",
    explanation = paste(
      "Enter the number of **secondary cases** among the contacts of the primary (index) cases and the number of **susceptible contacts**.",
      "Leave out the primary cases themselves, and people who were already immune or were infected at the same time as the primary case",
      "(**co-primary** cases), who did not catch it from them. The ratio measures how transmissible the infection is within households or other close groups.",
      "",
      "**Caution:** the interval treats the contacts as independent. Contacts in the same household are not, so when many contacts share a",
      "household the interval is too narrow; use a method that accounts for clusters for a formal analysis.",
      sep = "\n"
    ),
    worked_example = "9 secondary cases among 60 susceptible household contacts: secondary attack rate 15.0%, Wilson 95% interval 8.1% to 26.1%.",
    citation = .outbreak_citation,
    backend = "calc_analyze_secondary_attack() on calc_analyze_ci_proportion()"
  ),
  cfr = list(
    title = "Case fatality",
    formula_latex = paste0(
      "$$CFR_{crude}=\\frac{\\text{deaths}}{\\text{cases}},\\qquad CFR_{resolved}=\\frac{\\text{deaths}}{\\text{deaths}+\\text{recovered}}$$"
    ),
    explanation = paste(
      "Enter the number of **deaths** and the number of **cases**; optionally the number **recovered** to see the ratio among **resolved** cases.",
      "",
      "While an outbreak is still running, some cases have not yet had time to die, so the **crude** ratio is biased **low**. The ratio among",
      "resolved cases is biased the other way early on, because deaths are usually recorded sooner than recoveries, so it is biased **high**.",
      "The two bracket the true value; it settles as cases resolve. Neither accounts for cases that were never detected, which makes the crude ratio too high",
      "when only severe cases are counted. Report the deaths and cases with the date of the data.",
      sep = "\n"
    ),
    worked_example = "6 deaths among 80 cases, 34 recovered and 40 still unresolved: crude 7.5% (Clopper-Pearson 2.8% to 15.6%); among the 40 resolved cases 15.0% (5.7% to 29.8%).",
    citation = .outbreak_citation,
    backend = "calc_analyze_case_fatality() on calc_analyze_ci_proportion()"
  )
)
