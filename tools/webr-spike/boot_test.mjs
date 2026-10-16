// Shinylive spike, stage 2: open the exported site in headless Chrome and measure how long it
// takes until the app's UI is on screen, whether there are errors, and whether a calculation
// runs. Usage: node boot_test.mjs <url> <screenshot.png> <report.json>
import { chromium } from "playwright-core";
import fs from "node:fs";

const [url, shot, reportPath] = process.argv.slice(2);
const report = { url, started: new Date().toISOString(), console_errors: [], page_errors: [], requests: 0, bytes: 0 };
const browser = await chromium.launch({ executablePath: "/usr/bin/google-chrome", args: ["--no-sandbox"] });
const page = await browser.newPage();
report.load_lines = [];
page.on("console", (m) => {
  const t = m.text();
  if (/LOAD |SOURCE FAILED|unable to load shared object|could not load dynamic lib/.test(t)) report.load_lines.push(t.slice(0, 300));
  else if (m.type() === "error" && !/Downloading webR package/.test(t)) report.console_errors.push(t.slice(0, 300));
});
page.on("pageerror", (e) => report.page_errors.push(String(e).slice(0, 300)));
page.on("response", async (r) => { report.requests++; try { const b = await r.body(); report.bytes += b.length; } catch (e) {} });

const t0 = Date.now();
await page.goto(url, { waitUntil: "load", timeout: 120000 });
report.page_load_s = (Date.now() - t0) / 1000;
try {
  // Shinylive renders the app in an iframe; the navbar title is the signal that the UI is up.
  const frame = page.frameLocator("iframe").first();
  await frame.locator("text=epidemiologicasuite").first().waitFor({ timeout: 480000 });
  report.ui_visible_s = (Date.now() - t0) / 1000;
  // Open a calculator and check that a result renders.
  await frame.locator("a[data-value='Plan: Sample Size']").first().click({ timeout: 60000 });
  await frame.locator("a[data-value='Rule of Three']").first().click({ timeout: 60000 });
  const t1 = Date.now();
  await frame.locator("#rule_of_three-result").waitFor({ state: "visible", timeout: 300000 });
  report.first_calc_s = (Date.now() - t1) / 1000;
  report.calc_text = (await frame.locator("#rule_of_three-result").innerText({ timeout: 30000 }).catch(() => "")).slice(0, 300);
  report.output_errors = await frame.locator(".shiny-output-error").count();
  report.ok = true;

  // Crawl: open every module of every workbench and record whether its outputs render or error.
  if (process.env.CRAWL === "1") {
    const handle = await page.locator("iframe").first().elementHandle();
    const f = await handle.contentFrame();
    const clickByValue = (dv) => f.evaluate((dv) => {
      const a = [...document.querySelectorAll("a[data-value]")].find((e) => e.getAttribute("data-value") === dv && e.offsetParent !== null);
      if (a) { a.click(); return true; }
      return false;
    }, dv);
    const workbenches = ["Plan: Sample Size", "Analyze"];
    report.modules = [];
    for (const wb of workbenches) {
      await clickByValue(wb);
      await page.waitForTimeout(1500);
      const titles = await f.evaluate(() => [...document.querySelectorAll("ul.nav-stacked a[data-value]")]
        .filter((e) => e.offsetParent !== null).map((e) => e.getAttribute("data-value")));
      for (const title of titles) {
        const rec = { workbench: wb, title };
        const t2 = Date.now();
        await clickByValue(title);
        await page.waitForTimeout(2500);
        const probe = () => f.evaluate(() => {
          const vis = (e) => e.offsetParent !== null;
          const outs = [...document.querySelectorAll(".shiny-html-output, .shiny-text-output, .shiny-plot-output, .shiny-bound-output")].filter(vis);
          const errs = outs.filter((e) => e.classList.contains("shiny-output-error")).map((e) => e.innerText.replace(/\s+/g, " ").slice(0, 160));
          const danger = [...document.querySelectorAll(".text-danger")].filter(vis).map((e) => e.innerText.replace(/\s+/g, " ").slice(0, 160));
          const prefix = (outs.map((e) => e.id).filter((x) => x.includes("-") && !/^home/.test(x))[0] || "").split("-")[0];
          const res = prefix ? document.getElementById(prefix + "-result") : null;
          return { prefix, has_result: !!res, result: res ? res.innerText.replace(/\s+/g, " ").slice(0, 100) : "", errs, danger };
        });
        let info = await probe();
        rec.prefix = info.prefix; rec.has_result = info.has_result;
        rec.designs = [];
        // every value of the module's primary radio selector (what the native every-design UI test does)
        const radio = await f.evaluate((prefix) => {
          for (const g of ["design", "outcome", "mode", "es_type"]) {
            const vals = [...document.querySelectorAll("input[type=radio]")].filter((e) => e.name === prefix + "-" + g).map((e) => e.value);
            if (vals.length) return { name: prefix + "-" + g, vals };
          }
          return null;
        }, info.prefix);
        const visit = async (label, waited) => {
          const p = await probe();
          const bad = p.errs.length || p.danger.length;
          rec.designs.push({ design: label, waited, status: bad ? "ERROR" : p.result || !p.has_result ? "ok" : "empty", detail: (p.errs[0] || p.danger[0] || p.result || "").slice(0, 110) });
        };
        if (radio) {
          for (const v of radio.vals) {
            await f.evaluate((a) => { const r = [...document.querySelectorAll("input[type=radio]")].find((e) => e.name === a.name && e.value === a.v); if (r) r.click(); }, { name: radio.name, v });
            let waited = 0;
            for (; waited < 25; waited++) {
              await page.waitForTimeout(1000);
              const p = await probe();
              if (p.errs.length || p.danger.length || (p.has_result && p.result.length > 0) || (!p.has_result && waited >= 2)) break;
            }
            await visit(v, waited + 1);
          }
        } else {
          await visit("(single view)");
        }
        rec.status = rec.designs.some((d) => d.status === "ERROR") ? "ERROR" : rec.designs.every((d) => d.status === "ok") ? "ok" : "partial";
        rec.seconds = (Date.now() - t2) / 1000;
        report.modules.push(rec);
        console.log("MOD " + JSON.stringify({ title: rec.title, status: rec.status, n: rec.designs.length, bad: rec.designs.filter((d) => d.status !== "ok") }));
      }
    }
    for (const m of report.modules) {
      for (const d of m.designs.filter((x) => x.status !== "ok")) console.log("SUM " + m.title + " | " + d.design + " | " + d.status + " | waited " + d.waited + " | " + d.detail);
    }
    report.module_summary = {
      total: report.modules.length,
      modules_ok: report.modules.filter((m) => m.status === "ok").length,
      modules_error: report.modules.filter((m) => m.status === "ERROR").length,
      modules_partial: report.modules.filter((m) => m.status === "partial").length,
      designs_total: report.modules.reduce((n, m) => n + m.designs.length, 0),
      designs_error: report.modules.reduce((n, m) => n + m.designs.filter((d) => d.status === "ERROR").length, 0),
      designs_empty: report.modules.reduce((n, m) => n + m.designs.filter((d) => d.status === "empty").length, 0),
    };
  }
} catch (e) {
  report.ok = false;
  report.failure = String(e).slice(0, 500);
}
report.total_s = (Date.now() - t0) / 1000;
await page.screenshot({ path: shot, fullPage: false });
fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
console.log(JSON.stringify(report, null, 2));
await browser.close();
