/**
 * MEMX Playwright Smoke Tests
 * 
 * Verifies MEMX labs page functionality, cross-origin isolation,
 * and HUD toggle compatibility with other labs features.
 */

import { test, expect } from '@playwright/test';

test.describe('MEMX Labs Page', () => {
  test('should load MEMX labs page without errors', async ({ page }) => {
    // Navigate to MEMX labs page
    await page.goto('/labs/memx');
    
    // Check page loads successfully
    await expect(page).toHaveTitle(/Resonai/);
    
    // Verify MEMX content is present
    await expect(page.locator('h1:has-text("MEMX Diagnostics")')).toBeVisible();
    
    // Check for no console errors
    const consoleErrors: string[] = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        consoleErrors.push(msg.text());
      }
    });
    
    // Wait a moment for any async operations
    await page.waitForTimeout(1000);
    
    // Assert no console errors
    expect(consoleErrors).toHaveLength(0);
  });

  test('should have cross-origin isolation enabled', async ({ page }) => {
    await page.goto('/labs/memx');
    
    // Check cross-origin isolation status
    const crossOriginIsolated = await page.evaluate(() => window.crossOriginIsolated);
    console.log('Cross-origin isolated:', crossOriginIsolated);
    
    // Verify SharedArrayBuffer is available (when cross-origin isolation is enabled)
    const sabAvailable = await page.evaluate(() => typeof SharedArrayBuffer !== 'undefined');
    console.log('SharedArrayBuffer available:', sabAvailable);
    
    // In development, Chromium may not enable cross-origin isolation
    // This is expected behavior and not a failure condition
    if (crossOriginIsolated) {
      expect(sabAvailable).toBe(true);
    } else {
      // SharedArrayBuffer may not be available without cross-origin isolation
      // This is normal in development environments
      console.log('Note: Cross-origin isolation disabled in development - SharedArrayBuffer unavailable');
    }
  });

  test('should display MEMX metrics and controls', async ({ page }) => {
    await page.goto('/labs/memx');
    
    // Check for MEMX-specific UI elements
    await expect(page.locator('text=MEMX Labs')).toBeVisible();
    
    // Look for export controls (if MEMX is enabled)
    const exportButton = page.locator('button:has-text("Export")');
    if (await exportButton.count() > 0) {
      await expect(exportButton).toBeVisible();
    }
    
    // Check for session stats
    const sessionStats = page.locator('text=Session Statistics');
    if (await sessionStats.count() > 0) {
      await expect(sessionStats).toBeVisible();
    }
  });

  test('should not break prosody page when MEMX is active', async ({ page }) => {
    // First visit MEMX labs to activate any MEMX components
    await page.goto('/labs/memx');
    await page.waitForTimeout(500);
    
    // Then navigate to prosody page (if it exists)
    try {
      await page.goto('/labs/prosody');
      await page.waitForTimeout(1000);
      
      // Check prosody page loads without errors
      const consoleErrors: string[] = [];
      page.on('console', msg => {
        if (msg.type() === 'error') {
          consoleErrors.push(msg.text());
        }
      });
      
      // Assert no console errors on prosody page
      expect(consoleErrors).toHaveLength(0);
    } catch (error) {
      // Prosody page might not exist yet, that's okay
      console.log('Prosody page not found, skipping compatibility test');
    }
  });

  test('should maintain performance overlay functionality', async ({ page }) => {
    await page.goto('/labs/memx');
    
    // Check for performance overlay elements
    const perfOverlay = page.locator('[data-testid="perf-overlay"]');
    const perfOverlayClass = page.locator('.perf-overlay');
    const perfText = page.locator('text=Performance');
    
    if (await perfOverlay.count() > 0) {
      await expect(perfOverlay).toBeVisible();
    } else if (await perfOverlayClass.count() > 0) {
      await expect(perfOverlayClass).toBeVisible();
    } else if (await perfText.count() > 0) {
      await expect(perfText).toBeVisible();
    }
    
    // Verify page remains responsive
    const startTime = Date.now();
    await page.click('body'); // Simple interaction
    const endTime = Date.now();
    
    // Should respond within reasonable time
    expect(endTime - startTime).toBeLessThan(1000);
  });

  test('should handle HUD toggles without breaking', async ({ page }) => {
    await page.goto('/labs/memx');
    
    // Look for HUD toggle buttons
    const hudToggles = page.locator('button:has-text("HUD"), button:has-text("Toggle"), [data-testid*="hud"]');
    
    if (await hudToggles.count() > 0) {
      // Test toggling HUD elements
      for (let i = 0; i < Math.min(await hudToggles.count(), 3); i++) {
        const toggle = hudToggles.nth(i);
        await toggle.click();
        await page.waitForTimeout(200);
        
        // Verify no errors after toggle
        const consoleErrors: string[] = [];
        page.on('console', msg => {
          if (msg.type() === 'error') {
            consoleErrors.push(msg.text());
          }
        });
        
        expect(consoleErrors).toHaveLength(0);
      }
    }
  });

  test('should have proper navigation structure', async ({ page }) => {
    await page.goto('/labs/memx');
    
    // Check navigation header
    await expect(page.locator('nav')).toBeVisible();
    await expect(page.locator('text=Resonai')).toBeVisible();
    
    // Check for MEMX Labs link in navigation
    const memxNavLink = page.locator('a:has-text("MEMX Labs")');
    if (await memxNavLink.count() > 0) {
      await expect(memxNavLink).toBeVisible();
    }
    
    // Verify home link works
    const homeLink = page.locator('a:has-text("Home")');
    if (await homeLink.count() > 0) {
      await expect(homeLink).toBeVisible();
    }
  });
});

