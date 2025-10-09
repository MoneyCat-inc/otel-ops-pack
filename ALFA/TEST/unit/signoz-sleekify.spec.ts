import { test, expect } from '@playwright/test';
import path from 'node:path';
import { setupErrorCapture } from './helpers/error-capture';
import {
  SIGNOZ_URL,
  loginIfNeeded,
  ensureDashboardsLoaded,
  deleteCustomDashboards,
  importDashboardJson,
  ensureAlertsLoaded,
  verifyAlertVisible,
  logState,
  goto
} from './helpers/signoz';

const DELETE_ALL = process.env.DELETE_ALL === '1';

const DASHBOARD_JSON = path.resolve('assets/dashboards/otel-collector-health.json');
const ALERTS_JSONS = [
  path.resolve('assets/alerts/otel-collector-queue-fill.json'),
  path.resolve('assets/alerts/otel-collector-send-failures.json'),
  path.resolve('assets/alerts/otel-collector-mem-pressure.json'),
];

test.describe.configure({ mode: 'serial', timeout: 120_000 });

test.beforeEach(async ({ page }, testInfo) => {
  // Setup shared error capture system
  await setupErrorCapture(page);
  
  // Additional error logging for debugging
  page.on('pageerror', (error) => console.error('[pageerror]', error.message));
  page.on('console', (msg) => {
    const type = msg.type();
    if (type === 'error' || type === 'warning') {
      console.error(`[console.${type}]`, msg.text());
    }
  });
  page.on('requestfailed', (request) => {
    const failure = request.failure();
    console.warn('[requestfailed]', request.url(), failure?.errorText);
  });
});

test('Login (if required) & land', async ({ page }) => {
  await goto(page, '/');
  await loginIfNeeded(page);
  await expect(page).toHaveURL(new RegExp(`${SIGNOZ_URL.replace(/[-/\\^$*+?.()|[\]{}]/g, '\\$&')}`));
});

test('Reset noisy dashboards', async ({ page }) => {
  await ensureDashboardsLoaded(page);
  await deleteCustomDashboards(page, { aggressive: DELETE_ALL });
});

test('Import OTel Collector Health dashboard', async ({ page }) => {
  try {
    await importDashboardJson(page, DASHBOARD_JSON);
    await ensureDashboardsLoaded(page);
    try {
      const dashboardLink = page.getByRole('link', { name: /OTel Collector Health/i }).first();
      await dashboardLink.click({ trial: true });
      await dashboardLink.click();
    } catch (err) {
      await logState(page, 'open-collector-dashboard-fallback');
      const fallback = page.getByText(/OTel Collector Health/i).first();
      await fallback.click();
    }
    const anyPanel = page.locator('[data-testid="panel"], canvas, svg').first();
    await expect(anyPanel).toBeVisible({ timeout: 15000 });
  } catch (error) {
    await logState(page, 'import-dashboard-test');
    throw error;
  }
});

test('Import alert rules & verify enabled', async ({ page }) => {
  try {
    await ensureAlertsLoaded(page);
    for (const file of ALERTS_JSONS) {
      const importBtn = page.getByRole('button', { name: /import/i }).first();
      if (await importBtn.count()) {
        await importBtn.click();
        const fileInput = page.locator('input[type="file"]').first();
        await fileInput.setInputFiles(file);
        const confirm = page.getByRole('button', { name: /import|save|create/i }).first();
        await confirm.click();
      }
      await page.waitForLoadState('networkidle');
    }

    await verifyAlertVisible(page, 'Collector Queue Fill >25%');
    await verifyAlertVisible(page, 'Collector Send Failures >0');
    await verifyAlertVisible(page, 'Collector Memory Pressure >80%');
  } catch (error) {
    await logState(page, 'alerts-import-failed');
    throw error;
  }
});

test('E2E health check (logs view shows canary events)', async ({ page }) => {
  await goto(page, '/logs');
  const search = page.locator('input[placeholder*="Search"], input[type="search"]').first();
  if (await search.count()) {
    await search.fill('body contains "collector health canary"');
    const run = page.getByRole('button', { name: /run query|apply|search/i }).first();
    if (await run.count()) await run.click();
  }
  const row = page.locator('table >> tbody >> tr, [data-testid="log-row"]').first();
  try {
    await expect(row).toBeVisible({ timeout: 15000 });
  } catch (error) {
    await logState(page, 'logs-view-missing-canary');
    throw error;
  }
});



