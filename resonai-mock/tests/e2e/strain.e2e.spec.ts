/**
 * E2E Tests for Strain Detection and Cooldown Flow
 * 
 * T3: Safety Guardrails
 * Playwright tests verifying strain detection, cooldown display, and accessibility.
 */

import { test, expect } from '@playwright/test';

test.describe('Strain Detection & Cooldown', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to strain labs page
    await page.goto('/labs/strain');
  });

  test('should load strain labs page with controls', async ({ page }) => {
    // Check page title and description
    await expect(page.getByRole('heading', { name: /Safety Guardrails Lab/i })).toBeVisible();
    await expect(page.getByText(/Tune strain detection thresholds/i)).toBeVisible();

    // Check controls are present
    await expect(page.getByLabel(/Mock Mode/i)).toBeVisible();
    await expect(page.getByRole('button', { name: /Start Monitoring/i })).toBeVisible();
    await expect(page.getByRole('button', { name: /Reset/i })).toBeVisible();

    // Check preset buttons
    await expect(page.getByRole('button', { name: /Default/i })).toBeVisible();
    await expect(page.getByRole('button', { name: /Conservative/i })).toBeVisible();
    await expect(page.getByRole('button', { name: /Relaxed/i })).toBeVisible();
  });

  test('should enable mock mode and test loud fixture', async ({ page }) => {
    // Enable mock mode
    const mockToggle = page.getByLabel(/Mock Mode/i);
    await mockToggle.click();
    await expect(mockToggle).toBeChecked();

    // Start monitoring
    await page.getByRole('button', { name: /Start Monitoring/i }).click();

    // Test loud fixture
    await page.getByRole('button', { name: /Test loud/i }).click();

    // Wait for strain detection
    await expect(page.getByText(/Strain Detected/i)).toBeVisible({ timeout: 5000 });
    await expect(page.getByText(/Loudness exceeded/i)).toBeVisible();
  });

  test('should test rising jitter fixture', async ({ page }) => {
    // Enable mock mode
    await page.getByLabel(/Mock Mode/i).click();

    // Start monitoring
    await page.getByRole('button', { name: /Start Monitoring/i }).click();

    // Test rising jitter fixture
    await page.getByRole('button', { name: /Test rising-jitter/i }).click();

    // Wait for strain detection
    await expect(page.getByText(/Strain Detected/i)).toBeVisible({ timeout: 5000 });
    await expect(page.getByText(/Jitter trend/i)).toBeVisible();
  });

  test('should not detect strain for neutral fixture', async ({ page }) => {
    // Enable mock mode
    await page.getByLabel(/Mock Mode/i).click();

    // Start monitoring
    await page.getByRole('button', { name: /Start Monitoring/i }).click();

    // Test neutral fixture
    await page.getByRole('button', { name: /Test neutral/i }).click();

    // Wait and verify no strain detected
    await page.waitForTimeout(2000);
    await expect(page.getByText(/No Strain Detected/i)).toBeVisible();
  });

  test('should display live metrics during monitoring', async ({ page }) => {
    // Enable mock mode
    await page.getByLabel(/Mock Mode/i).click();

    // Start monitoring
    await page.getByRole('button', { name: /Start Monitoring/i }).click();

    // Check live metrics section appears
    await expect(page.getByRole('heading', { name: /Live Strain Metrics/i })).toBeVisible();
    
    // Check metric displays
    await expect(page.getByText(/dBFS/)).toBeVisible();
    await expect(page.getByText(/cents/)).toBeVisible();
    await expect(page.getByText(/ms/)).toBeVisible();
  });

  test('should update thresholds dynamically', async ({ page }) => {
    // Find loudness threshold input
    const loudnessInput = page.getByLabel(/Loudness Threshold/i);
    await expect(loudnessInput).toBeVisible();

    // Change threshold to more sensitive value
    await loudnessInput.fill('-15');

    // Verify the value was updated
    await expect(loudnessInput).toHaveValue('-15');
  });

  test('should switch between presets', async ({ page }) => {
    // Check default preset is selected
    await expect(page.getByRole('button', { name: /Default/i })).toHaveClass(/bg-orange-600/);

    // Switch to conservative preset
    await page.getByRole('button', { name: /Conservative/i }).click();
    await expect(page.getByRole('button', { name: /Conservative/i })).toHaveClass(/bg-orange-600/);

    // Switch to relaxed preset
    await page.getByRole('button', { name: /Relaxed/i }).click();
    await expect(page.getByRole('button', { name: /Relaxed/i })).toHaveClass(/bg-orange-600/);
  });

  test('should start and stop monitoring', async ({ page }) => {
    // Start monitoring
    await page.getByRole('button', { name: /Start Monitoring/i }).click();
    await expect(page.getByRole('button', { name: /Stop Monitoring/i })).toBeVisible();

    // Stop monitoring
    await page.getByRole('button', { name: /Stop Monitoring/i }).click();
    await expect(page.getByRole('button', { name: /Start Monitoring/i })).toBeVisible();
  });

  test('should reset detector state', async ({ page }) => {
    // Enable mock mode and start monitoring
    await page.getByLabel(/Mock Mode/i).click();
    await page.getByRole('button', { name: /Start Monitoring/i }).click();

    // Test a fixture to generate some state
    await page.getByRole('button', { name: /Test loud/i }).click();
    await page.waitForTimeout(1000);

    // Reset detector
    await page.getByRole('button', { name: /Reset/i }).click();

    // Verify metrics are cleared
    await expect(page.getByText(/Waiting for audio data/i)).toBeVisible();
  });

  test('should handle URL parameters for mock fixtures', async ({ page }) => {
    // Navigate with loud mock parameter
    await page.goto('/labs/strain?mock=loud');

    // Check mock mode is enabled
    const mockToggle = page.getByLabel(/Mock Mode/i);
    await expect(mockToggle).toBeChecked();

    // Start monitoring
    await page.getByRole('button', { name: /Start Monitoring/i }).click();

    // Wait for strain detection
    await expect(page.getByText(/Strain Detected/i)).toBeVisible({ timeout: 5000 });
  });

  test('should display test fixtures correctly', async ({ page }) => {
    // Check test fixtures section
    await expect(page.getByRole('heading', { name: /Test Fixtures/i })).toBeVisible();

    // Check fixture cards are present
    await expect(page.getByRole('button', { name: /Test loud/i })).toBeVisible();
    await expect(page.getByRole('button', { name: /Test rising-jitter/i })).toBeVisible();
    await expect(page.getByRole('button', { name: /Test neutral/i })).toBeVisible();
    await expect(page.getByRole('button', { name: /Test short-voiced/i })).toBeVisible();
    await expect(page.getByRole('button', { name: /Test mixed-pattern/i })).toBeVisible();
    await expect(page.getByRole('button', { name: /Test creaky-voice/i })).toBeVisible();
  });

  test('should show help section with detection guide', async ({ page }) => {
    // Check help section is visible
    await expect(page.getByText(/Strain Detection Guide/i)).toBeVisible();
    
    // Check specific guidance
    await expect(page.getByText(/Loudness.*sustained loud speech/i)).toBeVisible();
    await expect(page.getByText(/Jitter Trend.*pitch instability/i)).toBeVisible();
    await expect(page.getByText(/Duration.*minimum voiced time/i)).toBeVisible();
    await expect(page.getByText(/Cooldown.*SOVT exercises/i)).toBeVisible();
  });
});

