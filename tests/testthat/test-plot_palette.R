# Plot colours in light and dark mode (R/mod_shared_ui.R; CHECKLIST UI-12): every colour drawn on a plot has a contrast of at least
# 3:1 against the plot background (WCAG 2.1, 1.4.11 non-text contrast), text at least 4.5:1, and the background matches the page.

contrast <- function(a, b) {
  lum <- function(hex) {
    v <- grDevices::col2rgb(hex)[, 1] / 255
    v <- ifelse(v <= 0.03928, v / 12.92, ((v + 0.055) / 1.055)^2.4)
    sum(c(0.2126, 0.7152, 0.0722) * v)
  }
  l <- sort(c(lum(a), lum(b)), decreasing = TRUE)
  (l[1] + 0.05) / (l[2] + 0.05)
}

test_that("every plot colour is readable on its background, in both modes", {
  for (dark in c(FALSE, TRUE)) {
    pal <- .plot_palette(dark)
    for (nm in c("fg", "muted")) expect_gte(contrast(pal[[nm]], pal$bg), 4.5, label = paste(nm, "dark =", dark))
    for (nm in c("line", "accent", "grey")) expect_gte(contrast(pal[[nm]], pal$bg), 3, label = paste(nm, "dark =", dark))
    for (nm in names(pal$series)) expect_gte(contrast(pal$series[[nm]], pal$bg), 3, label = paste(nm, "dark =", dark))
    expect_named(pal$series, c("susceptible", "exposed", "infectious", "removed"))
  }
  expect_equal(.plot_palette(FALSE)$bg, "#ffffff")
  expect_equal(.plot_palette(TRUE)$bg, "#212529")          # Bootstrap's dark body background
  expect_false(.plot_is_dark(NULL))                         # outside a session: the light palette
})

test_that(".plot_start() sets the device colours and hands back what to restore", {
  f <- tempfile(fileext = ".png"); grDevices::png(f); on.exit({ grDevices::dev.off(); unlink(f) })
  before <- graphics::par("bg", "fg", "col.axis")
  st <- .plot_start(dark = TRUE)
  expect_equal(graphics::par("bg"), "#212529")
  expect_equal(tolower(graphics::par("col.axis")), "#dee2e6")
  graphics::par(st$op)
  expect_equal(graphics::par("bg", "fg", "col.axis"), before)
})
