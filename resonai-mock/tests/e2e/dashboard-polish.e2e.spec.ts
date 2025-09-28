/**
 * Dashboard Polish E2E Tests
 * 
 * C7: Dashboard Polish & UX
 * Playwright tests for OrbV2 shimmer overlay, FriendlySummary, and motion safety features.
 */

import { test, expect } from '@playwright/test';

test.describe('Dashboard Polish & UX', () => {
  test.beforeEach(async ({ page }) => {
    // Console guard for CSP violations
    page.on('console', msg => {
      const text = msg.text();
      if (/Cross-Origin-Embedder-Policy|Refused to apply inline|Content Security Policy/.test(text)) {
        throw new Error(`Console security error: ${text}`);
      }
    });

    // Navigate to progress page
    await page.goto('/progress');
    
    // Wait for page to load
    await expect(page.getByRole('heading', { name: /Your Progress/i })).toBeVisible();
  });

  test.describe('OrbV2 Shimmer Overlay', () => {
    test('should render OrbV2 with resonance-based shimmer effects', async ({ page }) => {
      // Check that OrbV2 component is present
      const orbContainer = page.locator('.orb-v2');
      await expect(orbContainer).toBeVisible();
      
      // Check for main orb element
      const orbMain = page.locator('.orb-v2-main');
      await expect(orbMain).toBeVisible();
      
      // Check for shimmer overlay
      const shimmerOverlay = page.locator('.orb-v2-shimmer');
      await expect(shimmerOverlay).toBeVisible();
      
      // Check for strain pulse ring
      const pulseRing = page.locator('.orb-v2-pulse');
      await expect(pulseRing).toBeVisible();
      
      // Check for inner glow
      const innerGlow = page.locator('.orb-v2-glow');
      await expect(innerGlow).toBeVisible();
    });

    test('should have no inline styles (CSP compliance)', async ({ page }) => {
      // Check that OrbV2 has no inline style attribute
      const orbContainer = page.locator('.orb-v2');
      await expect(orbContainer).toBeVisible();
      
      const styleAttr = await orbContainer.getAttribute('style');
      expect(styleAttr).toBeNull(); // CSP guard - no inline styles
      
      // Check that orb main also has no inline styles
      const orbMain = page.locator('.orb-v2-main');
      const mainStyleAttr = await orbMain.getAttribute('style');
      expect(mainStyleAttr).toBeNull(); // CSP guard - no inline styles
    });

    test('should use class-based hue selection', async ({ page }) => {
      // Check that OrbV2 has a hue class
      const orbContainer = page.locator('.orb-v2');
      await expect(orbContainer).toBeVisible();
      
      const classList = await orbContainer.getAttribute('class');
      expect(classList).toMatch(/orb-v2--h\d+|orb-v2--(front|central|back)/);
    });

    test('should have proper accessibility attributes', async ({ page }) => {
      const orbContainer = page.locator('.orb-v2');
      
      // Check for proper ARIA attributes
      await expect(orbContainer).toHaveAttribute('role', 'img');
      await expect(orbContainer).toHaveAttribute('aria-label');
      await expect(orbContainer).toHaveAttribute('aria-hidden', 'false');
      
      // Check that aria-label contains meaningful information
      const ariaLabel = await orbContainer.getAttribute('aria-label');
      expect(ariaLabel).toContain('Resonance visualization');
      expect(ariaLabel).toContain('expressiveness');
      expect(ariaLabel).toContain('strain');
    });

    test('should be focusable for keyboard navigation', async ({ page }) => {
      const orbContainer = page.locator('.orb-v2');
      
      // Focus the orb
      await orbContainer.focus();
      await expect(orbContainer).toBeFocused();
      
      // Check for focus-visible styles
      const hasFocusStyles = await orbContainer.evaluate((el) => {
        const computedStyle = window.getComputedStyle(el, ':focus-visible');
        return computedStyle.outline !== 'none';
      });
      
      expect(hasFocusStyles).toBe(true);
    });
  });

  test.describe('Motion Safety', () => {
    test('should respect prefers-reduced-motion for OrbV2 animations', async ({ page }) => {
      // Enable reduced motion
      await page.emulateMedia({ reducedMotion: 'reduce' });
      
      // Reload page to apply reduced motion
      await page.reload();
      await expect(page.getByRole('heading', { name: /Your Progress/i })).toBeVisible();
      
      // Check that orb container doesn't have shimmer/pulse animation classes
      const orbContainer = page.locator('.orb-v2');
      const classList = await orbContainer.getAttribute('class');
      expect(classList).not.toMatch(/orb-v2__shimmer|orb-v2__pulse--strain/);
      
      // Verify animations are disabled via CSS
      const shimmerOverlay = page.locator('.orb-v2-shimmer');
      const shimmerAnimation = await shimmerOverlay.evaluate((el) => {
        const computedStyle = window.getComputedStyle(el);
        return computedStyle.animation === 'none';
      });
      expect(shimmerAnimation).toBe(true);
      
      const pulseRing = page.locator('.orb-v2-pulse');
      const pulseAnimation = await pulseRing.evaluate((el) => {
        const computedStyle = window.getComputedStyle(el);
        return computedStyle.animation === 'none';
      });
      expect(pulseAnimation).toBe(true);
    });

    test('should respect prefers-reduced-motion for loading spinner', async ({ page }) => {
      // Enable reduced motion
      await page.emulateMedia({ reducedMotion: 'reduce' });
      
      // Mock slow loading to trigger spinner
      await page.route('**/progress**', route => {
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
      
      // Check for loading state
      await expect(page.getByText(/Loading your progress/i)).toBeVisible();
      
      // Check that spinner respects reduced motion
      const spinner = page.locator('.animate-spin');
      if (await spinner.count() > 0) {
        const classList = await spinner.first().getAttribute('class');
        expect(classList).not.toContain('animate-spin');
      }
    });

    test('should provide static fallbacks for reduced motion', async ({ page }) => {
      // Enable reduced motion
      await page.emulateMedia({ reducedMotion: 'reduce' });
      
      // Reload page
      await page.reload();
      await expect(page.getByRole('heading', { name: /Your Progress/i })).toBeVisible();
      
      // Check that shimmer has static transform
      const shimmerOverlay = page.locator('.orb-v2-shimmer');
      const shimmerTransform = await shimmerOverlay.evaluate((el) => {
        const computedStyle = window.getComputedStyle(el);
        return computedStyle.transform;
      });
      expect(shimmerTransform).toContain('rotate(45deg)');
      
      // Check that pulse has static scale
      const pulseRing = page.locator('.orb-v2-pulse');
      const pulseTransform = await pulseRing.evaluate((el) => {
        const computedStyle = window.getComputedStyle(el);
        return computedStyle.transform;
      });
      expect(pulseTransform).toContain('scale(1.02)');
    });

    test('should work with high contrast mode', async ({ page }) => {
      // Enable high contrast mode
      await page.emulateMedia({ forcedColors: 'active' });
      
      // Reload page
      await page.reload();
      await expect(page.getByRole('heading', { name: /Your Progress/i })).toBeVisible();
      
      // Check that orb has high contrast borders
      const orbMain = page.locator('.orb-v2-main');
      const hasBorder = await orbMain.evaluate((el) => {
        const computedStyle = window.getComputedStyle(el);
        return computedStyle.border !== 'none' && computedStyle.borderWidth !== '0px';
      });
      expect(hasBorder).toBe(true);
      
      // Check that pulse ring has high contrast border
      const pulseRing = page.locator('.orb-v2-pulse');
      const pulseBorder = await pulseRing.evaluate((el) => {
        const computedStyle = window.getComputedStyle(el);
        return computedStyle.border !== 'none' && computedStyle.borderWidth !== '0px';
      });
      expect(pulseBorder).toBe(true);
    });
  });

  test.describe('FriendlySummary Component', () => {
    test('should display encouraging summary message', async ({ page }) => {
      // Check for friendly summary container
      const summaryContainer = page.locator('[role="region"][aria-labelledby="friendly-summary-title"]');
      await expect(summaryContainer).toBeVisible();
      
      // Check for main summary message
      const summaryMessage = page.locator('p').filter({ hasText: /Last \d+ days/ });
      await expect(summaryMessage).toBeVisible();
      
      // Check for encouragement message
      const encouragementMessage = page.locator('p').filter({ hasText: /Keep up the great work|You're on the right track|Keep it up/ });
      await expect(encouragementMessage).toBeVisible();
    });

    test('should have proper accessibility announcements', async ({ page }) => {
      // Check for screen reader announcement
      const liveRegion = page.locator('[aria-live="polite"][role="status"]');
      await expect(liveRegion).toBeVisible();
      
      // Check that live region contains summary information
      const liveRegionText = await liveRegion.textContent();
      expect(liveRegionText).toContain('Progress summary');
      expect(liveRegionText).toContain('sessions');
      
      // Check for additional screen reader context
      const srOnlyText = page.locator('.sr-only p');
      await expect(srOnlyText).toBeVisible();
      
      const srText = await srOnlyText.textContent();
      expect(srText).toContain('practice sessions');
      expect(srText).toContain('practice time');
      expect(srText).toContain('average session');
      expect(srText).toContain('safety trend');
    });

    test('should display statistics in grid format', async ({ page }) => {
      // Check for stats grid
      const statsGrid = page.locator('.grid.grid-cols-2.md\\:grid-cols-4');
      await expect(statsGrid).toBeVisible();
      
      // Check for individual stat items
      await expect(page.getByText(/Sessions/i)).toBeVisible();
      await expect(page.getByText(/Practice Time/i)).toBeVisible();
      await expect(page.getByText(/Avg Session/i)).toBeVisible();
      await expect(page.getByText(/Safety/i)).toBeVisible();
      
      // Check for stat values
      const statValues = page.locator('.text-2xl.font-bold');
      await expect(statValues).toHaveCount(4);
      
      // Check that stat values are numeric or time-based
      for (let i = 0; i < 4; i++) {
        const value = await statValues.nth(i).textContent();
        expect(value).toBeTruthy();
        expect(value).not.toBe('');
      }
    });

    test('should adapt theme based on progress', async ({ page }) => {
      // Check for theme-based styling
      const summaryContainer = page.locator('[role="region"][aria-labelledby="friendly-summary-title"]');
      
      // Should have one of the theme classes
      const hasThemeClass = await summaryContainer.evaluate((el) => {
        const classList = el.className;
        return classList.includes('bg-green-50') || 
               classList.includes('bg-blue-50') || 
               classList.includes('bg-amber-50');
      });
      expect(hasThemeClass).toBe(true);
    });

    test('should update message based on date range selection', async ({ page }) => {
      // Get initial message
      const initialMessage = page.locator('p').filter({ hasText: /Last \d+ days/ });
      await expect(initialMessage).toBeVisible();
      const initialText = await initialMessage.textContent();
      
      // Change date range
      const dateRangeSelect = page.getByLabel(/Time Period/i);
      await dateRangeSelect.selectOption('14d');
      
      // Wait for message to update
      await page.waitForTimeout(100);
      
      // Check that message updated
      const updatedMessage = page.locator('p').filter({ hasText: /Last 2 weeks/ });
      await expect(updatedMessage).toBeVisible();
      
      const updatedText = await updatedMessage.textContent();
      expect(updatedText).not.toBe(initialText);
      expect(updatedText).toContain('Last 2 weeks');
    });
  });

  test.describe('Cross-Browser Compatibility', () => {
    test('should work in Firefox', async ({ page, browserName }) => {
      if (browserName !== 'firefox') {
        test.skip();
      }
      
      // Check that OrbV2 renders correctly
      const orbContainer = page.locator('.orb-v2');
      await expect(orbContainer).toBeVisible();
      
      // Check that hue classes work
      const classList = await orbContainer.getAttribute('class');
      expect(classList).toMatch(/orb-v2--h\d+|orb-v2--(front|central|back)/);
      
      // Check that animations work
      const shimmerOverlay = page.locator('.orb-v2-shimmer');
      await expect(shimmerOverlay).toBeVisible();
    });

    test('should work in Chromium', async ({ page, browserName }) => {
      if (browserName !== 'chromium') {
        test.skip();
      }
      
      // Check that OrbV2 renders correctly
      const orbContainer = page.locator('.orb-v2');
      await expect(orbContainer).toBeVisible();
      
      // Check that hue classes work
      const classList = await orbContainer.getAttribute('class');
      expect(classList).toMatch(/orb-v2--h\d+|orb-v2--(front|central|back)/);
      
      // Check that animations work
      const shimmerOverlay = page.locator('.orb-v2-shimmer');
      await expect(shimmerOverlay).toBeVisible();
    });
  });

  test.describe('Performance', () => {
    test('should not impact page load performance', async ({ page }) => {
      // Measure page load time
      const startTime = Date.now();
      await page.goto('/progress');
      await expect(page.getByRole('heading', { name: /Your Progress/i })).toBeVisible();
      const loadTime = Date.now() - startTime;
      
      // Page should load within reasonable time (5 seconds)
      expect(loadTime).toBeLessThan(5000);
      
      // Check that OrbV2 is rendered
      const orbContainer = page.locator('.orb-v2-container');
      await expect(orbContainer).toBeVisible();
      
      // Check that FriendlySummary is rendered
      const summaryContainer = page.locator('[role="region"][aria-labelledby="friendly-summary-title"]');
      await expect(summaryContainer).toBeVisible();
    });

    test('should handle rapid date range changes', async ({ page }) => {
      const dateRangeSelect = page.getByLabel(/Time Period/i);
      
      // Rapidly change date ranges
      await dateRangeSelect.selectOption('7d');
      await page.waitForTimeout(50);
      await dateRangeSelect.selectOption('14d');
      await page.waitForTimeout(50);
      await dateRangeSelect.selectOption('30d');
      await page.waitForTimeout(50);
      await dateRangeSelect.selectOption('all');
      
      // Should still be responsive
      await expect(page.getByRole('heading', { name: /Your Progress/i })).toBeVisible();
      
      // OrbV2 should still be visible
      const orbContainer = page.locator('.orb-v2');
      await expect(orbContainer).toBeVisible();
    });
  });

  test.describe('Integration', () => {
    test('should work together with existing dashboard features', async ({ page }) => {
      // Check that all components work together
      await expect(page.getByRole('heading', { name: /Your Progress/i })).toBeVisible();
      
      // OrbV2 should be visible
      const orbContainer = page.locator('.orb-v2');
      await expect(orbContainer).toBeVisible();
      
      // FriendlySummary should be visible
      const summaryContainer = page.locator('[role="region"][aria-labelledby="friendly-summary-title"]');
      await expect(summaryContainer).toBeVisible();
      
      // Metric cards should be visible
      await expect(page.getByText(/Pitch Accuracy/i)).toBeVisible();
      await expect(page.getByText(/Expressiveness/i)).toBeVisible();
      await expect(page.getByText(/Resonance Balance/i)).toBeVisible();
      
      // Safety timeline should be visible
      await expect(page.getByText(/Safety Timeline/i)).toBeVisible();
      
      // Controls should work
      const dateRangeSelect = page.getByLabel(/Time Period/i);
      await dateRangeSelect.selectOption('7d');
      await expect(page.getByText(/Last 7 days/)).toBeVisible();
    });

    test('should maintain accessibility with all features enabled', async ({ page }) => {
      // Check for single aria-live region
      const liveRegions = page.locator('[aria-live="polite"]');
      await expect(liveRegions).toHaveCount(1);
      
      // Check for proper heading structure
      await expect(page.getByRole('heading', { name: /Your Progress/i, level: 1 })).toBeVisible();
      await expect(page.getByRole('heading', { name: /Your Practice Summary/i, level: 2 })).toBeVisible();
      
      // Check for proper form labels
      await expect(page.getByLabel(/Time Period/i)).toBeVisible();
      
      // Check for proper ARIA roles
      await expect(page.locator('[role="img"]')).toBeVisible(); // OrbV2
      await expect(page.locator('[role="region"]')).toBeVisible(); // FriendlySummary
      await expect(page.locator('[role="status"]')).toBeVisible(); // Live region
    });
  });
});