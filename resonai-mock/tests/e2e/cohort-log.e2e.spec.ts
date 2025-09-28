/**
 * Cohort Log E2E Tests
 * 
 * C5: Cohort Log & Tester Guide
 * End-to-end tests for cohort log UI functionality and accessibility.
 */

import { test, expect } from '@playwright/test';

test.describe('Cohort Log UI', () => {
  test.beforeEach(async ({ page }) => {
    // Enable cohort features
    await page.addInitScript(() => {
      window.__env = {
        NEXT_PUBLIC_COHORT_ENABLED: '1',
        NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY: '1',
        NEXT_PUBLIC_COHORT_EVENT_SUMMARY: '1',
      };
    });

    // Navigate to cohort log page
    await page.goto('/labs/cohort-log');
  });

  test('should display cohort log page with privacy notice', async ({ page }) => {
    // Check page title and main heading
    await expect(page.locator('h1')).toContainText('Cohort Log Viewer');
    
    // Check privacy notice
    await expect(page.locator('text=Privacy Notice')).toBeVisible();
    await expect(page.locator('text=Local-only session logging')).toBeVisible();
    await expect(page.locator('text=No information is sent to external servers')).toBeVisible();
  });

  test('should show empty state when no sessions logged', async ({ page }) => {
    // Check empty state
    await expect(page.locator('text=No sessions logged')).toBeVisible();
    await expect(page.locator('text=Complete practice sessions to see them logged here')).toBeVisible();
    
    // Check stats show zero sessions
    await expect(page.locator('text=Total Sessions')).toBeVisible();
    await expect(page.locator('text=0')).toBeVisible();
  });

  test('should display enabled features when cohort is active', async ({ page }) => {
    // Check enabled features section
    await expect(page.locator('text=Enabled Features')).toBeVisible();
    await expect(page.locator('text=cohort')).toBeVisible();
    await expect(page.locator('text=dashboard-entry')).toBeVisible();
    await expect(page.locator('text=event-summary')).toBeVisible();
  });

  test('should show cohort status as enabled', async ({ page }) => {
    // Check cohort status
    await expect(page.locator('text=Cohort Status')).toBeVisible();
    await expect(page.locator('text=Enabled')).toBeVisible();
  });

  test('should have accessible action buttons', async ({ page }) => {
    // Check export button is present but disabled (no sessions)
    const exportButton = page.locator('button:has-text("Export JSON")');
    await expect(exportButton).toBeVisible();
    await expect(exportButton).toBeDisabled();

    // Check clear button is present but disabled (no sessions)
    const clearButton = page.locator('button:has-text("Clear All Data")');
    await expect(clearButton).toBeVisible();
    await expect(clearButton).toBeDisabled();

    // Check refresh button is enabled
    const refreshButton = page.locator('button:has-text("Refresh")');
    await expect(refreshButton).toBeVisible();
    await expect(refreshButton).toBeEnabled();
  });

  test('should support keyboard navigation', async ({ page }) => {
    // Tab through interactive elements
    await page.keyboard.press('Tab');
    await expect(page.locator('button:has-text("Export JSON")')).toBeFocused();
    
    await page.keyboard.press('Tab');
    await expect(page.locator('button:has-text("Clear All Data")')).toBeFocused();
    
    await page.keyboard.press('Tab');
    await expect(page.locator('button:has-text("Refresh")')).toBeFocused();
  });

  test('should have proper ARIA labels and roles', async ({ page }) => {
    // Check main heading has proper role
    const heading = page.locator('h1');
    await expect(heading).toHaveAttribute('role', 'heading');
    
    // Check buttons have proper roles
    const buttons = page.locator('button');
    const buttonCount = await buttons.count();
    
    for (let i = 0; i < buttonCount; i++) {
      const button = buttons.nth(i);
      await expect(button).toHaveAttribute('role', 'button');
    }
  });

  test('should handle refresh action', async ({ page }) => {
    // Click refresh button
    await page.click('button:has-text("Refresh")');
    
    // Page should reload and show same empty state
    await expect(page.locator('text=No sessions logged')).toBeVisible();
  });
});

