/**
 * Offline Isolation E2E Tests
 * 
 * T4: Offline Isolation
 * Comprehensive tests ensuring cross-origin isolation is maintained
 * both online and offline through Service Worker control.
 */

import { test, expect } from '@playwright/test';

test.describe('Offline Isolation Tests', () => {
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
      const t = msg.text();
      if (ERR_PATTERNS.some(p => t.includes(p))) {
        throw new Error(`COEP/Isolation console error: ${t}`);
      }
    });
  });

  test('should maintain cross-origin isolation online', async ({ page }) => {
    // Navigate to home page
    await page.goto('/');
    
    // Check cross-origin isolation status
    const crossOriginIsolated = await page.evaluate(() => window.crossOriginIsolated);
    expect(crossOriginIsolated).toBe(true);
    
    // Check SharedArrayBuffer availability
    const sabAvailable = await page.evaluate(() => typeof SharedArrayBuffer !== 'undefined');
    expect(sabAvailable).toBe(true);
    
    // Check headers are present
    const response = await page.goto('/');
    const headers = response?.headers() || {};
    
    expect(headers['cross-origin-opener-policy']).toBe('same-origin');
    expect(headers['cross-origin-embedder-policy']).toBe('require-corp');
    expect(headers['cross-origin-resource-policy']).toBe('cross-origin');
  });

  test('should install Service Worker and maintain isolation', async ({ page }) => {
    // Navigate to home page to trigger Service Worker registration
    await page.goto('/');
    
    // Wait for Service Worker to be registered
    await page.waitForFunction(() => {
      return navigator.serviceWorker.controller !== null;
    }, { timeout: 10000 });
    
    // Check Service Worker is active
    const swActive = await page.evaluate(() => {
      return navigator.serviceWorker.controller !== null;
    });
    expect(swActive).toBe(true);
    
    // Check cross-origin isolation is still true
    const crossOriginIsolated = await page.evaluate(() => window.crossOriginIsolated);
    expect(crossOriginIsolated).toBe(true);
    
    // Check SharedArrayBuffer is still available
    const sabAvailable = await page.evaluate(() => typeof SharedArrayBuffer !== 'undefined');
    expect(sabAvailable).toBe(true);
  });

  test('should maintain isolation when going offline', async ({ page }) => {
    // Navigate and wait for Service Worker
    await page.goto('/');
    await page.waitForFunction(() => {
      return navigator.serviceWorker.controller !== null;
    }, { timeout: 10000 });
    
    // Go offline
    await page.context().setOffline(true);
    
    // Reload page (should be served by Service Worker)
    await page.reload();
    
    // Check cross-origin isolation is maintained
    const crossOriginIsolated = await page.evaluate(() => window.crossOriginIsolated);
    expect(crossOriginIsolated).toBe(true);
    
    // Check SharedArrayBuffer is still available
    const sabAvailable = await page.evaluate(() => typeof SharedArrayBuffer !== 'undefined');
    expect(sabAvailable).toBe(true);
    
    // Check that page loaded successfully offline
    await expect(page.getByText('Resonai')).toBeVisible();
  });

  test('should handle worklet loading without COEP errors', async ({ page }) => {
    // Navigate to practice page (uses worklets)
    await page.goto('/practice');
    
    // Wait for Service Worker
    await page.waitForFunction(() => {
      return navigator.serviceWorker.controller !== null;
    }, { timeout: 10000 });
    
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

  test('should handle offline navigation between pages', async ({ page }) => {
    // Navigate to home page
    await page.goto('/');
    await page.waitForFunction(() => {
      return navigator.serviceWorker.controller !== null;
    }, { timeout: 10000 });
    
    // Go offline
    await page.context().setOffline(true);
    
    // Navigate to different pages
    const routes = ['/listen', '/practice', '/labs/memx', '/labs/prosody-scenarios', '/labs/strain'];
    
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

  test('should preserve headers in Service Worker responses', async ({ page }) => {
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
    const headers = await page.evaluate(() => {
      // This is a bit tricky to test directly, but we can check the isolation status
      return {
        crossOriginIsolated: window.crossOriginIsolated,
        sharedArrayBuffer: typeof SharedArrayBuffer !== 'undefined'
      };
    });
    
    expect(headers.crossOriginIsolated).toBe(true);
    expect(headers.sharedArrayBuffer).toBe(true);
  });

  test('should handle Service Worker updates without breaking isolation', async ({ page }) {
    // Navigate and wait for Service Worker
    await page.goto('/');
    await page.waitForFunction(() => {
      return navigator.serviceWorker.controller !== null;
    }, { timeout: 10000 });
    
    // Simulate Service Worker update by unregistering and re-registering
    await page.evaluate(() => {
      return navigator.serviceWorker.getRegistrations().then(registrations => {
        return Promise.all(registrations.map(registration => registration.unregister()));
      });
    });
    
    // Wait a moment
    await page.waitForTimeout(1000);
    
    // Reload to trigger new registration
    await page.reload();
    
    // Wait for new Service Worker
    await page.waitForFunction(() => {
      return navigator.serviceWorker.controller !== null;
    }, { timeout: 10000 });
    
    // Check isolation is maintained
    const crossOriginIsolated = await page.evaluate(() => window.crossOriginIsolated);
    expect(crossOriginIsolated).toBe(true);
  });

  test('should handle mixed online/offline scenarios', async ({ page }) => {
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
    
    crossOriginIsolated = await page.evaluate(() => window.crossOriginIsolated);
    expect(crossOriginIsolated).toBe(true);
  });

  test('should handle Service Worker errors gracefully', async ({ page }) => {
    // Navigate to home page
    await page.goto('/');
    
    // Listen for Service Worker errors
    const swErrors: string[] = [];
    page.on('console', msg => {
      if (msg.type() === 'error' && msg.text().includes('Service Worker')) {
        swErrors.push(msg.text());
      }
    });
    
    // Wait for Service Worker
    await page.waitForFunction(() => {
      return navigator.serviceWorker.controller !== null;
    }, { timeout: 10000 });
    
    // Check isolation is still maintained despite any errors
    const crossOriginIsolated = await page.evaluate(() => window.crossOriginIsolated);
    expect(crossOriginIsolated).toBe(true);
    
    // Log any Service Worker errors for debugging
    if (swErrors.length > 0) {
      console.log('Service Worker errors:', swErrors);
    }
  });

  test('should maintain isolation across browser refresh', async ({ page }) => {
    // Navigate and wait for Service Worker
    await page.goto('/');
    await page.waitForFunction(() => {
      return navigator.serviceWorker.controller !== null;
    }, { timeout: 10000 });
    
    // Go offline
    await page.context().setOffline(true);
    
    // Refresh multiple times
    for (let i = 0; i < 3; i++) {
      await page.reload();
      
      const crossOriginIsolated = await page.evaluate(() => window.crossOriginIsolated);
      expect(crossOriginIsolated).toBe(true);
      
      const sabAvailable = await page.evaluate(() => typeof SharedArrayBuffer !== 'undefined');
      expect(sabAvailable).toBe(true);
    }
  });
});

test.describe('Service Worker Registration', () => {
  test('should register Service Worker on first visit', async ({ page }) => {
    // Clear any existing registrations
    await page.evaluate(() => {
      if ('serviceWorker' in navigator) {
        navigator.serviceWorker.getRegistrations().then(registrations => {
          registrations.forEach(registration => registration.unregister());
        });
      }
    });
    
    // Navigate to home page
    await page.goto('/');
    
    // Wait for Service Worker registration
    await page.waitForFunction(() => {
      return navigator.serviceWorker.controller !== null;
    }, { timeout: 10000 });
    
    // Check Service Worker is active
    const swActive = await page.evaluate(() => {
      return navigator.serviceWorker.controller !== null;
    });
    expect(swActive).toBe(true);
  });

  test('should handle Service Worker registration failure gracefully', async ({ page }) => {
    // Mock Service Worker registration failure
    await page.route('/sw.js', route => {
      route.abort('failed');
    });
    
    // Navigate to home page
    await page.goto('/');
    
    // Wait a moment for registration attempt
    await page.waitForTimeout(2000);
    
    // Check that page still loads and isolation works
    const crossOriginIsolated = await page.evaluate(() => window.crossOriginIsolated);
    expect(crossOriginIsolated).toBe(true);
  });
});

test.describe('Asset Loading', () => {
  test('should load worklet files without COEP errors', async ({ page }) => {
    // Navigate to practice page
    await page.goto('/practice');
    
    // Wait for Service Worker
    await page.waitForFunction(() => {
      return navigator.serviceWorker.controller !== null;
    }, { timeout: 10000 });
    
    // Check for worklet loading errors
    const consoleErrors: string[] = [];
    page.on('console', msg => {
      if (msg.type() === 'error') {
        consoleErrors.push(msg.text());
      }
    });
    
    // Wait for page to load
    await page.waitForLoadState('networkidle');
    
    // Check no COEP errors for worklets
    const workletErrors = consoleErrors.filter(error => 
      error.includes('worklet') && 
      (error.includes('Cross-Origin') || error.includes('COEP'))
    );
    expect(workletErrors).toHaveLength(0);
  });

  test('should handle missing assets gracefully offline', async ({ page }) => {
    // Navigate and wait for Service Worker
    await page.goto('/');
    await page.waitForFunction(() => {
      return navigator.serviceWorker.controller !== null;
    }, { timeout: 10000 });
    
    // Go offline
    await page.context().setOffline(true);
    
    // Navigate to a page that might have missing assets
    await page.goto('/practice');
    
    // Check isolation is maintained
    const crossOriginIsolated = await page.evaluate(() => window.crossOriginIsolated);
    expect(crossOriginIsolated).toBe(true);
    
    // Check page still loads
    await expect(page.locator('body')).toBeVisible();
  });
});
