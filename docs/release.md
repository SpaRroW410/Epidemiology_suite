# Releasing the package (CHECKLIST PKG-06, PKG-11)

The tarball is built and checked by `.github/workflows/package.yml`, so nothing has to be built on your own computer.

## 1. The tarball

- **Any time:** GitHub, *Actions* tab, workflow *package*, *Run workflow* (on `main`). When it finishes, the run's page has the file
  `epidemiologysuite_<version>.tar.gz` under *Artifacts* (a zip that contains it), and a summary of each `R CMD check --as-cran`
  (Linux R release and R devel, Windows, macOS; plus Windows on ARM, informational).
- **Every pull request** that touches the package runs the same build and checks.

## 2. A release

1. Raise `Version:` in `DESCRIPTION` and turn the top of `NEWS.md` from "(development version)" into that version.
   `v1.0.0` is already used: the GitHub release of 31 Oct 2026 that Zenodo archived (DOI 10.5281/zenodo.23794230). The code has
   changed a great deal since, so the next one, and the first sent to CRAN, needs a new number.
2. Merge that change, then create the tag on `main`: GitHub, *Releases*, *Draft a new release*, *Choose a tag*, type
   `v<version>` (for example `v1.1.0`), *Create new tag on publish*, *Publish release*.
3. The tag starts the workflow: it checks that the tag matches `DESCRIPTION`, builds and checks the tarball, and attaches it to the
   release. Zenodo archives the new release under the same concept DOI.

## 3. r-universe (binaries for Windows, macOS and Linux, built from GitHub)

1. Create a public repository named exactly `SpaRroW410.r-universe.dev` with one file, `packages.json`:

   ```json
   [{"package": "epidemiologysuite", "url": "https://github.com/SpaRroW410/Epidemiology_suite"}]
   ```

2. Install the r-universe GitHub app on your account (from <https://github.com/apps/r-universe/installations/new>), allowing that
   repository.
3. After the first build, people install with
   `install.packages("epidemiologysuite", repos = c("https://sparrow410.r-universe.dev", "https://cloud.r-project.org"))`.
   r-universe rebuilds on every push to `main`.

## 4. CRAN

1. The workflow's checks should show 0 errors and 0 warnings; read every note.
2. Update `cran-comments.md` with those results (the platforms and R versions from the run's summary).
3. Submit the tarball from the release at <https://cran.r-project.org/submit.html>. CRAN sends a confirmation e-mail to the
   maintainer address in `DESCRIPTION`; the submission goes ahead only after you click the link in it.
4. Answer the reviewers' e-mails; a resubmission raises the version's last number (1.1.0 to 1.1.1) and adds a "Resubmission"
   section to `cran-comments.md`.

## Windows on ARM (Snapdragon / Qualcomm)

The package itself is plain R code, so the tarball is the same on every machine. Problems on an ARM computer come from the
packages it needs that contain compiled code (`lme4` and the packages under it, `mvtnorm`, `clinfun`): with the native ARM build of
R these must be compiled on the machine, because CRAN's ready-made Windows packages are built for x64. The workflow's
`windows-arm` job shows whether that works on a clean ARM machine. The usual way round it is to install the ordinary x64 R for
Windows, which Windows on ARM runs by emulation and which uses CRAN's ready-made packages.
