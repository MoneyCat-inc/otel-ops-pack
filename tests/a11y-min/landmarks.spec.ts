import { test, expect } from '../setup/deterministic';

test('page exposes core accessibility landmarks', async ({ page }) => {
  await page.goto('/');
  await expect(page.locator('html')).toHaveAttribute('lang', 'en');
  await expect(page.locator('header')).toBeVisible();
  await expect(page.locator('main')).toBeVisible();
  await expect(page.locator('footer')).toBeVisible();
  await expect(page.locator('h1')).toHaveText(/Cat Nap Control Room/i);
});
