\name{run_app}
\alias{run_app}
\title{Run the epidemiologicasuite application}
\usage{
run_app(calculator = NULL, ...)
}
\arguments{
\item{calculator}{Optional: open the app straight on one calculator. Either a design key from \code{\link[=ss_find]{ss_find()}}
(the \code{key} column) or a few words describing it (the best match of \code{\link[=ss_find]{ss_find()}} is opened).}

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
  run_app(calculator = "eyes per patient")
}
}
