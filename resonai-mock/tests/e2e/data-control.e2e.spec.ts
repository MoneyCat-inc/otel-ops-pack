/**
 * Data Control E2E Tests
 * 
 * C2: Export & Delete UX
 * Playwright tests for data export and deletion functionality.
 */

import { test, expect } from '@playwright/test';

test.describe('Data Control', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to data control page
    await page.goto('/data');
  });

  test('should load data control page with session summary', async ({ page }) => {
    // Wait for page to load
    await expect(page.getByRole('heading', { name: /Data Control/i })).toBeVisible();
    
    // Check for data summary
    await expect(page.getByText(/Your Data Summary/i)).toBeVisible();
    await expect(page.getByText(/Practice Sessions/i)).toBeVisible();
    await expect(page.getByText(/Avg Pitch Accuracy/i)).toBeVisible();
    await expect(page.getByText(/Avg Comfort/i)).toBeVisible();
    
    // Check for control cards
    await expect(page.getByText(/Export Your Data/i)).toBeVisible();
    await expect(page.getByText(/Delete All Data/i)).toBeVisible();
    
    // Check for privacy notice
    await expect(page.getByText(/Privacy & Data Control/i)).toBeVisible();
  });

  test('should have proper accessibility features', async ({ page }) => {
    // Check for skip link
    await page.keyboard.press('Tab');
    await expect(page.getByRole('link', { name: /Skip to main content/i })).toBeFocused();
    
    // Check for single aria-live region
    const liveRegions = page.locator('[aria-live="polite"]');
    await expect(liveRegions).toHaveCount(1);
    
    // Check for proper headings structure
    await expect(page.getByRole('heading', { name: /Data Control/i, level: 1 })).toBeVisible();
    await expect(page.getByRole('heading', { name: /Your Data Summary/i, level: 2 })).toBeVisible();
    
    // Check for proper form labels
    await expect(page.getByRole('button', { name: /Export all practice data as JSON file/i })).toBeVisible();
    await expect(page.getByRole('button', { name: /Delete all practice data permanently/i })).toBeVisible();
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
    
    // Test export button
    await page.keyboard.press('Tab');
    const exportButton = page.getByRole('button', { name: /Export all practice data as JSON file/i });
    await expect(exportButton).toBeFocused();
    
    // Test delete button
    await page.keyboard.press('Tab');
    const deleteButton = page.getByRole('button', { name: /Delete all practice data permanently/i });
    await expect(deleteButton).toBeFocused();
  });

  test('should export data as JSON file', async ({ page }) => {
    // Wait for page to load
    await expect(page.getByRole('heading', { name: /Data Control/i })).toBeVisible();
    
    // Set up download handling
    const downloadPromise = page.waitForEvent('download');
    
    // Click export button
    await page.getByRole('button', { name: /Export as JSON/i }).click();
    
    // Wait for download
    const download = await downloadPromise;
    
    // Check filename format
    const filename = download.suggestedFilename();
    expect(filename).toMatch(/^resonai_sessions_v\d+_\d{4}-\d{2}-\d{2}\.json$/);
    
    // Check file content
    const path = await download.path();
    expect(path).toBeTruthy();
    
    // Read and validate JSON content
    const fs = require('fs');
    const content = fs.readFileSync(path, 'utf8');
    const jsonData = JSON.parse(content);
    
    // Validate export structure
    expect(jsonData).toHaveProperty('schemaVersion');
    expect(jsonData).toHaveProperty('exportedAt');
    expect(jsonData).toHaveProperty('build');
    expect(jsonData).toHaveProperty('appVersion');
    expect(jsonData).toHaveProperty('sessions');
    expect(jsonData).toHaveProperty('summary');
    
    // Validate data types
    expect(typeof jsonData.schemaVersion).toBe('number');
    expect(typeof jsonData.exportedAt).toBe('string');
    expect(typeof jsonData.build).toBe('string');
    expect(typeof jsonData.appVersion).toBe('string');
    expect(Array.isArray(jsonData.sessions)).toBe(true);
    expect(typeof jsonData.summary).toBe('object');
    
    // Validate summary
    expect(jsonData.summary).toHaveProperty('totalSessions');
    expect(jsonData.summary).toHaveProperty('dateRange');
    expect(jsonData.summary).toHaveProperty('metrics');
    
    // Clean up
    fs.unlinkSync(path);
  });

  test('should open delete confirmation modal', async ({ page }) => {
    // Wait for page to load
    await expect(page.getByRole('heading', { name: /Data Control/i })).toBeVisible();
    
    // Click delete button
    await page.getByRole('button', { name: /Delete All Data/i }).click();
    
    // Check modal appears
    await expect(page.getByRole('dialog')).toBeVisible();
    await expect(page.getByText(/Confirm Data Deletion/i)).toBeVisible();
    await expect(page.getByText(/This will permanently delete/i)).toBeVisible();
    
    // Check modal accessibility
    const modal = page.getByRole('dialog');
    await expect(modal).toHaveAttribute('aria-modal', 'true');
    await expect(modal).toHaveAttribute('aria-labelledby');
    await expect(modal).toHaveAttribute('aria-describedby');
    
    // Check input field
    const confirmInput = page.getByLabel(/Type DELETE to confirm/i);
    await expect(confirmInput).toBeVisible();
    await expect(confirmInput).toHaveAttribute('placeholder', 'Type DELETE here');
    
    // Check buttons
    await expect(page.getByRole('button', { name: /Cancel/i })).toBeVisible();
    await expect(page.getByRole('button', { name: /Delete All/i })).toBeVisible();
  });

  test('should handle delete confirmation flow', async ({ page }) => {
    // Wait for page to load
    await expect(page.getByRole('heading', { name: /Data Control/i })).toBeVisible();
    
    // Open delete modal
    await page.getByRole('button', { name: /Delete All Data/i }).click();
    await expect(page.getByRole('dialog')).toBeVisible();
    
    // Try to delete without typing DELETE
    await page.getByRole('button', { name: /Delete All/i }).click();
    
    // Should show error message
    await expect(page.getByText(/Please type DELETE to confirm/i)).toBeVisible();
    
    // Type incorrect text
    await page.getByLabel(/Type DELETE to confirm/i).fill('delete');
    await page.getByRole('button', { name: /Delete All/i }).click();
    
    // Should still show error
    await expect(page.getByText(/Please type DELETE to confirm/i)).toBeVisible();
    
    // Type correct text
    await page.getByLabel(/Type DELETE to confirm/i).fill('DELETE');
    
    // Delete button should be enabled
    const deleteButton = page.getByRole('button', { name: /Delete All/i });
    await expect(deleteButton).not.toBeDisabled();
    
    // Click delete
    await deleteButton.click();
    
    // Should show loading state
    await expect(page.getByText(/Deleting all data/i)).toBeVisible();
    
    // Wait for completion
    await expect(page.getByText(/All data deleted successfully/i)).toBeVisible();
    
    // Modal should be closed
    await expect(page.getByRole('dialog')).not.toBeVisible();
  });

  test('should cancel delete confirmation', async ({ page }) => {
    // Wait for page to load
    await expect(page.getByRole('heading', { name: /Data Control/i })).toBeVisible();
    
    // Open delete modal
    await page.getByRole('button', { name: /Delete All Data/i }).click();
    await expect(page.getByRole('dialog')).toBeVisible();
    
    // Click cancel
    await page.getByRole('button', { name: /Cancel/i }).click();
    
    // Modal should be closed
    await expect(page.getByRole('dialog')).not.toBeVisible();
    
    // Should show cancellation message
    await expect(page.getByText(/Delete confirmation cancelled/i)).toBeVisible();
  });

  test('should handle modal focus trap', async ({ page }) => {
    // Wait for page to load
    await expect(page.getByRole('heading', { name: /Data Control/i })).toBeVisible();
    
    // Open delete modal
    await page.getByRole('button', { name: /Delete All Data/i }).click();
    await expect(page.getByRole('dialog')).toBeVisible();
    
    // Test focus trap - should focus on input field
    const confirmInput = page.getByLabel(/Type DELETE to confirm/i);
    await expect(confirmInput).toBeFocused();
    
    // Tab should cycle through modal elements
    await page.keyboard.press('Tab');
    const cancelButton = page.getByRole('button', { name: /Cancel/i });
    await expect(cancelButton).toBeFocused();
    
    await page.keyboard.press('Tab');
    const deleteButton = page.getByRole('button', { name: /Delete All/i });
    await expect(deleteButton).toBeFocused();
    
    // Tab again should go back to input (focus trap)
    await page.keyboard.press('Tab');
    await expect(confirmInput).toBeFocused();
  });

  test('should handle empty data state', async ({ page }) => {
    // Mock empty data by intercepting the data loading
    await page.route('**/data**', route => {
      route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify([])
      });
    });
    
    // Reload page
    await page.reload();
    
    // Should show empty state
    await expect(page.getByText(/No Data to Export/i)).toBeVisible();
    await expect(page.getByText(/No Data to Delete/i)).toBeVisible();
    
    // Buttons should be disabled
    const exportButton = page.getByRole('button', { name: /No Data to Export/i });
    const deleteButton = page.getByRole('button', { name: /No Data to Delete/i });
    
    await expect(exportButton).toBeDisabled();
    await expect(deleteButton).toBeDisabled();
  });

  test('should handle loading state', async ({ page }) => {
    // Mock slow loading by intercepting requests
    await page.route('**/data**', route => {
      // Delay response
      setTimeout(() => {
        route.fulfill({
          status: 200,
          contentType: 'application/json',
          body: JSON.stringify([])
        });
      }, 100);
    });
    
    // Navigate to data control page
    await page.goto('/data');
    
    // Should show loading state
    await expect(page.getByText(/Loading your data/i)).toBeVisible();
    
    // Should have loading spinner
    const spinner = page.locator('.animate-spin');
    await expect(spinner).toBeVisible();
  });

  test('should handle error state', async ({ page }) => {
    // Mock error response
    await page.route('**/data**', route => {
      route.fulfill({
        status: 500,
        contentType: 'application/json',
        body: JSON.stringify({ error: 'Internal Server Error' })
      });
    });
    
    // Navigate to data control page
    await page.goto('/data');
    
    // Should show error state
    await expect(page.getByText(/Error/i)).toBeVisible();
    await expect(page.getByText(/Failed to load session data/i)).toBeVisible();
  });

  test('should maintain focus management', async ({ page }) => {
    // Wait for page to load
    await expect(page.getByRole('heading', { name: /Data Control/i })).toBeVisible();
    
    // Test focus order
    const focusableElements = [
      page.getByRole('link', { name: /Skip to main content/i }),
      page.getByRole('button', { name: /Export all practice data as JSON file/i }),
      page.getByRole('button', { name: /Delete all practice data permanently/i })
    ];
    
    // Tab through elements
    for (const element of focusableElements) {
      await page.keyboard.press('Tab');
      await expect(element).toBeFocused();
    }
  });

  test('should work with screen reader', async ({ page }) => {
    // Wait for page to load
    await expect(page.getByRole('heading', { name: /Data Control/i })).toBeVisible();
    
    // Check for proper ARIA labels
    const exportButton = page.getByRole('button', { name: /Export all practice data as JSON file/i });
    const deleteButton = page.getByRole('button', { name: /Delete all practice data permanently/i });
    
    await expect(exportButton).toBeVisible();
    await expect(deleteButton).toBeVisible();
    
    // Check for proper status announcements
    const statusRegion = page.locator('[role="status"]');
    await expect(statusRegion).toHaveCount(1);
    
    // Check for proper form labeling
    const formControls = page.locator('input, button');
    const count = await formControls.count();
    for (let i = 0; i < count; i++) {
      const control = formControls.nth(i);
      const hasLabel = await control.getAttribute('aria-label') || 
                      await control.getAttribute('aria-labelledby') ||
                      await page.locator(`label[for="${await control.getAttribute('id')}"]`).count() > 0;
      expect(hasLabel).toBeTruthy();
    }
  });

  test('should validate export file structure', async ({ page }) => {
    // Wait for page to load
    await expect(page.getByRole('heading', { name: /Data Control/i })).toBeVisible();
    
    // Set up download handling
    const downloadPromise = page.waitForEvent('download');
    
    // Click export button
    await page.getByRole('button', { name: /Export as JSON/i }).click();
    
    // Wait for download
    const download = await downloadPromise;
    const path = await download.path();
    
    // Read and validate JSON content
    const fs = require('fs');
    const content = fs.readFileSync(path, 'utf8');
    const jsonData = JSON.parse(content);
    
    // Validate required fields
    expect(jsonData.schemaVersion).toBe(1);
    expect(jsonData.build).toMatch(/^C2-data-control-v\d+$/);
    expect(jsonData.appVersion).toMatch(/^\d+\.\d+\.\d+$/);
    
    // Validate sessions array
    expect(Array.isArray(jsonData.sessions)).toBe(true);
    expect(jsonData.sessions.length).toBeGreaterThan(0);
    
    // Validate session structure
    const session = jsonData.sessions[0];
    expect(session).toHaveProperty('id');
    expect(session).toHaveProperty('ts');
    expect(session).toHaveProperty('schemaVersion');
    
    // Ensure no audio data is included
    expect(session).not.toHaveProperty('audioBlob');
    expect(session).not.toHaveProperty('audioData');
    expect(session).not.toHaveProperty('recording');
    
    // Validate summary
    expect(jsonData.summary.totalSessions).toBe(jsonData.sessions.length);
    expect(jsonData.summary.dateRange).toHaveProperty('start');
    expect(jsonData.summary.dateRange).toHaveProperty('end');
    expect(jsonData.summary.metrics).toHaveProperty('averageInBandPct');
    expect(jsonData.summary.metrics).toHaveProperty('averageExpressiveness');
    expect(jsonData.summary.metrics).toHaveProperty('averageComfort');
    
    // Clean up
    fs.unlinkSync(path);
  });
});
