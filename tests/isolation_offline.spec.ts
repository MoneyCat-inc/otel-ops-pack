/**
 * Offline Cross-Origin Isolation Test
 * 
 * Verifies that crossOriginIsolated === true is maintained when offline
 * Tests service worker header passthrough and AudioWorklet loading
 */

import { test, expect } from '@playwright/test';

test.describe('Offline Cross-Origin Isolation', () => {
  test('should maintain crossOriginIsolated=true when offline', async ({ page, context }) => {
    // Navigate to the app online first
    await page.goto('/');
    
    // Verify online isolation
    const onlineIsolation = await page.evaluate(() => window.crossOriginIsolated);
    console.log(`Online isolation: ${onlineIsolation}`);
    
    // Go offline
    await context.setOffline(true);
    console.log('Switched to offline mode');
    
    // Navigate to a different page while offline
    await page.goto('/practice');
    
    // Wait for service worker to handle the offline request
    await page.waitForTimeout(1000);
    
    // Check isolation status offline
    const offlineIsolation = await page.evaluate(() => window.crossOriginIsolated);
    console.log(`Offline isolation: ${offlineIsolation}`);
    
    // Verify isolation is maintained
    expect(offlineIsolation).toBe(true);
    
    // Check that SharedArrayBuffer is still available offline
    const sabAvailable = await page.evaluate(() => typeof SharedArrayBuffer !== 'undefined');
    expect(sabAvailable).toBe(true);
    
    // Verify service worker is active
    const swActive = await page.evaluate(() => {
      return 'serviceWorker' in navigator && navigator.serviceWorker.controller !== null;
    });
    expect(swActive).toBe(true);
  });

  test('should load AudioWorklet successfully when offline', async ({ page, context }) => {
    // Navigate to practice page (has AudioWorklet)
    await page.goto('/practice');
    
    // Go offline
    await context.setOffline(true);
    
    // Reload the page to trigger offline service worker
    await page.reload();
    await page.waitForTimeout(2000);
    
    // Check isolation status
    const isolation = await page.evaluate(() => window.crossOriginIsolated);
    expect(isolation).toBe(true);
    
    // Test AudioWorklet loading
    const workletLoaded = await page.evaluate(async () => {
      try {
        // Check if AudioContext is available
        if (typeof AudioContext === 'undefined' && typeof webkitAudioContext === 'undefined') {
          return { success: false, error: 'AudioContext not available' };
        }
        
        const AudioContextClass = AudioContext || webkitAudioContext;
        const audioContext = new AudioContextClass();
        
        // Try to load a worklet
        const workletCode = `
          class TestWorklet extends AudioWorkletProcessor {
            process() {
              return true;
            }
          }
          registerProcessor('test-worklet', TestWorklet);
        `;
        
        const blob = new Blob([workletCode], { type: 'application/javascript' });
        const workletUrl = URL.createObjectURL(blob);
        
        await audioContext.audioWorklet.addModule(workletUrl);
        
        // Clean up
        URL.revokeObjectURL(workletUrl);
        await audioContext.close();
        
        return { success: true };
      } catch (error) {
        return { success: false, error: error.message };
      }
    });
    
    expect(workletLoaded.success).toBe(true);
    if (!workletLoaded.success) {
      console.log(`AudioWorklet loading failed: ${workletLoaded.error}`);
    }
  });

  test('should preserve security headers when offline', async ({ page, context }) => {
    // Navigate to app online
    await page.goto('/');
    
    // Get online headers
    const onlineResponse = await page.goto('/');
    const onlineHeaders = onlineResponse?.headers() || {};
    
    // Go offline
    await context.setOffline(true);
    
    // Navigate to a page while offline
    const offlineResponse = await page.goto('/listen');
    
    // Note: In offline mode, we can't get response headers from service worker
    // But we can verify the page loads and isolation is maintained
    const offlineIsolation = await page.evaluate(() => window.crossOriginIsolated);
    expect(offlineIsolation).toBe(true);
    
    // Verify the page loaded successfully
    const pageTitle = await page.title();
    expect(pageTitle).toBeTruthy();
    
    console.log('Offline page loaded successfully with maintained isolation');
  });

  test('should handle offline navigation between routes', async ({ page, context }) => {
    // Start online
    await page.goto('/');
    
    // Go offline
    await context.setOffline(true);
    
    const routes = ['/listen', '/practice', '/labs/memx'];
    
    for (const route of routes) {
      console.log(`Testing offline navigation to ${route}`);
      
      await page.goto(route);
      await page.waitForTimeout(1000);
      
      // Verify isolation is maintained
      const isolation = await page.evaluate(() => window.crossOriginIsolated);
      expect(isolation).toBe(true);
      
      // Verify page loaded
      const pageTitle = await page.title();
      expect(pageTitle).toBeTruthy();
      
      console.log(`✓ ${route} loaded offline with isolation maintained`);
    }
  });

  test('should maintain isolation after going back online', async ({ page, context }) => {
    // Start online
    await page.goto('/');
    const initialIsolation = await page.evaluate(() => window.crossOriginIsolated);
    
    // Go offline
    await context.setOffline(true);
    await page.goto('/practice');
    const offlineIsolation = await page.evaluate(() => window.crossOriginIsolated);
    expect(offlineIsolation).toBe(true);
    
    // Go back online
    await context.setOffline(false);
    await page.reload();
    await page.waitForTimeout(2000);
    
    const onlineIsolation = await page.evaluate(() => window.crossOriginIsolated);
    expect(onlineIsolation).toBe(true);
    
    console.log('Isolation maintained through offline/online cycle');
  });

  test('should handle service worker errors gracefully', async ({ page, context }) => {
    // Navigate to app
    await page.goto('/');
    
    // Go offline
    await context.setOffline(true);
    
    // Try to navigate to a non-cached route
    await page.goto('/nonexistent-route');
    
    // Should still maintain isolation even for 404 pages
    const isolation = await page.evaluate(() => window.crossOriginIsolated);
    expect(isolation).toBe(true);
    
    // Verify we get some response (either cached or offline page)
    const pageContent = await page.content();
    expect(pageContent).toBeTruthy();
    
    console.log('Service worker handled non-cached route gracefully');
  });
});



