# Small, app-wide accessibility repairs for things Shiny and bslib generate without a name or keyboard access.
# They are applied in the browser because the elements are created there (selectize) or when an output first renders.
# tools/ui-audit/a11y.R runs axe-core over every calculator to check that nothing regresses.

#' Script that gives generated controls an accessible name and keyboard access
#'
#' * `selectInput()` renders a selectize search box (`<id>-selectized`) that has no label of its own; it is pointed at the
#'   input's visible label (`<id>-label`).
#' * Text outputs (`verbatimTextOutput()`, the justification paragraph, result tables) can scroll sideways; a scrollable
#'   region must be reachable with the keyboard, so it gets `tabindex="0"` and a role and name.
#'
#' @return A `<script>` tag for the page header.
#' @noRd
accessibility_script <- function() {
  shiny::tags$script(shiny::HTML("
(function () {
  var queued = false;
  function repair() {
    queued = false;
    document.querySelectorAll('.selectize-control input[id$=\"-selectized\"]').forEach(function (inp) {
      if (inp.getAttribute('aria-labelledby') || inp.getAttribute('aria-label')) return;
      var base = inp.id.replace(/-selectized$/, ''), lab = document.getElementById(base + '-label');
      if (lab) inp.setAttribute('aria-labelledby', base + '-label'); else inp.setAttribute('aria-label', 'Choose an option');
    });
    document.querySelectorAll('pre.shiny-text-output, .shiny-table-output, .table-responsive').forEach(function (el) {
      if (el.hasAttribute('tabindex')) return;
      el.setAttribute('tabindex', '0');
      if (!el.getAttribute('role')) el.setAttribute('role', 'region');
      if (!el.getAttribute('aria-label') && !el.getAttribute('aria-labelledby'))
        el.setAttribute('aria-label', el.id ? 'Result: ' + el.id.replace(/[-_]/g, ' ') : 'Result');
    });
  }
  function queue() { if (!queued) { queued = true; window.requestAnimationFrame(repair); } }
  document.addEventListener('DOMContentLoaded', function () {
    queue();
    new MutationObserver(queue).observe(document.body, { childList: true, subtree: true });
  });
})();"))
}
