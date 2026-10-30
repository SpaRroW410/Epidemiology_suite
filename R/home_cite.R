# The Cite tab: how to cite the software, in several formats, with copy and download. The facts come from citation_info.R.

cite_ui <- function() {
  info <- suite_citation_info()
  tagList(
    tags$style(HTML("#cite_text { white-space: pre-wrap; word-break: break-word; }")),
    h3("How to cite"),
    p("If this software helped with your work, please cite it. Choose the format your journal or reference manager uses."),
    uiOutput("cite_doi_note"),
    selectInput("cite_format", "Format", choices = citation_formats, selected = "apa", width = "26rem"),
    verbatimTextOutput("cite_text"),
    div(class = "mb-3",
      tags$button("Copy", type = "button", class = "btn btn-sm btn-primary me-2",
                  onclick = paste0("navigator.clipboard.writeText(document.getElementById('cite_text').innerText)",
                                   ".then(function(){ var b = event.target, o = b.innerText; b.innerText = 'Copied!'; setTimeout(function(){ b.innerText = o; }, 1500); });")),
      downloadButton("cite_download", "Download", class = "btn-sm btn-outline-secondary")
    ),
    h5("Version"),
    p(sprintf("This is version %s. Cite the version you used; results can change between versions.", info$version)),
    h5("Cite the formulas as well"),
    p("Every calculator's Reference tab names the original source of its formula, and each result can be exported with that citation",
      "(BibTeX or RIS). Please cite those sources where you report a sample size or power calculation."),
    h5("In R"),
    tags$pre(class = "border rounded p-2", "citation(\"epidemiologicasuite\")")
  )
}

cite_server <- function(input, output, session) {
  chosen <- reactive(if (is.null(input$cite_format) || !nzchar(input$cite_format)) "apa" else input$cite_format)
  output$cite_text <- renderText(citation_text(chosen()))
  output$cite_doi_note <- renderUI({
    info <- suite_citation_info()
    if (is.na(info$doi)) {
      div(class = "alert alert-info small",
          strong("DOI: "), "no DOI is set, so the citations give the web address and the version.")
    } else {
      p(strong("DOI: "), tags$a(href = paste0("https://doi.org/", info$doi), info$doi))
    }
  })
  output$cite_download <- downloadHandler(
    filename = function() .citation_file(chosen()),
    content = function(file) writeLines(citation_text(chosen()), file, useBytes = TRUE)
  )
}