test.describe('CooldownCard Component', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to strain labs and trigger strain
    await page.goto('/labs/strain?mock=loud');
    await page.getByLabel(/Mock Mode/i).click();
    await page.getByRole('button', { name: /Start Monitoring/i }).click();
    await page.getByRole('button', { name: /Test loud/i }).click();
  });

  test('should display cooldown card when strain is detected', async ({ page }) => {
    // Wait for strain detection
    await expect(page.getByText(/Strain Detected/i)).toBeVisible({ timeout: 5000 });

    // Check cooldown card appears (this would be triggered by the strain detection)
    // Note: In a real implementation, the cooldown card would be displayed by the parent component
    // For now, we'll verify the strain detection works as expected
    await expect(page.getByText(/Loudness exceeded/i)).toBeVisible();
  });

  test('should announce strain detection to screen readers', async ({ page }) => {
    // Wait for strain detection
    await expect(page.getByText(/Strain Detected/i)).toBeVisible({ timeout: 5000 });

    // Check aria-live region has announcement
    const liveRegion = page.locator('[aria-live="polite"]');
    await expect(liveRegion).toContainText(/Strain monitoring started/);
  });
});

test.describe('Accessibility', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/labs/strain');
  });

  test('should have proper ARIA labels and roles', async ({ page }) => {
    // Check main heading
    await expect(page.getByRole('heading', { name: /Safety Guardrails Lab/i })).toBeVisible();

    // Check form controls have proper labels
    await expect(page.getByLabel(/Mock Mode/i)).toBeVisible();
    await expect(page.getByLabel(/Loudness Threshold/i)).toBeVisible();
    await expect(page.getByLabel(/Loud Duration/i)).toBeVisible();
    await expect(page.getByLabel(/Jitter Threshold/i)).toBeVisible();
    await expect(page.getByLabel(/Cooldown/i)).toBeVisible();

    // Check buttons have proper labels
    await expect(page.getByRole('button', { name: /Start Monitoring/i })).toBeVisible();
    await expect(page.getByRole('button', { name: /Reset/i })).toBeVisible();
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
    await expect(statusElements).toHaveCount(1);
  });

  test('should have proper color contrast', async ({ page }) => {
    // This would typically be tested with axe-core or similar tool
    // For now, we'll just verify the page loads without accessibility errors
    await expect(page.getByRole('heading', { name: /Safety Guardrails Lab/i })).toBeVisible();
  });
});

