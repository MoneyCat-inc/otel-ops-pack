/**
 * Shared Playwright utilities and type extensions
 * Resolves TypeScript compilation issues in E2E tests
 */

import { expect, Locator } from '@playwright/test';

// Global type extensions for window.__env
declare global {
  interface Window {
    __env: {
      NEXT_PUBLIC_COHORT_ENABLED?: string;
      NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY?: string;
      NEXT_PUBLIC_COHORT_EVENT_SUMMARY?: string;
      NEXT_PUBLIC_COHORT_PROGRESS_TRENDS?: string;
      NEXT_PUBLIC_COHORT_MEMX_DEBUG?: string;
      NEXT_PUBLIC_COHORT_MOBILE_PERFORMANCE?: string;
      NEXT_PUBLIC_COHORT_A11Y_SMOKES?: string;
    };
  }
}

// Utility function for typed error handling
export function logError(error: unknown, context: string): void {
  if (error instanceof Error) {
    console.error(`${context}: ${error.message}`);
  } else {
    console.error(`${context}: ${String(error)}`);
  }
}

// Utility function for safe property access
export function safeGet<T>(obj: any, path: string, defaultValue: T): T {
  const keys = path.split('.');
  let current = obj;
  
  for (const key of keys) {
    if (current == null || typeof current !== 'object') {
      return defaultValue;
    }
    current = current[key];
  }
  
  return current !== undefined ? current : defaultValue;
}

// Utility function for API request context URL access
export function getApiUrl(request: any): string {
  return request.url || '';
}

// Custom matcher for toContainElement
expect.extend({
  async toContainElement(received: Locator, element: Locator) {
    const container = await received.elementHandle();
    const target = await element.elementHandle();
    
    if (!container || !target) {
      return {
        message: () => 'Expected container and element to exist',
        pass: false,
      };
    }
    
    const isContained = await container.evaluate((container, target) => {
      return container.contains(target);
    }, target);
    
    return {
      message: () => `Expected container to ${isContained ? 'not ' : ''}contain element`,
      pass: isContained,
    };
  },
});
