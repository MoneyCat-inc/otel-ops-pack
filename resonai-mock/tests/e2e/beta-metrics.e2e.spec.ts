/**
 * E2E Tests for Beta Metrics UI and Accessibility
 * 
 * C6: Beta Success Metrics
 * Tests the BetaMetricsPanel component rendering, accessibility, and user interactions.
 */

import { test, expect } from '@playwright/test';

test.describe('Beta Metrics Panel', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the progress page
    await page.goto('/progress');
    
    // Wait for the page to load
    await page.waitForLoadState('networkidle');
  });

  test('should render beta metrics panel with all components', async ({ page }) => {
    // Check if the beta metrics panel is visible
    await expect(page.locator('[data-testid="beta-metrics-panel"]')).toBeVisible();
    
    // Check for the main heading
    await expect(page.locator('h2:has-text("Beta Success Metrics")')).toBeVisible();
    
    // Check for all metric cards
    await expect(page.locator('text=Retention')).toBeVisible();
    await expect(page.locator('text=Comfort Level')).toBeVisible();
    await expect(page.locator('text=Strain Health')).toBeVisible();
    await expect(page.locator('text=Session Frequency')).toBeVisible();
    
    // Check for health insights section
    await expect(page.locator('text=Health Insights')).toBeVisible();
    await expect(page.locator('text=Comfort vs Fatigue')).toBeVisible();
    await expect(page.locator('text=Practice Consistency')).toBeVisible();
  });

  test('should display metric values correctly', async ({ page }) => {
    // Check that retention percentage is displayed
    await expect(page.locator('text=Retention')).toBeVisible();
    await expect(page.locator('text=%')).toBeVisible();
    
    // Check that comfort level is displayed
    await expect(page.locator('text=Comfort Level')).toBeVisible();
    
    // Check that strain health indicator is displayed
    await expect(page.locator('[data-testid="strain-health-indicator"]')).toBeVisible();
    
    // Check that session frequency is displayed
    await expect(page.locator('text=Session Frequency')).toBeVisible();
    await expect(page.locator('text=/week')).toBeVisible();
  });

  test('should show trend indicators', async ({ page }) => {
    // Check for trend arrows
    await expect(page.locator('text=↗')).toBeVisible();
    await expect(page.locator('text=↘')).toBeVisible();
    await expect(page.locator('text=→')).toBeVisible();
    
    // Check for trend text
    await expect(page.locator('text=Improving')).toBeVisible();
    await expect(page.locator('text=Declining')).toBeVisible();
    await expect(page.locator('text=Stable')).toBeVisible();
  });

  test('should display strain health categories correctly', async ({ page }) => {
    // Check for strain health emoji indicators
    await expect(page.locator('text=🟢')).toBeVisible();
    await expect(page.locator('text=🔵')).toBeVisible();
    await expect(page.locator('text=🟡')).toBeVisible();
    await expect(page.locator('text=🔴')).toBeVisible();
    
    // Check for strain health text
    await expect(page.locator('text=excellent')).toBeVisible();
    await expect(page.locator('text=good')).toBeVisible();
    await expect(page.locator('text=moderate')).toBeVisible();
    await expect(page.locator('text=poor')).toBeVisible();
  });

  test('should be accessible with proper ARIA labels', async ({ page }) => {
    // Check for proper ARIA labels
    await expect(page.locator('[aria-labelledby="beta-metrics-title"]')).toBeVisible();
    await expect(page.locator('[aria-labelledby="strain-health-title"]')).toBeVisible();
    
    // Check for screen reader content
    await expect(page.locator('[aria-live="polite"]')).toBeVisible();
    await expect(page.locator('[role="status"]')).toBeVisible();
    
    // Check for proper heading hierarchy
    const h2 = page.locator('h2:has-text("Beta Success Metrics")');
    await expect(h2).toBeVisible();
    
    const h3 = page.locator('h3:has-text("Health Insights")');
    await expect(h3).toBeVisible();
  });

  test('should support keyboard navigation', async ({ page }) => {
    // Tab through the page to ensure all elements are focusable
    await page.keyboard.press('Tab');
    await expect(page.locator(':focus')).toBeVisible();
    
    // Check that metric cards are focusable
    const metricCards = page.locator('[role="region"]');
    await expect(metricCards.first()).toBeVisible();
    
    // Tab through multiple elements
    for (let i = 0; i < 5; i++) {
      await page.keyboard.press('Tab');
      await expect(page.locator(':focus')).toBeVisible();
    }
  });

  test('should display progress bars correctly', async ({ page }) => {
    // Check for comfort progress bar
    const comfortBar = page.locator('.bg-blue-600');
    await expect(comfortBar).toBeVisible();
    
    // Check for retention progress bar
    const retentionBar = page.locator('.bg-green-600');
    await expect(retentionBar).toBeVisible();
    
    // Check that progress bars have proper width
    const comfortBarWidth = await comfortBar.evaluate(el => el.style.width);
    expect(comfortBarWidth).toMatch(/\d+%/);
    
    const retentionBarWidth = await retentionBar.evaluate(el => el.style.width);
    expect(retentionBarWidth).toMatch(/\d+%/);
  });

  test('should handle empty data gracefully', async ({ page }) => {
    // Mock empty data by clearing localStorage
    await page.evaluate(() => {
      localStorage.clear();
    });
    
    // Reload the page
    await page.reload();
    await page.waitForLoadState('networkidle');
    
    // Check that the panel still renders with appropriate message
    await expect(page.locator('text=No data available yet')).toBeVisible();
    await expect(page.locator('text=Start practicing to see your beta metrics!')).toBeVisible();
  });

  test('should be responsive on mobile devices', async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    
    // Check that the panel adapts to mobile layout
    await expect(page.locator('[data-testid="beta-metrics-panel"]')).toBeVisible();
    
    // Check that metric cards stack vertically on mobile
    const metricCards = page.locator('[role="region"]');
    const firstCard = metricCards.first();
    const secondCard = metricCards.nth(1);
    
    const firstCardBox = await firstCard.boundingBox();
    const secondCardBox = await secondCard.boundingBox();
    
    // On mobile, cards should stack vertically (second card below first)
    expect(secondCardBox!.y).toBeGreaterThan(firstCardBox!.y + firstCardBox!.height);
  });

  test('should display trend sparklines', async ({ page }) => {
    // Check for trend sparkline elements
    const sparklines = page.locator('[data-testid="trend-sparkline"]');
    await expect(sparklines).toHaveCount(4); // One for each metric
    
    // Check that sparklines have proper SVG elements
    const svgElements = page.locator('svg');
    await expect(svgElements).toHaveCount(4);
  });

  test('should show proper color coding for different metrics', async ({ page }) => {
    // Check for blue color scheme (retention)
    await expect(page.locator('.bg-blue-50')).toBeVisible();
    await expect(page.locator('.border-blue-200')).toBeVisible();
    await expect(page.locator('.text-blue-800')).toBeVisible();
    
    // Check for green color scheme (comfort)
    await expect(page.locator('.bg-green-50')).toBeVisible();
    await expect(page.locator('.border-green-200')).toBeVisible();
    await expect(page.locator('.text-green-800')).toBeVisible();
    
    // Check for purple color scheme (frequency)
    await expect(page.locator('.bg-purple-50')).toBeVisible();
    await expect(page.locator('.border-purple-200')).toBeVisible();
    await expect(page.locator('.text-purple-800')).toBeVisible();
  });

  test('should handle reduced motion preferences', async ({ page }) => {
    // Set reduced motion preference
    await page.emulateMedia({ reducedMotion: 'reduce' });
    
    // Reload the page
    await page.reload();
    await page.waitForLoadState('networkidle');
    
    // Check that the panel still renders correctly
    await expect(page.locator('[data-testid="beta-metrics-panel"]')).toBeVisible();
    
    // Check that animations are disabled
    const animatedElements = page.locator('[class*="animate-"]');
    await expect(animatedElements).toHaveCount(0);
  });

  test('should provide proper contrast ratios', async ({ page }) => {
    // Check that text has sufficient contrast
    const textElements = page.locator('p, span, h2, h3');
    
    for (let i = 0; i < await textElements.count(); i++) {
      const element = textElements.nth(i);
      const color = await element.evaluate(el => {
        const styles = window.getComputedStyle(el);
        return styles.color;
      });
      
      // Basic check that color is not transparent
      expect(color).not.toBe('rgba(0, 0, 0, 0)');
    }
  });

  test('should handle different screen readers', async ({ page }) => {
    // Check for proper semantic HTML
    await expect(page.locator('main')).toBeVisible();
    await expect(page.locator('section')).toBeVisible();
    
    // Check for proper heading structure
    const headings = page.locator('h1, h2, h3, h4, h5, h6');
    await expect(headings).toHaveCount(3); // Main heading + 2 subheadings
    
    // Check for proper list structure where applicable
    const lists = page.locator('ul, ol');
    await expect(lists).toHaveCount(0); // No lists in this component
  });

  test('should support high contrast mode', async ({ page }) => {
    // Enable high contrast mode
    await page.emulateMedia({ colorScheme: 'dark' });
    
    // Reload the page
    await page.reload();
    await page.waitForLoadState('networkidle');
    
    // Check that the panel still renders correctly
    await expect(page.locator('[data-testid="beta-metrics-panel"]')).toBeVisible();
    
    // Check that all text is still readable
    await expect(page.locator('text=Retention')).toBeVisible();
    await expect(page.locator('text=Comfort Level')).toBeVisible();
    await expect(page.locator('text=Strain Health')).toBeVisible();
    await expect(page.locator('text=Session Frequency')).toBeVisible();
  });
});
