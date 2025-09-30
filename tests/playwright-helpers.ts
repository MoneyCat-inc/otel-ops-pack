// Playwright Helper Utilities for Deflaking E2E Tests
// Provides deterministic data, timeout tuning, and hardened selectors

import { Page, expect } from '@playwright/test';

/**
 * Mock data for deterministic testing
 */
export const mockData = {
  aggregate: {
    timestamp: '2024-01-15T10:30:00Z',
    metrics: {
      micGrantRate: 0.85,
      activationRate: 0.72,
      ttvP50: 180,
      ttvP90: 320,
      smoothnessScore: 0.91
    },
    trends: {
      micGrant: [0.8, 0.82, 0.85, 0.83, 0.87],
      activation: [0.7, 0.71, 0.72, 0.73, 0.72],
      ttv: [200, 190, 180, 185, 175]
    }
  },
  progress: {
    sessions: [
      { id: 'session-1', duration: 300, score: 0.85 },
      { id: 'session-2', duration: 450, score: 0.92 },
      { id: 'session-3', duration: 380, score: 0.88 }
    ],
    weeklyTrend: [0.8, 0.82, 0.85, 0.87, 0.89, 0.91, 0.88]
  },
  prosody: {
    scenarios: [
      { name: 'Vowel Practice', difficulty: 'easy', duration: 120 },
      { name: 'Consonant Drills', difficulty: 'medium', duration: 180 },
      { name: 'Sentence Flow', difficulty: 'hard', duration: 240 }
    ]
  }
};

/**
 * Set up deterministic network mocking
 */
export async function setupDeterministicMocks(page: Page) {
  // Mock aggregate API
  await page.route('**/api/aggregate*', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify(mockData.aggregate)
    })
  );

  // Mock progress API
  await page.route('**/api/progress*', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify(mockData.progress)
    })
  );

  // Mock prosody API
  await page.route('**/api/prosody*', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify(mockData.prosody)
    })
  );

  // Mock analytics API
  await page.route('**/api/analytics*', route =>
    route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify({ success: true, data: [] })
    })
  );
}

/**
 * Wait for element with retry logic (replaces brittle waits)
 */
export async function waitForElementWithRetry(
  page: Page,
  selector: string,
  options: { timeout?: number; intervals?: number[] } = {}
) {
  const { timeout = 30000, intervals = [500, 1000, 2000] } = options;
  
  return expect(async () => {
    const element = page.locator(selector);
    await expect(element).toBeVisible();
    return element;
  }).toPass({ timeout, intervals });
}

/**
 * Get audio constraints for stable testing
 */
export async function getStableAudioConstraints(page: Page) {
  return await page.evaluate(() => {
    return navigator.mediaDevices.getUserMedia({
      audio: {
        echoCancellation: false,
        noiseSuppression: false,
        autoGainControl: false
      }
    });
  });
}

/**
 * Verify cross-origin isolation is working
 */
export async function verifyCrossOriginIsolation(page: Page) {
  const crossOriginIsolated = await page.evaluate(() => window.crossOriginIsolated);
  expect(crossOriginIsolated).toBe(true);
  
  const sabSupported = await page.evaluate(() => {
    try {
      return typeof SharedArrayBuffer !== 'undefined';
    } catch {
      return false;
    }
  });
  
  expect(sabSupported).toBe(true);
}

/**
 * Hardened selectors using roles and test IDs
 */
export const selectors = {
  // Dashboard elements
  progressDashboard: '[data-testid="progress-dashboard"]',
  trendSparkline: '[data-testid="trend-sparkline"]',
  metricsCard: '[data-testid="metrics-card"]',
  
  // Practice flow elements
  practiceHUD: '[data-testid="practice-hud"]',
  micButton: '[data-testid="mic-button"]',
  progressBar: '[data-testid="progress-bar"]',
  
  // Navigation elements
  navMenu: '[role="navigation"]',
  mainContent: '[role="main"]',
  
  // Form elements
  filterApply: '[data-testid="filter-apply"]',
  filterReset: '[data-testid="filter-reset"]',
  
  // Status indicators
  statusIndicator: '.w-3.h-3.rounded-full',
  loadingSpinner: '[data-testid="loading-spinner"]'
};

/**
 * Test tags for organizing tests
 */
export const testTags = {
  flaky: '@flaky',
  slow: '@slow',
  a11y: '@a11y-smokes',
  isolation: '@isolation-offline',
  prosody: '@prosody-scenarios',
  strain: '@strain',
  progress: '@progress',
  dataControl: '@data-control',
  reset: '@reset'
};

/**
 * Timeout configurations
 */
export const timeouts = {
  short: 5000,
  medium: 15000,
  long: 30000,
  veryLong: 60000
};

/**
 * Mark test as slow (3x timeout)
 */
export function markSlow(test: any) {
  test.slow();
}

/**
 * Mark test as flaky (exclude from PR lane)
 */
export function markFlaky(test: any) {
  test.describe.configure({ mode: 'parallel' });
  test.skip();
}
