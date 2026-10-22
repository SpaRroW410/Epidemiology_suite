#!/bin/bash
# Fails unless the boot report written by tools/webr-spike/boot_test.mjs shows a working browser build:
# the UI came up, a calculator rendered a result, no output errors, and no source file failed to load.
set -euo pipefail
report="$1"
jq . "$report" | head -40
jq -e '.ok == true and .output_errors == 0 and ([.load_lines[]? | select(test("SOURCE FAILED"))] | length) == 0' "$report" >/dev/null \
  || { echo "browser build check FAILED"; exit 1; }
echo "browser build check passed: UI visible after $(jq .ui_visible_s "$report") s, first calculation $(jq .first_calc_s "$report") s"
