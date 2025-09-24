import { test, expect } from '../setup/deterministic';

test('home loads and shows a main landmark', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('main')).toBeVisible();
});
