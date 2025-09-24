import { defineConfig, devices } from '@playwright/test';

const baseURL = process.env['BASE_URL'] ?? 'http://localhost:3003';

const baseUse = {
  baseURL,
  headless: true,
  trace: 'retain-on-failure' as const,
  video: 'off' as const,
  screenshot: 'only-on-failure' as const,
};

const firefoxPreferences = {
  'media.navigator.streams.fake': true,
  'media.navigator.permission.disabled': true,
  'media.navigator.audio.full_duplex': true,
  'media.autoplay.default': 0,
};

export default defineConfig({
  testDir: 'tests',
  testMatch: ['**/*.spec.ts'],
  retries: 2,
  timeout: 30_000,
  reporter: [['list']],
  use: baseUse,
  projects: [
    {
      name: 'chromium-nightly',
      use: {
        ...baseUse,
        ...devices['Desktop Chrome'],
        launchOptions: {
          args: [
            '--use-fake-device-for-media-stream',
            '--use-fake-ui-for-media-stream',
            '--no-sandbox',
          ],
        },
      },
    },
    {
      name: 'firefox-nightly',
      use: {
        ...baseUse,
        ...devices['Desktop Firefox'],
        launchOptions: {
          firefoxUserPrefs: {
            ...firefoxPreferences,
          },
        },
      },
    },
    {
      name: 'webkit-nightly',
      use: {
        ...baseUse,
        ...devices['Desktop Safari'],
      },
    },
  ],
});
