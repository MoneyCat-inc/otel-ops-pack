/**
 * Offline Cross-Origin Isolation Test
 * 
 * PR-C: Offline COOP/COEP via SW + Playwright
 * Tests that window.crossOriginIsolated === true when offline
 * and AudioWorklet loading works without COEP failures.
 */

import { test, expect } from '@playwright/test';

test.describe('Offline Cross-Origin Isolation', () => {
  test.beforeEach(async ({ page }) => {
    // Clear any existing Service Worker
    await page.evaluate(() => {
      if ('serviceWorker' in navigator) {
        navigator.serviceWorker.getRegistrations().then(registrations => {
          registrations.forEach(registration => registration.unregister());
        });
      }
    });

    // Console guard for COEP/Isolation errors
    const ERR_PATTERNS = [
      'Cross-Origin-Embedder-Policy',
      'blocked by COEP',
      'SharedArrayBuffer is not defined',
    ];

    page.on('console', msg => {
      const text = msg.text();
      if (ERR_PATTERNS.some(p => text.includes(p))) {
        throw new Error(`COEP/Isolation console error: ${text}`);
      }
    });
  });

  test('should maintain cross-origin isolation when offline', async ({ page }) => {
    // Start the app, ensure SW is installed
    await page.goto('/');
    
    // Wait for Service Worker to be registered and active
    await page.waitForFunction(() => {
      return navigator.serviceWorker.controller !== null;
    }, { timeout: 10000 });

    // Verify SW is active
    const swActive = await page.evaluate(() => {
      return navigator.serviceWorker.controller !== null;
    });
    expect(swActive).toBe(true);

    // Go offline
    await page.context().setOffline(true);

    // Navigate to the main page (served by SW cache)
    await page.reload();

    // Assert window.crossOriginIsolated === true
    const crossOriginIsolated = await page.evaluate(() => window.crossOriginIsolated);
    expect(crossOriginIsolated).toBe(true);

    // Check SharedArrayBuffer availability
    const sabAvailable = await page.evaluate(() => typeof SharedArrayBuffer !== 'undefined');
    expect(sabAvailable).toBe(true);
  });

  test('should handle AudioWorklet loading without COEP failures when offline', async ({ page }) => {
    // Navigate to practice page (uses AudioWorklets)
    await page.goto('/practice');
    
    // Wait for Service Worker
    await page.waitForFunction(() => {
      return navigator.serviceWorker.controller !== null;
    }, { timeout: 10000 });

    // Go offline
    await page.context().setOffline(true);

    // Reload page (should be served by SW cache)
    await page.reload();

    // Check cross-origin isolation is maintained
    const crossOriginIsolated = await page.evaluate(() => window.crossOriginIsolated);
    expect(crossOriginIsolated).toBe(true);

    // Test AudioWorklet loading
    const workletLoadSuccess = await page.evaluate(async () => {
      try {
        // Create AudioContext
        const audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
        
        // Test if we can add a worklet module (this will fail if COEP is missing)
        // We'll create a minimal processor for testing
        const processorCode = `
          class TestProcessor extends AudioWorkletProcessor {
            process() {
              return true;
            }
          }
          registerProcessor('test-processor', TestProcessor);
        `;
        
        // Create a blob URL for the processor
        const blob = new Blob([processorCode], { type: 'application/javascript' });
        const processorUrl = URL.createObjectURL(blob);
        
        // Try to add the worklet module
        await audioContext.audioWorklet.addModule(processorUrl);
        
        // Clean up
        URL.revokeObjectURL(processorUrl);
        audioContext.close();
        
        return true;
      } catch (error) {
        console.error('AudioWorklet test failed:', error);
        return false;
      }
    });

    expect(workletLoadSuccess).toBe(true);
  });

  test('should maintain isolation when going back online', async ({ page }) => {
    // Start online
    await page.goto('/');
    await page.waitForFunction(() => {
      return navigator.serviceWorker.controller !== null;
    }, { timeout: 10000 });

    let crossOriginIsolated = await page.evaluate(() => window.crossOriginIsolated);
    expect(crossOriginIsolated).toBe(true);

    // Go offline
    await page.context().setOffline(true);
    await page.reload();

    crossOriginIsolated = await page.evaluate(() => window.crossOriginIsolated);
    expect(crossOriginIsolated).toBe(true);

    // Go back online
    await page.context().setOffline(false);
    await page.reload();

    // Back online, isolation should still be true
    crossOriginIsolated = await page.evaluate(() => window.crossOriginIsolated);
    expect(crossOriginIsolated).toBe(true);

    // Check SharedArrayBuffer is still available
    const sabAvailable = await page.evaluate(() => typeof SharedArrayBuffer !== 'undefined');
    expect(sabAvailable).toBe(true);
  });

  test('should preserve COOP/COEP headers in Service Worker responses', async ({ page }) => {
    // Navigate and wait for Service Worker
    await page.goto('/');
    await page.waitForFunction(() => {
      return navigator.serviceWorker.controller !== null;
    }, { timeout: 10000 });

    // Go offline
    await page.context().setOffline(true);

    // Reload page
    await page.reload();

    // Check that headers are preserved in offline response
    const isolationStatus = await page.evaluate(() => {
      return {
        crossOriginIsolated: window.crossOriginIsolated,
        sharedArrayBuffer: typeof SharedArrayBuffer !== 'undefined',
        serviceWorkerActive: navigator.serviceWorker.controller !== null
      };
    });

    expect(isolationStatus.crossOriginIsolated).toBe(true);
    expect(isolationStatus.sharedArrayBuffer).toBe(true);
    expect(isolationStatus.serviceWorkerActive).toBe(true);
  });

  test('should handle offline navigation between pages', async ({ page }) => {
    // Navigate to home page
    await page.goto('/');
    await page.waitForFunction(() => {
      return navigator.serviceWorker.controller !== null;
    }, { timeout: 10000 });

    // Go offline
    await page.context().setOffline(true);

    // Navigate to different pages
    const routes = ['/listen', '/practice', '/labs/memx'];

    for (const route of routes) {
      await page.goto(route);

      // Check isolation is maintained
      const crossOriginIsolated = await page.evaluate(() => window.crossOriginIsolated);
      expect(crossOriginIsolated).toBe(true);

      // Check SharedArrayBuffer is available
      const sabAvailable = await page.evaluate(() => typeof SharedArrayBuffer !== 'undefined');
      expect(sabAvailable).toBe(true);

      // Check page loaded successfully
      await expect(page.locator('body')).toBeVisible();
    }
  });

  test('should not have COEP errors in console when offline', async ({ page }) => {
    // Navigate to practice page
    await page.goto('/practice');
    
    // Wait for Service Worker
    await page.waitForFunction(() => {
      return navigator.serviceWorker.controller !== null;
    }, { timeout: 10000 });

    // Go offline
    await page.context().setOffline(true);

    // Reload page
    await page.reload();

    // Check for COEP errors in console
    const consoleErrors: string[] = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        consoleErrors.push(msg.text());
      }
    });

    // Wait for page to fully load
    await page.waitForLoadState('networkidle');

    // Check no COEP errors occurred
    const coepErrors = consoleErrors.filter(error => 
      error.includes('Cross-Origin-Embedder-Policy') ||
      error.includes('COEP') ||
      error.includes('blocked by Cross-Origin')
    );
    expect(coepErrors).toHaveLength(0);

    // Verify isolation is maintained
    const crossOriginIsolated = await page.evaluate(() => window.crossOriginIsolated);
    expect(crossOriginIsolated).toBe(true);
  });
});