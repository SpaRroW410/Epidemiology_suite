// Times a published version of the app as a person would meet it (dev tool, not part of the test suite): the page until the navbar
// is visible, "Start the guide" until its first question is shown, and a Home quick link until that calculator's result is shown.
// Used on 2 Nov 2026 to find why the browser build took 80 s for the guide and 72 s for a Home button (#30).
// Usage: node tools/ui-audit/live_timing.js <url>   e.g. https://sparrow410.github.io/Epidemiology_suite/app/
// Needs Playwright with a Chromium (require('playwright')). Times are in seconds; page errors are listed at the end.
const { chromium } = require('playwright');
(async () => {
  const url = process.argv[2];
  if (!url) { console.error('usage: node tools/ui-audit/live_timing.js <url>'); process.exit(2); }
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1280, height: 900 } });
  const errors = []; page.on('pageerror', (e) => errors.push(String(e)));
  // the browser build runs inside an iframe; the server versions do not
  const app = () => page.frames().find((f) => f.url().includes('/app') && f !== page.mainFrame()) || page.mainFrame();
  const t0 = Date.now(); const s = (t) => ((Date.now() - t) / 1000).toFixed(1);
  await page.goto(url, { waitUntil: 'load', timeout: 300000 });
  await page.waitForFunction(() => true);
  let f = app();
  const deadline = Date.now() + 300000;
  while (Date.now() < deadline) {
    f = app();
    if (await f.locator('#home_go_wizard').first().isVisible().catch(() => false)) break;
    await page.waitForTimeout(500);
  }
  console.log(`page until Home is usable: ${s(t0)} s`);
  let t = Date.now();
  await f.locator('#home_go_wizard').first().click();
  await f.locator('#design_wizard_freetext').first().waitFor({ state: 'visible', timeout: 300000 });
  console.log(`"Start the guide" until the guide is shown: ${s(t)} s`);
  await f.locator("a[data-value='Home']").first().click();
  await f.locator('#home_quick_proportion').first().waitFor({ state: 'visible', timeout: 60000 });
  t = Date.now();
  await f.locator('#home_quick_proportion').first().click();
  await f.locator('#proportion-result').first().waitFor({ state: 'visible', timeout: 300000 });
  await f.waitForFunction(() => { const e = document.querySelector('#proportion-result'); return e && e.innerText.trim().length > 0; }, null, { timeout: 300000 });
  console.log(`Home quick link until the Proportions result is shown: ${s(t)} s`);
  console.log('page errors:', errors.length ? errors : 'none');
  await browser.close();
})();