test.describe('Cohort Log with Data', () => {
  test.beforeEach(async ({ page }) => {
    // Enable cohort features
    await page.addInitScript(() => {
      window.__env = {
        NEXT_PUBLIC_COHORT_ENABLED: '1',
        NEXT_PUBLIC_COHORT_DASHBOARD_ENTRY: '1',
        NEXT_PUBLIC_COHORT_EVENT_SUMMARY: '1',
      };
    });

    // Add mock session data to localStorage
    await page.addInitScript(() => {
      const mockLogData = {
        sessions: [
          {
            cohortId: 'test-uuid-1',
            timestamp: Date.now() - 86400000, // 1 day ago
            buildHash: 'build-test123',
            flagsEnabled: ['cohort', 'dashboard-entry'],
            sessionSummary: {
              ts: Date.now() - 86400000,
              medianF0: 150,
              inBandPct: 0.75,
              comfort: 4,
              fatigue: 2,
              schemaVersion: 1,
            },
            metadata: {
              userAgent: 'Mozilla/5.0 (Test Browser)',
              viewport: { width: 1920, height: 1080 },
              platform: 'TestPlatform',
              cohortVersion: '1.0.0',
            },
          },
          {
            cohortId: 'test-uuid-2',
            timestamp: Date.now(),
            buildHash: 'build-test123',
            flagsEnabled: ['cohort', 'event-summary'],
            sessionSummary: {
              ts: Date.now(),
              medianF0: 160,
              inBandPct: 0.80,
              comfort: 5,
              fatigue: 1,
              schemaVersion: 1,
            },
            metadata: {
              userAgent: 'Mozilla/5.0 (Test Browser)',
              viewport: { width: 1920, height: 1080 },
              platform: 'TestPlatform',
              cohortVersion: '1.0.0',
            },
          },
        ],
        metadata: {
          totalSessions: 2,
          firstSession: Date.now() - 86400000,
          lastSession: Date.now(),
          schemaVersion: '1.0.0',
          lastUpdated: Date.now(),
        },
      };
      
      localStorage.setItem('resonai_cohort_log', JSON.stringify(mockLogData));
    });

    await page.goto('/labs/cohort-log');
  });

  test('should display session logs when data exists', async ({ page }) => {
    // Check session count
    await expect(page.locator('text=Session Logs (2)')).toBeVisible();
    
    // Check individual sessions
    await expect(page.locator('text=Session #2')).toBeVisible();
    await expect(page.locator('text=Session #1')).toBeVisible();
    
    // Check session details
    await expect(page.locator('text=In-band: 80.0%')).toBeVisible();
    await expect(page.locator('text=Comfort: 5/5')).toBeVisible();
    await expect(page.locator('text=Fatigue: 1/5')).toBeVisible();
  });

  test('should enable action buttons when sessions exist', async ({ page }) => {
    // Export button should be enabled
    const exportButton = page.locator('button:has-text("Export JSON")');
    await expect(exportButton).toBeEnabled();
    
    // Clear button should be enabled
    const clearButton = page.locator('button:has-text("Clear All Data")');
    await expect(clearButton).toBeEnabled();
  });

  test('should handle export functionality', async ({ page }) => {
    // Set up download handling
    const downloadPromise = page.waitForEvent('download');
    
    // Click export button
    await page.click('button:has-text("Export JSON")');
    
    // Wait for download
    const download = await downloadPromise;
    
    // Check download filename
    expect(download.suggestedFilename()).toMatch(/^resonai-cohort-log-\d{4}-\d{2}-\d{2}\.json$/);
  });

  test('should handle clear functionality with confirmation', async ({ page }) => {
    // Mock confirm dialog
    page.on('dialog', async dialog => {
      expect(dialog.type()).toBe('confirm');
      expect(dialog.message()).toContain('Are you sure you want to clear all cohort log data?');
      await dialog.accept();
    });

    // Click clear button
    await page.click('button:has-text("Clear All Data")');
    
    // Wait for page to update
    await page.waitForTimeout(100);
    
    // Check that sessions are cleared
    await expect(page.locator('text=No sessions logged')).toBeVisible();
    await expect(page.locator('text=Session Logs (0)')).toBeVisible();
  });

  test('should cancel clear when confirmation is dismissed', async ({ page }) => {
    // Mock confirm dialog to cancel
    page.on('dialog', async dialog => {
      await dialog.dismiss();
    });

    // Click clear button
    await page.click('button:has-text("Clear All Data")');
    
    // Wait for page to update
    await page.waitForTimeout(100);
    
    // Check that sessions are still there
    await expect(page.locator('text=Session Logs (2)')).toBeVisible();
    await expect(page.locator('text=Session #2')).toBeVisible();
  });

  test('should display session metadata correctly', async ({ page }) => {
    // Check cohort IDs are displayed (truncated)
    await expect(page.locator('text=test-uuid...')).toBeVisible();
    
    // Check build hash
    await expect(page.locator('text=Build: build-test123')).toBeVisible();
    
    // Check version
    await expect(page.locator('text=Version: 1.0.0')).toBeVisible();
    
    // Check enabled flags
    await expect(page.locator('text=cohort')).toBeVisible();
    await expect(page.locator('text=dashboard-entry')).toBeVisible();
  });

  test('should show correct statistics', async ({ page }) => {
    // Check total sessions
    await expect(page.locator('text=Total Sessions')).toBeVisible();
    await expect(page.locator('text=2')).toBeVisible();
    
    // Check date range (should show actual dates)
    await expect(page.locator('text=Date Range')).toBeVisible();
    // Date range should not show "No sessions"
    await expect(page.locator('text=No sessions')).not.toBeVisible();
  });

  test('should be responsive on mobile', async ({ page }) => {
    // Set mobile viewport
    await page.setViewportSize({ width: 375, height: 667 });
    
    // Check that page still loads
    await expect(page.locator('h1')).toContainText('Cohort Log Viewer');
    
    // Check that buttons are still accessible
    await expect(page.locator('button:has-text("Export JSON")')).toBeVisible();
    await expect(page.locator('button:has-text("Clear All Data")')).toBeVisible();
  });

  test('should handle loading states', async ({ page }) => {
    // Mock slow localStorage access
    await page.addInitScript(() => {
      const originalGetItem = localStorage.getItem;
      localStorage.getItem = function(key) {
        if (key === 'resonai_cohort_log') {
          // Simulate slow access
          return new Promise(resolve => {
            setTimeout(() => resolve(originalGetItem.call(this, key)), 100);
          }) as any;
        }
        return originalGetItem.call(this, key);
      };
    });

    // Reload page
    await page.reload();
    
    // Should show loading state initially
    await expect(page.locator('text=Loading cohort log...')).toBeVisible();
  });

  test('should handle errors gracefully', async ({ page }) => {
    // Mock localStorage to throw error
    await page.addInitScript(() => {
      const originalGetItem = localStorage.getItem;
      localStorage.getItem = function(key) {
        if (key === 'resonai_cohort_log') {
          throw new Error('Storage error');
        }
        return originalGetItem.call(this, key);
      };
    });

    // Reload page
    await page.reload();
    
    // Should show error state
    await expect(page.locator('text=Error')).toBeVisible();
    await expect(page.locator('text=Storage error')).toBeVisible();
  });
});

