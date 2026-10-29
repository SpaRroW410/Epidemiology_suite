# The phone layout (narrow screens, up to 575 px wide): the same app, shaped for one hand and one column.
#   * the navbar becomes a bar of large tabs fixed to the bottom of the screen (Home, Plan, Analyze, Cite), where a thumb reaches;
#   * the long calculator list becomes one drop-down ("Choose a calculator", grouped like the list);
#   * form controls and buttons get a touch-sized height, and the pinned result sits above the bottom bar.
# Wider screens are unchanged: the drop-down and the bottom bar only appear under the breakpoint. No second app, no second URL.

phone_shell_assets <- function() {
  tagList(
    tags$style(HTML("
.phone-picker { display: none; }
@media (max-width: 575.98px) {
  /* the navbar's collapsed menu becomes a bottom tab bar */
  nav.navbar .navbar-toggle, nav.navbar .navbar-toggler { display: none !important; }
  nav.navbar .navbar-collapse, nav.navbar .navbar-collapse.collapse {
    display: flex !important; position: fixed; left: 0; right: 0; bottom: 0; z-index: 1040; height: auto !important;
    background: var(--bs-body-bg); border-top: 2px solid var(--bs-border-color); padding: 0 .25rem;
    box-shadow: 0 -4px 10px rgba(0, 0, 0, .08);
    padding-bottom: env(safe-area-inset-bottom);
  }
  nav.navbar .navbar-collapse > ul, nav.navbar .navbar-nav { display: flex !important; flex-direction: row !important; width: 100%; margin: 0 !important; align-items: stretch; }
  nav.navbar .navbar-nav > li.nav-item { flex: 1 1 0; text-align: center; }
  nav.navbar .navbar-nav > li.nav-item > .nav-link { padding: .9rem .25rem !important; font-size: .9rem; font-weight: 600; min-height: 3rem; color: var(--bs-body-color) !important; }
  nav.navbar .navbar-nav > li.nav-item > .nav-link.active { color: var(--bs-primary) !important; box-shadow: inset 0 3px 0 var(--bs-primary); }
  html[data-bs-theme='dark'] nav.navbar .navbar-nav > li.nav-item > .nav-link.active { color: var(--bs-primary-text-emphasis) !important; }
  nav.navbar .navbar-nav > li.bslib-nav-item { flex: 0 0 auto; margin-left: 0 !important; display: flex; align-items: center; }
  nav.navbar .navbar-nav > li.bslib-nav-item bslib-input-dark-mode, nav.navbar .navbar-nav > li.bslib-nav-item .btn { color: var(--bs-body-color) !important; }
  nav.navbar .navbar-nav > li.bslib-nav-item:has(#nav_search) { display: none; }   /* the search box on Home does that job on a phone */
  body { padding-bottom: 4rem; }
  .pin-result { bottom: 3.2rem; }
  html { scroll-padding-bottom: 10rem; }
  /* one drop-down instead of a long list of calculators */
  .phone-picker { display: block; margin: .5rem 0 1rem; font-size: 1rem; min-height: 2.75rem; }
  ul.nav-stacked { display: none !important; }
  /* touch-sized controls */
  .form-control, .form-select, .selectize-input { min-height: 2.75rem; }
  .btn { min-height: 2.5rem; }
  .accordion-button { min-height: 3rem; }
}
")),
    tags$script(HTML("
(function () {
  function build() {
    document.querySelectorAll('ul.nav-stacked').forEach(function (ul) {
      if (ul.getAttribute('data-phone-picker')) return;
      ul.setAttribute('data-phone-picker', '1');
      var sel = document.createElement('select');
      sel.className = 'form-select phone-picker';
      sel.setAttribute('aria-label', 'Choose a calculator');
      var group = null;
      Array.prototype.forEach.call(ul.children, function (li) {
        if (li.classList.contains('navbar-brand')) {
          group = document.createElement('optgroup'); group.label = li.textContent.trim(); sel.appendChild(group);
        } else {
          var a = li.querySelector('a[data-value]');
          if (!a) return;
          var o = document.createElement('option');
          o.textContent = a.textContent.trim(); o.value = a.getAttribute('data-value');
          (group || sel).appendChild(o);
        }
      });
      sel.addEventListener('change', function () {
        var v = sel.value;
        Array.prototype.forEach.call(ul.querySelectorAll('a[data-value]'), function (a) { if (a.getAttribute('data-value') === v) a.click(); });
      });
      ul.parentNode.insertBefore(sel, ul);
      sync(ul, sel);
    });
  }
  function sync(ul, sel) {
    var act = ul.querySelector('a.active[data-value]');
    if (act) sel.value = act.getAttribute('data-value');
  }
  function syncAll() {
    document.querySelectorAll('ul.nav-stacked[data-phone-picker]').forEach(function (ul) {
      var sel = ul.previousElementSibling;
      if (sel && sel.classList.contains('phone-picker')) sync(ul, sel);
    });
  }
  // on a phone the bar is narrow: the long tab name is shortened (the full name stays as the accessible name)
  var phone = window.matchMedia('(max-width: 575.98px)');
  function shorten() {
    document.querySelectorAll('nav.navbar .navbar-nav > li.nav-item > a.nav-link').forEach(function (a) {
      var full = a.getAttribute('data-full-label') || a.textContent.trim();
      a.setAttribute('data-full-label', full);
      if (full === 'Plan: Sample Size') {
        a.textContent = phone.matches ? 'Plan' : full;
        a.setAttribute('aria-label', full);
      }
    });
  }
  if (phone.addEventListener) phone.addEventListener('change', shorten);
  document.addEventListener('shown.bs.tab', syncAll);
  document.addEventListener('DOMContentLoaded', function () {
    build(); shorten();
    new MutationObserver(function () { build(); }).observe(document.body, { childList: true, subtree: true });
  });
})();"))
  )
}
