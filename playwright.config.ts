import { defineConfig, devices } from '@playwright/test';

/**
 * Playwright configuration for IONA gate verification
 * Used by BRAV/SCPT/iona-snapshot.spec.ts
 */
export default defineConfig({
  testDir: './BRAV/SCPT',
  testMatch: '**/iona-snapshot.spec.ts',
  fullyParallel: true,
  forbidOnly: !!process.env['CI'],
  retries: process.env['CI'] ? 2 : 0,
  workers: process.env['CI'] ? 1 : 4,
  reporter: [
    ['html', { outputFolder: 'playwright-report' }],
    ['json', { outputFile: 'test-results/iona-results.json' }],
    ['list'],
  ],
  use: {
    baseURL: process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
  // webServer removed 2026-08-29 (audit P2): 'pnpm dev' no longer exists — point
  // PLAYWRIGHT_BASE_URL at a running server instead.
});

