const { chromium } = require("playwright");
const fs = require("node:fs");

(async () => {
  const base = process.env.SIGNOZ_URL || "http://localhost:8080";
  const email = process.env.SIGNOZ_EMAIL || process.env.SIGNOZ_USER;
  const pass  = process.env.SIGNOZ_PASSWORD || process.env.SIGNOZ_PASS;

  const browser = await chromium.launch({ headless: false });
  const storagePath = "artifacts/signoz-auth.json";
  const ctx = fs.existsSync(storagePath)
    ? await browser.newContext({ storageState: storagePath })
    : await browser.newContext();
  const page = await ctx.newPage();

  // Reuse session if available
  try { await ctx.addCookies([{ name: "IS_LOGGED_IN", value: "true", domain: "localhost", path: "/" }]); } catch {}

  // Login (email -> Next -> password -> Sign in) if needed
  await page.goto(base, { waitUntil: "domcontentloaded" });
  const already = await page.evaluate(() => localStorage.getItem("IS_LOGGED_IN") === "true");
  if (!already && email && pass) {
    await page.locator("input[type='email'], input[type='text']").first().fill(email);
    const next = page.getByRole("button", { name: /next/i }).first();
    if (await next.isVisible().catch(() => false)) {
      await next.click();
      await page.waitForLoadState("networkidle");
    }
    const pw = page.locator("input[type='password'], [data-testid='password'], #currentPassword, #loginPassword").first();
    await pw.waitFor({ state: 'visible', timeout: 15000 }).catch(() => {});
    await pw.fill(pass);

    const submitVariants = [
      page.getByRole("button", { name: /sign\s*in/i }).first(),
      page.getByRole("button", { name: /log\s*in/i }).first(),
      page.getByRole("button", { name: /submit/i }).first(),
      page.locator("button[type='submit']").first()
    ];
    let clicked = false;
    for (const btn of submitVariants) {
      if (await btn.isVisible().catch(() => false)) {
        await btn.click().catch(() => {});
        clicked = true;
        break;
      }
    }
    if (!clicked) {
      // Fallback: press Enter on password field
      await pw.press('Enter').catch(() => {});
    }
    await page.waitForFunction(() => localStorage.getItem("IS_LOGGED_IN") === "true", { timeout: 30000 });
    // Persist session for future runs
    fs.mkdirSync('artifacts', { recursive: true });
    await ctx.storageState({ path: storagePath });
  }

  // Go to dashboards
  await page.goto(`${base}/dashboard`, { waitUntil: "domcontentloaded" });
  await page.waitForLoadState("networkidle");

  // Try to surface any Import entry points
  const candidates = [
    "button:has-text('Import')",
    "button:has-text('Import JSON')",
    "button:has-text('Import dashboard')",
    "button:has-text('New dashboard')",
    "button:has-text('Create dashboard')",
    "[role='menuitem']:has-text('Import')",
    "[aria-label*='More' i], button:has-text('More')"
  ];

  console.log("== Visible Import triggers ==");
  for (const sel of candidates) {
    const loc = page.locator(sel);
    const n = await loc.count();
    if (n) {
      for (let i = 0; i < n; i++) {
        const el = loc.nth(i);
        const vis = await el.isVisible().catch(() => false);
        if (vis) {
          const txt = (await el.innerText().catch(() => "")).trim();
          console.log(`- ${sel} :: "${txt}"`);
        }
      }
    }
  }

  // If we found a New/Create menu, click it and list menuitems
  const menuOpeners = [page.getByRole("button", { name: /\+?\s*new dashboard/i }).first(),
                       page.getByRole("button", { name: /create dashboard/i }).first()];
  for (const op of menuOpeners) {
    if (await op.isVisible().catch(() => false)) {
      await op.click().catch(() => {});
      await page.waitForTimeout(300);
      const items = page.locator("[role='menuitem']");
      const c = await items.count();
      console.log("== Menu items ==");
      for (let i = 0; i < c; i++) {
        const it = items.nth(i);
        const t = (await it.innerText().catch(() => "")).trim();
        if (t) console.log(`* ${t}`);
      }
      break;
    }
  }

  // Look for inputs if an import modal is already on screen
  const hasFile = await page.locator("input[type='file']").first().isVisible().catch(() => false);
  const hasText = await page.locator("textarea, [role='textbox'], .monaco-editor textarea").first().isVisible().catch(() => false);
  console.log(`== Inputs present ==\nfileInput=${hasFile}  pasteArea=${hasText}`);

  await page.screenshot({ path: "artifacts/import-ui-probe.png", fullPage: true }).catch(() => {});
  console.log("Probe screenshot -> artifacts/import-ui-probe.png");
  await browser.close();
})();
