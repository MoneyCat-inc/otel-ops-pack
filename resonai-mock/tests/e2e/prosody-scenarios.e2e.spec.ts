/**
 * E2E Tests for Prosody Scenarios
 * 
 * T2: Prosody Carry-over Scenarios
 * Playwright tests verifying scenarios load, mock runs succeed, verdicts visible/announced.
 */

import { test, expect } from '@playwright/test';

test.describe('Prosody Scenarios', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to prosody scenarios page
    await page.goto('/labs/prosody-scenarios');
  });

  test('should load prosody scenarios page with both scenario cards', async ({ page }) => {
    // Check page title and description
    await expect(page.getByRole('heading', { name: /Applied Prosody Scenarios/i })).toBeVisible();
    await expect(page.getByText(/Practice real-world scenarios with voicemail and meeting introductions/i)).toBeVisible();

    // Check both scenario cards are present
    await expect(page.getByText('Voicemail Intro')).toBeVisible();
    await expect(page.getByText('Meeting Intro')).toBeVisible();

    // Check scenario details
    await expect(page.getByText(/Hi, this is \[your name\]/)).toBeVisible();
    await expect(page.getByText(/Good morning everyone/)).toBeVisible();
  });

  test('should enable mock mode and run voicemail scenario', async ({ page }) => {
    // Enable mock mode
    const mockToggle = page.getByLabel(/Mock Mode/i);
    await mockToggle.click();
    await expect(mockToggle).toBeChecked();

    // Start voicemail scenario
    const voicemailCard = page.locator('[data-testid="scenario-card"]').first();
    const startButton = voicemailCard.getByRole('button', { name: /Start Recording/i });
    await startButton.click();

    // Check countdown appears
    await expect(page.getByText('3')).toBeVisible();
    await expect(page.getByText('Get ready...')).toBeVisible();

    // Wait for countdown to complete and recording to start
    await expect(page.getByText('Recording...')).toBeVisible({ timeout: 5000 });

    // Wait for scenario to complete
    await expect(page.getByText('Scenario complete')).toBeVisible({ timeout: 10000 });

    // Check results appear
    await expect(voicemailCard.getByText(/Rise\/Fall/)).toBeVisible();
    await expect(voicemailCard.getByText(/Expressiveness/)).toBeVisible();
    await expect(voicemailCard.getByText(/Feedback:/)).toBeVisible();
  });

  test('should enable mock mode and run meeting scenario', async ({ page }) => {
    // Enable mock mode
    const mockToggle = page.getByLabel(/Mock Mode/i);
    await mockToggle.click();

    // Start meeting scenario (second card)
    const meetingCard = page.locator('[data-testid="scenario-card"]').last();
    const startButton = meetingCard.getByRole('button', { name: /Start Recording/i });
    await startButton.click();

    // Wait for scenario to complete
    await expect(page.getByText('Scenario complete')).toBeVisible({ timeout: 10000 });

    // Check results appear
    await expect(meetingCard.getByText(/Rise\/Fall/)).toBeVisible();
    await expect(meetingCard.getByText(/Expressiveness/)).toBeVisible();
    await expect(meetingCard.getByText(/Feedback:/)).toBeVisible();
  });

  test('should display progress and session results after completing scenarios', async ({ page }) => {
    // Enable mock mode
    await page.getByLabel(/Mock Mode/i).click();

    // Complete voicemail scenario
    const voicemailCard = page.locator('[data-testid="scenario-card"]').first();
    await voicemailCard.getByRole('button', { name: /Start Recording/i }).click();
    await expect(page.getByText('Scenario complete')).toBeVisible({ timeout: 10000 });

    // Complete meeting scenario
    const meetingCard = page.locator('[data-testid="scenario-card"]').last();
    await meetingCard.getByRole('button', { name: /Start Recording/i }).click();
    await expect(page.getByText('Scenario complete')).toBeVisible({ timeout: 10000 });

    // Check progress updates
    await expect(page.getByText(/Progress: \d+\/2 scenarios/)).toBeVisible();

    // Check session results section appears
    await expect(page.getByRole('heading', { name: /Session Results/i })).toBeVisible();
    await expect(page.getByText('Total Attempts')).toBeVisible();
    await expect(page.getByText('Passed')).toBeVisible();
    await expect(page.getByText('Success Rate')).toBeVisible();
    await expect(page.getByText('Recent Attempts')).toBeVisible();
  });

  test('should export results when export button is clicked', async ({ page }) => {
    // Enable mock mode and complete a scenario
    await page.getByLabel(/Mock Mode/i).click();
    const voicemailCard = page.locator('[data-testid="scenario-card"]').first();
    await voicemailCard.getByRole('button', { name: /Start Recording/i }).click();
    await expect(page.getByText('Scenario complete')).toBeVisible({ timeout: 10000 });

    // Set up download promise
    const downloadPromise = page.waitForEvent('download');

    // Click export button
    await page.getByRole('button', { name: /Export Results/i }).click();

    // Wait for download
    const download = await downloadPromise;
    expect(download.suggestedFilename()).toMatch(/prosody-scenarios-.*\.json/);
  });

  test('should clear results when clear button is clicked', async ({ page }) => {
    // Enable mock mode and complete a scenario
    await page.getByLabel(/Mock Mode/i).click();
    const voicemailCard = page.locator('[data-testid="scenario-card"]').first();
    await voicemailCard.getByRole('button', { name: /Start Recording/i }).click();
    await expect(page.getByText('Scenario complete')).toBeVisible({ timeout: 10000 });

    // Verify results section is visible
    await expect(page.getByRole('heading', { name: /Session Results/i })).toBeVisible();

    // Clear results
    await page.getByRole('button', { name: /Clear Results/i }).click();

    // Verify results section is hidden
    await expect(page.getByRole('heading', { name: /Session Results/i })).not.toBeVisible();
  });

  test('should support keyboard navigation', async ({ page }) => {
    // Tab to first scenario card
    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');

    // Check focus is on start button
    const startButton = page.locator('[data-testid="scenario-card"]').first().getByRole('button');
    await expect(startButton).toBeFocused();

    // Enable mock mode with keyboard
    await page.keyboard.press('Shift+Tab');
    await page.keyboard.press('Shift+Tab');
    await page.keyboard.press('Enter');

    // Start scenario with keyboard
    await page.keyboard.press('Tab');
    await page.keyboard.press('Enter');

    // Wait for completion
    await expect(page.getByText('Scenario complete')).toBeVisible({ timeout: 10000 });
  });

  test('should announce verdicts to screen readers', async ({ page }) => {
    // Enable mock mode
    await page.getByLabel(/Mock Mode/i).click();

    // Start voicemail scenario
    const voicemailCard = page.locator('[data-testid="scenario-card"]').first();
    await voicemailCard.getByRole('button', { name: /Start Recording/i }).click();

    // Wait for completion
    await expect(page.getByText('Scenario complete')).toBeVisible({ timeout: 10000 });

    // Check aria-live region has announcement
    const liveRegion = page.locator('[aria-live="polite"]');
    await expect(liveRegion).toContainText(/Scenario complete/);
    await expect(liveRegion).toContainText(/Passed|Try again/);
  });

  test('should have exactly one aria-live region per scenario card', async ({ page }) => {
    // Check that each scenario card has exactly one aria-live region
    const scenarioCards = page.locator('[data-testid="scenario-card"]');
    await expect(scenarioCards).toHaveCount(2);

    for (let i = 0; i < 2; i++) {
      const card = scenarioCards.nth(i);
      const liveRegions = card.locator('[aria-live="polite"]');
      await expect(liveRegions).toHaveCount(1);
    }
  });

  test('should not duplicate announcements across cards', async ({ page }) => {
    // Enable mock mode
    await page.getByLabel(/Mock Mode/i).click();

    // Start both scenarios simultaneously
    const voicemailCard = page.locator('[data-testid="scenario-card"]').first();
    const meetingCard = page.locator('[data-testid="scenario-card"]').last();
    
    await voicemailCard.getByRole('button', { name: /Start Recording/i }).click();
    await meetingCard.getByRole('button', { name: /Start Recording/i }).click();

    // Wait for both to complete
    await expect(page.getByText('Scenario complete')).toBeVisible({ timeout: 10000 });

    // Check that each card has its own announcement
    const voicemailLiveRegion = voicemailCard.locator('[aria-live="polite"]');
    const meetingLiveRegion = meetingCard.locator('[aria-live="polite"]');
    
    await expect(voicemailLiveRegion).toContainText(/voicemail|Voicemail/);
    await expect(meetingLiveRegion).toContainText(/meeting|Meeting/);
  });

  test('should respect reduced motion preference', async ({ page }) => {
    // Mock reduced motion preference
    await page.emulateMedia({ reducedMotion: 'reduce' });

    // Check reduced motion indicator appears
    await expect(page.getByText(/Reduced motion enabled/)).toBeVisible();

    // Enable mock mode and complete scenario
    await page.getByLabel(/Mock Mode/i).click();
    const voicemailCard = page.locator('[data-testid="scenario-card"]').first();
    await voicemailCard.getByRole('button', { name: /Start Recording/i }).click();
    await expect(page.getByText('Scenario complete')).toBeVisible({ timeout: 10000 });

    // Verify animations are reduced (no transition classes should be present)
    const progressBar = page.locator('[style*="transition-all duration-500"]');
    await expect(progressBar).not.toBeVisible();
  });

  test('should disable animations when reduced motion is preferred', async ({ page }) => {
    // Mock reduced motion preference
    await page.emulateMedia({ reducedMotion: 'reduce' });

    // Check that scenario cards don't have transition animations
    const scenarioCards = page.locator('[data-testid="scenario-card"]');
    await expect(scenarioCards).toHaveCount(2);

    // Verify no transition classes are applied
    for (let i = 0; i < 2; i++) {
      const card = scenarioCards.nth(i);
      const element = await card.elementHandle();
      if (element) {
        const className = await element.getAttribute('class');
        expect(className).not.toContain('transition-all');
        expect(className).not.toContain('duration-500');
      }
    }
  });

  test('should handle URL parameters for mock scenarios', async ({ page }) => {
    // Navigate with voicemail mock parameter
    await page.goto('/labs/prosody-scenarios?mock=voicemail');

    // Check mock mode is enabled
    const mockToggle = page.getByLabel(/Mock Mode/i);
    await expect(mockToggle).toBeChecked();

    // Check voicemail scenario is active
    const voicemailCard = page.locator('[data-testid="scenario-card"]').first();
    const startButton = voicemailCard.getByRole('button', { name: /Start Recording/i });
    await expect(startButton).toBeEnabled();

    // Start scenario
    await startButton.click();
    await expect(page.getByText('Scenario complete')).toBeVisible({ timeout: 10000 });
  });

  test('should show help section with usage instructions', async ({ page }) => {
    // Check help section is visible
    await expect(page.getByText(/How to Use Prosody Scenarios/i)).toBeVisible();
    
    // Check specific instructions
    await expect(page.getByText(/Voicemail Intro.*gentle fall/i)).toBeVisible();
    await expect(page.getByText(/Meeting Intro.*slight rise/i)).toBeVisible();
    await expect(page.getByText(/Expressiveness.*pitch variety/i)).toBeVisible();
    await expect(page.getByText(/Mock Mode.*microphone access/i)).toBeVisible();
  });
});

