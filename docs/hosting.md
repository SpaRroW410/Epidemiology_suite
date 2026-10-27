# Three ways to use epidemiologicasuite

One codebase (the R package), three ways to run it. They are built from the same `R/` directory by CI, so they cannot drift apart.

| | Where | Runs on | Good for | Limits |
|---|---|---|---|---|
| **1. Browser build** | GitHub Pages: `https://sparrow410.github.io/Sample_size_all/app/` | your own device, in the browser (R compiled to WebAssembly) | desktop browsers; nothing is sent anywhere; no server, no cost | about 60 MB first download and about 1 GB of memory, so many phones cannot run it; a few designs that need compiled packages are unavailable; slower simulations |
| **2. Phone / server version** | Posit Connect Cloud (live at https://sparrow410-epidemiological-suite.share.connect.posit.cloud) | a Posit server running R | phones and tablets: the phone only receives a web page | what people type goes to the server; free plans may sleep when idle and have limits (check Posit's pricing page); one R process serves several users |
| **3. R package** | `remotes::install_github("SpaRroW410/Sample_size_all")`, then `epidemiologicasuite::run_app()`; or the Docker image | your own R | everything, offline, fastest, every design | needs R |

## How the three are produced
- **Browser build:** `docs` workflow -> `tools/pages/make_app.R` -> `shinylive::export()` -> `/app/` on Pages (boot-tested in headless Chrome).
- **Phone / server version:** `connect-bundle` workflow -> `tools/connect/make_manifest.R` builds a bundle (`app.R`, the package's `R/`
  directory, `manifest.json` listing every R package, version and CRAN source), starts it as a plain Shiny app in headless Chrome to
  prove it works, and **on `main` pushes it to the branch `connect`**. Nothing in it needs a Posit account or token.
- **R package:** the repository itself; tests in `tests/`; image in `Dockerfile`.

## Redirecting phones (one-time setup, after step 2 below)
Put the address of the Connect Cloud app in `tools/pages/mobile_url.txt` (one line). From then on the `docs` workflow adds a few
lines to the top of `/app/` that send phones and tablets there. While the file is empty nobody is redirected. A visitor can keep the
browser build with `?full=1` on the address (remembered on that device) and undo it with `?mobile=1`. The "still starting" message of
the browser build also offers the phone link.

## Owner steps for Posit Connect Cloud
These need a Posit account, so only the repository owner can do them. The wording of Posit's screens changes; follow Posit's current
documentation for deploying from GitHub (the manifest route) if a label differs.
1. Merge the PR that adds `connect-bundle` to `main`; the workflow creates the `connect` branch on its first run on `main`
   (Actions tab -> `connect-bundle`; or run it by hand with *Run workflow*).
2. Create a Posit Connect Cloud account, connect it to GitHub, publish new content from the repository `SpaRroW410/Sample_size_all`,
   choose the branch **`connect`**, content type Shiny, primary file `app.R` (the manifest is in that branch).
3. Open the address Connect gives you on a phone. Then put that address in `tools/pages/mobile_url.txt` and open a PR.
4. Each later push to `main` that changes `R/`, `DESCRIPTION` or `tools/connect/` rebuilds the `connect` branch; Connect Cloud redeploys
   from it (check that the app is set to follow the branch).

## Things to know
- **Privacy:** the browser build and the package keep what you type on your own device. The server version sends it to Posit's
  server. The README and the app say so.
- **Cost and limits:** not verified here. Check Posit's pricing page for the Connect Cloud free plan (apps, active hours, memory).
  shinyapps.io is being retired in favour of Connect Cloud (Posit's announcement: no new apps after the end of 2026).
- **Concurrency:** one R process per app instance; many simultaneous users share it until the async work (to-do list) is done.
- **Not tested here:** the Connect Cloud deployment itself (no account), and any real phone. The bundle is tested as a plain Shiny app
  in headless Chrome; the redirect is tested in Chromium device emulation (iPhone, Pixel, iPad desktop-site, desktop, `?full=1`).
