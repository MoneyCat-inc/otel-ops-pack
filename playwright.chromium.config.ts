import { defineConfig, devices } from '@playwright/test';

/**
 * Chromium-specific Playwright configuration for MEMX testing
 * Focuses on debugging cross-origin isolation and SharedArrayBuffer issues
 */
export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env['CI'],
  retries: process.env['CI'] ? 2 : 0,
  workers: process.env['CI'] ? 1 : 4,
  reporter: [
    ['html', { outputFolder: 'playwright-report-chromium' }],
    ['json', { outputFile: 'test-results-chromium.json' }],
    ['junit', { outputFile: 'test-results-chromium.xml' }],
  ],
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { 
        ...devices['Desktop Chrome'],
        // Additional Chromium-specific settings
        launchOptions: {
          args: [
            '--disable-web-security',
            '--disable-features=VizDisplayCompositor',
            '--enable-experimental-web-platform-features',
            '--enable-shared-array-buffer',
            '--cross-origin-isolated',
            '--disable-site-isolation-trials',
            '--disable-background-timer-throttling',
            '--disable-backgrounding-occluded-windows',
            '--disable-renderer-backgrounding',
            '--disable-features=TranslateUI',
            '--disable-ipc-flooding-protection',
            '--no-sandbox',
            '--disable-setuid-sandbox',
          ],
        },
        // Enable console logging for debugging
        contextOptions: {
          ignoreHTTPSErrors: true,
        },
      },
    },
    {
      name: 'chromium-debug',
      use: { 
        ...devices['Desktop Chrome'],
        headless: false, // Run in headed mode for debugging
        launchOptions: {
          args: [
            '--disable-web-security',
            '--disable-features=VizDisplayCompositor',
            '--enable-experimental-web-platform-features',
            '--enable-shared-array-buffer',
            '--cross-origin-isolated',
            '--disable-site-isolation-trials',
            '--disable-background-timer-throttling',
            '--disable-backgrounding-occluded-windows',
            '--disable-renderer-backgrounding',
            '--disable-features=TranslateUI',
            '--disable-ipc-flooding-protection',
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--remote-debugging-port=9222',
            '--enable-logging',
            '--v=1',
          ],
        },
        contextOptions: {
          ignoreHTTPSErrors: true,
        },
      },
    },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env['CI'],
    timeout: 120 * 1000,
  },
});
