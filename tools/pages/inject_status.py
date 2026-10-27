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
html = html.replace("</body>", snippet + "\n</body>", 1)
index.write_text(html, encoding="utf-8")
print("overlay injected into", index)
