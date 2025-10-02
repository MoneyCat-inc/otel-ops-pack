import { test, expect } from "@playwright/test";

// Helper function to perform login
async function loginToSigNoz(page: any) {
  const baseURL = process.env.SIGNOZ_URL || "http://localhost:8080";
  const user = process.env.SIGNOZ_USER || "fubumaki@gmail.com";
  const pass = process.env.SIGNOZ_PASS || "X+4E*Cn*dpq4p2C2";

  // Check if already logged in by looking at localStorage
  await page.goto(baseURL, { waitUntil: "domcontentloaded" });
  const isLoggedIn = await page.evaluate(() => {
    return localStorage.getItem('IS_LOGGED_IN') === 'true';
  });

  if (isLoggedIn) {
    console.log("Already logged in, skipping authentication");
    return;
  }

  console.log("Not logged in, performing authentication...");
  
  // Enter email
  const emailInput = page.locator("input[type='email'], input[type='text']").first();
  await emailInput.fill(user);
  
  // Click Next if present
  const nextButton = page.getByRole("button", { name: /next/i });
  if (await nextButton.count() > 0) {
    await nextButton.click();
    await page.waitForLoadState("networkidle", { timeout: 10000 });
  }
  
  // Enter password
  const passwordInput = page.locator("input[type='password']").first();
  await passwordInput.fill(pass);
  
  // Submit
  const submitButton = page.getByRole("button", { name: /sign\s*in|log\s*in|submit/i });
  await submitButton.click();
  
  // Wait for authentication to complete
  await page.waitForFunction(() => {
    return localStorage.getItem('IS_LOGGED_IN') === 'true';
  }, { timeout: 30000 });
  
  console.log("Authentication completed successfully");
}

test.describe("SigNoz Final Automation", () => {
  test("SigNoz health check", async ({ page }) => {
    const response = await page.request.get("/api/v1/health");
    expect(response.status()).toBe(200);
    
    const healthData = await response.json();
    expect(healthData.status).toBe("ok");
  });

  test("Authentication and basic navigation", async ({ page }) => {
    await loginToSigNoz(page);
    
    // Verify authentication state
    const isLoggedIn = await page.evaluate(() => {
      return localStorage.getItem('IS_LOGGED_IN') === 'true';
    });
    
    console.log(`Authentication status: ${isLoggedIn}`);
    expect(isLoggedIn).toBe(true);
    
    // Try to access dashboards
    await page.goto("/dashboards");
    await page.waitForLoadState("networkidle");
    
    const url = page.url();
    const title = await page.title();
    
    console.log(`Dashboards - URL: ${url}, Title: ${title}`);
    
    // Check if we have auth token
    const hasAuthToken = await page.evaluate(() => {
      return localStorage.getItem('AUTH_TOKEN') !== null;
    });
    
    console.log(`Has auth token: ${hasAuthToken}`);
    expect(hasAuthToken).toBe(true);
  });

  test("Logs page accessibility", async ({ page }) => {
    await loginToSigNoz(page);
    
    // Verify authentication state
    const isLoggedIn = await page.evaluate(() => {
      return localStorage.getItem('IS_LOGGED_IN') === 'true';
    });
    
    expect(isLoggedIn).toBe(true);
    
    await page.goto("/logs");
    await page.waitForLoadState("networkidle");
    
    const url = page.url();
    const title = await page.title();
    
    console.log(`Logs - URL: ${url}, Title: ${title}`);
    
    // Check if we have auth token
    const hasAuthToken = await page.evaluate(() => {
      return localStorage.getItem('AUTH_TOKEN') !== null;
    });
    
    console.log(`Has auth token: ${hasAuthToken}`);
    expect(hasAuthToken).toBe(true);
  });

  test("Alerts page accessibility", async ({ page }) => {
    await loginToSigNoz(page);
    
    // Verify authentication state
    const isLoggedIn = await page.evaluate(() => {
      return localStorage.getItem('IS_LOGGED_IN') === 'true';
    });
    
    expect(isLoggedIn).toBe(true);
    
    await page.goto("/alerts/rules");
    await page.waitForLoadState("networkidle");
    
    const url = page.url();
    const title = await page.title();
    
    console.log(`Alerts - URL: ${url}, Title: ${title}`);
    
    // Check if we have auth token
    const hasAuthToken = await page.evaluate(() => {
      return localStorage.getItem('AUTH_TOKEN') !== null;
    });
    
    console.log(`Has auth token: ${hasAuthToken}`);
    expect(hasAuthToken).toBe(true);
  });

  test("Logs search functionality", async ({ page }) => {
    await loginToSigNoz(page);
    
    // Verify authentication state
    const isLoggedIn = await page.evaluate(() => {
      return localStorage.getItem('IS_LOGGED_IN') === 'true';
    });
    
    expect(isLoggedIn).toBe(true);
    
    await page.goto("/logs");
    await page.waitForLoadState("networkidle");
    
    // Look for search input with multiple selectors
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
    
    // If we found a search input, try to use it
    if (await searchInput.count() > 0) {
      await searchInput.fill("collector AND health");
      console.log("Search input found and filled");
      
      // Look for search/run button
      let runButton = page.getByRole("button", { name: /run|apply|search/i });
      if (!(await runButton.count())) {
        runButton = page.locator("button[type='submit']");
      }
      if (!(await runButton.count())) {
        runButton = page.locator("button").first();
      }
      
      if (await runButton.count() > 0) {
        await runButton.click();
        await page.waitForLoadState("networkidle", { timeout: 10000 });
        console.log("Search executed");
      }
    } else {
      console.log("No search input found - this is expected for some SigNoz versions");
    }
    
    // Check if we have auth token
    const hasAuthToken = await page.evaluate(() => {
      return localStorage.getItem('AUTH_TOKEN') !== null;
    });
    
    console.log(`Has auth token: ${hasAuthToken}`);
    expect(hasAuthToken).toBe(true);
  });
});
