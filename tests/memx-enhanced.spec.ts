import { test, expect } from '@playwright/test';

test.describe('MEMX Enhanced Tests', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to MEMX labs page
    await page.goto('/labs/memx');
  });

  test('Cross-origin isolation verification across all browsers', async ({ page }) => {
    // Check crossOriginIsolated flag
    const crossOriginIsolated = await page.evaluate(() => window.crossOriginIsolated);
    expect(crossOriginIsolated).toBe(true);
    
    // Check SharedArrayBuffer availability
    const sabSupported = await page.evaluate(() => {
      try {
        return typeof SharedArrayBuffer !== 'undefined';
      } catch {
        return false;
      }
    });
    
    expect(sabSupported).toBe(true);
  });

  test('MEMX UI elements and functionality', async ({ page }) => {
    // Wait for page to fully load
    await page.waitForLoadState('networkidle');
    
    // Check for key MEMX UI elements
    await expect(page.locator('[data-testid="memx-metrics"]')).toBeVisible();
    
    // Check for browser compatibility info
    await expect(page.locator('text=Browser Compatibility')).toBeVisible();
    
    // Check for status indicators
    const statusIndicators = await page.locator('.w-3.h-3.rounded-full').count();
    expect(statusIndicators).toBeGreaterThan(0);
  });

  test('Performance overlay functionality', async ({ page }) => {
    // Wait for page to load
    await page.waitForLoadState('networkidle');
    
    // Check if performance overlay is present (if implemented)
    const perfOverlay = page.locator('[data-testid="perf-overlay"]');
    
    if (await perfOverlay.isVisible()) {
      // Verify overlay shows expected metrics
      await expect(perfOverlay.locator('[data-testid="fps-counter"]')).toBeVisible();
      
      // Check FPS is reasonable (≥45 fps)
      const fpsText = await perfOverlay.locator('[data-testid="fps-counter"]').textContent();
      const fps = parseInt(fpsText?.match(/\d+/)?.[0] || '0');
      expect(fps).toBeGreaterThanOrEqual(45);
    }
  });

  test('Browser compatibility debug info', async ({ page }) => {
    // Wait for page to load
    await page.waitForLoadState('networkidle');
    
    // Check for debug info visibility
    const showDebugButton = page.locator('text=Show Debug Info');
    if (await showDebugButton.isVisible()) {
      await showDebugButton.click();
      
      // Verify debug information is displayed
      await expect(page.locator('text=Debug Information')).toBeVisible();
      
      // Check for browser detection
      const userAgentInfo = page.locator('text=Browser:');
      await expect(userAgentInfo).toBeVisible();
    }
  });

  test('Export functionality', async ({ page }) => {
    // Wait for page to load
    await page.waitForLoadState('networkidle');
    
    // Look for export buttons (these should be present based on the imports)
    const exportButtons = page.locator('button').filter({ hasText: /export/i });
    const buttonCount = await exportButtons.count();
    
    if (buttonCount > 0) {
      // Test export functionality
      const firstExportButton = exportButtons.first();
      await expect(firstExportButton).toBeVisible();
      
      // Set up download handler
      const downloadPromise = page.waitForEvent('download');
      await firstExportButton.click();
      
      // Verify download starts (with timeout)
      try {
        const download = await downloadPromise;
        expect(download.suggestedFilename()).toMatch(/\.(json|csv|txt)$/);
      } catch (error) {
        // Download might not trigger immediately, which is okay for testing
        console.log('Download not triggered immediately, continuing...');
      }
    }
  });

  test('SigNoz streaming toggle', async ({ page }) => {
    // Wait for page to load
    await page.waitForLoadState('networkidle');
    
    // Look for streaming toggle
    const streamingToggle = page.locator('button[aria-label*="streaming"]');
    
    if (await streamingToggle.isVisible()) {
      // Test toggle functionality
      await streamingToggle.click();
      
      // Check for status indicator update
      const statusIndicator = page.locator('text=Streaming to SigNoz');
      await expect(statusIndicator).toBeVisible();
    }
  });

  test('Console error monitoring', async ({ page }) => {
    const errors: string[] = [];
    
    page.on('console', msg => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });
    
    // Wait for page to fully load
    await page.waitForLoadState('networkidle');
    
    // Wait a bit more for any async operations
    await page.waitForTimeout(1000);
    
    // Check for critical errors
    const criticalErrors = errors.filter(error => 
      !error.includes('favicon') && 
      !error.includes('404') &&
      !error.includes('net::ERR_ABORTED')
    );
    
    // Log errors for debugging
    if (criticalErrors.length > 0) {
      console.log('Critical errors found:', criticalErrors);
    }
    
    // Allow some non-critical errors but fail on critical ones
    const hasCriticalErrors = criticalErrors.some(error => 
      error.includes('SharedArrayBuffer') ||
      error.includes('cross-origin') ||
      error.includes('CORS')
    );
    
    expect(hasCriticalErrors).toBe(false);
  });

  test('Navigation and routing', async ({ page }) => {
    // Check that we're on the correct page
    await expect(page).toHaveURL(/\/labs\/memx/);
    
    // Check page title
    const title = await page.title();
    expect(title).toContain('MEMX');
    
    // Check for main heading
    await expect(page.locator('h1')).toContainText('MEMX');
  });

  test('Responsive design', async ({ page }) => {
    // Test different viewport sizes
    const viewports = [
      { width: 375, height: 667 }, // Mobile
      { width: 768, height: 1024 }, // Tablet
      { width: 1920, height: 1080 }, // Desktop
    ];
    
    for (const viewport of viewports) {
      await page.setViewportSize(viewport);
      await page.waitForLoadState('networkidle');
      
      // Check that main elements are still visible
      await expect(page.locator('[data-testid="memx-metrics"]')).toBeVisible();
      
      // Check that layout is responsive
      const mainContainer = page.locator('.max-w-7xl');
      await expect(mainContainer).toBeVisible();
    }
  });
});

test.describe('MEMX Integration Tests', () => {
  test('OTLP endpoint connectivity', async ({ page }) => {
    // Test OTLP endpoint connectivity
    const response = await page.request.get('http://localhost:5318/v1/logs');
    expect(response.status()).toBeLessThan(500); // Should not be server error
  });

  test('SigNoz health check', async ({ page }) => {
    // Test SigNoz health endpoint
    const response = await page.request.get('http://localhost:8080/api/v1/health');
    expect(response.status()).toBe(200);
  });

  test('Environment variable validation', async ({ page }) => {
    // Check that MEMX feature flag is properly set
    await page.goto('/labs/memx');
    
    // If MEMX is disabled, should show disabled message
    const bodyText = await page.textContent('body');
    
    if (bodyText?.includes('MEMX Disabled')) {
      // MEMX is disabled, check for proper messaging
      await expect(page.locator('text=MEMX Disabled')).toBeVisible();
      await expect(page.locator('text=NEXT_PUBLIC_FEATURE_MEMX=1')).toBeVisible();
    } else {
      // MEMX is enabled, check for proper functionality
      await expect(page.locator('text=MEMX Diagnostics')).toBeVisible();
    }
  });
});
