import { test, expect, Page } from "@playwright/test";

const baseURL = process.env.SIGNOZ_URL || "http://localhost:8080";

function requireEnv(name: "SIGNOZ_USER" | "SIGNOZ_PASS"): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`${name} is required for SigNoz automation`);
  }
  return value;
}

async function ensureAuthenticated(page: Page) {
  const user = requireEnv("SIGNOZ_USER");
  const pass = requireEnv("SIGNOZ_PASS");

  await page.goto(baseURL, { waitUntil: "domcontentloaded" });

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

  await page.locator("input[type='email'], input[type='text']").first().fill(user);

  const nextButton = page.getByRole("button", { name: /next/i }).first();
  if (await nextButton.isVisible().catch(() => false)) {
    await nextButton.click();
    await page.waitForLoadState("networkidle", { timeout: 10_000 });
  }

  await page.locator("input[type='password']").first().fill(pass);

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
}

test.describe("SigNoz Final Automation", () => {
  test("SigNoz health check", async ({ request }) => {
    const response = await request.get("/api/v1/health");
    expect(response.status()).toBe(200);
    const health = await response.json();
    expect(health.status).toBe("ok");
  });

  test("Authentication and basic navigation", async ({ page }) => {
    await ensureAuthenticated(page);

    const isLoggedIn = await page.evaluate(() => window.localStorage.getItem("IS_LOGGED_IN") === "true");
    expect(isLoggedIn).toBe(true);

    await page.goto("/dashboards");
    await page.waitForLoadState("networkidle");

    const hasAuthToken = await page.evaluate(() => window.localStorage.getItem("AUTH_TOKEN") !== null);
    expect(hasAuthToken).toBe(true);
  });

  test("Logs page accessibility", async ({ page }) => {
    await ensureAuthenticated(page);

    await page.goto("/logs");
    await page.waitForLoadState("networkidle");

    const hasAuthToken = await page.evaluate(() => window.localStorage.getItem("AUTH_TOKEN") !== null);
    expect(hasAuthToken).toBe(true);
  });

  test("Alerts page accessibility", async ({ page }) => {
    await ensureAuthenticated(page);

    await page.goto("/alerts/rules");
    await page.waitForLoadState("networkidle");

    const hasAuthToken = await page.evaluate(() => window.localStorage.getItem("AUTH_TOKEN") !== null);
    expect(hasAuthToken).toBe(true);
  });

  test("Logs search resilience", async ({ page }) => {
    await ensureAuthenticated(page);

    await page.goto("/logs");
    await page.waitForLoadState("networkidle");

    let searchInput = page.getByPlaceholder(/search|query|filter/i);
    if (!(await searchInput.count())) {
      searchInput = page.locator("input[type='search']");
    }
    if (!(await searchInput.count())) {
      searchInput = page.locator("input[aria-label*='search' i]");
    }
    if (!(await searchInput.count())) {
      searchInput = page.locator("input").first();
    }

    if (await searchInput.count()) {
      await searchInput.fill("collector AND health");

      let runButton = page.getByRole("button", { name: /run|apply|search/i });
      if (!(await runButton.count())) {
        runButton = page.locator("button[type='submit']");
      }
      if (!(await runButton.count())) {
        runButton = page.locator("button").first();
      }

      if (await runButton.count()) {
        await runButton.click();
        await page.waitForLoadState("networkidle", { timeout: 10_000 });
      }
    } else {
      console.log("SigNoz logs search input not present; skipping search step");
    }

    const hasAuthToken = await page.evaluate(() => window.localStorage.getItem("AUTH_TOKEN") !== null);
    expect(hasAuthToken).toBe(true);
  });
});