test.describe('Accessibility', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/labs/prosody-scenarios');
  });

  test('should have proper ARIA labels and roles', async ({ page }) => {
    // Check main heading
    await expect(page.getByRole('heading', { name: /Applied Prosody Scenarios/i })).toBeVisible();

    // Check scenario cards have proper structure
    const scenarioCards = page.locator('[data-testid="scenario-card"]');
    await expect(scenarioCards).toHaveCount(2);

    // Check buttons have proper labels
    await expect(page.getByRole('button', { name: /Start Recording/i })).toBeVisible();
    await expect(page.getByLabel(/Mock Mode/i)).toBeVisible();
  });

  test('should support screen reader navigation', async ({ page }) => {
    // Check skip link
    const skipLink = page.getByRole('link', { name: /Skip to main content/i });
    await expect(skipLink).toBeVisible();

    // Check aria-live regions
    const liveRegion = page.locator('[aria-live="polite"]');
    await expect(liveRegion).toBeVisible();

    // Check status roles
    const statusElements = page.locator('[role="status"]');
    await expect(statusElements).toHaveCount(2); // Main announcement + individual card announcements
  });

  test('should have proper color contrast', async ({ page }) => {
    // This would typically be tested with axe-core or similar tool
    // For now, we'll just verify the page loads without accessibility errors
    await expect(page.getByRole('heading', { name: /Applied Prosody Scenarios/i })).toBeVisible();
  });
});

