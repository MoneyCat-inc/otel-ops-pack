import { test as base, Page } from '@playwright/test';
import { setupErrorCapture, scheduleScriptError, schedulePromiseRejection } from '../helpers/error-capture';

/**
 * Enhanced Playwright test setup with error capture
 * Captures browser errors, console errors, and page errors using shared helpers
 */

/**
 * Enhanced error capture using the shared error radar system
 */
function captureError(error: Error, context: any = {}) {
    console.error('🚨 Browser Error Captured:', {
        message: error.message,
        stack: error.stack,
        context,
        timestamp: new Date().toISOString()
    });
    
    // TODO: Integrate with actual error radar system when available
    // This would call the actual captureError from error-watcher
}

/**
 * Setup page error handlers
 */
async function setupPageErrorHandlers(page: Page, testId?: string) {
    // Capture page errors
    page.on('pageerror', (error) => {
        captureError(error, {
            origin: 'pageerror',
            service: 'playwright-test',
            testId,
            url: page.url(),
            timestamp: new Date().toISOString()
        });
    });

    // Capture console errors
    page.on('console', (msg) => {
        const type = msg.type();
        if (type === 'error') {
            const error = new Error(`Console Error: ${msg.text()}`);
            captureError(error, {
                origin: 'console.error',
                service: 'playwright-test',
                testId,
                url: page.url(),
                timestamp: new Date().toISOString(),
                consoleArgs: msg.args().map(arg => arg.toString())
            });
        }
    });

    // Capture network failures
    page.on('response', (response) => {
        if (response.status() >= 500) {
            const error = new Error(`Network Error: ${response.status()} ${response.url()}`);
            captureError(error, {
                origin: 'network-error',
                service: 'playwright-test',
                testId,
                url: response.url(),
                status: response.status(),
                statusText: response.statusText(),
                timestamp: new Date().toISOString()
            });
        }
    });

    // Capture unhandled requests
    page.on('requestfailed', (request) => {
        const error = new Error(`Request Failed: ${request.url()} - ${request.failure()?.errorText}`);
        captureError(error, {
            origin: 'request-failed',
            service: 'playwright-test',
            testId,
            url: request.url(),
            method: request.method(),
            failure: request.failure()?.errorText,
            timestamp: new Date().toISOString()
        });
    });
}

/**
 * Enhanced test with error capture
 */
export const test = base.extend<{
    page: Page;
}>({
    page: async ({ page }, use) => {
        // Generate test ID for correlation
        const testId = `test-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
        
        // Setup shared error capture system
        await setupErrorCapture(page);
        
        // Setup additional error handlers for network and other errors
        await setupPageErrorHandlers(page, testId);
        
        // Add test metadata to page context
        await page.addInitScript((testId) => {
            (window as any).__TEST_ID__ = testId;
        }, testId);

        // Listen for error messages from browser
        page.on('console', (msg) => {
            if (msg.type() === 'error' && msg.text().includes('🚨')) {
                // This is an error we captured in the browser
                console.log(`📱 Browser Error: ${msg.text()}`);
            }
        });

        await use(page);
    }
});

/**
 * Helper function to induce test errors for validation using shared helpers
 */
export async function induceTestError(page: Page, errorType: 'js' | 'network' | 'promise' = 'js') {
    switch (errorType) {
        case 'js':
            await scheduleScriptError(page, 'Test JavaScript Error (Hardening)');
            break;
        case 'network':
            await page.goto('http://localhost:9999/nonexistent');
            break;
        case 'promise':
            await schedulePromiseRejection(page, 'Test Promise Rejection (Hardening)');
            break;
    }
}

/**
 * Helper function to check error capture status
 */
export async function getErrorCaptureStatus(page: Page): Promise<{
    store: ReturnType<typeof Object.assign>;
    errors: number;
    consoleErrors: number;
    promiseRejections: number;
}> {
    return await page.evaluate(() => {
        const capture = (window as any).__ERROR_CAPTURE_TEST__ ?? {
            errors: [],
            consoleErrors: [],
            promiseRejections: []
        };

        return {
            store: capture,
            errors: capture.errors.length,
            consoleErrors: capture.consoleErrors.length,
            promiseRejections: capture.promiseRejections.length
        };
    });
}

export { expect } from '@playwright/test';