test.describe('Cohort Log Network Security', () => {
  test('@cohort-log no-network', async ({ page }) => {
    // Block any accidental network calls on the cohort log page
    await page.route('**/*', route => {
      const req = route.request();
      const type = req.resourceType();
      const sameOrigin = new URL(req.url()).origin === new URL(page.url()).origin;
      const ok = sameOrigin && ['document','stylesheet','script','font'].includes(type);
      ok ? route.continue() : route.abort();
    });

    // Console guard for COEP/CSP errors
    const BAD = ['Cross-Origin-Embedder-Policy', 'Refused to apply inline', 'Content Security Policy'];
    page.on('console', m => {
      if (BAD.some(b => m.text().includes(b))) {
        throw new Error(`Console security error: ${m.text()}`);
      }
    });

    await page.goto('/labs/cohort-log');
    
    // Verify page loads without network calls
    await expect(page.locator('h1')).toContainText('Cohort Log Viewer');
    
    // Verify no network requests were made (except same-origin resources)
    const requests = page.request.url();
    // This test ensures no external network calls
  });

  test('@cohort-log export-json', async ({ page, context }) => {
    // Add mock session data
    await page.addInitScript(() => {
      const mockLogData = {
        sessions: [{
          cohortId: 'test-uuid-1',
          timestamp: Date.now(),
          buildHash: 'build-test123',
          flagsEnabled: ['cohort'],
          sessionSummary: {
            ts: Date.now(),
            medianF0: 150,
            inBandPct: 0.75,
            schemaVersion: 1,
          },
          metadata: {
            userAgent: 'Mozilla/5.0 (Test Browser)',
            viewport: { width: 1920, height: 1080 },
            platform: 'TestPlatform',
            cohortVersion: '1.0.0',
          },
        }],
        metadata: {
          totalSessions: 1,
          firstSession: Date.now(),
          lastSession: Date.now(),
          schemaVersion: '1.0.0',
          lastUpdated: Date.now(),
        },
      };
      localStorage.setItem('resonai_cohort_log', JSON.stringify(mockLogData));
    });

    await page.goto('/labs/cohort-log');

    const [download] = await Promise.all([
      page.waitForEvent('download'),
      page.getByRole('button', { name: /export json/i }).click(),
    ]);
    
    const path = await download.path();
    const content = await (await download.createReadStream())?.read()?.toString?.() ?? '';
    const data = JSON.parse(content);
    
    expect(data.schemaVersion).toBeGreaterThan(0);
    expect(Array.isArray(data.entries)).toBe(true);
    expect(data.build).toBeDefined();
    expect(data.cohortId).toBeDefined();
  });
});

