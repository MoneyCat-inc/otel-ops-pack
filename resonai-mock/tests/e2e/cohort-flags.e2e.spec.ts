/**
 * Cohort Flags E2E Tests
 * 
 * C4: Cohort Analytics Toggles
 * Tests for cohort UI behavior with flags ON vs OFF.
 */

import { test, expect } from '@playwright/test';
import '../e2e/playwright-helpers';

test.describe('Cohort Flags E2E Tests', () => {
  test.describe('Flags OFF (Default)', () => {
    test('should not show cohort CTA in navigation @cohort-flags', async ({ page }) => {
      await page.goto('/');
      await page.waitForLoadState('networkidle');

      // Should not see the cohort CTA button
      await expect(page.locator('a[href="/progress"]').filter({ hasText: 'Progress' })).not.toBeVisible();
      
      // Should see regular navigation links
      await expect(page.locator('a[href="/practice"]')).toBeVisible();
      await expect(page.locator('a[href="/data"]')).toBeVisible();
    });

    test('should not show event summary on practice page @cohort-flags', async ({ page }) => {
      await page.goto('/practice');
      await page.waitForLoadState('networkidle');

      // Should not see the local event summary component
      await expect(page.locator('text=Your Practice Summary')).not.toBeVisible();
      await expect(page.locator('text=Total Sessions')).not.toBeVisible();
      
      // Should see regular practice page content
      await expect(page.locator('text=Practice Session')).toBeVisible();
    });

    test('should have unchanged UI with flags OFF @cohort-flags', async ({ page }) => {
      await page.goto('/');
      await page.waitForLoadState('networkidle');

      // Take screenshot for visual regression testing
      await expect(page).toHaveScreenshot('cohort-flags-off.png');
    });
  });

  test.describe('Flags ON (Cohort Enabled)', () => {
    test.beforeEach(async ({ page }) => {
      // Set cohort flags to ON
      await page.addInitScript(() => {
        window.__env = {
          NEXT_PUBLIC_COHORT_ENABLED: '1',
          NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY: '1',
          NEXT_PUBLIC_COHORT_EVENT_SUMMARY: '1'
        };
      });
    });

    test('should show cohort CTA in navigation @cohort-flags', async ({ page }) => {
      await page.goto('/');
      await page.waitForLoadState('networkidle');

      // Should see the cohort CTA button
      await expect(page.locator('a[href="/progress"]').filter({ hasText: 'Progress' })).toBeVisible();
      
      // Should also see regular navigation
      await expect(page.locator('a[href="/practice"]')).toBeVisible();
      await expect(page.locator('a[href="/data"]')).toBeVisible();
    });

    test('should show event summary on practice page @cohort-flags', async ({ page }) => {
      await page.goto('/practice');
      await page.waitForLoadState('networkidle');

      // Should see the local event summary component
      await expect(page.locator('text=Your Practice Summary')).toBeVisible();
      await expect(page.locator('text=Total Sessions')).toBeVisible();
      await expect(page.locator('text=This Week')).toBeVisible();
      await expect(page.locator('text=Avg Accuracy')).toBeVisible();
      await expect(page.locator('text=Avg Comfort')).toBeVisible();
      
      // Should see privacy notice
      await expect(page.locator('text=All data stays local')).toBeVisible();
      await expect(page.locator('text=No uploads')).toBeVisible();
    });

    test('should navigate to progress page from CTA @cohort-flags', async ({ page }) => {
      await page.goto('/');
      await page.waitForLoadState('networkidle');

      // Click the cohort CTA
      await page.locator('a[href="/progress"]').filter({ hasText: 'Progress' }).click();
      
      // Should navigate to progress page
      await expect(page).toHaveURL('/progress');
      await expect(page.locator('text=Your Progress')).toBeVisible();
    });

    test('should navigate to progress page from event summary @cohort-flags', async ({ page }) => {
      await page.goto('/practice');
      await page.waitForLoadState('networkidle');

      // Click the "View Details" link in event summary
      await page.locator('a[href="/progress"]').filter({ hasText: 'View Details' }).click();
      
      // Should navigate to progress page
      await expect(page).toHaveURL('/progress');
      await expect(page.locator('text=Your Progress')).toBeVisible();
    });

    test('should have accessible cohort CTA @cohort-flags', async ({ page }) => {
      await page.goto('/');
      await page.waitForLoadState('networkidle');

      const cta = page.locator('a[href="/progress"]').filter({ hasText: 'Progress' });
      
      // Should have proper ARIA label
      await expect(cta).toHaveAttribute('aria-label', 'View your progress dashboard');
      
      // Should be keyboard focusable
      await page.keyboard.press('Tab');
      await expect(cta).toBeFocused();
      
      // Should be clickable with keyboard
      await page.keyboard.press('Enter');
      await expect(page).toHaveURL('/progress');
    });

    test('should have accessible event summary @cohort-flags', async ({ page }) => {
      await page.goto('/practice');
      await page.waitForLoadState('networkidle');

      const summaryLink = page.locator('a[href="/progress"]').filter({ hasText: 'View Details' });
      
      // Should have proper ARIA label
      await expect(summaryLink).toHaveAttribute('aria-label', 'View detailed progress dashboard');
      
      // Should be keyboard focusable
      await page.keyboard.press('Tab');
      await page.keyboard.press('Tab'); // Skip other elements
      await expect(summaryLink).toBeFocused();
      
      // Should be clickable with keyboard
      await page.keyboard.press('Enter');
      await expect(page).toHaveURL('/progress');
    });

    test('should respect reduced motion preferences @cohort-flags', async ({ page }) => {
      await page.emulateMedia({ reducedMotion: 'reduce' });
      await page.goto('/practice');
      await page.waitForLoadState('networkidle');

      // Check that animations are disabled
      const summaryElement = page.locator('text=Your Practice Summary').locator('..');
      const classList = await summaryElement.getAttribute('class');
      
      // Should not contain transition classes when reduced motion is enabled
      expect(classList).not.toContain('transition-all');
      expect(classList).not.toContain('animate-spin');
    });

    test('should load local data only (no network calls) @cohort-flags', async ({ page }) => {
      const networkRequests: string[] = [];
      
      page.on('request', request => {
        networkRequests.push(request.url());
      });

      await page.goto('/practice');
      await page.waitForLoadState('networkidle');

      // Should not make any network calls for cohort data
      const cohortRequests = networkRequests.filter(url => 
        url.includes('cohort') || 
        url.includes('analytics') || 
        url.includes('progress') ||
        url.includes('summary')
      );
      
      expect(cohortRequests).toHaveLength(0);
    });

    test('should have proper focus management @cohort-flags', async ({ page }) => {
      await page.goto('/practice');
      await page.waitForLoadState('networkidle');

      // Tab through the page
      await page.keyboard.press('Tab');
      await page.keyboard.press('Tab');
      await page.keyboard.press('Tab');
      
      // Should be able to focus on the event summary link
      const summaryLink = page.locator('a[href="/progress"]').filter({ hasText: 'View Details' });
      await expect(summaryLink).toBeFocused();
      
      // Should have visible focus ring
      const focusRing = await summaryLink.evaluate(el => {
        const styles = window.getComputedStyle(el);
        return styles.outline !== 'none' || styles.boxShadow !== 'none';
      });
      
      expect(focusRing).toBe(true);
    });
  });

  test.describe('Partial Flag Configuration', () => {
    test('should show only dashboard entry when event summary disabled @cohort-flags', async ({ page }) => {
      await page.addInitScript(() => {
        window.__env = {
          NEXT_PUBLIC_COHORT_ENABLED: '1',
          NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY: '1',
          NEXT_PUBLIC_COHORT_EVENT_SUMMARY: '0'
        };
      });

      await page.goto('/');
      await page.waitForLoadState('networkidle');

      // Should see dashboard CTA
      await expect(page.locator('a[href="/progress"]').filter({ hasText: 'Progress' })).toBeVisible();
      
      // Should not see event summary on practice page
      await page.goto('/practice');
      await page.waitForLoadState('networkidle');
      await expect(page.locator('text=Your Practice Summary')).not.toBeVisible();
    });

    test('should show only event summary when dashboard entry disabled @cohort-flags', async ({ page }) => {
      await page.addInitScript(() => {
        window.__env = {
          NEXT_PUBLIC_COHORT_ENABLED: '1',
          NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY: '0',
          NEXT_PUBLIC_COHORT_EVENT_SUMMARY: '1'
        };
      });

      await page.goto('/');
      await page.waitForLoadState('networkidle');

      // Should not see dashboard CTA
      await expect(page.locator('a[href="/progress"]').filter({ hasText: 'Progress' })).not.toBeVisible();
      
      // Should see event summary on practice page
      await page.goto('/practice');
      await page.waitForLoadState('networkidle');
      await expect(page.locator('text=Your Practice Summary')).toBeVisible();
    });
  });

  test.describe('Error Handling', () => {
    test('should handle invalid flag values gracefully @cohort-flags', async ({ page }) => {
      await page.addInitScript(() => {
        window.__env = {
          NEXT_PUBLIC_COHORT_ENABLED: 'invalid',
          NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY: 'true',
          NEXT_PUBLIC_COHORT_EVENT_SUMMARY: 'yes'
        };
      });

      await page.goto('/');
      await page.waitForLoadState('networkidle');

      // Should not show any cohort features with invalid values
      await expect(page.locator('a[href="/progress"]').filter({ hasText: 'Progress' })).not.toBeVisible();
      
      await page.goto('/practice');
      await page.waitForLoadState('networkidle');
      await expect(page.locator('text=Your Practice Summary')).not.toBeVisible();
    });

    test('should handle missing environment variables @cohort-flags', async ({ page }) => {
      await page.addInitScript(() => {
        window.__env = {};
      });

      await page.goto('/');
      await page.waitForLoadState('networkidle');

      // Should not show any cohort features
      await expect(page.locator('a[href="/progress"]').filter({ hasText: 'Progress' })).not.toBeVisible();
      
      await page.goto('/practice');
      await page.waitForLoadState('networkidle');
      await expect(page.locator('text=Your Practice Summary')).not.toBeVisible();
    });
  });

  test.describe('Cross-Browser Compatibility', () => {
    test('should work in Firefox @cohort-flags', async ({ page, browserName }) => {
      if (browserName !== 'firefox') {
        test.skip();
      }

      await page.addInitScript(() => {
        window.__env = {
          NEXT_PUBLIC_COHORT_ENABLED: '1',
          NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY: '1',
          NEXT_PUBLIC_COHORT_EVENT_SUMMARY: '1'
        };
      });

      await page.goto('/');
      await page.waitForLoadState('networkidle');

      // Should see cohort CTA
      await expect(page.locator('a[href="/progress"]').filter({ hasText: 'Progress' })).toBeVisible();
      
      // Should navigate correctly
      await page.locator('a[href="/progress"]').filter({ hasText: 'Progress' }).click();
      await expect(page).toHaveURL('/progress');
    });

    test('should work in Chromium @cohort-flags', async ({ page, browserName }) => {
      if (browserName !== 'chromium') {
        test.skip();
      }

      await page.addInitScript(() => {
        window.__env = {
          NEXT_PUBLIC_COHORT_ENABLED: '1',
          NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY: '1',
          NEXT_PUBLIC_COHORT_EVENT_SUMMARY: '1'
        };
      });

      await page.goto('/practice');
      await page.waitForLoadState('networkidle');

      // Should see event summary
      await expect(page.locator('text=Your Practice Summary')).toBeVisible();
      
      // Should navigate correctly
      await page.locator('a[href="/progress"]').filter({ hasText: 'View Details' }).click();
      await expect(page).toHaveURL('/progress');
    });
  });
});
