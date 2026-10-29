# Small, app-wide accessibility repairs for things Shiny and bslib generate without a name or keyboard access.
# They are applied in the browser because the elements are created there (selectize) or when an output first renders.
# tools/ui-audit/a11y.R runs axe-core over every calculator to check that nothing regresses.

#' Script that gives generated controls an accessible name and keyboard access
#'
#' * `selectInput()` renders a selectize search box (a combobox `<input>`) that has no label of its own; it is pointed at the
#'   visible label of the underlying `<select>` (`<id>-label`).
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
    document.querySelectorAll('.selectize-control input[role=\"combobox\"]').forEach(function (inp) {
      if (inp.getAttribute('aria-labelledby') || inp.getAttribute('aria-label')) return;
      var ctrl = inp.closest('.selectize-control'), sel = ctrl && ctrl.parentElement.querySelector('select');
      var lab = sel && sel.id && document.getElementById(sel.id + '-label');
      if (lab) inp.setAttribute('aria-labelledby', sel.id + '-label'); else inp.setAttribute('aria-label', 'Choose an option');
    });
    // Grid inputs (2x2 tables, stratum rows) are built without labels: the column heading and row label are on screen
    // above/beside them. Their accessible name is composed from those: the row label (a text cell, or the stratum-name box)
    // plus the heading in the same column of the nearest heading row above (a row of cells without inputs).
    document.querySelectorAll('.shiny-input-container input:not([type=checkbox]):not([type=radio]):not([role=combobox])').forEach(function (inp) {
      if (inp.getAttribute('aria-label') || inp.getAttribute('aria-labelledby') || inp.closest('.selectize-control')) return;
      var box = inp.closest('.shiny-input-container'), lab = box && box.querySelector('label');
      if (lab && lab.textContent.trim() && !lab.classList.contains('shiny-label-null')) return;
      var cell = box.closest('[class*=\"col-\"]'), row = cell && cell.parentElement;
      var text = function (el) { return (el && !el.querySelector('input, select, textarea') ? el.textContent : '').replace(/\\s+/g, ' ').trim(); };
      var parts = [];
      if (cell && row && row.classList.contains('row')) {
        var cells = Array.prototype.slice.call(row.children), idx = cells.indexOf(cell);
        var first = cells[0] !== cell ? cells[0] : null;
        if (first) {
          var fi = first.querySelector('input[type=text]');
          var rl = fi ? (fi.value || fi.placeholder) : text(first);
          if (rl) parts.push(rl);
        }
        var scope = row.closest('.tab-pane, .well, form, .shiny-input-container') || document.body, head = null;
        var rows = Array.prototype.slice.call((row.closest('.tab-pane') || document).querySelectorAll('.row'));
        for (var k = rows.indexOf(row) - 1; k >= 0; k--) {
          var r = rows[k];
          if (r.children.length === cells.length && !r.querySelector('input, select, textarea') && text(r.children[idx])) { head = text(r.children[idx]); break; }
        }
        if (head) parts.push(head);
      }
      var name = parts.join(' ').trim() || inp.placeholder || '';
      if (name) inp.setAttribute('aria-label', name);
    });
    // keep a short result in view while the inputs above it are edited (a tall result is left in the page flow)
    document.querySelectorAll('[id$=\"-result\"].shiny-html-output').forEach(function (el) {
      var short = el.offsetHeight > 0 && el.offsetHeight <= window.innerHeight * 0.3;
      el.classList.toggle('pin-result', short);
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
