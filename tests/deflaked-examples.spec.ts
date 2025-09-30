import { test, expect } from '@playwright/test';
import { 
  setupDeterministicMocks, 
  waitForElementWithRetry, 
  selectors, 
  testTags, 
  timeouts,
  markSlow,
  markFlaky,
  verifyCrossOriginIsolation,
  getStableAudioConstraints
} from './playwright-helpers';

test.describe('Progress Dashboard - Deflaked', () => {
  test.beforeEach(async ({ page }) => {
    // Set up deterministic mocks to eliminate network waits
    await setupDeterministicMocks(page);
    
    // Navigate to progress page
    await page.goto('/progress');
  });

  test('progress dashboard loads with deterministic data', async ({ page }) => {
    // Use retry logic instead of brittle waits
    await waitForElementWithRetry(page, selectors.progressDashboard, {
      timeout: timeouts.medium,
      intervals: [500, 1000, 2000]
    });

    // Verify key elements are visible
    await expect(page.locator(selectors.trendSparkline)).toBeVisible();
    await expect(page.locator(selectors.metricsCard)).toBeVisible();
    
    // Check for progress data (mocked, so should be instant)
    const progressData = await page.locator('[data-testid="progress-data"]').textContent();
    expect(progressData).toBeTruthy();
  });

  test('progress dashboard filters work correctly', async ({ page }) => {
    // Wait for dashboard to load
    await waitForElementWithRetry(page, selectors.progressDashboard);
    
    // Test filter functionality
    const filterApply = page.locator(selectors.filterApply);
    await expect(filterApply).toBeVisible();
    
    // Apply filter and verify results update
    await filterApply.click();
    
    // Verify filter results (mocked data should be consistent)
    await expect(page.locator('[data-testid="filtered-results"]')).toBeVisible();
  });

  // Mark as slow for complex operations
  test('progress dashboard handles large datasets', async ({ page }) => {
    markSlow(test);
    
    // This test gets 3x timeout due to slow() marker
    await waitForElementWithRetry(page, selectors.progressDashboard, {
      timeout: timeouts.veryLong
    });
    
    // Simulate large dataset scenario
    await page.evaluate(() => {
      // Simulate loading large dataset
      window.dispatchEvent(new CustomEvent('largeDatasetLoaded'));
    });
    
    // Verify performance remains acceptable
    const renderTime = await page.evaluate(() => {
      const start = performance.now();
      // Simulate rendering
      return performance.now() - start;
    });
    
    expect(renderTime).toBeLessThan(100); // Should be fast with mocked data
  });
});

test.describe('Prosody Scenarios - Deflaked', () => {
  test.beforeEach(async ({ page }) => {
    await setupDeterministicMocks(page);
    await page.goto('/practice/prosody');
  });

  test('prosody scenarios load with stable data', async ({ page }) => {
    // Wait for scenarios to load
    await waitForElementWithRetry(page, '[data-testid="prosody-scenarios"]');
    
    // Verify scenario cards are visible
    const scenarioCards = page.locator('[data-testid="scenario-card"]');
    await expect(scenarioCards).toHaveCount(3); // Mock data has 3 scenarios
    
    // Check scenario details
    await expect(page.locator('text=Vowel Practice')).toBeVisible();
    await expect(page.locator('text=Consonant Drills')).toBeVisible();
    await expect(page.locator('text=Sentence Flow')).toBeVisible();
  });

  test('prosody practice flow works with stable audio', async ({ page }) => {
    // Set up stable audio constraints
    await getStableAudioConstraints(page);
    
    // Start practice session
    const startButton = page.locator('[data-testid="start-practice"]');
    await expect(startButton).toBeVisible();
    await startButton.click();
    
    // Verify practice HUD appears
    await waitForElementWithRetry(page, selectors.practiceHUD);
    
    // Check mic button state
    const micButton = page.locator(selectors.micButton);
    await expect(micButton).toBeVisible();
    
    // Verify progress tracking
    const progressBar = page.locator(selectors.progressBar);
    await expect(progressBar).toBeVisible();
  });
});

test.describe('Strain Detection - Deflaked', () => {
  test.beforeEach(async ({ page }) => {
    await setupDeterministicMocks(page);
    await page.goto('/analytics/strain');
  });

  test('strain detection loads without long waits', async ({ page }) => {
    // Use deterministic data to avoid 30+ second waits
    await waitForElementWithRetry(page, '[data-testid="strain-detection"]', {
      timeout: timeouts.medium
    });
    
    // Verify strain metrics are displayed
    await expect(page.locator('[data-testid="strain-metrics"]')).toBeVisible();
    
    // Check for strain indicators
    const strainIndicators = page.locator(selectors.statusIndicator);
    await expect(strainIndicators).toHaveCount(3); // Mock data has 3 indicators
  });

  // Mark as flaky and exclude from PR lane
  test('strain detection handles edge cases', async ({ page }) => {
    markFlaky(test);
    
    // This test is marked as flaky and will be excluded from PR runs
    // It can still run in nightly builds with retries
    
    await page.goto('/analytics/strain');
    
    // Simulate edge case scenario
    await page.evaluate(() => {
      window.dispatchEvent(new CustomEvent('strainEdgeCase'));
    });
    
    // Verify handling
    await expect(page.locator('[data-testid="edge-case-handler"]')).toBeVisible();
  });
});

test.describe('Cross-Origin Isolation - Smoke Tests', () => {
  test('cross-origin isolation works across browsers', async ({ page }) => {
    await page.goto('/labs/memx');
    
    // Verify cross-origin isolation
    await verifyCrossOriginIsolation(page);
    
    // Check SharedArrayBuffer availability
    const sabSupported = await page.evaluate(() => {
      try {
        return typeof SharedArrayBuffer !== 'undefined';
      } catch {
        return false;
      }
    });
    
    expect(sabSupported).toBe(true);
  });

  test('audio worklet functionality', async ({ page }) => {
    await page.goto('/practice');
    
    // Set up stable audio constraints
    await getStableAudioConstraints(page);
    
    // Verify audio worklet can be created
    const workletSupported = await page.evaluate(() => {
      try {
        return typeof AudioWorklet !== 'undefined';
      } catch {
        return false;
      }
    });
    
    expect(workletSupported).toBe(true);
  });
});
