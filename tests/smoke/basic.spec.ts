import { test, expect } from '@playwright/test';

test('home loads and shows a main landmark', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('main')).toBeVisible();
});
