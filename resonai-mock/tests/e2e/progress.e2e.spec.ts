/**
 * Progress Dashboard E2E Tests
 * 
 * C1: Progress Dashboard
 * Playwright tests for progress dashboard functionality, accessibility, and reduced motion.
 */

import { test, expect } from '@playwright/test';

test.describe('Progress Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to progress page
    await page.goto('/progress');
  });

  test('should load progress dashboard with mock data', async ({ page }) => {
    // Wait for page to load
    await expect(page.getByRole('heading', { name: /Your Progress/i })).toBeVisible();
    
    // Check for summary stats
    await expect(page.getByText(/Total Sessions/i)).toBeVisible();
    await expect(page.getByText(/Practice Time/i)).toBeVisible();
    await expect(page.getByText(/Avg Session/i)).toBeVisible();
    await expect(page.getByText(/Safety Trend/i)).toBeVisible();
    
    // Check for metric cards
    await expect(page.getByText(/Pitch Accuracy/i)).toBeVisible();
    await expect(page.getByText(/Expressiveness/i)).toBeVisible();
    await expect(page.getByText(/Resonance Balance/i)).toBeVisible();
    
    // Check for safety timeline
    await expect(page.getByText(/Safety Timeline/i)).toBeVisible();
  });

  test('should have proper accessibility features', async ({ page }) => {
    // Check for skip link
    await page.keyboard.press('Tab');
    await expect(page.getByRole('link', { name: /Skip to main content/i })).toBeFocused();
    
    // Check for single aria-live region
    const liveRegions = page.locator('[aria-live="polite"]');
    await expect(liveRegions).toHaveCount(1);
    
    // Check for proper headings structure
    await expect(page.getByRole('heading', { name: /Your Progress/i, level: 1 })).toBeVisible();
    await expect(page.getByRole('heading', { name: /View Options/i, level: 2 })).toBeVisible();
    await expect(page.getByRole('heading', { name: /Summary/i, level: 2 })).toBeVisible();
    await expect(page.getByRole('heading', { name: /Key Metrics/i, level: 2 })).toBeVisible();
    
    // Check for proper form labels
    await expect(page.getByLabel(/Time Period/i)).toBeVisible();
    await expect(page.getByLabel(/Show Metrics/i)).toBeVisible();
  });

  test('should respect reduced motion preferences', async ({ page }) => {
    // Enable reduced motion
    await page.emulateMedia({ reducedMotion: 'reduce' });
    
    // Reload page to apply reduced motion
    await page.reload();
    
    // Check that animations are disabled
    const spinningElement = page.locator('.animate-spin');
    if (await spinningElement.count() > 0) {
      const classList = await spinningElement.first().getAttribute('class');
      expect(classList).not.toContain('animate-spin');
    }
    
    // Check that transitions are disabled
    const transitionElements = page.locator('[class*="transition"]');
    const count = await transitionElements.count();
    for (let i = 0; i < count; i++) {
      const classList = await transitionElements.nth(i).getAttribute('class');
      if (classList) {
        expect(classList).not.toContain('transition-all');
        expect(classList).not.toContain('duration-');
      }
    }
  });

  test('should allow keyboard navigation', async ({ page }) => {
    // Test skip link
    await page.keyboard.press('Tab');
    await expect(page.getByRole('link', { name: /Skip to main content/i })).toBeFocused();
    await page.keyboard.press('Enter');
    
    // Test form controls
    await page.keyboard.press('Tab'); // Should focus on date range selector
    const dateRangeSelect = page.getByLabel(/Time Period/i);
    await expect(dateRangeSelect).toBeFocused();
    
    // Test checkbox toggles
    await page.keyboard.press('Tab');
    const pitchCheckbox = page.getByLabel(/Pitch Accuracy/i);
    await expect(pitchCheckbox).toBeFocused();
    
    // Test checkbox activation
    await page.keyboard.press('Space');
    await expect(pitchCheckbox).toBeChecked();
    
    await page.keyboard.press('Space');
    await expect(pitchCheckbox).not.toBeChecked();
  });

  test('should filter data by date range', async ({ page }) => {
    // Wait for page to load
    await expect(page.getByRole('heading', { name: /Your Progress/i })).toBeVisible();
    
    // Change date range to 7 days
    const dateRangeSelect = page.getByLabel(/Time Period/i);
    await dateRangeSelect.selectOption('7d');
    
    // Wait for data to update (mock data should still show)
    await expect(page.getByText(/Total Sessions/i)).toBeVisible();
    
    // Change to 14 days
    await dateRangeSelect.selectOption('14d');
    await expect(page.getByText(/Total Sessions/i)).toBeVisible();
    
    // Change to all time
    await dateRangeSelect.selectOption('all');
    await expect(page.getByText(/Total Sessions/i)).toBeVisible();
  });

  test('should toggle metric visibility', async ({ page }) => {
    // Wait for page to load
    await expect(page.getByRole('heading', { name: /Your Progress/i })).toBeVisible();
    
    // Initially all metrics should be visible
    await expect(page.getByText(/Pitch Accuracy/i)).toBeVisible();
    await expect(page.getByText(/Expressiveness/i)).toBeVisible();
    await expect(page.getByText(/Resonance Balance/i)).toBeVisible();
    await expect(page.getByText(/Safety Timeline/i)).toBeVisible();
    
    // Toggle off Pitch Accuracy
    const pitchCheckbox = page.getByLabel(/Pitch Accuracy/i);
    await pitchCheckbox.click();
    
    // Pitch Accuracy card should be hidden
    await expect(page.getByText(/Pitch Accuracy/i)).not.toBeVisible();
    
    // Other metrics should still be visible
    await expect(page.getByText(/Expressiveness/i)).toBeVisible();
    await expect(page.getByText(/Resonance Balance/i)).toBeVisible();
    await expect(page.getByText(/Safety Timeline/i)).toBeVisible();
    
    // Toggle off Safety
    const safetyCheckbox = page.getByLabel(/Safety/i);
    await safetyCheckbox.click();
    
    // Safety Timeline should be hidden
    await expect(page.getByText(/Safety Timeline/i)).not.toBeVisible();
    
    // Toggle back on
    await pitchCheckbox.click();
    await safetyCheckbox.click();
    
    // All metrics should be visible again
    await expect(page.getByText(/Pitch Accuracy/i)).toBeVisible();
    await expect(page.getByText(/Safety Timeline/i)).toBeVisible();
  });

  test('should display trend sparklines', async ({ page }) => {
    // Wait for page to load
    await expect(page.getByRole('heading', { name: /Your Progress/i })).toBeVisible();
    
    // Check for trend sparklines in metric cards
    const sparklines = page.locator('svg');
    await expect(sparklines).toHaveCount(3); // One for each metric card
    
    // Check that sparklines have proper accessibility
    for (let i = 0; i < 3; i++) {
      const sparkline = sparklines.nth(i);
      await expect(sparkline).toHaveAttribute('role', 'img');
      await expect(sparkline).toHaveAttribute('aria-label');
    }
  });

  test('should display safety timeline', async ({ page }) => {
    // Wait for page to load
    await expect(page.getByRole('heading', { name: /Your Progress/i })).toBeVisible();
    
    // Check for safety timeline
    await expect(page.getByText(/Safety Timeline/i)).toBeVisible();
    
    // Check for timeline elements
    await expect(page.getByText(/Low risk/i)).toBeVisible();
    await expect(page.getByText(/Moderate risk/i)).toBeVisible();
    await expect(page.getByText(/High risk/i)).toBeVisible();
    
    // Check for summary stats
    await expect(page.getByText(/Total Events/i)).toBeVisible();
    await expect(page.getByText(/Avg Rate/i)).toBeVisible();
    await expect(page.getByText(/Active Days/i)).toBeVisible();
  });

  test('should show helpful explanations', async ({ page }) => {
    // Wait for page to load
    await expect(page.getByRole('heading', { name: /Your Progress/i })).toBeVisible();
    
    // Check for "What This Means" section
    await expect(page.getByText(/What This Means/i)).toBeVisible();
    
    // Check for explanations
    await expect(page.getByText(/Higher percentages mean you're spending more time/i)).toBeVisible();
    await expect(page.getByText(/Higher values indicate more variety/i)).toBeVisible();
    await expect(page.getByText(/Shows which part of your vocal tract/i)).toBeVisible();
    await expect(page.getByText(/Tracks vocal strain events/i)).toBeVisible();
  });

  test('should handle empty data gracefully', async ({ page }) => {
    // Mock empty data by intercepting the data loading
    await page.route('**/progress**', route => {
      route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([])
      });
    });
    
    // Reload page
    await page.reload();
    
    // Should show "No Progress Data Yet" message
    await expect(page.getByText(/No Progress Data Yet/i)).toBeVisible();
    await expect(page.getByText(/Start practicing to see your progress trends/i)).toBeVisible();
    
    // Should have link to practice page
    const practiceLink = page.getByRole('link', { name: /Start Practicing/i });
    await expect(practiceLink).toBeVisible();
    
    // Clicking should navigate to practice page
    await practiceLink.click();
    await expect(page).toHaveURL('/practice');
  });

  test('should handle loading state', async ({ page }) => {
    // Mock slow loading by intercepting requests
    await page.route('**/progress**', route => {
      // Delay response
      setTimeout(() => {
        route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify([])
        });
      }, 100);
    });
    
    // Navigate to progress page
    await page.goto('/progress');
    
    // Should show loading state
    await expect(page.getByText(/Loading your progress/i)).toBeVisible();
    
    // Should have loading spinner
    const spinner = page.locator('.animate-spin');
    await expect(spinner).toBeVisible();
  });

  test('should handle error state', async ({ page }) => {
    // Mock error response
    await page.route('**/progress**', route => {
      route.fulfill({
        status: 500,
        contentType: 'application/json',
        body: JSON.stringify({ error: 'Internal Server Error' })
      });
    });
    
    // Navigate to progress page
    await page.goto('/progress');
    
    // Should show error state
    await expect(page.getByText(/Unable to Load Progress/i)).toBeVisible();
    await expect(page.getByText(/Please try again/i)).toBeVisible();
    
    // Should have retry button
    const retryButton = page.getByRole('button', { name: /Try Again/i });
    await expect(retryButton).toBeVisible();
    
    // Retry button should be focusable
    await retryButton.focus();
    await expect(retryButton).toBeFocused();
  });

  test('should maintain focus management', async ({ page }) => {
    // Wait for page to load
    await expect(page.getByRole('heading', { name: /Your Progress/i })).toBeVisible();
    
    // Test focus order
    const focusableElements = [
      page.getByRole('link', { name: /Skip to main content/i }),
      page.getByLabel(/Time Period/i),
      page.getByLabel(/Pitch Accuracy/i),
      page.getByLabel(/Expressiveness/i),
      page.getByLabel(/Resonance/i),
      page.getByLabel(/Safety/i)
    ];
    
    // Tab through elements
    for (const element of focusableElements) {
      await page.keyboard.press('Tab');
      await expect(element).toBeFocused();
    }
  });

  test('should work with screen reader', async ({ page }) => {
    // Wait for page to load
    await expect(page.getByRole('heading', { name: /Your Progress/i })).toBeVisible();
    
    // Check for proper ARIA labels
    const metricCards = page.locator('[role="region"]');
    await expect(metricCards).toHaveCount(3); // Three metric cards
    
    // Each metric card should have proper labeling
    for (let i = 0; i < 3; i++) {
      const card = metricCards.nth(i);
      await expect(card).toHaveAttribute('aria-labelledby');
    }
    
    // Check for proper status announcements
    const statusRegion = page.locator('[role="status"]');
    await expect(statusRegion).toHaveCount(1);
    
    // Check for proper form labeling
    const formControls = page.locator('input, select');
    const count = await formControls.count();
    for (let i = 0; i < count; i++) {
      const control = formControls.nth(i);
      const hasLabel = await control.getAttribute('aria-label') || 
                      await control.getAttribute('aria-labelledby') ||
                      await page.locator(`label[for="${await control.getAttribute('id')}"]`).count() > 0;
      expect(hasLabel).toBeTruthy();
    }
  });
});
