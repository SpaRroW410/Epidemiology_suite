// Browser smoke test for the container: open the app, wait for the navbar, open a calculator and read a result.
// Usage: node smoke.mjs http://localhost:3838/
import { chromium } from "playwright-core";

const url = process.argv[2] || "http://localhost:3838/";
const browser = await chromium.launch({ executablePath: process.env.CHROME || "/usr/bin/google-chrome", args: ["--no-sandbox"] });
const page = await browser.newPage();
const errors = [];
page.on("pageerror", (e) => errors.push(String(e)));
const t0 = Date.now();
await page.goto(url, { waitUntil: "load", timeout: 120000 });
await page.locator("text=epidemiologicasuite").first().waitFor({ timeout: 120000 });
console.log(`navbar after ${(Date.now() - t0) / 1000}s`);
await page.locator("a[data-value='Plan: Sample Size']").first().click();
await page.locator("a[data-value='Rule of Three']").first().click();
await page.locator("#rule_of_three-result").waitFor({ state: "visible", timeout: 60000 });
const text = await page.locator("#rule_of_three-result").innerText();
console.log("rule of three:", text.replace(/\s+/g, " ").slice(0, 120));
const bad = await page.locator(".shiny-output-error").count();
await browser.close();
if (!/Exact upper bound: 0\.0950/.test(text)) { console.error("unexpected result text"); process.exit(1); }
if (bad > 0 || errors.length) { console.error("errors:", bad, errors); process.exit(1); }
console.log("OK");
