# Ecological Studies Guidance module. Like mod_qualitative.R, this one has
# no numeric inputs, no formula, and no computed output -- it presents the
# field's own established framework (unit-of-analysis, ecological fallacy)
# as reference guidance, per the checklist's own framing for this line
# ("note confounding/aggregation caveats"). So the first tab is "Guidance"
# rather than "Calculate", and there is no calc_ecological.R.

ecological_meta <- list(
  id = "ecological",
  nav_title = "Ecological Study Guidance"
)

.render_ecological_topic <- function(topic) {
  tagList(
    h4(topic$title),
    shiny::markdown(topic$explanation),
    p(strong("Citation: "), topic$citation)
  )
}

mod_ecological_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    tabPanel(
      "Guidance",
      br(),
      div(
        class = "alert alert-info",
        strong("No formula, on purpose: "),
        "An ecological study's unit of analysis is a group (a district, a ",
        "school, a country-year), not an individual, so this app's ",
        "individual-level sample-size formulas don't transfer -- what needs ",
        "planning is the number of groups and their between-group variance, ",
        "and the resulting association carries its own well-documented ",
        "interpretive hazard regardless of group count."
      ),
      .render_ecological_topic(ecological_content$unit_of_analysis),
      hr(),
      .render_ecological_topic(ecological_content$ecological_fallacy)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(ecological_content$unit_of_analysis$title),
      p(strong("Citation: "), ecological_content$unit_of_analysis$citation),
      hr(),
      h4(ecological_content$ecological_fallacy$title),
      p(strong("Citation: "), ecological_content$ecological_fallacy$citation)
    )
  )
}

mod_ecological_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # No server-side computation -- this module is pure reference content.
  })
}