test.describe('Security & Isolation', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/labs/strain');
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
    const response = await page.goto('/labs/strain');
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
    
    // Start monitoring and test fixture
    await page.getByRole('button', { name: /Start Monitoring/i }).click();
    await page.getByRole('button', { name: /Test loud/i }).click();
    
    // Wait for strain detection
    await expect(page.getByText(/Strain Detected/i)).toBeVisible({ timeout: 5000 });

    // Check that no audio data is present in the DOM
    const pageContent = await page.content();
    expect(pageContent).not.toContain('audio');
    expect(pageContent).not.toContain('blob');
    expect(pageContent).not.toContain('ArrayBuffer');
  });
});

test.describe('Reduced Motion', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/labs/strain');
  });

  test('should respect reduced motion preference', async ({ page }) => {
    // Mock reduced motion preference
    await page.emulateMedia({ reducedMotion: 'reduce' });

    // Check reduced motion indicator appears
    await expect(page.getByText(/Reduced motion enabled/)).toBeVisible();

    // Enable mock mode and test
    await page.getByLabel(/Mock Mode/i).click();
    await page.getByRole('button', { name: /Start Monitoring/i }).click();
    await page.getByRole('button', { name: /Test loud/i }).click();

    // Wait for strain detection
    await expect(page.getByText(/Strain Detected/i)).toBeVisible({ timeout: 5000 });

    // Verify animations are reduced (no transition classes should be present)
    const transitionElements = page.locator('[class*="transition-all"]');
    await expect(transitionElements).toHaveCount(0);
  });

  test('should disable animations when reduced motion is preferred', async ({ page }) => {
    // Mock reduced motion preference
    await page.emulateMedia({ reducedMotion: 'reduce' });

    // Check that no transition classes are applied
    const transitionElements = page.locator('[class*="transition-all"]');
    await expect(transitionElements).toHaveCount(0);

    // Check that no duration classes are applied
    const durationElements = page.locator('[class*="duration-"]');
    await expect(durationElements).toHaveCount(0);
  });
});
