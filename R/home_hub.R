# Home tab: a short welcome, then a "Helper" area (one navset_card_tab) that
# bundles the three ways to find/understand a calculator -- the dual-taxonomy
# browser (home_finder.R), the guided wizard (design_wizard.R), and a formula/
# LaTeX explainer + live sandbox (this file) -- so the top navbar only needs
# one "Home" entry instead of separate crowding tabs for each. Composes
# home_finder.R's and design_wizard.R's UI-fragment/server functions rather
# than rewriting them (both already expose exactly that shape); this file
# just supplies the Welcome block, the wrapping navset, and the new sandbox.
#
# Same non-idiomatic pattern as home_finder.R/design_wizard.R: plain
# UI-building + server logic, not a Shiny module, since the pieces it
# composes need root-session access to jump the top-level navbar.

home_panel_ui <- function() {
  tagList(
    h2("Comprehensive Sample Size Calculator"),
    p(paste(
      "A sample size and power calculator for community medicine,",
      "epidemiology, and clinical research. Each calculator includes a",
      "worked-formula help tab and a reference to its original source."
    )),
    p(paste(
      "Use the tabs above to go straight to a calculator, grouped by study",
      "design, or use the Helper below to find, learn about, or understand",
      "the formula behind the calculator you need."
    )),
    hr(),
    navset_card_tab(
      nav_panel("Browse calculators", br(), home_finder_body()),
      nav_panel("Which calculator? (guided wizard)", br(), design_wizard_body()),
      nav_panel("Formulas & LaTeX", br(), home_sandbox_ui())
    )
  )
}

home_server <- function(input, output, session) {
  home_finder_server(input, output, session)
  design_wizard_server(input, output, session)

  latex_input <- debounce(reactive(input$home_latex_sandbox), 400)

  output$home_latex_preview <- renderUI({
    raw <- latex_input()
    body <- gsub("\\${2}", "", if (is.null(raw)) "" else raw)
    tagList(
      div(id = "home_latex_output", class = "border rounded p-3 bg-light",
          withMathJax(HTML(paste0("$$", body, "$$")))),
      tags$script(HTML(
        "if (window.MathJax && MathJax.Hub) {",
        "  MathJax.Hub.Queue(['Typeset', MathJax.Hub, 'home_latex_output']);",
        "}"
      ))
    )
  })
}

home_sandbox_ui <- function() {
  tagList(
    h4("How formulas are written in this app"),
    shiny::markdown(paste(
      "Every formula in this app is typeset with MathJax using standard",
      "LaTeX, wrapped in `$$...$$` for display-mode equations (e.g.",
      "`$$n = ...$$`). A multi-line formula is just several `$$...$$` blocks",
      "one after another. Because R itself treats a single backslash as an",
      "escape character, every LaTeX backslash has to be doubled when it's",
      "written inside an R string -- `\\frac` becomes `\\\\frac`,",
      "`\\alpha` becomes `\\\\alpha`, and so on.",
      "",
      "Try it yourself below -- type LaTeX (without the `$$`) and see it",
      "rendered live."
    )),
    textAreaInput(
      "home_latex_sandbox", NULL,
      value = "n = \\frac{Z_{1-\\alpha/2}^2\\,p(1-p)}{d^2}",
      width = "100%", rows = 2
    ),
    uiOutput("home_latex_preview")
  )
}
