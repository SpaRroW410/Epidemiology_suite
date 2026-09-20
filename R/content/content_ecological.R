# Metadata for the Ecological Studies Guidance module. Content is data,
# rendered generically by mod_ecological.R (SDD 4.2: "content is data, not
# hardcoded UI").
#
# Like the Qualitative & Mixed Methods module, this one has NO numeric
# formula and produces NO computed sample size, per the checklist's own
# framing for this line ("note confounding/aggregation caveats"). The
# problem with an ecological study isn't that no individual-level formula
# has been found yet -- it's that the unit of ANALYSIS is a group (a
# district, a PHC catchment, a country), not a person, so none of this
# app's individual-level n formulas transfer directly: what needs to be
# planned is the number of GROUPS and their between-group variance
# structure, a genuinely different quantity, and the resulting group-level
# association carries its own well-documented inferential hazard (the
# ecological fallacy) regardless of how many groups are used. Rather than
# fabricate a formula that would misrepresent what an ecological analysis
# can support, this module presents the field's own established framework
# and cautions as reference guidance.

ecological_content <- list(
  unit_of_analysis = list(
    title = "Unit of Analysis: Groups, Not Individuals",
    explanation = paste(
      "An ecological study measures exposure and outcome at the level of",
      "a GROUP (a district, a school, a country-year) rather than the",
      "individual -- often because individual-level data isn't available,",
      "or because the exposure genuinely only exists at group level (a",
      "policy, an ambient pollution level, a health-system feature).",
      "",
      "Morgenstern (1995) frames ecological designs into three main",
      "types, each with a different sample-size unit:",
      "",
      "1. **Multiple-group design** -- compares exposure and outcome",
      "   rates across many groups at one point in time (the most common",
      "   type; \"sample size\" here means the NUMBER OF GROUPS, plus",
      "   each group's own size, not a single individual-level n).",
      "2. **Time-trend design** -- tracks exposure and outcome changes",
      "   over time within one or a few groups (sample size is largely a",
      "   question of how many time points, and their spacing).",
      "3. **Mixed design** -- combines both (multiple groups tracked over",
      "   time), needing both a group count and a time-point count.",
      "",
      "Because the input to the analysis is a table of GROUP-level rates",
      "(not a list of individual outcomes), none of this app's",
      "individual-level formulas (two-proportion, two-mean, etc.) apply",
      "directly to plan an ecological study -- what would need planning",
      "instead is the number of groups and the expected between-group",
      "variance in exposure and outcome, a materially different power",
      "problem this app does not compute a number for.",
      sep = "\n"
    ),
    citation = paste(
      "Morgenstern H. Ecologic studies in epidemiology: concepts,",
      "principles, and methods. Annu Rev Public Health. 1995;16:61-81."
    )
  ),

  ecological_fallacy = list(
    title = "The Ecological Fallacy",
    explanation = paste(
      "Even with a well-chosen number of groups, an ecological",
      "association can mislead about the individual-level relationship it",
      "is often used to suggest -- a hazard known as the ecological",
      "fallacy (Robinson 1950 coined the term after showing that",
      "state-level correlations between literacy and immigrant status in",
      "1930 US census data had the OPPOSITE sign of the individual-level",
      "correlation).",
      "",
      "Piantadosi, Byar & Green (1988) formalize why: a group-level",
      "regression coefficient is a function not just of the true",
      "individual-level effect, but also of the within-group distribution",
      "of exposure and any within-group confounding -- quantities an",
      "ecological (group-level) dataset cannot observe directly. No",
      "amount of additional group-level sample size fixes this; it is a",
      "structural limitation of the design, not a precision problem.",
      "",
      "Greenland & Robins (1994) catalogue the specific bias mechanisms",
      "(specification bias, effect-measure modification within groups,",
      "confounding by group) and the conditions under which ecological",
      "estimates can still be interpreted cautiously -- most importantly,",
      "when within-group exposure variation is small relative to",
      "between-group variation.",
      "",
      "**Practical implication for planning:** before running any power",
      "or precision calculation for an ecological study, first confirm",
      "that a group-level analysis is scientifically defensible for the",
      "question at hand (or that only a group-level exposure genuinely",
      "exists) -- a bigger sample of groups cannot substitute for",
      "individual-level data when the research question is really about",
      "individual-level risk.",
      sep = "\n"
    ),
    citation = paste(
      "Robinson WS. Ecological correlations and the behavior of",
      "individuals. Am Sociol Rev. 1950;15(3):351-357. Piantadosi S,",
      "Byar DP, Green SB. The ecological fallacy. Am J Epidemiol.",
      "1988;127(5):893-904. Greenland S, Robins J. Ecologic studies --",
      "biases, misconceptions, and counterstrategies. Am J Epidemiol.",
      "1994;139(8):747-760."
    )
  )
)
