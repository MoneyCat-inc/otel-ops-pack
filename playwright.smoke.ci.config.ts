import { defineConfig, devices } from '@playwright/test';

const baseURL = process.env['BASE_URL'] ?? 'http://127.0.0.1:3000';

// Minimal preferences for CI - focus on stability
const firefoxPreferences = {
  'media.navigator.streams.fake': true,
  'media.navigator.permission.disabled': true,
  'media.autoplay.default': 0,
  'dom.webnotifications.enabled': false,
  'browser.cache.disk.enable': false,
  'browser.cache.memory.enable': false,
  'network.http.use-cache': false,
};

const chromePreferences = {
  'autoplay-policy': 'no-user-gesture-required',
  'disable-web-security': false,
  'disable-background-timer-throttling': true,
  'disable-backgrounding-occluded-windows': true,
  'disable-renderer-backgrounding': true,
};

export default defineConfig({
  testDir: 'tests/smoke',
  retries: process.env['CI'] ? 2 : 0,
  workers: process.env['CI'] ? 2 : 1,
  timeout: 30_000,
  reporter: process.env['CI'] ? [['github'], ['html']] : [['list']],
  use: {
    baseURL,
    headless: true,
    trace: 'retain-on-failure',
    video: 'retain-on-failure',
    screenshot: 'only-on-failure',
  },
  webServer: {
    command: 'npm run preview:dev',
    url: baseURL,
    reuseExistingServer: !process.env['CI'],
    timeout: 60_000,
    stdout: 'pipe',
    stderr: 'pipe',
  },
  projects: [
    // Core browsers for CI
    {
      name: 'firefox-ci',
      use: {
        ...devices['Desktop Firefox'],
        launchOptions: {
          firefoxUserPrefs: {
            ...firefoxPreferences,
          },
        },
      },
    },
    {
      name: 'chrome-ci',
      use: {
        ...devices['Desktop Chrome'],
        launchOptions: {
          args: Object.entries(chromePreferences).map(([key, value]) => `--${key}=${value}`),
        },
      },
    },
  ],
});
