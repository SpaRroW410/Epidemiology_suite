# epidemiologysuite as a container (docs/ROADMAP.md item 18, Track D1).
#   docker build -t epidemiologysuite .
#   docker run --rm -p 3838:3838 epidemiologysuite       # then open http://localhost:3838
# The app listens on 0.0.0.0:$PORT (default 3838) and needs no internet at run time: the theme uses a local font
# stack and every dependency is installed at build time.
FROM rocker/r-ver:4.4.3

# curl is used by the health check; the others are headers some packages are built against when no binary exists.
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl libcurl4-openssl-dev libssl-dev libxml2-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Dependencies first, from DESCRIPTION alone, so this layer is cached until the dependency list changes.
# rocker/r-ver points R at a dated Posit Package Manager snapshot, which serves Linux binaries.
COPY DESCRIPTION ./
RUN Rscript -e 'install.packages("remotes"); remotes::install_deps(dependencies = c("Depends", "Imports"), upgrade = "never"); install.packages("mirai")' \
 && Rscript -e 'stopifnot(all(c("shiny","bslib","lme4","kappaSize","PowerTOST","mirai") %in% rownames(installed.packages())))'

COPY . .
RUN R CMD INSTALL --no-docs --no-multiarch --no-test-load . \
 && Rscript -e 'library(epidemiologysuite); stopifnot(is.function(run_app))' \
 && rm -rf /build

# Run as an unprivileged user.
RUN useradd --create-home --shell /usr/sbin/nologin appuser
USER appuser
WORKDIR /home/appuser

ENV PORT=3838
EXPOSE 3838

HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD curl -fsS "http://localhost:${PORT}/" > /dev/null || exit 1

CMD ["R", "--quiet", "--no-save", "-e", "epidemiologysuite::run_app(host = '0.0.0.0', port = as.integer(Sys.getenv('PORT', '3838')), launch.browser = FALSE)"]
