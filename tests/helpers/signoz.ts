import { expect, Page } from '@playwright/test';
import fs from 'node:fs';

export const SIGNOZ_URL = process.env.SIGNOZ_URL || 'http://localhost:8080';

export async function goto(page: Page, pathOrUrl: string) {
  const isAbsolute = /^https?:/i.test(pathOrUrl);
  const url = isAbsolute ? pathOrUrl : `${SIGNOZ_URL}${pathOrUrl}`;
  const navAbortMs = 45_000;
  const started = Date.now();
  let labelSuffix = '';
  try {
    labelSuffix = encodeURIComponent(isAbsolute ? new URL(url).pathname : pathOrUrl);
  } catch {
    labelSuffix = encodeURIComponent(pathOrUrl);
  }

  try {
    await page.goto(url, { waitUntil: 'domcontentloaded', timeout: navAbortMs });
  } catch (err) {
    await logState(page, `goto-timeout-${labelSuffix}`);
    throw err;
  }

  try {
    await page.waitForLoadState('networkidle');
  } catch (err) {
    await logState(page, `networkidle-timeout-${labelSuffix}`);
    throw err;
  }

  const elapsed = Date.now() - started;
  if (elapsed > 10_000) {
    console.warn('[slow-nav]', url, `${elapsed}ms`);
  }
}

export async function logState(page: Page, label: string) {
  const safeBase = (label || 'state').replace(/[^a-z0-9-_]/gi, '_').slice(0, 60) || 'state';
  try {
    fs.mkdirSync('artifacts', { recursive: true });
    await page.screenshot({ path: `artifacts/${safeBase}.png`, fullPage: true }).catch(() => {});
    const html = await page.content().catch(() => '');
    if (html) {
      fs.writeFileSync(`artifacts/${safeBase}.html`, html);
    }
  } catch (error) {
    console.warn('[logState]', safeBase, 'capture failed', error?.message ?? '');
  }
}

export async function ensureAt(page: Page, absoluteOrPath: string) {
  const targetUrl = absoluteOrPath.startsWith('http') ? absoluteOrPath : `${SIGNOZ_URL}${absoluteOrPath}`;
  const href = page.url();
  if (!href.startsWith(targetUrl)) {
    await goto(page, absoluteOrPath);
  }
}

export async function openInNewTab(page: Page, absoluteOrPath: string) {
  const ctx = page.context();
  const p2 = await ctx.newPage();
  await ensureAt(p2, absoluteOrPath);
  return p2;
}

