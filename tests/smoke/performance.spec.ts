import { test, expect } from '@playwright/test';

test('page loads within performance budget', async ({ page }) => {
  // Navigate and measure load time
  const startTime = Date.now();
  await page.goto('/');
  await page.waitForLoadState('networkidle');
  const loadTime = Date.now() - startTime;
  
  // Performance budget: page should load within 3 seconds
  expect(loadTime).toBeLessThan(3000);
  
  // Verify main content is visible
  await expect(page.locator('main')).toBeVisible();
  
  // Check for critical UI elements
  await expect(page.locator('h1')).toContainText('Cat Nap Control Room');
  await expect(page.locator('.bg-green-400')).toHaveCount(4); // Status indicators exist
});

test('dashboard panels render correctly', async ({ page }) => {
  await page.goto('/');
  
  // Verify main dashboard panels are present (there are 4 panels including status bar)
  const panels = page.locator('.bg-gray-800.rounded-lg');
  await expect(panels).toHaveCount(4);
  
  // Check panel titles
  await expect(page.locator('text=📋 Logs')).toBeVisible();
  await expect(page.locator('text=📊 Metrics')).toBeVisible();
  await expect(page.locator('text=🔍 Traces')).toBeVisible();
  
  // Verify status bar components
  await expect(page.locator('text=SigNoz')).toBeVisible();
  await expect(page.locator('text=Windows Collector')).toBeVisible();
  await expect(page.locator('text=Docker Services')).toBeVisible();
});

test('responsive design works on mobile viewport', async ({ page }) => {
  // Set mobile viewport
  await page.setViewportSize({ width: 375, height: 667 });
  await page.goto('/');
  
  // Verify mobile layout
  await expect(page.locator('main')).toBeVisible();
  await expect(page.locator('h1')).toBeVisible();
  
  // Check that grid adapts to mobile (should stack vertically)
  const grid = page.locator('.grid.grid-cols-1.md\\:grid-cols-3');
  await expect(grid).toBeVisible();
});
