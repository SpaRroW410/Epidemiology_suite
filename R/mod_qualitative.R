# Qualitative & Mixed Methods Sample Size Guidance module. Unlike every
# other module in this app, this one has no numeric inputs, no formula,
# and no computed output -- it presents the field's own established
# frameworks as reference guidance (per the checklist's own explicit
# instruction for this section: "non-formula -- acknowledge, don't fake
# precision"; "present as guidance panel, no numeric output"). So the
# first tab is "Guidance" rather than "Calculate", and there is no
# calc_qualitative.R / mod_qualitative_server reactive computation --
# content is rendered directly.

qualitative_meta <- list(
  id = "qualitative",
  nav_title = "Qualitative Sample Size Guidance"
)

.render_qualitative_topic <- function(topic) {
  tagList(
    h4(topic$title),
    shiny::markdown(topic$explanation),
    p(strong("Citation: "), topic$citation)
  )
}

mod_qualitative_ui <- function(id) {
  ns <- NS(id)

  tabsetPanel(
    tabPanel(
      "Guidance",
      br(),
      div(
        class = "alert alert-info",
        strong("No formula, on purpose: "),
        "Qualitative sample size is a matter of ongoing judgment during ",
        "data collection (saturation, information sufficiency), not a ",
        "number solved in advance from alpha/power/effect-size inputs. ",
        "The frameworks below are the field's own established guidance, ",
        "not a calculator."
      ),
      .render_qualitative_topic(qualitative_content$saturation),
      hr(),
      .render_qualitative_topic(qualitative_content$information_power),
      hr(),
      .render_qualitative_topic(qualitative_content$purposive_theoretical)
    ),
    tabPanel(
      "Reference",
      br(),
      h4(qualitative_content$saturation$title),
      p(strong("Citation: "), qualitative_content$saturation$citation),
      hr(),
      h4(qualitative_content$information_power$title),
      p(strong("Citation: "), qualitative_content$information_power$citation),
      hr(),
      h4(qualitative_content$purposive_theoretical$title),
      p(strong("Citation: "), qualitative_content$purposive_theoretical$citation)
    )
  )
}

mod_qualitative_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # No server-side computation -- this module is pure reference content.
  })
}
