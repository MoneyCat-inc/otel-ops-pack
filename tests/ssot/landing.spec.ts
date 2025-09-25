import { expect, test } from "@playwright/test";

const pageBody = encodeURIComponent('<!doctype html><html lang="en"><head><meta charset="utf-8"><title>SSOT</title></head><body><main>SSOT Ready</main></body></html>');

const DATA_URL = `data:text/html,${pageBody}`;

test("renders main landmark from data url", async ({ page }) => {
  await page.goto(DATA_URL, { waitUntil: "load" });
  const main = page.locator("main");
  await expect(main).toBeVisible();
  await expect(main).toHaveText("SSOT Ready");
});
