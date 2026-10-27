#!/usr/bin/env python3
"""Put tools/pages/status_overlay.html just before </body> of the exported Shinylive index.html, and give the page a proper title.
Usage: python3 tools/pages/inject_status.py <path to exported index.html>"""
import sys, pathlib
index = pathlib.Path(sys.argv[1])
snippet = (pathlib.Path(__file__).parent / "status_overlay.html").read_text(encoding="utf-8")
html = index.read_text(encoding="utf-8")
if "s2r-status" in html:
    sys.exit("overlay already present")
if "</body>" not in html:
    sys.exit("no </body> in " + str(index))
html = html.replace("<title>Shiny App</title>", "<title>epidemiologicasuite</title>", 1)

# the phone version: redirect phones there when its address is set, and offer the link in the "still starting" message
urls = [l.strip() for l in (pathlib.Path(__file__).parent / "mobile_url.txt").read_text(encoding="utf-8").splitlines()
        if l.strip() and not l.lstrip().startswith("#")]
mobile = urls[0] if urls else ""
if mobile:
    redirect = (pathlib.Path(__file__).parent / "mobile_redirect.html").read_text(encoding="utf-8").replace("__MOBILE_URL__", mobile)
    if "<head>" not in html:
        sys.exit("no <head> in " + str(index))
    html = html.replace("<head>", "<head>\n" + redirect, 1)
    snippet = snippet.replace("__MOBILE_URL__", mobile)
else:
    snippet = snippet.replace("__MOBILE_URL__", "")
html = html.replace("</body>", snippet + "\n</body>", 1)
index.write_text(html, encoding="utf-8")
print("overlay injected into", index, "| phone redirect:", mobile or "off")
