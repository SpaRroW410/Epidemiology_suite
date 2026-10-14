\name{run_app}
\alias{run_app}
\title{Run the sample2result application}
\usage{
run_app(...)
}
\arguments{
\item{...}{Passed on to \code{shiny::runApp()}, e.g. \code{port = 8080},
\code{host = "0.0.0.0"} or \code{launch.browser = FALSE}.}
}
\value{
Does not return while the app is running.
}
\description{
Starts the sample size / power calculator in the default web browser (or the
RStudio viewer). Blocks until the app is stopped.
}
\examples{
if (interactive()) {
  run_app()
}
}
