# Metadata for the Meta-Analysis Power module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_meta_power.R (SDD 4.2: "content is data, not
# hardcoded UI").

meta_power_content <- list(
  power = list(
    title = "Power for a Planned Meta-Analysis (Fixed- and Random-Effects)",
    formula_latex = paste0(
      "$$ncp = \\frac{\\theta}{\\sqrt{v/k}}, \\qquad ",
      "Power_{fixed} = \\Phi(ncp - z_{crit}) + \\Phi(-ncp - z_{crit})$$",
      "$$Power_{random} = 1 - \\left[F(z_{crit}) - F(-z_{crit})\\right], ",
      "\\quad F(t) = P\\!\\left(\\frac{\\hat\\theta - \\theta}{\\sqrt{v/k \\, (1-I^2)^{-1}}} \\le t\\right)$$"
    ),
    explanation = paste(
      "Before running a meta-analysis (or planning a multi-site/multi-",
      "study program to feed one), this answers: given a true summary",
      "effect, how many studies (k), of what size, are needed to reliably",
      "detect it? Unlike a single-study power calculation, a meta-",
      "analysis also has to reckon with **between-study heterogeneity**",
      "(I-squared) -- how much the true effect itself varies from study",
      "to study, on top of each study's own sampling error.",
      "",
      "- **Effect size** - the assumed TRUE summary effect: Cohen's d",
      "  (standardized mean difference), a correlation r, or an odds",
      "  ratio (entered via a representative 2x2 table).",
      "- **Per-study size** - the number of participants in EACH",
      "  contributing study (assumed equal across studies here).",
      "- **k** - the total number of studies in the meta-analysis.",
      "- **I-squared (I^2)** - the proportion of total variance in study",
      "  effects that is due to real between-study differences rather",
      "  than sampling error; 0 = every study estimates the exact same",
      "  true effect (the fixed-effect case), closer to 1 = substantial",
      "  heterogeneity.",
      "",
      "**Fixed-effect power** assumes I^2 = 0 (every study shares one",
      "true effect) -- optimistic, since real heterogeneity always makes",
      "detection harder. **Random-effects power** properly accounts for",
      "the specified I^2, and is never larger than the fixed-effect",
      "power for the same inputs -- the more realistic (and usually more",
      "conservative) planning figure.",
      "",
      "This is Hedges & Pigott (2004)'s meta-analysis power framework,",
      "generalized to the random-effects case by Jackson & Turner (2017)",
      "-- the basis of the `metapower` package's `mpower()` function.",
      sep = "\n"
    ),
    worked_example = paste(
      "Cohen's d = 0.2 (a small true effect), 10 participants/study, k =",
      "10 studies, I^2 = 0.5 (moderate heterogeneity), two-tailed alpha =",
      "0.05 -> fixed-effect power = 0.169, random-effects power = 0.136 --",
      "both quite low, correctly warning that 10 small studies are far",
      "from enough to reliably detect a small effect. Solving instead for",
      "the number of studies needed to reach 80% power under the random-",
      "effects model, holding everything else fixed, needs many more",
      "studies of the same small size -- illustrating why meta-analyses",
      "of many small, heterogeneous studies routinely remain",
      "underpowered even when each individual study looks reasonable on",
      "its own.",
      "",
      "All four combinations checked this session (Cohen's d, a",
      "correlation r, an odds ratio via a 2x2 table, and a one-tailed",
      "test) reproduced a real `metapower::mpower()` call bit-for-bit.",
      sep = "\n"
    ),
    citation = paste(
      "Hedges LV, Pigott TD. The power of statistical tests for",
      "moderators in meta-analysis. Psychol Methods. 2004;9(4):426-445.",
      "",
      "Jackson D, Turner R. Power analysis for random-effects",
      "meta-analysis. Res Synth Methods. 2017;8(3):290-302.",
      "",
      "Formula reimplemented from, and verified bit-for-bit against, real",
      "`metapower::mpower()` calls (Griffin JW. metapower: Power Analysis",
      "for Meta-Analysis. R package, https://github.com/cran/metapower) --",
      "installed in this sandbox via the github.com/cran mirror",
      "(`cran.r-project.org` itself is network-blocked here), used only as",
      "a verification oracle. Per this project's vendoring policy, the",
      "shipped calculator has no new runtime dependency. Note: this",
      "covers standard pairwise meta-analysis power, not network",
      "meta-analysis specifically -- no closed-form network-meta-analysis",
      "power method was locatable this session."
    ),
    backend = "closed-form reimplementation (Hedges & Pigott 2004; Jackson & Turner 2017)"
  )
)
