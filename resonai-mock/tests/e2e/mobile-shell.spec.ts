import { test, expect } from '@playwright/test';

test('mobile shell loads', async ({ page }) => {
  await page.goto('/');
  await expect(page.getByRole('link', { name: /Practice/i })).toBeVisible();
});
