\name{sample2result_app}
\alias{sample2result_app}
\title{Build the sample2result Shiny app object}
\usage{
sample2result_app()
}
\value{
A \code{shiny::shinyApp()} object.
}
\description{
The app object itself, without running it -- for \code{shiny::runApp()}, for
the root \code{app.R} used during development, and for deployment or testing
(e.g. \code{shiny::testServer()}, shinytest2).
}
