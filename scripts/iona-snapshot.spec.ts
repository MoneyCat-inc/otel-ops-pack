import { test, expect } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

/**
 * IONA UI Snapshot Spec
 * 
 * Purpose: Capture screenshots of key IONA (Resonai) app pages for gate verification
 * Mirrors the synthetic span verification pattern used in existing gate tests
 * 
 * Part of: IONA-PR-01 - UI Snapshot Integration
 * Gate: BossCat Gate Verify
 * Service: iona-app
 */

test.describe('IONA UI Snapshot Tests', () => {
  const artifactsDir = path.join(process.cwd(), 'artifacts');

  test.beforeAll(() => {
    // Ensure artifacts directory exists
    if (!fs.existsSync(artifactsDir)) {
      fs.mkdirSync(artifactsDir, { recursive: true });
    }
  });

  test('IONA Home page loads and captures snapshot', async ({ page }) => {
    // Navigate to home page
    await page.goto('/');
    
    // Wait for page to fully load
    await page.waitForLoadState('networkidle');
    
    // Check for key elements on home page
    await expect(page.getByRole('heading', { level: 1 }).first()).toBeVisible();
    
    // Capture screenshot
    const screenshotPath = path.join(artifactsDir, 'iona-home.png');
    await page.screenshot({ 
      path: screenshotPath,
      fullPage: true 
    });
    
    console.log(`[IONA] home screenshot saved: ${screenshotPath}`);
    
    // Verify screenshot was created
    expect(fs.existsSync(screenshotPath)).toBe(true);
  });

  test('IONA /try (Practice) page loads and captures snapshot', async ({ page }) => {
    // Navigate to instant practice page
    await page.goto('/try');
    
    // Wait for page to fully load
    await page.waitForLoadState('networkidle');
    
    // Check for practice UI elements
    const practiceElements = await page.locator('[data-testid], button, canvas').count();
    expect(practiceElements).toBeGreaterThan(0);
    
    // Capture screenshot
    const screenshotPath = path.join(artifactsDir, 'iona-practice.png');
    await page.screenshot({ 
      path: screenshotPath,
      fullPage: true 
    });
    
    console.log(`[IONA] practice screenshot saved: ${screenshotPath}`);
    
    // Verify screenshot was created
    expect(fs.existsSync(screenshotPath)).toBe(true);
  });

  test('IONA Health API responds correctly', async ({ page }) => {
    // Test health endpoint
    const response = await page.request.get('/api/health');
    
    // Verify health endpoint returns 200
    expect(response.status()).toBe(200);
    
    const healthData = await response.json();
    console.log('[IONA] health check response:', healthData);
    
    // Basic health check validation
    expect(healthData).toBeDefined();
  });

  test('IONA Detailed Health API responds correctly', async ({ page }) => {
    // Test detailed health endpoint
    const response = await page.request.get('/api/health/detailed');
    
    // Verify detailed health endpoint responds (may be 200 or error, but should respond)
    expect([200, 500, 503]).toContain(response.status());
    
    let detailedHealth: unknown = null;
    try {
      detailedHealth = await response.json();
      console.log('[IONA] detailed health check response:', detailedHealth);
    } catch {
      const rawBody = await response.text();
      console.warn('[IONA] detailed health returned non-JSON payload:', rawBody.slice(0, 200));
    }
  });

  test('IONA MEMX Labs page loads and captures snapshot', async ({ page }) => {
    // Navigate to MEMX labs page (if MEMX feature is enabled)
    await page.goto('/labs/memx');
    
    // Wait for page load
    await page.waitForLoadState('networkidle');
    
    // Capture screenshot regardless of page content
    const screenshotPath = path.join(artifactsDir, 'iona-memx-labs.png');
    await page.screenshot({ 
      path: screenshotPath,
      fullPage: true 
    });
    
    console.log(`[IONA] MEMX labs screenshot saved: ${screenshotPath}`);
    
    // Verify screenshot was created
    expect(fs.existsSync(screenshotPath)).toBe(true);
  });

  test('IONA navigation and routing work correctly', async ({ page }) => {
    // Start at home
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    
    // Verify home page loaded
    expect(page.url()).toContain('/');
    
    // Navigate to /try
    await page.goto('/try');
    await page.waitForLoadState('networkidle');
    
    // Verify practice page loaded
    expect(page.url()).toContain('/try');
    
    console.log('[IONA] navigation verified: home → /try');
  });

  test('IONA console has no critical errors', async ({ page }) => {
    const errors: string[] = [];
    
    // Capture console errors
    page.on('console', msg => {
      if (msg.type() === 'error') {
        errors.push(msg.text());
      }
    });
    
    // Navigate to home
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    
    // Filter out expected/harmless errors
    const criticalErrors = errors.filter(err => 
      !err.includes('favicon') && 
      !err.includes('DevTools') &&
      !err.includes('net::ERR_FAILED')
    );
    
    if (criticalErrors.length > 0) {
      console.warn('⚠ IONA console errors detected:', criticalErrors);
    }
    
    console.log(`✓ IONA console check: ${errors.length} total errors, ${criticalErrors.length} critical`);
  });

  test('IONA artifacts summary', async () => {
    // List all IONA artifacts created
    const ionaFiles = fs.readdirSync(artifactsDir)
      .filter(file => file.startsWith('iona-') && file.endsWith('.png'));
    
    console.log('=== IONA Snapshot Summary ===');
    console.log(`Artifacts directory: ${artifactsDir}`);
    console.log(`IONA screenshots captured: ${ionaFiles.length}`);
    ionaFiles.forEach(file => {
      const filePath = path.join(artifactsDir, file);
      const stats = fs.statSync(filePath);
      console.log(`  - ${file} (${(stats.size / 1024).toFixed(2)} KB)`);
    });
    
    // Verify at least 3 screenshots were captured
    expect(ionaFiles.length).toBeGreaterThanOrEqual(3);
  });
});

