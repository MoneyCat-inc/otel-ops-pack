import { test, expect } from '@playwright/test';
import { setupErrorCapture } from './helpers/error-capture';

test.describe('MEMX Chromium Debug Tests', () => {
  test.beforeEach(async ({ page }) => {
    // Setup shared error capture system
    await setupErrorCapture(page);
    
    // Enable console logging for debugging
    page.on('console', msg => {
      console.log(`[${msg.type()}] ${msg.text()}`);
    });
    
    // Log all network requests
    page.on('request', request => {
      console.log(`[REQUEST] ${request.method()} ${request.url()}`);
    });
    
    // Log all network responses
    page.on('response', response => {
      console.log(`[RESPONSE] ${response.status()} ${response.url()}`);
      if (response.status() >= 400) {
        console.log(`[ERROR] Failed request: ${response.url()}`);
      }
    });
  });

  test('Debug Chromium cross-origin isolation', async ({ page }) => {
    console.log('=== CHROMIUM CROSS-ORIGIN ISOLATION DEBUG ===');
    
    // Navigate to MEMX page
    await page.goto('/labs/memx');
    
    // Check if page loaded
    const title = await page.title();
    console.log(`Page title: ${title}`);
    
    // Check for console errors using shared error capture
    const errorData = await page.evaluate(() => {
      const capture = (window as any).__ERROR_CAPTURE_TEST__;
      return capture ? {
        errors: capture.errors.length,
        consoleErrors: capture.consoleErrors.length,
        promiseRejections: capture.promiseRejections.length
      } : { errors: 0, consoleErrors: 0, promiseRejections: 0 };
    });
    
    console.log(`[ERROR CAPTURE] Errors: ${errorData.errors}, Console Errors: ${errorData.consoleErrors}, Promise Rejections: ${errorData.promiseRejections}`);
    
    // Wait for page to load
    await page.waitForLoadState('networkidle');
    
    // Check cross-origin isolation
    const crossOriginIsolated = await page.evaluate(() => {
      console.log('Checking crossOriginIsolated...');
      return window.crossOriginIsolated;
    });
    
    console.log(`crossOriginIsolated: ${crossOriginIsolated}`);
    
    // Check SharedArrayBuffer support
    const sabSupported = await page.evaluate(() => {
      console.log('Checking SharedArrayBuffer support...');
      try {
        if (typeof SharedArrayBuffer === 'undefined') {
          console.log('SharedArrayBuffer is undefined');
          return false;
        }
        console.log('SharedArrayBuffer is available');
        return true;
      } catch (error) {
        console.log('SharedArrayBuffer error:', error);
        return false;
      }
    });
    
    console.log(`SharedArrayBuffer supported: ${sabSupported}`);
    
    // Check COOP/COEP headers
    const headers = await page.evaluate(() => {
      console.log('Checking headers...');
      return {
        userAgent: navigator.userAgent,
        crossOriginIsolated: window.crossOriginIsolated,
        sharedArrayBuffer: typeof SharedArrayBuffer !== 'undefined',
        location: window.location.href
      };
    });
    
    console.log('Headers check:', headers);
    
    // Check for specific MEMX elements
    const memxElements = await page.evaluate(() => {
      const elements = {
        title: document.querySelector('h1')?.textContent,
        memxActive: document.querySelector('[data-testid="memx-hud"]') !== null,
        memxMetrics: document.querySelector('[data-testid="memx-metrics"]') !== null,
        memxExport: document.querySelector('[data-testid="memx-export"]') !== null,
        bodyText: document.body.textContent?.includes('MEMX') || false
      };
      console.log('MEMX elements:', elements);
      return elements;
    });
    
    console.log('MEMX elements found:', memxElements);
    
    // Log any errors found
    if (errors.length > 0) {
      console.log('Console errors found:', errors);
    }
    
    // For debugging, we'll log the results but not fail the test
    console.log('=== DEBUG COMPLETE ===');
    
    // Basic assertion - page should at least load
    expect(title).toBeTruthy();
  });

  test('Debug Chromium SharedArrayBuffer creation', async ({ page }) => {
    console.log('=== CHROMIUM SHAREDARRAYBUFFER DEBUG ===');
    
    await page.goto('/labs/memx');
    await page.waitForLoadState('networkidle');
    
    const sabTest = await page.evaluate(() => {
      console.log('Testing SharedArrayBuffer creation...');
      
      try {
        if (typeof SharedArrayBuffer === 'undefined') {
          return { success: false, error: 'SharedArrayBuffer is undefined' };
        }
        
        // Try to create a small SharedArrayBuffer
        const sab = new SharedArrayBuffer(1024);
        console.log('SharedArrayBuffer created successfully');
        
        return { 
          success: true, 
          bufferSize: sab.byteLength,
          crossOriginIsolated: window.crossOriginIsolated
        };
      } catch (error) {
        console.log('SharedArrayBuffer creation failed:', error);
        return { 
          success: false, 
          error: error.message,
          crossOriginIsolated: window.crossOriginIsolated
        };
      }
    });
    
    console.log('SharedArrayBuffer test result:', sabTest);
    
    // Log the result for debugging
    if (!sabTest.success) {
      console.log('SharedArrayBuffer creation failed:', sabTest.error);
    }
  });

  test('Debug Chromium COOP/COEP headers', async ({ page }) => {
    console.log('=== CHROMIUM COOP/COEP HEADERS DEBUG ===');
    
    // Navigate and capture response headers
    const response = await page.goto('/labs/memx');
    const headers = response?.headers();
    
    console.log('Response headers:');
    Object.entries(headers || {}).forEach(([key, value]) => {
      if (key.toLowerCase().includes('cross-origin') || 
          key.toLowerCase().includes('corp') || 
          key.toLowerCase().includes('csp')) {
        console.log(`  ${key}: ${value}`);
      }
    });
    
    // Check headers in browser
    const headerCheck = await page.evaluate(() => {
      // Check if we can access headers via fetch
      return fetch(window.location.href, { method: 'HEAD' })
        .then(response => {
          const headers = {};
          for (const [key, value] of response.headers.entries()) {
            headers[key] = value;
          }
          return { success: true, headers };
        })
        .catch(error => {
          return { success: false, error: error.message };
        });
    });
    
    console.log('Header check result:', headerCheck);
    
    // Check cross-origin isolation status
    const isolationStatus = await page.evaluate(() => {
      return {
        crossOriginIsolated: window.crossOriginIsolated,
        userAgent: navigator.userAgent,
        location: window.location.href
      };
    });
    
    console.log('Isolation status:', isolationStatus);
  });

  test('Debug Chromium MEMX UI elements', async ({ page }) => {
    console.log('=== CHROMIUM MEMX UI DEBUG ===');
    
    await page.goto('/labs/memx');
    await page.waitForLoadState('networkidle');
    
    // Check if MEMX is enabled
    const memxStatus = await page.evaluate(() => {
      const body = document.body.textContent || '';
      const isEnabled = body.includes('MEMX Active') || body.includes('MEMX Diagnostics');
      const isDisabled = body.includes('MEMX Disabled');
      
      return {
        isEnabled,
        isDisabled,
        bodyContainsMEMX: body.includes('MEMX'),
        title: document.title,
        h1Text: document.querySelector('h1')?.textContent
      };
    });
    
    console.log('MEMX status:', memxStatus);
    
    // If MEMX is enabled, check for specific elements
    if (memxStatus.isEnabled) {
      const elements = await page.evaluate(() => {
        return {
          memxHud: document.querySelector('[data-testid="memx-hud"]') !== null,
          memxMetrics: document.querySelector('[data-testid="memx-metrics"]') !== null,
          memxExport: document.querySelector('[data-testid="memx-export"]') !== null,
          memxHudToggle: document.querySelector('[data-testid="memx-hud-toggle"]') !== null,
          allTestIds: Array.from(document.querySelectorAll('[data-testid]')).map(el => el.getAttribute('data-testid'))
        };
      });
      
      console.log('MEMX elements:', elements);
    }
    
    // Take a screenshot for debugging
    await page.screenshot({ path: 'chromium-memx-debug.png' });
    console.log('Screenshot saved: chromium-memx-debug.png');
  });
});
