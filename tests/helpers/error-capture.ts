/**
 * Shared Error Capture Helpers for Playwright Tests
 * Provides reliable error capture and validation utilities
 */

import type { Page } from '@playwright/test';

export type ErrorCaptureStore = {
  errors: Array<{
    message: string;
    filename: string;
    lineno: number;
    colno: number;
    timestamp: string;
  }>;
  consoleErrors: Array<{
    message: string;
    timestamp: string;
  }>;
  promiseRejections: Array<{
    message: string;
    timestamp: string;
  }>;
};

/**
 * Set up error capture instrumentation on the page
 */
export async function setupErrorCapture(page: Page): Promise<void> {
  await page.evaluate(() => {
    const capture = {
      errors: [] as Array<{
        message: string;
        filename: string;
        lineno: number;
        colno: number;
        timestamp: string;
      }>,
      consoleErrors: [] as Array<{
        message: string;
        timestamp: string;
      }>,
      promiseRejections: [] as Array<{
        message: string;
        timestamp: string;
      }>,
    };

    const serialise = (value: unknown): string => {
      if (typeof value === 'string') return value;
      if (value instanceof Error && value.message) return value.message;
      try {
        return JSON.stringify(value);
      } catch {
        return String(value);
      }
    };

    const globalAny = window as any;
    globalAny.__ERROR_CAPTURE_TEST__ = capture;

    const originalConsoleError =
      globalAny.__ERROR_CAPTURE_ORIGINAL_CONSOLE__ ?? console.error.bind(console);
    globalAny.__ERROR_CAPTURE_ORIGINAL_CONSOLE__ = originalConsoleError;

    console.error = (...args: unknown[]) => {
      capture.consoleErrors.push({
        message: args.map(serialise).join(' '),
        timestamp: new Date().toISOString(),
      });
      originalConsoleError(...args);
    };

    window.addEventListener('error', (event: ErrorEvent) => {
      capture.errors.push({
        message: event.message ?? '',
        filename: event.filename ?? '',
        lineno: event.lineno ?? 0,
        colno: event.colno ?? 0,
        timestamp: new Date().toISOString(),
      });
    });

    window.addEventListener('unhandledrejection', (event: PromiseRejectionEvent) => {
      capture.promiseRejections.push({
        message: serialise(event.reason),
        timestamp: new Date().toISOString(),
      });
    });
  });
}

/**
 * Schedule a script error to be thrown asynchronously
 */
export async function scheduleScriptError(page: Page, message: string, delay = 0): Promise<void> {
  await page.evaluate(
    ({ msg, timeout }) => {
      setTimeout(() => {
        throw new Error(msg);
      }, timeout);
    },
    { msg: message, timeout: delay },
  );
}

/**
 * Schedule a console error to be logged asynchronously
 */
export async function scheduleConsoleError(page: Page, message: string, delay = 0): Promise<void> {
  await page.evaluate(
    ({ msg, timeout }) => {
      setTimeout(() => {
        console.error(msg);
      }, timeout);
    },
    { msg: message, timeout: delay },
  );
}

/**
 * Schedule a promise rejection to occur asynchronously
 */
export async function schedulePromiseRejection(page: Page, message: string, delay = 0): Promise<void> {
  await page.evaluate(
    ({ msg, timeout }) => {
      setTimeout(() => {
        Promise.reject(new Error(msg));
      }, timeout);
    },
    { msg: message, timeout: delay },
  );
}

/**
 * Read the current error capture store from the page
 */
export async function readErrorCapture(page: Page): Promise<ErrorCaptureStore | null> {
  return (await page.evaluate(() => (window as any).__ERROR_CAPTURE_TEST__ ?? null)) as
    | ErrorCaptureStore
    | null;
}

/**
 * Wait for specific error capture conditions to be met
 */
export async function waitForErrorCapture(
  page: Page,
  condition: (store: ErrorCaptureStore) => boolean,
  timeout = 5000,
  pollInterval = 50
): Promise<ErrorCaptureStore> {
  const deadline = Date.now() + timeout;
  let lastStore: ErrorCaptureStore | null = null;

  while (Date.now() < deadline) {
    lastStore = await readErrorCapture(page);
    if (lastStore && condition(lastStore)) {
      return lastStore;
    }

    const remaining = deadline - Date.now();
    if (remaining <= 0) break;
    await page.waitForTimeout(Math.min(pollInterval, remaining));
  }

  lastStore = await readErrorCapture(page);
  if (lastStore && condition(lastStore)) {
    return lastStore;
  }

  throw new Error('Timed out waiting for error capture condition');
}

/**
 * Wait for minimum error counts to be captured
 */
export async function waitForMinimumErrors(
  page: Page,
  minErrors = 1,
  minConsoleErrors = 1,
  minPromiseRejections = 1,
  timeout = 5000
): Promise<ErrorCaptureStore> {
  return waitForErrorCapture(
    page,
    (store) =>
      store.errors.length >= minErrors &&
      store.consoleErrors.length >= minConsoleErrors &&
      store.promiseRejections.length >= minPromiseRejections,
    timeout
  );
}

/**
 * Create a SigNoz error event payload for validation
 */
export function createSigNozErrorEvent(
  capturedError: { message: string },
  overrides: Partial<{
    fingerprint: string;
    known: boolean;
    severity: string;
    origin: string;
    service: string;
    frames: Array<{ file: string; line: number; fn: string }>;
    count: number;
    suppressed: number;
  }> = {}
) {
  return {
    timestamp: new Date().toISOString(),
    fingerprint: 'test-fp-12345',
    known: false,
    severity: 'error',
    origin: 'pageerror',
    service: 'playwright-test',
    message: capturedError.message,
    frames: [
      { file: 'test-file.js', line: 10, fn: 'testFunction' },
      { file: 'test-file.js', line: 25, fn: 'mainFunction' },
      { file: 'test-file.js', line: 1, fn: 'globalScope' },
    ],
    count: 1,
    suppressed: 0,
    ...overrides,
  };
}
