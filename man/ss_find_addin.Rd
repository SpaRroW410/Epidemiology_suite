\name{ss_find_addin}
\alias{ss_find_addin}
\title{RStudio / Positron addin: find a calculator and open it}
\usage{
ss_find_addin()
}
\value{
Called for its side effect (starts the app); returns \code{NULL} if the window is cancelled.
}
\description{
A small search window (the same search as \code{\link[=ss_find]{ss_find()}}); choosing a result starts the app on that calculator.
It appears under \emph{Addins} as "Find a sample size calculator".
}
