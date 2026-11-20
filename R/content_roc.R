# Metadata for the ROC / AUC module: formula text, plain-language
# explanation, worked example, and citation. Content is data, rendered
# generically by mod_roc.R (SDD 4.2: "content is data, not hardcoded UI").

roc_content <- list(
  single_auc = list(
    title = "Single ROC AUC vs. Chance (0.5)",
    formula_latex = paste0(
      "$$n_{cases} \\text{ solved from Obuchowski et al. (2004), formulas 2 \\& 3; } ",
      "n_{controls} = \\kappa \\times n_{cases}$$"
    ),
    explanation = paste(
      "Use this to size a study testing whether a diagnostic test's area",
      "under the ROC curve (AUC) is significantly better than chance",
      "(AUC = 0.5) -- a global test of whether the test discriminates",
      "diseased from non-diseased subjects at all.",
      "",
      "- **auc** - the AUC you expect the test to achieve (must exceed",
      "  0.5; e.g. 0.7-0.8 fair, 0.8-0.9 good, >0.9 excellent",
      "  discrimination, per common conventions).",
      "- **alpha, power** - as elsewhere.",
      "- **kappa** - the ratio of controls to cases (1 = equal",
      "  allocation); useful when the condition is rare and controls are",
      "  easier to recruit than cases.",
      "",
      "This calculator returns the number of *cases* (subjects with the",
      "condition) and *controls* (without it) needed -- not a simple",
      "total, since AUC studies need both groups represented.",
      sep = "\n"
    ),
    worked_example = paste(
      "Worked from pROC's own example data (the aSAH dataset, S100B",
      "biomarker, observed AUC = 0.73): wanting to detect this AUC with",
      "95% power at alpha = 0.05, with 1.7 controls per case (kappa =",
      "1.7), this calculator returns 30 cases and 51 controls (81 total)",
      "-- matching pROC's own computed answer (29.67/50.44) after",
      "rounding up.",
      sep = "\n"
    ),
    citation = paste(
      "Obuchowski NA, Lieber ML, Wians FH Jr. ROC curves in clinical",
      "chemistry: uses, misuses, and possible solutions. Clin Chem.",
      "2004;50(7):1118-1125. (formulas 2 and 3, as implemented by",
      "pROC::power.roc.test)."
    ),
    backend = "closed form written out in the app, equal to pROC::power.roc.test() (compared with the package in the tests; the package is not a dependency)"
  ),

  compare_two_aucs = list(
    title = "Compare Two Correlated (Paired) ROC AUCs",
    formula_latex = paste0(
      "$$N \\text{ solved from Obuchowski \\& McClish (1997), formulas 2 \\& 3, ",
      "given binormal parameters } A_1,B_1,A_2,B_2 \\text{ and correlations } r_n, r_a$$"
    ),
    explanation = paste(
      "Use this to size a study comparing whether TWO diagnostic tests'",
      "AUCs differ, when both tests are applied to the SAME subjects",
      "(paired/correlated design) -- e.g. comparing a new biomarker",
      "against an existing one on the same patient cohort.",
      "",
      "Each ROC curve's shape is described by its own **binormal",
      "parameters A and B** (the standard way to parameterize an ROC",
      "curve's shape without needing raw patient-level data) -- if you",
      "only know each test's AUC, B=1 (the equal-variance/standard",
      "binormal case) and A = qnorm(AUC) x sqrt(2) recovers A from AUC.",
      "",
      "- **A1, B1 / A2, B2** - binormal shape parameters for curve 1/2.",
      "- **rn** - correlation between the two tests' results in",
      "  CONTROLS (non-diseased subjects).",
      "- **ra** - correlation between the two tests' results in CASES",
      "  (diseased subjects) -- can differ from rn.",
      "- **delta** - the AUC difference between the two curves you want",
      "  to detect.",
      "- **kappa** - the ratio of controls to cases.",
      "- **Partial AUC (optional)** - restrict the comparison to a false-",
      "  positive-rate (1-specificity) range via the FPR bounds for each",
      "  curve; leave blank to compare the FULL AUC of each curve.",
      sep = "\n"
    ),
    worked_example = paste(
      "Obuchowski & McClish (1997)'s own Example 2 (reproduced exactly",
      "as pROC's own documentation example): A1=2.6, B1=1, A2=1.9, B2=1,",
      "rn=ra=0.6, comparing a PARTIAL AUC restricted to the FPR range",
      "[0, 0.2] for both curves, delta=0.037, alpha=0.05, target power=",
      "0.80. This calculator's underlying computation gives ncases =",
      "ncontrols = 107.02 (this calculator rounds UP to 108/108, 216",
      "total, per this app's own always-round-up convention for a",
      "REQUIRED sample size -- the package's own documentation examples",
      "simply illustrate with the nearest whole number, 107, since 107.02",
      "is only marginally above it). Comparing the FULL AUC of the same",
      "two curves instead (omitting the partial-AUC FPR bounds) needs",
      "substantially more: 166 cases and 166 controls (332 total) --",
      "confirmed self-consistent via a round-trip power check at that n",
      "(power = 0.8004, matching the 0.80 target).",
      sep = "\n"
    ),
    citation = paste(
      "Obuchowski NA, McClish DK. Sample size determination for",
      "diagnostic accuracy studies involving binormal ROC curve",
      "indices. Stat Med. 1997;16(13):1529-1542."
    ),
    backend = "closed form written out in the app, equal to pROC::power.roc.test() (list/binormal-parameter method) (compared with the package in the tests; the package is not a dependency)"
  )
)
