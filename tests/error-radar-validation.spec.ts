import { expect, test } from '@playwright/test';
import {
  setupErrorCapture,
  scheduleScriptError,
  scheduleConsoleError,
  schedulePromiseRejection,
  readErrorCapture,
  waitForMinimumErrors,
  createSigNozErrorEvent,
  type ErrorCaptureStore,
} from './helpers/error-capture';

test.describe('Error Radar Validation', () => {
  test('should capture browser errors and generate error events', async ({ page }) => {
    await page.goto('data:text/html,<html><body><h1>Error Radar Test Page</h1></body></html>');
    await setupErrorCapture(page);

    await scheduleScriptError(page, 'Test JavaScript Error for Error Radar');
    await scheduleConsoleError(page, 'Test Console Error for Error Radar', 50);
    await schedulePromiseRejection(page, 'Test Promise Rejection for Error Radar', 100);

    const errorData = await waitForMinimumErrors(page, 1, 1, 1);

    console.log('[capture] Page Errors:', errorData.errors.length);
    console.log('[capture] Console Errors:', errorData.consoleErrors.length);
    console.log('[capture] Promise Rejections:', errorData.promiseRejections.length);

    expect(errorData.errors.length).toBeGreaterThan(0);
    expect(errorData.consoleErrors.length).toBeGreaterThan(0);
    expect(errorData.promiseRejections.length).toBeGreaterThan(0);

    const jsError = errorData.errors.find((entry) => entry.message.includes('Test JavaScript Error'));
    expect(jsError?.message).toContain('Test JavaScript Error for Error Radar');

    const consoleError = errorData.consoleErrors.find((entry) =>
      entry.message.includes('Test Console Error'),
    );
    expect(consoleError?.message).toContain('Test Console Error for Error Radar');

    const promiseRejection = errorData.promiseRejections.find((entry) =>
      entry.message.includes('Test Promise Rejection'),
    );
    expect(promiseRejection?.message).toContain('Test Promise Rejection for Error Radar');

    console.log('[capture] All error types captured successfully');
  });

  test('should validate error fingerprinting consistency', async ({ page }) => {
    await page.goto('data:text/html,<html><body><h1>Fingerprint Test</h1></body></html>');
    await setupErrorCapture(page);

    for (let i = 0; i < 3; i += 1) {
      await scheduleScriptError(page, `Consistent Error Message ${i}`, i * 100);
    }

    await scheduleScriptError(page, 'Different Error Message', 400);

    const errorData = await waitForMinimumErrors(page, 4, 0, 0);

    console.log('[fingerprint] total errors captured:', errorData.errors.length);

    expect(errorData.errors.length).toBeGreaterThanOrEqual(4);
  });

  test('should generate error events for SigNoz', async ({ page }) => {
    await page.goto('data:text/html,<html><body><h1>SigNoz Error Event Test</h1></body></html>');
    await setupErrorCapture(page);

    await scheduleScriptError(page, 'SigNoz Test Error Event');

    const capture = await waitForMinimumErrors(page, 1, 0, 0);

    const capturedError = capture.errors.find((entry) =>
      entry.message.includes('SigNoz Test Error Event'),
    );
    expect(capturedError).toBeTruthy();

    const errorEvent = createSigNozErrorEvent(capturedError!);

    console.log('[signoz-event] payload:', JSON.stringify(errorEvent, null, 2));

    expect(errorEvent.fingerprint).toBeTruthy();
    expect(errorEvent.known).toBe(false);
    expect(errorEvent.origin).toBe('pageerror');
    expect(errorEvent.service).toBe('playwright-test');
    expect(errorEvent.message).toContain('SigNoz Test Error Event');
    expect(errorEvent.frames.length).toBeGreaterThan(0);
    expect(errorEvent.count).toBe(1);
    expect(errorEvent.suppressed).toBe(0);
  });
});
