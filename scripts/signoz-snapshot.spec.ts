import { test, expect } from "@playwright/test";

const BASE = process.env.SIGNOZ_URL || "http://localhost:8080";
const SERVICE = process.env.SERVICE_NAME || "synthetic-windows-check";

test("SigNoz evidence bundle for synthetic service", async ({ page }) => {
  test.setTimeout(120_000);

  await page.goto(`${BASE}/services`, { waitUntil: "domcontentloaded" });

  // Poll up to 30 tries x 3s = 90s
  let found = false;
  for (let i = 0; i < 30; i++) {
    // Try quick search if available
    const hasSearch = await page.getByPlaceholder(/search/i).first().count();
    if (hasSearch) {
      await page.getByPlaceholder(/search/i).first().fill(SERVICE);
      await page.waitForTimeout(400);
    } else {
      await page.reload();
    }

    const itemCount = await page.getByText(SERVICE, { exact: false }).count();
    if (itemCount > 0) { found = true; break; }
    await page.waitForTimeout(3000);
  }

  if (!found) test.fail(true, `Service ${SERVICE} not listed yet`);

  await page.screenshot({ path: "artifacts/signoz-services-synthetic.png", fullPage: true });

  // Open service detail
  await page.getByText(SERVICE, { exact: false }).first().click();
  await page.waitForLoadState("domcontentloaded");

  await page.screenshot({ path: "artifacts/signoz-service-detail.png", fullPage: true });

  // Traces tab
  const tracesTab = page.getByRole("tab", { name: /traces/i }).first();
  if (await tracesTab.count()) {
    await tracesTab.click();
    await page.waitForTimeout(800);
    await page.screenshot({ path: "artifacts/signoz-traces.png", fullPage: true });
  }

  // Logs tab (if present)
  const logsTab = page.getByRole("tab", { name: /logs|events/i }).first();
  if (await logsTab.count()) {
    await logsTab.click();
    await page.waitForTimeout(800);
    await page.screenshot({ path: "artifacts/signoz-logs.png", fullPage: true });
  }
});