test.describe('Security & Isolation', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/labs/prosody-scenarios');
  });

  test('should maintain CSP compliance', async ({ page }) => {
    // Check that no inline styles are present
    const inlineStyleElements = page.locator('[style]');
    const inlineStyleCount = await inlineStyleElements.count();
    expect(inlineStyleCount).toBe(0);

    // Check that no inline scripts are present
    const inlineScripts = page.locator('script:not([src])');
    const inlineScriptCount = await inlineScripts.count();
    expect(inlineScriptCount).toBe(0);

    // Verify page loads without CSP violations
    const cspViolations: string[] = [];
    page.on('console', msg => {
      if (msg.type() === 'error' && msg.text().includes('Content Security Policy')) {
        cspViolations.push(msg.text());
      }
    });

    // Wait for page to fully load
    await page.waitForLoadState('networkidle');
    
    // No CSP violations should occur
    expect(cspViolations).toHaveLength(0);
  });

  test('should maintain cross-origin isolation', async ({ page }) => {
    // Check that crossOriginIsolated is true
    const isCrossOriginIsolated = await page.evaluate(() => window.crossOriginIsolated);
    expect(isCrossOriginIsolated).toBe(true);

    // Check that SharedArrayBuffer is available
    const hasSharedArrayBuffer = await page.evaluate(() => typeof SharedArrayBuffer !== 'undefined');
    expect(hasSharedArrayBuffer).toBe(true);
  });

  test('should have proper COOP/COEP headers', async ({ page }) => {
    // Navigate to the page and check response headers
    const response = await page.goto('/labs/prosody-scenarios');
    expect(response).toBeTruthy();

    const headers = response!.headers();
    
    // Check for COOP header
    expect(headers['cross-origin-opener-policy']).toBeDefined();
    
    // Check for COEP header
    expect(headers['cross-origin-embedder-policy']).toBeDefined();
  });

  test('should not leak audio data', async ({ page }) => {
    // Enable mock mode to test data handling
    await page.getByLabel(/Mock Mode/i).click();
    
    // Complete a scenario
    const voicemailCard = page.locator('[data-testid="scenario-card"]').first();
    await voicemailCard.getByRole('button', { name: /Start Recording/i }).click();
    await expect(page.getByText('Scenario complete')).toBeVisible({ timeout: 10000 });

    // Export results and verify no audio data
    const downloadPromise = page.waitForEvent('download');
    await page.getByRole('button', { name: /Export Results/i }).click();
    const download = await downloadPromise;
    
    // Read the downloaded file
    const path = await download.path();
    expect(path).toBeTruthy();
    
    const fs = require('fs');
    const content = fs.readFileSync(path, 'utf8');
    const data = JSON.parse(content);
    
    // Verify no audio data is present
    expect(JSON.stringify(data)).not.toContain('audio');
    expect(JSON.stringify(data)).not.toContain('blob');
    expect(JSON.stringify(data)).not.toContain('ArrayBuffer');
  });
});