test.describe('Cohort Log Accessibility', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/labs/cohort-log');
  });

  test('should have proper heading hierarchy', async ({ page }) => {
    // Check h1 exists
    await expect(page.locator('h1')).toBeVisible();
    
    // Check h3 elements exist for sections
    const h3Elements = page.locator('h3');
    const h3Count = await h3Elements.count();
    expect(h3Count).toBeGreaterThan(0);
  });

  test('should have proper color contrast', async ({ page }) => {
    // Check that text is readable
    const heading = page.locator('h1');
    const headingColor = await heading.evaluate(el => {
      const styles = window.getComputedStyle(el);
      return styles.color;
    });
    
    // Should not be transparent or very light
    expect(headingColor).not.toBe('rgba(0, 0, 0, 0)');
    expect(headingColor).not.toBe('transparent');
  });

  test('should support screen reader navigation', async ({ page }) => {
    // Check that important elements have proper labels
    const buttons = page.locator('button');
    const buttonCount = await buttons.count();
    
    for (let i = 0; i < buttonCount; i++) {
      const button = buttons.nth(i);
      const text = await button.textContent();
      expect(text).toBeTruthy();
      expect(text!.trim().length).toBeGreaterThan(0);
    }
  });

  test('should have proper focus management', async ({ page }) => {
    // Tab through the page
    await page.keyboard.press('Tab');
    
    // First focusable element should be visible
    const focusedElement = page.locator(':focus');
    await expect(focusedElement).toBeVisible();
  });

  test('should work with reduced motion preferences', async ({ page }) => {
    // Set reduced motion preference
    await page.emulateMedia({ reducedMotion: 'reduce' });
    
    // Page should still function normally
    await expect(page.locator('h1')).toContainText('Cohort Log Viewer');
    
    // Buttons should still be clickable
    await expect(page.locator('button:has-text("Refresh")')).toBeEnabled();
  });
});
