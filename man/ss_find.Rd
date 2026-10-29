\name{ss_find}
\alias{ss_find}
\title{Find a sample size calculator}
\usage{
ss_find(query = "", n = 10)
}
\arguments{
\item{query}{A few words, e.g. \code{"two means"}, \code{"kappa"}, \code{"eyes per patient"}. Empty (the default) lists everything.}

\item{n}{The most rows to return (default 10; use \code{Inf} for all).}
}
\value{
A data frame with one row per design: \code{key} (what \code{\link[=run_app]{run_app()}} takes), \code{design} (its name), \code{calculator} (the
calculator in the app that holds it) and \code{answers} (the question it answers).
}
\description{
Searches every built design by words in its name, in the question it answers and in the name of the calculator it lives in.
A word in the name counts most; results are ranked by how many of your words match. A design must match every word.
}
\examples{
ss_find("eyes per patient")
ss_find("kappa", n = 3)
}
