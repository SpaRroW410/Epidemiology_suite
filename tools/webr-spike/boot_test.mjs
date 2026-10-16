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
        // wait until some output of this module has text, or an error shows, up to 40 s
        let info = null;
        for (let i = 0; i < 40; i++) {
          await page.waitForTimeout(1000);
          info = await f.evaluate(() => {
            const outs = [...document.querySelectorAll(".shiny-html-output, .shiny-text-output, .shiny-plot-output, .shiny-bound-output")].filter((e) => e.offsetParent !== null);
            const errs = outs.filter((e) => e.classList.contains("shiny-output-error")).map((e) => e.innerText.slice(0, 160));
            const withText = outs.filter((e) => !e.classList.contains("shiny-output-error") && e.innerText.trim().length > 15 && !/^home/.test(e.id));
            const prefix = (outs.map((e) => e.id).filter((x) => x.includes("-"))[0] || "").split("-")[0];
            return { errors: errs, n_outputs: outs.length, text: withText.length ? withText[0].innerText.replace(/\s+/g, " ").slice(0, 110) : "", prefix };
          });
          if (info.errors.length || info.text) break;
        }
        rec.prefix = info.prefix; rec.n_outputs = info.n_outputs;
        rec.status = info.errors.length ? "ERROR" : info.text ? "ok" : "no output (button-driven or empty)";
        rec.detail = info.errors.length ? info.errors[0] : info.text;
        rec.seconds = (Date.now() - t2) / 1000;
        report.modules.push(rec);
        console.log(JSON.stringify(rec));
      }
    }
    report.module_summary = {
      total: report.modules.length,
      ok: report.modules.filter((m) => m.status === "ok").length,
      error: report.modules.filter((m) => m.status === "ERROR").length,
      no_output: report.modules.filter((m) => m.status.startsWith("no output")).length,
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
