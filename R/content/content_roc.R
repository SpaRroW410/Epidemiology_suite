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
    backend = "pROC::power.roc.test()"
  )
)
