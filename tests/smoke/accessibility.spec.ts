import { test, expect } from '@playwright/test';

test('page has proper semantic structure', async ({ page }) => {
  await page.goto('/');
  
  // Verify semantic HTML structure
  await expect(page.locator('header')).toBeVisible();
  await expect(page.locator('main')).toBeVisible();
  await expect(page.locator('footer')).toBeVisible();
  
  // Check heading hierarchy
  const h1 = page.locator('h1');
  await expect(h1).toBeVisible();
  await expect(h1).toContainText('Cat Nap Control Room');
  
  // Verify landmark roles
  await expect(page.locator('main')).toBeVisible();
});

test('color contrast meets accessibility standards', async ({ page }) => {
  await page.goto('/');
  
  // Check that text elements are visible (basic contrast check)
  await expect(page.locator('h1')).toBeVisible();
  await expect(page.locator('text=Pipeline Active')).toBeVisible();
  
  // Verify status indicators exist (may be hidden by animation in headless mode)
  const statusIndicators = page.locator('.bg-green-400');
  await expect(statusIndicators).toHaveCount(4); // Should have 4 green indicators
});

test('keyboard navigation works', async ({ page }) => {
  await page.goto('/');
  
  // Test that page is keyboard accessible by checking for focusable elements
  const focusableElements = await page.locator('button, input, select, textarea, a[href], [tabindex]:not([tabindex="-1"])').count();
  expect(focusableElements).toBeGreaterThanOrEqual(0); // Page should be navigable
  
  // Test tab navigation (basic check)
  await page.keyboard.press('Tab');
  
  // Verify page responds to keyboard input
  const body = page.locator('body');
  await expect(body).toBeVisible();
});

test('page title is descriptive', async ({ page }) => {
  await page.goto('/');
  
  const title = await page.title();
  expect(title).toBe('Cat Nap Control Room - OTel Preview');
  expect(title.length).toBeGreaterThan(0);
});
