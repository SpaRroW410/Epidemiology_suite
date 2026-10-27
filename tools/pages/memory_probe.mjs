// How much memory does the browser build need? Opens the exported site in headless Chrome at a phone size and samples the
// renderer process's resident memory every 2 s until the UI is visible and for `settle` seconds after it (background loading).
// A phone tab is killed by the operating system when it uses too much memory (iOS Safari: roughly 1.5 GB or less depending on
// the phone), which shows as a blank page or "a problem repeatedly occurred" -- so the peak matters more than the load time.
// Usage: node memory_probe.mjs <url> <marker text> <report.json> [settle seconds]
import { chromium, devices } from "playwright-core";
import { execSync } from "node:child_process";
import fs from "node:fs";

const [url, marker, out, settleArg] = process.argv.slice(2);
const settle = Number(settleArg || 30);
const browser = await chromium.launch({ executablePath: "/usr/bin/google-chrome", args: ["--no-sandbox"] });
const page = await (await browser.newContext({ ...devices["iPhone 13"] })).newPage();
const rss = () => {
  try { return Number(execSync("ps -eo rss,args | grep -E 'chrome.*--type=renderer' | grep -v grep | awk '{s+=$1} END {print s/1024}'").toString().trim() || 0); }
  catch (e) { return 0; }
};
const series = []; const stages = []; const t0 = Date.now();
page.on("console", (m) => { const t = m.text(); if (t.includes("MEMSTAGE")) stages.push(t.replace(/^.*MEMSTAGE /, "")); });
const iv = setInterval(() => series.push([Math.round((Date.now() - t0) / 1000), Math.round(rss())]), 2000);
await page.goto(url, { waitUntil: "load", timeout: 120000 });
let ui = null;
try {
  await page.frameLocator("iframe").first().locator(`text=${marker}`).first().waitFor({ timeout: 420000 });
  ui = (Date.now() - t0) / 1000;
} catch (e) { /* UI never appeared */ }
await page.waitForTimeout(settle * 1000);
clearInterval(iv);
const peak = Math.max(0, ...series.map((s) => s[1]));
const report = { url, marker, ui_visible_s: ui, peak_renderer_rss_mb: peak, final_renderer_rss_mb: series.at(-1)?.[1], stages, series };
fs.writeFileSync(out, JSON.stringify(report));
console.log(JSON.stringify({ ...report, series: undefined }));
for (const s of stages) console.log("STAGE " + s);
await browser.close();