export async function loginIfNeeded(page: Page) {
  const email = process.env.SIGNOZ_EMAIL || process.env.SIGNOZ_USER;
  const password = process.env.SIGNOZ_PASSWORD || process.env.SIGNOZ_PASS;
  if (!email || !password) return;

  // Copy exact flow from signoz.final.spec.ts ensureAuthenticated function
  await page.goto(SIGNOZ_URL, { waitUntil: "domcontentloaded" });

  const alreadyLoggedIn = await page.evaluate(() => {
    try {
      return window.localStorage.getItem("IS_LOGGED_IN") === "true";
    } catch {
      return false;
    }
  });

  if (alreadyLoggedIn) {
    console.log("SigNoz session already active; skipping login");
    return;
  }

  console.log("Authenticating against SigNoz...");

  await page.locator("input[type='email'], input[type='text']").first().fill(email);

  const nextButton = page.getByRole("button", { name: /next/i }).first();
  if (await nextButton.isVisible().catch(() => false)) {
    await nextButton.click();
    await page.waitForLoadState("networkidle", { timeout: 10_000 }).catch(() => {});
  }

  // Wait robustly for password field to appear after Next
  const passwordField = page
    .locator("input[type='password'], input#loginPassword, [data-testid='password']")
    .first();
  try {
    await passwordField.waitFor({ state: 'visible', timeout: 15_000 });
  } catch (e) {
    // Capture state for diagnostics and retry a gentle focus on the form
    await logState(page, 'login-password-missing');
  }

  await passwordField.fill(password);

  const submitButton = await page.getByRole("button", { name: /sign\s*in|log\s*in|submit/i }).first();
  await submitButton.click();

  await page.waitForFunction(() => {
    try {
      return window.localStorage.getItem("IS_LOGGED_IN") === "true";
    } catch {
      return false;
    }
  }, { timeout: 30_000 });

  console.log("SigNoz authentication complete");
  // Persist storage state for subsequent tests to reuse session
  try {
    fs.mkdirSync('artifacts', { recursive: true });
    await page.context().storageState({ path: 'artifacts/signoz-auth.json' });
  } catch {}
  // Land on dashboards tab and BLOCK until login completes (not /login)
  await ensureAt(page, '/dashboard');
  // Wait loop: require localStorage flag AND URL not containing '/login'
  await page.waitForFunction(() => {
    try {
      const ok = window.localStorage.getItem('IS_LOGGED_IN') === 'true';
      const notLogin = !/\/login($|\?|#)/.test(window.location.pathname);
      return ok && notLogin;
    } catch { return false; }
  }, { timeout: 45_000 }).catch(() => {});
  await page.waitForLoadState('networkidle').catch(() => {});
  await page.waitForTimeout(1000).catch(() => {});
}

export async function ensureDashboardsLoaded(page: Page) {
  await ensureAt(page, '/dashboard');

  const settleDashboards = async () => {
    await page.waitForLoadState('domcontentloaded').catch(() => {});
    const splashLocators = [
      page.getByText(/OpenTelemetry-Native Logs, Metrics and Traces in a single pane/i),
      page.locator('[data-testid*="app-loader"]'),
      page.locator('[data-test*="loading"]'),
    ];

    for (const splash of splashLocators) {
      if (await splash.count()) {
        await splash.first().waitFor({ state: 'hidden', timeout: 45000 }).catch(() => {});
      }
    }

    await page.waitForLoadState('networkidle').catch(() => {});
    await page.waitForTimeout(1500);
    // Soft-check for app shell navigation; do not block if missing on this build
    try {
      const navCandidate = page.locator('nav, [role="navigation"], [data-testid*="navbar"], header');
      if (await navCandidate.count()) {
        await navCandidate.first().waitFor({ state: 'visible', timeout: 10000 }).catch(() => {});
      }
    } catch {}
  };

  await settleDashboards();

  // Check if we're still on login page
  const stillOnLogin = /\/login($|\?|#)/.test(page.url()) ||
    (await page.getByText(/sign in to monitor/i).isVisible().catch(() => false));
  if (stillOnLogin) {
    // Attempt login once using provided env vars
    await loginIfNeeded(page);
    await page.waitForTimeout(500);
    await ensureAt(page, '/dashboard');
    // Require we're off the login route before proceeding
    await page.waitForFunction(() => !/\/login($|\?|#)/.test(window.location.pathname), { timeout: 45_000 }).catch(() => {});
    await settleDashboards();
  }

  // Check if we're on onboarding/welcome page
  const onWelcome = await page.getByText(/OpenTelemetry-Native Logs/i).isVisible().catch(() => false);
  if (onWelcome) {
    // Look for navigation menu or sidebar
    const navItems = [
      page.getByRole('link', { name: /dashboards?/i }),
      page.getByRole('button', { name: /dashboards?/i }),
      page.locator('a[href*="/dashboard"], a[href*="/dashboards"]'),
      page.locator('[data-testid*="dashboard"]'),
      page.getByRole('button', { name: /enter signoz|explore dashboards|view dashboards/i }),
    ];

    for (const nav of navItems) {
      try {
        const target = nav.first();
        await target.waitFor({ state: 'visible', timeout: 5000 });
        await target.click().catch(() => {});
        await settleDashboards();
        break;
      } catch {
        // Try next locator
      }
    }
  }

  const indicators = [
    page.getByRole('heading', { name: /dashboards?/i }),
    page.getByRole('heading', { name: /all dashboards?/i }),
    page.getByRole('button', { name: /\+?\s*new dashboard/i }),
    page.getByRole('button', { name: /import json|import/i }),
    page.getByRole('button', { name: /create dashboard/i }),
    page.getByText(/no dashboards/i),
    page.getByText(/create your first/i),
    page.getByText(/welcome/i),
    page.getByText(/get started/i),
    page.locator('[data-testid*="dashboard-card"]'),
    page.locator('[data-qa*="dashboard"]'),
    page.locator('table:has-text("Dashboard")'),
  ];

  for (const loc of indicators) {
    const candidate = loc.first();
    const visible = await candidate.isVisible().catch(() => false);
    if (visible) {
      return;
    }

    try {
      await candidate.waitFor({ state: 'visible', timeout: 5000 });
      return;
    } catch {
      // continue
    }
  }

  await logState(page, 'dashboards-missing');
  // Take a screenshot for debugging
  await page.screenshot({ path: 'debug-dashboards-page.png' });
  throw new Error('No dashboard indicators found on /dashboards page');
}


export async function deleteCustomDashboards(page: Page, opts: { aggressive?: boolean } = {}) {
  const aggressive = !!opts.aggressive;
  await ensureDashboardsLoaded(page);

  for (let i = 0; i < 30; i++) {
    const actionMenu = page.locator('button[aria-label*="More"], button[title*="More"], button:has-text("…"), button:has-text("...")').nth(i);
    if (!(await actionMenu.count())) break;
    await actionMenu.click().catch(() => {});

    const row = page.locator('tr').nth(i);
    const nameCell = row.locator('td').first();
    const name = ((await nameCell.textContent()) || '').trim();
    const looksCustom = /^OTel |^Sleek |^Playwright |^Temp |^Test /i.test(name);
    if (!aggressive && !looksCustom) continue;

    const del = page.getByRole('button', { name: /^delete$/i }).first();
    if (await del.count()) {
      await del.click().catch(async () => {
        await page.getByText(/^Delete$/).first().click().catch(() => {});
      });
      const confirm = page.getByRole('button', { name: /confirm|delete/i }).first();
      if (await confirm.count()) await confirm.click();
      await page.waitForLoadState('networkidle');
    }
  }
}

export async function importDashboardJson(page: Page, filePath: string) {
  await ensureDashboardsLoaded(page);

  try {
    // 1) Try direct import/open routes first (covers recent SigNoz builds)
    const importRoutes = ['/dashboard/import', '/dashboards/import'];
    for (const route of importRoutes) {
      await goto(page, route);
      const hasUi = await page
        .locator('input[type="file"], textarea, [role="textbox"], .monaco-editor textarea')
        .first()
        .isVisible()
        .catch(() => false);
      if (hasUi) break;
    }

    // 2) If no route worked, try UI buttons/menus
    const importTriggers = [
      page.getByRole('button', { name: /import json|import dashboard|import/i }).first(),
      page.getByRole('menuitem', { name: /import json|import dashboard|import/i }).first(),
      page.getByRole('button', { name: /\+?\s*new dashboard/i }).first(),
      page.getByRole('button', { name: /create dashboard/i }).first(),
      page.locator('button[aria-label*="More" i], button:has-text("More")').first(),
    ];
    for (const trigger of importTriggers) {
      if (await trigger.isVisible().catch(() => false)) {
        await trigger.click().catch(() => {});
        // If this was a menu opener, click Import inside menu
        const maybeImport = page
          .getByRole('menuitem', { name: /import json|import dashboard|import/i })
          .first()
          .or(page.getByRole('button', { name: /import json|import dashboard|import/i }).first());
        if (await maybeImport.isVisible().catch(() => false)) {
          await maybeImport.click().catch(() => {});
        }
        break;
      }
    }

    // Wait for either a file input or a paste area
    const fileInput = page.locator('input[type="file"]').first();
    const pasteArea = page.locator('textarea, [role="textbox"], .monaco-editor textarea').first();

    const fileInputVisible = await fileInput.isVisible().catch(() => false);
    const pasteVisible = fileInputVisible ? false : await pasteArea.isVisible().catch(() => false);

    if (fileInputVisible) {
      await fileInput.setInputFiles(filePath);
    } else if (pasteVisible) {
      const json = fs.readFileSync(filePath, 'utf-8');
      await pasteArea.fill(json).catch(async () => {
        await pasteArea.type(json, { delay: 0 });
      });
    } else {
      // Give it a bit more time in case modal animates in
      await page.waitForTimeout(1000);
      if (await fileInput.isVisible().catch(() => false)) {
        await fileInput.setInputFiles(filePath);
      } else if (await pasteArea.isVisible().catch(() => false)) {
        const json = fs.readFileSync(filePath, 'utf-8');
        await pasteArea.fill(json).catch(async () => { await pasteArea.type(json, { delay: 0 }); });
      } else {
        throw new Error('Import UI did not present a file input or paste area');
      }
    }

    const confirm = page
      .getByRole('button', { name: /import|save|create|continue|upload/i })
      .first();
    if (await confirm.isVisible().catch(() => false)) {
      await confirm.click().catch(() => {});
    }
    await page.waitForLoadState('networkidle').catch(() => {});
  } catch (error) {
    await logState(page, 'import-dashboard-failed');
    throw error;
  }
}

export async function ensureAlertsLoaded(page: Page) {
  await goto(page, '/alerts/rules');
  await expect(page.getByRole('heading', { name: /alerts?|rules/i })).toBeVisible({ timeout: 15000 });
}

export async function verifyAlertVisible(page: Page, name: string) {
  const row = page.locator(`tr:has-text("${name}")`).first();
  await expect(row).toBeVisible();
  const enabled = row.locator('button[aria-pressed="true"], .badge:has-text("enabled"), .status:has-text("active")');
  await expect(enabled.first()).toBeVisible({ timeout: 5000 });
}


