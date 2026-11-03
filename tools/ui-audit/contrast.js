// Text whose colour contrast against its background is below 3:1 (WCAG 2.x formula), for tools/ui-audit/contrast.R.
// Walks every visible text node; returns one line per element: "ratio | element | colour on background | text".
(function () {
  function parse(c) { var m = c.match(/rgba?\(([^)]+)\)/); if (!m) return null; var p = m[1].split(/[ ,\/]+/).filter(Boolean).map(Number); return { r: p[0], g: p[1], b: p[2], a: p.length > 3 ? p[3] : 1 }; }
  function lum(c) { var f = function (v) { v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); }; return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b); }
  function bgOf(el) { for (var e = el; e; e = e.parentElement) { var c = parse(getComputedStyle(e).backgroundColor); if (c && c.a > 0.5) return c; } return parse(getComputedStyle(document.body).backgroundColor); }
  var out = [];
  var walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
  var seen = new Set();
  while (walker.nextNode()) {
    var t = walker.currentNode; if (!t.nodeValue.trim()) continue;
    var el = t.parentElement; if (!el || seen.has(el)) continue; seen.add(el);
    if (el.closest('script,style,mjx-assistive-mml,.visually-hidden,.MJX_Assistive_MathML')) continue;
    var r = el.getBoundingClientRect(); if (r.width === 0 || r.height === 0 || el.offsetParent === null) continue;
    var cs = getComputedStyle(el); if (cs.visibility === 'hidden' || parseFloat(cs.opacity) < 0.3) continue;
    var fg = parse(cs.color), bg = bgOf(el); if (!fg || !bg) continue;
    var l1 = lum(fg), l2 = lum(bg), ratio = (Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05);
    if (ratio < 3) out.push(ratio.toFixed(2) + ' | ' + el.tagName.toLowerCase() + '.' + (el.className || '').toString().slice(0, 40) + ' | ' + cs.color + ' on ' + 'rgb(' + bg.r + ',' + bg.g + ',' + bg.b + ') | ' + t.nodeValue.trim().slice(0, 50));
  }
  return out;
})()
