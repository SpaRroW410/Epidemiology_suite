# Metadata for the Qualitative & Mixed Methods Sample Size Guidance
# module. Content is data, rendered generically by mod_qualitative.R
# (SDD 4.2: "content is data, not hardcoded UI").
#
# Unlike every other module in this app, this one has NO numeric
# formula and produces NO computed sample size -- per the checklist's
# own explicit framing for this section ("non-formula -- acknowledge,
# don't fake precision"; "present as guidance panel, no numeric
# output"). Qualitative sample size is a matter of ongoing judgment
# during data collection (saturation, information sufficiency), not a
# number solved in advance from alpha/power/effect-size inputs -- so
# rather than fabricate a spurious formula, this module presents the
# field's own established frameworks and their own reported findings
# as reference guidance.

qualitative_content <- list(
  saturation = list(
    title = "Saturation-Based Guidance",
    explanation = paste(
      "\"Saturation\" -- the point at which new interviews stop",
      "surfacing new themes or codes -- is the traditional qualitative",
      "criterion for \"enough\" data, but it can only be recognized",
      "DURING analysis, not calculated in advance. Guest, Bunce &",
      "Johnson (2006) empirically tracked when new codes stopped",
      "appearing across 60 in-depth interviews in a relatively",
      "homogeneous study population with a fairly narrow, well-defined",
      "research aim.",
      "",
      "Their own finding, stated directly: \"saturation occurred within the first twelve interviews, although basic elements for metathemes were present as early as six interviews.\"",
      "",
      "This is often cited as a rough starting benchmark (roughly 6-12",
      "interviews) for similarly homogeneous, narrowly-scoped studies --",
      "but the authors themselves caution this is specific to their",
      "study's population and aim. A more heterogeneous population, a",
      "broader research question, or a more complex code structure will",
      "typically need more interviews before new themes stop emerging;",
      "there is no universal number. Plan to continue data collection",
      "until your own analysis shows saturation, rather than fixing a",
      "target interview count in advance.",
      sep = "\n"
    ),
    citation = paste(
      "Guest G, Bunce A, Johnson L. How many interviews are enough? An",
      "experiment with data saturation and variability. Field Methods.",
      "2006;18(1):59-82."
    )
  ),

  information_power = list(
    title = "Information Power",
    explanation = paste(
      "Malterud, Siersma & Guassora (2016) propose \"information",
      "power\" as an alternative to saturation for guiding qualitative",
      "sample size: the more information power a sample holds relevant",
      "to the study, the FEWER participants are needed. Information",
      "power depends on five dimensions -- weigh each for your own",
      "study rather than looking up a fixed number:",
      "",
      "1. **Study aim** - a narrow, focused aim needs fewer",
      "   participants than a broad, exploratory one.",
      "2. **Sample specificity** - participants with dense, highly",
      "   relevant experience of the phenomenon need a smaller sample",
      "   than a more general/varied group.",
      "3. **Use of established theory** - a study grounded in strong",
      "   existing theory can draw on richer, more targeted analysis",
      "   from fewer participants than an atheoretical study.",
      "4. **Quality of dialogue** - interviews with strong, clear,",
      "   reflective communication yield more usable information per",
      "   participant than weak or ambiguous dialogue.",
      "5. **Analysis strategy** - an in-depth, case-focused analysis of",
      "   a few cases can need fewer participants than a broad",
      "   cross-case comparison strategy.",
      "",
      "A study that scores strongly on all five (narrow aim, highly",
      "specific sample, strong theory base, rich dialogue, focused",
      "analysis) can reach adequate information power with a notably",
      "smaller sample than a study that scores weakly on most of them.",
      sep = "\n"
    ),
    citation = paste(
      "Malterud K, Siersma VD, Guassora AD. Sample size in qualitative",
      "interview studies: guided by information power. Qual Health Res.",
      "2016;26(13):1753-1760."
    )
  ),

  purposive_theoretical = list(
    title = "Purposive / Theoretical Sampling",
    explanation = paste(
      "Unlike probability-based quantitative sampling, purposive and",
      "theoretical sampling deliberately select participants (or",
      "cases, settings, documents) BECAUSE of what they can contribute",
      "to answering the research question -- not to be statistically",
      "representative of a population. Sample size is therefore not",
      "fixed in advance; it emerges from the sampling strategy and the",
      "point at which the researcher judges enough has been learned.",
      "",
      "- **Purposive sampling** (Patton 2002, 2015) covers a family of",
      "  strategies -- e.g. maximum-variation, critical-case,",
      "  homogeneous, or typical-case sampling -- chosen to serve the",
      "  study's specific analytic purpose.",
      "- **Theoretical sampling** (Glaser & Strauss 1967, the founding",
      "  grounded-theory text) is an iterative variant: the analyst",
      "  collects, codes, and analyzes data, then uses what has emerged",
      "  so far to decide who or what to sample NEXT, continuing until",
      "  no new theoretical insight emerges (\"theoretical saturation\").",
      "",
      "In both cases, sample size is a product of the sampling and",
      "analysis process itself, not a number a calculator can solve for",
      "in advance -- plan for iterative, judgment-based data collection",
      "rather than a fixed enrollment target.",
      sep = "\n"
    ),
    citation = paste(
      "Glaser BG, Strauss AL. The Discovery of Grounded Theory:",
      "Strategies for Qualitative Research. Aldine Publishing, 1967.",
      "Patton MQ. Qualitative Research & Evaluation Methods. 3rd/4th ed.",
      "Sage Publications, 2002/2015."
    )
  )
)
