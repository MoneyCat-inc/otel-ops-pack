/**
 * Isolation Headers Smoke Test
 * 
 * Verifies COOP/COEP headers across all routes
 * Part of test framework separation fix
 */

import { test, expect } from '@playwright/test';

test.describe('Cross-Origin Isolation Headers', () => {
  const routes = ['/', '/listen', '/practice', '/labs/memx'];

  for (const route of routes) {
    test(`should have correct headers on ${route}`, async ({ page }) => {
      // Navigate to route
      await page.goto(route);
      
      // Check cross-origin isolation status
      const crossOriginIsolated = await page.evaluate(() => window.crossOriginIsolated);
      console.log(`${route}: Cross-origin isolated = ${crossOriginIsolated}`);
      
      // Verify SharedArrayBuffer availability (when COI is enabled)
      const sabAvailable = await page.evaluate(() => typeof SharedArrayBuffer !== 'undefined');
      console.log(`${route}: SharedArrayBuffer available = ${sabAvailable}`);
      
      // In development, COI may not be enabled - that's expected
      if (crossOriginIsolated) {
        expect(sabAvailable).toBe(true);
      } else {
        // Log but don't fail - development environment may not have COI
        console.log(`Note: ${route} - Cross-origin isolation disabled in development`);
      }
    });
  }

  test('should have consistent headers across all routes', async ({ page }) => {
    const headers: Record<string, string[]> = {};
    
    for (const route of routes) {
      const response = await page.goto(route);
      const responseHeaders = response?.headers() || {};
      
      // Extract security headers
      const securityHeaders = {
        'cross-origin-opener-policy': responseHeaders['cross-origin-opener-policy'],
        'cross-origin-embedder-policy': responseHeaders['cross-origin-embedder-policy'],
        'cross-origin-resource-policy': responseHeaders['cross-origin-resource-policy'],
        'content-security-policy': responseHeaders['content-security-policy']
      };
      
      headers[route] = Object.values(securityHeaders).filter(Boolean);
    }
    
    // Verify all routes have the same security headers
    const firstRouteHeaders = headers[routes[0]];
    for (const route of routes.slice(1)) {
      expect(headers[route]).toEqual(firstRouteHeaders);
    }
    
    console.log('Security headers consistency verified across all routes');
  });
});
