# Filter box over the calculator lists (docs/ui_remap_plan.md, step 4; owner's choices 27 Nov 2026): typing narrows the sidebar to
# the calculators whose name or one-line description (the hover text, R/content_module_blurbs.R) contains every word typed, and lists
# the matches in the other workbench too (Plan and Analyze), with a link that opens them. One box per sidebar, kept in step. Runs in
# the browser only (no round trip to R), so it works in the browser build; hidden on phones, where the sidebar is a drop-down.
sidebar_filter_assets <- function() {
  tagList(
    tags$style(HTML("
.sidebar-filter { margin: 0 0 .5rem 0; }
.sidebar-filter input { font-size: .85rem; }
.sidebar-filter .sf-other { font-size: .8rem; margin-top: .35rem; }
.sidebar-filter .sf-other a { display: inline-block; margin-right: .6rem; }
.sidebar-filter .sf-none { font-size: .8rem; color: var(--bs-secondary-color); margin-top: .35rem; }
@media (max-width: 575.98px) { .sidebar-filter { display: none; } }
")),
    tags$script(HTML("
(function () {
  function lists() { return Array.prototype.slice.call(document.querySelectorAll('ul.nav-stacked')); }
  function words(s) { return s.toLowerCase().split(/\\s+/).filter(function (w) { return w.length; }); }
  function text(a) { var sp = a.querySelector('span[title]'); return (a.textContent + ' ' + (sp ? sp.getAttribute('title') : '')).toLowerCase(); }
  function matches(a, ws) { var t = text(a); return ws.every(function (w) { return t.indexOf(w) >= 0; }); }
  function paneOf(ul) { return ul.closest('.tab-pane'); }
  function tabFor(pane) {
    return pane && document.querySelector('nav.navbar a[data-bs-target=\"#' + pane.id + '\"], nav.navbar a[href=\"#' + pane.id + '\"]');
  }
  function apply(q) {
    var ws = words(q), all = lists();
    all.forEach(function (ul) {
      var shown = 0, head = null, headShown = false;
      Array.prototype.forEach.call(ul.children, function (li) {
        if (li.classList.contains('navbar-brand')) {
          if (head) head.style.display = (headShown || !ws.length) ? '' : 'none';
          head = li; headShown = false; return;
        }
        var a = li.querySelector('a[data-value]');
        if (!a) return;
        var ok = !ws.length || matches(a, ws);
        li.style.display = ok ? '' : 'none';
        if (ok) { shown++; headShown = true; }
      });
      if (head) head.style.display = (headShown || !ws.length) ? '' : 'none';
      var box = ul.parentNode.querySelector('.sidebar-filter');
      if (!box) return;
      var other = box.querySelector('.sf-other'), none = box.querySelector('.sf-none');
      other.innerHTML = ''; none.textContent = '';
      if (!ws.length) return;
      all.forEach(function (ul2) {
        if (ul2 === ul) return;
        var hits = Array.prototype.filter.call(ul2.querySelectorAll('a[data-value]'), function (a) { return matches(a, ws); });
        if (!hits.length) return;
        var tab = tabFor(paneOf(ul2));
        var lab = document.createElement('div');
        lab.textContent = 'Also in ' + (tab ? tab.textContent.trim() : 'another workbench') + ':';
        other.appendChild(lab);
        hits.forEach(function (a) {
          var l = document.createElement('a'); l.href = '#'; l.textContent = a.textContent.trim();
          l.addEventListener('click', function (e) {
            e.preventDefault();
            if (tab) tab.click();
            setTimeout(function () { a.click(); }, 150);
          });
          other.appendChild(l);
        });
      });
      if (!shown && !other.childNodes.length) none.textContent = 'No calculator matches. Try fewer words, or the guide on Home.';
    });
  }
  function build() {
    lists().forEach(function (ul) {
      if (ul.getAttribute('data-sidebar-filter')) return;
      ul.setAttribute('data-sidebar-filter', '1');
      var box = document.createElement('div'); box.className = 'sidebar-filter';
      var inp = document.createElement('input');
      inp.type = 'search'; inp.className = 'form-control form-control-sm';
      inp.placeholder = 'Filter calculators (name or what it does)';
      inp.setAttribute('aria-label', 'Filter the calculator list');
      var other = document.createElement('div'); other.className = 'sf-other'; other.setAttribute('aria-live', 'polite');
      var none = document.createElement('div'); none.className = 'sf-none'; none.setAttribute('aria-live', 'polite');
      box.appendChild(inp); box.appendChild(other); box.appendChild(none);
      ul.parentNode.insertBefore(box, ul.parentNode.firstChild);
      inp.addEventListener('input', function () {
        document.querySelectorAll('.sidebar-filter input').forEach(function (o) { if (o !== inp) o.value = inp.value; });
        apply(inp.value);
      });
    });
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', build); else build();
  document.addEventListener('shiny:connected', build);
})();
"))
  )
}
