\name{epidemiologicasuite_app}
\alias{epidemiologicasuite_app}
\title{Build the epidemiologicasuite Shiny app object}
\usage{
epidemiologicasuite_app(lazy = getOption("epidemiologicasuite.lazy", TRUE))
}
\arguments{
\item{lazy}{If \code{TRUE} (the default) only a few basic calculators are built when the app
starts and the others are loaded when opened, and in the background with a progress bar,
which makes the first screen much faster; \code{FALSE} builds every calculator up front.
The default can be changed with \code{options(epidemiologicasuite.lazy = FALSE)}.}
}
\value{
A \code{shiny::shinyApp()} object.
}
\description{
The app object itself, without running it -- for \code{shiny::runApp()}, for
the root \code{app.R} used during development, and for deployment or testing
(e.g. \code{shiny::testServer()}, shinytest2).
}
