#!/bin/bash
# Installs R plus every package this Shiny app's global.R loads (and the
# testthat suite needs) whenever a fresh Claude Code on the web container
# starts. This is a full app dependency, not a repo-tracked artifact -- the
# container is ephemeral and nothing installed outside the git repo survives
# a container swap, so this hook exists to make that recovery automatic
# instead of a manual, from-scratch investigation each time.
set -euo pipefail

# Only run in Claude Code on the web / remote environments.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Idempotent: skip entirely if the environment is already fully set up.
# Checking for a package installed near the end of this script (rather than
# just Rscript's presence) avoids skipping a re-run after a partial failure.
if command -v Rscript >/dev/null 2>&1 && \
   Rscript -e 'quit(status = if (requireNamespace("PowerTOST", quietly = TRUE)) 0 else 1, save = "no")' \
     >/dev/null 2>&1; then
  exit 0
fi

apt-get update -qq

# Packages available as prebuilt Ubuntu/Debian binaries (fast, no
# compilation, no CRAN network access needed -- cran.r-project.org itself
# is blocked in this sandbox, but Ubuntu's own package archive is not).
apt-get install -y --no-install-recommends \
  r-base r-base-dev gfortran \
  r-cran-shiny r-cran-bslib r-cran-pwr r-cran-epir r-cran-proc \
  r-cran-hmisc r-cran-tseries r-cran-bayesfactor r-cran-mvtnorm \
  r-cran-rstatix r-cran-lme4 r-cran-lmertest \
  r-cran-pracma r-cran-cubature r-cran-remotes \
  r-cran-testthat

# Packages with no Ubuntu/Debian binary -- installed from their CRAN
# GitHub mirror (github.com/cran/<pkg> mirrors every CRAN package's
# source; this route works even though cran.r-project.org itself does
# not). kappaSize and rootSolve are listed first because presize and
# Exact respectively depend on them.
pkg_dir="$(mktemp -d)"
trap 'rm -rf "$pkg_dir"' EXIT

for pkg in kappaSize rootSolve clinfun powerSurvEpi Exact pmsampsize \
           TrialSize powerMediation pacman presize PowerTOST; do
  git clone --depth 1 "https://github.com/cran/${pkg}.git" "$pkg_dir/$pkg"
  R CMD INSTALL --no-docs --no-byte-compile "$pkg_dir/$pkg"
done
