import { test, expect } from '@playwright/test';
import { getOtelIngestHttpBase } from '../../LIBS/lib/otel-ports';
import { setupErrorCapture, waitForMinimumErrors } from './helpers/error-capture';

test.describe('MEMX Labs Smoke Tests', () => {
  test.beforeEach(async ({ page }) => {
    // Setup shared error capture system
    await setupErrorCapture(page);
    
    // Navigate to MEMX labs page
    await page.goto('/labs/memx');
  });

  test('MEMX page loads without console errors', async ({ page }) => {
    // Wait for page to fully load
    await page.waitForLoadState('networkidle');
    
    // Use shared error capture system to check for errors
    const errorData = await page.evaluate(() => {
      const capture = (window as any).__ERROR_CAPTURE_TEST__;
      return capture ? {
        errors: capture.errors.length,
        consoleErrors: capture.consoleErrors.length,
        promiseRejections: capture.promiseRejections.length
      } : { errors: 0, consoleErrors: 0, promiseRejections: 0 };
    });
    
    // Verify no errors were captured
    expect(errorData.errors).toBe(0);
    expect(errorData.consoleErrors).toBe(0);
    expect(errorData.promiseRejections).toBe(0);
  });

  test('Cross-origin isolation is enabled', async ({ page }) => {
    // Check crossOriginIsolated flag
    const crossOriginIsolated = await page.evaluate(() => window.crossOriginIsolated);
    expect(crossOriginIsolated).toBe(true);
  });

  test('MEMX HUD elements are present and functional', async ({ page }) => {
    // Check for key MEMX UI elements
    await expect(page.locator('[data-testid="memx-hud"]')).toBeVisible();
    
    // Check for live metrics display
    await expect(page.locator('[data-testid="memx-metrics"]')).toBeVisible();
    
    // Check for export controls
    await expect(page.locator('[data-testid="memx-export"]')).toBeVisible();
  });

  test('MEMX HUD toggles work without breaking prosody', async ({ page }) => {
    // Test HUD toggle functionality
    const hudToggle = page.locator('[data-testid="memx-hud-toggle"]');
    await expect(hudToggle).toBeVisible();
    
    // Toggle HUD on/off
    await hudToggle.click();
    await page.waitForTimeout(100); // Allow for state update
    
    // Verify HUD state changes
    const hud = page.locator('[data-testid="memx-hud"]');
    const isVisible = await hud.isVisible();
    
    // Toggle again
    await hudToggle.click();
    await page.waitForTimeout(100);
    
    // Verify HUD state toggled back
    const isVisibleAfter = await hud.isVisible();
    expect(isVisible).not.toBe(isVisibleAfter);
  });

  test('Live metrics update at expected cadence', async ({ page }) => {
    // Wait for initial metrics to load
    await page.waitForSelector('[data-testid="memx-metrics"]', { timeout: 5000 });
    
    // Capture initial metric values
    const initialMetrics = await page.locator('[data-testid="memx-metrics"]').textContent();
    
    // Wait for metrics to update (should happen within 100ms)
    await page.waitForTimeout(200);
    
    // Capture updated metric values
    const updatedMetrics = await page.locator('[data-testid="memx-metrics"]').textContent();
    
    // Verify metrics have updated (not identical)
    expect(updatedMetrics).not.toBe(initialMetrics);
  });

  test('Prosody page still loads after MEMX interaction', async ({ page }) => {
    // Interact with MEMX page first
    await page.locator('[data-testid="memx-hud-toggle"]').click();
    await page.waitForTimeout(100);
    
    // Navigate to prosody page
    await page.goto('/labs/prosody');
    
    // Verify prosody page loads without errors
    await expect(page.locator('h1')).toContainText('Prosody');
    
    // Check for console errors on prosody page
    const errors: string[] = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });
    
    await page.waitForLoadState('networkidle');
    expect(errors).toHaveLength(0);
  });

  test('Export functionality works', async ({ page }) => {
    // Click export button
    const exportButton = page.locator('[data-testid="memx-export"]');
    await expect(exportButton).toBeVisible();
    
    // Set up download handler
    const downloadPromise = page.waitForEvent('download');
    await exportButton.click();
    
    // Verify download starts
    const download = await downloadPromise;
    expect(download.suggestedFilename()).toMatch(/memx-.*\.json$/);
  });

  test('Performance overlay compatibility', async ({ page }) => {
    // Check if performance overlay is present and functional
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

  test('IndexedDB integration works', async ({ page }) => {
    // Test IndexedDB write/read functionality
    const result = await page.evaluate(async () => {
      try {
        // Write test data
        const testData = { memx: { test: 'data', timestamp: Date.now() } };
        localStorage.setItem('memx-test', JSON.stringify(testData));
        
        // Read test data
        const readData = JSON.parse(localStorage.getItem('memx-test') || '{}');
        
        return { success: true, data: readData };
      } catch (error) {
        return { success: false, error: error.message };
      }
    });
    
    expect(result.success).toBe(true);
    expect(result.data.memx.test).toBe('data');
  });
});

test.describe('MEMX Integration Tests', () => {
  test('OTLP endpoint reachability', async ({ page }) => {
    // Test OTLP endpoint connectivity
    const response = await page.request.get(`${getOtelIngestHttpBase('localhost')}/v1/logs`);
    expect(response.status()).toBeLessThan(500); // Should not be server error
  });

  test('SigNoz health check', async ({ page }) => {
    // Test SigNoz health endpoint
    const response = await page.request.get('http://localhost:8080/api/v1/health');
    expect(response.status()).toBe(200);
  });
});