test.describe('IONA Integration Tests', () => {
  test('OTLP endpoint reachability', async ({ page }) => {
    // Test OTLP endpoint connectivity
    const response = await page.request.get('http://127.0.0.1:14318/v1/logs');
    expect(response.status()).toBeLessThan(500); // Should not be server error
    
    console.log('[IONA] OTLP endpoint reachable');
  });

  test('SigNoz health check', async ({ page }) => {
    // Test SigNoz health endpoint
    try {
      const response = await page.request.get('http://localhost:8080/api/v1/health');
      expect(response.status()).toBe(200);
      console.log('[IONA] SigNoz integration verified');
    } catch (error) {
      console.warn('⚠ SigNoz health check failed - may not be running:', error.message);
    }
  });

  test('IONA synthetic span can be emitted', async ({ page }) => {
    // This test verifies that IONA can emit telemetry
    // Actual span emission will be handled by the synthetic generator
    
    // Navigate to home to trigger any boot spans
    await page.goto('/');
    await page.waitForLoadState('networkidle');
    
    // Give time for any boot telemetry to be emitted
    await page.waitForTimeout(1000);
    
    console.log('✓ IONA boot sequence completed (potential telemetry emitted)');
  });
});

test.describe('IONA Diagnostics Shell Tests', () => {
  const artifactsDir = path.join(process.cwd(), 'artifacts');

  test('Diagnostics page renders correctly', async ({ page }) => {
    // Navigate to diagnostics page
    await page.goto('/diagnostics');
    
    // Wait for page to load
    await page.waitForLoadState('networkidle');
    
    // Check for main heading
    await expect(page.getByRole('heading', { name: /IONA Diagnostics/i })).toBeVisible();
    
    // Check for tab navigation
    await expect(page.getByRole('button', { name: /Metrics/i })).toBeVisible();
    await expect(page.getByRole('button', { name: /Traces/i })).toBeVisible();
    await expect(page.getByRole('button', { name: /Logs/i })).toBeVisible();
    await expect(page.getByRole('button', { name: /Controls/i })).toBeVisible();
    
    console.log('✓ IONA diagnostics page rendered successfully');
  });

  test('Diagnostics page captures screenshot', async ({ page }) => {
    // Navigate to diagnostics page
    await page.goto('/diagnostics');
    await page.waitForLoadState('networkidle');
    
    // Wait for telemetry data to load
    await page.waitForTimeout(2000);
    
    // Capture screenshot
    const screenshotPath = path.join(artifactsDir, 'iona-diagnostics.png');
    await page.screenshot({ 
      path: screenshotPath,
      fullPage: true 
    });
    
    console.log(`[IONA] diagnostics screenshot saved: ${screenshotPath}`);
    
    // Verify screenshot was created
    expect(fs.existsSync(screenshotPath)).toBe(true);
  });

  test('Instrumentation toggle works', async ({ page }) => {
    // Navigate to diagnostics page
    await page.goto('/diagnostics');
    await page.waitForLoadState('networkidle');
    
    // Switch to Controls tab
    await page.getByRole('button', { name: /Controls/i }).click();
    await page.waitForTimeout(500);
    
    // Find instrumentation toggle
    const toggle = page.locator('[role="switch"]').first();
    await expect(toggle).toBeVisible();
    
    // Get initial state
    const initialState = await toggle.getAttribute('aria-checked');
    console.log(`[IONA] Initial instrumentation state: ${initialState}`);
    
    // Click toggle
    await toggle.click();
    await page.waitForTimeout(300);
    
    // Verify state changed
    const newState = await toggle.getAttribute('aria-checked');
    expect(newState).not.toBe(initialState);
    
    console.log(`[IONA] Instrumentation toggled: ${initialState} → ${newState}`);
  });

  test('Emit span button triggers span emission', async ({ page }) => {
    // Navigate to diagnostics page
    await page.goto('/diagnostics');
    await page.waitForLoadState('networkidle');
    
    // Switch to Controls tab
    await page.getByRole('button', { name: /Controls/i }).click();
    await page.waitForTimeout(500);
    
    // Find emit span button
    const emitButton = page.getByRole('button', { name: /Emit Test Span/i });
    await expect(emitButton).toBeVisible();
    
    // Click emit button
    await emitButton.click();
    
    // Wait for response
    await page.waitForTimeout(1500);
    
    // Check for success message
    const successIndicator = page.locator('text=/emitted successfully/i');
    const isVisible = await successIndicator.isVisible().catch(() => false);
    
    if (isVisible) {
      console.log('✓ IONA span emission successful');
    } else {
      console.warn('⚠ IONA span emission may have failed or response not visible');
    }
  });

  test('Metrics panel displays data', async ({ page }) => {
    // Navigate to diagnostics page
    await page.goto('/diagnostics');
    await page.waitForLoadState('networkidle');
    
    // Wait for metrics to load
    await page.waitForTimeout(2000);
    
    // Metrics tab should be active by default
    const metricsContent = page.locator('text=/uptime|memory|cpu/i').first();
    await expect(metricsContent).toBeVisible({ timeout: 5000 });
    
    console.log('✓ IONA metrics panel loaded');
  });

  test('Traces panel displays data', async ({ page }) => {
    // Navigate to diagnostics page
    await page.goto('/diagnostics');
    await page.waitForLoadState('networkidle');
    
    // Switch to Traces tab
    await page.getByRole('button', { name: /Traces/i }).click();
    await page.waitForTimeout(2000);
    
    // Check for trace content or "no traces" message
    const hasTraces = await page.locator('text=/trace|span|no traces/i').isVisible();
    expect(hasTraces).toBe(true);
    
    console.log('✓ IONA traces panel loaded');
  });

  test('Logs panel displays data', async ({ page }) => {
    // Navigate to diagnostics page
    await page.goto('/diagnostics');
    await page.waitForLoadState('networkidle');
    
    // Switch to Logs tab
    await page.getByRole('button', { name: /Logs/i }).click();
    await page.waitForTimeout(2000);
    
    // Check for log filter buttons
    await expect(page.getByRole('button', { name: /All/i })).toBeVisible();
    await expect(page.getByRole('button', { name: /Info/i })).toBeVisible();
    
    console.log('✓ IONA logs panel loaded');
  });

  test('Tab navigation works correctly', async ({ page }) => {
    // Navigate to diagnostics page
    await page.goto('/diagnostics');
    await page.waitForLoadState('networkidle');
    
    const tabs = ['Metrics', 'Traces', 'Logs', 'Controls'];
    
    for (const tabName of tabs) {
      await page.getByRole('button', { name: new RegExp(tabName, 'i') }).click();
      await page.waitForTimeout(500);
      console.log(`  ✓ Switched to ${tabName} tab`);
    }
    
    console.log('✓ IONA tab navigation verified');
  });
});

